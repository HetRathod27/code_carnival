import uuid
from typing import Any

from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.clock import Clock
from api.app.domain.state_machine import transition
from api.app.models.entities import (
    IdempotencyKey,
    NotificationOutbox,
    Office,
    OfficeSettings,
    PriorityCheck,
    QueueState,
    Service,
    Token,
    TokenEvent,
)


class BookingError(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


async def book_token(
    session: AsyncSession,
    clock: Clock,
    office_id: str,
    service_id: str,
    category: str = "NORMAL",
    phone: str | None = None,
    citizen_id: str | None = None,
    created_via: str = "APP",
    idempotency_key: str | None = None,
    travel_minutes: int = 15,
    on_behalf_of: str | None = None,
) -> dict[str, Any]:
    """
    Booking (C3, O7) — atomic numbering, one transaction.
    Lock order: queue_state -> counters -> tokens.
    """
    # 1. Idempotency Check
    if idempotency_key:
        stmt_idem = select(IdempotencyKey).where(IdempotencyKey.key == idempotency_key)
        res_idem = await session.execute(stmt_idem)
        existing_key = res_idem.scalar_one_or_none()
        if existing_key:
            return existing_key.response

    now_dt = clock.now()
    b_date = clock.business_date()

    # 2. Validation: Office open, Service active, Phone active token limit
    stmt_office = select(Office).where(Office.id == office_id)
    res_office = await session.execute(stmt_office)
    office = res_office.scalar_one_or_none()
    if not office or not office.active:
        raise BookingError("OFFICE_NOT_FOUND_OR_INACTIVE", "Office is not active or found", 404)

    stmt_svc = select(Service).where(Service.id == service_id, Service.office_id == office_id)
    res_svc = await session.execute(stmt_svc)
    service = res_svc.scalar_one_or_none()
    if not service or not service.active:
        raise BookingError("SERVICE_NOT_FOUND_OR_INACTIVE", "Service is not active or found", 404)

    if category == "PRIORITY":
        if not service.priority_allowed:
            raise BookingError("PRIORITY_NOT_ALLOWED", "Priority booking not permitted for this service", 400)
        # Check strike limit per spec O6: at strike_limit priority claims are blocked for that phone
        if phone:
            stmt_strikes = (
                select(func.count(PriorityCheck.id))
                .select_from(PriorityCheck)
                .join(Token, Token.id == PriorityCheck.token_id)
                .where(
                    Token.phone == phone,
                    PriorityCheck.result == "REJECTED",
                )
            )
            res_strikes = await session.execute(stmt_strikes)
            strike_count = res_strikes.scalar_one()

            stmt_settings = select(OfficeSettings.strike_limit).where(OfficeSettings.office_id == office_id)
            res_settings = await session.execute(stmt_settings)
            strike_limit = res_settings.scalar_one_or_none() or 3

            if strike_count >= strike_limit:
                raise BookingError(
                    "PRIORITY_BLOCKED_STRIKES",
                    f"Priority bookings blocked due to {strike_count} rejected priority claims",
                    403,
                )

    # Check active token limit for phone per service on today's business date
    if phone:
        stmt_active = select(Token).where(
            Token.phone == phone,
            Token.service_id == service_id,
            Token.business_date == b_date,
            Token.state.in_(["WAITING", "CALLED", "SERVING"]),
        )
        res_active = await session.execute(stmt_active)
        if res_active.scalar_one_or_none():
            raise BookingError(
                "ACTIVE_TOKEN_EXISTS",
                "An active token already exists for this phone number and service",
                409,
            )

    # 3. Ensure queue_state row exists, then lock FOR UPDATE
    await session.execute(
        text("""
        INSERT INTO queue_state (office_id, service_id, business_date, last_seq, calls_since_priority, waiting_count, version, updated_at)
        VALUES (:office_id, :service_id, :b_date, 0, 0, 0, 1, :now_dt)
        ON CONFLICT (office_id, service_id, business_date) DO NOTHING;
        """),
        {"office_id": office_id, "service_id": service_id, "b_date": b_date, "now_dt": now_dt},
    )

    stmt_qs = (
        select(QueueState)
        .where(
            QueueState.office_id == office_id,
            QueueState.service_id == service_id,
            QueueState.business_date == b_date,
        )
        .with_for_update()
    )
    res_qs = await session.execute(stmt_qs)
    queue_state = res_qs.scalar_one()

    # Section 19.5 queue paused check
    if queue_state.paused:
        raise BookingError("QUEUE_PAUSED", "This queue is temporarily paused by administration", 409)

    # Atomic increment of sequence
    stmt_max = select(func.coalesce(func.max(Token.seq), 0)).where(
        Token.office_id == office_id,
        Token.service_id == service_id,
        Token.business_date == b_date,
    )
    res_max = await session.execute(stmt_max)
    max_existing_seq = res_max.scalar_one()

    current_seq = max(queue_state.last_seq, max_existing_seq)
    new_seq = current_seq + 1
    queue_state.last_seq = new_seq
    queue_state.waiting_count += 1
    queue_state.version += 1
    queue_state.updated_at = now_dt

    display_code = f"{service.code}-{new_seq:03d}"
    token_id = str(uuid.uuid4())
    sort_key = clock.now_epoch()

    token = Token(
        id=token_id,
        office_id=office_id,
        service_id=service_id,
        business_date=b_date,
        seq=new_seq,
        display_code=display_code,
        citizen_id=citizen_id,
        phone=phone,
        beneficiary_name=on_behalf_of,
        category=category,
        priority_status="PENDING" if category == "PRIORITY" else "VERIFIED",
        created_via=created_via,
        state="WAITING",
        sort_key=sort_key,
        travel_minutes=travel_minutes,
        arrived_at=now_dt if created_via in ["WALKIN", "ASSISTED"] else None,
        created_at=now_dt,
    )
    session.add(token)
    await session.flush()

    # 4. Insert initial event in token_events
    actor_type = "DESK" if created_via in ["ASSISTED", "DESK"] else "CITIZEN"
    event = TokenEvent(
        token_id=token_id,
        from_state=None,
        to_state="WAITING",
        actor_type=actor_type,
        actor_id=citizen_id or phone,
        at=now_dt,
        meta={"created_via": created_via, "seq": new_seq},
    )
    session.add(event)

    # 5. Outbox: TOKEN_CONFIRMED push notification
    dedupe_key = f"{token_id}:TOKEN_CONFIRMED"
    outbox = NotificationOutbox(
        token_id=token_id,
        user_id=citizen_id,
        kind="TOKEN_CONFIRMED",
        payload={
            "display_code": display_code,
            "seq": new_seq,
            "service_code": service.code,
            "office_id": office_id,
        },
        dedupe_key=dedupe_key,
        status="PENDING",
        attempts=0,
        send_after=now_dt,
        created_at=now_dt,
    )
    session.add(outbox)

    response_data = {
        "token_id": token_id,
        "office_id": office_id,
        "service_id": service_id,
        "display_code": display_code,
        "seq": new_seq,
        "state": "WAITING",
        "category": category,
        "sort_key": sort_key,
        "business_date": str(b_date),
        "created_at": now_dt.isoformat(),
    }

    # 6. Save Idempotency response if key provided
    if idempotency_key:
        idem = IdempotencyKey(
            key=idempotency_key,
            user_id=citizen_id or phone or "anonymous",
            endpoint="POST /v1/tokens",
            response=response_data,
            created_at=now_dt,
        )
        session.add(idem)

    return response_data


async def cancel_token(
    session: AsyncSession,
    clock: Clock,
    token_id: str,
    actor_type: str = "CITIZEN",
    actor_id: str | None = None,
) -> Token:
    """
    Cancel token: locks queue_state, token -> transition() -> waiting_count - 1.
    """
    # 1. Fetch token and lock
    stmt_tok = select(Token).where(Token.id == token_id).with_for_update()
    res_tok = await session.execute(stmt_tok)
    token = res_tok.scalar_one_or_none()
    if not token:
        raise BookingError("TOKEN_NOT_FOUND", "Token not found", 404)

    if token.state not in ["WAITING", "CALLED"]:
        raise BookingError(
            "CANNOT_CANCEL_STATE",
            f"Cannot cancel token in state {token.state}",
            400,
        )

    # 2. Lock queue_state
    stmt_qs = (
        select(QueueState)
        .where(
            QueueState.office_id == token.office_id,
            QueueState.service_id == token.service_id,
            QueueState.business_date == token.business_date,
        )
        .with_for_update()
    )
    res_qs = await session.execute(stmt_qs)
    queue_state = res_qs.scalar_one()

    # 3. Transition token to CANCELLED
    was_waiting = token.state == "WAITING"
    await transition(
        token=token,
        to_state="CANCELLED",
        actor_type=actor_type,
        actor_id=actor_id,
        session=session,
        clock=clock,
    )

    if was_waiting:
        queue_state.waiting_count = max(0, queue_state.waiting_count - 1)

    return token

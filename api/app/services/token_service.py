import secrets
import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.clock import Clock
from api.app.domain.state_machine import transition
from api.app.eta.admission import check_admission
from api.app.eta.engine import LiveAdjustedEngine, NaiveEngine
from api.app.eta.loader import load_queue_snapshot
from api.app.models.entities import (
    EtaLog,
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


def calculate_staggered_slot_time(base_slot: str | None, offset_index: int) -> str | None:
    if not base_slot:
        return None
    try:
        dash = "–" if "–" in base_slot else ("-" if "-" in base_slot else None)
        if dash:
            start_part = base_slot.split(dash)[0].strip()
        else:
            start_part = base_slot.strip()

        import re
        m = re.match(r"(\d{1,2}):(\d{2})\s*(AM|PM)", start_part, re.IGNORECASE)
        if m:
            hour = int(m.group(1))
            minute = int(m.group(2))
            meridiem = m.group(3).upper()
            if meridiem == "PM" and hour != 12:
                hour += 12
            elif meridiem == "AM" and hour == 12:
                hour = 0

            total_minutes = hour * 60 + minute + offset_index * 15
            s_hour = (total_minutes // 60) % 24
            s_min = total_minutes % 60
            e_total = total_minutes + 15
            e_hour = (e_total // 60) % 24
            e_min = e_total % 60

            def fmt(h: int, mi: int) -> str:
                med = "AM" if h < 12 else "PM"
                h12 = h % 12
                if h12 == 0:
                    h12 = 12
                return f"{h12:02d}:{mi:02d} {med}"

            return f"{fmt(s_hour, s_min)} – {fmt(e_hour, e_min)}"
    except Exception:
        pass
    if offset_index == 0:
        return base_slot
    return f"{base_slot} (+{offset_index * 15}m)"


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
    beneficiary_name: str | None = None,
    priority_doc_type: str | None = None,
    override_reason: str | None = None,
    appointment_date: str | None = None,
    appointment_slot: str | None = None,
    is_fixed: bool = False,
    accompanying_members: list[Any] | None = None,
) -> dict[str, Any]:
    """
    Booking (C3, O7) — atomic numbering, one transaction.
    Lock order: queue_state -> counters -> tokens.
    """
    if beneficiary_name and not on_behalf_of:
        on_behalf_of = beneficiary_name

    # 1. Idempotency Check
    if idempotency_key:
        stmt_idem = select(IdempotencyKey).where(IdempotencyKey.key == idempotency_key)
        res_idem = await session.execute(stmt_idem)
        existing_key = res_idem.scalar_one_or_none()
        if existing_key:
            return existing_key.response

    now_dt = clock.now()
    curr_b_date = clock.business_date()
    if appointment_date:
        try:
            b_date = datetime.strptime(appointment_date, "%Y-%m-%d").date()
        except ValueError:
            b_date = curr_b_date
        if b_date < curr_b_date:
            raise BookingError("APPOINTMENT_DATE_PAST", "Appointment date cannot be in the past", 400)
        if (b_date - curr_b_date).days > 15:
            raise BookingError(
                "APPOINTMENT_DATE_EXCEEDS_LIMIT",
                "Appointment date cannot exceed 15 days in advance",
                400,
            )
    else:
        b_date = curr_b_date

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

    db_category = "PRIORITY" if category in ["PRIORITY", "SENIOR", "PREGNANT", "DISABILITY"] else "NORMAL"

    if db_category == "PRIORITY":
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

    # Section 19.1 Admission Control (P0)
    stmt_office_settings = select(OfficeSettings).where(OfficeSettings.office_id == office_id)
    res_office_settings = await session.execute(stmt_office_settings)
    office_settings = res_office_settings.scalar_one_or_none()
    close_grace = office_settings.close_grace_minutes if office_settings else 15
    max_waiting = office_settings.max_waiting_per_service if office_settings else 100

    current_snapshot = await load_queue_snapshot(session, clock, office_id, service_id)
    is_fixed_appointment = is_fixed or bool(appointment_slot) or (appointment_date is not None)
    is_desk_override = created_via in ["ASSISTED", "DESK", "WALKIN"] or bool(override_reason) or is_fixed_appointment
    admitted, rejection_reason, _ = check_admission(
        snapshot=current_snapshot,
        office_close_time=office.close_time,
        close_grace_minutes=close_grace,
        max_waiting_per_service=max_waiting,
        is_desk_override=is_desk_override,
    )
    if not admitted:
        if rejection_reason == "QUEUE_FULL_CAPACITY":
            raise BookingError("QUEUE_FULL_CAPACITY", "Queue has reached maximum capacity for this service", 409)
        raise BookingError("QUEUE_FULL_FOR_TODAY", "Queue full for today. Please try tomorrow.", 409)

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
    verification_secret = f"{secrets.randbelow(900000) + 100000:06d}"

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
        category=db_category,
        priority_status="VERIFIED" if (created_via in ["WALKIN", "ASSISTED", "DESK"] or db_category == "NORMAL") else "PENDING",
        created_via=created_via,
        state="WAITING",
        sort_key=sort_key,
        travel_minutes=travel_minutes,
        arrived_at=now_dt if created_via in ["WALKIN", "ASSISTED"] else None,
        verification_secret=verification_secret,
        verification_verified=False,
        failed_verification_attempts=0,
        created_at=now_dt,
    )
    session.add(token)
    await session.flush()

    # 4. Insert initial event in token_events
    actor_type = "DESK" if created_via in ["ASSISTED", "DESK"] else "CITIZEN"
    event_meta: dict[str, Any] = {"created_via": created_via, "seq": new_seq}
    if category != db_category:
        event_meta["priority_sub_category"] = category
    if is_desk_override and override_reason:
        event_meta["reason_code"] = override_reason

    event = TokenEvent(
        token_id=token_id,
        from_state=None,
        to_state="WAITING",
        actor_type=actor_type,
        actor_id=citizen_id or phone,
        at=now_dt,
        meta=event_meta,
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

    # 6. Compute ETAs and record in eta_log
    new_snapshot = await load_queue_snapshot(session, clock, office_id, service_id)
    live_engine = LiveAdjustedEngine()
    naive_engine = NaiveEngine()

    live_etas = live_engine.compute_etas(new_snapshot)
    naive_etas = naive_engine.compute_etas(new_snapshot)

    token_eta = live_etas.get(token_id)
    naive_eta = naive_etas.get(token_id)

    p50 = token_eta.p50_minutes if token_eta else 0.0
    low = token_eta.low_minutes if token_eta else 0.0
    high = token_eta.high_minutes if token_eta else 0.0
    reason = token_eta.reason if token_eta else None
    n_p50 = naive_eta.p50_minutes if naive_eta else 0.0

    token.last_eta_minutes = int(p50)
    token.last_eta_reason = reason
    eta_meta: dict[str, Any] = {"low": low, "high": high, "naive_p50": n_p50}
    if is_fixed_appointment:
        eta_meta["is_fixed"] = True
    if appointment_slot:
        eta_meta["appointment_slot"] = appointment_slot
    if appointment_date:
        eta_meta["appointment_date"] = appointment_date
    token.eta_features = eta_meta

    eta_log_entry = EtaLog(
        token_id=token_id,
        at=now_dt,
        engine="live_adjusted",
        predicted_p50=p50,
        low=low,
        high=high,
        naive_p50=n_p50,
    )
    session.add(eta_log_entry)

    child_token_ids: list[str] = []
    if accompanying_members:
        primary_slot = calculate_staggered_slot_time(appointment_slot, 0)
        if primary_slot and token.eta_features:
            token.eta_features["appointment_slot"] = primary_slot

        for idx, member in enumerate(accompanying_members):
            m_name = member.get("name") if isinstance(member, dict) else getattr(member, "name", "")
            m_reason = member.get("reason") if isinstance(member, dict) else getattr(member, "reason", "")
            m_custom_slot = member.get("slot_time") if isinstance(member, dict) else getattr(member, "slot_time", None)
            c_slot_time = m_custom_slot or calculate_staggered_slot_time(appointment_slot, idx + 1)

            new_seq += 1
            queue_state.last_seq = new_seq
            queue_state.waiting_count += 1
            queue_state.version += 1
            queue_state.updated_at = now_dt

            c_display_code = f"{service.code}-{new_seq:03d}"
            c_token_id = str(uuid.uuid4())
            c_secret = f"{secrets.randbelow(900000) + 100000:06d}"

            c_eta_meta: dict[str, Any] = {
                "low": low,
                "high": high,
                "naive_p50": n_p50,
                "co_attendance_reason": m_reason,
                "appointment_slot": c_slot_time,
            }
            if is_fixed_appointment:
                c_eta_meta["is_fixed"] = True
            if appointment_date:
                c_eta_meta["appointment_date"] = appointment_date

            c_token = Token(
                id=c_token_id,
                office_id=office_id,
                service_id=service_id,
                business_date=b_date,
                seq=new_seq,
                display_code=c_display_code,
                citizen_id=citizen_id,
                phone=None,
                beneficiary_name=m_name,
                parent_token_id=token_id,
                category=db_category,
                priority_status="VERIFIED" if (created_via in ["WALKIN", "ASSISTED", "DESK"] or db_category == "NORMAL") else "PENDING",
                created_via=created_via,
                state="WAITING",
                sort_key=sort_key + (idx + 1) * 0.001,
                travel_minutes=travel_minutes,
                arrived_at=now_dt if created_via in ["WALKIN", "ASSISTED"] else None,
                verification_secret=c_secret,
                verification_verified=False,
                failed_verification_attempts=0,
                last_eta_minutes=int(p50),
                last_eta_reason=reason,
                eta_features=c_eta_meta,
                created_at=now_dt,
            )
            session.add(c_token)
            await session.flush()

            c_event = TokenEvent(
                token_id=c_token_id,
                from_state=None,
                to_state="WAITING",
                actor_type=actor_type,
                actor_id=citizen_id or phone,
                at=now_dt,
                meta={
                    "created_via": created_via,
                    "seq": new_seq,
                    "parent_token_id": token_id,
                    "co_attendance_reason": m_reason,
                    "appointment_slot": c_slot_time,
                },
            )
            session.add(c_event)
            child_token_ids.append(c_token_id)

    response_data = {
        "token_id": token_id,
        "verification_secret": verification_secret,
        "office_id": office_id,
        "service_id": service_id,
        "display_code": display_code,
        "seq": token.seq,
        "state": "WAITING",
        "category": category,
        "sort_key": sort_key,
        "business_date": str(b_date),
        "last_eta_minutes": int(p50),
        "eta_low": low,
        "eta_high": high,
        "eta_reason": reason,
        "naive_p50": n_p50,
        "child_token_ids": child_token_ids,
        "created_at": now_dt.isoformat(),
    }

    # 7. Save Idempotency response if key provided
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

    token.verification_secret = None
    token.verification_verified = False
    token.verified_counter_id = None
    token.verified_officer_id = None
    token.verified_at = None

    if was_waiting:
        queue_state.waiting_count = max(0, queue_state.waiting_count - 1)

    return token

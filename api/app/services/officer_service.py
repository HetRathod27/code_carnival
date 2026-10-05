import hashlib
import hmac
from datetime import timedelta
from typing import Any

from sqlalchemy import func, select, text, update
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.clock import Clock
from api.app.domain.state_machine import transition
from api.app.models.entities import (
    Counter,
    CounterEvent,
    CounterService,
    NotificationOutbox,
    Office,
    OfficeSettings,
    PriorityCheck,
    QueueState,
    Token,
)
from api.app.services.token_service import book_token


class OfficerOperationError(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


async def set_counter_status(
    session: AsyncSession,
    clock: Clock,
    counter_id: str,
    status: str,
    officer_id: str,
) -> Counter:
    """
    Set counter status (OPEN, BREAK, CLOSED) per spec O2 & Section 19.6 (O12).
    Rule O12: A counter cannot be set CLOSED while it has a SERVING token.
    """
    if status not in ["OPEN", "BREAK", "CLOSED"]:
        raise OfficerOperationError("INVALID_STATUS", f"Invalid counter status: {status}", 400)

    # 1. Lock counter
    stmt = select(Counter).where(Counter.id == counter_id).with_for_update()
    res = await session.execute(stmt)
    counter = res.scalar_one_or_none()
    if not counter:
        raise OfficerOperationError("COUNTER_NOT_FOUND", f"Counter '{counter_id}' not found", 404)

    # 2. O12 Guard: cannot set CLOSED while SERVING a token today
    if status == "CLOSED":
        b_date = clock.business_date()
        stmt_serving = select(Token).where(
            Token.counter_id == counter_id,
            Token.business_date == b_date,
            Token.state == "SERVING",
        )
        res_serving = await session.execute(stmt_serving)

        if res_serving.first():
            raise OfficerOperationError(
                "COUNTER_HAS_SERVING_TOKEN",
                "Cannot close counter while a token is in SERVING state. Complete, release, or transfer first.",
                409,
            )

    now_dt = clock.now()
    counter.status = status
    if status == "CLOSED":
        counter.officer_id = None
    else:
        counter.officer_id = officer_id

    # 3. Log counter_event
    event = CounterEvent(
        counter_id=counter_id,
        status=status,
        at=now_dt,
        actor=officer_id,
    )
    session.add(event)
    return counter


async def call_next(
    session: AsyncSession,
    clock: Clock,
    counter_id: str,
    officer_id: str,
    target_service_id: str | None = None,
) -> Token:
    """
    Call next token (O3, spec 6.5 with Section 19.2 arrived-first dispatch).
    Lock order: queue_state -> counters -> tokens.
    """
    now_dt = clock.now()
    b_date = clock.business_date()

    # 1. Inspect Counter and verify status
    stmt_cnt = select(Counter).where(Counter.id == counter_id).with_for_update()
    res_cnt = await session.execute(stmt_cnt)
    counter = res_cnt.scalar_one_or_none()
    if not counter:
        raise OfficerOperationError("COUNTER_NOT_FOUND", f"Counter '{counter_id}' not found", 404)
    if counter.status != "OPEN":
        raise OfficerOperationError("COUNTER_NOT_OPEN", "Counter is not in OPEN status", 409)

    # Check if counter already has a CALLED or SERVING token today
    stmt_active = select(Token).where(
        Token.counter_id == counter_id,
        Token.business_date == b_date,
        Token.state.in_(["CALLED", "SERVING"]),
    )
    res_active = await session.execute(stmt_active)
    active_tok = res_active.scalar_one_or_none()
    if active_tok:
        raise OfficerOperationError(
            "COUNTER_BUSY",
            f"Counter currently has active token '{active_tok.display_code}' in state '{active_tok.state}'",
            409,
        )

    # 2. Identify mapped services for this counter
    stmt_map = select(CounterService.service_id).where(CounterService.counter_id == counter_id)
    res_map = await session.execute(stmt_map)
    mapped_service_ids = [row[0] for row in res_map.fetchall()]

    if not mapped_service_ids:
        raise OfficerOperationError("NO_SERVICES_MAPPED", "No services mapped to this counter", 400)

    if target_service_id:
        if target_service_id not in mapped_service_ids:
            raise OfficerOperationError("SERVICE_NOT_MAPPED", f"Service '{target_service_id}' is not mapped to this counter", 400)
        chosen_service_id = target_service_id
    else:
        # Pick mapped service whose head token has waited longest (smallest sort_key)
        stmt_oldest = (
            select(Token.service_id)
            .where(
                Token.service_id.in_(mapped_service_ids),
                Token.business_date == b_date,
                Token.state == "WAITING",
            )
            .order_by(Token.sort_key.asc())
            .limit(1)
        )
        res_oldest = await session.execute(stmt_oldest)
        chosen_service_id = res_oldest.scalar_one_or_none() or mapped_service_ids[0]

    # 3. Lock queue_state row FOR UPDATE
    # First ensure row exists
    await session.execute(
        text("""
        INSERT INTO queue_state (office_id, service_id, business_date, last_seq, calls_since_priority, waiting_count, version, updated_at)
        VALUES (:office_id, :service_id, :b_date, 0, 0, 0, 1, :now_dt)
        ON CONFLICT (office_id, service_id, business_date) DO NOTHING;
        """),
        {"office_id": counter.office_id, "service_id": chosen_service_id, "b_date": b_date, "now_dt": now_dt},
    )
    stmt_qs = (
        select(QueueState)
        .where(
            QueueState.office_id == counter.office_id,
            QueueState.service_id == chosen_service_id,
            QueueState.business_date == b_date,
        )
        .with_for_update()
    )
    res_qs = await session.execute(stmt_qs)
    queue_state = res_qs.scalar_one()

    # 4. Read office settings (priority_ratio, grace_minutes, dispatch_window, max_pass_overs)
    stmt_settings = select(OfficeSettings).where(OfficeSettings.office_id == counter.office_id)
    res_settings = await session.execute(stmt_settings)
    settings = res_settings.scalar_one_or_none()

    priority_every_n = settings.priority_every_n if settings else 3
    grace_minutes = settings.grace_minutes if settings else 5
    dispatch_window = settings.dispatch_window if settings else 3
    max_pass_overs = settings.max_pass_overs if settings else 2

    # 5. Determine pool (PRIORITY vs NORMAL) per spec 6.5
    # Check if any priority waiting tokens exist
    stmt_has_priority = select(func.count(Token.id)).where(
        Token.office_id == counter.office_id,
        Token.service_id == chosen_service_id,
        Token.business_date == b_date,
        Token.state == "WAITING",
        Token.category == "PRIORITY",
    )
    has_priority = (await session.execute(stmt_has_priority)).scalar_one() > 0

    stmt_has_normal = select(func.count(Token.id)).where(
        Token.office_id == counter.office_id,
        Token.service_id == chosen_service_id,
        Token.business_date == b_date,
        Token.state == "WAITING",
        Token.category == "NORMAL",
    )
    has_normal = (await session.execute(stmt_has_normal)).scalar_one() > 0

    if not has_priority and not has_normal:
        raise OfficerOperationError("QUEUE_EMPTY", "No waiting tokens in this queue", 404)

    # Interleave rule:
    # pool = PRIORITY if (calls_since_priority >= priority_every_n - 1 and has_priority) or (not has_normal and has_priority) else NORMAL
    if (queue_state.calls_since_priority >= priority_every_n - 1 and has_priority) or (not has_normal and has_priority):
        target_category = "PRIORITY"
    else:
        target_category = "NORMAL"

    # 6. Section 19.2 Arrived-first dispatch within dispatch_window
    # Query candidate tokens in order of sort_key with FOR UPDATE SKIP LOCKED
    stmt_candidates = (
        select(Token)
        .where(
            Token.office_id == counter.office_id,
            Token.service_id == chosen_service_id,
            Token.business_date == b_date,
            Token.state == "WAITING",
            Token.category == target_category,
        )
        .order_by(Token.sort_key.asc())
        .limit(dispatch_window)
        .with_for_update(skip_locked=True)
    )
    res_candidates = await session.execute(stmt_candidates)
    candidates = list(res_candidates.scalars().all())

    if not candidates:
        # Fallback to any waiting token if targeted category was locked
        stmt_fallback = (
            select(Token)
            .where(
                Token.office_id == counter.office_id,
                Token.service_id == chosen_service_id,
                Token.business_date == b_date,
                Token.state == "WAITING",
            )
            .order_by(Token.sort_key.asc())
            .limit(dispatch_window)
            .with_for_update(skip_locked=True)
        )
        candidates = list((await session.execute(stmt_fallback)).scalars().all())

    if not candidates:
        raise OfficerOperationError("NO_AVAILABLE_TOKENS", "No available tokens found to call", 404)

    # Section 19.2: Check if any candidate in the window has reached max_pass_overs
    # If the head candidate has already been passed over max_pass_overs times, they must be picked
    chosen_token: Token | None = None
    passed_over_tokens: list[Token] = []
    head_token = candidates[0]
    if head_token.pass_over_count >= max_pass_overs:
        chosen_token = head_token
    else:
        # Otherwise, look for the first arrived candidate
        for cand in candidates:
            if cand.arrived_at is not None:
                chosen_token = cand
                break

    if chosen_token is None:
        # Nobody in dispatch window has arrived -> pick head candidate
        chosen_token = candidates[0]
    else:
        # One candidate was chosen. Any candidates before it in sort_key order are passed over
        for cand in candidates:
            if cand.id == chosen_token.id:
                break
            cand.pass_over_count += 1
            passed_over_tokens.append(cand)

    # 7. Transition chosen_token from WAITING -> CALLED
    grace_deadline = now_dt + timedelta(minutes=grace_minutes)
    chosen_token.grace_deadline = grace_deadline
    chosen_token.called_at = now_dt
    chosen_token.counter_id = counter_id

    await transition(
        token=chosen_token,
        to_state="CALLED",
        actor_type="OFFICER",
        actor_id=officer_id,
        session=session,
        clock=clock,
        counter_id=counter_id,
        meta={"pass_over_count": chosen_token.pass_over_count},
    )

    # 8. Update queue_state
    if chosen_token.category == "PRIORITY":
        queue_state.calls_since_priority = 0
    else:
        queue_state.calls_since_priority += 1

    queue_state.now_serving = chosen_token.display_code
    if queue_state.waiting_count > 0:
        queue_state.waiting_count -= 1
    queue_state.updated_at = now_dt

    # 9. Enqueue YOUR_TURN notification outbox (dedupe key: token+kind+call_count per spec Section 7)
    stmt_call_count = select(func.count(NotificationOutbox.id)).where(
        NotificationOutbox.token_id == chosen_token.id,
        NotificationOutbox.kind == "YOUR_TURN",
    )
    res_call_count = await session.execute(stmt_call_count)
    call_count = res_call_count.scalar_one() + 1

    dedupe_key = f"{chosen_token.id}:YOUR_TURN:{call_count}"
    outbox = NotificationOutbox(
        token_id=chosen_token.id,
        user_id=chosen_token.citizen_id,
        kind="YOUR_TURN",
        payload={
            "token_id": chosen_token.id,
            "display_code": chosen_token.display_code,
            "counter_id": counter_id,
            "counter_label": counter.label,
            "grace_deadline": grace_deadline.isoformat(),
        },
        dedupe_key=dedupe_key,
        status="PENDING",
        send_after=now_dt,
        created_at=now_dt,
    )
    session.add(outbox)

    return chosen_token


async def start_serving(
    session: AsyncSession,
    clock: Clock,
    token_id: str,
    counter_id: str,
    officer_id: str,
) -> Token:
    """
    Start serving a CALLED token (O4).
    """
    stmt = select(Token).where(Token.id == token_id).with_for_update()
    res = await session.execute(stmt)
    token = res.scalar_one_or_none()
    if not token:
        raise OfficerOperationError("TOKEN_NOT_FOUND", "Token not found", 404)

    now_dt = clock.now()
    token.serving_started_at = now_dt

    await transition(
        token=token,
        to_state="SERVING",
        actor_type="OFFICER",
        actor_id=officer_id,
        session=session,
        clock=clock,
        counter_id=counter_id,
    )
    return token


async def complete_serving(
    session: AsyncSession,
    clock: Clock,
    token_id: str,
    counter_id: str,
    officer_id: str,
    outcome_code: str = "SERVED",
    meta: dict[str, Any] | None = None,
) -> Token:
    """
    Complete serving a SERVING token (O4, Section 19.5 outcome_code).
    """
    valid_outcomes = ["SERVED", "MISSING_DOCS", "WRONG_SERVICE", "WRONG_OFFICE", "CITIZEN_LEFT", "OTHER"]
    if outcome_code not in valid_outcomes:
        raise OfficerOperationError("INVALID_OUTCOME_CODE", f"Invalid outcome code: {outcome_code}", 400)

    stmt = select(Token).where(Token.id == token_id).with_for_update()
    res = await session.execute(stmt)
    token = res.scalar_one_or_none()
    if not token:
        raise OfficerOperationError("TOKEN_NOT_FOUND", "Token not found", 404)

    now_dt = clock.now()
    token.completed_at = now_dt
    token.outcome_code = outcome_code

    event_meta = meta or {}
    event_meta["outcome_code"] = outcome_code

    await transition(
        token=token,
        to_state="COMPLETED",
        actor_type="OFFICER",
        actor_id=officer_id,
        session=session,
        clock=clock,
        counter_id=counter_id,
        meta=event_meta,
    )
    return token


async def mark_no_show(
    session: AsyncSession,
    clock: Clock,
    token_id: str,
    counter_id: str,
    officer_id: str,
    reason: str = "CITIZEN_DID_NOT_APPEAR",
) -> Token:
    """
    Mark a CALLED token as NO_SHOW (O5).
    Requirement 4.1: Manual no-show must never leave token stranded in NO_SHOW;
    it must requeue or cancel exactly like the tick sweep.
    """
    stmt = select(Token).where(Token.id == token_id).with_for_update()
    res = await session.execute(stmt)
    token = res.scalar_one_or_none()
    if not token:
        raise OfficerOperationError("TOKEN_NOT_FOUND", "Token not found", 404)

    # 1. Transition: CALLED -> NO_SHOW
    await transition(
        token=token,
        to_state="NO_SHOW",
        actor_type="OFFICER",
        actor_id=officer_id,
        session=session,
        clock=clock,
        counter_id=counter_id,
        meta={"reason_code": reason},
    )

    # 2. Requeue or Cancel based on office settings
    stmt_set = select(OfficeSettings).where(OfficeSettings.office_id == token.office_id)
    res_set = await session.execute(stmt_set)
    settings = res_set.scalar_one_or_none()
    max_requeues = settings.max_requeues if settings else 1
    requeue_offset = settings.requeue_offset if settings else 5

    if token.requeue_count < max_requeues:
        token.requeue_count += 1
        stmt_offset = (
            select(Token.sort_key)
            .where(
                Token.office_id == token.office_id,
                Token.service_id == token.service_id,
                Token.business_date == token.business_date,
                Token.state == "WAITING",
            )
            .order_by(Token.sort_key.asc())
            .offset(requeue_offset)
            .limit(1)
        )
        res_offset = await session.execute(stmt_offset)
        offset_sort_key = res_offset.scalar_one_or_none()
        if offset_sort_key is not None:
            token.sort_key = float(offset_sort_key) + 0.001
        else:
            token.sort_key = clock.now_epoch() + 1.0

        # Transition: NO_SHOW -> WAITING
        await transition(
            token=token,
            to_state="WAITING",
            actor_type="SYSTEM",
            actor_id="system",
            session=session,
            clock=clock,
            meta={"reason_code": "OFFICER_NO_SHOW_REQUEUE", "requeue_count": token.requeue_count},
        )

        stmt_qs = select(QueueState).where(
            QueueState.office_id == token.office_id,
            QueueState.service_id == token.service_id,
            QueueState.business_date == token.business_date,
        ).with_for_update()
        res_qs = await session.execute(stmt_qs)
        qs = res_qs.scalar_one_or_none()
        if qs:
            qs.waiting_count += 1
            qs.version += 1
    else:
        # Transition: NO_SHOW -> CANCELLED
        await transition(
            token=token,
            to_state="CANCELLED",
            actor_type="SYSTEM",
            actor_id="system",
            session=session,
            clock=clock,
            meta={"reason_code": "OFFICER_NO_SHOW_MAX_REQUEUES"},
        )

    return token


async def release_token(
    session: AsyncSession,
    clock: Clock,
    token_id: str,
    counter_id: str,
    officer_id: str,
    reason: str = "COUNTER_PROBLEM",
) -> Token:
    """
    Release a CALLED token back to WAITING without sort_key penalty (O5).
    Section 19.5: reason_code is mandatory.
    """
    stmt = select(Token).where(Token.id == token_id).with_for_update()
    res = await session.execute(stmt)
    token = res.scalar_one_or_none()
    if not token:
        raise OfficerOperationError("TOKEN_NOT_FOUND", "Token not found", 404)

    # Re-increment waiting_count on queue_state
    b_date = clock.business_date()
    stmt_qs = (
        update(QueueState)
        .where(
            QueueState.office_id == token.office_id,
            QueueState.service_id == token.service_id,
            QueueState.business_date == b_date,
        )
        .values(waiting_count=QueueState.waiting_count + 1)
    )
    await session.execute(stmt_qs)

    token.counter_id = None
    token.called_at = None
    token.grace_deadline = None

    await transition(
        token=token,
        to_state="WAITING",
        actor_type="OFFICER",
        actor_id=officer_id,
        session=session,
        clock=clock,
        counter_id=None,
        meta={"reason_code": reason, "released_from_counter": counter_id},
    )
    return token


async def transfer_token(
    session: AsyncSession,
    clock: Clock,
    token_id: str,
    target_service_id: str,
    counter_id: str,
    officer_id: str,
    reason: str = "WRONG_SERVICE",
    carry_over_sort_key: bool = True,
) -> dict[str, Any]:
    """
    Transfer token to another service (O8, Section 19.6 O4).
    Transitions current token to TRANSFERRED, creates new token in target service with parent_token_id.
    """
    stmt = select(Token).where(Token.id == token_id).with_for_update()
    res = await session.execute(stmt)
    token = res.scalar_one_or_none()
    if not token:
        raise OfficerOperationError("TOKEN_NOT_FOUND", "Token not found", 404)

    # Transition source token
    await transition(
        token=token,
        to_state="TRANSFERRED",
        actor_type="OFFICER",
        actor_id=officer_id,
        session=session,
        clock=clock,
        counter_id=counter_id,
        meta={"reason_code": reason, "target_service_id": target_service_id},
    )

    # Create new token in target service
    new_token_res = await book_token(
        session=session,
        clock=clock,
        office_id=token.office_id,
        service_id=target_service_id,
        category=token.category,
        phone=token.phone,
        citizen_id=token.citizen_id,
        created_via="TRANSFER",
        travel_minutes=token.travel_minutes,
        on_behalf_of=token.beneficiary_name,
    )

    # Link parent token and optionally carry over sort_key
    new_token_id = new_token_res["token_id"]
    new_tok = (await session.execute(select(Token).where(Token.id == new_token_id))).scalar_one()
    new_tok.parent_token_id = token.id
    if carry_over_sort_key:
        new_tok.sort_key = token.sort_key

    return {
        "original_token_id": token.id,
        "new_token": new_token_res,
    }


async def priority_check(
    session: AsyncSession,
    clock: Clock,
    token_id: str,
    officer_id: str,
    result: str,
    doc_type: str = "GOVT_ID",
    note: str | None = None,
) -> dict[str, Any]:
    """
    Priority check (O6).
    VERIFIED: token stays PRIORITY, priority_status = VERIFIED.
    REJECTED: token category becomes NORMAL, strike recorded, priority_status = REJECTED.
    At strike_limit, future priority claims are blocked.
    """
    if result not in ["VERIFIED", "REJECTED"]:
        raise OfficerOperationError("INVALID_CHECK_RESULT", "Result must be VERIFIED or REJECTED", 400)

    stmt = select(Token).where(Token.id == token_id).with_for_update()
    res = await session.execute(stmt)
    token = res.scalar_one_or_none()
    if not token:
        raise OfficerOperationError("TOKEN_NOT_FOUND", "Token not found", 404)

    now_dt = clock.now()

    # Record priority check row
    check = PriorityCheck(
        token_id=token.id,
        officer_id=officer_id,
        doc_type=doc_type,
        result=result,
        at=now_dt,
    )
    session.add(check)

    token.priority_status = result

    strikes_count = 0
    if result == "REJECTED":
        token.category = "NORMAL"
        # Check total strikes for this phone
        if token.phone:
            stmt_strikes = (
                select(func.count(PriorityCheck.id))
                .select_from(PriorityCheck)
                .join(Token, Token.id == PriorityCheck.token_id)
                .where(
                    Token.phone == token.phone,
                    PriorityCheck.result == "REJECTED",
                )
            )
            res_strikes = await session.execute(stmt_strikes)
            strikes_count = res_strikes.scalar_one()

    return {
        "token_id": token.id,
        "result": result,
        "category": token.category,
        "priority_status": token.priority_status,
        "strikes_count": strikes_count,
    }


def generate_qr_payload(office_id: str, qr_secret: str, window: str = "static") -> str:
    """
    Generates a signed QR string format: '{office_id}:{window}:{hmac_digest}'
    per spec 6.7.
    """
    message = f"{office_id}:{window}".encode("utf-8")
    sig = hmac.new(qr_secret.encode("utf-8"), message, hashlib.sha256).hexdigest()
    return f"{office_id}:{window}:{sig}"


def verify_qr_payload(qr_payload: str, office_id: str, qr_secret: str) -> bool:
    """
    Verifies HMAC-signed QR payload.
    """
    parts = qr_payload.split(":")
    if len(parts) != 3:
        return False
    payload_office_id, window, provided_sig = parts
    if payload_office_id != office_id:
        return False

    message = f"{office_id}:{window}".encode("utf-8")
    expected_sig = hmac.new(qr_secret.encode("utf-8"), message, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected_sig, provided_sig)


async def check_in_token(
    session: AsyncSession,
    clock: Clock,
    token_id: str,
    qr_payload: str,
) -> Token:
    """
    Citizen check-in (C6, 6.7).
    Validates QR signature against office.qr_secret and marks arrived_at.
    """
    stmt = select(Token).where(Token.id == token_id).with_for_update()
    res = await session.execute(stmt)
    token = res.scalar_one_or_none()
    if not token:
        raise OfficerOperationError("TOKEN_NOT_FOUND", "Token not found", 404)

    stmt_office = select(Office).where(Office.id == token.office_id)
    res_office = await session.execute(stmt_office)
    office = res_office.scalar_one_or_none()
    if not office:
        raise OfficerOperationError("OFFICE_NOT_FOUND", "Office not found", 404)

    # Verify signed QR
    if not verify_qr_payload(qr_payload, office.id, office.qr_secret):
        raise OfficerOperationError("INVALID_QR_SIGNATURE", "QR payload signature is invalid or expired", 400)

    now_dt = clock.now()
    token.arrived_at = now_dt
    return token

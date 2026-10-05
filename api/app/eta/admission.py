from datetime import datetime, time, timedelta

from api.app.eta.engine import LiveAdjustedEngine
from api.app.eta.models import CounterInfo, QueueSnapshot, WaitingToken


def check_admission(
    snapshot: QueueSnapshot,
    office_close_time: time,
    close_grace_minutes: int,
    max_waiting_per_service: int,
    is_desk_override: bool = False,
) -> tuple[bool, str | None, float | None]:
    """
    Section 19.1 Admission control (P0).
    Pure function predicting whether a new token can be served today.
    Returns: (is_admitted, rejection_reason, predicted_wait_minutes)
    """
    if is_desk_override:
        return True, None, None

    # Check 1: Maximum waiting capacity
    if len(snapshot.waiting_tokens) >= max_waiting_per_service:
        return False, "QUEUE_FULL_CAPACITY", None

    # Check 2: Calculate hypothetical tail token ETA
    engine = LiveAdjustedEngine()

    dummy_token = WaitingToken(
        id="hypothetical-tail-token",
        category="NORMAL",
        sort_key=float(snapshot.now.timestamp()) + 1.0,
        arrived_at=None,
    )

    # For admission planning, if all counters are currently closed (e.g. before opening time or on break),
    # model capacity assuming configured counters operate.
    has_open_counter = any(c.status == "OPEN" for c in snapshot.counters)
    tail_counters = (
        [CounterInfo(id=c.id, status="OPEN", current_serving_token_id=c.current_serving_token_id) for c in snapshot.counters]
        if not has_open_counter and snapshot.counters
        else snapshot.counters
    )

    tail_snapshot = QueueSnapshot(
        now=snapshot.now,
        service=snapshot.service,
        counters=tail_counters,
        serving_tokens=snapshot.serving_tokens,
        waiting_tokens=snapshot.waiting_tokens + [dummy_token],
        calls_since_priority=snapshot.calls_since_priority,
        priority_every_n=snapshot.priority_every_n,
        dispatch_window=snapshot.dispatch_window,
        max_pass_overs=snapshot.max_pass_overs,
    )

    etas = engine.compute_etas(tail_snapshot)
    tail_eta = etas.get("hypothetical-tail-token")
    if not tail_eta:
        return True, None, None

    predicted_start = tail_eta.predicted_start_time or (snapshot.now + timedelta(minutes=tail_eta.p50_minutes))

    # Cutoff time: close_time - close_grace_minutes
    # Combine snapshot date with close_time
    office_close_dt = datetime.combine(snapshot.now.date(), office_close_time, tzinfo=snapshot.now.tzinfo)
    cutoff_dt = office_close_dt - timedelta(minutes=close_grace_minutes)

    if predicted_start > cutoff_dt:
        return False, "QUEUE_FULL_FOR_TODAY", tail_eta.p50_minutes

    return True, None, tail_eta.p50_minutes

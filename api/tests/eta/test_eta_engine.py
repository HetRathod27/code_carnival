import uuid
from datetime import datetime, time, timedelta, timezone

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from api.app.core.clock import VirtualClock
from api.app.core.config import settings as app_settings
from api.app.core.safety import assert_test_database
from api.app.eta.admission import check_admission
from api.app.eta.engine import LiveAdjustedEngine, NaiveEngine
from api.app.eta.models import (
    CounterInfo,
    QueueSnapshot,
    ServiceInfo,
    ServingToken,
    WaitingToken,
)
from api.app.models.entities import EtaLog, Token
from api.app.services.token_service import BookingError, book_token

assert_test_database(app_settings.TEST_DATABASE_URL)


@pytest.fixture
def test_engine():
    engine = create_async_engine(
        app_settings.TEST_DATABASE_URL,
        echo=False,
        pool_size=10,
        max_overflow=10,
    )
    yield engine
    engine.sync_engine.dispose()


@pytest.fixture
def session_factory(test_engine):
    return async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


def make_snapshot(
    now: datetime | None = None,
    mean: float = 10.0,
    open_counters_count: int = 1,
    waiting_count: int = 3,
    serving_elapsed: list[float] | None = None,
    calls_since_priority: int = 0,
    priority_every_n: int = 3,
) -> QueueSnapshot:
    if now is None:
        now = datetime(2026, 10, 2, 10, 0, 0, tzinfo=timezone.utc)

    svc = ServiceInfo(
        id="srv-bc",
        code="BC",
        prior_avg_minutes=mean,
        ewma_mean=mean,
        ewma_var=0.0,
    )

    serving_tokens: list[ServingToken] = []
    counters: list[CounterInfo] = []
    serving_elapsed = serving_elapsed or []

    for i in range(open_counters_count):
        cid = f"counter-{i+1}"
        if i < len(serving_elapsed):
            tok_id = f"serv-tok-{i+1}"
            st_obj = ServingToken(
                token_id=tok_id,
                counter_id=cid,
                started_at=now - timedelta(minutes=serving_elapsed[i]),
                elapsed_minutes=serving_elapsed[i],
            )
            serving_tokens.append(st_obj)
            counters.append(CounterInfo(id=cid, status="OPEN", current_serving_token_id=tok_id))
        else:
            counters.append(CounterInfo(id=cid, status="OPEN", current_serving_token_id=None))

    waiting_tokens = [
        WaitingToken(
            id=f"wait-tok-{j+1}",
            category="NORMAL",
            sort_key=float(j + 1),
            arrived_at=now,
        )
        for j in range(waiting_count)
    ]

    return QueueSnapshot(
        now=now,
        service=svc,
        counters=counters,
        serving_tokens=serving_tokens,
        waiting_tokens=waiting_tokens,
        calls_since_priority=calls_since_priority,
        priority_every_n=priority_every_n,
    )


def test_pure_function_zero_db_or_network():
    """Core Rule 5: compute_etas is a pure function. Zero DB or network calls."""
    snapshot = make_snapshot(mean=12.0, open_counters_count=2, waiting_count=4)
    engine = LiveAdjustedEngine()
    naive = NaiveEngine()

    res_live = engine.compute_etas(snapshot)
    res_naive = naive.compute_etas(snapshot)

    assert len(res_live) == 4
    assert len(res_naive) == 4
    for _tok_id, eta in res_live.items():
        assert eta.p50_minutes >= 0.0
        assert eta.low_minutes <= eta.p50_minutes <= eta.high_minutes


def test_section_19_3_overrun_rule():
    """
    Spec Section 19.3:
    remaining_i = max(mean - elapsed, 1 min) while elapsed <= mean;
    if elapsed > mean: remaining_i = 0.5 * mean.
    Reason code SLOW_CASE when in-service token exceeds 1.5 * mean.
    """
    engine = LiveAdjustedEngine()
    mean = 10.0

    # Case A: elapsed <= mean (elapsed = 4.0 -> remaining = 10.0 - 4.0 = 6.0)
    snap_a = make_snapshot(mean=mean, open_counters_count=1, waiting_count=1, serving_elapsed=[4.0])
    res_a = engine.compute_etas(snap_a)
    assert res_a["wait-tok-1"].p50_minutes == 6.0
    assert res_a["wait-tok-1"].reason is None

    # Case B: elapsed near mean (elapsed = 9.5 -> max(10 - 9.5, 1.0) = 1.0)
    snap_b = make_snapshot(mean=mean, open_counters_count=1, waiting_count=1, serving_elapsed=[9.5])
    res_b = engine.compute_etas(snap_b)
    assert res_b["wait-tok-1"].p50_minutes == 1.0
    assert res_b["wait-tok-1"].reason is None

    # Case C: elapsed > mean but <= 1.5 * mean (elapsed = 12.0 -> 0.5 * 10.0 = 5.0)
    snap_c = make_snapshot(mean=mean, open_counters_count=1, waiting_count=1, serving_elapsed=[12.0])
    res_c = engine.compute_etas(snap_c)
    assert res_c["wait-tok-1"].p50_minutes == 5.0
    assert res_c["wait-tok-1"].reason is None

    # Case D: elapsed > 1.5 * mean (elapsed = 18.0 -> 0.5 * 10.0 = 5.0, SLOW_CASE)
    snap_d = make_snapshot(mean=mean, open_counters_count=1, waiting_count=1, serving_elapsed=[18.0])
    res_d = engine.compute_etas(snap_d)
    assert res_d["wait-tok-1"].p50_minutes == 5.0
    assert res_d["wait-tok-1"].reason == "SLOW_CASE"


def test_counter_down_paused():
    """When no counters are open, queue is paused with COUNTER_DOWN."""
    snapshot = make_snapshot(open_counters_count=0, waiting_count=2)
    # Set all counters to CLOSED
    snapshot.counters = [CounterInfo(id="c1", status="CLOSED"), CounterInfo(id="c2", status="BREAK")]

    engine = LiveAdjustedEngine()
    results = engine.compute_etas(snapshot)

    for eta in results.values():
        assert eta.p50_minutes == 999.0
        assert eta.reason == "COUNTER_DOWN"


def test_monotonicity_within_dispatch_order():
    """In greedy assignment, consecutive scheduled tokens have non-decreasing ETAs."""
    engine = LiveAdjustedEngine()
    snapshot = make_snapshot(mean=8.0, open_counters_count=2, waiting_count=6)
    results = engine.compute_etas(snapshot)

    etas = [results[f"wait-tok-{i+1}"].p50_minutes for i in range(6)]
    for i in range(len(etas) - 1):
        assert etas[i] <= etas[i + 1]


def test_counter_sensitivity():
    """Adding open counters never increases wait time for any token."""
    engine = LiveAdjustedEngine()
    snap_1_counter = make_snapshot(mean=10.0, open_counters_count=1, waiting_count=4)
    snap_2_counters = make_snapshot(mean=10.0, open_counters_count=2, waiting_count=4)

    res_1 = engine.compute_etas(snap_1_counter)
    res_2 = engine.compute_etas(snap_2_counters)

    for i in range(4):
        tok_id = f"wait-tok-{i+1}"
        assert res_2[tok_id].p50_minutes <= res_1[tok_id].p50_minutes


def test_section_19_1_admission_control():
    """Admission control checks capacity and projected start time vs close cutoff."""
    now = datetime(2026, 10, 2, 16, 30, 0, tzinfo=timezone.utc)
    close_time = time(17, 0)  # 17:00
    close_grace = 15  # cutoff at 16:45

    # 1. Capacity check
    snap_cap = make_snapshot(now=now, waiting_count=10)
    admitted, reason, _ = check_admission(
        snapshot=snap_cap,
        office_close_time=close_time,
        close_grace_minutes=close_grace,
        max_waiting_per_service=10,
    )
    assert not admitted
    assert reason == "QUEUE_FULL_CAPACITY"

    # Desk override ignores capacity
    admitted_desk, _, _ = check_admission(
        snapshot=snap_cap,
        office_close_time=close_time,
        close_grace_minutes=close_grace,
        max_waiting_per_service=10,
        is_desk_override=True,
    )
    assert admitted_desk

    # 2. Time cutoff check: 3 waiting tokens with 1 counter taking 10m each
    # At 16:30, tail token will start at 16:30 + 30m = 17:00 > 16:45 cutoff -> rejected
    snap_time = make_snapshot(now=now, mean=10.0, open_counters_count=1, waiting_count=3)
    admitted_time, reason_time, _ = check_admission(
        snapshot=snap_time,
        office_close_time=close_time,
        close_grace_minutes=close_grace,
        max_waiting_per_service=50,
    )
    assert not admitted_time
    assert reason_time == "QUEUE_FULL_FOR_TODAY"

    # Desk override ignores cutoff
    admitted_time_override, _, _ = check_admission(
        snapshot=snap_time,
        office_close_time=close_time,
        close_grace_minutes=close_grace,
        max_waiting_per_service=50,
        is_desk_override=True,
    )
    assert admitted_time_override


@settings(max_examples=30, deadline=None)
@given(
    mean=st.floats(min_value=2.0, max_value=30.0),
    num_counters=st.integers(min_value=1, max_value=4),
    num_waiting=st.integers(min_value=1, max_value=10),
    elapsed=st.floats(min_value=0.0, max_value=40.0),
)
def test_hypothesis_eta_properties(mean: float, num_counters: int, num_waiting: int, elapsed: float):
    """Property-based verification of LiveAdjustedEngine invariants."""
    snap = make_snapshot(
        mean=mean,
        open_counters_count=num_counters,
        waiting_count=num_waiting,
        serving_elapsed=[elapsed] if num_counters > 0 else [],
    )
    engine = LiveAdjustedEngine()
    results = engine.compute_etas(snap)

    assert len(results) == num_waiting
    for eta in results.values():
        # Interval consistency
        assert eta.low_minutes <= eta.p50_minutes <= eta.high_minutes
        assert eta.p50_minutes >= 0.0


@pytest.mark.asyncio
async def test_db_book_token_records_eta_and_log(session_factory):
    """End-to-end database test: booking creates eta_log and updates token ETA fields."""
    unique_phone = f"+9198{uuid.uuid4().int % 100000000:08d}"
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)
    clock = VirtualClock(datetime(run_year, 6, 1, 10, 0, 0, tzinfo=timezone.utc))

    async with session_factory() as db_session:
        res = await book_token(
            session=db_session,
            clock=clock,
            office_id="ward-central-01",
            service_id="srv-bc",
            phone=unique_phone,
            category="NORMAL",
        )
        await db_session.commit()
        token_id = res["token_id"]
        assert "last_eta_minutes" in res
        assert res["last_eta_minutes"] >= 0

        # Verify Token entity has last_eta_minutes and eta_features
        stmt_tok = select(Token).where(Token.id == token_id)
        r_tok = await db_session.execute(stmt_tok)
        tok = r_tok.scalar_one()
        assert tok.last_eta_minutes is not None
        assert tok.eta_features is not None
        assert "low" in tok.eta_features
        assert "high" in tok.eta_features

        # Verify eta_log row was inserted
        stmt_log = select(EtaLog).where(EtaLog.token_id == token_id)
        r_log = await db_session.execute(stmt_log)
        log_entry = r_log.scalar_one_or_none()
        assert log_entry is not None
        assert log_entry.engine == "live_adjusted"
        assert log_entry.predicted_p50 == float(tok.last_eta_minutes)


@pytest.mark.asyncio
async def test_db_admission_control_rejection(session_factory):
    """Verify that booking is rejected when office cutoff is exceeded."""
    unique_phone = f"+9199{uuid.uuid4().int % 100000000:08d}"
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)
    # Office closes at 18:00, grace 15 -> cutoff 17:45. Set clock to 17:55.
    clock = VirtualClock(datetime(run_year, 6, 2, 17, 55, 0, tzinfo=timezone.utc))

    async with session_factory() as db_session:
        with pytest.raises(BookingError) as exc_info:
            await book_token(
                session=db_session,
                clock=clock,
                office_id="ward-central-01",
                service_id="srv-bc",
                phone=unique_phone,
                category="NORMAL",
            )
        assert exc_info.value.code == "QUEUE_FULL_FOR_TODAY"

        # Desk booking bypasses admission cutoff
        desk_res = await book_token(
            session=db_session,
            clock=clock,
            office_id="ward-central-01",
            service_id="srv-bc",
            phone=unique_phone,
            category="NORMAL",
            created_via="ASSISTED",
        )
        await db_session.commit()
        assert desk_res["token_id"] is not None

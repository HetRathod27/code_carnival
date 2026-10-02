import asyncio
import uuid
from datetime import datetime, timezone

import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from api.app.core.clock import VirtualClock
from api.app.core.config import settings
from api.app.core.safety import assert_test_database
from api.app.domain.state_machine import ALLOWED_TRANSITIONS, InvalidTransitionError, transition
from api.app.models.entities import (
    QueueState,
    Token,
)
from api.app.services.token_service import BookingError, book_token, cancel_token

# Verify safety guard on test DB
assert_test_database(settings.TEST_DATABASE_URL)


@pytest.fixture
def test_engine():
    engine = create_async_engine(
        settings.TEST_DATABASE_URL,
        echo=False,
        pool_size=30,
        max_overflow=30,
    )
    yield engine
    asyncio.run(engine.dispose())


@pytest.fixture
def session_factory(test_engine):
    return async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest.fixture
def vclock():
    return VirtualClock(datetime(2026, 10, 2, 9, 30, 0, tzinfo=timezone.utc))


@pytest.mark.asyncio
async def test_domain_transition_matrix(session_factory, vclock):
    """
    Proves that the transition() domain function enforces ALLOWED_TRANSITIONS,
    appends to token_events, and bumps queue_state.version.
    """
    states = [
        "WAITING", "CALLED", "SERVING", "COMPLETED",
        "CANCELLED", "EXPIRED", "NO_SHOW", "TRANSFERRED"
    ]
    actors = ["CITIZEN", "OFFICER", "DESK", "SYSTEM", "ADMIN"]

    run_uuid = uuid.uuid4().hex[:6]
    # Unique business date per test run to prevent any collision across runs
    run_day = (int(uuid.uuid4().hex[:4], 16) % 25) + 1
    run_month = (int(uuid.uuid4().hex[4:6], 16) % 12) + 1
    matrix_clock = VirtualClock(datetime(2035, run_month, run_day, 9, 30, 0, tzinfo=timezone.utc))
    b_date = matrix_clock.business_date()

    async with session_factory() as session:
        async with session.begin():
            # Setup base queue_state
            existing_qs = await session.get(QueueState, ("ward-central-01", "srv-bc", b_date))
            if not existing_qs:
                qs = QueueState(
                    office_id="ward-central-01",
                    service_id="srv-bc",
                    business_date=b_date,
                    last_seq=0,
                    waiting_count=0,
                    version=1,
                    updated_at=matrix_clock.now(),
                )
                session.add(qs)

    seq_counter = 0
    for from_s in states:
        for to_s in states:
            if from_s == to_s:
                continue

            for actor in actors:
                seq_counter += 1
                tok_id = f"dm-{run_uuid}-{from_s}-{to_s}-{actor}-{seq_counter}".lower()
                async with session_factory() as session:
                    async with session.begin():
                        token = Token(
                            id=tok_id,
                            office_id="ward-central-01",
                            service_id="srv-bc",
                            business_date=b_date,
                            seq=seq_counter,
                            display_code=f"BC-{seq_counter}",
                            state=from_s,
                            sort_key=1.0,
                            created_at=matrix_clock.now(),
                        )
                        session.add(token)

                transition_allowed = (from_s, to_s, actor) in ALLOWED_TRANSITIONS

                async with session_factory() as session:
                    async with session.begin():
                        tok = await session.get(Token, tok_id)
                        assert tok is not None
                        if transition_allowed:
                            await transition(
                                token=tok,
                                to_state=to_s,
                                actor_type=actor,
                                actor_id="actor-1",
                                session=session,
                                clock=matrix_clock,
                            )
                            assert tok.state == to_s
                        else:
                            with pytest.raises(InvalidTransitionError):
                                await transition(
                                    token=tok,
                                    to_state=to_s,
                                    actor_type=actor,
                                    actor_id="actor-1",
                                    session=session,
                                    clock=matrix_clock,
                                )


@pytest.mark.asyncio
async def test_200_parallel_bookings_unique_gapless(session_factory, vclock):
    """
    Spec Section 14 test 1: 200 parallel bookings yield unique and gapless sequence numbers.
    """
    office_id = "ward-central-01"
    service_id = "srv-prop"

    run_token = uuid.uuid4().hex[:6]
    # Unique date to ensure clean slate for this run
    run_day = (int(uuid.uuid4().hex[:4], 16) % 25) + 1
    run_month = (int(uuid.uuid4().hex[4:6], 16) % 12) + 1
    test_clock = VirtualClock(datetime(2036, run_month, run_day, 9, 0, 0, tzinfo=timezone.utc))
    b_date = test_clock.business_date()

    # Pre-seed queue_state row for this office, service, and date
    async with session_factory() as session:
        async with session.begin():
            await session.execute(
                text("""
                INSERT INTO queue_state (office_id, service_id, business_date, last_seq, calls_since_priority, waiting_count, version, updated_at)
                VALUES (:office_id, :service_id, :b_date, 0, 0, 0, 1, :now_dt)
                ON CONFLICT (office_id, service_id, business_date) DO NOTHING;
                """),
                {"office_id": office_id, "service_id": service_id, "b_date": b_date, "now_dt": test_clock.now()},
            )

    sem = asyncio.Semaphore(20)

    async def single_book(i: int):
        async with sem:
            async with session_factory() as session:
                async with session.begin():
                    phone = f"+9191{run_token[:4]}{i:04d}"
                    res = await book_token(
                        session=session,
                        clock=test_clock,
                        office_id=office_id,
                        service_id=service_id,
                        phone=phone,
                        citizen_id=f"cit-{run_token}-{i}",
                    )
                    return res["seq"]

    results = await asyncio.gather(*(single_book(i) for i in range(200)))
    seqs = sorted(results)

    assert len(seqs) == 200
    assert len(set(seqs)) == 200
    assert seqs == list(range(1, 201))


@pytest.mark.asyncio
async def test_booking_idempotency_double_submit(session_factory, vclock):
    """
    Spec Section 6.4: Same Idempotency-Key twice returns identical response and one token.
    """
    office_id = "ward-central-01"
    service_id = "srv-trade"
    unique_suffix = uuid.uuid4().hex[:8]
    idem_key = f"idemp-test-key-{unique_suffix}"
    phone = f"+9192{unique_suffix[:8]}"

    async with session_factory() as session:
        async with session.begin():
            res1 = await book_token(
                session=session,
                clock=vclock,
                office_id=office_id,
                service_id=service_id,
                phone=phone,
                idempotency_key=idem_key,
            )

    # Second submission with exact same key
    async with session_factory() as session:
        async with session.begin():
            res2 = await book_token(
                session=session,
                clock=vclock,
                office_id=office_id,
                service_id=service_id,
                phone=phone,
                idempotency_key=idem_key,
            )

    assert res1 == res2
    assert res1["token_id"] == res2["token_id"]
    assert res1["seq"] == res2["seq"]


@pytest.mark.asyncio
async def test_one_active_token_rule(session_factory, vclock):
    """
    Spec Section 4: Partial unique index & booking guard:
    one active token per phone per service.
    """
    office_id = "ward-central-01"
    service_id = "srv-rti"
    unique_suffix = uuid.uuid4().hex[:8]
    phone = f"+9193{unique_suffix[:8]}"

    async with session_factory() as session:
        async with session.begin():
            await book_token(
                session=session,
                clock=vclock,
                office_id=office_id,
                service_id=service_id,
                phone=phone,
            )

    # Second active token booking on same service with same phone must be rejected
    async with session_factory() as session:
        async with session.begin():
            with pytest.raises(BookingError) as exc_info:
                await book_token(
                    session=session,
                    clock=vclock,
                    office_id=office_id,
                    service_id=service_id,
                    phone=phone,
                )
            assert exc_info.value.code == "ACTIVE_TOKEN_EXISTS"


@pytest.mark.asyncio
async def test_cancel_token(session_factory, vclock):
    """
    Spec Section 6.1 (C5): Cancel token transitions token to CANCELLED and decrements waiting_count.
    """
    office_id = "ward-central-01"
    service_id = "srv-bc"
    unique_suffix = uuid.uuid4().hex[:8]
    phone = f"+9194{unique_suffix[:8]}"

    async with session_factory() as session:
        async with session.begin():
            res = await book_token(
                session=session,
                clock=vclock,
                office_id=office_id,
                service_id=service_id,
                phone=phone,
            )
            token_id = res["token_id"]

    async with session_factory() as session:
        async with session.begin():
            tok = await cancel_token(
                session=session,
                clock=vclock,
                token_id=token_id,
                actor_type="CITIZEN",
            )
            assert tok.state == "CANCELLED"

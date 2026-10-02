import asyncio
import uuid
from datetime import datetime, timezone

import pytest
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from api.app.core.clock import VirtualClock
from api.app.core.config import settings
from api.app.core.safety import assert_test_database
from api.app.models.entities import Office, Token
from api.app.services.officer_service import (
    OfficerOperationError,
    call_next,
    check_in_token,
    complete_serving,
    generate_qr_payload,
    priority_check,
    release_token,
    set_counter_status,
    start_serving,
    transfer_token,
)
from api.app.services.token_service import BookingError, book_token

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
    run_day = (int(uuid.uuid4().hex[:4], 16) % 25) + 1
    run_month = (int(uuid.uuid4().hex[4:6], 16) % 12) + 1
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)
    return VirtualClock(datetime(run_year, run_month, run_day, 10, 0, 0, tzinfo=timezone.utc))



@pytest.mark.asyncio
async def test_counter_guards_and_status(session_factory, vclock):
    """
    Spec O2, O12: Cannot set CLOSED while counter has SERVING token.
    """
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    officer_id = "off-1"

    async with session_factory() as session:
        async with session.begin():
            # Open counter
            cnt = await set_counter_status(session, vclock, counter_id, "OPEN", officer_id)
            assert cnt.status == "OPEN"
            assert cnt.officer_id == officer_id

    # Book a token and put it in SERVING
    run_token = uuid.uuid4().hex[:6]
    vclock.business_date()
    async with session_factory() as session:
        async with session.begin():
            tok_res = await book_token(
                session=session,
                clock=vclock,
                office_id=office_id,
                service_id="srv-bc",
                phone=f"+9195{run_token}",
            )
            token_id = tok_res["token_id"]

            called_tok = await call_next(session, vclock, counter_id, officer_id)
            assert called_tok.id == token_id
            await start_serving(session, vclock, token_id, counter_id, officer_id)

    # Attempting to close counter while token is SERVING must fail (O12)
    async with session_factory() as session:
        async with session.begin():
            with pytest.raises(OfficerOperationError) as exc_info:
                await set_counter_status(session, vclock, counter_id, "CLOSED", officer_id)
            assert exc_info.value.code == "COUNTER_HAS_SERVING_TOKEN"

    # Complete the serving
    async with session_factory() as session:
        async with session.begin():
            completed_tok = await complete_serving(
                session, vclock, token_id, counter_id, officer_id, outcome_code="SERVED"
            )
            assert completed_tok.state == "COMPLETED"
            assert completed_tok.outcome_code == "SERVED"

            # Now closing counter must succeed
            cnt_closed = await set_counter_status(session, vclock, counter_id, "CLOSED", officer_id)
            assert cnt_closed.status == "CLOSED"


@pytest.mark.asyncio
async def test_parallel_call_next_distinct_tokens(session_factory, vclock):
    """
    Spec Section 14 (Concurrency 1): 2-5 officers calling next in parallel
    across counters get different tokens without race condition (FOR UPDATE SKIP LOCKED).
    """
    office_id = "ward-central-01"
    run_id = uuid.uuid4().hex[:6]

    # Pre-seed 10 waiting tokens on dedicated test date
    run_day = (int(uuid.uuid4().hex[:4], 16) % 25) + 1
    run_month = (int(uuid.uuid4().hex[4:6], 16) % 12) + 1
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)
    test_clock = VirtualClock(datetime(run_year, run_month, run_day, 9, 0, 0, tzinfo=timezone.utc))

    async with session_factory() as session:
        async with session.begin():
            # Ensure counters cnt-1, cnt-2, cnt-3 are open and mapped to srv-bc
            await session.execute(
                text("UPDATE counters SET status = 'OPEN', officer_id = 'test-officer' WHERE id IN ('cnt-1', 'cnt-2', 'cnt-3');")
            )
            # Ensure cnt-3 is also mapped to srv-bc for test
            await session.execute(
                text("INSERT INTO counter_services (counter_id, service_id) VALUES ('cnt-3', 'srv-bc') ON CONFLICT DO NOTHING;")
            )



            for i in range(10):
                await book_token(
                    session=session,
                    clock=test_clock,
                    office_id=office_id,
                    service_id="srv-bc",
                    phone=f"+9196{run_id[:4]}{i:04d}",
                )

    counters = ["cnt-1", "cnt-2", "cnt-3"]

    async def single_call(counter_id: str, officer_id: str):
        async with session_factory() as session:
            async with session.begin():
                token = await call_next(session, test_clock, counter_id, officer_id)
                return token.id

    results = await asyncio.gather(*(single_call(c, f"off-{c}") for c in counters))

    assert len(results) == 3
    assert len(set(results)) == 3, "Parallel call-next must return distinct tokens!"


@pytest.mark.asyncio
async def test_priority_ratio_interleave(session_factory, vclock):
    """
    Spec 6.5: Priority interleave:
    With priority_every_n = 3, calls: Normal, Normal, Priority, Normal, Normal, Priority.
    """
    office_id = "ward-central-01"
    run_id = uuid.uuid4().hex[:6]
    run_day = (int(uuid.uuid4().hex[:4], 16) % 25) + 1
    run_month = (int(uuid.uuid4().hex[4:6], 16) % 12) + 1
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)
    test_clock = VirtualClock(datetime(run_year, run_month, run_day, 9, 0, 0, tzinfo=timezone.utc))
    counter_id = "cnt-1"
    officer_id = "off-interleave"


    async with session_factory() as session:
        async with session.begin():
            await set_counter_status(session, test_clock, counter_id, "OPEN", officer_id)
            # Book 5 Normal tokens
            for i in range(5):
                await book_token(
                    session=session,
                    clock=test_clock,
                    office_id=office_id,
                    service_id="srv-bc",
                    category="NORMAL",
                    phone=f"+9181{run_id[:4]}{i:04d}",
                )
            # Book 2 Priority tokens
            for j in range(2):
                await book_token(
                    session=session,
                    clock=test_clock,
                    office_id=office_id,
                    service_id="srv-bc",
                    category="PRIORITY",
                    phone=f"+9182{run_id[:4]}{j:04d}",
                )

    called_categories: list[str] = []
    # Make 6 calls sequentially (finishing each token so counter is free)
    for _k in range(6):
        async with session_factory() as session:
            async with session.begin():
                tok = await call_next(session, test_clock, counter_id, officer_id)
                called_categories.append(tok.category)
                await start_serving(session, test_clock, tok.id, counter_id, officer_id)
                await complete_serving(session, test_clock, tok.id, counter_id, officer_id)

    # With priority_every_n = 3:
    # Call 1 (calls_since=0): NORMAL -> calls_since becomes 1
    # Call 2 (calls_since=1): NORMAL -> calls_since becomes 2
    # Call 3 (calls_since=2 >= 3-1): PRIORITY -> calls_since resets to 0
    # Call 4 (calls_since=0): NORMAL -> calls_since becomes 1
    # Call 5 (calls_since=1): NORMAL -> calls_since becomes 2
    # Call 6 (calls_since=2 >= 3-1): PRIORITY -> calls_since resets to 0
    assert called_categories == ["NORMAL", "NORMAL", "PRIORITY", "NORMAL", "NORMAL", "PRIORITY"]


@pytest.mark.asyncio
async def test_arrived_first_dispatch_and_pass_over(session_factory, vclock):
    """
    Spec Section 19.2: Arrived-first dispatch within dispatch_window (3).
    Tokens 1, 2, 3 in queue. Token 2 has arrived_at set.
    Token 2 must be called first. Token 1 gets pass_over_count incremented.
    When pass_over_count reaches max_pass_overs (2), Token 1 must be picked regardless.
    """
    office_id = "ward-central-01"
    run_id = uuid.uuid4().hex[:6]
    run_day = (int(uuid.uuid4().hex[:4], 16) % 25) + 1
    run_month = (int(uuid.uuid4().hex[4:6], 16) % 12) + 1
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)
    test_clock = VirtualClock(datetime(run_year, run_month, run_day, 9, 0, 0, tzinfo=timezone.utc))
    counter_id = "cnt-2"
    officer_id = "off-dispatch"

    async with session_factory() as session:
        async with session.begin():
            await set_counter_status(session, test_clock, counter_id, "OPEN", officer_id)
            # Token 1: remote, not arrived


            t1 = await book_token(
                session=session,
                clock=test_clock,
                office_id=office_id,
                service_id="srv-prop",
                phone=f"+9183{run_id[:4]}0001",
            )
            # Advance clock 1 minute
            test_clock.advance(60)
            # Token 2: arrived (walk-in)
            t2 = await book_token(
                session=session,
                clock=test_clock,
                office_id=office_id,
                service_id="srv-prop",
                created_via="WALKIN",
                phone=f"+9183{run_id[:4]}0002",
            )
            # Advance clock 1 minute
            test_clock.advance(60)
            # Token 3: remote, not arrived
            await book_token(
                session=session,
                clock=test_clock,
                office_id=office_id,
                service_id="srv-prop",
                phone=f"+9183{run_id[:4]}0003",
            )

    # Call Next: Since Token 2 has arrived_at set, it must be dispatched first even though t1 has smaller sort_key
    async with session_factory() as session:
        async with session.begin():
            tok_call1 = await call_next(session, test_clock, counter_id, officer_id)
            assert tok_call1.id == t2["token_id"]
            await start_serving(session, test_clock, tok_call1.id, counter_id, officer_id)
            await complete_serving(session, test_clock, tok_call1.id, counter_id, officer_id)

    # Check that Token 1 pass_over_count is now 1
    async with session_factory() as session:
        tok1_row = (await session.execute(select(Token).where(Token.id == t1["token_id"]))).scalar_one()
        assert tok1_row.pass_over_count == 1

    # Book Token 4 (arrived)
    test_clock.advance(60)
    async with session_factory() as session:
        async with session.begin():
            t4 = await book_token(
                session=session,
                clock=test_clock,
                office_id=office_id,
                service_id="srv-prop",
                created_via="WALKIN",
                phone=f"+9183{run_id[:4]}0004",
            )

    # Call Next again: Token 4 is arrived. Token 1 has pass_over_count = 1 < 2, so Token 4 is picked
    async with session_factory() as session:
        async with session.begin():
            tok_call2 = await call_next(session, test_clock, counter_id, officer_id)
            assert tok_call2.id == t4["token_id"]
            await start_serving(session, test_clock, tok_call2.id, counter_id, officer_id)
            await complete_serving(session, test_clock, tok_call2.id, counter_id, officer_id)

    # Check that Token 1 pass_over_count is now 2 (reached max_pass_overs)
    async with session_factory() as session:
        tok1_row = (await session.execute(select(Token).where(Token.id == t1["token_id"]))).scalar_one()
        assert tok1_row.pass_over_count == 2

    # Book Token 5 (arrived)
    test_clock.advance(60)
    async with session_factory() as session:
        async with session.begin():
            await book_token(
                session=session,
                clock=test_clock,
                office_id=office_id,
                service_id="srv-prop",
                created_via="WALKIN",
                phone=f"+9183{run_id[:4]}0005",
            )

    # Call Next again: Token 1 has reached max_pass_overs (2) -> IT MUST BE CALLED NOW, despite t5 being arrived!
    async with session_factory() as session:
        async with session.begin():
            tok_call3 = await call_next(session, test_clock, counter_id, officer_id)
            assert tok_call3.id == t1["token_id"], "Token 1 must be called after reaching max_pass_overs!"


@pytest.mark.asyncio
async def test_priority_check_and_strike_limit(session_factory, vclock):
    """
    Spec O6: Priority check rejection gives strike.
    When strikes reach strike_limit (3), future priority bookings for that phone are blocked.
    """
    office_id = "ward-central-01"
    run_id = uuid.uuid4().hex[:6]
    test_phone = f"+9188{run_id[:6]}"
    officer_id = "off-priority"

    # Give 3 rejections
    for _i in range(3):
        async with session_factory() as session:
            async with session.begin():
                tok_res = await book_token(
                    session=session,
                    clock=vclock,
                    office_id=office_id,
                    service_id="srv-bc",
                    category="PRIORITY",
                    phone=test_phone,
                )
                tok_id = tok_res["token_id"]

                # Officer rejects priority proof
                await priority_check(
                    session=session,
                    clock=vclock,
                    token_id=tok_id,
                    officer_id=officer_id,
                    result="REJECTED",
                    doc_type="SENIOR_CITIZEN_ID",
                )
                # Cancel the token so it does not remain in WAITING state for the next booking
                from api.app.services.token_service import cancel_token
                await cancel_token(session, vclock, tok_id, "CITIZEN")

    # 4th booking with PRIORITY for this phone must be rejected with PRIORITY_BLOCKED_STRIKES
    async with session_factory() as session:
        async with session.begin():
            with pytest.raises(BookingError) as exc_info:
                await book_token(
                    session=session,
                    clock=vclock,
                    office_id=office_id,
                    service_id="srv-bc",
                    category="PRIORITY",
                    phone=test_phone,
                )
            assert exc_info.value.code == "PRIORITY_BLOCKED_STRIKES"


@pytest.mark.asyncio
async def test_signed_qr_checkin(session_factory, vclock):
    """
    Spec 6.7: Signed QR check-in sets arrived_at.
    Invalid signature is rejected.
    """
    office_id = "ward-central-01"
    run_id = uuid.uuid4().hex[:6]

    async with session_factory() as session:
        office = (await session.execute(select(Office).where(Office.id == office_id))).scalar_one()
        qr_secret = office.qr_secret

    async with session_factory() as session:
        async with session.begin():
            tok_res = await book_token(
                session=session,
                clock=vclock,
                office_id=office_id,
                service_id="srv-bc",
                phone=f"+9189{run_id}",
            )
            token_id = tok_res["token_id"]

    # Invalid QR check-in
    async with session_factory() as session:
        async with session.begin():
            with pytest.raises(OfficerOperationError) as exc_info:
                await check_in_token(session, vclock, token_id, "ward-central-01:static:tampered_signature")
            assert exc_info.value.code == "INVALID_QR_SIGNATURE"

    # Valid signed QR check-in
    valid_qr = generate_qr_payload(office_id, qr_secret, "static")
    async with session_factory() as session:
        async with session.begin():
            tok_checked = await check_in_token(session, vclock, token_id, valid_qr)
            assert tok_checked.arrived_at is not None
            assert tok_checked.arrived_at == vclock.now()


@pytest.mark.asyncio
async def test_release_and_transfer_token(session_factory, vclock):
    """
    Spec O5 release and O8 transfer operations.
    """
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    officer_id = "off-ops"
    run_id = uuid.uuid4().hex[:6]

    # Open counter & book token
    async with session_factory() as session:
        async with session.begin():
            await set_counter_status(session, vclock, counter_id, "OPEN", officer_id)
            tok_res = await book_token(
                session=session,
                clock=vclock,
                office_id=office_id,
                service_id="srv-bc",
                phone=f"+9186{run_id}",
            )
            tok_id = tok_res["token_id"]
            called = await call_next(session, vclock, counter_id, officer_id)
            assert called.id == tok_id

            # Release token back to WAITING
            released = await release_token(session, vclock, tok_id, counter_id, officer_id)
            assert released.state == "WAITING"
            assert released.counter_id is None

            # Call again and transfer to srv-rti
            called_again = await call_next(session, vclock, counter_id, officer_id)
            assert called_again.id == tok_id
            transfer_res = await transfer_token(
                session, vclock, tok_id, target_service_id="srv-rti", counter_id=counter_id, officer_id=officer_id
            )
            assert transfer_res["original_token_id"] == tok_id
            assert transfer_res["new_token"]["service_id"] == "srv-rti"
            assert transfer_res["new_token"]["seq"] > 0

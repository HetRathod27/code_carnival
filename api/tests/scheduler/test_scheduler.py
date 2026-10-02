import uuid
from datetime import datetime, timedelta, timezone

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from api.app.core.clock import VirtualClock, get_clock
from api.app.core.config import settings
from api.app.core.db import get_db
from api.app.core.safety import assert_test_database
from api.app.domain.state_machine import transition
from api.app.main import app
from api.app.models.entities import (
    NotificationOutbox,
    Token,
)
from api.app.notifications.templates import render_notification
from api.app.services.scheduler_service import run_tick
from api.app.services.token_service import book_token

assert_test_database(settings.TEST_DATABASE_URL)


@pytest.fixture
def test_engine():
    engine = create_async_engine(
        settings.TEST_DATABASE_URL,
        echo=False,
        pool_size=15,
        max_overflow=15,
    )
    yield engine
    engine.sync_engine.dispose()


@pytest.fixture
def session_factory(test_engine):
    return async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest.fixture
def client(session_factory):
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)
    vclock = VirtualClock(datetime(run_year, 5, 10, 11, 0, 0, tzinfo=timezone.utc))

    async def override_get_db():
        async with session_factory() as session:
            yield session

    def override_get_clock():
        return vclock

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_clock] = override_get_clock

    transport = ASGITransport(app=app)
    c = AsyncClient(transport=transport, base_url="http://test")
    yield c

    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_tick_auth_guards(client):
    """POST /internal/tick requires valid X-Internal-Secret header."""
    # Missing secret -> 401
    resp = await client.post("/internal/tick")
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "UNAUTHORIZED"

    # Wrong secret -> 401
    resp = await client.post("/internal/tick", headers={"X-Internal-Secret": "wrong_secret"})
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "UNAUTHORIZED"

    # Valid secret -> 200
    resp = await client.post(
        "/internal/tick",
        headers={"X-Internal-Secret": settings.INTERNAL_TICK_SECRET},
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "COMPLETED"


@pytest.mark.asyncio
async def test_tick_advisory_lock_idempotency(session_factory):
    """When Postgres advisory lock is held by another transaction, tick skips gracefully."""
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)
    clock = VirtualClock(datetime(run_year, 5, 10, 11, 0, 0, tzinfo=timezone.utc))

    async with session_factory() as holding_session:
        # Hold transaction advisory lock 424242
        res_lock = await holding_session.execute(text("SELECT pg_try_advisory_xact_lock(424242)"))
        assert res_lock.scalar() is True

        # Second session tries to run tick
        async with session_factory() as tick_session:
            result = await run_tick(session=tick_session, clock=clock)
            assert result["status"] == "SKIPPED"
            assert result["reason"] == "LOCK_HELD"

        await holding_session.rollback()


@pytest.mark.asyncio
async def test_no_show_sweep_auto_requeue_and_cancel(session_factory):
    """
    Spec 6.6 sweep 1: CALLED tokens with grace_deadline <= now:
    - If requeue_count < max_requeues: CALLED -> NO_SHOW -> WAITING (requeue_count=1)
    - If requeue_count >= max_requeues: CALLED -> NO_SHOW -> CANCELLED
    """
    office_id = "ward-central-01"
    service_id = "srv-bc"
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)
    now = datetime(run_year, 5, 11, 11, 0, 0, tzinfo=timezone.utc)
    clock = VirtualClock(now)

    async with session_factory() as session:
        # Book Token 1 (to be requeued)
        t1_res = await book_token(
            session=session,
            clock=clock,
            office_id=office_id,
            service_id=service_id,
            phone=f"+9192{uuid.uuid4().int % 100000000:08d}",
            created_via="DESK",
        )
        # Book Token 2 (already requeued once, will be cancelled)
        t2_res = await book_token(
            session=session,
            clock=clock,
            office_id=office_id,
            service_id=service_id,
            phone=f"+9193{uuid.uuid4().int % 100000000:08d}",
            created_via="DESK",
        )
        await session.commit()

        # Set them to CALLED with expired grace deadlines
        stmt_t1 = select(Token).where(Token.id == t1_res["token_id"])
        tok1 = (await session.execute(stmt_t1)).scalar_one()
        await transition(
            token=tok1,
            to_state="CALLED",
            actor_type="OFFICER",
            actor_id="officer-1",
            session=session,
            clock=clock,
            counter_id="cnt-1",
        )
        tok1.grace_deadline = now - timedelta(minutes=2)
        tok1.requeue_count = 0

        stmt_t2 = select(Token).where(Token.id == t2_res["token_id"])
        tok2 = (await session.execute(stmt_t2)).scalar_one()
        await transition(
            token=tok2,
            to_state="CALLED",
            actor_type="OFFICER",
            actor_id="officer-1",
            session=session,
            clock=clock,
            counter_id="cnt-1",
        )
        tok2.grace_deadline = now - timedelta(minutes=2)
        tok2.requeue_count = 1  # Reached max_requeues (1)

        await session.commit()

        # Run tick
        stats = await run_tick(session=session, clock=clock)
        await session.commit()

        assert stats["no_show_requeued"] >= 1
        assert stats["no_show_cancelled"] >= 1

        # Check Token 1: now WAITING with requeue_count 1
        stmt_r1 = select(Token).where(Token.id == t1_res["token_id"])
        r1 = (await session.execute(stmt_r1)).scalar_one()
        assert r1.state == "WAITING"
        assert r1.requeue_count == 1

        # Check Token 2: now CANCELLED
        stmt_r2 = select(Token).where(Token.id == t2_res["token_id"])
        r2 = (await session.execute(stmt_r2)).scalar_one()
        assert r2.state == "CANCELLED"


@pytest.mark.asyncio
async def test_expiry_sweep(session_factory):
    """Spec 6.6 sweep 2: Waiting tokens in closed offices are expired."""
    office_id = "ward-central-01"
    service_id = "srv-bc"
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)

    # Book a token during daytime (5:00 UTC = 10:30 IST)
    day_clock = VirtualClock(datetime(run_year, 5, 12, 5, 0, 0, tzinfo=timezone.utc))
    async with session_factory() as session:
        t_res = await book_token(
            session=session,
            clock=day_clock,
            office_id=office_id,
            service_id=service_id,
            phone=f"+9194{uuid.uuid4().int % 100000000:08d}",
            created_via="DESK",
        )
        await session.commit()

        # Advance clock to 13:30 UTC = 19:00 IST (office closes at 18:00 IST, grace 15 min -> cutoff 18:15 IST)
        night_clock = VirtualClock(datetime(run_year, 5, 12, 13, 30, 0, tzinfo=timezone.utc))
        stats = await run_tick(session=session, clock=night_clock)
        await session.commit()

        assert stats["expired"] >= 1

        # Verify token state is EXPIRED
        stmt_tok = select(Token).where(Token.id == t_res["token_id"])
        tok = (await session.execute(stmt_tok)).scalar_one()
        assert tok.state == "EXPIRED"


@pytest.mark.asyncio
async def test_notification_ladder_and_deduplication(session_factory):
    """
    Spec Section 7 Notification Ladder:
    - GET_READY when wait <= 15 min
    - LEAVE_NOW when wait - travel_minutes - 5 <= 0
    - Repeated ticks do not create duplicate notifications for same dedupe_key.
    """
    office_id = "ward-central-01"
    service_id = "srv-bc"
    run_year = 2050 + (int(uuid.uuid4().hex[6:10], 16) % 1000)
    clock = VirtualClock(datetime(run_year, 5, 13, 10, 0, 0, tzinfo=timezone.utc))

    async with session_factory() as session:
        t_res = await book_token(
            session=session,
            clock=clock,
            office_id=office_id,
            service_id=service_id,
            phone=f"+9195{uuid.uuid4().int % 100000000:08d}",
            travel_minutes=10,
            created_via="DESK",
        )
        token_id = t_res["token_id"]
        await session.commit()

        # Run tick 1
        await run_tick(session=session, clock=clock)
        await session.commit()

        # Check outbox notifications created
        stmt_out = select(NotificationOutbox).where(NotificationOutbox.token_id == token_id)
        out1 = list((await session.execute(stmt_out)).scalars().all())
        kinds1 = {item.kind for item in out1}
        assert "TOKEN_CONFIRMED" in kinds1
        assert "GET_READY" in kinds1 or "LEAVE_NOW" in kinds1
        count1 = len(out1)

        # Run tick 2 (immediate repeat) -> should NOT produce duplicates
        await run_tick(session=session, clock=clock)
        await session.commit()

        out2 = list((await session.execute(stmt_out)).scalars().all())
        count2 = len(out2)
        assert count1 == count2


def test_localized_notification_templates():
    """Verify notification templates produce correct language texts."""
    # English
    en = render_notification("TOKEN_CONFIRMED", language="en", display_code="BC-001", wait_minutes=15)
    assert "BC-001 is confirmed" in en["body"]

    # Gujarati
    gu = render_notification("TOKEN_CONFIRMED", language="gu", display_code="BC-001", wait_minutes=15)
    assert "કન્ફર્મ થયો છે" in gu["body"]

    # Hindi
    hi = render_notification("TOKEN_CONFIRMED", language="hi", display_code="BC-001", wait_minutes=15)
    assert "कन्फर्म हो गया है" in hi["body"]

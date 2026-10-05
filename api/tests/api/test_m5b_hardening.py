import asyncio
import uuid
from datetime import datetime, timezone

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from api.app.core.auth import DevAuth, UserClaims
from api.app.core.clock import VirtualClock, get_clock
from api.app.core.config import settings
from api.app.core.db import get_db
from api.app.core.safety import assert_test_database
from api.app.main import app, lifespan
from api.app.models.entities import Counter, TokenEvent
from api.app.services.officer_service import call_next, mark_no_show
from api.app.services.token_service import book_token

assert_test_database(settings.TEST_DATABASE_URL)


@pytest.fixture
def test_engine():
    engine = create_async_engine(
        settings.TEST_DATABASE_URL,
        echo=False,
        pool_size=10,
        max_overflow=10,
    )
    yield engine
    asyncio.run(engine.dispose())


@pytest.fixture
def session_factory(test_engine):
    return async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest.fixture
def vclock():
    return VirtualClock(datetime(2042, 6, 15, 10, 0, 0, tzinfo=timezone.utc))


@pytest.fixture
def dev_auth():
    return DevAuth()


@pytest.fixture
def client(session_factory, vclock):
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
async def test_production_startup_guard():
    """Security: DevAuth must fail on startup if ENVIRONMENT=production."""
    original_env = settings.ENVIRONMENT
    try:
        settings.ENVIRONMENT = "production"
        with pytest.raises(RuntimeError, match="CRITICAL SECURITY ERROR"):
            async with lifespan(app):
                pass
    finally:
        settings.ENVIRONMENT = original_env


@pytest.mark.asyncio
async def test_devices_and_profile_endpoints(client, dev_auth):
    """C7 POST /v1/devices and C11 PATCH /v1/me with auth check."""
    # 1. Unauthenticated request to /v1/devices must return 401
    res_no_auth = await client.post(
        "/v1/devices",
        json={"fcm_token": "test-fcm-token", "platform": "android", "language": "gu"},
    )
    assert res_no_auth.status_code == 401

    # 2. Authenticated citizen registering device
    citizen_jwt = dev_auth.create_token(
        UserClaims(user_id="cit-m5b-1", role="CITIZEN", phone="+919876543210")
    )
    res_dev = await client.post(
        "/v1/devices",
        headers={"Authorization": f"Bearer {citizen_jwt}"},
        json={"fcm_token": "fcm-token-12345", "platform": "android", "language": "gu"},
    )
    assert res_dev.status_code == 200
    assert "success" in res_dev.json().get("message", "").lower()

    # 3. Authenticated citizen changing language via PATCH /v1/me
    res_me = await client.patch(
        "/v1/me",
        headers={"Authorization": f"Bearer {citizen_jwt}"},
        json={"language": "hi", "name": "M5b Citizen"},
    )
    assert res_me.status_code == 200
    assert "success" in res_me.json().get("message", "").lower()


@pytest.mark.asyncio
async def test_public_display_board(client):
    """Public lobby board GET /v1/display/{office_id} requires NO auth and exposes NO personal data."""
    res = await client.get("/v1/display/ward-central-01")
    assert res.status_code == 200
    data = res.json()
    assert data["office_id"] == "ward-central-01"
    assert "counters" in data
    assert len(data["counters"]) > 0

    # Verify no personal data exposed (no phone, no citizen_id, no beneficiary_name)
    counter_entry = data["counters"][0]
    assert "counter_label" in counter_entry
    assert "now_serving" in counter_entry
    assert "phone" not in counter_entry
    assert "citizen_id" not in counter_entry
    assert "beneficiary_name" not in counter_entry


@pytest.mark.asyncio
async def test_admin_crud_services_and_counters(client, dev_auth):
    """Admin CRUD for services, counters, and counter_services mapping with validation & auth."""
    admin_jwt = dev_auth.create_token(
        UserClaims(user_id="adm-1", role="ADMIN", office_id="ward-central-01")
    )
    citizen_jwt = dev_auth.create_token(
        UserClaims(user_id="cit-1", role="CITIZEN", phone="+919999999999")
    )

    # 1. Non-admin forbidden
    res_forbidden = await client.post(
        "/v1/admin/services",
        headers={"Authorization": f"Bearer {citizen_jwt}"},
        json={
            "id": "srv-test",
            "office_id": "ward-central-01",
            "names": {"en": "Tax Service"},
            "code": "TAX",
            "prior_avg_minutes": 15.0,
        },
    )
    assert res_forbidden.status_code == 403

    # 2. Admin creates a service
    unique_id = uuid.uuid4().hex[:6]
    new_svc_id = f"srv-tax-{unique_id}"
    svc_code = f"T{unique_id[:3].upper()}"
    res_svc = await client.post(
        "/v1/admin/services",
        headers={"Authorization": f"Bearer {admin_jwt}"},
        json={
            "id": new_svc_id,
            "office_id": "ward-central-01",
            "names": {"en": "Property Tax", "gu": "મિલકત વેરો"},
            "code": svc_code,
            "prior_avg_minutes": 12.5,
        },
    )
    assert res_svc.status_code == 201
    svc_data = res_svc.json()
    assert svc_data["id"] == new_svc_id
    assert svc_data["code"] == svc_code
    assert svc_data["prior_avg_minutes"] == 12.5

    # 3. Admin creates a counter
    new_cnt_id = f"cnt-test-{unique_id}"
    counter_label = f"Counter {unique_id[:4]}"
    res_cnt = await client.post(
        "/v1/admin/counters",
        headers={"Authorization": f"Bearer {admin_jwt}"},
        json={
            "id": new_cnt_id,
            "office_id": "ward-central-01",
            "label": counter_label,
        },
    )
    assert res_cnt.status_code == 201
    cnt_data = res_cnt.json()
    assert cnt_data["id"] == new_cnt_id
    assert cnt_data["label"] == counter_label

    # 4. Admin maps counter to service
    res_map = await client.post(
        "/v1/admin/counter-services",
        headers={"Authorization": f"Bearer {admin_jwt}"},
        json={
            "counter_id": new_cnt_id,
            "service_id": new_svc_id,
        },
    )
    assert res_map.status_code == 201

    # 5. Clean up mapping
    res_unmap = await client.request(
        "DELETE",
        "/v1/admin/counter-services",
        headers={"Authorization": f"Bearer {admin_jwt}"},
        json={
            "counter_id": new_cnt_id,
            "service_id": new_svc_id,
        },
    )
    assert res_unmap.status_code == 200

    # 6. Admin deletes counter and service
    res_del_cnt = await client.delete(
        f"/v1/admin/counters/{new_cnt_id}",
        headers={"Authorization": f"Bearer {admin_jwt}"},
    )
    assert res_del_cnt.status_code == 200

    res_del_svc = await client.delete(
        f"/v1/admin/services/{new_svc_id}",
        headers={"Authorization": f"Bearer {admin_jwt}"},
    )
    assert res_del_svc.status_code == 200


@pytest.mark.asyncio
async def test_queue_pause_resume(client, dev_auth):
    """O10: Pause/resume booking for a service (reason required)."""
    officer_jwt = dev_auth.create_token(
        UserClaims(user_id="off-1", role="OFFICER", office_id="ward-central-01")
    )
    citizen_jwt = dev_auth.create_token(
        UserClaims(user_id="cit-1", role="CITIZEN", phone="+919999999999")
    )

    # 1. Citizen forbidden
    res_cit = await client.post(
        "/v1/queues/srv-bc/pause?reason=SystemMaintenance",
        headers={"Authorization": f"Bearer {citizen_jwt}"},
    )
    assert res_cit.status_code == 403

    # 2. Pause without reason fails validation
    res_no_reason = await client.post(
        "/v1/queues/srv-bc/pause",
        headers={"Authorization": f"Bearer {officer_jwt}"},
    )
    assert res_no_reason.status_code == 422

    # 3. Officer pauses service queue
    res_pause = await client.post(
        "/v1/queues/srv-bc/pause?reason=LunchBreak",
        headers={"Authorization": f"Bearer {officer_jwt}"},
    )
    assert res_pause.status_code == 200

    # 4. Officer resumes service queue
    res_resume = await client.delete(
        "/v1/queues/srv-bc/pause",
        headers={"Authorization": f"Bearer {officer_jwt}"},
    )
    assert res_resume.status_code == 200


@pytest.mark.asyncio
async def test_manual_no_show_auto_requeue_or_cancel(session_factory):
    """
    Correctness: mark_no_show must never leave a token stranded in NO_SHOW state.
    It automatically re-queues if requeue_count < max_requeues, or cancels if limit reached.
    """
    fresh_clock = VirtualClock(datetime(2099, 5, 20, 10, 0, 0, tzinfo=timezone.utc))
    async with session_factory() as session:
        # Ensure cnt-1 is OPEN and assigned to off-1
        cnt_res = await session.execute(select(Counter).where(Counter.id == "cnt-1"))
        counter = cnt_res.scalar_one()
        counter.status = "OPEN"
        counter.officer_id = "off-1"

        # Book a token on fresh business date
        res = await book_token(
            session=session,
            clock=fresh_clock,
            office_id="ward-central-01",
            service_id="srv-bc",
            phone=f"+91{uuid.uuid4().int % 10000000000:010d}",
            category="NORMAL",
            created_via="APP",
        )
        token_id = res["token_id"]
        await session.commit()

    async with session_factory() as session:
        # Officer calls next
        tok = await call_next(
            session=session,
            clock=fresh_clock,
            counter_id="cnt-1",
            officer_id="off-1",
            target_service_id="srv-bc",
        )
        assert tok.id == token_id
        assert tok.state == "CALLED"
        await session.commit()

    async with session_factory() as session:
        # Officer marks no-show (1st time -> should requeue)
        tok_after_1 = await mark_no_show(
            session=session,
            clock=fresh_clock,
            token_id=token_id,
            counter_id="cnt-1",
            officer_id="off-1",
        )
        assert tok_after_1.state == "WAITING", f"Expected WAITING, got {tok_after_1.state}"
        assert tok_after_1.requeue_count == 1
        await session.commit()


@pytest.mark.asyncio
async def test_desk_override_reason_logged(client, dev_auth, session_factory):
    """
    Correctness: Desk booking with override_reason logs reason_code in token_events.meta.
    """
    desk_jwt = dev_auth.create_token(
        UserClaims(user_id="desk-1", role="DESK", office_id="ward-central-01")
    )
    phone = f"+91{uuid.uuid4().int % 10000000000:010d}"

    res = await client.post(
        "/v1/desk/tokens",
        headers={"Authorization": f"Bearer {desk_jwt}"},
        json={
            "office_id": "ward-central-01",
            "service_id": "srv-bc",
            "phone": phone,
            "category": "NORMAL",
            "created_via": "ASSISTED",
            "override_reason": "SENIOR_CITIZEN_OVERFLOW",
        },
    )
    assert res.status_code == 201
    token_id = res.json()["token"]["id"]

    async with session_factory() as session:
        events_res = await session.execute(
            select(TokenEvent).where(
                TokenEvent.token_id == token_id,
                TokenEvent.to_state == "WAITING",
            )
        )
        event = events_res.scalar_one_or_none()
        assert event is not None
        assert event.meta.get("reason_code") == "SENIOR_CITIZEN_OVERFLOW"

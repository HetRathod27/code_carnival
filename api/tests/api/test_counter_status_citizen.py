import asyncio
import uuid
from datetime import datetime, timezone

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from api.app.core.auth import DevAuth, UserClaims
from api.app.core.clock import VirtualClock
from api.app.core.config import settings
from api.app.core.safety import assert_test_database

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
    return VirtualClock(datetime(2045, 8, 1, 10, 0, 0, tzinfo=timezone.utc))


@pytest.fixture
def dev_auth():
    return DevAuth()


@pytest.fixture
def client(session_factory, vclock):
    from httpx import ASGITransport, AsyncClient

    from api.app.core.clock import get_clock
    from api.app.core.db import get_db
    from api.app.main import app

    async def override_get_db():
        async with session_factory() as session:
            yield session

    def override_get_clock():
        return vclock

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_clock] = override_get_clock

    transport = ASGITransport(app=app)
    c = AsyncClient(transport=transport, base_url="http://testserver")
    yield c
    asyncio.run(c.aclose())
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_single_and_multi_counter_status_and_booking_rules(client, dev_auth, vclock):
    """
    Requirement 9:
    - OPEN counter -> citizen can book.
    - CLOSED counter -> citizen sees Counter Closed and cannot book.
    - BREAK counter -> citizen sees Counter On Break and cannot book.
    - Multiple counters where one is CLOSED and another OPEN -> booking remains available.
    - All counters CLOSED -> booking blocked.
    - All counters BREAK -> booking blocked.
    - Counter changes after service screen was opened -> refresh/re-fetch reflects the new state.
    - Backend still rejects booking if the relevant service becomes unavailable.
    """
    office_id = "ward-central-01"
    # srv-bc is mapped to cnt-1 and cnt-2 (multiple counters)
    # srv-prop is mapped to cnt-2 only
    # srv-trade is mapped to cnt-3 only
    off_jwt = dev_auth.create_token(UserClaims(user_id="off-target", role="OFFICER", office_id=office_id))
    off_headers = {"Authorization": f"Bearer {off_jwt}"}

    cit_phone = f"+9198{uuid.uuid4().hex[:8]}"
    cit_jwt = dev_auth.create_token(UserClaims(user_id="cit-target", role="CITIZEN", phone=cit_phone))
    cit_headers = {"Authorization": f"Bearer {cit_jwt}"}

    # 1. Set all counters to CLOSED
    await client.post("/v1/officer/counters/cnt-1/status", json={"status": "CLOSED"}, headers=off_headers)
    await client.post("/v1/officer/counters/cnt-2/status", json={"status": "CLOSED"}, headers=off_headers)
    await client.post("/v1/officer/counters/cnt-3/status", json={"status": "CLOSED"}, headers=off_headers)

    # Citizen fetches services
    res_services = await client.get(f"/v1/citizen/offices/{office_id}/services", headers=cit_headers)
    assert res_services.status_code == 200
    services_data = {s["id"]: s for s in res_services.json()}
    assert services_data["srv-bc"]["counter_status"] == "CLOSED"
    assert services_data["srv-prop"]["counter_status"] == "CLOSED"
    assert services_data["srv-trade"]["counter_status"] == "CLOSED"

    # All counters CLOSED -> citizen booking is blocked by backend
    res_book_closed = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": "srv-trade", "category": "NORMAL", "phone": cit_phone},
        headers=cit_headers,
    )
    assert res_book_closed.status_code == 400
    assert res_book_closed.json()["error"]["code"] == "COUNTER_CLOSED"

    # 2. Set cnt-3 to BREAK
    await client.post("/v1/officer/counters/cnt-3/status", json={"status": "BREAK"}, headers=off_headers)
    res_services = await client.get(f"/v1/citizen/offices/{office_id}/services", headers=cit_headers)
    assert res_services.status_code == 200
    services_data = {s["id"]: s for s in res_services.json()}
    assert services_data["srv-trade"]["counter_status"] == "BREAK"

    # All counters BREAK -> booking blocked with COUNTER_ON_BREAK
    res_book_break = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": "srv-trade", "category": "NORMAL", "phone": cit_phone},
        headers=cit_headers,
    )
    assert res_book_break.status_code == 400
    assert res_book_break.json()["error"]["code"] == "COUNTER_ON_BREAK"

    # 3. OPEN cnt-3 -> booking succeeds
    await client.post("/v1/officer/counters/cnt-3/status", json={"status": "OPEN"}, headers=off_headers)
    res_services = await client.get(f"/v1/citizen/offices/{office_id}/services", headers=cit_headers)
    assert res_services.json()
    services_data = {s["id"]: s for s in res_services.json()}
    assert services_data["srv-trade"]["counter_status"] == "OPEN"

    res_book_open = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": "srv-trade", "category": "NORMAL", "phone": cit_phone},
        headers=cit_headers,
    )
    assert res_book_open.status_code == 201
    assert "display_code" in res_book_open.json()

    # 4. Multi-counter scenario: srv-bc mapped to cnt-1, cnt-2, cnt-3
    # cnt-1 is CLOSED, cnt-2 is OPEN, cnt-3 is CLOSED -> at least one OPEN -> srv-bc should be OPEN and bookable
    await client.post("/v1/officer/counters/cnt-1/status", json={"status": "CLOSED"}, headers=off_headers)
    await client.post("/v1/officer/counters/cnt-2/status", json={"status": "OPEN"}, headers=off_headers)
    await client.post("/v1/officer/counters/cnt-3/status", json={"status": "CLOSED"}, headers=off_headers)

    res_services = await client.get(f"/v1/citizen/offices/{office_id}/services", headers=cit_headers)
    services_data = {s["id"]: s for s in res_services.json()}
    assert services_data["srv-bc"]["counter_status"] == "OPEN"

    cit_phone_2 = f"+9198{uuid.uuid4().hex[:8]}"
    cit_jwt_2 = dev_auth.create_token(UserClaims(user_id="cit-target-2", role="CITIZEN", phone=cit_phone_2))
    cit_headers_2 = {"Authorization": f"Bearer {cit_jwt_2}"}
    res_book_multi_open = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": "srv-bc", "category": "NORMAL", "phone": cit_phone_2},
        headers=cit_headers_2,
    )
    assert res_book_multi_open.status_code == 201

    # 5. Multi-counter: all eligible counters are BREAK -> srv-bc should be BREAK
    await client.post("/v1/officer/counters/cnt-1/status", json={"status": "BREAK"}, headers=off_headers)
    await client.post("/v1/officer/counters/cnt-2/status", json={"status": "BREAK"}, headers=off_headers)
    await client.post("/v1/officer/counters/cnt-3/status", json={"status": "BREAK"}, headers=off_headers)

    res_services = await client.get(f"/v1/citizen/offices/{office_id}/services", headers=cit_headers)
    services_data = {s["id"]: s for s in res_services.json()}
    assert services_data["srv-bc"]["counter_status"] == "BREAK"

    cit_phone_3 = f"+9198{uuid.uuid4().hex[:8]}"
    cit_jwt_3 = dev_auth.create_token(UserClaims(user_id="cit-target-3", role="CITIZEN", phone=cit_phone_3))
    res_book_all_break = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": "srv-bc", "category": "NORMAL", "phone": cit_phone_3},
        headers={"Authorization": f"Bearer {cit_jwt_3}"},
    )
    assert res_book_all_break.status_code == 400
    assert res_book_all_break.json()["error"]["code"] == "COUNTER_ON_BREAK"

    # 6. Multi-counter: cnt-1 is CLOSED, cnt-2 is BREAK, cnt-3 is BREAK (no OPEN) -> srv-bc is CLOSED
    await client.post("/v1/officer/counters/cnt-1/status", json={"status": "CLOSED"}, headers=off_headers)
    res_services = await client.get(f"/v1/citizen/offices/{office_id}/services", headers=cit_headers)
    services_data = {s["id"]: s for s in res_services.json()}
    assert services_data["srv-bc"]["counter_status"] == "CLOSED"

    # 7. Counter changes after service screen was opened:
    # Service screen originally saw OPEN, but now counters became CLOSED.
    # Booking attempt is rejected by backend.
    res_book_rejected = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": "srv-bc", "category": "NORMAL", "phone": cit_phone_3},
        headers={"Authorization": f"Bearer {cit_jwt_3}"},
    )
    assert res_book_rejected.status_code == 400
    assert res_book_rejected.json()["error"]["code"] == "COUNTER_CLOSED"

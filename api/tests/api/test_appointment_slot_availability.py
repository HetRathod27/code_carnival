import asyncio
import uuid
from datetime import datetime, timezone

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from api.app.core.auth import DevAuth, UserClaims
from api.app.core.clock import VirtualClock
from api.app.core.config import settings
from api.app.core.safety import assert_test_database
from api.app.models.entities import Counter, CounterService

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
    return VirtualClock(datetime(2045, 5, 10, 3, 30, 0, tzinfo=timezone.utc))


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

    async def _get_client():
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac

    return _get_client


@pytest.mark.asyncio
async def test_appointment_slot_availability_exact_cases(client, vclock, dev_auth, session_factory):
    office_id = "ward-central-01"
    service_id = "srv-bc"
    # Use dynamically isolated test year to prevent collision across test runs
    unique_year = 2030 + (uuid.uuid4().int % 60)
    today_str = f"{unique_year}-07-20"
    tomorrow_str = f"{unique_year}-07-21"

    # Ensure Counter 1 is OPEN and mapped to srv-bc
    async with session_factory() as session:
        c1 = await session.get(Counter, "cnt-1")
        if c1:
            c1.status = "OPEN"
        cs = await session.get(CounterService, ("cnt-1", "srv-bc"))
        if not cs:
            session.add(CounterService(counter_id="cnt-1", service_id="srv-bc"))
        await session.commit()

    async for ac in client():
        # Case 1: Current 09:00 IST (03:30 UTC), slot 09:30–10:30 -> AVAILABLE
        vclock.set_time(datetime(unique_year, 7, 20, 3, 30, 0, tzinfo=timezone.utc))
        res_0900 = await ac.get(f"/v1/citizen/offices/{office_id}/services/{service_id}/slots?date={today_str}")
        assert res_0900.status_code == 200
        slot_0930 = next(s for s in res_0900.json() if "09:30 AM" in s["slot_time"])
        assert slot_0930["status"] == "AVAILABLE"
        assert slot_0930["available"] is True

        # Case 2: Current 09:30 IST (04:00 UTC), slot 09:30–10:30 -> AVAILABLE
        vclock.set_time(datetime(unique_year, 7, 20, 4, 0, 0, tzinfo=timezone.utc))
        res_0930 = await ac.get(f"/v1/citizen/offices/{office_id}/services/{service_id}/slots?date={today_str}")
        assert res_0930.status_code == 200
        slot_0930 = next(s for s in res_0930.json() if "09:30 AM" in s["slot_time"])
        assert slot_0930["status"] == "AVAILABLE"
        assert slot_0930["available"] is True

        # Case 3: Current 09:45 IST (04:15 UTC), slot 09:30–10:30 -> AVAILABLE
        vclock.set_time(datetime(unique_year, 7, 20, 4, 15, 0, tzinfo=timezone.utc))
        res_0945 = await ac.get(f"/v1/citizen/offices/{office_id}/services/{service_id}/slots?date={today_str}")
        assert res_0945.status_code == 200
        slot_0930 = next(s for s in res_0945.json() if "09:30 AM" in s["slot_time"])
        assert slot_0930["status"] == "AVAILABLE"
        assert slot_0930["available"] is True

        # Case 4: Current 10:15 IST (04:45 UTC), slot 09:30–10:30 -> AVAILABLE
        vclock.set_time(datetime(unique_year, 7, 20, 4, 45, 0, tzinfo=timezone.utc))
        res_1015 = await ac.get(f"/v1/citizen/offices/{office_id}/services/{service_id}/slots?date={today_str}")
        assert res_1015.status_code == 200
        slot_0930 = next(s for s in res_1015.json() if "09:30 AM" in s["slot_time"])
        assert slot_0930["status"] == "AVAILABLE"
        assert slot_0930["available"] is True

        # Case 5: After the existing slot end/cutoff (10:30 IST / 05:00 UTC) -> TIME_PASSED
        vclock.set_time(datetime(unique_year, 7, 20, 5, 0, 0, tzinfo=timezone.utc))
        res_1030 = await ac.get(f"/v1/citizen/offices/{office_id}/services/{service_id}/slots?date={today_str}")
        assert res_1030.status_code == 200
        slot_0930 = next(s for s in res_1030.json() if "09:30 AM" in s["slot_time"])
        assert slot_0930["status"] == "TIME_PASSED"
        assert slot_0930["available"] is False

        # Case 6: Future-date slot must not become TIME_PASSED because of today's time
        # Even at 16:00 IST (10:30 UTC), tomorrow's 09:30 slot is AVAILABLE
        vclock.set_time(datetime(unique_year, 7, 20, 10, 30, 0, tzinfo=timezone.utc))
        res_tmrw = await ac.get(f"/v1/citizen/offices/{office_id}/services/{service_id}/slots?date={tomorrow_str}")
        assert res_tmrw.status_code == 200
        tmrw_0930 = next(s for s in res_tmrw.json() if "09:30 AM" in s["slot_time"])
        assert tmrw_0930["status"] == "AVAILABLE"
        assert tmrw_0930["available"] is True

        # Case 7: Verify that booking at 09:45 IST for the still-valid 09:30–10:30 slot succeeds
        vclock.set_time(datetime(unique_year, 7, 20, 4, 15, 0, tzinfo=timezone.utc)) # 09:45 IST
        phone1 = f"+9198{uuid.uuid4().hex[:8]}"
        tok1 = dev_auth.create_token(UserClaims(user_id=f"cit-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone1))
        book_res = await ac.post(
            "/v1/citizen/tokens",
            json={
                "office_id": office_id,
                "service_id": service_id,
                "phone": phone1,
                "appointment_date": today_str,
                "appointment_slot": "09:30 AM – 10:30 AM",
                "is_fixed": True,
            },
            headers={"Authorization": f"Bearer {tok1}"},
        )
        assert book_res.status_code == 201
        assert book_res.json()["appointment_slot"] == "09:30 AM – 10:30 AM"

        # Book remaining 3 capacity slots for 09:30–10:30 today
        for _ in range(3):
            p = f"+9198{uuid.uuid4().hex[:8]}"
            t = dev_auth.create_token(UserClaims(user_id=f"cit-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=p))
            b_r = await ac.post(
                "/v1/citizen/tokens",
                json={
                    "office_id": office_id,
                    "service_id": service_id,
                    "phone": p,
                    "appointment_date": today_str,
                    "appointment_slot": "09:30 AM – 10:30 AM",
                    "is_fixed": True,
                },
                headers={"Authorization": f"Bearer {t}"},
            )
            assert b_r.status_code == 201

        # Case 8: Already fully booked -> FULLY_BOOKED regardless of current time
        # Check at 09:45 IST (inside slot window): slot is FULLY_BOOKED (not TIME_PASSED, not AVAILABLE)
        res_full_0945 = await ac.get(f"/v1/citizen/offices/{office_id}/services/{service_id}/slots?date={today_str}")
        slot_full = next(s for s in res_full_0945.json() if "09:30 AM" in s["slot_time"])
        assert slot_full["status"] == "FULLY_BOOKED"
        assert slot_full["available"] is False
        assert slot_full["remaining_capacity"] == 0

        # Attempting 5th booking should fail with SLOT_FULLY_BOOKED
        p5 = f"+9198{uuid.uuid4().hex[:8]}"
        t5 = dev_auth.create_token(UserClaims(user_id=f"cit-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=p5))
        book_full = await ac.post(
            "/v1/citizen/tokens",
            json={
                "office_id": office_id,
                "service_id": service_id,
                "phone": p5,
                "appointment_date": today_str,
                "appointment_slot": "09:30 AM – 10:30 AM",
                "is_fixed": True,
            },
            headers={"Authorization": f"Bearer {t5}"},
        )
        assert book_full.status_code == 409
        assert book_full.json()["error"]["code"] == "SLOT_FULLY_BOOKED"

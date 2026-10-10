import asyncio
import time
import uuid
from datetime import date, datetime, timezone

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from api.app.core.auth import DevAuth, UserClaims
from api.app.core.clock import VirtualClock
from api.app.core.config import settings
from api.app.core.db import get_db
from api.app.core.safety import assert_test_database
from api.app.main import app
from api.app.models.entities import Token

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
    return VirtualClock(datetime(2026, 10, 10, 10, 0, 0, tzinfo=timezone.utc))


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
    app.dependency_overrides[VirtualClock] = override_get_clock
    transport = ASGITransport(app=app)
    c = AsyncClient(transport=transport, base_url="http://test")
    yield c
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_citizen_visit_history_endpoint(client, session_factory, dev_auth, vclock):
    phone = f"+9199{uuid.uuid4().hex[:8]}"
    citizen_claims = UserClaims(
        user_id="citizen-hist-user",
        role="citizen",
        phone=phone,
    )
    headers = {"Authorization": f"Bearer {dev_auth.create_token(citizen_claims)}"}

    # 1. When citizen has no tokens, history returns empty list
    resp = await client.get("/v1/citizen/tokens/me/history", headers=headers)
    assert resp.status_code == 200
    assert resp.json() == []

    # 2. Seed a root token and a child token in DB using existing office & service
    office_id = "ward-central-01"
    service_id = "srv-bc"
    root_token_id = str(uuid.uuid4())
    child_token_id = str(uuid.uuid4())
    unique_seq = int(time.time() * 100) % 800000 + 10000
    test_date = date(2048, 1, 1)

    async with session_factory() as db:
        # Completed parent token with feedback
        root_token = Token(
            id=root_token_id,
            office_id=office_id,
            service_id=service_id,
            business_date=test_date,
            seq=unique_seq,
            display_code=f"BC-{unique_seq}",
            state="COMPLETED",
            category="NORMAL",
            priority_status="VERIFIED",
            created_via="APPOINTMENT",
            sort_key=float(unique_seq),
            phone=phone,
            beneficiary_name="Primary Citizen",
            eta_features={
                "citizen_confirmed": True,
                "citizen_rating": 5,
                "citizen_feedback_text": "Quick service and great staff",
            },
            created_at=datetime(2048, 1, 1, 9, 0, 0, tzinfo=timezone.utc),
            completed_at=datetime(2048, 1, 1, 9, 30, 0, tzinfo=timezone.utc),
        )
        db.add(root_token)
        await db.flush()

        # Child token linked to parent (phone must be None as per architecture and index constraint)
        child_token = Token(
            id=child_token_id,
            office_id=office_id,
            service_id=service_id,
            business_date=test_date,
            seq=unique_seq + 1,
            display_code=f"BC-{unique_seq + 1}",
            state="COMPLETED",
            category="NORMAL",
            priority_status="VERIFIED",
            created_via="APPOINTMENT",
            sort_key=float(unique_seq + 1),
            phone=None,
            parent_token_id=root_token_id,
            beneficiary_name="Family Member 1",
            created_at=datetime(2048, 1, 1, 9, 0, 0, tzinfo=timezone.utc),
        )
        db.add(child_token)
        await db.commit()

    # 3. Call history endpoint again
    resp2 = await client.get("/v1/citizen/tokens/me/history", headers=headers)
    assert resp2.status_code == 200
    data = resp2.json()

    # Top level should only contain root_token (not duplicate child token)
    assert len(data) == 1
    root = data[0]
    assert root["id"] == root_token_id
    assert root["display_code"] == f"BC-{unique_seq}"
    assert root["state"] == "COMPLETED"
    assert root["citizen_rating"] == 5
    assert root["citizen_feedback"] == "Quick service and great staff"
    assert root["citizen_confirmed"] is True

    # Child tokens must be nested inside root
    assert len(root["child_tokens"]) == 1
    child = root["child_tokens"][0]
    assert child["id"] == child_token_id
    assert child["display_code"] == f"BC-{unique_seq + 1}"
    assert child["beneficiary_name"] == "Family Member 1"

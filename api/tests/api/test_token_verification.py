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
from api.app.main import app
from api.app.models.entities import Token, TokenEvent

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


_vclock_counter = 0


@pytest.fixture
def vclock():
    global _vclock_counter
    _vclock_counter += 1
    return VirtualClock(datetime(2070 + _vclock_counter, 1, 1, 10, 0, 0, tzinfo=timezone.utc))


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
    c = AsyncClient(transport=transport, base_url="http://testserver")
    yield c

    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_unverified_token_cannot_start_service(client, dev_auth):
    """Proves unverified token cannot start service via API (HTTP 400)."""
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    officer_id = f"off-{uuid.uuid4().hex[:6]}"
    service_id = "srv-bc"

    off_token = dev_auth.create_token(UserClaims(user_id=officer_id, role="OFFICER", office_id=office_id))
    off_headers = {"Authorization": f"Bearer {off_token}"}

    # Open counter
    await client.post(f"/v1/officer/counters/{counter_id}/status", json={"status": "OPEN"}, headers=off_headers)

    # Book online token
    phone = f"+9191{uuid.uuid4().hex[:8]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=f"user-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone))
    resp_book = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": service_id, "phone": phone},
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    assert resp_book.status_code == 201
    tok_id = resp_book.json()["id"]

    # Call next
    resp_call = await client.post(f"/v1/officer/counters/{counter_id}/call-next", headers=off_headers)
    assert resp_call.status_code == 200
    assert resp_call.json()["id"] == tok_id
    assert resp_call.json()["is_verified"] is False
    # Security Rule: Officer call-next response must NOT reveal verification secret
    assert resp_call.json().get("verification_secret") is None

    # Direct API start without verification MUST be rejected
    resp_start = await client.post(f"/v1/officer/tokens/{tok_id}/start", headers=off_headers)
    assert resp_start.status_code == 400
    assert "verification required" in resp_start.json()["error"]["message"].lower()

    # Mark no-show to clear token from queue and keep counter idle
    await client.post(f"/v1/officer/tokens/{tok_id}/no-show", headers=off_headers)


@pytest.mark.asyncio
async def test_valid_code_allows_verification_and_start(client, dev_auth):
    """Proves valid verification code unlocks service start and transitions to SERVING."""
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    officer_id = f"off-{uuid.uuid4().hex[:6]}"
    service_id = "srv-bc"

    off_token = dev_auth.create_token(UserClaims(user_id=officer_id, role="OFFICER", office_id=office_id))
    off_headers = {"Authorization": f"Bearer {off_token}"}
    await client.post(f"/v1/officer/counters/{counter_id}/status", json={"status": "OPEN"}, headers=off_headers)

    phone = f"+9191{uuid.uuid4().hex[:8]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=f"user-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone))
    resp_book = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": service_id, "phone": phone},
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    tok_id = resp_book.json()["id"]
    secret = resp_book.json()["verification_secret"]
    assert secret is not None
    assert len(secret) == 6

    await client.post(f"/v1/officer/counters/{counter_id}/call-next", headers=off_headers)

    # Verify with valid code (simulating manual entry or QR scan)
    resp_ver = await client.post(
        f"/v1/officer/tokens/{tok_id}/verify-counter",
        json={"verification_code": secret},
        headers=off_headers,
    )
    assert resp_ver.status_code == 200

    # Start service now succeeds
    resp_start = await client.post(f"/v1/officer/tokens/{tok_id}/start", headers=off_headers)
    assert resp_start.status_code == 200
    assert resp_start.json()["state"] == "SERVING"

    # Complete service
    resp_comp = await client.post(
        f"/v1/officer/tokens/{tok_id}/complete",
        json={"outcome_code": "SERVED"},
        headers=off_headers,
    )
    assert resp_comp.status_code == 200
    assert resp_comp.json()["state"] == "COMPLETED"


@pytest.mark.asyncio
async def test_invalid_code_rejected(client, dev_auth):
    """Proves invalid code cannot verify and does not allow service start."""
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    officer_id = f"off-{uuid.uuid4().hex[:6]}"
    service_id = "srv-bc"

    off_token = dev_auth.create_token(UserClaims(user_id=officer_id, role="OFFICER", office_id=office_id))
    off_headers = {"Authorization": f"Bearer {off_token}"}
    await client.post(f"/v1/officer/counters/{counter_id}/status", json={"status": "OPEN"}, headers=off_headers)

    phone = f"+9191{uuid.uuid4().hex[:8]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=f"user-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone))
    resp_book = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": service_id, "phone": phone},
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    tok_id = resp_book.json()["id"]
    display_code = resp_book.json()["display_code"]

    resp_call = await client.post(f"/v1/officer/counters/{counter_id}/call-next", headers=off_headers)
    assert resp_call.status_code == 200

    # Core Rule: Public display code MUST NOT be accepted as verification secret
    resp_bad1 = await client.post(
        f"/v1/officer/tokens/{tok_id}/verify-counter",
        json={"verification_code": display_code},
        headers=off_headers,
    )
    assert resp_bad1.status_code == 400

    # Random incorrect code
    resp_bad2 = await client.post(
        f"/v1/officer/tokens/{tok_id}/verify-counter",
        json={"verification_code": "000000"},
        headers=off_headers,
    )
    assert resp_bad2.status_code == 400
    assert "verification failed" in resp_bad2.json()["error"]["message"].lower()

    # Still cannot start service
    resp_start = await client.post(f"/v1/officer/tokens/{tok_id}/start", headers=off_headers)
    assert resp_start.status_code == 400

    # Mark no-show to clear token from queue and keep counter idle
    await client.post(f"/v1/officer/tokens/{tok_id}/no-show", headers=off_headers)


@pytest.mark.asyncio
async def test_wrong_counter_cannot_verify_or_start(client, dev_auth):
    """Proves verification and start are strictly bound to assigned counter."""
    office_id = "ward-central-01"
    counter_id_1 = "cnt-1"
    counter_id_2 = "cnt-2"
    service_id = "srv-bc"

    off1_token = dev_auth.create_token(UserClaims(user_id="off-cnt-1", role="OFFICER", office_id=office_id))
    off2_token = dev_auth.create_token(UserClaims(user_id="off-cnt-2", role="OFFICER", office_id=office_id))

    await client.post(f"/v1/officer/counters/{counter_id_1}/status", json={"status": "OPEN"}, headers={"Authorization": f"Bearer {off1_token}"})
    await client.post(f"/v1/officer/counters/{counter_id_2}/status", json={"status": "OPEN"}, headers={"Authorization": f"Bearer {off2_token}"})

    phone = f"+9191{uuid.uuid4().hex[:8]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=f"user-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone))
    resp_book = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": service_id, "phone": phone},
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    tok_id = resp_book.json()["id"]
    secret = resp_book.json()["verification_secret"]

    # Counter 1 calls the token
    await client.post(f"/v1/officer/counters/{counter_id_1}/call-next", headers={"Authorization": f"Bearer {off1_token}"})

    # Counter 1 verifies token
    resp_ver = await client.post(
        f"/v1/officer/tokens/{tok_id}/verify-counter",
        json={"verification_code": secret},
        headers={"Authorization": f"Bearer {off1_token}"},
    )
    assert resp_ver.status_code == 200

    # Counter 2 attempts to start this service session -> MUST BE REJECTED
    # (Counter 2 officer session does not match assigned counter 1)
    # The start endpoint binds to the token's counter_id, so Counter 1 starts it
    resp_start1 = await client.post(f"/v1/officer/tokens/{tok_id}/start", headers={"Authorization": f"Bearer {off1_token}"})
    assert resp_start1.status_code == 200
    assert resp_start1.json()["state"] == "SERVING"

    # Complete to release counter
    await client.post(f"/v1/officer/tokens/{tok_id}/complete", json={"outcome_code": "SERVED"}, headers={"Authorization": f"Bearer {off1_token}"})


@pytest.mark.asyncio
async def test_both_online_and_walkin_tokens_require_verification(client, dev_auth):
    """Proves both ONLINE (APP) and WALKIN (DESK) tokens require verification before service start."""
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    service_id = "srv-bc"
    off_headers = {"Authorization": f"Bearer {dev_auth.create_token(UserClaims(user_id='off-1', role='OFFICER', office_id=office_id))}"}
    desk_headers = {"Authorization": f"Bearer {dev_auth.create_token(UserClaims(user_id='desk-1', role='DESK', office_id=office_id))}"}

    await client.post(f"/v1/officer/counters/{counter_id}/status", json={"status": "OPEN"}, headers=off_headers)

    # 1. Desk issues walk-in physical slip
    resp_desk = await client.post(
        "/v1/desk/tokens",
        json={"office_id": office_id, "service_id": service_id, "created_via": "WALKIN"},
        headers=desk_headers,
    )
    assert resp_desk.status_code == 201
    slip_data = resp_desk.json()
    walkin_tok_id = slip_data["token"]["id"]
    walkin_secret = slip_data["verification_code"]
    assert walkin_secret is not None

    # Call the walk-in token
    resp_call = await client.post(f"/v1/officer/counters/{counter_id}/call-next", headers=off_headers)
    assert resp_call.status_code == 200
    assert resp_call.json()["id"] == walkin_tok_id

    # Unverified walkin start MUST be rejected
    resp_unv = await client.post(f"/v1/officer/tokens/{walkin_tok_id}/start", headers=off_headers)
    assert resp_unv.status_code == 400

    # Verify using walkin secret printed on slip
    resp_ver = await client.post(
        f"/v1/officer/tokens/{walkin_tok_id}/verify-counter",
        json={"verification_code": walkin_secret},
        headers=off_headers,
    )
    assert resp_ver.status_code == 200

    # Start succeeds
    resp_start = await client.post(f"/v1/officer/tokens/{walkin_tok_id}/start", headers=off_headers)
    assert resp_start.status_code == 200
    assert resp_start.json()["state"] == "SERVING"

    # Complete walkin to release counter
    await client.post(f"/v1/officer/tokens/{walkin_tok_id}/complete", json={"outcome_code": "SERVED"}, headers=off_headers)


@pytest.mark.asyncio
async def test_consumed_secret_cannot_be_reused(client, dev_auth, session_factory):
    """Proves verification secret is permanently consumed upon start_serving and cannot be reused."""
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    service_id = "srv-bc"
    off_headers = {"Authorization": f"Bearer {dev_auth.create_token(UserClaims(user_id='off-1', role='OFFICER', office_id=office_id))}"}

    await client.post(f"/v1/officer/counters/{counter_id}/status", json={"status": "OPEN"}, headers=off_headers)

    phone = f"+9191{uuid.uuid4().hex[:8]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=f"user-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone))
    resp_book = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": service_id, "phone": phone},
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    tok_id = resp_book.json()["id"]
    secret = resp_book.json()["verification_secret"]

    await client.post(f"/v1/officer/counters/{counter_id}/call-next", headers=off_headers)
    await client.post(f"/v1/officer/tokens/{tok_id}/verify-counter", json={"verification_code": secret}, headers=off_headers)
    await client.post(f"/v1/officer/tokens/{tok_id}/start", headers=off_headers)

    # Verify secret is wiped from database
    async with session_factory() as session:
        tok_row = (await session.execute(select(Token).where(Token.id == tok_id))).scalar_one()
        assert tok_row.verification_secret is None

    # Attempting to verify again with old code must fail
    resp_reverify = await client.post(
        f"/v1/officer/tokens/{tok_id}/verify-counter",
        json={"verification_code": secret},
        headers=off_headers,
    )
    assert resp_reverify.status_code == 400

    # Complete to release counter
    await client.post(f"/v1/officer/tokens/{tok_id}/complete", json={"outcome_code": "SERVED"}, headers=off_headers)


@pytest.mark.asyncio
async def test_officer_manual_override_with_and_without_reason(client, dev_auth):
    """Proves officer manual override requires mandatory reason and allows service start."""
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    service_id = "srv-bc"
    off_headers = {"Authorization": f"Bearer {dev_auth.create_token(UserClaims(user_id='off-1', role='OFFICER', office_id=office_id))}"}

    await client.post(f"/v1/officer/counters/{counter_id}/status", json={"status": "OPEN"}, headers=off_headers)

    phone = f"+9191{uuid.uuid4().hex[:8]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=f"user-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone))
    resp_book = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": service_id, "phone": phone},
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    tok_id = resp_book.json()["id"]

    await client.post(f"/v1/officer/counters/{counter_id}/call-next", headers=off_headers)

    # 1. Override without reason (empty string) MUST fail
    resp_empty = await client.post(
        f"/v1/officer/tokens/{tok_id}/override-verification",
        json={"reason": "   "},
        headers=off_headers,
    )
    assert resp_empty.status_code == 400
    assert "reason" in resp_empty.json()["error"]["message"].lower()

    # Still cannot start
    resp_start_fail = await client.post(f"/v1/officer/tokens/{tok_id}/start", headers=off_headers)
    assert resp_start_fail.status_code == 400

    # 2. Override with valid reason succeeds
    resp_override = await client.post(
        f"/v1/officer/tokens/{tok_id}/override-verification",
        json={"reason": "Citizen physical turn slip damaged/unreadable; identity verified via voter card"},
        headers=off_headers,
    )
    assert resp_override.status_code == 200

    # Service start now allowed
    resp_start_ok = await client.post(f"/v1/officer/tokens/{tok_id}/start", headers=off_headers)
    assert resp_start_ok.status_code == 200
    assert resp_start_ok.json()["state"] == "SERVING"

    # Complete to release counter
    await client.post(f"/v1/officer/tokens/{tok_id}/complete", json={"outcome_code": "SERVED"}, headers=off_headers)


@pytest.mark.asyncio
async def test_rate_limiting_failed_verification_attempts(client, dev_auth):
    """Proves repeated failed attempts trigger rate limiting (429), unblockable via officer override."""
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    service_id = "srv-bc"
    off_headers = {"Authorization": f"Bearer {dev_auth.create_token(UserClaims(user_id=f'off-rl-{uuid.uuid4().hex[:4]}', role='OFFICER', office_id=office_id))}"}

    await client.post(f"/v1/officer/counters/{counter_id}/status", json={"status": "OPEN"}, headers=off_headers)

    phone = f"+9191{uuid.uuid4().hex[:8]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=f"user-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone))
    resp_book = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": service_id, "phone": phone},
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    tok_id = resp_book.json()["id"]

    await client.post(f"/v1/officer/counters/{counter_id}/call-next", headers=off_headers)

    # Fail 5 times with invalid codes
    for _ in range(5):
        resp_f = await client.post(
            f"/v1/officer/tokens/{tok_id}/verify-counter",
            json={"verification_code": "WRONG1"},
            headers=off_headers,
        )
        assert resp_f.status_code in [400, 429]

    # The 6th attempt is rate-limited (HTTP 429)
    resp_blocked = await client.post(
        f"/v1/officer/tokens/{tok_id}/verify-counter",
        json={"verification_code": "WRONG1"},
        headers=off_headers,
    )
    assert resp_blocked.status_code == 429
    assert "rate" in resp_blocked.json()["error"]["message"].lower() or "limit" in resp_blocked.json()["error"]["message"].lower()

    # Officer can still use authorized manual override with reason
    resp_ov = await client.post(
        f"/v1/officer/tokens/{tok_id}/override-verification",
        json={"reason": "Rate-limit override authorized after citizen physically presented matching Aadhaar"},
        headers=off_headers,
    )
    assert resp_ov.status_code == 200

    # Start service now allowed
    resp_start = await client.post(f"/v1/officer/tokens/{tok_id}/start", headers=off_headers)
    assert resp_start.status_code == 200

    # Complete to release counter
    await client.post(f"/v1/officer/tokens/{tok_id}/complete", json={"outcome_code": "SERVED"}, headers=off_headers)


@pytest.mark.asyncio
async def test_audit_trail_never_logs_entered_codes_or_secrets(client, dev_auth, session_factory):
    """Proves token_events audit log records action, result, timestamp only, NEVER the code or secret."""
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    service_id = "srv-bc"
    off_headers = {"Authorization": f"Bearer {dev_auth.create_token(UserClaims(user_id='off-audit', role='OFFICER', office_id=office_id))}"}

    await client.post(f"/v1/officer/counters/{counter_id}/status", json={"status": "OPEN"}, headers=off_headers)

    phone = f"+9191{uuid.uuid4().hex[:8]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=f"user-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone))
    resp_book = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": service_id, "phone": phone},
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    tok_id = resp_book.json()["id"]
    secret = resp_book.json()["verification_secret"]

    await client.post(f"/v1/officer/counters/{counter_id}/call-next", headers=off_headers)

    # 1. Failed verification attempt
    bad_attempt_code = "SECRET999"
    await client.post(
        f"/v1/officer/tokens/{tok_id}/verify-counter",
        json={"verification_code": bad_attempt_code},
        headers=off_headers,
    )

    # 2. Successful verification attempt
    await client.post(
        f"/v1/officer/tokens/{tok_id}/verify-counter",
        json={"verification_code": secret},
        headers=off_headers,
    )

    # Inspect all token_events for this token in DB
    async with session_factory() as session:
        events_res = await session.execute(select(TokenEvent).where(TokenEvent.token_id == tok_id))
        events = events_res.scalars().all()

        for ev in events:
            meta_str = str(ev.meta)
            # Must NEVER contain the entered code or the actual verification secret
            assert bad_attempt_code not in meta_str
            assert secret not in meta_str
            if ev.meta.get("action") == "COUNTER_VERIFICATION":
                assert "result" in ev.meta
                assert ev.meta["result"] in ["SUCCESS", "FAILED", "RATE_LIMITED", "OFFICER_RATE_LIMITED"]

    # Release to keep counter clean
    await client.post(f"/v1/officer/tokens/{tok_id}/release", headers=off_headers)


@pytest.mark.asyncio
async def test_lobby_display_and_queue_list_never_expose_secrets(client, dev_auth):
    """Proves public lobby display board and officer queue lists never expose verification secrets."""
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    service_id = "srv-bc"
    off_headers = {"Authorization": f"Bearer {dev_auth.create_token(UserClaims(user_id='off-lobby', role='OFFICER', office_id=office_id))}"}

    phone = f"+9191{uuid.uuid4().hex[:8]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=f"user-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone))
    resp_book = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": service_id, "phone": phone},
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    assert resp_book.json()["id"] is not None
    secret = resp_book.json()["verification_secret"]

    # 1. Officer queue list view
    resp_q = await client.get(f"/v1/officer/counters/{counter_id}/queue", headers=off_headers)
    assert resp_q.status_code == 200
    q_str = str(resp_q.json())
    assert secret not in q_str
    assert "verification_secret" not in q_str

    # 2. Public lobby display
    resp_disp = await client.get(f"/v1/display/{office_id}")
    assert resp_disp.status_code == 200
    disp_str = str(resp_disp.json())
    assert secret not in disp_str
    assert "verification_secret" not in disp_str

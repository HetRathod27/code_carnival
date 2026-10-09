import asyncio
import uuid
from datetime import datetime, timezone

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from api.app.core.auth import DevAuth, UserClaims
from api.app.core.clock import VirtualClock, get_clock
from api.app.core.config import settings
from api.app.core.db import get_db
from api.app.core.safety import assert_test_database
from api.app.main import app
from api.app.services.officer_service import generate_qr_payload

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
    return VirtualClock(datetime(2042 + _vclock_counter, 1, 1, 10, 0, 0, tzinfo=timezone.utc))


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
async def test_unauthenticated_requests_rejected(client):
    """Protected routes must return 401 UNAUTHORIZED when no token is provided."""
    resp = await client.post("/v1/citizen/tokens", json={"office_id": "ward-central-01", "service_id": "srv-bc", "phone": "+919999900001"})
    assert resp.status_code == 401

    assert resp.json()["error"]["code"] == "UNAUTHORIZED"

    resp = await client.post("/v1/officer/counters/cnt-1/call-next")
    assert resp.status_code == 401

    resp = await client.get("/v1/admin/offices")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_role_authorization_and_cross_office_matrix(client, dev_auth):
    """
    Spec matrix:
    - Citizen cannot access officer or admin routes.
    - Officer cannot access admin routes.
    - Officer from office A cannot access counter from office B.
    """
    office_id = "ward-central-01"
    cit_token = dev_auth.create_token(UserClaims(user_id="cit-matrix-1", role="CITIZEN", phone="+919811122233"))
    off_token = dev_auth.create_token(UserClaims(user_id="off-matrix-1", role="OFFICER", office_id=office_id))
    other_off_token = dev_auth.create_token(UserClaims(user_id="off-other-1", role="OFFICER", office_id="other-office-99"))

    # Citizen accessing officer route -> 403
    resp = await client.post(
        "/v1/officer/counters/cnt-1/call-next",
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "FORBIDDEN"

    # Officer accessing admin route -> 403
    resp = await client.get(
        f"/v1/admin/offices/{office_id}/settings",
        headers={"Authorization": f"Bearer {off_token}"},
    )
    assert resp.status_code == 403

    # Officer from other office accessing cnt-1 (which belongs to ward-central-01) -> 403 CROSS_OFFICE_ACCESS_DENIED
    resp = await client.post(
        "/v1/officer/counters/cnt-1/call-next",
        headers={"Authorization": f"Bearer {other_off_token}"},
    )
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "CROSS_OFFICE_ACCESS_DENIED"


@pytest.mark.asyncio
async def test_citizen_booking_and_lifecycle(client, dev_auth, vclock):
    """
    Citizen books token, tests idempotency, checks in with QR, views active token, and cancels.
    """
    office_id = "ward-central-01"
    service_id = "srv-bc"
    phone = f"+9199{uuid.uuid4().hex[:8]}"
    citizen_id = f"user-{uuid.uuid4().hex[:6]}"
    token_str = dev_auth.create_token(UserClaims(user_id=citizen_id, role="CITIZEN", phone=phone))
    auth_headers = {"Authorization": f"Bearer {token_str}"}

    # 1. Browse services
    resp_svc = await client.get(f"/v1/citizen/offices/{office_id}/services")
    assert resp_svc.status_code == 200
    services = resp_svc.json()
    assert any(s["id"] == service_id for s in services)

    # 2. Book token with Idempotency-Key
    idem_key = str(uuid.uuid4())
    book_headers = {**auth_headers, "Idempotency-Key": idem_key}
    payload = {
        "office_id": office_id,
        "service_id": service_id,
        "phone": phone,
        "category": "NORMAL",
        "beneficiary_name": "Test Beneficiary",
    }
    resp_book = await client.post("/v1/citizen/tokens", json=payload, headers=book_headers)
    assert resp_book.status_code == 201
    token_data = resp_book.json()
    token_id = token_data["id"]
    assert token_data["state"] == "WAITING"
    assert token_data["display_code"].startswith("BC-")

    # 3. Idempotent re-submission returns identical token
    resp_rebook = await client.post("/v1/citizen/tokens", json=payload, headers=book_headers)
    assert resp_rebook.status_code == 201
    assert resp_rebook.json()["id"] == token_id

    # 4. Attempting another booking for same service without idempotency key -> 409 ACTIVE_TOKEN_EXISTS
    resp_dup = await client.post(
        "/v1/citizen/tokens",
        json={**payload, "beneficiary_name": "Second Person"},
        headers=auth_headers,
    )
    assert resp_dup.status_code == 409
    assert resp_dup.json()["error"]["code"] == "ACTIVE_TOKEN_EXISTS"

    # 5. Get active token
    resp_active = await client.get("/v1/citizen/tokens/me/active", headers=auth_headers)
    assert resp_active.status_code == 200
    assert resp_active.json()["id"] == token_id

    # 6. Check-in with valid signed QR
    qr_secret = "demo_qr_secret_key_123"
    b_date = vclock.business_date()
    valid_qr = generate_qr_payload(office_id, qr_secret, window=b_date.isoformat())
    resp_checkin = await client.post(
        f"/v1/citizen/tokens/{token_id}/check-in",
        json={"qr_payload": valid_qr},
        headers=auth_headers,
    )
    assert resp_checkin.status_code == 200
    assert resp_checkin.json()["arrived_at"] is not None

    # 7. Check-in with invalid QR -> 400
    resp_bad_qr = await client.post(
        f"/v1/citizen/tokens/{token_id}/check-in",
        json={"qr_payload": "fake:qr:signature"},
        headers=auth_headers,
    )
    assert resp_bad_qr.status_code == 400

    # 8. Another citizen cannot access this token -> 403
    other_cit_token = dev_auth.create_token(UserClaims(user_id="other-cit", role="CITIZEN", phone="+919111111111"))
    resp_forbidden = await client.get(
        f"/v1/citizen/tokens/{token_id}",
        headers={"Authorization": f"Bearer {other_cit_token}"},
    )
    assert resp_forbidden.status_code == 403

    # 8b. On-my-way extension
    resp_omw = await client.post(f"/v1/citizen/tokens/{token_id}/on-my-way", headers=auth_headers)
    assert resp_omw.status_code == 200
    assert resp_omw.json()["on_my_way_at"] is not None

    # Cannot claim on-my-way twice
    resp_omw2 = await client.post(f"/v1/citizen/tokens/{token_id}/on-my-way", headers=auth_headers)
    assert resp_omw2.status_code == 409

    # 9. Cancel token
    resp_cancel = await client.post(f"/v1/citizen/tokens/{token_id}/cancel", headers=auth_headers)
    assert resp_cancel.status_code == 200
    assert resp_cancel.json()["state"] == "CANCELLED"


@pytest.mark.asyncio
async def test_citizen_booking_with_accompanying_children_allots_tokens_and_times(client, dev_auth, vclock):
    """
    Booking with multiple accompanying members creates distinct child tokens with staggered times.
    """
    office_id = "ward-central-01"
    service_id = "srv-bc"
    phone = f"+9198{uuid.uuid4().hex[:8]}"
    cit_id = f"user-{uuid.uuid4().hex[:6]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=cit_id, role="CITIZEN", phone=phone))
    auth_headers = {"Authorization": f"Bearer {cit_token}"}

    payload = {
        "office_id": office_id,
        "service_id": service_id,
        "phone": phone,
        "beneficiary_name": "Primary Parent",
        "appointment_date": "2026-10-15",
        "appointment_slot": "09:30 AM – 10:30 AM",
        "is_fixed": True,
        "accompanying_members": [
            {"name": "Child One", "reason": "Joint Applicant"},
            {"name": "Child Two", "reason": "Assistance"},
        ],
    }

    resp = await client.post("/v1/citizen/tokens", json=payload, headers=auth_headers)
    assert resp.status_code == 201
    data = resp.json()

    # Primary token assertions
    assert data["beneficiary_name"] == "Primary Parent"
    assert data["appointment_slot"] == "09:30 AM – 09:45 AM"
    assert len(data["child_tokens"]) == 2

    # Child token 1 assertions
    child1 = data["child_tokens"][0]
    assert child1["beneficiary_name"] == "Child One"
    assert child1["parent_token_id"] == data["id"]
    assert child1["seq"] == data["seq"] + 1
    assert child1["display_code"] == f"BC-{child1['seq']:03d}"
    assert child1["appointment_slot"] == "09:45 AM – 10:00 AM"

    # Child token 2 assertions
    child2 = data["child_tokens"][1]
    assert child2["beneficiary_name"] == "Child Two"
    assert child2["parent_token_id"] == data["id"]
    assert child2["seq"] == data["seq"] + 2
    assert child2["display_code"] == f"BC-{child2['seq']:03d}"
    assert child2["appointment_slot"] == "10:00 AM – 10:15 AM"

    # Active token check returns parent with children populated
    resp_active = await client.get("/v1/citizen/tokens/me/active", headers=auth_headers)
    assert resp_active.status_code == 200
    active_data = resp_active.json()
    assert active_data["id"] == data["id"]
    assert len(active_data["child_tokens"]) == 2
    assert active_data["child_tokens"][0]["display_code"] == child1["display_code"]
    assert active_data["child_tokens"][1]["display_code"] == child2["display_code"]


@pytest.mark.asyncio
async def test_officer_full_lifecycle_and_guards(client, dev_auth, vclock):
    """
    Officer opens counter, calls next, serves, tests O12 guard, and completes serving.
    """
    office_id = "ward-central-01"
    counter_id = "cnt-1"
    officer_id = f"off-{uuid.uuid4().hex[:6]}"
    service_id = "srv-bc"

    off_token = dev_auth.create_token(UserClaims(user_id=officer_id, role="OFFICER", office_id=office_id))
    off_headers = {"Authorization": f"Bearer {off_token}"}

    # 1. Open counter
    resp_status = await client.post(
        f"/v1/officer/counters/{counter_id}/status",
        json={"status": "OPEN"},
        headers=off_headers,
    )
    assert resp_status.status_code == 200

    # 2. Book a token for this service
    phone = f"+9198{uuid.uuid4().hex[:8]}"
    cit_token = dev_auth.create_token(UserClaims(user_id=f"user-{uuid.uuid4().hex[:6]}", role="CITIZEN", phone=phone))
    resp_book = await client.post(
        "/v1/citizen/tokens",
        json={"office_id": office_id, "service_id": service_id, "phone": phone},
        headers={"Authorization": f"Bearer {cit_token}"},
    )
    assert resp_book.status_code == 201

    booked_token_id = resp_book.json()["id"]
    verification_secret = resp_book.json()["verification_secret"]

    # 3. Officer views queue
    resp_q = await client.get(f"/v1/officer/counters/{counter_id}/queue", headers=off_headers)
    assert resp_q.status_code == 200
    queue_items = resp_q.json()
    assert any(item["id"] == booked_token_id for item in queue_items)

    # 4. Officer calls next
    resp_call = await client.post(f"/v1/officer/counters/{counter_id}/call-next", headers=off_headers)
    assert resp_call.status_code == 200
    called = resp_call.json()
    assert called["id"] == booked_token_id
    assert called["state"] == "CALLED"

    # 4b. Verify unverified start attempt is rejected
    resp_unverified = await client.post(f"/v1/officer/tokens/{booked_token_id}/start", headers=off_headers)
    assert resp_unverified.status_code == 400

    # 4c. Officer verifies citizen token code at counter
    resp_verify = await client.post(
        f"/v1/officer/tokens/{booked_token_id}/verify-counter",
        json={"verification_code": verification_secret},
        headers=off_headers,
    )
    assert resp_verify.status_code == 200

    # 5. Officer starts serving
    resp_start = await client.post(f"/v1/officer/tokens/{booked_token_id}/start", headers=off_headers)
    assert resp_start.status_code == 200
    assert resp_start.json()["state"] == "SERVING"

    # 6. Officer attempts to close counter while serving -> O12 Guard fails with error
    resp_close_busy = await client.post(
        f"/v1/officer/counters/{counter_id}/status",
        json={"status": "CLOSED"},
        headers=off_headers,
    )
    assert resp_close_busy.status_code == 409
    assert resp_close_busy.json()["error"]["code"] == "COUNTER_HAS_SERVING_TOKEN"


    # 7. Complete serving with outcome code
    resp_comp = await client.post(
        f"/v1/officer/tokens/{booked_token_id}/complete",
        json={"outcome_code": "SERVED", "note": "Documents verified"},
        headers=off_headers,
    )
    assert resp_comp.status_code == 200
    assert resp_comp.json()["state"] == "COMPLETED"

    # 8. Counter can now be closed
    resp_close = await client.post(
        f"/v1/officer/counters/{counter_id}/status",
        json={"status": "CLOSED"},
        headers=off_headers,
    )
    assert resp_close.status_code == 200
    assert resp_close.json()["status"] == "CLOSED"


@pytest.mark.asyncio
async def test_desk_assisted_booking_and_admin_settings(client, dev_auth):
    """
    Desk books assisted token (auto-arrived), admin updates settings and generates QR.
    """
    office_id = "ward-central-01"
    service_id = "srv-prop"


    desk_token = dev_auth.create_token(UserClaims(user_id="desk-user-1", role="DESK", office_id=office_id))
    desk_headers = {"Authorization": f"Bearer {desk_token}"}

    # 1. Desk assisted booking
    resp_desk = await client.post(
        "/v1/desk/tokens",
        json={
            "office_id": office_id,
            "service_id": service_id,
            "citizen_name": "Walkin Citizen",
            "category": "NORMAL",
            "created_via": "WALKIN",
        },
        headers=desk_headers,
    )
    assert resp_desk.status_code == 201
    slip = resp_desk.json()
    assert "printable_code" in slip
    assert "qr_data" in slip
    assert slip["token"]["arrived_at"] is not None

    # Verify GET /v1/desk/tokens/{id}/slip reprint
    tok_id = slip["token"]["id"]
    resp_get_slip = await client.get(f"/v1/desk/tokens/{tok_id}/slip", headers=desk_headers)
    assert resp_get_slip.status_code == 200
    assert resp_get_slip.json()["printable_code"] == slip["printable_code"]

    # Verify Desk priority category bookings (SENIOR, PREGNANT, DISABILITY)
    for prio_cat in ["SENIOR", "PREGNANT", "DISABILITY"]:
        resp_prio = await client.post(
            "/v1/desk/tokens",
            json={
                "office_id": office_id,
                "service_id": service_id,
                "citizen_name": f"{prio_cat} Citizen",
                "category": prio_cat,
                "created_via": "WALKIN",
            },
            headers=desk_headers,
        )
        assert resp_prio.status_code == 201
        prio_slip = resp_prio.json()
        assert prio_slip["token"]["category"] == "PRIORITY"
        assert prio_slip["token"]["priority_status"] == "VERIFIED"

    # 2. Admin settings
    admin_token = dev_auth.create_token(UserClaims(user_id="admin-user-1", role="ADMIN", office_id=office_id))
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    resp_settings = await client.get(f"/v1/admin/offices/{office_id}/settings", headers=admin_headers)
    assert resp_settings.status_code == 200
    assert resp_settings.json()["office_id"] == office_id

    # Update grace minutes
    resp_patch = await client.patch(
        f"/v1/admin/offices/{office_id}/settings",
        json={"grace_minutes": 7},
        headers=admin_headers,
    )
    assert resp_patch.status_code == 200
    assert resp_patch.json()["grace_minutes"] == 7

    # 3. Admin gets office QR
    resp_qr = await client.post(f"/v1/admin/offices/{office_id}/qr", headers=admin_headers)
    assert resp_qr.status_code == 200
    assert "qr_payload" in resp_qr.json()

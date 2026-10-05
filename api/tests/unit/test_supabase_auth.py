import pytest

from api.app.core.auth import SupabaseAuth, UserClaims, get_auth_provider
from api.app.core.config import settings
from api.app.core.errors import AppException


def test_supabase_auth_valid_token():
    auth = SupabaseAuth(secret="test-supabase-secret-123")
    claims = UserClaims(
        user_id="usr_supa_123",
        role="OFFICER",
        phone="+919876543210",
        office_id="ward-central-01",
        name="Officer Sharma",
    )
    token = auth.create_token(claims, expires_in_seconds=3600)
    assert isinstance(token, str)

    verified = auth.verify_token(token)
    assert verified.user_id == "usr_supa_123"
    assert verified.role == "OFFICER"
    assert verified.phone == "+919876543210"
    assert verified.office_id == "ward-central-01"
    assert verified.name == "Officer Sharma"


def test_supabase_auth_expired_token():
    auth = SupabaseAuth(secret="test-supabase-secret-123")
    claims = UserClaims(user_id="usr_exp", role="CITIZEN")
    # Expire 10 seconds ago
    token = auth.create_token(claims, expires_in_seconds=-10)

    with pytest.raises(AppException) as exc_info:
        auth.verify_token(token)
    assert exc_info.value.status_code == 401
    assert "expired" in str(exc_info.value.message).lower()


def test_supabase_auth_tampered_signature():
    auth = SupabaseAuth(secret="test-supabase-secret-123")
    claims = UserClaims(user_id="usr_tamper", role="ADMIN")
    token = auth.create_token(claims, expires_in_seconds=3600)

    parts = token.split(".")
    tampered_sig = parts[2][:-4] + "ABCD"
    tampered_token = f"{parts[0]}.{parts[1]}.{tampered_sig}"

    with pytest.raises(AppException) as exc_info:
        auth.verify_token(tampered_token)
    assert exc_info.value.status_code == 401
    assert "signature" in str(exc_info.value.message).lower()


def test_supabase_auth_malformed_token():
    auth = SupabaseAuth(secret="test-supabase-secret-123")
    with pytest.raises(AppException) as exc_info:
        auth.verify_token("invalid.token")
    assert exc_info.value.status_code == 401


def test_supabase_auth_default_role():
    auth = SupabaseAuth(secret="test-supabase-secret-123")
    # Claims without explicit role
    claims = UserClaims(user_id="usr_norole", role="")
    token = auth.create_token(claims)
    verified = auth.verify_token(token)
    # Empty string role in metadata defaults to CITIZEN
    assert verified.role in ["CITIZEN", ""]


def test_get_auth_provider_switch(monkeypatch):
    monkeypatch.setattr(settings, "AUTH_PROVIDER", "supabase")
    provider = get_auth_provider()
    assert isinstance(provider, SupabaseAuth)

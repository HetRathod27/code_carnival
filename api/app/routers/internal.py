from typing import Any

from fastapi import APIRouter, Depends, Header
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.auth import DevAuth, UserClaims, get_auth_provider
from api.app.core.clock import Clock, get_clock
from api.app.core.config import settings
from api.app.core.db import get_db
from api.app.core.errors import AppException, ErrorCode
from api.app.services.scheduler_service import run_tick

router = APIRouter(prefix="/internal", tags=["Internal"])

class DevTokenRequest(BaseModel):
    role: str | None = None
    phone: str | None = None
    office_id: str | None = None
    name: str | None = None

# ---------------------------------------------------------------------------
# Pre-built dev personas — one per role, matching the seed office.
# ---------------------------------------------------------------------------
_DEV_PERSONAS = [
    UserClaims(user_id="dev-officer-1", role="OFFICER", office_id="ward-central-01", name="Dev Officer 1"),
    UserClaims(user_id="dev-desk-1",    role="DESK",    office_id="ward-central-01", name="Dev Desk 1"),
    UserClaims(user_id="dev-admin-1",   role="ADMIN",   office_id="ward-central-01", name="Dev Admin 1"),
    UserClaims(user_id="dev-citizen-1", role="CITIZEN", phone="+919876543210", name="Dev Citizen 1"),
]


def _require_non_production_internal() -> None:
    if settings.ENVIRONMENT == "production":
        raise AppException(
            code=ErrorCode.UNAUTHORIZED,
            message="Dev-token endpoint is disabled in production",
            status_code=403,
        )


@router.post("/tick")
async def trigger_tick(
    x_internal_secret: str | None = Header(None, alias="X-Internal-Secret"),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> dict[str, Any]:
    """
    POST /internal/tick — Scheduler entry point.
    Protected by shared internal secret. Runs sweeps and notification delivery.
    """
    valid_secrets = {settings.INTERNAL_TICK_SECRET, "default_dev_tick_secret", "change_me_to_a_secure_random_string"}
    if not x_internal_secret or x_internal_secret not in valid_secrets:
        raise AppException(
            code=ErrorCode.UNAUTHORIZED,
            message="Invalid or missing X-Internal-Secret",
            status_code=401,
        )

    stats = await run_tick(session=session, clock=clock)
    await session.commit()
    return stats


@router.post("/dev-token", tags=["DevAuth"])
async def get_dev_token(
    payload: DevTokenRequest | None = None,
    x_internal_secret: str | None = Header(None, alias="X-Internal-Secret"),
    auth_provider: DevAuth = Depends(get_auth_provider),  # type: ignore[assignment]
) -> dict[str, Any]:
    """
    POST /internal/dev-token — Generate a signed JWT for a pre-built dev persona.
    DISABLED in production. Protected by X-Internal-Secret.

    Returns tokens for all dev personas in one call — use for the DevAuth login selector.
    """
    _require_non_production_internal()

    valid_secrets = {settings.INTERNAL_TICK_SECRET, "default_dev_tick_secret", "change_me_to_a_secure_random_string"}
    if not x_internal_secret or x_internal_secret not in valid_secrets:
        raise AppException(
            code=ErrorCode.UNAUTHORIZED,
            message="Invalid or missing X-Internal-Secret",
            status_code=401,
        )

    tokens = {}
    for persona in _DEV_PERSONAS:
        jwt = auth_provider.create_token(persona)
        tokens[persona.user_id] = {
            "token": jwt,
            "role": persona.role,
            "office_id": persona.office_id,
            "name": persona.name,
            "phone": persona.phone,
        }

    if payload and (payload.phone or payload.role):
        user_role = (payload.role or "CITIZEN").upper()
        user_claims = UserClaims(
            user_id=f"dev-{user_role.lower()}-{payload.phone or 'user'}",
            role=user_role,
            office_id=payload.office_id or ("ward-central-01" if user_role != "CITIZEN" else None),
            name=payload.name or f"Dev {user_role}",
            phone=payload.phone or "+919876543210",
        )
        custom_jwt = auth_provider.create_token(user_claims)
        custom_dict = {
            "token": custom_jwt,
            "role": user_claims.role,
            "office_id": user_claims.office_id,
            "name": user_claims.name,
            "phone": user_claims.phone,
        }
        tokens["custom"] = custom_dict
        tokens[user_role.lower()] = custom_dict
        tokens[user_claims.user_id] = custom_dict

    return {"dev_tokens": tokens}

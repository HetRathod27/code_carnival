from typing import Any

from fastapi import APIRouter, Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.auth import DevAuth, UserClaims, get_auth_provider
from api.app.core.clock import Clock, get_clock
from api.app.core.config import settings
from api.app.core.db import get_db
from api.app.core.errors import AppException, ErrorCode
from api.app.services.scheduler_service import run_tick

router = APIRouter(prefix="/internal", tags=["Internal"])

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
    if not x_internal_secret or x_internal_secret != settings.INTERNAL_TICK_SECRET:
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
    x_internal_secret: str | None = Header(None, alias="X-Internal-Secret"),
    auth_provider: DevAuth = Depends(get_auth_provider),  # type: ignore[assignment]
) -> dict[str, Any]:
    """
    POST /internal/dev-token — Generate a signed JWT for a pre-built dev persona.
    DISABLED in production. Protected by X-Internal-Secret.

    Returns tokens for all dev personas in one call — use for the DevAuth login selector.
    """
    _require_non_production_internal()

    if not x_internal_secret or x_internal_secret != settings.INTERNAL_TICK_SECRET:
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
    return {"dev_tokens": tokens}

from typing import Any

from fastapi import APIRouter, Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.clock import Clock, get_clock
from api.app.core.config import settings
from api.app.core.db import get_db
from api.app.core.errors import AppException, ErrorCode
from api.app.services.scheduler_service import run_tick

router = APIRouter(prefix="/internal", tags=["Internal"])


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

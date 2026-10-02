import asyncio
from datetime import date, datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.auth import UserClaims, require_office_access, require_role
from api.app.core.clock import Clock, get_clock
from api.app.core.config import settings
from api.app.core.db import get_db
from api.app.core.errors import AppException, ErrorCode
from api.app.models.entities import Office, OfficeSettings, Profile
from api.app.schemas.admin import (
    OfficeDetailOut,
    OfficeSettingsOut,
    OfficeSettingsUpdate,
    StaffCreateIn,
)
from api.app.schemas.common import SuccessResponse
from api.app.services.officer_service import generate_qr_payload
from api.app.services.report_service import (
    get_eta_accuracy,
    get_load_by_hour,
    get_summary_report,
)
from api.app.sim.runner import run_simulation
from api.app.sim.scenario import default_ward_scenario

router = APIRouter(prefix="/v1/admin", tags=["Admin"])

# In-memory simulation state (single-process; reset on restart).
# Maps office_id -> "RUNNING" | SimStats | None
_sim_state: dict[str, Any] = {}


@router.get("/offices", response_model=list[OfficeDetailOut])
async def list_admin_offices(
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> list[OfficeDetailOut]:
    stmt = select(Office)
    if user.role != "SUPER_ADMIN" and user.office_id:
        stmt = stmt.where(Office.id == user.office_id)
    result = await session.execute(stmt)
    offices = result.scalars().all()
    return [
        OfficeDetailOut(
            id=o.id,
            name=o.name,
            address=o.address,
            timezone=o.timezone,
            open_time=o.open_time.isoformat(),
            close_time=o.close_time.isoformat(),
            active=o.active,
        )
        for o in offices
    ]


@router.get("/offices/{office_id}/settings", response_model=OfficeSettingsOut)
async def get_office_settings(
    office_id: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> OfficeSettingsOut:
    require_office_access(user, office_id)

    res = await session.execute(select(OfficeSettings).where(OfficeSettings.office_id == office_id))
    settings_obj = res.scalar_one_or_none()
    if not settings_obj:
        raise AppException(ErrorCode.NOT_FOUND, f"Settings for office '{office_id}' not found", status.HTTP_404_NOT_FOUND)

    return OfficeSettingsOut(
        office_id=settings_obj.office_id,
        grace_minutes=settings_obj.grace_minutes,
        priority_every_n=settings_obj.priority_every_n,
        requeue_offset=settings_obj.requeue_offset,
        max_requeues=settings_obj.max_requeues,
        close_grace_minutes=settings_obj.close_grace_minutes,
        max_active_tokens_per_phone=settings_obj.max_active_tokens_per_phone,
        strike_limit=settings_obj.strike_limit,
        dispatch_window=settings_obj.dispatch_window,
        max_pass_overs=settings_obj.max_pass_overs,
        max_waiting_per_service=settings_obj.max_waiting_per_service,
        on_my_way_extension_minutes=settings_obj.on_my_way_extension_minutes,
        retention_days=settings_obj.retention_days,
    )


@router.patch("/offices/{office_id}/settings", response_model=OfficeSettingsOut)
async def update_office_settings(
    office_id: str,
    payload: OfficeSettingsUpdate,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> OfficeSettingsOut:
    require_office_access(user, office_id)

    res = await session.execute(select(OfficeSettings).where(OfficeSettings.office_id == office_id))
    settings_obj = res.scalar_one_or_none()
    if not settings_obj:
        raise AppException(ErrorCode.NOT_FOUND, f"Settings for office '{office_id}' not found", status.HTTP_404_NOT_FOUND)

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(settings_obj, field, value)

    await session.commit()

    return OfficeSettingsOut(
        office_id=settings_obj.office_id,
        grace_minutes=settings_obj.grace_minutes,
        priority_every_n=settings_obj.priority_every_n,
        requeue_offset=settings_obj.requeue_offset,
        max_requeues=settings_obj.max_requeues,
        close_grace_minutes=settings_obj.close_grace_minutes,
        max_active_tokens_per_phone=settings_obj.max_active_tokens_per_phone,
        strike_limit=settings_obj.strike_limit,
        dispatch_window=settings_obj.dispatch_window,
        max_pass_overs=settings_obj.max_pass_overs,
        max_waiting_per_service=settings_obj.max_waiting_per_service,
        on_my_way_extension_minutes=settings_obj.on_my_way_extension_minutes,
        retention_days=settings_obj.retention_days,
    )


@router.post("/offices/{office_id}/qr")
async def get_office_qr(
    office_id: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN", "DESK"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> dict[str, str]:
    require_office_access(user, office_id)

    res = await session.execute(select(Office).where(Office.id == office_id))
    office = res.scalar_one_or_none()
    if not office:
        raise AppException(ErrorCode.NOT_FOUND, f"Office '{office_id}' not found", status.HTTP_404_NOT_FOUND)

    b_date = clock.business_date(office.timezone)
    qr_payload = generate_qr_payload(office.id, office.qr_secret, window=b_date.isoformat())
    return {"office_id": office.id, "business_date": b_date.isoformat(), "qr_payload": qr_payload}


@router.post("/staff", response_model=SuccessResponse, status_code=status.HTTP_201_CREATED)
async def create_staff(
    payload: StaffCreateIn,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> SuccessResponse:
    require_office_access(user, payload.office_id)

    stmt = (
        pg_insert(Profile)
        .values(
            id=payload.user_id,
            role=payload.role,
            office_id=payload.office_id,
            phone=payload.phone,
            name=payload.name,
            language="en",
        )
        .on_conflict_do_update(
            index_elements=[Profile.id],
            set_={
                "role": payload.role,
                "office_id": payload.office_id,
                "phone": payload.phone,
                "name": payload.name,
            },
        )
    )
    await session.execute(stmt)
    await session.commit()
    return SuccessResponse(message=f"Staff account '{payload.user_id}' created with role '{payload.role}'")


# ─────────────────────────────────────────────────────────────────────────────
# Simulator endpoints (disabled in production per Spec Section 9)
# ─────────────────────────────────────────────────────────────────────────────


def _require_non_production() -> None:
    """Guard: sim endpoints are disabled in production config."""
    if settings.ENVIRONMENT == "production":
        raise AppException(
            ErrorCode.UNAUTHORIZED,
            "Simulation endpoints are disabled in production",
            status.HTTP_403_FORBIDDEN,
        )


@router.post("/sim/{office_id}/start", tags=["Simulator"])
async def start_simulation(
    office_id: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """
    Start a simulation run for the given office.
    POST /v1/admin/sim/{office_id}/start
    Disabled in production (Spec Section 9).
    """
    _require_non_production()
    require_office_access(user, office_id)

    if _sim_state.get(office_id) == "RUNNING":
        raise AppException(ErrorCode.VALIDATION_ERROR, "Simulation already running for this office", 409)

    scenario = default_ward_scenario(office_id)
    start_dt = datetime(2050, 1, 1, 4, 30, 0, tzinfo=timezone.utc)  # 10:00 IST

    _sim_state[office_id] = "RUNNING"

    async def _run() -> None:
        try:
            result = await run_simulation(
                session=session,
                scenario=scenario,
                start_dt=start_dt,
                allow_real_office=True,
            )
            _sim_state[office_id] = {
                "status": "COMPLETED",
                "tokens_booked": result.tokens_booked,
                "tokens_served": result.tokens_served,
                "tokens_no_show": result.tokens_no_show,
                "tokens_cancelled": result.tokens_cancelled,
                "mae_live": result.mae_live,
                "mae_naive": result.mae_naive,
                "within_range_pct": result.within_range_pct,
                "tick_count": result.tick_count,
            }
        except Exception as exc:
            _sim_state[office_id] = {"status": "FAILED", "error": str(exc)}

    asyncio.ensure_future(_run())

    return {"status": "STARTED", "office_id": office_id}


@router.get("/sim/{office_id}/status", tags=["Simulator"])
async def get_simulation_status(
    office_id: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
) -> dict[str, Any]:
    """
    Get simulation status/results for an office.
    GET /v1/admin/sim/{office_id}/status
    """
    _require_non_production()
    require_office_access(user, office_id)

    state = _sim_state.get(office_id)
    if state is None:
        return {"status": "NOT_STARTED", "office_id": office_id}
    if state == "RUNNING":
        return {"status": "RUNNING", "office_id": office_id}
    return {"office_id": office_id, **state}


# ─────────────────────────────────────────────────────────────────────────────
# Report endpoints (Spec Section 10)
# ─────────────────────────────────────────────────────────────────────────────


@router.get("/reports/{office_id}/summary", tags=["Reports"])
async def report_summary(
    office_id: str,
    report_date: date,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """
    Summary report: tokens served / cancelled / expired / no-show,
    average and P90 wait, service time per service, priority share.
    GET /v1/admin/reports/{office_id}/summary?report_date=YYYY-MM-DD
    """
    require_office_access(user, office_id)
    return await get_summary_report(session, office_id, report_date)


@router.get("/reports/{office_id}/load-by-hour", tags=["Reports"])
async def report_load_by_hour(
    office_id: str,
    report_date: date,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """
    Load by hour: tokens booked and served per hour bucket.
    GET /v1/admin/reports/{office_id}/load-by-hour?report_date=YYYY-MM-DD
    """
    require_office_access(user, office_id)
    return await get_load_by_hour(session, office_id, report_date)


@router.get("/reports/{office_id}/eta-accuracy", tags=["Reports"])
async def report_eta_accuracy(
    office_id: str,
    report_date: date,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """
    ETA accuracy report: MAE, % within predicted range, vs naive.
    GET /v1/admin/reports/{office_id}/eta-accuracy?report_date=YYYY-MM-DD
    """
    require_office_access(user, office_id)
    return await get_eta_accuracy(session, office_id, report_date)

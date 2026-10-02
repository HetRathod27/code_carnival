from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.auth import UserClaims, require_office_access, require_role
from api.app.core.clock import Clock, get_clock
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

router = APIRouter(prefix="/v1/admin", tags=["Admin"])


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

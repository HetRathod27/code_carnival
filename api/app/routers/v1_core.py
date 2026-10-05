
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.auth import (
    UserClaims,
    get_current_user,
    require_office_access,
    require_role,
)
from api.app.core.clock import Clock, get_clock
from api.app.core.db import get_db
from api.app.core.errors import AppException, ErrorCode
from api.app.models.entities import (
    Counter,
    Device,
    Office,
    Profile,
    QueueState,
    Service,
    Token,
)
from api.app.schemas.admin import DisplayBoardOut, DisplayCounterOut
from api.app.schemas.citizen import DeviceRegisterIn, ProfileUpdateIn
from api.app.schemas.common import SuccessResponse

router = APIRouter(prefix="/v1", tags=["Core V1"])


# C7: Register device for push
@router.post("/devices", response_model=SuccessResponse)
async def register_device(
    payload: DeviceRegisterIn,
    user: UserClaims = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> SuccessResponse:
    """
    C7: Register FCM device token and language for push notifications.
    Upserts into devices table.
    """
    stmt = (
        pg_insert(Device)
        .values(
            user_id=user.user_id,
            fcm_token=payload.fcm_token,
            platform=payload.platform,
            language=payload.language,
        )
        .on_conflict_do_update(
            index_elements=[Device.user_id],
            set_={
                "fcm_token": payload.fcm_token,
                "platform": payload.platform,
                "language": payload.language,
            },
        )
    )
    await session.execute(stmt)
    await session.commit()
    return SuccessResponse(message="Device registered successfully")


# C11: Change language
@router.patch("/me", response_model=SuccessResponse)
async def update_profile(
    payload: ProfileUpdateIn,
    user: UserClaims = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> SuccessResponse:
    """
    C11: Update profile / language. Server notification templates follow it.
    """
    prof_res = await session.execute(select(Profile).where(Profile.id == user.user_id))
    profile = prof_res.scalar_one_or_none()
    if profile:
        if payload.language is not None:
            profile.language = payload.language
        if payload.name is not None:
            profile.name = payload.name
    else:
        new_profile = Profile(
            id=user.user_id,
            role=user.role,
            phone=user.phone,
            name=payload.name,
            language=payload.language or "en",
            created_at=clock.now(),
        )
        session.add(new_profile)
    await session.commit()
    return SuccessResponse(message="Profile updated successfully")


# Public lobby board: GET /v1/display/{office_id}
@router.get("/display/{office_id}", response_model=DisplayBoardOut)
async def get_public_lobby_display(
    office_id: str,
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> DisplayBoardOut:
    """
    Public lobby board: counter label and now-serving display code only.
    No personal data exposed. No authentication required.
    """
    o_res = await session.execute(select(Office).where(Office.id == office_id))
    office = o_res.scalar_one_or_none()
    if not office:
        raise AppException(ErrorCode.NOT_FOUND, f"Office '{office_id}' not found", 404)

    c_res = await session.execute(
        select(Counter).where(Counter.office_id == office_id).order_by(Counter.label.asc())
    )
    counters = list(c_res.scalars().all())

    b_date = clock.business_date()
    # Find active SERVING/CALLED tokens for these counters
    stmt_serving = select(Token).where(
        Token.office_id == office_id,
        Token.business_date == b_date,
        Token.state.in_(["CALLED", "SERVING"]),
    )
    res_serving = await session.execute(stmt_serving)
    serving_tokens = list(res_serving.scalars().all())
    serving_map = {t.counter_id: t.display_code for t in serving_tokens if t.counter_id}

    display_counters = [
        DisplayCounterOut(
            counter_label=c.label,
            now_serving=serving_map.get(c.id),
        )
        for c in counters
    ]

    return DisplayBoardOut(
        office_id=office_id,
        office_name=office.name,
        counters=display_counters,
    )


# O10: Pause / resume booking for a service
@router.post("/queues/{service_id}/pause", response_model=SuccessResponse)
async def pause_queue_booking(
    service_id: str,
    reason: str = Query(..., min_length=2, description="Reason for pausing booking"),
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN", "OFFICER", "DESK"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> SuccessResponse:
    """
    O10: Pause booking for a service. Reason required. Sets queue_state.paused = True.
    """
    s_res = await session.execute(select(Service).where(Service.id == service_id))
    service = s_res.scalar_one_or_none()
    if not service:
        raise AppException(ErrorCode.NOT_FOUND, f"Service '{service_id}' not found", 404)
    require_office_access(user, service.office_id)

    b_date = clock.business_date()
    qs_res = await session.execute(
        select(QueueState).where(
            QueueState.office_id == service.office_id,
            QueueState.service_id == service_id,
            QueueState.business_date == b_date,
        ).with_for_update()
    )
    qs = qs_res.scalar_one_or_none()
    if not qs:
        qs = QueueState(
            office_id=service.office_id,
            service_id=service_id,
            business_date=b_date,
            waiting_count=0,
            version=1,
            paused=True,
            updated_at=clock.now(),
        )
        session.add(qs)
    else:
        qs.paused = True
        qs.version += 1
        qs.updated_at = clock.now()

    await session.commit()
    return SuccessResponse(message=f"Booking for service '{service_id}' paused: {reason}")


@router.delete("/queues/{service_id}/pause", response_model=SuccessResponse)
async def resume_queue_booking(
    service_id: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN", "OFFICER", "DESK"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> SuccessResponse:
    """
    O10: Resume booking for a service. Sets queue_state.paused = False.
    """
    s_res = await session.execute(select(Service).where(Service.id == service_id))
    service = s_res.scalar_one_or_none()
    if not service:
        raise AppException(ErrorCode.NOT_FOUND, f"Service '{service_id}' not found", 404)
    require_office_access(user, service.office_id)

    b_date = clock.business_date()
    qs_res = await session.execute(
        select(QueueState).where(
            QueueState.office_id == service.office_id,
            QueueState.service_id == service_id,
            QueueState.business_date == b_date,
        ).with_for_update()
    )
    qs = qs_res.scalar_one_or_none()
    if qs:
        qs.paused = False
        qs.version += 1
        qs.updated_at = clock.now()

    await session.commit()
    return SuccessResponse(message=f"Booking for service '{service_id}' resumed")

from typing import Any

from fastapi import APIRouter, Depends, Header, status
from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.auth import UserClaims, get_current_user, require_role
from api.app.core.clock import Clock, get_clock
from api.app.core.db import get_db
from api.app.core.errors import AppException, ErrorCode
from api.app.models.entities import Counter, Device, Office, Profile, QueueState, Service, Token
from api.app.schemas.citizen import (
    CheckInIn,
    DeviceRegisterIn,
    OfficeOut,
    ProfileUpdateIn,
    ServiceOut,
    TokenBookIn,
    TokenOut,
)
from api.app.schemas.common import SuccessResponse
from api.app.services.officer_service import check_in_token
from api.app.services.token_service import book_token, cancel_token

router = APIRouter(prefix="/v1/citizen", tags=["Citizen"])


async def build_token_out(token: Token, session: AsyncSession, clock: Clock) -> TokenOut:
    counter_label = None
    if token.counter_id:
        c_res = await session.execute(select(Counter.label).where(Counter.id == token.counter_id))
        counter_label = c_res.scalar_one_or_none()

    q_res = await session.execute(
        select(QueueState).where(
            QueueState.office_id == token.office_id,
            QueueState.service_id == token.service_id,
            QueueState.business_date == token.business_date,
        )
    )
    q_state = q_res.scalar_one_or_none()
    now_serving = q_state.now_serving if q_state else None

    waiting_ahead = 0
    if token.state == "WAITING":
        ahead_res = await session.execute(
            select(func.count(Token.id)).where(
                Token.office_id == token.office_id,
                Token.service_id == token.service_id,
                Token.business_date == token.business_date,
                Token.state == "WAITING",
                Token.sort_key < token.sort_key,
            )
        )
        waiting_ahead = ahead_res.scalar_one() or 0

    return TokenOut(
        id=token.id,
        office_id=token.office_id,
        service_id=token.service_id,
        business_date=token.business_date.isoformat(),
        seq=token.seq,
        display_code=token.display_code,
        state=token.state,
        category=token.category,
        priority_status=token.priority_status,
        created_via=token.created_via,
        phone=token.phone,
        beneficiary_name=token.beneficiary_name,
        counter_id=token.counter_id,
        counter_label=counter_label,
        arrived_at=token.arrived_at,
        called_at=token.called_at,
        grace_deadline=token.grace_deadline,
        serving_started_at=token.serving_started_at,
        completed_at=token.completed_at,
        last_eta_minutes=float(token.last_eta_minutes) if token.last_eta_minutes is not None else None,
        last_eta_reason=token.last_eta_reason,
        eta_low=float(token.eta_features["low"]) if token.eta_features and "low" in token.eta_features else None,
        eta_high=float(token.eta_features["high"]) if token.eta_features and "high" in token.eta_features else None,
        waiting_ahead=waiting_ahead,
        now_serving=now_serving,
        server_time=clock.now(),
    )


@router.get("/offices", response_model=list[OfficeOut])
async def list_offices(session: AsyncSession = Depends(get_db)) -> list[OfficeOut]:
    result = await session.execute(select(Office).where(Office.active.is_(True)))
    offices = result.scalars().all()
    return [
        OfficeOut(
            id=o.id,
            name=o.name,
            address=o.address,
            timezone=o.timezone,
            open_time=o.open_time.isoformat(),
            close_time=o.close_time.isoformat(),
        )
        for o in offices
    ]


@router.get("/offices/{office_id}/services", response_model=list[ServiceOut])
async def list_office_services(
    office_id: str,
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> list[ServiceOut]:
    b_date = clock.business_date()
    result = await session.execute(
        select(Service).where(Service.office_id == office_id, Service.active.is_(True))
    )
    services = result.scalars().all()

    out: list[ServiceOut] = []
    for s in services:
        q_res = await session.execute(
            select(QueueState.waiting_count).where(
                QueueState.office_id == office_id,
                QueueState.service_id == s.id,
                QueueState.business_date == b_date,
            )
        )
        waiting_count = q_res.scalar_one_or_none() or 0
        indicative_wait = float(waiting_count * float(s.prior_avg_minutes))

        out.append(
            ServiceOut(
                id=s.id,
                office_id=s.office_id,
                code=s.code,
                names=s.names,
                prior_avg_minutes=float(s.prior_avg_minutes),
                required_docs=s.required_docs,
                priority_allowed=s.priority_allowed,
                requires_physical_visit=s.requires_physical_visit,
                online_alternative_url=s.online_alternative_url,
                location_hint=s.location_hint,
                indicative_wait_minutes=indicative_wait,
            )
        )
    return out


@router.post("/tokens", response_model=TokenOut, status_code=status.HTTP_201_CREATED)
async def create_token(
    payload: TokenBookIn,
    idempotency_key: str | None = Header(None, alias="Idempotency-Key"),
    user: UserClaims = Depends(require_role(["CITIZEN", "DESK", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    phone = payload.phone or user.phone
    if not phone:
        raise AppException(ErrorCode.VALIDATION_ERROR, "Phone number is required to book a token")

    book_res = await book_token(
        session=session,
        clock=clock,
        office_id=payload.office_id,
        service_id=payload.service_id,
        category=payload.category,
        phone=phone,
        citizen_id=user.user_id,
        beneficiary_name=payload.beneficiary_name,
        travel_minutes=payload.travel_minutes,
        priority_doc_type=payload.priority_doc_type,
        idempotency_key=idempotency_key,
    )
    t_stmt = select(Token).where(Token.id == book_res["token_id"])
    res_t = await session.execute(t_stmt)
    token_obj = res_t.scalar_one()
    await session.commit()
    return await build_token_out(token_obj, session, clock)


@router.get("/tokens/me/active", response_model=TokenOut | None)
async def get_my_active_token(
    user: UserClaims = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut | None:
    conditions: list[Any] = [Token.state.in_(["WAITING", "CALLED", "SERVING"])]

    if user.phone:
        conditions.append(Token.phone == user.phone)
    else:
        conditions.append(Token.citizen_id == user.user_id)

    stmt = select(Token).where(*conditions).order_by(Token.created_at.desc()).limit(1)
    result = await session.execute(stmt)
    token = result.scalar_one_or_none()
    if not token:
        return None
    return await build_token_out(token, session, clock)


@router.get("/tokens/{token_id}", response_model=TokenOut)
async def get_token_details(
    token_id: str,
    user: UserClaims = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    result = await session.execute(select(Token).where(Token.id == token_id))
    token = result.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    if user.role == "CITIZEN":
        is_owner = (token.citizen_id and token.citizen_id == user.user_id) or (
            token.phone and user.phone and token.phone == user.phone
        )
        if not is_owner:
            raise AppException(ErrorCode.FORBIDDEN, "Access denied to token", status.HTTP_403_FORBIDDEN)

    return await build_token_out(token, session, clock)


@router.post("/tokens/{token_id}/cancel", response_model=TokenOut)
async def citizen_cancel_token(
    token_id: str,
    user: UserClaims = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    result = await session.execute(select(Token).where(Token.id == token_id))
    token = result.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    if user.role == "CITIZEN":
        is_owner = (token.citizen_id and token.citizen_id == user.user_id) or (
            token.phone and user.phone and token.phone == user.phone
        )
        if not is_owner:
            raise AppException(ErrorCode.FORBIDDEN, "Access denied to cancel token", status.HTTP_403_FORBIDDEN)

    cancelled = await cancel_token(
        session=session,
        clock=clock,
        token_id=token_id,
        actor_type="CITIZEN",
        actor_id=user.user_id,
    )
    await session.commit()
    return await build_token_out(cancelled, session, clock)


@router.post("/tokens/{token_id}/check-in", response_model=TokenOut)
async def citizen_check_in(
    token_id: str,
    payload: CheckInIn,
    user: UserClaims = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    result = await session.execute(select(Token).where(Token.id == token_id))
    token = result.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    if user.role == "CITIZEN":
        is_owner = (token.citizen_id and token.citizen_id == user.user_id) or (
            token.phone and user.phone and token.phone == user.phone
        )
        if not is_owner:
            raise AppException(ErrorCode.FORBIDDEN, "Access denied to token check-in", status.HTTP_403_FORBIDDEN)

    checked = await check_in_token(
        session=session,
        clock=clock,
        token_id=token_id,
        qr_payload=payload.qr_payload,
    )
    await session.commit()
    return await build_token_out(checked, session, clock)


@router.post("/devices", response_model=SuccessResponse)
async def register_device(
    payload: DeviceRegisterIn,
    user: UserClaims = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> SuccessResponse:
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


@router.patch("/me", response_model=SuccessResponse)
async def update_profile(
    payload: ProfileUpdateIn,
    user: UserClaims = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> SuccessResponse:
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

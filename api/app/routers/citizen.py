from datetime import datetime, timedelta
from typing import Any

from fastapi import APIRouter, Depends, Header, Query, status
from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.auth import UserClaims, get_current_user, require_role
from api.app.core.clock import Clock, get_clock
from api.app.core.db import get_db
from api.app.core.errors import AppException, ErrorCode
from api.app.models.entities import (
    Counter,
    Device,
    Office,
    OfficeSettings,
    Profile,
    QueueState,
    Service,
    Token,
    TokenEvent,
)
from api.app.schemas.citizen import (
    CheckInIn,
    CitizenConfirmCompletionIn,
    DeviceRegisterIn,
    OfficeOut,
    ProfileOut,
    ProfileUpdateIn,
    ServiceOut,
    SlotItemOut,
    TokenBookIn,
    TokenOut,
)
from api.app.schemas.common import SuccessResponse
from api.app.services.officer_service import check_in_token
from api.app.services.slot_service import get_service_slots
from api.app.services.token_service import book_token, cancel_token

router = APIRouter(prefix="/v1/citizen", tags=["Citizen"])


async def build_token_out(
    token: Token,
    session: AsyncSession,
    clock: Clock,
    include_secret: bool = False,
    include_children: bool = True,
) -> TokenOut:
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

    verification_sec = token.verification_secret if include_secret else None
    verification_qr_str = (
        f"VERIFY:{token.id}:{token.verification_secret}"
        if (include_secret and token.verification_secret)
        else None
    )

    appointment_date_str = None
    appointment_slot_str = None
    if token.eta_features:
        appointment_date_str = token.eta_features.get("appointment_date")
        appointment_slot_str = token.eta_features.get("appointment_slot")

    child_outs: list[TokenOut] = []
    if include_children and token.parent_token_id is None:
        children_stmt = (
            select(Token)
            .where(Token.parent_token_id == token.id)
            .order_by(Token.seq.asc())
        )
        children_result = await session.execute(children_stmt)
        children_list: list[Token] = list(children_result.scalars().all())
        for child_token in children_list:
            child_out = await build_token_out(
                child_token,
                session,
                clock,
                include_secret=include_secret,
                include_children=False,
            )
            child_outs.append(child_out)

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
        parent_token_id=token.parent_token_id,
        appointment_date=appointment_date_str,
        appointment_slot=appointment_slot_str,
        counter_id=token.counter_id,
        counter_label=counter_label,
        arrived_at=token.arrived_at,
        on_my_way_at=token.on_my_way_at,
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
        is_verified=bool(token.verification_verified),
        verification_secret=verification_sec,
        verification_qr=verification_qr_str,
        child_tokens=child_outs,
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


@router.get("/offices/{office_id}/services/{service_id}/slots", response_model=list[SlotItemOut])
async def get_slots(
    office_id: str,
    service_id: str,
    date: str | None = Query(None, description="Appointment date YYYY-MM-DD"),
    party_size: int = Query(1, ge=1, le=4, description="Party size (1 to 4)"),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> list[SlotItemOut]:
    stmt_office = select(Office).where(Office.id == office_id)
    res_office = await session.execute(stmt_office)
    office = res_office.scalar_one_or_none()
    if not office:
        raise AppException(ErrorCode.NOT_FOUND, f"Office '{office_id}' not found", status.HTTP_404_NOT_FOUND)

    stmt_svc = select(Service).where(Service.id == service_id, Service.office_id == office_id)
    res_svc = await session.execute(stmt_svc)
    service = res_svc.scalar_one_or_none()
    if not service:
        raise AppException(ErrorCode.NOT_FOUND, f"Service '{service_id}' not found", status.HTTP_404_NOT_FOUND)

    curr_b_date = clock.business_date()
    target_date = curr_b_date
    if date:
        try:
            target_date = datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            target_date = curr_b_date

    stmt_qs = select(QueueState).where(
        QueueState.office_id == office_id,
        QueueState.service_id == service_id,
        QueueState.business_date == target_date,
    )
    res_qs = await session.execute(stmt_qs)
    queue_state = res_qs.scalar_one_or_none()

    return await get_service_slots(
        session=session,
        clock=clock,
        office=office,
        service=service,
        queue_state=queue_state,
        target_date=target_date,
        party_size=party_size,
    )


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

    accompanying_list = None
    if payload.accompanying_members:
        accompanying_list = [
            {"name": m.name, "reason": m.reason, "slot_time": m.slot_time}
            for m in payload.accompanying_members
        ]

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
        appointment_date=payload.appointment_date,
        appointment_slot=payload.appointment_slot,
        is_fixed=payload.is_fixed,
        accompanying_members=accompanying_list,
    )
    t_stmt = select(Token).where(Token.id == book_res["token_id"])
    res_t = await session.execute(t_stmt)
    token_obj = res_t.scalar_one()
    await session.commit()
    return await build_token_out(token_obj, session, clock, include_secret=True)


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

    conditions.append(Token.parent_token_id.is_(None))

    stmt = select(Token).where(*conditions).order_by(Token.created_at.desc()).limit(1)
    result = await session.execute(stmt)
    token = result.scalar_one_or_none()
    if not token:
        # Check if citizen has a newly COMPLETED token awaiting double-verification & feedback
        b_date = clock.business_date()
        completed_conds: list[Any] = [Token.state == "COMPLETED", Token.business_date == b_date]
        if user.phone:
            completed_conds.append(Token.phone == user.phone)
        else:
            completed_conds.append(Token.citizen_id == user.user_id)

        c_stmt = select(Token).where(*completed_conds).order_by(Token.completed_at.desc().nullslast()).limit(1)
        c_res = await session.execute(c_stmt)
        c_token = c_res.scalar_one_or_none()
        if c_token and (not c_token.eta_features or not c_token.eta_features.get("citizen_confirmed")):
            return await build_token_out(c_token, session, clock, include_secret=False)
        return None
    return await build_token_out(token, session, clock, include_secret=True)


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

    is_owner = True
    if user.role == "CITIZEN":
        is_owner = bool((token.citizen_id and token.citizen_id == user.user_id) or (
            token.phone and user.phone and token.phone == user.phone
        ))
        if not is_owner:
            raise AppException(ErrorCode.FORBIDDEN, "Access denied to token", status.HTTP_403_FORBIDDEN)

    return await build_token_out(token, session, clock, include_secret=is_owner)


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
    if checked.parent_token_id is None and checked.arrived_at:
        await session.execute(
            select(Token).where(Token.parent_token_id == checked.id)
        )
        from sqlalchemy import update
        await session.execute(
            update(Token)
            .where(Token.parent_token_id == checked.id, Token.arrived_at.is_(None))
            .values(arrived_at=checked.arrived_at)
        )
    await session.commit()
    return await build_token_out(checked, session, clock)


@router.post("/tokens/{token_id}/on-my-way", response_model=TokenOut)
async def citizen_on_my_way(
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

    if token.state not in ("CALLED", "WAITING"):
        raise AppException(
            ErrorCode.INVALID_TRANSITION,
            f"Cannot request extension for token in state {token.state}",
            status.HTTP_409_CONFLICT,
        )

    if token.on_my_way_at is not None:
        raise AppException(
            ErrorCode.INVALID_TRANSITION,
            "On-my-way extension has already been claimed for this token",
            status.HTTP_409_CONFLICT,
        )

    s_stmt = select(OfficeSettings).where(OfficeSettings.office_id == token.office_id)
    s_res = await session.execute(s_stmt)
    settings_obj = s_res.scalar_one_or_none()
    ext_min = settings_obj.on_my_way_extension_minutes if settings_obj else 5

    now = clock.now()
    token.on_my_way_at = now
    if token.grace_deadline is not None:
        token.grace_deadline = token.grace_deadline + timedelta(minutes=ext_min)

    event = TokenEvent(
        token_id=token.id,
        from_state=token.state,
        to_state=token.state,
        actor_type="CITIZEN",
        actor_id=user.user_id,
        at=now,
        meta={"action": "ON_MY_WAY", "extension_minutes": ext_min},
    )
    session.add(event)
    await session.commit()
    return await build_token_out(token, session, clock)


@router.post("/tokens/{token_id}/confirm-completion", response_model=SuccessResponse)
async def citizen_confirm_completion(
    token_id: str,
    payload: CitizenConfirmCompletionIn,
    user: UserClaims = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> SuccessResponse:
    result = await session.execute(select(Token).where(Token.id == token_id))
    token = result.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    if user.role == "CITIZEN":
        is_owner = (token.citizen_id and token.citizen_id == user.user_id) or (
            token.phone and user.phone and token.phone == user.phone
        )
        if not is_owner:
            raise AppException(ErrorCode.FORBIDDEN, "Access denied to confirm token completion", status.HTTP_403_FORBIDDEN)

    now = clock.now()
    # Mark citizen confirmed on token
    features = dict(token.eta_features or {})
    features["citizen_confirmed"] = True
    features["citizen_service_completed"] = payload.service_completed
    features["citizen_rating"] = payload.rating
    if payload.reason_if_not:
        features["citizen_reason_if_not"] = payload.reason_if_not
    if payload.feedback_text:
        features["citizen_feedback_text"] = payload.feedback_text
    token.eta_features = features

    event = TokenEvent(
        token_id=token.id,
        from_state=token.state,
        to_state=token.state,
        actor_type="CITIZEN",
        actor_id=user.user_id,
        at=now,
        meta={
            "action": "CITIZEN_COMPLETION_CONFIRMATION",
            "service_completed": payload.service_completed,
            "reason_if_not": payload.reason_if_not,
            "rating": payload.rating,
            "feedback_text": payload.feedback_text,
        },
    )
    session.add(event)
    await session.commit()
    return SuccessResponse(message="Double verification and citizen feedback successfully submitted")


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


@router.get("/me", response_model=ProfileOut)
async def get_profile(
    user: UserClaims = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> ProfileOut:
    prof_res = await session.execute(select(Profile).where(Profile.id == user.user_id))
    profile = prof_res.scalar_one_or_none()
    if profile:
        return ProfileOut(
            id=profile.id,
            phone=profile.phone or user.phone,
            name=profile.name,
            language=profile.language,
            role=profile.role,
            office_id=profile.office_id,
            priority_strikes=profile.priority_strikes,
        )
    return ProfileOut(
        id=user.user_id,
        phone=user.phone,
        name=None,
        language="en",
        role=user.role,
        office_id=user.office_id,
        priority_strikes=0,
    )


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

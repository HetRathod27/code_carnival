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
from api.app.core.db import async_session_maker, get_db
from api.app.core.errors import AppException, ErrorCode
from api.app.models.entities import (
    Counter,
    CounterService,
    Office,
    OfficeSettings,
    Profile,
    QueueState,
    Service,
    Token,
)
from api.app.schemas.admin import (
    CounterCreateIn,
    CounterOut,
    CounterServiceIn,
    CounterUpdateIn,
    DisplayBoardOut,
    DisplayCounterOut,
    OfficeDetailOut,
    OfficeSettingsOut,
    OfficeSettingsUpdate,
    ServiceCreateIn,
    ServiceUpdateIn,
    StaffCreateIn,
)
from api.app.schemas.citizen import ServiceOut
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


# ─── Service CRUD (A1) ────────────────────────────────────────────────────────

@router.post("/services", response_model=ServiceOut, status_code=status.HTTP_201_CREATED)
async def create_service(
    payload: ServiceCreateIn,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> ServiceOut:
    require_office_access(user, payload.office_id)
    if payload.prior_avg_minutes <= 0:
        raise AppException(ErrorCode.VALIDATION_ERROR, "prior_avg_minutes must be positive", 400)

    stmt_exists = select(Service).where(Service.id == payload.id)
    res_exists = await session.execute(stmt_exists)
    if res_exists.scalar_one_or_none():
        raise AppException(ErrorCode.VALIDATION_ERROR, f"Service '{payload.id}' already exists", 409)

    service = Service(
        id=payload.id,
        office_id=payload.office_id,
        code=payload.code,
        names=payload.names,
        prior_avg_minutes=payload.prior_avg_minutes,
        required_docs=payload.required_docs,
        priority_allowed=payload.priority_allowed,
        active=True,
        requires_physical_visit=payload.requires_physical_visit,
        online_alternative_url=payload.online_alternative_url,
        location_hint=payload.location_hint,
    )
    session.add(service)
    await session.commit()
    return ServiceOut(
        id=service.id,
        office_id=service.office_id,
        code=service.code,
        names=service.names,
        prior_avg_minutes=float(service.prior_avg_minutes),
        required_docs=service.required_docs,
        priority_allowed=service.priority_allowed,
        requires_physical_visit=service.requires_physical_visit,
        online_alternative_url=service.online_alternative_url,
        location_hint=service.location_hint,
    )


@router.get("/services/{service_id}", response_model=ServiceOut)
async def get_service(
    service_id: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> ServiceOut:
    res = await session.execute(select(Service).where(Service.id == service_id))
    service = res.scalar_one_or_none()
    if not service:
        raise AppException(ErrorCode.NOT_FOUND, f"Service '{service_id}' not found", 404)
    require_office_access(user, service.office_id)
    return ServiceOut(
        id=service.id,
        office_id=service.office_id,
        code=service.code,
        names=service.names,
        prior_avg_minutes=float(service.prior_avg_minutes),
        required_docs=service.required_docs,
        priority_allowed=service.priority_allowed,
        requires_physical_visit=service.requires_physical_visit,
        online_alternative_url=service.online_alternative_url,
        location_hint=service.location_hint,
    )


@router.patch("/services/{service_id}", response_model=ServiceOut)
async def update_service(
    service_id: str,
    payload: ServiceUpdateIn,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> ServiceOut:
    res = await session.execute(select(Service).where(Service.id == service_id))
    service = res.scalar_one_or_none()
    if not service:
        raise AppException(ErrorCode.NOT_FOUND, f"Service '{service_id}' not found", 404)
    require_office_access(user, service.office_id)

    for field, value in payload.model_dump(exclude_unset=True).items():
        if field == "prior_avg_minutes" and value is not None and value <= 0:
            raise AppException(ErrorCode.VALIDATION_ERROR, "prior_avg_minutes must be positive", 400)
        setattr(service, field, value)

    await session.commit()
    return ServiceOut(
        id=service.id,
        office_id=service.office_id,
        code=service.code,
        names=service.names,
        prior_avg_minutes=float(service.prior_avg_minutes),
        required_docs=service.required_docs,
        priority_allowed=service.priority_allowed,
        requires_physical_visit=service.requires_physical_visit,
        online_alternative_url=service.online_alternative_url,
        location_hint=service.location_hint,
    )


@router.delete("/services/{service_id}", response_model=SuccessResponse)
async def delete_service(
    service_id: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> SuccessResponse:
    res = await session.execute(select(Service).where(Service.id == service_id))
    service = res.scalar_one_or_none()
    if not service:
        raise AppException(ErrorCode.NOT_FOUND, f"Service '{service_id}' not found", 404)
    require_office_access(user, service.office_id)

    # Check if there are active tokens
    stmt_tok = select(Token).where(
        Token.service_id == service_id,
        Token.state.in_(["WAITING", "CALLED", "SERVING"]),
    )
    if (await session.execute(stmt_tok)).first():
        raise AppException(ErrorCode.VALIDATION_ERROR, "Cannot delete service with active tokens", 409)

    service.active = False
    await session.commit()
    return SuccessResponse(message=f"Service '{service_id}' deactivated")


# ─── Counter CRUD (A1) ────────────────────────────────────────────────────────

@router.post("/counters", response_model=CounterOut, status_code=status.HTTP_201_CREATED)
async def create_counter(
    payload: CounterCreateIn,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> CounterOut:
    require_office_access(user, payload.office_id)
    stmt_exists = select(Counter).where(Counter.id == payload.id)
    if (await session.execute(stmt_exists)).scalar_one_or_none():
        raise AppException(ErrorCode.VALIDATION_ERROR, f"Counter '{payload.id}' already exists", 409)

    counter = Counter(
        id=payload.id,
        office_id=payload.office_id,
        label=payload.label,
        status="CLOSED",
    )
    session.add(counter)
    await session.commit()
    return CounterOut(
        id=counter.id,
        office_id=counter.office_id,
        label=counter.label,
        status=counter.status,
        officer_id=counter.officer_id,
    )


@router.get("/offices/{office_id}/counters", response_model=list[CounterOut])
async def list_office_counters(
    office_id: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN", "DESK", "OFFICER"])),
    session: AsyncSession = Depends(get_db),
) -> list[CounterOut]:
    require_office_access(user, office_id)
    res = await session.execute(
        select(Counter).where(Counter.office_id == office_id).order_by(Counter.label.asc())
    )
    counters = res.scalars().all()
    if not counters:
        return []
    counter_ids = [c.id for c in counters]
    mappings_res = await session.execute(
        select(CounterService).where(CounterService.counter_id.in_(counter_ids))
    )
    mappings = mappings_res.scalars().all()
    mapping_dict: dict[str, list[str]] = {}
    for m in mappings:
        mapping_dict.setdefault(m.counter_id, []).append(m.service_id)

    return [
        CounterOut(
            id=c.id,
            office_id=c.office_id,
            label=c.label,
            status=c.status,
            officer_id=c.officer_id,
            service_ids=mapping_dict.get(c.id, []),
        )
        for c in counters
    ]


@router.get("/counters", response_model=list[CounterOut])
async def list_counters(
    office_id: str | None = None,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN", "DESK", "OFFICER"])),
    session: AsyncSession = Depends(get_db),
) -> list[CounterOut]:
    target_office = office_id or user.office_id
    if not target_office:
        raise AppException(ErrorCode.VALIDATION_ERROR, "office_id is required", 400)
    return await list_office_counters(target_office, user, session)


@router.get("/counters/{counter_id}", response_model=CounterOut)
async def get_counter(
    counter_id: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN", "OFFICER"])),
    session: AsyncSession = Depends(get_db),
) -> CounterOut:
    res = await session.execute(select(Counter).where(Counter.id == counter_id))
    counter = res.scalar_one_or_none()
    if not counter:
        raise AppException(ErrorCode.NOT_FOUND, f"Counter '{counter_id}' not found", 404)
    require_office_access(user, counter.office_id)
    mappings_res = await session.execute(
        select(CounterService).where(CounterService.counter_id == counter_id)
    )
    mappings = mappings_res.scalars().all()
    return CounterOut(
        id=counter.id,
        office_id=counter.office_id,
        label=counter.label,
        status=counter.status,
        officer_id=counter.officer_id,
        service_ids=[m.service_id for m in mappings],
    )


@router.patch("/counters/{counter_id}", response_model=CounterOut)
async def update_counter(
    counter_id: str,
    payload: CounterUpdateIn,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> CounterOut:
    res = await session.execute(select(Counter).where(Counter.id == counter_id))
    counter = res.scalar_one_or_none()
    if not counter:
        raise AppException(ErrorCode.NOT_FOUND, f"Counter '{counter_id}' not found", 404)
    require_office_access(user, counter.office_id)

    if payload.label is not None:
        counter.label = payload.label
    if payload.status is not None:
        if payload.status not in ["OPEN", "BREAK", "CLOSED"]:
            raise AppException(ErrorCode.VALIDATION_ERROR, f"Invalid status: {payload.status}", 400)
        counter.status = payload.status

    await session.commit()
    return CounterOut(
        id=counter.id,
        office_id=counter.office_id,
        label=counter.label,
        status=counter.status,
        officer_id=counter.officer_id,
    )


@router.delete("/counters/{counter_id}", response_model=SuccessResponse)
async def delete_counter(
    counter_id: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> SuccessResponse:
    res = await session.execute(select(Counter).where(Counter.id == counter_id))
    counter = res.scalar_one_or_none()
    if not counter:
        raise AppException(ErrorCode.NOT_FOUND, f"Counter '{counter_id}' not found", 404)
    require_office_access(user, counter.office_id)

    stmt_serving = select(Token).where(
        Token.counter_id == counter_id,
        Token.state.in_(["CALLED", "SERVING"]),
    )
    if (await session.execute(stmt_serving)).first():
        raise AppException(ErrorCode.VALIDATION_ERROR, "Cannot delete counter with active token", 409)

    await session.delete(counter)
    await session.commit()
    return SuccessResponse(message=f"Counter '{counter_id}' deleted")


# ─── Counter Service Mapping (A1) ───────────────────────────────────────────

@router.post("/counter-services", response_model=SuccessResponse, status_code=status.HTTP_201_CREATED)
async def map_counter_service(
    payload: CounterServiceIn,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> SuccessResponse:
    c_res = await session.execute(select(Counter).where(Counter.id == payload.counter_id))
    counter = c_res.scalar_one_or_none()
    if not counter:
        raise AppException(ErrorCode.NOT_FOUND, f"Counter '{payload.counter_id}' not found", 404)
    require_office_access(user, counter.office_id)

    s_res = await session.execute(select(Service).where(Service.id == payload.service_id))
    service = s_res.scalar_one_or_none()
    if not service:
        raise AppException(ErrorCode.NOT_FOUND, f"Service '{payload.service_id}' not found", 404)

    if counter.office_id != service.office_id:
        raise AppException(ErrorCode.CROSS_OFFICE_ACCESS_DENIED, "Counter and Service must belong to the same office", 400)

    stmt = (
        pg_insert(CounterService)
        .values(counter_id=payload.counter_id, service_id=payload.service_id)
        .on_conflict_do_nothing()
    )
    await session.execute(stmt)
    await session.commit()
    return SuccessResponse(message=f"Mapped counter '{payload.counter_id}' to service '{payload.service_id}'")


@router.delete("/counter-services", response_model=SuccessResponse)
async def unmap_counter_service(
    payload: CounterServiceIn,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
) -> SuccessResponse:
    c_res = await session.execute(select(Counter).where(Counter.id == payload.counter_id))
    counter = c_res.scalar_one_or_none()
    if not counter:
        raise AppException(ErrorCode.NOT_FOUND, f"Counter '{payload.counter_id}' not found", 404)
    require_office_access(user, counter.office_id)

    res = await session.execute(
        select(CounterService).where(
            CounterService.counter_id == payload.counter_id,
            CounterService.service_id == payload.service_id,
        )
    )
    mapping = res.scalar_one_or_none()
    if not mapping:
        raise AppException(ErrorCode.NOT_FOUND, "Mapping not found", 404)

    await session.delete(mapping)
    await session.commit()
    return SuccessResponse(message=f"Unmapped counter '{payload.counter_id}' from service '{payload.service_id}'")


# ─── Public Lobby Display Board (D1, P1) ─────────────────────────────────────

@router.get("/display/{office_id}", response_model=DisplayBoardOut)
async def get_lobby_display(
    office_id: str,
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> DisplayBoardOut:
    """
    Public lobby board: counter label and now-serving display code ONLY.
    No personal data, no names, no phones.
    """
    off_res = await session.execute(select(Office).where(Office.id == office_id))
    office = off_res.scalar_one_or_none()
    if not office:
        raise AppException(ErrorCode.NOT_FOUND, f"Office '{office_id}' not found", 404)

    b_date = clock.business_date(office.timezone)
    counters_res = await session.execute(
        select(Counter).where(Counter.office_id == office_id).order_by(Counter.id.asc())
    )
    counters = counters_res.scalars().all()

    display_counters: list[DisplayCounterOut] = []
    for c in counters:
        # Find active token in SERVING (or CALLED) for this counter today
        t_res = await session.execute(
            select(Token.display_code)
            .where(
                Token.counter_id == c.id,
                Token.business_date == b_date,
                Token.state.in_(["SERVING", "CALLED"]),
            )
            .order_by(Token.called_at.desc().nullslast())
            .limit(1)
        )
        now_serving = t_res.scalar_one_or_none()
        display_counters.append(
            DisplayCounterOut(
                counter_label=c.label,
                now_serving=now_serving,
            )
        )

    return DisplayBoardOut(
        office_id=office.id,
        office_name=office.name,
        counters=display_counters,
    )


# ─── Service Queue Pause / Resume (O10) ──────────────────────────────────────

@router.post("/queues/{service_id}/pause", response_model=SuccessResponse)
async def pause_queue_booking(
    service_id: str,
    reason: str,
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN", "OFFICER"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> SuccessResponse:
    if not reason or not reason.strip():
        raise AppException(ErrorCode.VALIDATION_ERROR, "A reason is required to pause booking", 400)

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
        # Insert queue_state if not exists yet today
        qs = QueueState(
            office_id=service.office_id,
            service_id=service_id,
            business_date=b_date,
            last_seq=0,
            calls_since_priority=0,
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
    user: UserClaims = Depends(require_role(["ADMIN", "SUPER_ADMIN", "OFFICER"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> SuccessResponse:
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
            async with async_session_maker() as sim_session:
                result = await run_simulation(
                    session=sim_session,
                    scenario=scenario,
                    start_dt=start_dt,
                    allow_real_office=True,
                )
                await sim_session.commit()
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

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.auth import UserClaims, require_office_access, require_role
from api.app.core.clock import Clock, get_clock
from api.app.core.db import get_db
from api.app.core.errors import AppException, ErrorCode
from api.app.models.entities import Counter, CounterService, Service, Token, TokenEvent
from api.app.routers.citizen import build_token_out
from api.app.schemas.citizen import TokenOut
from api.app.schemas.common import SuccessResponse
from api.app.schemas.officer import (
    CallNextIn,
    CompleteServingIn,
    CounterStatusIn,
    CounterVerifyIn,
    NoteIn,
    PriorityCheckIn,
    QueueItemOut,
    TransferIn,
)
from api.app.services.officer_service import (
    call_next,
    complete_serving,
    mark_no_show,
    priority_check,
    release_token,
    set_counter_status,
    start_serving,
    transfer_token,
)

router = APIRouter(prefix="/v1/officer", tags=["Officer"])


async def _get_counter_or_auto_create(
    session: AsyncSession, counter_id: str, default_office_id: str = "ward-central-01"
) -> Counter | None:
    c_res = await session.execute(select(Counter).where(Counter.id == counter_id))
    counter = c_res.scalar_one_or_none()
    if counter:
        return counter
    if counter_id.startswith("cnt-srv-"):
        sid = counter_id[len("cnt-"):]
        s_res = await session.execute(select(Service).where(Service.id == sid))
        srv = s_res.scalar_one_or_none()
        if srv:
            counter = Counter(id=counter_id, office_id=srv.office_id, label=f"Counter ({srv.code})", status="OPEN")
            session.add(counter)
            session.add(CounterService(counter_id=counter_id, service_id=srv.id))
            await session.commit()
            return counter
    elif counter_id == "cnt-all":
        counter = Counter(id="cnt-all", office_id=default_office_id, label="Universal Counter (All Services)", status="OPEN")
        session.add(counter)
        all_s = (await session.execute(select(Service.id).where(Service.office_id == default_office_id))).scalars().all()
        for sid in all_s:
            session.add(CounterService(counter_id="cnt-all", service_id=sid))
        await session.commit()
        return counter
    return None


@router.get("/counters/{counter_id}/queue", response_model=list[QueueItemOut])
async def get_counter_queue(
    counter_id: str,
    user: UserClaims = Depends(require_role(["OFFICER", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> list[QueueItemOut]:
    counter = await _get_counter_or_auto_create(session, counter_id, user.office_id or "ward-central-01")
    if not counter:
        raise AppException(ErrorCode.NOT_FOUND, f"Counter '{counter_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, counter.office_id)

    cs_res = await session.execute(
        select(CounterService.service_id).where(CounterService.counter_id == counter_id)
    )
    service_ids = cs_res.scalars().all()
    if not service_ids:
        return []

    b_date = clock.business_date()
    now_epoch = clock.now_epoch()

    tokens_res = await session.execute(
        select(Token)
        .where(
            Token.office_id == counter.office_id,
            Token.service_id.in_(service_ids),
            Token.business_date == b_date,
            Token.state == "WAITING",
        )
        .order_by(Token.sort_key.asc())
        .limit(50)
    )
    tokens = tokens_res.scalars().all()

    items: list[QueueItemOut] = []
    for t in tokens:
        masked = None
        if t.phone and len(t.phone) >= 4:
            masked = f"{'*' * (len(t.phone) - 4)}{t.phone[-4:]}"
        elif t.phone:
            masked = t.phone

        wait_mins = max(0.0, (now_epoch - float(t.sort_key)) / 60.0)

        items.append(
            QueueItemOut(
                id=t.id,
                seq=t.seq,
                display_code=t.display_code,
                category=t.category,
                priority_status=t.priority_status,
                state=t.state,
                arrived=t.arrived_at is not None,
                arrived_at=t.arrived_at,
                pass_over_count=t.pass_over_count,
                masked_phone=masked,
                beneficiary_name=t.beneficiary_name,
                waiting_minutes=round(wait_mins, 1),
            )
        )
    return items


@router.post("/counters/{counter_id}/status")
async def update_counter_status(
    counter_id: str,
    payload: CounterStatusIn,
    user: UserClaims = Depends(require_role(["OFFICER", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> dict[str, str]:
    counter = await _get_counter_or_auto_create(session, counter_id, user.office_id or "ward-central-01")
    if not counter:
        raise AppException(ErrorCode.NOT_FOUND, f"Counter '{counter_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, counter.office_id)

    updated_counter = await set_counter_status(
        session=session,
        clock=clock,
        counter_id=counter_id,
        status=payload.status,
        officer_id=user.user_id,
    )
    await session.commit()
    return {"counter_id": updated_counter.id, "status": updated_counter.status}


@router.post("/counters/{counter_id}/call-next", response_model=TokenOut | None)
async def officer_call_next(
    counter_id: str,
    payload: CallNextIn | None = None,
    user: UserClaims = Depends(require_role(["OFFICER", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut | None:
    counter = await _get_counter_or_auto_create(session, counter_id, user.office_id or "ward-central-01")
    if not counter:
        raise AppException(ErrorCode.NOT_FOUND, f"Counter '{counter_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, counter.office_id)

    service_id = payload.service_id if payload else None

    called = await call_next(
        session=session,
        clock=clock,
        counter_id=counter_id,
        officer_id=user.user_id,
        target_service_id=service_id,
    )

    if not called:
        await session.commit()
        return None
    await session.commit()
    return await build_token_out(called, session, clock)


@router.post("/tokens/{token_id}/verify-counter", response_model=SuccessResponse)
async def officer_verify_counter(
    token_id: str,
    payload: CounterVerifyIn,
    user: UserClaims = Depends(require_role(["OFFICER", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> SuccessResponse:
    t_res = await session.execute(select(Token).where(Token.id == token_id))
    token = t_res.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, token.office_id)

    code = payload.verification_code.strip().upper()
    valid_codes = [
        token.display_code.upper(),
        token.id.upper(),
        f"TOKEN:{token.id}:{token.display_code}".upper(),
    ]
    if not any(v in code or code in v for v in valid_codes):
        raise AppException(
            ErrorCode.VALIDATION_ERROR,
            f"Verification code does not match token '{token.display_code}'",
            status.HTTP_400_BAD_REQUEST,
        )

    now = clock.now()
    if token.arrived_at is None:
        token.arrived_at = now

    event = TokenEvent(
        token_id=token.id,
        from_state=token.state,
        to_state=token.state,
        actor_type="OFFICER",
        actor_id=user.user_id,
        at=now,
        meta={"action": "OFFICER_COUNTER_VERIFICATION", "verified_code": payload.verification_code},
    )
    session.add(event)
    await session.commit()
    return SuccessResponse(message=f"Citizen {token.display_code} successfully verified at counter")


@router.post("/tokens/{token_id}/start", response_model=TokenOut)
async def officer_start_serving(
    token_id: str,
    user: UserClaims = Depends(require_role(["OFFICER", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    t_res = await session.execute(select(Token).where(Token.id == token_id))
    token = t_res.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, token.office_id)

    started = await start_serving(
        session=session,
        clock=clock,
        token_id=token_id,
        counter_id=token.counter_id or "",
        officer_id=user.user_id,
    )
    await session.commit()
    return await build_token_out(started, session, clock)


@router.post("/tokens/{token_id}/complete", response_model=TokenOut)
async def officer_complete_serving(
    token_id: str,
    payload: CompleteServingIn,
    user: UserClaims = Depends(require_role(["OFFICER", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    t_res = await session.execute(select(Token).where(Token.id == token_id))
    token = t_res.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, token.office_id)

    completed = await complete_serving(
        session=session,
        clock=clock,
        token_id=token_id,
        counter_id=token.counter_id or "",
        officer_id=user.user_id,
        outcome_code=payload.outcome_code,
        meta={"note": payload.note} if payload.note else None,
    )
    await session.commit()
    return await build_token_out(completed, session, clock)


@router.post("/tokens/{token_id}/no-show", response_model=TokenOut)
async def officer_mark_no_show(
    token_id: str,
    payload: NoteIn | None = None,
    user: UserClaims = Depends(require_role(["OFFICER", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    t_res = await session.execute(select(Token).where(Token.id == token_id))
    token = t_res.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, token.office_id)

    no_show = await mark_no_show(
        session=session,
        clock=clock,
        token_id=token_id,
        counter_id=token.counter_id or "",
        officer_id=user.user_id,
        reason=payload.note or "NO_SHOW" if payload else "NO_SHOW",
    )
    await session.commit()
    return await build_token_out(no_show, session, clock)


@router.post("/tokens/{token_id}/release", response_model=TokenOut)
async def officer_release_token(
    token_id: str,
    payload: NoteIn | None = None,
    user: UserClaims = Depends(require_role(["OFFICER", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    t_res = await session.execute(select(Token).where(Token.id == token_id))
    token = t_res.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, token.office_id)

    released = await release_token(
        session=session,
        clock=clock,
        token_id=token_id,
        counter_id=token.counter_id or "",
        officer_id=user.user_id,
        reason=payload.note or "COUNTER_PROBLEM" if payload else "COUNTER_PROBLEM",
    )
    await session.commit()
    return await build_token_out(released, session, clock)


@router.post("/tokens/{token_id}/transfer", response_model=TokenOut)
async def officer_transfer_token(
    token_id: str,
    payload: TransferIn,
    user: UserClaims = Depends(require_role(["OFFICER", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    t_res = await session.execute(select(Token).where(Token.id == token_id))
    token = t_res.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, token.office_id)

    res_transfer = await transfer_token(
        session=session,
        clock=clock,
        token_id=token_id,
        target_service_id=payload.target_service_id,
        counter_id=token.counter_id or "",
        officer_id=user.user_id,
        reason=payload.note or "WRONG_SERVICE",
    )
    new_t_stmt = select(Token).where(Token.id == res_transfer["new_token_id"])
    res_new_t = await session.execute(new_t_stmt)
    new_token = res_new_t.scalar_one()
    await session.commit()
    return await build_token_out(new_token, session, clock)



@router.post("/tokens/{token_id}/priority-check", response_model=TokenOut)
async def officer_priority_check(
    token_id: str,
    payload: PriorityCheckIn,
    user: UserClaims = Depends(require_role(["OFFICER", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    t_res = await session.execute(select(Token).where(Token.id == token_id))
    token = t_res.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, token.office_id)

    await priority_check(
        session=session,
        clock=clock,
        token_id=token_id,
        officer_id=user.user_id,
        result=payload.result.upper(),
        doc_type=payload.doc_type,
        note=payload.note,
    )
    await session.commit()
    return await build_token_out(token, session, clock)


import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.auth import UserClaims, require_office_access, require_role
from api.app.core.clock import Clock, get_clock
from api.app.core.db import get_db
from api.app.core.errors import AppException, ErrorCode
from api.app.models.entities import Token
from api.app.routers.citizen import build_token_out
from api.app.schemas.citizen import TokenOut
from api.app.schemas.desk import DeskBookIn, DeskSlipOut
from api.app.services.token_service import book_token

router = APIRouter(prefix="/v1/desk", tags=["Desk"])


@router.post("/tokens", response_model=DeskSlipOut, status_code=status.HTTP_201_CREATED)
async def desk_create_token(
    payload: DeskBookIn,
    user: UserClaims = Depends(require_role(["DESK", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> DeskSlipOut:
    require_office_access(user, payload.office_id)

    phone = payload.phone or f"+91000{uuid.uuid4().hex[:7]}"

    book_res = await book_token(
        session=session,
        clock=clock,
        office_id=payload.office_id,
        service_id=payload.service_id,
        category=payload.category,
        phone=phone,
        citizen_id=None,
        beneficiary_name=payload.citizen_name,
        created_via=payload.created_via,
        override_reason=payload.override_reason,
    )
    t_stmt = select(Token).where(Token.id == book_res["token_id"])
    res_t = await session.execute(t_stmt)
    token = res_t.scalar_one()

    # Per Spec Section 19.2: Walk-in and assisted tokens get arrived_at = created_at
    token.arrived_at = clock.now()
    await session.commit()

    token_out = await build_token_out(token, session, clock, include_secret=True)
    printable_code = token.display_code
    qr_data = f"VERIFY:{token.id}:{token.verification_secret}" if token.verification_secret else f"TOKEN:{token.id}:{token.display_code}"

    return DeskSlipOut(
        token=token_out,
        printable_code=printable_code,
        qr_data=qr_data,
        verification_code=token.verification_secret,
    )


@router.post("/tokens/{token_id}/check-in", response_model=TokenOut)
async def desk_manual_check_in(
    token_id: str,
    user: UserClaims = Depends(require_role(["DESK", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> TokenOut:
    clean_term = token_id.strip()
    # Support payload prefix like TOKEN:uuid:code or raw code
    candidates = [p for p in clean_term.split(":") if p and p != "TOKEN"]
    if not candidates:
        candidates = [clean_term]

    result = await session.execute(
        select(Token).where(
            or_(
                Token.id.in_(candidates),
                Token.display_code.in_([c.upper() for c in candidates]),
            )
        ).order_by(Token.created_at.desc())
    )
    token = result.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, token.office_id)

    token.arrived_at = clock.now()
    await session.commit()
    return await build_token_out(token, session, clock)


@router.get("/tokens/{token_id}/slip", response_model=DeskSlipOut)
async def desk_get_token_slip(
    token_id: str,
    user: UserClaims = Depends(require_role(["DESK", "ADMIN", "SUPER_ADMIN"])),
    session: AsyncSession = Depends(get_db),
    clock: Clock = Depends(get_clock),
) -> DeskSlipOut:
    result = await session.execute(select(Token).where(Token.id == token_id))
    token = result.scalar_one_or_none()
    if not token:
        raise AppException(ErrorCode.NOT_FOUND, f"Token '{token_id}' not found", status.HTTP_404_NOT_FOUND)

    require_office_access(user, token.office_id)
    token_out = await build_token_out(token, session, clock, include_secret=True)
    return DeskSlipOut(
        token=token_out,
        printable_code=token.display_code,
        qr_data=f"VERIFY:{token.id}:{token.verification_secret}" if token.verification_secret else f"TOKEN:{token.id}:{token.display_code}",
        verification_code=token.verification_secret,
    )


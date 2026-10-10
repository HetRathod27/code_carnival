from __future__ import annotations

import zoneinfo
from datetime import date, time
from typing import TypedDict

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.clock import Clock
from api.app.models.entities import Office, QueueState, Service, Token
from api.app.schemas.citizen import SlotItemOut


class SlotWindow(TypedDict):
    slot_time: str
    start_time: time
    end_time: time
    start_str: str
    end_str: str


DEFAULT_SLOT_WINDOWS: list[SlotWindow] = [
    {
        "slot_time": "09:30 AM – 10:30 AM",
        "start_time": time(9, 30),
        "end_time": time(10, 30),
        "start_str": "09:30",
        "end_str": "10:30",
    },
    {
        "slot_time": "10:30 AM – 11:30 AM",
        "start_time": time(10, 30),
        "end_time": time(11, 30),
        "start_str": "10:30",
        "end_str": "11:30",
    },
    {
        "slot_time": "11:30 AM – 12:30 PM",
        "start_time": time(11, 30),
        "end_time": time(12, 30),
        "start_str": "11:30",
        "end_str": "12:30",
    },
    {
        "slot_time": "02:00 PM – 03:00 PM",
        "start_time": time(14, 0),
        "end_time": time(15, 0),
        "start_str": "14:00",
        "end_str": "15:00",
    },
    {
        "slot_time": "03:00 PM – 04:00 PM",
        "start_time": time(15, 0),
        "end_time": time(16, 0),
        "start_str": "15:00",
        "end_str": "16:00",
    },
    {
        "slot_time": "04:30 PM – 05:30 PM",
        "start_time": time(16, 30),
        "end_time": time(17, 30),
        "start_str": "16:30",
        "end_str": "17:30",
    },
]


async def get_service_slots(
    session: AsyncSession,
    clock: Clock,
    office: Office,
    service: Service,
    queue_state: QueueState | None,
    target_date: date,
    party_size: int = 1,
) -> list[SlotItemOut]:
    """
    Computes slot availability and exact reason codes for a given office, service, and date.
    Strictly follows state precedence:
    OFFICE_CLOSED > BOOKING_CLOSED > TIME_PASSED > FULLY_BOOKED > INSUFFICIENT_GROUP_SLOTS > AVAILABLE.
    """
    curr_b_date = clock.business_date()
    try:
        tz = zoneinfo.ZoneInfo(office.timezone)
        office_now = clock.now().astimezone(tz)
    except Exception:
        office_now = clock.now()
    now_time = office_now.time()

    # Query active/booked tokens on target_date for this office and service
    stmt = select(Token).where(
        Token.office_id == office.id,
        Token.service_id == service.id,
        Token.business_date == target_date,
        Token.state.in_(["WAITING", "CALLED", "SERVING", "COMPLETED"]),
    )
    res = await session.execute(stmt)
    booked_tokens = res.scalars().all()

    booked_by_slot: dict[str, int] = {w["start_str"]: 0 for w in DEFAULT_SLOT_WINDOWS}
    for tok in booked_tokens:
        if tok.eta_features:
            base_slot = (
                tok.eta_features.get("base_slot")
                or tok.eta_features.get("appointment_slot")
                or ""
            )
            for w in DEFAULT_SLOT_WINDOWS:
                if w["slot_time"] == base_slot or base_slot.startswith(w["start_str"]):
                    booked_by_slot[w["start_str"]] += 1
                    break

    office_close_mins = office.close_time.hour * 60 + office.close_time.minute
    office_open_mins = office.open_time.hour * 60 + office.open_time.minute

    slot_items: list[SlotItemOut] = []
    for w in DEFAULT_SLOT_WINDOWS:
        start_t = w["start_time"]
        end_t = w["end_time"]
        start_mins = start_t.hour * 60 + start_t.minute
        end_mins = end_t.hour * 60 + end_t.minute

        booked_cnt = booked_by_slot[w["start_str"]]
        total_capacity = 4
        remaining_cap = max(0, total_capacity - booked_cnt)

        # Precedence:
        # 1. OFFICE_CLOSED
        # 2. BOOKING_CLOSED
        # 3. TIME_PASSED
        # 4. FULLY_BOOKED
        # 5. INSUFFICIENT_GROUP_SLOTS
        # 6. AVAILABLE
        status = "AVAILABLE"

        if not office.active or start_mins < office_open_mins or end_mins > office_close_mins:
            status = "OFFICE_CLOSED"
        elif not service.active or (queue_state and queue_state.paused):
            status = "BOOKING_CLOSED"
        elif target_date < curr_b_date or (target_date == curr_b_date and now_time >= start_t):
            status = "TIME_PASSED"
        elif remaining_cap == 0:
            status = "FULLY_BOOKED"
        elif party_size > 1 and (
            (start_mins + party_size * 15 > office_close_mins) or (party_size > remaining_cap)
        ):
            status = "INSUFFICIENT_GROUP_SLOTS"

        slot_items.append(
            SlotItemOut(
                slot_time=w["slot_time"],
                start_time=w["start_str"],
                end_time=w["end_str"],
                available=(status == "AVAILABLE"),
                status=status,
                reason_code=status,
                remaining_capacity=remaining_cap,
                booked_count=booked_cnt,
                total_capacity=total_capacity,
            )
        )

    return slot_items

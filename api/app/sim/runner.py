"""
Simulation runner (Spec Section 9).

Runs against the real service layer with a VirtualClock.
All domain rules (state machine, ETA, admission, priority) execute unchanged —
only Clock.now() is simulated.

Safety: refuses to run unless the target office has is_simulation=True
OR is the seeded demo office in a test database.
"""

import random
from dataclasses import dataclass, field
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.clock import VirtualClock
from api.app.models.entities import Counter, Office, Token
from api.app.services.officer_service import (
    call_next,
    complete_serving,
    mark_no_show,
    set_counter_status,
    start_serving,
    verify_token_at_counter,
)
from api.app.services.scheduler_service import run_tick
from api.app.services.token_service import book_token, cancel_token
from api.app.sim.scenario import ServiceScenario, SimScenario

# ─────────────────────────────────────────────────────────────────────────────
# Result types
# ─────────────────────────────────────────────────────────────────────────────


@dataclass
class SimStats:
    """Aggregate statistics produced by one simulation run."""

    tokens_booked: int = 0
    tokens_served: int = 0
    tokens_no_show: int = 0
    tokens_cancelled: int = 0
    tokens_expired: int = 0
    # ETA accuracy vs actual wait
    mae_live: float = 0.0       # Mean Absolute Error for live-adjusted engine
    mae_naive: float = 0.0      # Mean Absolute Error for naive engine
    within_range_pct: float = 0.0  # % of served tokens where actual was in [low, high]
    tick_count: int = 0
    # Raw per-token records for post-analysis
    records: list[dict] = field(default_factory=list)


# ─────────────────────────────────────────────────────────────────────────────
# Citizen arrival generators
# ─────────────────────────────────────────────────────────────────────────────


def _generate_arrival_minutes(
    svc: ServiceScenario, duration_minutes: int, rng: random.Random
) -> list[int]:
    """
    Convert per-hour arrival rates into a list of virtual minutes when
    citizens arrive (bounded random within each hour bucket).
    """
    minutes: list[int] = []
    hours_in_sim = min(len(svc.arrivals_per_hour), duration_minutes // 60)
    for h in range(hours_in_sim):
        rate = svc.arrivals_per_hour[h]
        count = rng.randint(max(0, int(rate * 0.6)), int(rate * 1.4))
        for _ in range(count):
            minute = h * 60 + rng.randint(0, 59)
            if minute < duration_minutes:
                minutes.append(minute)
    return sorted(minutes)


# ─────────────────────────────────────────────────────────────────────────────
# Main runner
# ─────────────────────────────────────────────────────────────────────────────


async def run_simulation(
    session: AsyncSession,
    scenario: SimScenario,
    start_dt: datetime,
    allow_real_office: bool = False,
) -> SimStats:
    """
    Execute a full simulated day against the real service layer.

    Args:
        session: DB session (must point to a test or simulation database).
        scenario: Simulation scenario configuration.
        start_dt: Wall-clock datetime representing virtual time 0 (office open time).
        allow_real_office: If True, skip the is_simulation guard (use only in tests).

    Returns:
        SimStats with aggregate results and per-token records.
    """
    # Safety guard: target office must be a simulation office.
    if not allow_real_office:
        stmt_office = select(Office).where(Office.id == scenario.office_id)
        res_office = await session.execute(stmt_office)
        office = res_office.scalar_one_or_none()
        if office is None:
            raise ValueError(f"Office {scenario.office_id!r} not found")
        if not office.is_simulation:
            raise ValueError(
                f"Office {scenario.office_id!r} is not a simulation office (is_simulation=False). "
                "Refusing to run simulation against a real office."
            )

    rng = random.Random(scenario.random_seed)
    clock = VirtualClock(start_dt)
    stats = SimStats()

    # Open the scenario counters and ensure any other counters in the office are closed
    stmt_all_c = select(Counter).where(Counter.office_id == scenario.office_id)
    res_all_c = await session.execute(stmt_all_c)
    for c in res_all_c.scalars().all():
        if c.id not in scenario.counter_ids and c.status != "CLOSED":
            c.status = "CLOSED"
            c.officer_id = None

    for counter_id in scenario.counter_ids:
        try:
            await set_counter_status(
                session=session,
                clock=clock,
                counter_id=counter_id,
                status="OPEN",
                officer_id=f"sim-officer-{counter_id}",
            )
        except Exception:
            pass  # Counter may already be open

    await session.flush()

    # Pre-compute citizen arrival schedules per service
    # Maps virtual_minute -> list of (service_scenario, phone, is_priority)
    arrivals_by_minute: dict[int, list[tuple[ServiceScenario, str, bool]]] = {}

    for svc in scenario.services:
        minutes = _generate_arrival_minutes(svc, scenario.duration_minutes, rng)
        for minute in minutes:
            arrivals_by_minute.setdefault(minute, [])
            is_priority = rng.random() < svc.priority_fraction
            phone = f"+91{rng.randint(7000000000, 9999999999)}"
            arrivals_by_minute[minute].append((svc, phone, is_priority))

    # Add rush events
    for rush in scenario.rushes:
        svc_map = {s.service_id: s for s in scenario.services}
        svc_rush = svc_map.get(rush.service_id)
        if svc_rush:
            for _ in range(rush.extra_tokens):
                minute = rush.start_at_minute + rng.randint(0, 10)
                arrivals_by_minute.setdefault(minute, [])
                phone = f"+91{rng.randint(7000000000, 9999999999)}"
                arrivals_by_minute[minute].append((svc_rush, phone, False))

    # Break schedule: counter_id -> list of (break_start, break_end)
    break_schedule: dict[str, list[tuple[int, int]]] = {}
    for brk in scenario.breaks:
        break_schedule.setdefault(brk.counter_id, [])
        break_schedule[brk.counter_id].append(
            (brk.start_at_minute, brk.start_at_minute + brk.duration_minutes)
        )

    # Track booked tokens: token_id -> (eta_p50, eta_low, eta_high, naive_p50, booked_at_minute)
    booked: dict[str, tuple[float, float, float, float, int]] = {}
    # Track which counter is currently serving a token: counter_id -> token_id | None
    serving: dict[str, str | None] = {c: None for c in scenario.counter_ids}
    # Track service duration per serving slot: counter_id -> target_duration_minutes
    service_duration_target: dict[str, float] = {}

    mean_minutes = scenario.services[0].mean_service_minutes if scenario.services else 12.0
    no_show_fraction = scenario.services[0].no_show_fraction if scenario.services else 0.08
    first_service_id = scenario.services[0].service_id if scenario.services else None

    # Track when tokens are called to compute actual_wait = called_at - created_at (Spec Section 8)
    called_at_minute: dict[str, int] = {}

    # Virtual minute loop
    for minute in range(scenario.duration_minutes):
        # Advance clock by 1 virtual minute
        clock.advance(60)
        now = clock.now()
        stats.tick_count += 1

        # --- Book arriving citizens ---
        for svc, phone, is_priority in arrivals_by_minute.get(minute, []):
            try:
                result = await book_token(
                    session=session,
                    clock=clock,
                    office_id=scenario.office_id,
                    service_id=svc.service_id,
                    phone=phone,
                    category="PRIORITY" if is_priority else "NORMAL",
                    created_via="APP",
                )
                token_id = result["token_id"]
                # Capture ETA fields recorded at booking time
                # book_token returns: last_eta_minutes (p50), eta_low, eta_high
                eta_p50 = float(result.get("last_eta_minutes", 0) or 0)
                eta_low = float(result.get("eta_low", 0) or 0)
                eta_high = float(result.get("eta_high", 0) or 0)
                naive_p50 = float(result.get("naive_p50", 0) or 0)
                booked[token_id] = (eta_p50, eta_low, eta_high, naive_p50, minute)
                stats.tokens_booked += 1

                # Random cancel before being called
                if rng.random() < svc.cancel_fraction:
                    try:
                        await cancel_token(
                            session=session,
                            clock=clock,
                            token_id=token_id,
                            actor_type="CITIZEN",
                            actor_id=phone,
                        )
                        stats.tokens_cancelled += 1
                        booked.pop(token_id, None)
                    except Exception:
                        pass
            except Exception:
                # Admission control rejected or duplicate phone — skip
                pass

        await session.flush()

        # --- Handle counter breaks ---
        for counter_id, break_windows in break_schedule.items():
            for bstart, bend in break_windows:
                if minute == bstart:
                    try:
                        await set_counter_status(
                            session=session,
                            clock=clock,
                            counter_id=counter_id,
                            status="BREAK",
                            officer_id=f"sim-officer-{counter_id}",
                        )
                    except Exception:
                        pass
                elif minute == bend:
                    try:
                        await set_counter_status(
                            session=session,
                            clock=clock,
                            counter_id=counter_id,
                            status="OPEN",
                            officer_id=f"sim-officer-{counter_id}",
                        )
                    except Exception:
                        pass

        # --- Officers: complete current serving or call next ---
        for counter_id in scenario.counter_ids:
            token_id = serving[counter_id]

            if token_id:
                # Check elapsed time vs target duration
                stmt_tok = select(Token).where(Token.id == token_id)
                tok_res = await session.execute(stmt_tok)
                tok = tok_res.scalar_one_or_none()

                if tok and tok.state == "SERVING":
                    started_at = tok.serving_started_at or now
                    elapsed_minutes = (now - started_at).total_seconds() / 60.0
                    target = service_duration_target.get(counter_id, mean_minutes)
                    if elapsed_minutes >= target:
                        try:
                            await complete_serving(
                                session=session,
                                clock=clock,
                                token_id=token_id,
                                counter_id=counter_id,
                                officer_id=f"sim-officer-{counter_id}",
                                outcome_code="SERVED",
                            )
                            stats.tokens_served += 1
                            if token_id in booked:
                                eta_p50, eta_low, eta_high, naive_p50, booked_minute = booked[token_id]
                                called_m = called_at_minute.get(token_id, minute)
                                actual_wait = float(called_m - booked_minute)
                                stats.records.append({
                                    "token_id": token_id,
                                    "booked_minute": booked_minute,
                                    "served_minute": minute,
                                    "actual_wait": actual_wait,
                                    "eta_p50": eta_p50,
                                    "eta_low": eta_low,
                                    "eta_high": eta_high,
                                    "naive_p50": naive_p50,
                                })
                            serving[counter_id] = None
                            service_duration_target.pop(counter_id, None)
                        except Exception:
                            serving[counter_id] = None
                elif tok and tok.state not in ("SERVING", "CALLED"):
                    serving[counter_id] = None
            else:
                # Try to call next token
                try:
                    called_tok = await call_next(
                        session=session,
                        clock=clock,
                        counter_id=counter_id,
                        officer_id=f"sim-officer-{counter_id}",
                        target_service_id=first_service_id,
                    )
                    called_token_id = called_tok.id
                    called_at_minute[called_token_id] = minute

                    # Decide no-show
                    if rng.random() < no_show_fraction:
                        try:
                            await mark_no_show(
                                session=session,
                                clock=clock,
                                token_id=called_token_id,
                                counter_id=counter_id,
                                officer_id=f"sim-officer-{counter_id}",
                            )
                            stats.tokens_no_show += 1
                        except Exception:
                            pass
                        serving[counter_id] = None
                    else:
                        # Verify and Start serving
                        try:
                            t_called = (await session.execute(select(Token).where(Token.id == called_token_id))).scalar_one_or_none()
                            if t_called and t_called.verification_secret:
                                await verify_token_at_counter(
                                    session=session,
                                    clock=clock,
                                    token_id=called_token_id,
                                    verification_code=t_called.verification_secret,
                                    counter_id=counter_id,
                                    officer_id=f"sim-officer-{counter_id}",
                                )
                            await start_serving(
                                session=session,
                                clock=clock,
                                token_id=called_token_id,
                                counter_id=counter_id,
                                officer_id=f"sim-officer-{counter_id}",
                            )
                            serving[counter_id] = called_token_id
                            # Draw service duration
                            duration = max(1.0, rng.gauss(mean_minutes, mean_minutes * 0.3))
                            service_duration_target[counter_id] = duration
                        except Exception:
                            serving[counter_id] = None
                except Exception:
                    pass  # No tokens to call or counter on break

        # --- Run scheduler tick every virtual minute ---
        try:
            await run_tick(session=session, clock=clock)
        except Exception:
            pass

        await session.flush()

    # Close counters
    for counter_id in scenario.counter_ids:
        try:
            await set_counter_status(
                session=session,
                clock=clock,
                counter_id=counter_id,
                status="CLOSED",
                officer_id=f"sim-officer-{counter_id}",
            )
        except Exception:
            pass

    await session.flush()

    # Compute accuracy metrics
    records = stats.records
    if records:
        eval_records = [
            r for r in records
            if 0.0 <= r["eta_p50"] < 500.0 and 0.0 <= r["naive_p50"] < 500.0
        ]
        if eval_records:
            stats.mae_live = sum(abs(r["actual_wait"] - r["eta_p50"]) for r in eval_records) / len(eval_records)
            stats.mae_naive = sum(abs(r["actual_wait"] - r["naive_p50"]) for r in eval_records) / len(eval_records)
            in_range = sum(
                1 for r in eval_records
                if r["eta_high"] > 0 and r["eta_low"] <= r["actual_wait"] <= r["eta_high"]
            )
            stats.within_range_pct = (in_range / len(eval_records)) * 100.0

    return stats

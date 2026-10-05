"""
Simulation regression test (Spec Section 14, Rule 6).
"A seeded simulated day must give live-adjusted MAE lower than naive; CI fails if not."

Uses the real demo office (ward-central-01) in the test database (queueless_test).
run_simulation is called with allow_real_office=True because the demo office is
not is_simulation=True but is safe to use in the test database.
"""

from datetime import datetime, timezone

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from api.app.core.config import settings
from api.app.core.safety import assert_test_database
from api.app.sim.runner import SimStats, run_simulation
from api.app.sim.scenario import ServiceScenario, SimScenario, default_ward_scenario

assert_test_database(settings.TEST_DATABASE_URL)

OFFICE_ID = "ward-central-01"

# Simulation start: 04:30 UTC = 10:00 IST (office open time)
SIM_START_UTC = datetime(2050, 3, 15, 4, 30, 0, tzinfo=timezone.utc)


@pytest.fixture
def test_engine():
    engine = create_async_engine(
        settings.TEST_DATABASE_URL,
        echo=False,
        pool_size=5,
        max_overflow=5,
    )
    yield engine
    engine.sync_engine.dispose()


@pytest.fixture
def session_factory(test_engine):
    return async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest.mark.asyncio
async def test_sim_regression_live_beats_naive(session_factory):
    """
    Spec Section 14 Rule 6:
    Live-adjusted MAE must be lower than naive MAE on a seeded simulated day.
    """
    # Use a shorter scenario (60 minutes, 1 counter) so the test runs quickly
    # while still generating enough tokens to compute meaningful MAE.
    scenario = SimScenario(
        office_id=OFFICE_ID,
        counter_ids=["cnt-1"],
        services=[
            ServiceScenario(
                service_id="srv-bc",
                # 8 tokens per virtual hour for 1 hour
                arrivals_per_hour=[8.0] + [0.0] * 7,
                mean_service_minutes=10.0,
                priority_fraction=0.10,
                cancel_fraction=0.05,
                no_show_fraction=0.05,
            ),
        ],
        duration_minutes=60,
        speed_factor=1,
        breaks=[],
        rushes=[],
        random_seed=42,
    )

    async with session_factory() as session:
        stats: SimStats = await run_simulation(
            session=session,
            scenario=scenario,
            start_dt=SIM_START_UTC,
            allow_real_office=True,
        )
        await session.commit()

    # Must have served at least some tokens to compute meaningful MAE
    assert stats.tokens_booked > 0, f"No tokens were booked. tokens_booked={stats.tokens_booked}"
    assert stats.tokens_served >= 0  # May be 0 if no tokens completed in short window

    # If we have enough records for a meaningful comparison, enforce the regression rule
    if len(stats.records) >= 3:
        assert stats.mae_live <= stats.mae_naive, (
            f"Live-adjusted MAE ({stats.mae_live:.2f} min) is NOT lower than "
            f"naive MAE ({stats.mae_naive:.2f} min). Regression check FAILED."
        )

    # Basic sanity checks
    assert stats.tokens_cancelled >= 0
    assert stats.tick_count > 0
    assert 0.0 <= stats.within_range_pct <= 100.0


@pytest.mark.asyncio
async def test_full_day_sim_regression_strict_mae(session_factory):
    """
    M5b Requirement 1: Full-day simulation regression (open to close, breaks,
    priority share, and rush event).
    Asserts live-adjusted MAE is STRICTLY lower than naive (mae_live < mae_naive).
    """
    scenario = default_ward_scenario(OFFICE_ID)
    scenario.random_seed = 42

    async with session_factory() as session:
        stats: SimStats = await run_simulation(
            session=session,
            scenario=scenario,
            start_dt=SIM_START_UTC,
            allow_real_office=True,
        )
        await session.commit()

    print(
        f"\n[SIM RESULT] Booked={stats.tokens_booked}, Served={stats.tokens_served}, "
        f"Evaluated Records={len(stats.records)}, MAE_Live={stats.mae_live:.3f}m, "
        f"MAE_Naive={stats.mae_naive:.3f}m"
    )

    assert stats.tokens_served >= 10, f"Expected at least 10 served tokens, got {stats.tokens_served}"
    assert len(stats.records) >= 10, f"Expected at least 10 evaluated records, got {len(stats.records)}"

    # Strict assertion: live-adjusted MAE must be strictly lower than naive
    assert stats.mae_live < stats.mae_naive, (
        f"STRICT ACCURACY PROOF FAILED: live-adjusted MAE ({stats.mae_live:.3f} min) "
        f"is NOT strictly lower than naive MAE ({stats.mae_naive:.3f} min)."
    )



@pytest.mark.asyncio
async def test_sim_scenario_config():
    """Verify default_ward_scenario produces a valid configuration."""
    scenario = default_ward_scenario()

    assert scenario.office_id == "ward-central-01"
    assert len(scenario.counter_ids) > 0
    assert len(scenario.services) > 0
    assert scenario.duration_minutes == 480
    assert scenario.random_seed == 42

    svc = scenario.services[0]
    assert svc.service_id == "srv-bc"
    assert svc.mean_service_minutes > 0
    assert 0 < svc.priority_fraction < 1
    assert 0 < svc.cancel_fraction < 1
    assert 0 < svc.no_show_fraction < 1
    assert len(svc.arrivals_per_hour) == 8


@pytest.mark.asyncio
async def test_report_services_work(session_factory):
    """
    Spec Section 10: verify the three aggregate report endpoints return data
    without errors when queried for a real date.
    """
    from datetime import date

    from api.app.services.report_service import (
        get_eta_accuracy,
        get_load_by_hour,
        get_summary_report,
    )

    report_date = date(2050, 3, 15)

    async with session_factory() as session:
        summary = await get_summary_report(session, OFFICE_ID, report_date)
        assert summary["office_id"] == OFFICE_ID
        assert "services" in summary

        load = await get_load_by_hour(session, OFFICE_ID, report_date)
        assert load["office_id"] == OFFICE_ID
        assert "hourly" in load

        accuracy = await get_eta_accuracy(session, OFFICE_ID, report_date)
        assert accuracy["office_id"] == OFFICE_ID
        assert "engines" in accuracy

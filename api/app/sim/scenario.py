"""
Simulator scenario configuration (Spec Section 9).
Dataclasses only — no DB or network calls.
"""

from dataclasses import dataclass, field


@dataclass
class ServiceScenario:
    """Per-service arrival and timing parameters."""

    service_id: str
    # Tokens arriving per virtual hour (index 0 = hour 0, len must be 24)
    arrivals_per_hour: list[float]
    # Mean service duration in minutes
    mean_service_minutes: float
    # Fraction of arrivals that are PRIORITY (~10–15%)
    priority_fraction: float = 0.12
    # Fraction that cancel spontaneously before being called (~5%)
    cancel_fraction: float = 0.05
    # Fraction that no-show when called (~8%)
    no_show_fraction: float = 0.08


@dataclass
class BreakEvent:
    """A planned counter break injected at a specific virtual minute."""

    counter_id: str
    # Minutes after simulation start when break begins
    start_at_minute: int
    # Duration in minutes
    duration_minutes: int = 15


@dataclass
class RushEvent:
    """A rush of additional citizens injected at a specific virtual minute."""

    service_id: str
    start_at_minute: int
    extra_tokens: int = 30


@dataclass
class SimScenario:
    """Full simulation scenario configuration."""

    office_id: str
    # Which counters are active for this simulation
    counter_ids: list[str]
    # Per-service scenarios
    services: list[ServiceScenario]
    # Total simulation duration in virtual minutes
    duration_minutes: int = 480  # 8-hour working day
    # Virtual clock speed: 1 real second = speed_factor virtual minutes
    speed_factor: int = 1
    # Planned breaks
    breaks: list[BreakEvent] = field(default_factory=list)
    # Rush injections
    rushes: list[RushEvent] = field(default_factory=list)
    # Random seed for reproducibility
    random_seed: int = 42


def default_ward_scenario(office_id: str = "ward-central-01") -> SimScenario:
    """
    Default one-service scenario for the demo ward office.
    Arrival curve: peak late morning (10:00–12:00), lunch dip (13:00–14:00),
    end-of-day taper (15:00–17:00).
    """
    # 8-hour window starting at open_time; index i = hour i relative to open
    # Office opens at 10:00 IST (idx 0 = 10:00, idx 7 = 17:00)
    arrivals_bc = [
        8.0,   # 10:00–11:00
        14.0,  # 11:00–12:00
        16.0,  # 12:00–13:00 peak
        6.0,   # 13:00–14:00 lunch dip
        10.0,  # 14:00–15:00
        8.0,   # 15:00–16:00
        5.0,   # 16:00–17:00 taper
        2.0,   # 17:00–18:00
    ]

    return SimScenario(
        office_id=office_id,
        counter_ids=["cnt-1", "cnt-2"],
        services=[
            ServiceScenario(
                service_id="srv-bc",
                arrivals_per_hour=arrivals_bc,
                mean_service_minutes=12.0,
                priority_fraction=0.12,
                cancel_fraction=0.05,
                no_show_fraction=0.08,
            ),
        ],
        duration_minutes=480,
        speed_factor=1,
        breaks=[
            BreakEvent(counter_id="cnt-1", start_at_minute=180, duration_minutes=15),
        ],
        rushes=[
            RushEvent(service_id="srv-bc", start_at_minute=120, extra_tokens=20),
        ],
        random_seed=42,
    )

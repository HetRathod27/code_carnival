from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass
class WaitingToken:
    id: str
    category: str  # NORMAL or PRIORITY
    sort_key: float
    arrived_at: datetime | None = None
    pass_over_count: int = 0


@dataclass
class ServingToken:
    token_id: str
    counter_id: str
    started_at: datetime
    elapsed_minutes: float


@dataclass
class CounterInfo:
    id: str
    status: str  # OPEN, BREAK, CLOSED
    current_serving_token_id: str | None = None


@dataclass
class ServiceInfo:
    id: str
    code: str
    prior_avg_minutes: float
    ewma_mean: float
    ewma_var: float = 0.0


@dataclass
class QueueSnapshot:
    now: datetime
    service: ServiceInfo
    counters: list[CounterInfo]
    serving_tokens: list[ServingToken]
    waiting_tokens: list[WaitingToken]
    calls_since_priority: int = 0
    priority_every_n: int = 3
    dispatch_window: int = 3
    max_pass_overs: int = 2
    meta: dict[str, Any] = field(default_factory=dict)


@dataclass
class EtaResult:
    token_id: str
    p50_minutes: float
    low_minutes: float
    high_minutes: float
    reason: str | None = None
    engine: str = "live_adjusted"
    predicted_start_time: datetime | None = None

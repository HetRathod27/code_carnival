from typing import Any

from pydantic import BaseModel


class OfficeSettingsOut(BaseModel):
    office_id: str
    grace_minutes: int
    priority_every_n: int
    requeue_offset: int
    max_requeues: int
    close_grace_minutes: int
    max_active_tokens_per_phone: int
    strike_limit: int
    dispatch_window: int
    max_pass_overs: int
    max_waiting_per_service: int
    on_my_way_extension_minutes: int
    retention_days: int


class OfficeSettingsUpdate(BaseModel):
    grace_minutes: int | None = None
    priority_every_n: int | None = None
    requeue_offset: int | None = None
    max_requeues: int | None = None
    close_grace_minutes: int | None = None
    max_active_tokens_per_phone: int | None = None
    strike_limit: int | None = None
    dispatch_window: int | None = None
    max_pass_overs: int | None = None
    max_waiting_per_service: int | None = None
    on_my_way_extension_minutes: int | None = None
    retention_days: int | None = None


class StaffCreateIn(BaseModel):
    user_id: str
    role: str  # OFFICER, DESK, ADMIN
    office_id: str
    phone: str | None = None
    name: str | None = None


class OfficeDetailOut(BaseModel):
    id: str
    name: str
    address: str
    timezone: str
    open_time: str
    close_time: str
    active: bool


# ─── M5b Admin CRUD & Display Models ─────────────────────────────────────────

class ServiceCreateIn(BaseModel):
    id: str
    office_id: str
    code: str
    names: dict[str, str]
    prior_avg_minutes: float
    required_docs: list[Any] = []
    priority_allowed: bool = True
    requires_physical_visit: bool = True
    online_alternative_url: str | None = None
    location_hint: dict[str, str] | None = None


class ServiceUpdateIn(BaseModel):
    names: dict[str, str] | None = None
    prior_avg_minutes: float | None = None
    required_docs: list[Any] | None = None
    priority_allowed: bool | None = None
    requires_physical_visit: bool | None = None
    online_alternative_url: str | None = None
    location_hint: dict[str, str] | None = None
    active: bool | None = None


class CounterCreateIn(BaseModel):
    id: str
    office_id: str
    label: str


class CounterUpdateIn(BaseModel):
    label: str | None = None
    status: str | None = None


class CounterOut(BaseModel):
    id: str
    office_id: str
    label: str
    status: str
    officer_id: str | None = None


class CounterServiceIn(BaseModel):
    counter_id: str
    service_id: str


class DisplayCounterOut(BaseModel):
    counter_label: str
    now_serving: str | None = None


class DisplayBoardOut(BaseModel):
    office_id: str
    office_name: str
    counters: list[DisplayCounterOut]


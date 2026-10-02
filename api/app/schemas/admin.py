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

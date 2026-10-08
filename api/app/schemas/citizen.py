from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class ServiceOut(BaseModel):
    id: str
    office_id: str
    code: str
    names: dict[str, str]
    prior_avg_minutes: float
    required_docs: list[Any]
    priority_allowed: bool

    requires_physical_visit: bool
    online_alternative_url: str | None = None
    location_hint: dict[str, str] | None = None
    indicative_wait_minutes: float | None = None


class OfficeOut(BaseModel):
    id: str
    name: str
    address: str
    timezone: str
    open_time: str
    close_time: str


class TokenBookIn(BaseModel):
    office_id: str
    service_id: str
    phone: str
    category: str = "NORMAL"
    priority_doc_type: str | None = None
    beneficiary_name: str | None = None
    travel_minutes: int = 0


class TokenOut(BaseModel):
    id: str
    office_id: str
    service_id: str
    business_date: str
    seq: int
    display_code: str
    state: str
    category: str
    priority_status: str
    created_via: str
    phone: str | None = None
    beneficiary_name: str | None = None
    counter_id: str | None = None
    counter_label: str | None = None
    arrived_at: datetime | None = None
    on_my_way_at: datetime | None = None
    called_at: datetime | None = None
    grace_deadline: datetime | None = None
    serving_started_at: datetime | None = None
    completed_at: datetime | None = None
    last_eta_minutes: float | None = None
    last_eta_reason: str | None = None
    eta_low: float | None = None
    eta_high: float | None = None
    waiting_ahead: int = 0
    now_serving: str | None = None
    server_time: datetime = Field(default_factory=datetime.utcnow)


class CheckInIn(BaseModel):
    qr_payload: str


class DeviceRegisterIn(BaseModel):
    fcm_token: str
    platform: str = "android"
    language: str = "en"


class ProfileOut(BaseModel):
    id: str
    phone: str | None = None
    name: str | None = None
    language: str = "en"
    role: str = "CITIZEN"
    office_id: str | None = None
    priority_strikes: int = 0


class ProfileUpdateIn(BaseModel):
    language: str | None = None
    name: str | None = None


class CitizenConfirmCompletionIn(BaseModel):
    service_completed: bool = True
    reason_if_not: str | None = None
    rating: int = Field(default=5, ge=1, le=5)
    feedback_text: str | None = None

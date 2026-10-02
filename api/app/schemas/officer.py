from datetime import datetime

from pydantic import BaseModel


class CounterStatusIn(BaseModel):
    status: str  # OPEN, BREAK, CLOSED


class CallNextIn(BaseModel):
    service_id: str | None = None


class CompleteServingIn(BaseModel):
    outcome_code: str = "SERVED"
    note: str | None = None


class NoteIn(BaseModel):
    note: str | None = None


class TransferIn(BaseModel):
    target_service_id: str
    note: str | None = None


class PriorityCheckIn(BaseModel):
    doc_type: str
    result: str  # VERIFIED, REJECTED
    note: str | None = None


class QueueItemOut(BaseModel):
    id: str
    seq: int
    display_code: str
    category: str
    priority_status: str
    state: str
    arrived: bool
    arrived_at: datetime | None = None
    pass_over_count: int
    masked_phone: str | None = None
    beneficiary_name: str | None = None
    waiting_minutes: float

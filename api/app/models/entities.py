from datetime import date, datetime, time
from typing import Any

from sqlalchemy import (
    BigInteger,
    Boolean,
    Date,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Identity,
    Integer,
    Numeric,
    String,
    Text,
    Time,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class Office(Base):
    __tablename__ = "offices"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    address: Mapped[str] = mapped_column(Text, nullable=False)
    timezone: Mapped[str] = mapped_column(String(64), default="Asia/Kolkata", nullable=False)
    open_time: Mapped[time] = mapped_column(Time, nullable=False)
    close_time: Mapped[time] = mapped_column(Time, nullable=False)
    qr_secret: Mapped[str] = mapped_column(String(255), nullable=False)
    is_simulation: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    settings: Mapped["OfficeSettings"] = relationship("OfficeSettings", back_populates="office", uselist=False)
    services: Mapped[list["Service"]] = relationship("Service", back_populates="office")
    counters: Mapped[list["Counter"]] = relationship("Counter", back_populates="office")


class OfficeSettings(Base):
    __tablename__ = "office_settings"

    office_id: Mapped[str] = mapped_column(String(64), ForeignKey("offices.id", ondelete="CASCADE"), primary_key=True)
    grace_minutes: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    priority_every_n: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    requeue_offset: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    max_requeues: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    close_grace_minutes: Mapped[int] = mapped_column(Integer, default=15, nullable=False)
    max_active_tokens_per_phone: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    strike_limit: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    dispatch_window: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    max_pass_overs: Mapped[int] = mapped_column(Integer, default=2, nullable=False)
    max_waiting_per_service: Mapped[int] = mapped_column(Integer, default=100, nullable=False)
    max_on_behalf_tokens: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    on_my_way_extension_minutes: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    retention_days: Mapped[int] = mapped_column(Integer, default=90, nullable=False)
    max_verification_attempts: Mapped[int] = mapped_column(Integer, default=5, nullable=False)

    office: Mapped["Office"] = relationship("Office", back_populates="settings")


class Service(Base):
    __tablename__ = "services"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    office_id: Mapped[str] = mapped_column(String(64), ForeignKey("offices.id", ondelete="CASCADE"), nullable=False)
    code: Mapped[str] = mapped_column(String(16), nullable=False)
    names: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    prior_avg_minutes: Mapped[float] = mapped_column(Float, nullable=False)
    required_docs: Mapped[list[Any]] = mapped_column(JSONB, default=list, nullable=False)
    priority_allowed: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    requires_physical_visit: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    online_alternative_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    location_hint: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)

    office: Mapped["Office"] = relationship("Office", back_populates="services")


class Counter(Base):
    __tablename__ = "counters"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    office_id: Mapped[str] = mapped_column(String(64), ForeignKey("offices.id", ondelete="CASCADE"), nullable=False)
    label: Mapped[str] = mapped_column(String(64), nullable=False)
    status: Mapped[str] = mapped_column(
        Enum("OPEN", "BREAK", "CLOSED", name="counter_status_enum", create_type=False),
        default="CLOSED",
        nullable=False,
    )
    officer_id: Mapped[str | None] = mapped_column(String(64), nullable=True)

    office: Mapped["Office"] = relationship("Office", back_populates="counters")


class CounterService(Base):
    __tablename__ = "counter_services"

    counter_id: Mapped[str] = mapped_column(String(64), ForeignKey("counters.id", ondelete="CASCADE"), primary_key=True)
    service_id: Mapped[str] = mapped_column(String(64), ForeignKey("services.id", ondelete="CASCADE"), primary_key=True)


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    role: Mapped[str] = mapped_column(
        Enum("CITIZEN", "OFFICER", "DESK", "ADMIN", "SYSTEM", name="actor_type_enum", create_type=False),
        default="CITIZEN",
        nullable=False,
    )
    office_id: Mapped[str | None] = mapped_column(String(64), ForeignKey("offices.id", ondelete="SET NULL"), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    language: Mapped[str] = mapped_column(String(8), default="en", nullable=False)
    priority_strikes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    priority_blocked_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class QueueState(Base):
    __tablename__ = "queue_state"

    office_id: Mapped[str] = mapped_column(String(64), ForeignKey("offices.id", ondelete="CASCADE"), primary_key=True)
    service_id: Mapped[str] = mapped_column(String(64), ForeignKey("services.id", ondelete="CASCADE"), primary_key=True)
    business_date: Mapped[date] = mapped_column(Date, primary_key=True)
    last_seq: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    calls_since_priority: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    now_serving: Mapped[str | None] = mapped_column(String(32), nullable=True)
    waiting_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    paused: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    version: Mapped[int] = mapped_column(BigInteger, default=1, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class Token(Base):
    __tablename__ = "tokens"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    office_id: Mapped[str] = mapped_column(String(64), ForeignKey("offices.id", ondelete="CASCADE"), nullable=False)
    service_id: Mapped[str] = mapped_column(String(64), ForeignKey("services.id", ondelete="CASCADE"), nullable=False)
    business_date: Mapped[date] = mapped_column(Date, nullable=False)
    seq: Mapped[int] = mapped_column(Integer, nullable=False)
    display_code: Mapped[str] = mapped_column(String(32), nullable=False)
    citizen_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    beneficiary_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    beneficiary_key: Mapped[str | None] = mapped_column(String(255), nullable=True)
    category: Mapped[str] = mapped_column(
        Enum("NORMAL", "PRIORITY", name="category_enum", create_type=False),
        default="NORMAL",
        nullable=False,
    )
    priority_status: Mapped[str] = mapped_column(
        Enum("PENDING", "VERIFIED", "REJECTED", name="priority_status_enum", create_type=False),
        default="PENDING",
        nullable=False,
    )
    created_via: Mapped[str] = mapped_column(String(32), default="APP", nullable=False)
    state: Mapped[str] = mapped_column(
        Enum(
            "WAITING", "CALLED", "SERVING", "COMPLETED",
            "CANCELLED", "EXPIRED", "NO_SHOW", "TRANSFERRED",
            name="token_state_enum",
            create_type=False,
        ),
        default="WAITING",
        nullable=False,
    )
    sort_key: Mapped[float] = mapped_column(Numeric(18, 6), nullable=False)
    travel_minutes: Mapped[int] = mapped_column(Integer, default=15, nullable=False)
    counter_id: Mapped[str | None] = mapped_column(String(64), ForeignKey("counters.id", ondelete="SET NULL"), nullable=True)
    pass_over_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    outcome_code: Mapped[str | None] = mapped_column(
        Enum(
            "SERVED", "MISSING_DOCS", "WRONG_SERVICE", "WRONG_OFFICE", "CITIZEN_LEFT", "OTHER",
            name="outcome_code_enum",
            create_type=False,
        ),
        nullable=True,
    )
    arrived_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    on_my_way_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    called_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    grace_deadline: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    serving_started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    requeue_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    parent_token_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    last_eta_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    last_eta_reason: Mapped[str | None] = mapped_column(String(64), nullable=True)
    eta_features: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)
    verification_secret: Mapped[str | None] = mapped_column(String(32), nullable=True)
    verification_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    verified_counter_id: Mapped[str | None] = mapped_column(String(64), ForeignKey("counters.id", ondelete="SET NULL"), nullable=True)
    verified_officer_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    failed_verification_attempts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        UniqueConstraint("office_id", "service_id", "business_date", "seq", name="uq_tokens_office_service_date_seq"),
    )


class TokenEvent(Base):
    __tablename__ = "token_events"

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=False), primary_key=True)
    token_id: Mapped[str] = mapped_column(String(64), ForeignKey("tokens.id", ondelete="CASCADE"), nullable=False)
    from_state: Mapped[str | None] = mapped_column(
        Enum(
            "WAITING", "CALLED", "SERVING", "COMPLETED",
            "CANCELLED", "EXPIRED", "NO_SHOW", "TRANSFERRED",
            name="token_state_enum",
            create_type=False,
        ),
        nullable=True,
    )
    to_state: Mapped[str] = mapped_column(
        Enum(
            "WAITING", "CALLED", "SERVING", "COMPLETED",
            "CANCELLED", "EXPIRED", "NO_SHOW", "TRANSFERRED",
            name="token_state_enum",
            create_type=False,
        ),
        nullable=False,
    )
    actor_type: Mapped[str] = mapped_column(
        Enum("CITIZEN", "OFFICER", "DESK", "ADMIN", "SYSTEM", name="actor_type_enum", create_type=False),
        nullable=False,
    )
    actor_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    counter_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    meta: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)


class AllowedTransition(Base):
    __tablename__ = "allowed_transitions"

    from_state: Mapped[str | None] = mapped_column(
        Enum(
            "WAITING", "CALLED", "SERVING", "COMPLETED",
            "CANCELLED", "EXPIRED", "NO_SHOW", "TRANSFERRED",
            name="token_state_enum",
            create_type=False,
        ),
        primary_key=True,
        nullable=True,
    )
    to_state: Mapped[str] = mapped_column(
        Enum(
            "WAITING", "CALLED", "SERVING", "COMPLETED",
            "CANCELLED", "EXPIRED", "NO_SHOW", "TRANSFERRED",
            name="token_state_enum",
            create_type=False,
        ),
        primary_key=True,
        nullable=False,
    )
    actor_type: Mapped[str] = mapped_column(
        Enum("CITIZEN", "OFFICER", "DESK", "ADMIN", "SYSTEM", name="actor_type_enum", create_type=False),
        primary_key=True,
        nullable=False,
    )


class IdempotencyKey(Base):
    __tablename__ = "idempotency_keys"

    key: Mapped[str] = mapped_column(String(128), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(64), nullable=False)
    endpoint: Mapped[str] = mapped_column(String(128), nullable=False)
    response: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class NotificationOutbox(Base):
    __tablename__ = "notification_outbox"

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=False), primary_key=True)
    token_id: Mapped[str] = mapped_column(String(64), ForeignKey("tokens.id", ondelete="CASCADE"), nullable=False)
    user_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    kind: Mapped[str] = mapped_column(String(64), nullable=False)
    payload: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    dedupe_key: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="PENDING", nullable=False)
    attempts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    send_after: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class PriorityCheck(Base):
    __tablename__ = "priority_checks"

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=False), primary_key=True)
    token_id: Mapped[str] = mapped_column(String(64), ForeignKey("tokens.id", ondelete="CASCADE"), nullable=False)
    officer_id: Mapped[str] = mapped_column(String(64), nullable=False)
    doc_type: Mapped[str] = mapped_column(String(64), nullable=False)
    result: Mapped[str] = mapped_column(
        Enum("PENDING", "VERIFIED", "REJECTED", name="priority_status_enum", create_type=False),
        nullable=False,
    )
    at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class CounterEvent(Base):
    __tablename__ = "counter_events"

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=False), primary_key=True)
    counter_id: Mapped[str] = mapped_column(String(64), ForeignKey("counters.id", ondelete="CASCADE"), nullable=False)
    status: Mapped[str] = mapped_column(
        Enum("OPEN", "BREAK", "CLOSED", name="counter_status_enum", create_type=False),
        nullable=False,
    )
    at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    actor: Mapped[str] = mapped_column(String(64), nullable=False)


class Device(Base):
    __tablename__ = "devices"

    user_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    fcm_token: Mapped[str] = mapped_column(String(512), nullable=False)
    platform: Mapped[str] = mapped_column(String(32), default="android", nullable=False)
    language: Mapped[str] = mapped_column(String(8), default="en", nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class EtaLog(Base):
    __tablename__ = "eta_log"

    id: Mapped[int] = mapped_column(BigInteger, Identity(always=False), primary_key=True)
    token_id: Mapped[str] = mapped_column(String(64), ForeignKey("tokens.id", ondelete="CASCADE"), nullable=False)
    at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    engine: Mapped[str] = mapped_column(String(32), nullable=False)
    predicted_p50: Mapped[float] = mapped_column(Float, nullable=False)
    low: Mapped[float] = mapped_column(Float, nullable=False)
    high: Mapped[float] = mapped_column(Float, nullable=False)
    naive_p50: Mapped[float] = mapped_column(Float, nullable=False)


class ServiceStats(Base):
    __tablename__ = "service_stats"

    service_id: Mapped[str] = mapped_column(String(64), ForeignKey("services.id", ondelete="CASCADE"), primary_key=True)
    hour_bucket: Mapped[int] = mapped_column(Integer, primary_key=True)
    ewma_minutes: Mapped[float] = mapped_column(Float, nullable=False)
    ewma_var: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    n: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


from typing import Any

from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.clock import Clock
from api.app.models.entities import QueueState, Token, TokenEvent

# Allowed transitions matrix: (from_state, to_state, actor_type)
# Core Rule 2: Never update tokens.state directly. Use transition() which validates
# against ALLOWED_TRANSITIONS, writes a token_events row, and bumps queue_state.version.
ALLOWED_TRANSITIONS: set[tuple[str | None, str, str]] = {
    (None, "WAITING", "CITIZEN"),
    (None, "WAITING", "DESK"),
    ("WAITING", "CALLED", "OFFICER"),
    ("CALLED", "SERVING", "OFFICER"),
    ("SERVING", "COMPLETED", "OFFICER"),
    ("WAITING", "CANCELLED", "CITIZEN"),
    ("WAITING", "CANCELLED", "DESK"),
    ("CALLED", "CANCELLED", "CITIZEN"),
    ("CALLED", "CANCELLED", "OFFICER"),
    ("WAITING", "EXPIRED", "SYSTEM"),
    ("CALLED", "NO_SHOW", "SYSTEM"),
    ("CALLED", "NO_SHOW", "OFFICER"),
    ("NO_SHOW", "WAITING", "SYSTEM"),
    ("NO_SHOW", "CANCELLED", "SYSTEM"),
    ("CALLED", "WAITING", "OFFICER"),
    ("CALLED", "TRANSFERRED", "OFFICER"),
    ("SERVING", "TRANSFERRED", "OFFICER"),
}


class InvalidTransitionError(Exception):
    """Raised when an illegal token state transition is attempted."""

    def __init__(self, from_state: str | None, to_state: str, actor_type: str):
        super().__init__(
            f"Invalid transition from state '{from_state}' to '{to_state}' by actor '{actor_type}'"
        )
        self.from_state = from_state
        self.to_state = to_state
        self.actor_type = actor_type


async def transition(
    token: Token,
    to_state: str,
    actor_type: str,
    actor_id: str | None,
    session: AsyncSession,
    clock: Clock,
    counter_id: str | None = None,
    meta: dict[str, Any] | None = None,
) -> Token:
    """
    Core Rule 2: The single authority for state mutations on tokens.
    1. Validates against ALLOWED_TRANSITIONS.
    2. Writes an append-only token_events row.
    3. Bumps queue_state.version.
    4. Updates token.state.
    """
    from_state = token.state
    transition_key = (from_state, to_state, actor_type)

    if transition_key not in ALLOWED_TRANSITIONS:
        raise InvalidTransitionError(from_state, to_state, actor_type)

    event_time = clock.now()

    # 1. Record event in token_events
    event = TokenEvent(
        token_id=token.id,
        from_state=from_state,
        to_state=to_state,
        actor_type=actor_type,
        actor_id=actor_id,
        counter_id=counter_id or token.counter_id,
        at=event_time,
        meta=meta or {},
    )
    session.add(event)

    # 2. Update token state & references
    token.state = to_state
    if counter_id:
        token.counter_id = counter_id

    # 3. Lock and bump queue_state version
    stmt = (
        update(QueueState)
        .where(
            QueueState.office_id == token.office_id,
            QueueState.service_id == token.service_id,
            QueueState.business_date == token.business_date,
        )
        .values(
            version=QueueState.version + 1,
            updated_at=event_time,
        )
    )
    await session.execute(stmt)

    return token

from abc import ABC, abstractmethod
from datetime import date, datetime, timezone
from zoneinfo import ZoneInfo


class Clock(ABC):
    """
    Abstract Clock interface.
    Core Rule 4: No datetime.now() and no SQL now() in business logic. Inject Clock.
    """

    @abstractmethod
    def now(self) -> datetime:
        """Returns the current timezone-aware datetime."""
        ...

    @abstractmethod
    def now_epoch(self) -> float:
        """Returns current unix timestamp in seconds."""
        ...

    @abstractmethod
    def business_date(self, tz_name: str = "Asia/Kolkata") -> date:
        """Returns the current business date in the office's timezone."""
        ...


class SystemClock(Clock):
    """Production clock reading real-world time."""

    def now(self) -> datetime:
        return datetime.now(timezone.utc)

    def now_epoch(self) -> float:
        return self.now().timestamp()

    def business_date(self, tz_name: str = "Asia/Kolkata") -> date:
        return datetime.now(ZoneInfo(tz_name)).date()


class VirtualClock(Clock):
    """
    Controllable virtual clock for simulations and deterministic property tests.
    """

    def __init__(self, start_time: datetime | None = None):
        if start_time is None:
            self._current_time = datetime(2026, 10, 2, 9, 0, 0, tzinfo=timezone.utc)
        else:
            if start_time.tzinfo is None:
                self._current_time = start_time.replace(tzinfo=timezone.utc)
            else:
                self._current_time = start_time

    def now(self) -> datetime:
        return self._current_time

    def now_epoch(self) -> float:
        return self._current_time.timestamp()

    def business_date(self, tz_name: str = "Asia/Kolkata") -> date:
        return self._current_time.astimezone(ZoneInfo(tz_name)).date()

    def advance(self, seconds: float) -> None:
        from datetime import timedelta
        self._current_time += timedelta(seconds=seconds)

    def set_time(self, new_time: datetime) -> None:
        if new_time.tzinfo is None:
            self._current_time = new_time.replace(tzinfo=timezone.utc)
        else:
            self._current_time = new_time


_system_clock = SystemClock()


def get_clock() -> Clock:
    return _system_clock


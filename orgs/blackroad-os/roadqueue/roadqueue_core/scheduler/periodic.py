"""RoadQueue Periodic Task - Recurring Task Definition.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum, auto
from typing import Any, Callable, Optional


class TaskSchedule(Enum):
    """Common task schedules."""
    
    EVERY_SECOND = "every 1s"
    EVERY_MINUTE = "every 1m"
    EVERY_5_MINUTES = "every 5m"
    EVERY_15_MINUTES = "every 15m"
    EVERY_30_MINUTES = "every 30m"
    EVERY_HOUR = "every 1h"
    EVERY_6_HOURS = "every 6h"
    EVERY_12_HOURS = "every 12h"
    DAILY = "every 24h"
    WEEKLY = "every 168h"


@dataclass
class PeriodicTask:
    """A periodic recurring task.

    Attributes:
        name: Task name
        func: Task function
        interval: Execution interval
        start_at: When to start
        end_at: When to stop
        max_runs: Maximum executions
        run_immediately: Run on start
    """

    name: str
    func: Callable[[], Any]
    interval: timedelta
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    max_runs: Optional[int] = None
    run_immediately: bool = False

    run_count: int = field(default=0, repr=False)
    last_run: Optional[datetime] = field(default=None, repr=False)
    next_run: Optional[datetime] = field(default=None, repr=False)
    active: bool = field(default=True, repr=False)

    def __post_init__(self):
        if self.run_immediately:
            self.next_run = self.start_at or datetime.now()
        else:
            self.next_run = (self.start_at or datetime.now()) + self.interval

    def should_run(self) -> bool:
        """Check if task should run now."""
        if not self.active:
            return False

        now = datetime.now()

        if self.start_at and now < self.start_at:
            return False

        if self.end_at and now > self.end_at:
            self.active = False
            return False

        if self.max_runs and self.run_count >= self.max_runs:
            self.active = False
            return False

        if self.next_run and now >= self.next_run:
            return True

        return False

    def run(self) -> Any:
        """Execute the task."""
        result = self.func()
        self.run_count += 1
        self.last_run = datetime.now()
        self.next_run = self.last_run + self.interval
        return result

    @classmethod
    def every(
        cls,
        interval: timedelta,
        name: str,
        func: Callable,
        **kwargs,
    ) -> "PeriodicTask":
        """Create task running at interval."""
        return cls(name=name, func=func, interval=interval, **kwargs)

    @classmethod
    def every_seconds(cls, seconds: int, name: str, func: Callable, **kwargs) -> "PeriodicTask":
        return cls.every(timedelta(seconds=seconds), name, func, **kwargs)

    @classmethod
    def every_minutes(cls, minutes: int, name: str, func: Callable, **kwargs) -> "PeriodicTask":
        return cls.every(timedelta(minutes=minutes), name, func, **kwargs)

    @classmethod
    def every_hours(cls, hours: int, name: str, func: Callable, **kwargs) -> "PeriodicTask":
        return cls.every(timedelta(hours=hours), name, func, **kwargs)


__all__ = ["PeriodicTask", "TaskSchedule"]

"""RoadQueue Cron Parser - Cron Expression Parser.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import List, Optional, Set, Tuple


@dataclass
class CronSchedule:
    """Parsed cron schedule."""

    minutes: Set[int] = field(default_factory=lambda: set(range(60)))
    hours: Set[int] = field(default_factory=lambda: set(range(24)))
    days: Set[int] = field(default_factory=lambda: set(range(1, 32)))
    months: Set[int] = field(default_factory=lambda: set(range(1, 13)))
    weekdays: Set[int] = field(default_factory=lambda: set(range(7)))

    def matches(self, dt: datetime) -> bool:
        """Check if datetime matches schedule."""
        return (
            dt.minute in self.minutes
            and dt.hour in self.hours
            and dt.day in self.days
            and dt.month in self.months
            and dt.weekday() in self.weekdays
        )


class CronParser:
    """Cron expression parser.

    Supports standard 5-field cron expressions:
    - minute (0-59)
    - hour (0-23)
    - day of month (1-31)
    - month (1-12)
    - day of week (0-6, 0=Sunday)

    Special characters:
    - * : any value
    - , : value list
    - - : range
    - / : step
    """

    WEEKDAYS = {"sun": 0, "mon": 1, "tue": 2, "wed": 3, "thu": 4, "fri": 5, "sat": 6}
    MONTHS = {"jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
              "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12}

    def __init__(self, expression: str):
        self.expression = expression
        self.schedule = self._parse(expression)

    def _parse(self, expression: str) -> CronSchedule:
        """Parse cron expression."""
        parts = expression.strip().split()

        if len(parts) == 5:
            minute, hour, day, month, weekday = parts
        elif len(parts) == 6:
            # Extended format with seconds (ignore seconds)
            _, minute, hour, day, month, weekday = parts
        else:
            raise ValueError(f"Invalid cron expression: {expression}")

        return CronSchedule(
            minutes=self._parse_field(minute, 0, 59),
            hours=self._parse_field(hour, 0, 23),
            days=self._parse_field(day, 1, 31),
            months=self._parse_field(month, 1, 12, self.MONTHS),
            weekdays=self._parse_field(weekday, 0, 6, self.WEEKDAYS),
        )

    def _parse_field(
        self,
        field: str,
        min_val: int,
        max_val: int,
        names: Optional[dict] = None,
    ) -> Set[int]:
        """Parse a cron field."""
        values = set()

        for part in field.split(","):
            # Replace names
            if names:
                for name, val in names.items():
                    part = part.lower().replace(name, str(val))

            if part == "*":
                values.update(range(min_val, max_val + 1))
            elif "/" in part:
                base, step = part.split("/")
                step = int(step)
                if base == "*":
                    start = min_val
                else:
                    start = int(base)
                values.update(range(start, max_val + 1, step))
            elif "-" in part:
                start, end = part.split("-")
                values.update(range(int(start), int(end) + 1))
            else:
                values.add(int(part))

        return {v for v in values if min_val <= v <= max_val}

    def matches(self, dt: datetime) -> bool:
        """Check if datetime matches schedule."""
        return self.schedule.matches(dt)

    def next_run(self, from_time: Optional[datetime] = None) -> datetime:
        """Calculate next run time."""
        dt = (from_time or datetime.now()).replace(second=0, microsecond=0)
        dt += timedelta(minutes=1)

        # Search for next matching time (limit to 1 year)
        max_iterations = 525600  # minutes in a year
        for _ in range(max_iterations):
            if self.matches(dt):
                return dt
            dt += timedelta(minutes=1)

        raise ValueError("No matching time found in next year")

    def get_next_runs(self, count: int, from_time: Optional[datetime] = None) -> List[datetime]:
        """Get next N run times."""
        runs = []
        current = from_time

        for _ in range(count):
            next_run = self.next_run(current)
            runs.append(next_run)
            current = next_run

        return runs


# Common cron expressions
EVERY_MINUTE = "* * * * *"
EVERY_HOUR = "0 * * * *"
EVERY_DAY = "0 0 * * *"
EVERY_WEEK = "0 0 * * 0"
EVERY_MONTH = "0 0 1 * *"
WORKDAY_9AM = "0 9 * * 1-5"
WEEKENDS = "0 9 * * 0,6"


__all__ = ["CronParser", "CronSchedule", "EVERY_MINUTE", "EVERY_HOUR", "EVERY_DAY"]

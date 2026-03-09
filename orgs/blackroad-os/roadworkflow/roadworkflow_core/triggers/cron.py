"""Cron Trigger - Time-based scheduling.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import calendar
import logging
import re
import threading
import time
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Set, Tuple

from roadworkflow_core.triggers.base import (
    Trigger,
    TriggerConfig,
    TriggerEvent,
    TriggerType,
)

logger = logging.getLogger(__name__)


@dataclass
class CronField:
    """A field in a cron expression."""

    name: str
    min_value: int
    max_value: int
    values: Set[int]

    def matches(self, value: int) -> bool:
        """Check if value matches."""
        return value in self.values


class CronExpression:
    """Parse and evaluate cron expressions.

    Format: minute hour day_of_month month day_of_week

    Examples:
    - "0 * * * *" - Every hour
    - "*/15 * * * *" - Every 15 minutes
    - "0 0 * * *" - Daily at midnight
    - "0 0 * * 0" - Weekly on Sunday
    - "0 0 1 * *" - Monthly on 1st
    """

    FIELD_NAMES = ["minute", "hour", "day_of_month", "month", "day_of_week"]
    FIELD_RANGES = [
        (0, 59),
        (0, 23),
        (1, 31),
        (1, 12),
        (0, 6),
    ]

    MONTH_NAMES = {
        "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
        "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12,
    }

    DAY_NAMES = {
        "sun": 0, "mon": 1, "tue": 2, "wed": 3, "thu": 4, "fri": 5, "sat": 6,
    }

    def __init__(self, expression: str):
        self.expression = expression
        self.fields: List[CronField] = []
        self._parse(expression)

    def _parse(self, expression: str) -> None:
        """Parse cron expression."""
        parts = expression.strip().split()

        if len(parts) == 5:
            for i, (part, (min_val, max_val)) in enumerate(zip(parts, self.FIELD_RANGES)):
                values = self._parse_field(part, min_val, max_val, i)
                self.fields.append(CronField(
                    name=self.FIELD_NAMES[i],
                    min_value=min_val,
                    max_value=max_val,
                    values=values,
                ))
        elif len(parts) == 6:
            for i, (part, (min_val, max_val)) in enumerate(zip(parts[1:], self.FIELD_RANGES)):
                values = self._parse_field(part, min_val, max_val, i)
                self.fields.append(CronField(
                    name=self.FIELD_NAMES[i],
                    min_value=min_val,
                    max_value=max_val,
                    values=values,
                ))
        else:
            raise ValueError(f"Invalid cron expression: {expression}")

    def _parse_field(
        self,
        field: str,
        min_val: int,
        max_val: int,
        field_idx: int,
    ) -> Set[int]:
        """Parse a single cron field."""
        values: Set[int] = set()

        if field_idx == 3:
            for name, num in self.MONTH_NAMES.items():
                field = field.lower().replace(name, str(num))
        elif field_idx == 4:
            for name, num in self.DAY_NAMES.items():
                field = field.lower().replace(name, str(num))

        for part in field.split(","):
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

        return values

    def matches(self, dt: datetime) -> bool:
        """Check if datetime matches cron expression."""
        return (
            self.fields[0].matches(dt.minute) and
            self.fields[1].matches(dt.hour) and
            self.fields[2].matches(dt.day) and
            self.fields[3].matches(dt.month) and
            self.fields[4].matches(dt.weekday() if dt.weekday() < 6 else 0)
        )

    def get_next(self, from_time: Optional[datetime] = None) -> datetime:
        """Get next matching datetime.

        Args:
            from_time: Start time (default: now)

        Returns:
            Next matching datetime
        """
        if from_time is None:
            from_time = datetime.utcnow()

        current = from_time.replace(second=0, microsecond=0) + timedelta(minutes=1)

        for _ in range(527040):
            if self.matches(current):
                return current
            current += timedelta(minutes=1)

        raise ValueError("Could not find next run time within 1 year")

    def get_previous(self, from_time: Optional[datetime] = None) -> datetime:
        """Get previous matching datetime."""
        if from_time is None:
            from_time = datetime.utcnow()

        current = from_time.replace(second=0, microsecond=0) - timedelta(minutes=1)

        for _ in range(527040):
            if self.matches(current):
                return current
            current -= timedelta(minutes=1)

        raise ValueError("Could not find previous run time within 1 year")


class CronTrigger(Trigger):
    """Cron-based trigger.

    Usage:
        trigger = CronTrigger("0 * * * *")  # Every hour
        trigger.on_trigger(lambda e: print(f"Triggered: {e}"))
        trigger.start()
    """

    def __init__(
        self,
        cron_expression: str,
        timezone: str = "UTC",
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        catchup: bool = True,
        jitter: float = 0.0,
        **kwargs,
    ):
        config = TriggerConfig(trigger_type=TriggerType.CRON)
        super().__init__(config=config, **kwargs)

        self.cron = CronExpression(cron_expression)
        self.timezone = timezone
        self.start_date = start_date
        self.end_date = end_date
        self.catchup = catchup
        self.jitter = jitter

        self._thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()
        self._last_run: Optional[datetime] = None

    def start(self) -> None:
        """Start the cron trigger."""
        if self._running:
            return

        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._run_loop,
            daemon=True,
            name=f"CronTrigger-{self.trigger_id}",
        )
        self._thread.start()
        self._running = True
        logger.info(f"CronTrigger started: {self.cron.expression}")

    def stop(self) -> None:
        """Stop the cron trigger."""
        self._stop_event.set()

        if self._thread:
            self._thread.join(timeout=5)
            self._thread = None

        self._running = False
        logger.info(f"CronTrigger stopped: {self.trigger_id}")

    def check(self) -> Optional[TriggerEvent]:
        """Check if cron matches current time."""
        now = datetime.utcnow()

        if self.start_date and now < self.start_date:
            return None
        if self.end_date and now > self.end_date:
            return None

        if self.cron.matches(now):
            return self._create_event(
                payload={"scheduled_time": now.isoformat()},
                source="cron",
            )
        return None

    def get_next_run(self) -> Optional[datetime]:
        """Get next scheduled run time."""
        try:
            next_time = self.cron.get_next()

            if self.end_date and next_time > self.end_date:
                return None

            return next_time
        except ValueError:
            return None

    def _run_loop(self) -> None:
        """Main trigger loop."""
        while not self._stop_event.is_set():
            now = datetime.utcnow()

            if self.start_date and now < self.start_date:
                self._stop_event.wait(60)
                continue

            if self.end_date and now > self.end_date:
                break

            if self._should_trigger(now):
                if self.jitter > 0:
                    import random
                    jitter_delay = random.uniform(0, self.jitter)
                    time.sleep(jitter_delay)

                event = self._create_event(
                    payload={
                        "scheduled_time": now.isoformat(),
                        "expression": self.cron.expression,
                    },
                    source="cron",
                )
                self._fire(event)
                self._last_run = now

            sleep_seconds = self._calculate_sleep(now)
            self._stop_event.wait(min(sleep_seconds, 60))

    def _should_trigger(self, now: datetime) -> bool:
        """Check if should trigger."""
        now_minute = now.replace(second=0, microsecond=0)

        if self._last_run:
            last_minute = self._last_run.replace(second=0, microsecond=0)
            if now_minute == last_minute:
                return False

        return self.cron.matches(now)

    def _calculate_sleep(self, now: datetime) -> float:
        """Calculate sleep time until next check."""
        next_minute = (now + timedelta(minutes=1)).replace(second=0, microsecond=0)
        delta = (next_minute - now).total_seconds()
        return max(1, delta)


class IntervalTrigger(Trigger):
    """Interval-based trigger.

    Usage:
        trigger = IntervalTrigger(timedelta(minutes=5))
        trigger.on_trigger(lambda e: print("Triggered"))
        trigger.start()
    """

    def __init__(
        self,
        interval: timedelta,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        run_immediately: bool = False,
        **kwargs,
    ):
        config = TriggerConfig(trigger_type=TriggerType.INTERVAL)
        super().__init__(config=config, **kwargs)

        self.interval = interval
        self.start_date = start_date
        self.end_date = end_date
        self.run_immediately = run_immediately

        self._thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()
        self._last_run: Optional[datetime] = None

    def start(self) -> None:
        """Start interval trigger."""
        if self._running:
            return

        self._stop_event.clear()

        if self.run_immediately:
            self._trigger_now()

        self._thread = threading.Thread(
            target=self._run_loop,
            daemon=True,
            name=f"IntervalTrigger-{self.trigger_id}",
        )
        self._thread.start()
        self._running = True
        logger.info(f"IntervalTrigger started: {self.interval}")

    def stop(self) -> None:
        """Stop interval trigger."""
        self._stop_event.set()

        if self._thread:
            self._thread.join(timeout=5)
            self._thread = None

        self._running = False

    def check(self) -> Optional[TriggerEvent]:
        """Check if interval has elapsed."""
        now = datetime.utcnow()

        if self._last_run is None:
            return self._create_event(source="interval")

        if now - self._last_run >= self.interval:
            return self._create_event(source="interval")

        return None

    def _run_loop(self) -> None:
        """Main trigger loop."""
        while not self._stop_event.is_set():
            self._stop_event.wait(self.interval.total_seconds())

            if self._stop_event.is_set():
                break

            now = datetime.utcnow()

            if self.end_date and now > self.end_date:
                break

            self._trigger_now()

    def _trigger_now(self) -> None:
        """Trigger immediately."""
        event = self._create_event(
            payload={"interval_seconds": self.interval.total_seconds()},
            source="interval",
        )
        self._fire(event)
        self._last_run = datetime.utcnow()


__all__ = [
    "CronTrigger",
    "CronExpression",
    "IntervalTrigger",
]

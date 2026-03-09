"""Trigger Base - Core trigger definitions.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set

logger = logging.getLogger(__name__)


class TriggerType(Enum):
    """Types of triggers."""

    CRON = "cron"
    INTERVAL = "interval"
    EVENT = "event"
    WEBHOOK = "webhook"
    FILE = "file"
    DATASET = "dataset"
    EXTERNAL = "external"
    MANUAL = "manual"


@dataclass
class TriggerConfig:
    """Trigger configuration."""

    trigger_id: str = ""
    trigger_type: TriggerType = TriggerType.MANUAL
    enabled: bool = True
    max_runs: int = -1
    run_count: int = 0
    description: str = ""
    tags: List[str] = field(default_factory=list)

    def __post_init__(self):
        if not self.trigger_id:
            self.trigger_id = str(uuid.uuid4())[:8]


@dataclass
class TriggerEvent:
    """A trigger event."""

    event_id: str
    trigger_id: str
    trigger_type: TriggerType
    timestamp: datetime
    payload: Dict[str, Any] = field(default_factory=dict)
    source: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "event_id": self.event_id,
            "trigger_id": self.trigger_id,
            "trigger_type": self.trigger_type.value,
            "timestamp": self.timestamp.isoformat(),
            "payload": self.payload,
            "source": self.source,
            "metadata": self.metadata,
        }


class Trigger(ABC):
    """Abstract base trigger.

    Architecture:
    ┌─────────────────────────────────────────────────────────────────────┐
    │                          Trigger                                     │
    ├─────────────────────────────────────────────────────────────────────┤
    │  ┌───────────────┐  ┌────────────────┐  ┌──────────────────────┐   │
    │  │   Config      │  │   Condition    │  │     Callbacks        │   │
    │  │               │  │                │  │                      │   │
    │  │ - type        │  │ - check()      │  │ - on_trigger         │   │
    │  │ - enabled     │  │ - should_run() │  │ - on_complete        │   │
    │  │ - max_runs    │  │                │  │                      │   │
    │  └───────────────┘  └────────────────┘  └──────────────────────┘   │
    ├─────────────────────────────────────────────────────────────────────┤
    │  Implementations: Cron | Event | Webhook | File | Dataset          │
    └─────────────────────────────────────────────────────────────────────┘
    """

    def __init__(self, config: Optional[TriggerConfig] = None, **kwargs):
        self.config = config or TriggerConfig()

        for key, value in kwargs.items():
            if hasattr(self.config, key):
                setattr(self.config, key, value)

        self._callbacks: List[Callable[[TriggerEvent], None]] = []
        self._running = False
        self._lock = threading.Lock()

    @property
    def trigger_id(self) -> str:
        """Get trigger ID."""
        return self.config.trigger_id

    @property
    def trigger_type(self) -> TriggerType:
        """Get trigger type."""
        return self.config.trigger_type

    @property
    def is_running(self) -> bool:
        """Check if trigger is running."""
        return self._running

    @abstractmethod
    def start(self) -> None:
        """Start the trigger."""
        pass

    @abstractmethod
    def stop(self) -> None:
        """Stop the trigger."""
        pass

    @abstractmethod
    def check(self) -> Optional[TriggerEvent]:
        """Check if trigger condition is met.

        Returns:
            TriggerEvent if triggered, None otherwise
        """
        pass

    def should_run(self) -> bool:
        """Check if trigger should create a run."""
        if not self.config.enabled:
            return False

        if self.config.max_runs > 0 and self.config.run_count >= self.config.max_runs:
            return False

        return True

    def on_trigger(self, callback: Callable[[TriggerEvent], None]) -> "Trigger":
        """Register trigger callback."""
        self._callbacks.append(callback)
        return self

    def _fire(self, event: TriggerEvent) -> None:
        """Fire trigger event."""
        if not self.should_run():
            return

        self.config.run_count += 1

        for callback in self._callbacks:
            try:
                callback(event)
            except Exception as e:
                logger.error(f"Trigger callback error: {e}")

    def _create_event(
        self,
        payload: Optional[Dict[str, Any]] = None,
        source: str = "",
    ) -> TriggerEvent:
        """Create a trigger event."""
        return TriggerEvent(
            event_id=str(uuid.uuid4()),
            trigger_id=self.trigger_id,
            trigger_type=self.trigger_type,
            timestamp=datetime.utcnow(),
            payload=payload or {},
            source=source,
        )

    def enable(self) -> None:
        """Enable trigger."""
        self.config.enabled = True
        logger.info(f"Trigger {self.trigger_id} enabled")

    def disable(self) -> None:
        """Disable trigger."""
        self.config.enabled = False
        logger.info(f"Trigger {self.trigger_id} disabled")

    def reset(self) -> None:
        """Reset trigger run count."""
        self.config.run_count = 0


class CompositeTrigger(Trigger):
    """Composite trigger combining multiple triggers."""

    def __init__(
        self,
        triggers: List[Trigger],
        mode: str = "any",
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.triggers = triggers
        self.mode = mode
        self._events: Dict[str, TriggerEvent] = {}

    def start(self) -> None:
        """Start all triggers."""
        for trigger in self.triggers:
            trigger.on_trigger(self._on_child_trigger)
            trigger.start()
        self._running = True

    def stop(self) -> None:
        """Stop all triggers."""
        for trigger in self.triggers:
            trigger.stop()
        self._running = False

    def check(self) -> Optional[TriggerEvent]:
        """Check composite condition."""
        events = [t.check() for t in self.triggers]
        triggered = [e for e in events if e is not None]

        if self.mode == "any" and triggered:
            return triggered[0]
        elif self.mode == "all" and len(triggered) == len(self.triggers):
            return self._create_event(
                payload={"events": [e.to_dict() for e in triggered]},
                source="composite",
            )
        return None

    def _on_child_trigger(self, event: TriggerEvent) -> None:
        """Handle child trigger event."""
        with self._lock:
            self._events[event.trigger_id] = event

            if self.mode == "any":
                self._fire(event)
            elif self.mode == "all":
                if len(self._events) == len(self.triggers):
                    composite_event = self._create_event(
                        payload={"events": [e.to_dict() for e in self._events.values()]},
                        source="composite",
                    )
                    self._fire(composite_event)
                    self._events.clear()


class ConditionalTrigger(Trigger):
    """Trigger with custom condition."""

    def __init__(
        self,
        base_trigger: Trigger,
        condition: Callable[[TriggerEvent], bool],
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.base_trigger = base_trigger
        self.condition = condition

    def start(self) -> None:
        """Start base trigger."""
        self.base_trigger.on_trigger(self._on_base_trigger)
        self.base_trigger.start()
        self._running = True

    def stop(self) -> None:
        """Stop base trigger."""
        self.base_trigger.stop()
        self._running = False

    def check(self) -> Optional[TriggerEvent]:
        """Check with condition."""
        event = self.base_trigger.check()
        if event and self.condition(event):
            return event
        return None

    def _on_base_trigger(self, event: TriggerEvent) -> None:
        """Handle base trigger event with condition."""
        if self.condition(event):
            self._fire(event)


__all__ = [
    "Trigger",
    "TriggerConfig",
    "TriggerEvent",
    "TriggerType",
    "CompositeTrigger",
    "ConditionalTrigger",
]

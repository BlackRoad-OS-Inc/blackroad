"""
RoadEvents - Event Sourcing & Event Bus for BlackRoad
CQRS-compatible event store with pub/sub and replay capabilities.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, Generic, List, Optional, Set, Type, TypeVar, Union
import asyncio
import hashlib
import json
import logging
import threading
import time
import uuid
from abc import ABC, abstractmethod
from collections import defaultdict

logger = logging.getLogger(__name__)

T = TypeVar("T")


class EventType(str, Enum):
    """Common event types."""
    CREATED = "created"
    UPDATED = "updated"
    DELETED = "deleted"
    PUBLISHED = "published"
    ARCHIVED = "archived"


@dataclass
class EventMetadata:
    """Event metadata."""
    event_id: str
    timestamp: datetime
    version: int
    correlation_id: Optional[str] = None
    causation_id: Optional[str] = None
    user_id: Optional[str] = None
    source: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "event_id": self.event_id,
            "timestamp": self.timestamp.isoformat(),
            "version": self.version,
            "correlation_id": self.correlation_id,
            "causation_id": self.causation_id,
            "user_id": self.user_id,
            "source": self.source
        }


@dataclass
class Event:
    """Base event class."""
    aggregate_type: str
    aggregate_id: str
    event_type: str
    data: Dict[str, Any]
    metadata: EventMetadata

    def to_dict(self) -> Dict[str, Any]:
        return {
            "aggregate_type": self.aggregate_type,
            "aggregate_id": self.aggregate_id,
            "event_type": self.event_type,
            "data": self.data,
            "metadata": self.metadata.to_dict()
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Event":
        return cls(
            aggregate_type=data["aggregate_type"],
            aggregate_id=data["aggregate_id"],
            event_type=data["event_type"],
            data=data["data"],
            metadata=EventMetadata(
                event_id=data["metadata"]["event_id"],
                timestamp=datetime.fromisoformat(data["metadata"]["timestamp"]),
                version=data["metadata"]["version"],
                correlation_id=data["metadata"].get("correlation_id"),
                causation_id=data["metadata"].get("causation_id"),
                user_id=data["metadata"].get("user_id"),
                source=data["metadata"].get("source")
            )
        )


class EventStore:
    """Append-only event store with versioning."""

    def __init__(self):
        self.events: List[Event] = []
        self.aggregate_versions: Dict[str, int] = {}  # aggregate_id -> version
        self.snapshots: Dict[str, tuple] = {}  # aggregate_id -> (version, state)
        self._lock = threading.Lock()
        self._indexes: Dict[str, Dict[str, List[int]]] = {
            "aggregate_type": defaultdict(list),
            "aggregate_id": defaultdict(list),
            "event_type": defaultdict(list)
        }

    def _get_aggregate_key(self, aggregate_type: str, aggregate_id: str) -> str:
        return f"{aggregate_type}:{aggregate_id}"

    def append(self, event: Event) -> None:
        """Append event to store."""
        with self._lock:
            key = self._get_aggregate_key(event.aggregate_type, event.aggregate_id)
            current_version = self.aggregate_versions.get(key, 0)

            # Optimistic concurrency check
            if event.metadata.version != current_version + 1:
                raise ValueError(
                    f"Version conflict: expected {current_version + 1}, got {event.metadata.version}"
                )

            idx = len(self.events)
            self.events.append(event)
            self.aggregate_versions[key] = event.metadata.version

            # Update indexes
            self._indexes["aggregate_type"][event.aggregate_type].append(idx)
            self._indexes["aggregate_id"][event.aggregate_id].append(idx)
            self._indexes["event_type"][event.event_type].append(idx)

            logger.debug(f"Event appended: {event.event_type} for {key}")

    def get_events(
        self,
        aggregate_type: str,
        aggregate_id: str,
        from_version: int = 0,
        to_version: Optional[int] = None
    ) -> List[Event]:
        """Get events for an aggregate."""
        with self._lock:
            indexes = self._indexes["aggregate_id"].get(aggregate_id, [])
            events = [self.events[i] for i in indexes if self.events[i].aggregate_type == aggregate_type]

            if from_version > 0:
                events = [e for e in events if e.metadata.version >= from_version]
            if to_version:
                events = [e for e in events if e.metadata.version <= to_version]

            return sorted(events, key=lambda e: e.metadata.version)

    def get_all_events(
        self,
        event_types: Optional[List[str]] = None,
        since: Optional[datetime] = None,
        limit: int = 1000
    ) -> List[Event]:
        """Get all events with optional filters."""
        with self._lock:
            events = self.events

            if event_types:
                events = [e for e in events if e.event_type in event_types]
            if since:
                events = [e for e in events if e.metadata.timestamp >= since]

            return events[-limit:]

    def get_current_version(self, aggregate_type: str, aggregate_id: str) -> int:
        """Get current version of aggregate."""
        key = self._get_aggregate_key(aggregate_type, aggregate_id)
        return self.aggregate_versions.get(key, 0)

    def save_snapshot(self, aggregate_type: str, aggregate_id: str, version: int, state: Any) -> None:
        """Save aggregate snapshot."""
        key = self._get_aggregate_key(aggregate_type, aggregate_id)
        self.snapshots[key] = (version, state)

    def get_snapshot(self, aggregate_type: str, aggregate_id: str) -> Optional[tuple]:
        """Get aggregate snapshot."""
        key = self._get_aggregate_key(aggregate_type, aggregate_id)
        return self.snapshots.get(key)


class EventHandler(ABC):
    """Base event handler."""

    @abstractmethod
    def handle(self, event: Event) -> None:
        pass

    @property
    @abstractmethod
    def event_types(self) -> List[str]:
        pass


class EventBus:
    """Pub/sub event bus with async support."""

    def __init__(self):
        self.handlers: Dict[str, List[Callable[[Event], None]]] = defaultdict(list)
        self.async_handlers: Dict[str, List[Callable[[Event], Any]]] = defaultdict(list)
        self.middlewares: List[Callable[[Event], Optional[Event]]] = []
        self._dead_letter: List[tuple] = []

    def subscribe(self, event_type: str, handler: Callable[[Event], None]) -> None:
        """Subscribe to event type."""
        self.handlers[event_type].append(handler)
        logger.debug(f"Handler subscribed to {event_type}")

    def subscribe_async(self, event_type: str, handler: Callable[[Event], Any]) -> None:
        """Subscribe async handler."""
        self.async_handlers[event_type].append(handler)

    def subscribe_all(self, handler: Callable[[Event], None]) -> None:
        """Subscribe to all events."""
        self.handlers["*"].append(handler)

    def add_middleware(self, middleware: Callable[[Event], Optional[Event]]) -> None:
        """Add middleware for event processing."""
        self.middlewares.append(middleware)

    def publish(self, event: Event) -> None:
        """Publish event to handlers."""
        # Apply middlewares
        for middleware in self.middlewares:
            event = middleware(event)
            if event is None:
                return

        # Call specific handlers
        for handler in self.handlers.get(event.event_type, []):
            try:
                handler(event)
            except Exception as e:
                logger.error(f"Handler error: {e}")
                self._dead_letter.append((event, str(e)))

        # Call wildcard handlers
        for handler in self.handlers.get("*", []):
            try:
                handler(event)
            except Exception as e:
                logger.error(f"Wildcard handler error: {e}")

    async def publish_async(self, event: Event) -> None:
        """Publish event asynchronously."""
        # Apply middlewares
        for middleware in self.middlewares:
            event = middleware(event)
            if event is None:
                return

        tasks = []

        for handler in self.async_handlers.get(event.event_type, []):
            tasks.append(asyncio.create_task(handler(event)))

        for handler in self.async_handlers.get("*", []):
            tasks.append(asyncio.create_task(handler(event)))

        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)

    def get_dead_letters(self) -> List[tuple]:
        """Get failed events."""
        return self._dead_letter.copy()


class Aggregate(ABC):
    """Base aggregate class for event sourcing."""

    def __init__(self, aggregate_id: str):
        self.aggregate_id = aggregate_id
        self._version = 0
        self._pending_events: List[Event] = []

    @property
    @abstractmethod
    def aggregate_type(self) -> str:
        pass

    @abstractmethod
    def apply(self, event: Event) -> None:
        """Apply event to aggregate state."""
        pass

    def _raise_event(
        self,
        event_type: str,
        data: Dict[str, Any],
        user_id: Optional[str] = None,
        correlation_id: Optional[str] = None
    ) -> Event:
        """Raise a new event."""
        self._version += 1

        event = Event(
            aggregate_type=self.aggregate_type,
            aggregate_id=self.aggregate_id,
            event_type=event_type,
            data=data,
            metadata=EventMetadata(
                event_id=str(uuid.uuid4()),
                timestamp=datetime.now(),
                version=self._version,
                user_id=user_id,
                correlation_id=correlation_id
            )
        )

        self.apply(event)
        self._pending_events.append(event)
        return event

    def load_from_history(self, events: List[Event]) -> None:
        """Load aggregate from event history."""
        for event in events:
            self.apply(event)
            self._version = event.metadata.version

    def get_pending_events(self) -> List[Event]:
        """Get uncommitted events."""
        return self._pending_events.copy()

    def clear_pending_events(self) -> None:
        """Clear uncommitted events."""
        self._pending_events.clear()


class Repository(Generic[T]):
    """Event-sourced repository."""

    def __init__(
        self,
        event_store: EventStore,
        event_bus: EventBus,
        aggregate_class: Type[T],
        snapshot_threshold: int = 100
    ):
        self.event_store = event_store
        self.event_bus = event_bus
        self.aggregate_class = aggregate_class
        self.snapshot_threshold = snapshot_threshold

    def get(self, aggregate_id: str) -> Optional[T]:
        """Load aggregate from events."""
        aggregate = self.aggregate_class(aggregate_id)

        # Check for snapshot
        snapshot = self.event_store.get_snapshot(
            aggregate.aggregate_type,
            aggregate_id
        )

        from_version = 0
        if snapshot:
            version, state = snapshot
            aggregate.__dict__.update(state)
            aggregate._version = version
            from_version = version + 1

        # Load events since snapshot
        events = self.event_store.get_events(
            aggregate.aggregate_type,
            aggregate_id,
            from_version=from_version
        )

        if not events and not snapshot:
            return None

        aggregate.load_from_history(events)
        return aggregate

    def save(self, aggregate: T) -> None:
        """Save aggregate events."""
        events = aggregate.get_pending_events()

        for event in events:
            self.event_store.append(event)
            self.event_bus.publish(event)

        aggregate.clear_pending_events()

        # Create snapshot if needed
        if aggregate._version % self.snapshot_threshold == 0:
            state = {k: v for k, v in aggregate.__dict__.items() if not k.startswith("_")}
            self.event_store.save_snapshot(
                aggregate.aggregate_type,
                aggregate.aggregate_id,
                aggregate._version,
                state
            )


class Projection:
    """Event projection for read models."""

    def __init__(self):
        self.state: Dict[str, Any] = {}
        self.handlers: Dict[str, Callable[[Event, Dict], None]] = {}
        self._version = 0

    def when(self, event_type: str, handler: Callable[[Event, Dict], None]) -> "Projection":
        """Register event handler."""
        self.handlers[event_type] = handler
        return self

    def apply(self, event: Event) -> None:
        """Apply event to projection."""
        handler = self.handlers.get(event.event_type)
        if handler:
            handler(event, self.state)
            self._version = event.metadata.version

    def rebuild(self, events: List[Event]) -> None:
        """Rebuild projection from events."""
        self.state.clear()
        self._version = 0
        for event in events:
            self.apply(event)


class EventProcessor:
    """Process events from store to projections."""

    def __init__(self, event_store: EventStore):
        self.event_store = event_store
        self.projections: Dict[str, Projection] = {}
        self._positions: Dict[str, int] = {}
        self._running = False

    def register_projection(self, name: str, projection: Projection) -> None:
        """Register a projection."""
        self.projections[name] = projection
        self._positions[name] = 0

    def process_events(self, projection_name: Optional[str] = None) -> int:
        """Process pending events for projections."""
        count = 0

        for name, projection in self.projections.items():
            if projection_name and name != projection_name:
                continue

            position = self._positions.get(name, 0)
            events = self.event_store.events[position:]

            for event in events:
                projection.apply(event)
                count += 1

            self._positions[name] = len(self.event_store.events)

        return count

    async def run_continuous(self, interval: float = 0.1) -> None:
        """Continuously process events."""
        self._running = True
        while self._running:
            self.process_events()
            await asyncio.sleep(interval)

    def stop(self) -> None:
        """Stop continuous processing."""
        self._running = False


class EventReplay:
    """Replay events for debugging and recovery."""

    def __init__(self, event_store: EventStore):
        self.event_store = event_store

    def replay_aggregate(
        self,
        aggregate_type: str,
        aggregate_id: str,
        to_version: Optional[int] = None,
        handler: Optional[Callable[[Event], None]] = None
    ) -> List[Event]:
        """Replay events for an aggregate."""
        events = self.event_store.get_events(
            aggregate_type,
            aggregate_id,
            to_version=to_version
        )

        if handler:
            for event in events:
                handler(event)

        return events

    def replay_all(
        self,
        event_types: Optional[List[str]] = None,
        since: Optional[datetime] = None,
        handler: Optional[Callable[[Event], None]] = None
    ) -> int:
        """Replay all events."""
        events = self.event_store.get_all_events(
            event_types=event_types,
            since=since,
            limit=999999
        )

        if handler:
            for event in events:
                handler(event)

        return len(events)


# Decorators
def event_handler(*event_types: str):
    """Decorator for event handlers."""
    def decorator(func: Callable[[Event], None]) -> Callable[[Event], None]:
        func._event_types = list(event_types)
        return func
    return decorator


# Example usage
class UserAggregate(Aggregate):
    """Example user aggregate."""

    def __init__(self, aggregate_id: str):
        super().__init__(aggregate_id)
        self.email: Optional[str] = None
        self.name: Optional[str] = None
        self.active: bool = False

    @property
    def aggregate_type(self) -> str:
        return "user"

    def create(self, email: str, name: str, user_id: str = None) -> Event:
        return self._raise_event("user.created", {"email": email, "name": name}, user_id)

    def update_name(self, name: str, user_id: str = None) -> Event:
        return self._raise_event("user.name_updated", {"name": name}, user_id)

    def apply(self, event: Event) -> None:
        if event.event_type == "user.created":
            self.email = event.data["email"]
            self.name = event.data["name"]
            self.active = True
        elif event.event_type == "user.name_updated":
            self.name = event.data["name"]


def example_usage():
    """Example event sourcing usage."""
    store = EventStore()
    bus = EventBus()
    repo = Repository(store, bus, UserAggregate)

    # Create user
    user = UserAggregate("user-123")
    user.create("alice@example.com", "Alice")
    repo.save(user)

    # Load and update
    user = repo.get("user-123")
    user.update_name("Alice Smith")
    repo.save(user)

    # Create projection
    user_list = Projection()
    user_list.when("user.created", lambda e, s: s.update({e.aggregate_id: e.data}))
    user_list.when("user.name_updated", lambda e, s: s[e.aggregate_id].update({"name": e.data["name"]}))

    # Build projection
    user_list.rebuild(store.events)
    print(f"User list: {user_list.state}")

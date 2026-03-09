"""
RoadAudit - Audit Logging for BlackRoad
Comprehensive audit trail with structured events and querying.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple
import asyncio
import hashlib
import json
import logging
import threading
import uuid

logger = logging.getLogger(__name__)


class AuditAction(str, Enum):
    """Standard audit actions."""
    CREATE = "create"
    READ = "read"
    UPDATE = "update"
    DELETE = "delete"
    LOGIN = "login"
    LOGOUT = "logout"
    ACCESS = "access"
    DENIED = "denied"
    EXECUTE = "execute"
    EXPORT = "export"
    IMPORT = "import"
    CONFIG = "config"


class AuditSeverity(str, Enum):
    """Audit event severity."""
    DEBUG = "debug"
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class AuditOutcome(str, Enum):
    """Audit event outcome."""
    SUCCESS = "success"
    FAILURE = "failure"
    PARTIAL = "partial"
    UNKNOWN = "unknown"


@dataclass
class AuditActor:
    """Who performed the action."""
    id: str
    type: str = "user"
    name: Optional[str] = None
    email: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    session_id: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class AuditResource:
    """What was acted upon."""
    id: str
    type: str
    name: Optional[str] = None
    parent_id: Optional[str] = None
    path: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class AuditEvent:
    """An audit event."""
    id: str
    action: AuditAction
    actor: AuditActor
    resource: AuditResource
    timestamp: datetime = field(default_factory=datetime.now)
    outcome: AuditOutcome = AuditOutcome.SUCCESS
    severity: AuditSeverity = AuditSeverity.INFO
    description: str = ""
    old_value: Optional[Any] = None
    new_value: Optional[Any] = None
    changes: Dict[str, Tuple[Any, Any]] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)
    correlation_id: Optional[str] = None
    request_id: Optional[str] = None

    def __post_init__(self):
        if not self.id:
            self.id = str(uuid.uuid4())

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "action": self.action.value,
            "actor": {"id": self.actor.id, "type": self.actor.type, "name": self.actor.name},
            "resource": {"id": self.resource.id, "type": self.resource.type, "name": self.resource.name},
            "timestamp": self.timestamp.isoformat(),
            "outcome": self.outcome.value,
            "severity": self.severity.value,
            "description": self.description,
            "changes": self.changes,
        }

    def hash(self) -> str:
        data = json.dumps(self.to_dict(), sort_keys=True)
        return hashlib.sha256(data.encode()).hexdigest()


class AuditStore:
    """Store audit events."""

    def __init__(self, max_events: int = 100000):
        self.max_events = max_events
        self.events: List[AuditEvent] = []
        self._index_by_actor: Dict[str, List[int]] = {}
        self._index_by_resource: Dict[str, List[int]] = {}
        self._index_by_action: Dict[str, List[int]] = {}
        self._lock = threading.Lock()

    def store(self, event: AuditEvent) -> None:
        with self._lock:
            if len(self.events) >= self.max_events:
                self._evict_oldest()
            idx = len(self.events)
            self.events.append(event)
            if event.actor.id not in self._index_by_actor:
                self._index_by_actor[event.actor.id] = []
            self._index_by_actor[event.actor.id].append(idx)
            resource_key = f"{event.resource.type}:{event.resource.id}"
            if resource_key not in self._index_by_resource:
                self._index_by_resource[resource_key] = []
            self._index_by_resource[resource_key].append(idx)
            if event.action.value not in self._index_by_action:
                self._index_by_action[event.action.value] = []
            self._index_by_action[event.action.value].append(idx)

    def _evict_oldest(self) -> None:
        cutoff = self.max_events // 10
        self.events = self.events[cutoff:]
        self._rebuild_indexes()

    def _rebuild_indexes(self) -> None:
        self._index_by_actor = {}
        self._index_by_resource = {}
        self._index_by_action = {}
        for idx, event in enumerate(self.events):
            if event.actor.id not in self._index_by_actor:
                self._index_by_actor[event.actor.id] = []
            self._index_by_actor[event.actor.id].append(idx)
            resource_key = f"{event.resource.type}:{event.resource.id}"
            if resource_key not in self._index_by_resource:
                self._index_by_resource[resource_key] = []
            self._index_by_resource[resource_key].append(idx)
            if event.action.value not in self._index_by_action:
                self._index_by_action[event.action.value] = []
            self._index_by_action[event.action.value].append(idx)

    def get(self, event_id: str) -> Optional[AuditEvent]:
        for event in self.events:
            if event.id == event_id:
                return event
        return None

    def count(self) -> int:
        return len(self.events)


@dataclass
class AuditQuery:
    """Query parameters for audit events."""
    actor_id: Optional[str] = None
    actor_type: Optional[str] = None
    resource_id: Optional[str] = None
    resource_type: Optional[str] = None
    action: Optional[AuditAction] = None
    actions: Optional[List[AuditAction]] = None
    outcome: Optional[AuditOutcome] = None
    severity: Optional[AuditSeverity] = None
    min_severity: Optional[AuditSeverity] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    correlation_id: Optional[str] = None
    limit: int = 100
    offset: int = 0
    order_desc: bool = True


class AuditQuerier:
    """Query audit events."""
    SEVERITY_ORDER = [AuditSeverity.DEBUG, AuditSeverity.INFO, AuditSeverity.WARNING, AuditSeverity.ERROR, AuditSeverity.CRITICAL]

    def __init__(self, store: AuditStore):
        self.store = store

    def query(self, q: AuditQuery) -> List[AuditEvent]:
        events = self._get_candidate_events(q)
        events = [e for e in events if self._matches(e, q)]
        events.sort(key=lambda e: e.timestamp, reverse=q.order_desc)
        return events[q.offset:q.offset + q.limit]

    def _get_candidate_events(self, q: AuditQuery) -> List[AuditEvent]:
        if q.actor_id:
            indices = self.store._index_by_actor.get(q.actor_id, [])
            return [self.store.events[i] for i in indices if i < len(self.store.events)]
        if q.resource_id and q.resource_type:
            key = f"{q.resource_type}:{q.resource_id}"
            indices = self.store._index_by_resource.get(key, [])
            return [self.store.events[i] for i in indices if i < len(self.store.events)]
        if q.action:
            indices = self.store._index_by_action.get(q.action.value, [])
            return [self.store.events[i] for i in indices if i < len(self.store.events)]
        return list(self.store.events)

    def _matches(self, event: AuditEvent, q: AuditQuery) -> bool:
        if q.actor_id and event.actor.id != q.actor_id:
            return False
        if q.actor_type and event.actor.type != q.actor_type:
            return False
        if q.resource_id and event.resource.id != q.resource_id:
            return False
        if q.resource_type and event.resource.type != q.resource_type:
            return False
        if q.action and event.action != q.action:
            return False
        if q.actions and event.action not in q.actions:
            return False
        if q.outcome and event.outcome != q.outcome:
            return False
        if q.severity and event.severity != q.severity:
            return False
        if q.min_severity:
            event_idx = self.SEVERITY_ORDER.index(event.severity)
            min_idx = self.SEVERITY_ORDER.index(q.min_severity)
            if event_idx < min_idx:
                return False
        if q.start_time and event.timestamp < q.start_time:
            return False
        if q.end_time and event.timestamp > q.end_time:
            return False
        if q.correlation_id and event.correlation_id != q.correlation_id:
            return False
        return True

    def count(self, q: AuditQuery) -> int:
        events = self._get_candidate_events(q)
        return sum(1 for e in events if self._matches(e, q))


class AuditLogger:
    """Convenient audit logging interface."""

    def __init__(self, store: AuditStore, default_actor: AuditActor = None):
        self.store = store
        self.default_actor = default_actor
        self._context: Dict[str, Any] = {}
        self._lock = threading.Lock()

    def set_context(self, **kwargs) -> None:
        with self._lock:
            self._context.update(kwargs)

    def clear_context(self) -> None:
        with self._lock:
            self._context = {}

    def log(self, action: AuditAction, resource: AuditResource, actor: AuditActor = None,
            outcome: AuditOutcome = AuditOutcome.SUCCESS, severity: AuditSeverity = None,
            description: str = "", **kwargs) -> AuditEvent:
        actor = actor or self.default_actor
        if not actor:
            raise ValueError("Actor is required")
        if severity is None:
            if outcome == AuditOutcome.FAILURE:
                severity = AuditSeverity.WARNING
            elif action == AuditAction.DENIED:
                severity = AuditSeverity.WARNING
            else:
                severity = AuditSeverity.INFO
        event = AuditEvent(
            id=str(uuid.uuid4()), action=action, actor=actor, resource=resource,
            outcome=outcome, severity=severity, description=description,
            correlation_id=self._context.get("correlation_id"),
            request_id=self._context.get("request_id"), **kwargs
        )
        self.store.store(event)
        return event

    def create(self, resource: AuditResource, actor: AuditActor = None, **kwargs) -> AuditEvent:
        return self.log(AuditAction.CREATE, resource, actor, **kwargs)

    def read(self, resource: AuditResource, actor: AuditActor = None, **kwargs) -> AuditEvent:
        return self.log(AuditAction.READ, resource, actor, **kwargs)

    def update(self, resource: AuditResource, changes: Dict[str, Tuple[Any, Any]],
               actor: AuditActor = None, **kwargs) -> AuditEvent:
        return self.log(AuditAction.UPDATE, resource, actor, changes=changes, **kwargs)

    def delete(self, resource: AuditResource, actor: AuditActor = None, **kwargs) -> AuditEvent:
        return self.log(AuditAction.DELETE, resource, actor, **kwargs)

    def access_denied(self, resource: AuditResource, actor: AuditActor = None, **kwargs) -> AuditEvent:
        return self.log(AuditAction.DENIED, resource, actor, outcome=AuditOutcome.FAILURE,
                        severity=AuditSeverity.WARNING, **kwargs)


class AuditManager:
    """High-level audit management."""

    def __init__(self, max_events: int = 100000):
        self.store = AuditStore(max_events)
        self.querier = AuditQuerier(self.store)
        self._loggers: Dict[str, AuditLogger] = {}

    def get_logger(self, name: str = "default", actor: AuditActor = None) -> AuditLogger:
        if name not in self._loggers:
            self._loggers[name] = AuditLogger(self.store, actor)
        return self._loggers[name]

    def query(self, actor_id: str = None, resource_type: str = None, action: AuditAction = None,
              start_time: datetime = None, end_time: datetime = None, limit: int = 100) -> List[AuditEvent]:
        q = AuditQuery(actor_id=actor_id, resource_type=resource_type, action=action,
                       start_time=start_time, end_time=end_time, limit=limit)
        return self.querier.query(q)

    def get_actor_activity(self, actor_id: str, hours: int = 24) -> List[AuditEvent]:
        q = AuditQuery(actor_id=actor_id, start_time=datetime.now() - timedelta(hours=hours))
        return self.querier.query(q)

    def get_resource_history(self, resource_type: str, resource_id: str, limit: int = 50) -> List[AuditEvent]:
        q = AuditQuery(resource_type=resource_type, resource_id=resource_id, limit=limit)
        return self.querier.query(q)

    def get_security_events(self, hours: int = 24) -> List[AuditEvent]:
        q = AuditQuery(actions=[AuditAction.LOGIN, AuditAction.LOGOUT, AuditAction.DENIED],
                       start_time=datetime.now() - timedelta(hours=hours), min_severity=AuditSeverity.WARNING)
        return self.querier.query(q)

    def get_stats(self) -> Dict[str, Any]:
        events = self.store.events
        now = datetime.now()
        last_hour = [e for e in events if e.timestamp > now - timedelta(hours=1)]
        last_day = [e for e in events if e.timestamp > now - timedelta(days=1)]
        return {
            "total_events": len(events),
            "events_last_hour": len(last_hour),
            "events_last_day": len(last_day),
            "actions": {action.value: sum(1 for e in events if e.action == action) for action in AuditAction},
            "outcomes": {outcome.value: sum(1 for e in events if e.outcome == outcome) for outcome in AuditOutcome}
        }

    def export(self, query: AuditQuery = None, format: str = "json") -> str:
        events = self.querier.query(query or AuditQuery(limit=10000))
        if format == "json":
            return json.dumps([e.to_dict() for e in events], indent=2)
        elif format == "csv":
            lines = ["id,timestamp,action,actor_id,resource_type,resource_id,outcome"]
            for e in events:
                lines.append(f"{e.id},{e.timestamp.isoformat()},{e.action.value},{e.actor.id},{e.resource.type},{e.resource.id},{e.outcome.value}")
            return "\n".join(lines)
        return ""


def example_usage():
    """Example audit logging usage."""
    manager = AuditManager()
    admin = AuditActor(id="admin-1", type="user", name="Admin User", ip_address="192.168.1.100")
    audit = manager.get_logger("main", admin)
    audit.set_context(correlation_id="req-123")
    user_resource = AuditResource(id="user-456", type="user", name="John Doe", path="/users/456")
    audit.create(user_resource, description="Created new user account")
    audit.update(user_resource, changes={"email": ("old@example.com", "new@example.com")}, description="Updated user")
    events = manager.query(actor_id="admin-1")
    print(f"Admin events: {len(events)}")
    print(f"Stats: {manager.get_stats()}")

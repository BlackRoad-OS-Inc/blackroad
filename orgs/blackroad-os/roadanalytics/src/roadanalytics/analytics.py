"""
RoadAnalytics - Analytics Tracking for BlackRoad
Track events, page views, and user behavior.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import hashlib
import json
import logging
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class EventType(str, Enum):
    PAGE_VIEW = "page_view"
    CLICK = "click"
    FORM_SUBMIT = "form_submit"
    PURCHASE = "purchase"
    SIGN_UP = "sign_up"
    LOGIN = "login"
    CUSTOM = "custom"


@dataclass
class Event:
    id: str
    type: EventType
    name: str
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    properties: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.now)
    context: Dict[str, Any] = field(default_factory=dict)


@dataclass
class PageView:
    id: str
    url: str
    title: str
    referrer: str = ""
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    duration_ms: int = 0
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class Session:
    id: str
    user_id: Optional[str] = None
    started_at: datetime = field(default_factory=datetime.now)
    last_activity: datetime = field(default_factory=datetime.now)
    page_views: int = 0
    events: int = 0
    properties: Dict[str, Any] = field(default_factory=dict)


@dataclass
class User:
    id: str
    anonymous_id: str
    traits: Dict[str, Any] = field(default_factory=dict)
    first_seen: datetime = field(default_factory=datetime.now)
    last_seen: datetime = field(default_factory=datetime.now)
    sessions: int = 0
    total_events: int = 0


@dataclass
class MetricValue:
    value: float
    count: int = 1
    timestamp: datetime = field(default_factory=datetime.now)


class MetricAggregator:
    def __init__(self):
        self.metrics: Dict[str, List[MetricValue]] = {}
        self._lock = threading.Lock()

    def record(self, name: str, value: float) -> None:
        with self._lock:
            if name not in self.metrics:
                self.metrics[name] = []
            self.metrics[name].append(MetricValue(value=value))

    def get_sum(self, name: str, since: datetime = None) -> float:
        values = self._filter(name, since)
        return sum(v.value for v in values)

    def get_avg(self, name: str, since: datetime = None) -> float:
        values = self._filter(name, since)
        if not values:
            return 0.0
        return sum(v.value for v in values) / len(values)

    def get_count(self, name: str, since: datetime = None) -> int:
        return len(self._filter(name, since))

    def get_min(self, name: str, since: datetime = None) -> float:
        values = self._filter(name, since)
        return min((v.value for v in values), default=0.0)

    def get_max(self, name: str, since: datetime = None) -> float:
        values = self._filter(name, since)
        return max((v.value for v in values), default=0.0)

    def _filter(self, name: str, since: datetime = None) -> List[MetricValue]:
        values = self.metrics.get(name, [])
        if since:
            values = [v for v in values if v.timestamp >= since]
        return values


class EventStore:
    def __init__(self, max_events: int = 100000):
        self.max_events = max_events
        self.events: List[Event] = []
        self.page_views: List[PageView] = []
        self._lock = threading.Lock()

    def store_event(self, event: Event) -> None:
        with self._lock:
            self.events.append(event)
            if len(self.events) > self.max_events:
                self.events = self.events[-self.max_events:]

    def store_page_view(self, page_view: PageView) -> None:
        with self._lock:
            self.page_views.append(page_view)
            if len(self.page_views) > self.max_events:
                self.page_views = self.page_views[-self.max_events:]

    def query_events(self, event_type: EventType = None, user_id: str = None, since: datetime = None, limit: int = 100) -> List[Event]:
        events = self.events
        if event_type:
            events = [e for e in events if e.type == event_type]
        if user_id:
            events = [e for e in events if e.user_id == user_id]
        if since:
            events = [e for e in events if e.timestamp >= since]
        return sorted(events, key=lambda e: e.timestamp, reverse=True)[:limit]

    def query_page_views(self, url: str = None, user_id: str = None, since: datetime = None, limit: int = 100) -> List[PageView]:
        views = self.page_views
        if url:
            views = [v for v in views if v.url == url]
        if user_id:
            views = [v for v in views if v.user_id == user_id]
        if since:
            views = [v for v in views if v.timestamp >= since]
        return sorted(views, key=lambda v: v.timestamp, reverse=True)[:limit]


class Funnel:
    def __init__(self, name: str, steps: List[str]):
        self.name = name
        self.steps = steps
        self.user_progress: Dict[str, Set[str]] = {}

    def track(self, user_id: str, step: str) -> int:
        if user_id not in self.user_progress:
            self.user_progress[user_id] = set()
        if step in self.steps:
            self.user_progress[user_id].add(step)
        return self.get_user_step(user_id)

    def get_user_step(self, user_id: str) -> int:
        completed = self.user_progress.get(user_id, set())
        for i, step in enumerate(self.steps):
            if step not in completed:
                return i
        return len(self.steps)

    def get_conversion_rates(self) -> List[Dict[str, Any]]:
        results = []
        total_users = len(self.user_progress)
        
        for i, step in enumerate(self.steps):
            users_at_step = sum(1 for progress in self.user_progress.values() if step in progress)
            rate = (users_at_step / total_users * 100) if total_users > 0 else 0
            results.append({
                "step": step,
                "index": i,
                "users": users_at_step,
                "rate": round(rate, 2)
            })
        
        return results


class Analytics:
    def __init__(self):
        self.store = EventStore()
        self.metrics = MetricAggregator()
        self.users: Dict[str, User] = {}
        self.sessions: Dict[str, Session] = {}
        self.funnels: Dict[str, Funnel] = {}
        self.hooks: Dict[str, List[Callable]] = {"event": [], "page_view": [], "identify": []}
        self._lock = threading.Lock()

    def add_hook(self, event: str, handler: Callable) -> None:
        if event in self.hooks:
            self.hooks[event].append(handler)

    def _emit(self, event: str, data: Any) -> None:
        for handler in self.hooks.get(event, []):
            try:
                handler(data)
            except Exception as e:
                logger.error(f"Hook error: {e}")

    def track(self, event_type: EventType, name: str, user_id: str = None, session_id: str = None, properties: Dict[str, Any] = None, context: Dict[str, Any] = None) -> Event:
        event = Event(
            id=str(uuid.uuid4())[:12],
            type=event_type,
            name=name,
            user_id=user_id,
            session_id=session_id,
            properties=properties or {},
            context=context or {}
        )
        
        self.store.store_event(event)
        self._update_session(session_id, events=1)
        self._update_user(user_id, events=1)
        self._emit("event", event)
        
        self.metrics.record(f"event.{event_type.value}", 1)
        self.metrics.record(f"event.{name}", 1)
        
        return event

    def page(self, url: str, title: str, referrer: str = "", user_id: str = None, session_id: str = None, duration_ms: int = 0) -> PageView:
        page_view = PageView(
            id=str(uuid.uuid4())[:12],
            url=url,
            title=title,
            referrer=referrer,
            user_id=user_id,
            session_id=session_id,
            duration_ms=duration_ms
        )
        
        self.store.store_page_view(page_view)
        self._update_session(session_id, page_views=1)
        self._emit("page_view", page_view)
        
        self.metrics.record("page_view", 1)
        self.metrics.record(f"page_view.{url}", 1)
        if duration_ms > 0:
            self.metrics.record("page_duration_ms", duration_ms)
        
        return page_view

    def identify(self, user_id: str, anonymous_id: str = None, traits: Dict[str, Any] = None) -> User:
        with self._lock:
            if user_id in self.users:
                user = self.users[user_id]
                user.last_seen = datetime.now()
                if traits:
                    user.traits.update(traits)
            else:
                user = User(
                    id=user_id,
                    anonymous_id=anonymous_id or str(uuid.uuid4())[:12],
                    traits=traits or {}
                )
                self.users[user_id] = user
        
        self._emit("identify", user)
        return user

    def start_session(self, user_id: str = None, properties: Dict[str, Any] = None) -> Session:
        session = Session(
            id=str(uuid.uuid4())[:12],
            user_id=user_id,
            properties=properties or {}
        )
        
        with self._lock:
            self.sessions[session.id] = session
        
        if user_id and user_id in self.users:
            self.users[user_id].sessions += 1
        
        return session

    def _update_session(self, session_id: str, page_views: int = 0, events: int = 0) -> None:
        if not session_id:
            return
        session = self.sessions.get(session_id)
        if session:
            session.last_activity = datetime.now()
            session.page_views += page_views
            session.events += events

    def _update_user(self, user_id: str, events: int = 0) -> None:
        if not user_id:
            return
        user = self.users.get(user_id)
        if user:
            user.last_seen = datetime.now()
            user.total_events += events

    def create_funnel(self, name: str, steps: List[str]) -> Funnel:
        funnel = Funnel(name, steps)
        self.funnels[name] = funnel
        return funnel

    def track_funnel(self, funnel_name: str, user_id: str, step: str) -> Optional[int]:
        funnel = self.funnels.get(funnel_name)
        if funnel:
            return funnel.track(user_id, step)
        return None

    def get_stats(self, since: datetime = None) -> Dict[str, Any]:
        since = since or datetime.now() - timedelta(days=1)
        return {
            "events": self.metrics.get_count("event.custom", since),
            "page_views": self.metrics.get_count("page_view", since),
            "avg_page_duration_ms": self.metrics.get_avg("page_duration_ms", since),
            "active_users": len([u for u in self.users.values() if u.last_seen >= since]),
            "active_sessions": len([s for s in self.sessions.values() if s.last_activity >= since])
        }

    def get_top_pages(self, limit: int = 10, since: datetime = None) -> List[Dict[str, Any]]:
        views = self.store.query_page_views(since=since, limit=10000)
        counts: Dict[str, int] = {}
        for view in views:
            counts[view.url] = counts.get(view.url, 0) + 1
        
        sorted_pages = sorted(counts.items(), key=lambda x: x[1], reverse=True)[:limit]
        return [{"url": url, "views": count} for url, count in sorted_pages]


def example_usage():
    analytics = Analytics()
    
    user = analytics.identify("user-123", traits={"name": "Alice", "plan": "pro"})
    print(f"Identified user: {user.id}")
    
    session = analytics.start_session(user.id)
    print(f"Started session: {session.id}")
    
    analytics.page("/", "Home", session_id=session.id, user_id=user.id, duration_ms=5000)
    analytics.page("/products", "Products", referrer="/", session_id=session.id, user_id=user.id, duration_ms=8000)
    
    analytics.track(EventType.CLICK, "add_to_cart", user_id=user.id, session_id=session.id, properties={"product_id": "SKU-123", "price": 29.99})
    analytics.track(EventType.PURCHASE, "checkout", user_id=user.id, session_id=session.id, properties={"order_id": "ORD-456", "total": 29.99})
    
    funnel = analytics.create_funnel("purchase", ["view_product", "add_to_cart", "checkout", "payment"])
    analytics.track_funnel("purchase", user.id, "view_product")
    analytics.track_funnel("purchase", user.id, "add_to_cart")
    analytics.track_funnel("purchase", user.id, "checkout")
    
    print(f"\nFunnel conversion: {funnel.get_conversion_rates()}")
    
    stats = analytics.get_stats()
    print(f"\nStats: {stats}")
    
    top_pages = analytics.get_top_pages()
    print(f"Top pages: {top_pages}")


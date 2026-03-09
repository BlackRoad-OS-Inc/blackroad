"""
RoadMonitor - Health Monitoring for BlackRoad
Health checks, metrics collection, and alerting.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import asyncio
import json
import logging
import statistics
import threading
import time

logger = logging.getLogger(__name__)


class HealthStatus(str, Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"


class AlertSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


@dataclass
class HealthCheck:
    name: str
    check_fn: Callable[[], bool]
    interval_seconds: float = 30
    timeout_seconds: float = 10
    failure_threshold: int = 3
    success_threshold: int = 1
    tags: List[str] = field(default_factory=list)


@dataclass
class HealthCheckResult:
    name: str
    status: HealthStatus
    message: str = ""
    latency_ms: float = 0
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class Alert:
    id: str
    name: str
    severity: AlertSeverity
    message: str
    source: str
    timestamp: datetime = field(default_factory=datetime.now)
    resolved: bool = False


@dataclass
class MetricPoint:
    name: str
    value: float
    timestamp: datetime = field(default_factory=datetime.now)
    tags: Dict[str, str] = field(default_factory=dict)


class MetricsCollector:
    def __init__(self, max_points: int = 10000):
        self.max_points = max_points
        self.points: Dict[str, List[MetricPoint]] = {}
        self.counters: Dict[str, float] = {}
        self.gauges: Dict[str, float] = {}
        self._lock = threading.Lock()

    def counter(self, name: str, value: float = 1, tags: Dict[str, str] = None) -> None:
        with self._lock:
            key = self._make_key(name, tags)
            if key not in self.counters:
                self.counters[key] = 0
            self.counters[key] += value
            self._record_point(name, self.counters[key], tags)

    def gauge(self, name: str, value: float, tags: Dict[str, str] = None) -> None:
        with self._lock:
            key = self._make_key(name, tags)
            self.gauges[key] = value
            self._record_point(name, value, tags)

    def timing(self, name: str, duration_ms: float, tags: Dict[str, str] = None) -> None:
        self._record_point(name, duration_ms, tags)

    def _make_key(self, name: str, tags: Dict[str, str] = None) -> str:
        if not tags:
            return name
        tag_str = ",".join(f"{k}={v}" for k, v in sorted(tags.items()))
        return f"{name}[{tag_str}]"

    def _record_point(self, name: str, value: float, tags: Dict[str, str] = None) -> None:
        point = MetricPoint(name=name, value=value, tags=tags or {})
        if name not in self.points:
            self.points[name] = []
        self.points[name].append(point)
        if len(self.points[name]) > self.max_points:
            self.points[name] = self.points[name][-self.max_points:]

    def get_stats(self, name: str, window_seconds: float = 300) -> Dict[str, float]:
        with self._lock:
            if name not in self.points:
                return {}
            cutoff = datetime.now() - timedelta(seconds=window_seconds)
            values = [p.value for p in self.points[name] if p.timestamp > cutoff]
            if not values:
                return {}
            return {"count": len(values), "sum": sum(values), "min": min(values), "max": max(values), "avg": statistics.mean(values)}

    def get_percentile(self, name: str, percentile: float, window_seconds: float = 300) -> float:
        with self._lock:
            if name not in self.points:
                return 0
            cutoff = datetime.now() - timedelta(seconds=window_seconds)
            values = sorted([p.value for p in self.points[name] if p.timestamp > cutoff])
            if not values:
                return 0
            idx = int(len(values) * percentile / 100)
            return values[min(idx, len(values) - 1)]


class HealthChecker:
    def __init__(self):
        self.checks: Dict[str, HealthCheck] = {}
        self.results: Dict[str, HealthCheckResult] = {}
        self.failure_counts: Dict[str, int] = {}
        self.success_counts: Dict[str, int] = {}
        self._lock = threading.Lock()

    def register(self, check: HealthCheck) -> None:
        with self._lock:
            self.checks[check.name] = check
            self.failure_counts[check.name] = 0
            self.success_counts[check.name] = 0

    async def run_check(self, name: str) -> HealthCheckResult:
        check = self.checks.get(name)
        if not check:
            return HealthCheckResult(name=name, status=HealthStatus.UNKNOWN, message="Check not found")
        start = time.time()
        try:
            result = check.check_fn()
            if asyncio.iscoroutine(result):
                result = await asyncio.wait_for(result, timeout=check.timeout_seconds)
            latency = (time.time() - start) * 1000
            if result:
                self.success_counts[name] = self.success_counts.get(name, 0) + 1
                self.failure_counts[name] = 0
                status = HealthStatus.HEALTHY if self.success_counts[name] >= check.success_threshold else HealthStatus.DEGRADED
            else:
                self.failure_counts[name] = self.failure_counts.get(name, 0) + 1
                self.success_counts[name] = 0
                status = HealthStatus.UNHEALTHY if self.failure_counts[name] >= check.failure_threshold else HealthStatus.DEGRADED
            check_result = HealthCheckResult(name=name, status=status, latency_ms=latency)
        except asyncio.TimeoutError:
            check_result = HealthCheckResult(name=name, status=HealthStatus.UNHEALTHY, message="Check timed out", latency_ms=check.timeout_seconds * 1000)
        except Exception as e:
            check_result = HealthCheckResult(name=name, status=HealthStatus.UNHEALTHY, message=str(e), latency_ms=(time.time() - start) * 1000)
        with self._lock:
            self.results[name] = check_result
        return check_result

    async def run_all(self) -> Dict[str, HealthCheckResult]:
        tasks = [self.run_check(name) for name in self.checks]
        await asyncio.gather(*tasks)
        return self.results.copy()

    def get_overall_status(self) -> HealthStatus:
        if not self.results:
            return HealthStatus.UNKNOWN
        statuses = [r.status for r in self.results.values()]
        if any(s == HealthStatus.UNHEALTHY for s in statuses):
            return HealthStatus.UNHEALTHY
        if any(s == HealthStatus.DEGRADED for s in statuses):
            return HealthStatus.DEGRADED
        if all(s == HealthStatus.HEALTHY for s in statuses):
            return HealthStatus.HEALTHY
        return HealthStatus.UNKNOWN


class AlertManager:
    def __init__(self):
        self.alerts: Dict[str, Alert] = {}
        self.handlers: List[Callable[[Alert], None]] = []
        self._lock = threading.Lock()

    def add_handler(self, handler: Callable[[Alert], None]) -> None:
        self.handlers.append(handler)

    def fire(self, name: str, severity: AlertSeverity, message: str, source: str = "", **metadata) -> Alert:
        import uuid
        alert = Alert(id=str(uuid.uuid4())[:8], name=name, severity=severity, message=message, source=source)
        with self._lock:
            self.alerts[alert.id] = alert
        for handler in self.handlers:
            try:
                handler(alert)
            except Exception as e:
                logger.error(f"Alert handler error: {e}")
        return alert

    def resolve(self, alert_id: str) -> bool:
        with self._lock:
            if alert_id in self.alerts:
                self.alerts[alert_id].resolved = True
                return True
            return False

    def get_active(self) -> List[Alert]:
        return [a for a in self.alerts.values() if not a.resolved]


class MonitorManager:
    def __init__(self):
        self.metrics = MetricsCollector()
        self.health = HealthChecker()
        self.alerts = AlertManager()

    def add_health_check(self, name: str, check_fn: Callable, interval: float = 30, **kwargs) -> None:
        check = HealthCheck(name=name, check_fn=check_fn, interval_seconds=interval, **kwargs)
        self.health.register(check)

    def get_status(self) -> Dict[str, Any]:
        return {
            "status": self.health.get_overall_status().value,
            "checks": {name: {"status": r.status.value, "latency_ms": r.latency_ms} for name, r in self.health.results.items()},
            "alerts": {"active": len(self.alerts.get_active())}
        }

    def record_request(self, method: str, path: str, status: int, duration_ms: float) -> None:
        tags = {"method": method, "path": path, "status": str(status)}
        self.metrics.counter("http.requests", tags=tags)
        self.metrics.timing("http.duration", duration_ms, tags=tags)
        if status >= 500:
            self.metrics.counter("http.errors", tags=tags)


async def example_usage():
    monitor = MonitorManager()
    monitor.add_health_check("database", lambda: True, interval=30)
    monitor.add_health_check("cache", lambda: True, interval=60)
    monitor.alerts.add_handler(lambda a: print(f"ALERT: [{a.severity.value}] {a.name}: {a.message}"))
    results = await monitor.health.run_all()
    print(f"Health check results: {len(results)}")
    for name, result in results.items():
        print(f"  {name}: {result.status.value} ({result.latency_ms:.1f}ms)")
    for i in range(10):
        monitor.record_request("GET", "/api/users", 200, 50 + i * 10)
    stats = monitor.metrics.get_stats("http.duration")
    print(f"Request latency stats: {stats}")
    p99 = monitor.metrics.get_percentile("http.duration", 99)
    print(f"P99 latency: {p99:.1f}ms")
    alert = monitor.alerts.fire(name="high_latency", severity=AlertSeverity.WARNING, message="P99 latency above threshold", source="monitor")
    print(f"Fired alert: {alert.id}")
    status = monitor.get_status()
    print(f"Overall status: {status}")

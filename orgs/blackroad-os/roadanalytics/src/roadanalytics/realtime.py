"""
RoadAnalytics Real-Time Dashboard

Real-time analytics with live updates and streaming.

Features:
- Real-time event streaming
- Live dashboards
- Anomaly detection
- Alerting
- Metric aggregation
- Time-series storage
"""

from typing import Optional, Dict, Any, List, Callable, Awaitable
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
import asyncio
import json
import time
from collections import defaultdict


class MetricType(str, Enum):
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"
    SUMMARY = "summary"


class AggregationType(str, Enum):
    SUM = "sum"
    AVG = "avg"
    MIN = "min"
    MAX = "max"
    COUNT = "count"
    P50 = "p50"
    P95 = "p95"
    P99 = "p99"


@dataclass
class Metric:
    name: str
    value: float
    type: MetricType
    labels: Dict[str, str] = field(default_factory=dict)
    timestamp: int = field(default_factory=lambda: int(time.time() * 1000))

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "value": self.value,
            "type": self.type.value,
            "labels": self.labels,
            "timestamp": self.timestamp,
        }


@dataclass
class Alert:
    id: str
    name: str
    metric: str
    condition: str  # e.g., "> 100", "< 0.5"
    threshold: float
    duration_seconds: int
    severity: str  # critical, warning, info
    triggered_at: Optional[int] = None
    resolved_at: Optional[int] = None
    message: Optional[str] = None


@dataclass
class DashboardWidget:
    id: str
    type: str  # counter, chart, gauge, table
    title: str
    metric: str
    aggregation: AggregationType = AggregationType.SUM
    labels: Dict[str, str] = field(default_factory=dict)
    refresh_seconds: int = 5
    chart_type: str = "line"  # line, bar, area
    time_range_minutes: int = 60


class TimeSeriesStorage:
    """Store time-series data efficiently."""

    def __init__(self, storage):
        self.storage = storage
        self.retention_days = 30

    async def write(self, metric: Metric) -> None:
        """Write a metric point."""
        # Round to minute for aggregation
        minute = (metric.timestamp // 60000) * 60000
        key = f"ts:{metric.name}:{minute}"

        # Get existing data for this minute
        data = await self.storage.get(key) or {"points": [], "labels": {}}

        # Add point
        data["points"].append({
            "value": metric.value,
            "timestamp": metric.timestamp,
            "labels": metric.labels,
        })

        # Store with TTL
        ttl = self.retention_days * 86400
        await self.storage.put(key, data, ttl=ttl)

        # Update latest value for gauges
        if metric.type == MetricType.GAUGE:
            label_key = json.dumps(metric.labels, sort_keys=True)
            await self.storage.put(
                f"latest:{metric.name}:{label_key}",
                metric.to_dict(),
                ttl=3600,
            )

    async def query(
        self,
        metric_name: str,
        start_time: int,
        end_time: int,
        aggregation: AggregationType = AggregationType.AVG,
        labels: Optional[Dict[str, str]] = None,
        step_minutes: int = 1,
    ) -> List[Dict[str, Any]]:
        """Query time-series data."""
        results = []

        # Iterate through time range
        current = (start_time // 60000) * 60000
        while current <= end_time:
            key = f"ts:{metric_name}:{current}"
            data = await self.storage.get(key)

            if data and data.get("points"):
                # Filter by labels if specified
                points = data["points"]
                if labels:
                    points = [
                        p for p in points
                        if all(p.get("labels", {}).get(k) == v for k, v in labels.items())
                    ]

                if points:
                    values = [p["value"] for p in points]
                    aggregated = self._aggregate(values, aggregation)

                    results.append({
                        "timestamp": current,
                        "value": aggregated,
                    })

            current += step_minutes * 60000

        return results

    def _aggregate(self, values: List[float], agg: AggregationType) -> float:
        """Aggregate values."""
        if not values:
            return 0

        if agg == AggregationType.SUM:
            return sum(values)
        elif agg == AggregationType.AVG:
            return sum(values) / len(values)
        elif agg == AggregationType.MIN:
            return min(values)
        elif agg == AggregationType.MAX:
            return max(values)
        elif agg == AggregationType.COUNT:
            return len(values)
        elif agg == AggregationType.P50:
            return self._percentile(values, 50)
        elif agg == AggregationType.P95:
            return self._percentile(values, 95)
        elif agg == AggregationType.P99:
            return self._percentile(values, 99)
        return sum(values)

    def _percentile(self, values: List[float], p: int) -> float:
        """Calculate percentile."""
        sorted_values = sorted(values)
        k = (len(sorted_values) - 1) * p / 100
        f = int(k)
        c = f + 1
        if c >= len(sorted_values):
            return sorted_values[-1]
        return sorted_values[f] + (k - f) * (sorted_values[c] - sorted_values[f])

    async def get_latest(
        self,
        metric_name: str,
        labels: Optional[Dict[str, str]] = None,
    ) -> Optional[Dict[str, Any]]:
        """Get latest value for a metric."""
        label_key = json.dumps(labels or {}, sort_keys=True)
        return await self.storage.get(f"latest:{metric_name}:{label_key}")


class RealTimeAggregator:
    """Aggregate metrics in real-time."""

    def __init__(self):
        self.counters: Dict[str, float] = defaultdict(float)
        self.gauges: Dict[str, float] = {}
        self.histograms: Dict[str, List[float]] = defaultdict(list)
        self._lock = asyncio.Lock()

    async def increment(self, name: str, value: float = 1, labels: Dict[str, str] = None) -> None:
        """Increment a counter."""
        key = self._make_key(name, labels)
        async with self._lock:
            self.counters[key] += value

    async def set_gauge(self, name: str, value: float, labels: Dict[str, str] = None) -> None:
        """Set a gauge value."""
        key = self._make_key(name, labels)
        async with self._lock:
            self.gauges[key] = value

    async def observe(self, name: str, value: float, labels: Dict[str, str] = None) -> None:
        """Add observation to histogram."""
        key = self._make_key(name, labels)
        async with self._lock:
            self.histograms[key].append(value)
            # Keep last 1000 observations
            if len(self.histograms[key]) > 1000:
                self.histograms[key] = self.histograms[key][-1000:]

    async def get_snapshot(self) -> Dict[str, Any]:
        """Get current snapshot of all metrics."""
        async with self._lock:
            return {
                "counters": dict(self.counters),
                "gauges": dict(self.gauges),
                "histograms": {
                    k: {
                        "count": len(v),
                        "sum": sum(v),
                        "avg": sum(v) / len(v) if v else 0,
                        "min": min(v) if v else 0,
                        "max": max(v) if v else 0,
                    }
                    for k, v in self.histograms.items()
                },
                "timestamp": int(time.time() * 1000),
            }

    def _make_key(self, name: str, labels: Optional[Dict[str, str]]) -> str:
        """Create a unique key for metric + labels."""
        if not labels:
            return name
        label_str = ",".join(f"{k}={v}" for k, v in sorted(labels.items()))
        return f"{name}{{{label_str}}}"


class AnomalyDetector:
    """Detect anomalies in metrics."""

    def __init__(self, storage):
        self.storage = storage
        self.thresholds: Dict[str, Dict[str, float]] = {}

    async def train(
        self,
        metric_name: str,
        lookback_hours: int = 24,
    ) -> Dict[str, float]:
        """Train anomaly detector on historical data."""
        now = int(time.time() * 1000)
        start = now - (lookback_hours * 3600 * 1000)

        ts = TimeSeriesStorage(self.storage)
        data = await ts.query(metric_name, start, now, AggregationType.AVG)

        if len(data) < 10:
            return {"error": "Not enough data"}

        values = [d["value"] for d in data]
        mean = sum(values) / len(values)
        variance = sum((x - mean) ** 2 for x in values) / len(values)
        std_dev = variance ** 0.5

        thresholds = {
            "mean": mean,
            "std_dev": std_dev,
            "upper_3sigma": mean + 3 * std_dev,
            "lower_3sigma": mean - 3 * std_dev,
            "upper_2sigma": mean + 2 * std_dev,
            "lower_2sigma": mean - 2 * std_dev,
        }

        self.thresholds[metric_name] = thresholds
        await self.storage.put(f"anomaly_thresholds:{metric_name}", thresholds)

        return thresholds

    async def check(
        self,
        metric_name: str,
        value: float,
        sensitivity: float = 3.0,  # number of standard deviations
    ) -> Dict[str, Any]:
        """Check if a value is anomalous."""
        if metric_name not in self.thresholds:
            stored = await self.storage.get(f"anomaly_thresholds:{metric_name}")
            if stored:
                self.thresholds[metric_name] = stored
            else:
                return {"is_anomaly": False, "reason": "No thresholds trained"}

        t = self.thresholds[metric_name]
        upper = t["mean"] + sensitivity * t["std_dev"]
        lower = t["mean"] - sensitivity * t["std_dev"]

        is_anomaly = value > upper or value < lower

        return {
            "is_anomaly": is_anomaly,
            "value": value,
            "mean": t["mean"],
            "std_dev": t["std_dev"],
            "upper_bound": upper,
            "lower_bound": lower,
            "deviation": abs(value - t["mean"]) / t["std_dev"] if t["std_dev"] else 0,
        }


class AlertManager:
    """Manage alerts based on metrics."""

    def __init__(self, storage):
        self.storage = storage
        self.alerts: Dict[str, Alert] = {}
        self.handlers: List[Callable[[Alert], Awaitable[None]]] = []

    def register_alert(self, alert: Alert) -> None:
        """Register an alert definition."""
        self.alerts[alert.id] = alert

    def add_handler(self, handler: Callable[[Alert], Awaitable[None]]) -> None:
        """Add alert handler."""
        self.handlers.append(handler)

    async def evaluate(self, metric: Metric) -> Optional[Alert]:
        """Evaluate metric against alerts."""
        for alert in self.alerts.values():
            if alert.metric != metric.name:
                continue

            triggered = self._evaluate_condition(metric.value, alert.condition, alert.threshold)

            if triggered and not alert.triggered_at:
                # New alert
                alert.triggered_at = int(time.time())
                alert.message = f"{alert.name}: {metric.name} {alert.condition} {alert.threshold} (current: {metric.value})"

                await self._store_alert(alert)

                for handler in self.handlers:
                    await handler(alert)

                return alert

            elif not triggered and alert.triggered_at and not alert.resolved_at:
                # Resolved
                alert.resolved_at = int(time.time())
                await self._store_alert(alert)

        return None

    def _evaluate_condition(self, value: float, condition: str, threshold: float) -> bool:
        """Evaluate a condition."""
        if condition.startswith(">"):
            return value > threshold
        elif condition.startswith("<"):
            return value < threshold
        elif condition.startswith(">="):
            return value >= threshold
        elif condition.startswith("<="):
            return value <= threshold
        elif condition.startswith("=="):
            return value == threshold
        elif condition.startswith("!="):
            return value != threshold
        return False

    async def _store_alert(self, alert: Alert) -> None:
        """Store alert state."""
        await self.storage.put(f"alert:{alert.id}", {
            "id": alert.id,
            "name": alert.name,
            "metric": alert.metric,
            "severity": alert.severity,
            "triggered_at": alert.triggered_at,
            "resolved_at": alert.resolved_at,
            "message": alert.message,
        })

    async def get_active_alerts(self) -> List[Dict[str, Any]]:
        """Get all active alerts."""
        active = []
        for alert in self.alerts.values():
            if alert.triggered_at and not alert.resolved_at:
                active.append({
                    "id": alert.id,
                    "name": alert.name,
                    "severity": alert.severity,
                    "triggered_at": alert.triggered_at,
                    "message": alert.message,
                })
        return active


class Dashboard:
    """Real-time dashboard with widgets."""

    def __init__(self, storage):
        self.storage = storage
        self.widgets: Dict[str, DashboardWidget] = {}

    def add_widget(self, widget: DashboardWidget) -> None:
        """Add a widget to dashboard."""
        self.widgets[widget.id] = widget

    async def get_widget_data(self, widget_id: str) -> Dict[str, Any]:
        """Get data for a widget."""
        widget = self.widgets.get(widget_id)
        if not widget:
            return {"error": "Widget not found"}

        ts = TimeSeriesStorage(self.storage)
        now = int(time.time() * 1000)
        start = now - (widget.time_range_minutes * 60 * 1000)

        if widget.type == "counter":
            # Get latest value
            latest = await ts.get_latest(widget.metric, widget.labels)
            return {
                "type": "counter",
                "title": widget.title,
                "value": latest.get("value", 0) if latest else 0,
            }

        elif widget.type == "chart":
            # Get time series
            data = await ts.query(
                widget.metric,
                start,
                now,
                widget.aggregation,
                widget.labels,
            )
            return {
                "type": "chart",
                "chart_type": widget.chart_type,
                "title": widget.title,
                "data": data,
            }

        elif widget.type == "gauge":
            # Get latest value with min/max context
            latest = await ts.get_latest(widget.metric, widget.labels)
            data = await ts.query(widget.metric, start, now, AggregationType.AVG)
            values = [d["value"] for d in data] if data else [0]

            return {
                "type": "gauge",
                "title": widget.title,
                "value": latest.get("value", 0) if latest else 0,
                "min": min(values),
                "max": max(values),
            }

        return {"error": "Unknown widget type"}

    async def get_all_data(self) -> Dict[str, Any]:
        """Get data for all widgets."""
        results = {}
        for widget_id in self.widgets:
            results[widget_id] = await self.get_widget_data(widget_id)
        return results


class MetricsCollector:
    """Collect and process metrics."""

    def __init__(self, storage):
        self.storage = storage
        self.ts = TimeSeriesStorage(storage)
        self.aggregator = RealTimeAggregator()
        self.anomaly = AnomalyDetector(storage)
        self.alerts = AlertManager(storage)

    async def collect(self, metric: Metric) -> Dict[str, Any]:
        """Collect a metric."""
        # Store in time series
        await self.ts.write(metric)

        # Update real-time aggregates
        if metric.type == MetricType.COUNTER:
            await self.aggregator.increment(metric.name, metric.value, metric.labels)
        elif metric.type == MetricType.GAUGE:
            await self.aggregator.set_gauge(metric.name, metric.value, metric.labels)
        elif metric.type == MetricType.HISTOGRAM:
            await self.aggregator.observe(metric.name, metric.value, metric.labels)

        # Check anomalies
        anomaly_result = await self.anomaly.check(metric.name, metric.value)

        # Evaluate alerts
        alert = await self.alerts.evaluate(metric)

        return {
            "stored": True,
            "anomaly": anomaly_result,
            "alert": alert.message if alert else None,
        }

    async def query(
        self,
        metric: str,
        start: int,
        end: int,
        aggregation: str = "avg",
    ) -> List[Dict[str, Any]]:
        """Query metrics."""
        agg = AggregationType(aggregation)
        return await self.ts.query(metric, start, end, agg)


# FastAPI routes
def create_analytics_routes(collector: MetricsCollector, dashboard: Dashboard):
    """Create FastAPI routes for analytics."""
    from fastapi import APIRouter

    router = APIRouter(prefix="/analytics", tags=["analytics"])

    @router.post("/collect")
    async def collect_metric(metric: Dict[str, Any]):
        m = Metric(
            name=metric["name"],
            value=metric["value"],
            type=MetricType(metric.get("type", "gauge")),
            labels=metric.get("labels", {}),
        )
        result = await collector.collect(m)
        return result

    @router.get("/query/{metric}")
    async def query_metric(
        metric: str,
        start: int,
        end: int,
        aggregation: str = "avg",
    ):
        return await collector.query(metric, start, end, aggregation)

    @router.get("/dashboard")
    async def get_dashboard():
        return await dashboard.get_all_data()

    @router.get("/dashboard/{widget_id}")
    async def get_widget(widget_id: str):
        return await dashboard.get_widget_data(widget_id)

    @router.get("/alerts")
    async def get_alerts():
        return await collector.alerts.get_active_alerts()

    @router.get("/realtime")
    async def get_realtime():
        return await collector.aggregator.get_snapshot()

    return router

"""
RoadMetrics - Application Metrics & Observability for BlackRoad
Prometheus-compatible metrics collection, aggregation, and export.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union
import asyncio
import functools
import logging
import math
import re
import threading
import time
from collections import defaultdict
from contextlib import contextmanager

logger = logging.getLogger(__name__)


class MetricType(str, Enum):
    """Types of metrics."""
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"
    SUMMARY = "summary"


@dataclass
class MetricLabel:
    """Label for metric identification."""
    name: str
    value: str

    def __hash__(self) -> int:
        return hash((self.name, self.value))


@dataclass
class MetricSample:
    """A single metric sample."""
    name: str
    value: float
    timestamp: float
    labels: Dict[str, str] = field(default_factory=dict)

    def to_prometheus(self) -> str:
        """Format as Prometheus exposition format."""
        if self.labels:
            label_str = ",".join(f'{k}="{v}"' for k, v in sorted(self.labels.items()))
            return f'{self.name}{{{label_str}}} {self.value}'
        return f'{self.name} {self.value}'


class Counter:
    """Monotonically increasing counter metric."""

    def __init__(self, name: str, help_text: str = "", labels: Optional[List[str]] = None):
        self.name = name
        self.help_text = help_text
        self.label_names = labels or []
        self._values: Dict[tuple, float] = defaultdict(float)
        self._lock = threading.Lock()

    def _label_key(self, labels: Dict[str, str]) -> tuple:
        """Create label key for storage."""
        return tuple(sorted(labels.items()))

    def inc(self, value: float = 1, **labels) -> None:
        """Increment counter."""
        if value < 0:
            raise ValueError("Counter can only be incremented")
        with self._lock:
            key = self._label_key(labels)
            self._values[key] += value

    def labels(self, **label_values) -> "CounterChild":
        """Return labeled counter child."""
        return CounterChild(self, label_values)

    def collect(self) -> List[MetricSample]:
        """Collect all samples."""
        samples = []
        with self._lock:
            for label_key, value in self._values.items():
                labels = dict(label_key)
                samples.append(MetricSample(
                    name=self.name,
                    value=value,
                    timestamp=time.time(),
                    labels=labels
                ))
        return samples


class CounterChild:
    """Labeled counter child."""

    def __init__(self, counter: Counter, labels: Dict[str, str]):
        self._counter = counter
        self._labels = labels

    def inc(self, value: float = 1) -> None:
        self._counter.inc(value, **self._labels)


class Gauge:
    """Metric that can go up and down."""

    def __init__(self, name: str, help_text: str = "", labels: Optional[List[str]] = None):
        self.name = name
        self.help_text = help_text
        self.label_names = labels or []
        self._values: Dict[tuple, float] = defaultdict(float)
        self._lock = threading.Lock()

    def _label_key(self, labels: Dict[str, str]) -> tuple:
        return tuple(sorted(labels.items()))

    def set(self, value: float, **labels) -> None:
        """Set gauge value."""
        with self._lock:
            key = self._label_key(labels)
            self._values[key] = value

    def inc(self, value: float = 1, **labels) -> None:
        """Increment gauge."""
        with self._lock:
            key = self._label_key(labels)
            self._values[key] += value

    def dec(self, value: float = 1, **labels) -> None:
        """Decrement gauge."""
        with self._lock:
            key = self._label_key(labels)
            self._values[key] -= value

    def labels(self, **label_values) -> "GaugeChild":
        """Return labeled gauge child."""
        return GaugeChild(self, label_values)

    @contextmanager
    def track_inprogress(self, **labels):
        """Context manager to track in-progress operations."""
        self.inc(**labels)
        try:
            yield
        finally:
            self.dec(**labels)

    def set_to_current_time(self, **labels) -> None:
        """Set gauge to current time."""
        self.set(time.time(), **labels)

    def collect(self) -> List[MetricSample]:
        """Collect all samples."""
        samples = []
        with self._lock:
            for label_key, value in self._values.items():
                labels = dict(label_key)
                samples.append(MetricSample(
                    name=self.name,
                    value=value,
                    timestamp=time.time(),
                    labels=labels
                ))
        return samples


class GaugeChild:
    """Labeled gauge child."""

    def __init__(self, gauge: Gauge, labels: Dict[str, str]):
        self._gauge = gauge
        self._labels = labels

    def set(self, value: float) -> None:
        self._gauge.set(value, **self._labels)

    def inc(self, value: float = 1) -> None:
        self._gauge.inc(value, **self._labels)

    def dec(self, value: float = 1) -> None:
        self._gauge.dec(value, **self._labels)


class Histogram:
    """Histogram metric for tracking distributions."""

    DEFAULT_BUCKETS = (0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0, float("inf"))

    def __init__(
        self,
        name: str,
        help_text: str = "",
        labels: Optional[List[str]] = None,
        buckets: Optional[Tuple[float, ...]] = None
    ):
        self.name = name
        self.help_text = help_text
        self.label_names = labels or []
        self.buckets = buckets or self.DEFAULT_BUCKETS
        self._buckets: Dict[tuple, Dict[float, int]] = defaultdict(lambda: {b: 0 for b in self.buckets})
        self._sums: Dict[tuple, float] = defaultdict(float)
        self._counts: Dict[tuple, int] = defaultdict(int)
        self._lock = threading.Lock()

    def _label_key(self, labels: Dict[str, str]) -> tuple:
        return tuple(sorted(labels.items()))

    def observe(self, value: float, **labels) -> None:
        """Record an observation."""
        with self._lock:
            key = self._label_key(labels)
            self._sums[key] += value
            self._counts[key] += 1
            for bucket in self.buckets:
                if value <= bucket:
                    self._buckets[key][bucket] += 1

    def labels(self, **label_values) -> "HistogramChild":
        """Return labeled histogram child."""
        return HistogramChild(self, label_values)

    @contextmanager
    def time(self, **labels):
        """Context manager to time operations."""
        start = time.time()
        try:
            yield
        finally:
            self.observe(time.time() - start, **labels)

    def collect(self) -> List[MetricSample]:
        """Collect all samples."""
        samples = []
        timestamp = time.time()

        with self._lock:
            for label_key, bucket_values in self._buckets.items():
                labels = dict(label_key)

                # Bucket samples
                for bucket, count in sorted(bucket_values.items()):
                    bucket_labels = {**labels, "le": str(bucket)}
                    samples.append(MetricSample(
                        name=f"{self.name}_bucket",
                        value=count,
                        timestamp=timestamp,
                        labels=bucket_labels
                    ))

                # Sum sample
                samples.append(MetricSample(
                    name=f"{self.name}_sum",
                    value=self._sums[label_key],
                    timestamp=timestamp,
                    labels=labels
                ))

                # Count sample
                samples.append(MetricSample(
                    name=f"{self.name}_count",
                    value=self._counts[label_key],
                    timestamp=timestamp,
                    labels=labels
                ))

        return samples


class HistogramChild:
    """Labeled histogram child."""

    def __init__(self, histogram: Histogram, labels: Dict[str, str]):
        self._histogram = histogram
        self._labels = labels

    def observe(self, value: float) -> None:
        self._histogram.observe(value, **self._labels)

    @contextmanager
    def time(self):
        start = time.time()
        try:
            yield
        finally:
            self.observe(time.time() - start)


class Summary:
    """Summary metric for tracking distributions with quantiles."""

    def __init__(
        self,
        name: str,
        help_text: str = "",
        labels: Optional[List[str]] = None,
        quantiles: Optional[List[float]] = None,
        max_age: int = 600
    ):
        self.name = name
        self.help_text = help_text
        self.label_names = labels or []
        self.quantiles = quantiles or [0.5, 0.9, 0.99]
        self.max_age = max_age
        self._observations: Dict[tuple, List[Tuple[float, float]]] = defaultdict(list)
        self._lock = threading.Lock()

    def _label_key(self, labels: Dict[str, str]) -> tuple:
        return tuple(sorted(labels.items()))

    def _cleanup(self, key: tuple) -> None:
        """Remove old observations."""
        cutoff = time.time() - self.max_age
        self._observations[key] = [
            (t, v) for t, v in self._observations[key] if t > cutoff
        ]

    def observe(self, value: float, **labels) -> None:
        """Record an observation."""
        with self._lock:
            key = self._label_key(labels)
            self._observations[key].append((time.time(), value))
            self._cleanup(key)

    def labels(self, **label_values) -> "SummaryChild":
        """Return labeled summary child."""
        return SummaryChild(self, label_values)

    @contextmanager
    def time(self, **labels):
        """Context manager to time operations."""
        start = time.time()
        try:
            yield
        finally:
            self.observe(time.time() - start, **labels)

    def collect(self) -> List[MetricSample]:
        """Collect all samples."""
        samples = []
        timestamp = time.time()

        with self._lock:
            for label_key, observations in self._observations.items():
                labels = dict(label_key)
                self._cleanup(label_key)

                if not observations:
                    continue

                values = sorted([v for _, v in observations])
                count = len(values)
                total = sum(values)

                # Quantile samples
                for q in self.quantiles:
                    idx = int(q * count)
                    idx = min(idx, count - 1)
                    quantile_labels = {**labels, "quantile": str(q)}
                    samples.append(MetricSample(
                        name=self.name,
                        value=values[idx],
                        timestamp=timestamp,
                        labels=quantile_labels
                    ))

                # Sum sample
                samples.append(MetricSample(
                    name=f"{self.name}_sum",
                    value=total,
                    timestamp=timestamp,
                    labels=labels
                ))

                # Count sample
                samples.append(MetricSample(
                    name=f"{self.name}_count",
                    value=count,
                    timestamp=timestamp,
                    labels=labels
                ))

        return samples


class SummaryChild:
    """Labeled summary child."""

    def __init__(self, summary: Summary, labels: Dict[str, str]):
        self._summary = summary
        self._labels = labels

    def observe(self, value: float) -> None:
        self._summary.observe(value, **self._labels)

    @contextmanager
    def time(self):
        start = time.time()
        try:
            yield
        finally:
            self.observe(time.time() - start)


class MetricsRegistry:
    """Central registry for all metrics."""

    def __init__(self):
        self.metrics: Dict[str, Union[Counter, Gauge, Histogram, Summary]] = {}
        self._lock = threading.Lock()

    def register(self, metric: Union[Counter, Gauge, Histogram, Summary]) -> None:
        """Register a metric."""
        with self._lock:
            if metric.name in self.metrics:
                raise ValueError(f"Metric {metric.name} already registered")
            self.metrics[metric.name] = metric

    def unregister(self, name: str) -> None:
        """Unregister a metric."""
        with self._lock:
            self.metrics.pop(name, None)

    def get(self, name: str) -> Optional[Union[Counter, Gauge, Histogram, Summary]]:
        """Get metric by name."""
        return self.metrics.get(name)

    def counter(self, name: str, help_text: str = "", labels: Optional[List[str]] = None) -> Counter:
        """Create and register a counter."""
        metric = Counter(name, help_text, labels)
        self.register(metric)
        return metric

    def gauge(self, name: str, help_text: str = "", labels: Optional[List[str]] = None) -> Gauge:
        """Create and register a gauge."""
        metric = Gauge(name, help_text, labels)
        self.register(metric)
        return metric

    def histogram(
        self,
        name: str,
        help_text: str = "",
        labels: Optional[List[str]] = None,
        buckets: Optional[Tuple[float, ...]] = None
    ) -> Histogram:
        """Create and register a histogram."""
        metric = Histogram(name, help_text, labels, buckets)
        self.register(metric)
        return metric

    def summary(
        self,
        name: str,
        help_text: str = "",
        labels: Optional[List[str]] = None,
        quantiles: Optional[List[float]] = None
    ) -> Summary:
        """Create and register a summary."""
        metric = Summary(name, help_text, labels, quantiles)
        self.register(metric)
        return metric

    def collect(self) -> List[MetricSample]:
        """Collect all registered metrics."""
        samples = []
        with self._lock:
            for metric in self.metrics.values():
                samples.extend(metric.collect())
        return samples

    def export_prometheus(self) -> str:
        """Export metrics in Prometheus format."""
        lines = []
        for metric in self.metrics.values():
            # Help text
            lines.append(f"# HELP {metric.name} {metric.help_text}")

            # Type
            if isinstance(metric, Counter):
                lines.append(f"# TYPE {metric.name} counter")
            elif isinstance(metric, Gauge):
                lines.append(f"# TYPE {metric.name} gauge")
            elif isinstance(metric, Histogram):
                lines.append(f"# TYPE {metric.name} histogram")
            elif isinstance(metric, Summary):
                lines.append(f"# TYPE {metric.name} summary")

            # Samples
            for sample in metric.collect():
                lines.append(sample.to_prometheus())

        return "\n".join(lines)


# Global registry
REGISTRY = MetricsRegistry()


# Convenience functions
def counter(name: str, help_text: str = "", labels: Optional[List[str]] = None) -> Counter:
    """Create a counter in the default registry."""
    return REGISTRY.counter(name, help_text, labels)


def gauge(name: str, help_text: str = "", labels: Optional[List[str]] = None) -> Gauge:
    """Create a gauge in the default registry."""
    return REGISTRY.gauge(name, help_text, labels)


def histogram(
    name: str,
    help_text: str = "",
    labels: Optional[List[str]] = None,
    buckets: Optional[Tuple[float, ...]] = None
) -> Histogram:
    """Create a histogram in the default registry."""
    return REGISTRY.histogram(name, help_text, labels, buckets)


def summary(
    name: str,
    help_text: str = "",
    labels: Optional[List[str]] = None,
    quantiles: Optional[List[float]] = None
) -> Summary:
    """Create a summary in the default registry."""
    return REGISTRY.summary(name, help_text, labels, quantiles)


# Decorators
def count_calls(counter_metric: Counter):
    """Decorator to count function calls."""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            counter_metric.inc()
            return func(*args, **kwargs)

        @functools.wraps(func)
        async def async_wrapper(*args, **kwargs):
            counter_metric.inc()
            return await func(*args, **kwargs)

        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return wrapper

    return decorator


def time_calls(histogram_metric: Histogram):
    """Decorator to time function calls."""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            with histogram_metric.time():
                return func(*args, **kwargs)

        @functools.wraps(func)
        async def async_wrapper(*args, **kwargs):
            start = time.time()
            try:
                return await func(*args, **kwargs)
            finally:
                histogram_metric.observe(time.time() - start)

        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return wrapper

    return decorator


class MetricsExporter:
    """Export metrics to various backends."""

    def __init__(self, registry: MetricsRegistry):
        self.registry = registry

    def prometheus_handler(self) -> str:
        """Get Prometheus exposition format."""
        return self.registry.export_prometheus()

    def json_handler(self) -> Dict[str, Any]:
        """Get metrics as JSON."""
        samples = self.registry.collect()
        result = defaultdict(list)

        for sample in samples:
            result[sample.name].append({
                "value": sample.value,
                "timestamp": sample.timestamp,
                "labels": sample.labels
            })

        return dict(result)

    async def push_to_pushgateway(self, url: str, job: str) -> bool:
        """Push metrics to Prometheus Pushgateway."""
        # In production, use actual HTTP client
        logger.info(f"Would push metrics to {url} for job {job}")
        return True


class MetricsServer:
    """Simple HTTP server for metrics exposition."""

    def __init__(self, registry: MetricsRegistry, port: int = 9090):
        self.registry = registry
        self.port = port
        self.exporter = MetricsExporter(registry)

    async def serve(self) -> None:
        """Start metrics server."""
        from http.server import HTTPServer, BaseHTTPRequestHandler

        exporter = self.exporter

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                if self.path == "/metrics":
                    content = exporter.prometheus_handler()
                    self.send_response(200)
                    self.send_header("Content-Type", "text/plain; charset=utf-8")
                    self.end_headers()
                    self.wfile.write(content.encode())
                else:
                    self.send_response(404)
                    self.end_headers()

            def log_message(self, format, *args):
                pass  # Suppress logging

        server = HTTPServer(("0.0.0.0", self.port), Handler)
        logger.info(f"Metrics server started on port {self.port}")
        server.serve_forever()


# Built-in process metrics
def register_process_metrics(registry: MetricsRegistry) -> None:
    """Register standard process metrics."""
    import os
    import resource

    process_cpu = registry.gauge("process_cpu_seconds_total", "Total CPU time spent")
    process_mem = registry.gauge("process_resident_memory_bytes", "Resident memory size")
    process_open_fds = registry.gauge("process_open_fds", "Number of open file descriptors")
    process_start_time = registry.gauge("process_start_time_seconds", "Process start time")

    process_start_time.set(time.time())

    async def update_metrics():
        while True:
            try:
                usage = resource.getrusage(resource.RUSAGE_SELF)
                process_cpu.set(usage.ru_utime + usage.ru_stime)
                process_mem.set(usage.ru_maxrss * 1024)  # Convert to bytes

                fd_count = len(os.listdir(f"/proc/{os.getpid()}/fd")) if os.path.exists("/proc") else 0
                process_open_fds.set(fd_count)
            except Exception:
                pass

            await asyncio.sleep(5)

    asyncio.create_task(update_metrics())


# Example usage
def example_usage():
    """Example metrics usage."""
    registry = MetricsRegistry()

    # Create metrics
    requests_total = registry.counter(
        "http_requests_total",
        "Total HTTP requests",
        labels=["method", "endpoint", "status"]
    )

    requests_duration = registry.histogram(
        "http_request_duration_seconds",
        "HTTP request duration",
        labels=["method", "endpoint"],
        buckets=(0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0)
    )

    active_connections = registry.gauge(
        "active_connections",
        "Number of active connections"
    )

    # Record metrics
    requests_total.labels(method="GET", endpoint="/api/users", status="200").inc()
    requests_total.labels(method="POST", endpoint="/api/users", status="201").inc()

    with requests_duration.labels(method="GET", endpoint="/api/users").time():
        time.sleep(0.1)  # Simulate request

    active_connections.inc()

    # Export
    print(registry.export_prometheus())

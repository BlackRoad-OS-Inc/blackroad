"""RoadCache Metrics Collector - Cache Metrics and Monitoring.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
from collections import deque
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Deque, Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)


class MetricType(Enum):
    """Types of metrics."""

    COUNTER = auto()     # Monotonically increasing
    GAUGE = auto()       # Point-in-time value
    HISTOGRAM = auto()   # Distribution of values
    TIMER = auto()       # Duration measurements


@dataclass
class MetricValue:
    """A single metric value.

    Attributes:
        name: Metric name
        value: Metric value
        metric_type: Type of metric
        tags: Metric tags
        timestamp: When recorded
    """

    name: str
    value: float
    metric_type: MetricType = MetricType.GAUGE
    tags: Dict[str, str] = field(default_factory=dict)
    timestamp: float = field(default_factory=time.time)


@dataclass
class CacheMetrics:
    """Cache metrics container.

    Attributes:
        hits: Cache hits
        misses: Cache misses
        sets: Set operations
        deletes: Delete operations
        evictions: Evictions
        expirations: Expirations
        entry_count: Current entries
        size_bytes: Current size
        latency_avg_ms: Average latency
        latency_p99_ms: P99 latency
        ops_per_second: Operations per second
    """

    hits: int = 0
    misses: int = 0
    sets: int = 0
    deletes: int = 0
    evictions: int = 0
    expirations: int = 0
    entry_count: int = 0
    size_bytes: int = 0
    latency_avg_ms: float = 0.0
    latency_p99_ms: float = 0.0
    ops_per_second: float = 0.0

    @property
    def hit_rate(self) -> float:
        """Calculate hit rate."""
        total = self.hits + self.misses
        return self.hits / total if total > 0 else 0.0

    @property
    def total_ops(self) -> int:
        """Get total operations."""
        return self.hits + self.misses + self.sets + self.deletes

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary.

        Returns:
            Metrics dictionary
        """
        return {
            "hits": self.hits,
            "misses": self.misses,
            "sets": self.sets,
            "deletes": self.deletes,
            "evictions": self.evictions,
            "expirations": self.expirations,
            "hit_rate": self.hit_rate,
            "entry_count": self.entry_count,
            "size_bytes": self.size_bytes,
            "latency_avg_ms": self.latency_avg_ms,
            "latency_p99_ms": self.latency_p99_ms,
            "ops_per_second": self.ops_per_second,
        }


class MetricsCollector:
    """Collects and aggregates cache metrics.

    Features:
    - Real-time metric collection
    - Latency histograms
    - Throughput calculation
    - Time-series data
    - Prometheus export

    Example:
        collector = MetricsCollector()
        collector.record_hit()
        collector.record_latency(5.2)

        metrics = collector.get_metrics()
        print(f"Hit rate: {metrics.hit_rate:.2%}")
    """

    def __init__(
        self,
        window_seconds: int = 60,
        histogram_buckets: int = 100,
    ):
        """Initialize collector.

        Args:
            window_seconds: Window for rate calculations
            histogram_buckets: Histogram bucket count
        """
        self.window_seconds = window_seconds
        self.histogram_buckets = histogram_buckets

        # Counters
        self._hits = 0
        self._misses = 0
        self._sets = 0
        self._deletes = 0
        self._evictions = 0
        self._expirations = 0

        # Gauges
        self._entry_count = 0
        self._size_bytes = 0

        # Time series for rate calculation
        self._ops_window: Deque[Tuple[float, int]] = deque()

        # Latency histogram
        self._latencies: Deque[float] = deque(maxlen=10000)

        self._lock = threading.RLock()

        # Callbacks for metric export
        self._exporters: List[Callable[[CacheMetrics], None]] = []

    def record_hit(self) -> None:
        """Record a cache hit."""
        with self._lock:
            self._hits += 1
            self._record_op()

    def record_miss(self) -> None:
        """Record a cache miss."""
        with self._lock:
            self._misses += 1
            self._record_op()

    def record_set(self) -> None:
        """Record a set operation."""
        with self._lock:
            self._sets += 1
            self._record_op()

    def record_delete(self) -> None:
        """Record a delete operation."""
        with self._lock:
            self._deletes += 1
            self._record_op()

    def record_eviction(self) -> None:
        """Record an eviction."""
        with self._lock:
            self._evictions += 1

    def record_expiration(self) -> None:
        """Record an expiration."""
        with self._lock:
            self._expirations += 1

    def record_latency(self, ms: float) -> None:
        """Record operation latency.

        Args:
            ms: Latency in milliseconds
        """
        with self._lock:
            self._latencies.append(ms)

    def set_entry_count(self, count: int) -> None:
        """Set current entry count.

        Args:
            count: Entry count
        """
        self._entry_count = count

    def set_size_bytes(self, size: int) -> None:
        """Set current size in bytes.

        Args:
            size: Size in bytes
        """
        self._size_bytes = size

    def _record_op(self) -> None:
        """Record operation for rate calculation."""
        now = time.time()
        self._ops_window.append((now, 1))

        # Remove old entries
        cutoff = now - self.window_seconds
        while self._ops_window and self._ops_window[0][0] < cutoff:
            self._ops_window.popleft()

    def _calculate_ops_per_second(self) -> float:
        """Calculate operations per second.

        Returns:
            Ops/second
        """
        if not self._ops_window:
            return 0.0

        now = time.time()
        cutoff = now - self.window_seconds

        # Clean old entries
        while self._ops_window and self._ops_window[0][0] < cutoff:
            self._ops_window.popleft()

        if not self._ops_window:
            return 0.0

        elapsed = now - self._ops_window[0][0]
        if elapsed == 0:
            return 0.0

        return len(self._ops_window) / elapsed

    def _calculate_latency_avg(self) -> float:
        """Calculate average latency.

        Returns:
            Average latency in ms
        """
        if not self._latencies:
            return 0.0
        return sum(self._latencies) / len(self._latencies)

    def _calculate_latency_p99(self) -> float:
        """Calculate P99 latency.

        Returns:
            P99 latency in ms
        """
        if not self._latencies:
            return 0.0

        sorted_latencies = sorted(self._latencies)
        idx = int(len(sorted_latencies) * 0.99)
        return sorted_latencies[min(idx, len(sorted_latencies) - 1)]

    def get_metrics(self) -> CacheMetrics:
        """Get current metrics.

        Returns:
            CacheMetrics instance
        """
        with self._lock:
            return CacheMetrics(
                hits=self._hits,
                misses=self._misses,
                sets=self._sets,
                deletes=self._deletes,
                evictions=self._evictions,
                expirations=self._expirations,
                entry_count=self._entry_count,
                size_bytes=self._size_bytes,
                latency_avg_ms=self._calculate_latency_avg(),
                latency_p99_ms=self._calculate_latency_p99(),
                ops_per_second=self._calculate_ops_per_second(),
            )

    def reset(self) -> None:
        """Reset all metrics."""
        with self._lock:
            self._hits = 0
            self._misses = 0
            self._sets = 0
            self._deletes = 0
            self._evictions = 0
            self._expirations = 0
            self._entry_count = 0
            self._size_bytes = 0
            self._ops_window.clear()
            self._latencies.clear()

    def add_exporter(self, exporter: Callable[[CacheMetrics], None]) -> None:
        """Add metrics exporter.

        Args:
            exporter: Callback to receive metrics
        """
        self._exporters.append(exporter)

    def export(self) -> None:
        """Export metrics to all exporters."""
        metrics = self.get_metrics()
        for exporter in self._exporters:
            try:
                exporter(metrics)
            except Exception as e:
                logger.error(f"Exporter error: {e}")

    def to_prometheus(self) -> str:
        """Export metrics in Prometheus format.

        Returns:
            Prometheus-formatted metrics
        """
        metrics = self.get_metrics()
        lines = [
            f"# HELP cache_hits_total Total cache hits",
            f"# TYPE cache_hits_total counter",
            f"cache_hits_total {metrics.hits}",
            f"",
            f"# HELP cache_misses_total Total cache misses",
            f"# TYPE cache_misses_total counter",
            f"cache_misses_total {metrics.misses}",
            f"",
            f"# HELP cache_hit_rate Cache hit rate",
            f"# TYPE cache_hit_rate gauge",
            f"cache_hit_rate {metrics.hit_rate:.4f}",
            f"",
            f"# HELP cache_entries Current entry count",
            f"# TYPE cache_entries gauge",
            f"cache_entries {metrics.entry_count}",
            f"",
            f"# HELP cache_size_bytes Current size in bytes",
            f"# TYPE cache_size_bytes gauge",
            f"cache_size_bytes {metrics.size_bytes}",
            f"",
            f"# HELP cache_latency_avg_ms Average latency",
            f"# TYPE cache_latency_avg_ms gauge",
            f"cache_latency_avg_ms {metrics.latency_avg_ms:.2f}",
            f"",
            f"# HELP cache_latency_p99_ms P99 latency",
            f"# TYPE cache_latency_p99_ms gauge",
            f"cache_latency_p99_ms {metrics.latency_p99_ms:.2f}",
            f"",
            f"# HELP cache_ops_per_second Operations per second",
            f"# TYPE cache_ops_per_second gauge",
            f"cache_ops_per_second {metrics.ops_per_second:.2f}",
        ]
        return "\n".join(lines)

    def __repr__(self) -> str:
        metrics = self.get_metrics()
        return f"MetricsCollector(hits={metrics.hits}, hit_rate={metrics.hit_rate:.2%})"


class Timer:
    """Context manager for timing operations."""

    def __init__(self, collector: MetricsCollector):
        """Initialize timer.

        Args:
            collector: Metrics collector
        """
        self._collector = collector
        self._start: float = 0.0

    def __enter__(self) -> "Timer":
        self._start = time.time()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        elapsed_ms = (time.time() - self._start) * 1000
        self._collector.record_latency(elapsed_ms)


__all__ = [
    "MetricsCollector",
    "CacheMetrics",
    "MetricType",
    "MetricValue",
    "Timer",
]

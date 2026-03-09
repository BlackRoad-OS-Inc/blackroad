"""RoadQueue Monitor - System Monitoring.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Callable, Dict, List, Optional

logger = logging.getLogger(__name__)


@dataclass
class QueueMetrics:
    """Metrics for a queue."""

    queue_name: str
    messages_ready: int = 0
    messages_unacked: int = 0
    messages_total: int = 0
    consumers: int = 0
    publish_rate: float = 0.0
    consume_rate: float = 0.0
    avg_latency_ms: float = 0.0
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class SystemMetrics:
    """System-wide metrics."""

    total_queues: int = 0
    total_messages: int = 0
    total_consumers: int = 0
    messages_published: int = 0
    messages_consumed: int = 0
    publish_rate: float = 0.0
    consume_rate: float = 0.0
    uptime_seconds: float = 0.0
    timestamp: datetime = field(default_factory=datetime.now)


class Monitor:
    """System monitoring service."""

    def __init__(
        self,
        check_interval_seconds: int = 10,
        retention_hours: int = 24,
    ):
        self.check_interval = check_interval_seconds
        self.retention = timedelta(hours=retention_hours)

        self._queue_metrics: Dict[str, List[QueueMetrics]] = defaultdict(list)
        self._system_metrics: List[SystemMetrics] = []
        self._callbacks: List[Callable[[QueueMetrics], None]] = []
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._lock = threading.RLock()
        self._started_at: Optional[datetime] = None

        # Counters
        self._publish_count = 0
        self._consume_count = 0
        self._last_count_time = time.time()

    def record_publish(self, queue_name: str) -> None:
        """Record a message publish."""
        with self._lock:
            self._publish_count += 1

    def record_consume(self, queue_name: str, latency_ms: float) -> None:
        """Record a message consume."""
        with self._lock:
            self._consume_count += 1

    def record_queue_metrics(self, metrics: QueueMetrics) -> None:
        """Record queue metrics."""
        with self._lock:
            self._queue_metrics[metrics.queue_name].append(metrics)
            self._cleanup_old_metrics()

        for callback in self._callbacks:
            try:
                callback(metrics)
            except Exception as e:
                logger.error(f"Metrics callback error: {e}")

    def _cleanup_old_metrics(self) -> None:
        """Remove old metrics data."""
        cutoff = datetime.now() - self.retention
        for queue_name in list(self._queue_metrics.keys()):
            self._queue_metrics[queue_name] = [
                m for m in self._queue_metrics[queue_name]
                if m.timestamp > cutoff
            ]

    def get_queue_metrics(
        self,
        queue_name: str,
        since: Optional[datetime] = None,
    ) -> List[QueueMetrics]:
        """Get metrics for a queue."""
        with self._lock:
            metrics = self._queue_metrics.get(queue_name, [])
            if since:
                metrics = [m for m in metrics if m.timestamp >= since]
            return metrics

    def get_system_metrics(self) -> SystemMetrics:
        """Get current system metrics."""
        now = time.time()
        elapsed = now - self._last_count_time

        with self._lock:
            publish_rate = self._publish_count / max(elapsed, 1)
            consume_rate = self._consume_count / max(elapsed, 1)

            # Reset counters
            self._publish_count = 0
            self._consume_count = 0
            self._last_count_time = now

            uptime = 0.0
            if self._started_at:
                uptime = (datetime.now() - self._started_at).total_seconds()

            return SystemMetrics(
                total_queues=len(self._queue_metrics),
                total_messages=sum(
                    m[-1].messages_total if m else 0
                    for m in self._queue_metrics.values()
                ),
                publish_rate=publish_rate,
                consume_rate=consume_rate,
                uptime_seconds=uptime,
            )

    def on_metrics(self, callback: Callable[[QueueMetrics], None]) -> None:
        """Register metrics callback."""
        self._callbacks.append(callback)

    def start(self) -> None:
        """Start monitoring."""
        if self._running:
            return

        self._running = True
        self._started_at = datetime.now()
        logger.info("Monitor started")

    def stop(self) -> None:
        """Stop monitoring."""
        self._running = False
        logger.info("Monitor stopped")

    def get_health_status(self) -> Dict[str, Any]:
        """Get system health status."""
        return {
            "status": "healthy" if self._running else "stopped",
            "uptime_seconds": (datetime.now() - self._started_at).total_seconds()
            if self._started_at else 0,
            "queues_monitored": len(self._queue_metrics),
        }


__all__ = ["Monitor", "QueueMetrics", "SystemMetrics"]

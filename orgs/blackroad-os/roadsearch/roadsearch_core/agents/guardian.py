"""RoadSearch Index Guardian Agent - Index Health & Maintenance.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
import logging
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

@dataclass
class IndexHealthReport:
    """Index health assessment."""
    healthy: bool = True
    score: float = 100.0
    issues: List[str] = field(default_factory=list)
    recommendations: List[str] = field(default_factory=list)
    timestamp: datetime = field(default_factory=datetime.now)

class IndexGuardian:
    """Index Guardian Agent - Index Health & Maintenance.

    Monitors index health, triggers optimizations, and ensures
    search performance remains optimal.
    """

    def __init__(
        self,
        check_interval_seconds: int = 300,
        max_segment_count: int = 50,
        max_deleted_ratio: float = 0.3,
    ):
        self.check_interval = check_interval_seconds
        self.max_segment_count = max_segment_count
        self.max_deleted_ratio = max_deleted_ratio

        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._last_check: Optional[datetime] = None
        self._alerts: List[Dict[str, Any]] = []
        self._stats = {"checks": 0, "optimizations": 0, "alerts": 0}

    def start(self) -> None:
        """Start guardian monitoring."""
        self._running = True
        self._thread = threading.Thread(target=self._monitor_loop, daemon=True)
        self._thread.start()
        logger.info("Index Guardian started")

    def stop(self) -> None:
        """Stop guardian monitoring."""
        self._running = False
        if self._thread:
            self._thread.join(timeout=5.0)
        logger.info("Index Guardian stopped")

    def _monitor_loop(self) -> None:
        while self._running:
            try:
                self.check_health()
            except Exception as e:
                logger.error(f"Guardian check failed: {e}")
            time.sleep(self.check_interval)

    def check_health(self, index_stats: Dict[str, Any] = None) -> IndexHealthReport:
        """Check index health."""
        self._stats["checks"] += 1
        self._last_check = datetime.now()

        report = IndexHealthReport()
        stats = index_stats or {}

        # Check segment count
        segment_count = stats.get("segment_count", 0)
        if segment_count > self.max_segment_count:
            report.issues.append(f"Too many segments: {segment_count}")
            report.recommendations.append("Run optimize() to merge segments")
            report.score -= 20

        # Check deleted documents ratio
        doc_count = stats.get("doc_count", 1)
        deleted_count = stats.get("deleted_count", 0)
        deleted_ratio = deleted_count / max(1, doc_count)
        if deleted_ratio > self.max_deleted_ratio:
            report.issues.append(f"High deleted ratio: {deleted_ratio:.1%}")
            report.recommendations.append("Purge deleted documents")
            report.score -= 15

        # Check index size
        size_mb = stats.get("size_bytes", 0) / (1024 * 1024)
        if size_mb > 10000:  # 10GB
            report.issues.append(f"Large index: {size_mb:.1f}MB")
            report.recommendations.append("Consider sharding")
            report.score -= 10

        report.healthy = report.score >= 70

        if report.issues:
            self._stats["alerts"] += len(report.issues)
            self._alerts.extend([{"issue": i, "time": datetime.now()} for i in report.issues])

        return report

    def get_alerts(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent alerts."""
        return self._alerts[-limit:]

    def clear_alerts(self) -> None:
        """Clear all alerts."""
        self._alerts = []

    def get_statistics(self) -> Dict[str, Any]:
        return {
            **self._stats,
            "last_check": self._last_check.isoformat() if self._last_check else None,
            "running": self._running,
        }

__all__ = ["IndexGuardian", "IndexHealthReport"]

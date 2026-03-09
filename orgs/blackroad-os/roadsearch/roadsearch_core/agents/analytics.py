"""RoadSearch Analytics Agent - Search Analytics & Insights.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
import logging
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)

@dataclass
class QueryMetrics:
    """Metrics for a query."""
    query: str
    count: int = 0
    avg_latency_ms: float = 0.0
    avg_results: float = 0.0
    click_through_rate: float = 0.0
    zero_result_rate: float = 0.0

@dataclass
class SearchAnalytics:
    """Aggregated search analytics."""
    total_queries: int = 0
    unique_queries: int = 0
    avg_latency_ms: float = 0.0
    zero_result_queries: int = 0
    top_queries: List[QueryMetrics] = field(default_factory=list)
    period_start: datetime = field(default_factory=datetime.now)
    period_end: datetime = field(default_factory=datetime.now)

class AnalyticsAgent:
    """Analytics Agent - Search Analytics & Insights.

    Collects and analyzes search metrics for optimization insights.
    """

    def __init__(self, retention_days: int = 30):
        self.retention_days = retention_days
        self._query_stats: Dict[str, Dict[str, Any]] = defaultdict(lambda: {
            "count": 0, "total_latency": 0, "total_results": 0, "clicks": 0, "zero_results": 0
        })
        self._daily_stats: Dict[str, Dict[str, int]] = defaultdict(lambda: {"queries": 0, "clicks": 0})
        self._hourly_stats: Dict[int, int] = defaultdict(int)

    def record_query(
        self,
        query: str,
        latency_ms: float,
        result_count: int,
        clicked: bool = False,
    ) -> None:
        """Record a search query."""
        stats = self._query_stats[query.lower()]
        stats["count"] += 1
        stats["total_latency"] += latency_ms
        stats["total_results"] += result_count
        if clicked:
            stats["clicks"] += 1
        if result_count == 0:
            stats["zero_results"] += 1

        # Daily/hourly tracking
        today = datetime.now().strftime("%Y-%m-%d")
        self._daily_stats[today]["queries"] += 1
        if clicked:
            self._daily_stats[today]["clicks"] += 1
        self._hourly_stats[datetime.now().hour] += 1

    def get_query_metrics(self, query: str) -> Optional[QueryMetrics]:
        """Get metrics for a specific query."""
        query_lower = query.lower()
        if query_lower not in self._query_stats:
            return None

        stats = self._query_stats[query_lower]
        count = stats["count"]
        return QueryMetrics(
            query=query,
            count=count,
            avg_latency_ms=stats["total_latency"] / max(1, count),
            avg_results=stats["total_results"] / max(1, count),
            click_through_rate=stats["clicks"] / max(1, count),
            zero_result_rate=stats["zero_results"] / max(1, count),
        )

    def get_top_queries(self, limit: int = 10) -> List[QueryMetrics]:
        """Get top queries by volume."""
        sorted_queries = sorted(
            self._query_stats.items(),
            key=lambda x: x[1]["count"],
            reverse=True,
        )[:limit]

        return [
            QueryMetrics(
                query=q,
                count=s["count"],
                avg_latency_ms=s["total_latency"] / max(1, s["count"]),
                avg_results=s["total_results"] / max(1, s["count"]),
                click_through_rate=s["clicks"] / max(1, s["count"]),
            )
            for q, s in sorted_queries
        ]

    def get_zero_result_queries(self, limit: int = 10) -> List[Tuple[str, int]]:
        """Get queries with zero results."""
        zero_queries = [
            (q, s["zero_results"])
            for q, s in self._query_stats.items()
            if s["zero_results"] > 0
        ]
        zero_queries.sort(key=lambda x: x[1], reverse=True)
        return zero_queries[:limit]

    def get_analytics_report(self) -> SearchAnalytics:
        """Generate analytics report."""
        total_queries = sum(s["count"] for s in self._query_stats.values())
        total_latency = sum(s["total_latency"] for s in self._query_stats.values())
        zero_results = sum(s["zero_results"] for s in self._query_stats.values())

        return SearchAnalytics(
            total_queries=total_queries,
            unique_queries=len(self._query_stats),
            avg_latency_ms=total_latency / max(1, total_queries),
            zero_result_queries=zero_results,
            top_queries=self.get_top_queries(10),
        )

    def get_peak_hours(self) -> List[Tuple[int, int]]:
        """Get peak query hours."""
        return sorted(self._hourly_stats.items(), key=lambda x: x[1], reverse=True)[:5]

    def get_statistics(self) -> Dict[str, Any]:
        return {
            "unique_queries": len(self._query_stats),
            "total_queries": sum(s["count"] for s in self._query_stats.values()),
            "days_tracked": len(self._daily_stats),
        }

__all__ = ["AnalyticsAgent", "QueryMetrics", "SearchAnalytics"]

"""RoadSearch Aggregations - Statistical Aggregations.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

class Aggregation(ABC):
    """Base aggregation class."""

    def __init__(self, name: str, field: str):
        self.name = name
        self.field = field

    @abstractmethod
    def add(self, value: Any) -> None:
        pass

    @abstractmethod
    def result(self) -> Dict[str, Any]:
        pass

class TermsAggregation(Aggregation):
    """Count documents per term value."""

    def __init__(self, name: str, field: str, size: int = 10):
        super().__init__(name, field)
        self.size = size
        self._counts: Dict[str, int] = {}

    def add(self, value: Any) -> None:
        if value is not None:
            key = str(value)
            self._counts[key] = self._counts.get(key, 0) + 1

    def result(self) -> Dict[str, Any]:
        sorted_terms = sorted(self._counts.items(), key=lambda x: x[1], reverse=True)
        return {
            "buckets": [{"key": k, "doc_count": c} for k, c in sorted_terms[:self.size]],
            "sum_other_doc_count": sum(c for _, c in sorted_terms[self.size:]),
        }

class RangeAggregation(Aggregation):
    """Count documents in ranges."""

    def __init__(self, name: str, field: str, ranges: List[Dict[str, Any]]):
        super().__init__(name, field)
        self.ranges = ranges
        self._buckets: Dict[str, int] = {r.get("key", f"{r.get('from')}-{r.get('to')}"): 0 for r in ranges}

    def add(self, value: Any) -> None:
        if value is None:
            return
        for r in self.ranges:
            from_val = r.get("from")
            to_val = r.get("to")
            key = r.get("key", f"{from_val}-{to_val}")
            if (from_val is None or value >= from_val) and (to_val is None or value < to_val):
                self._buckets[key] = self._buckets.get(key, 0) + 1

    def result(self) -> Dict[str, Any]:
        return {"buckets": [{"key": k, "doc_count": c} for k, c in self._buckets.items()]}

class HistogramAggregation(Aggregation):
    """Fixed-interval histogram."""

    def __init__(self, name: str, field: str, interval: float):
        super().__init__(name, field)
        self.interval = interval
        self._buckets: Dict[float, int] = {}

    def add(self, value: Any) -> None:
        if value is not None:
            bucket = (value // self.interval) * self.interval
            self._buckets[bucket] = self._buckets.get(bucket, 0) + 1

    def result(self) -> Dict[str, Any]:
        return {"buckets": [{"key": k, "doc_count": c} for k, c in sorted(self._buckets.items())]}

class DateHistogramAggregation(Aggregation):
    """Date histogram aggregation."""

    def __init__(self, name: str, field: str, interval: str = "day"):
        super().__init__(name, field)
        self.interval = interval
        self._buckets: Dict[str, int] = {}

    def add(self, value: Any) -> None:
        if value is None:
            return
        if isinstance(value, datetime):
            key = value.strftime("%Y-%m-%d") if self.interval == "day" else value.strftime("%Y-%m")
            self._buckets[key] = self._buckets.get(key, 0) + 1

    def result(self) -> Dict[str, Any]:
        return {"buckets": [{"key": k, "doc_count": c} for k, c in sorted(self._buckets.items())]}

class StatsAggregation(Aggregation):
    """Statistical aggregation."""

    def __init__(self, name: str, field: str):
        super().__init__(name, field)
        self._count = 0
        self._sum = 0.0
        self._min = float("inf")
        self._max = float("-inf")
        self._sum_of_squares = 0.0

    def add(self, value: Any) -> None:
        if value is not None:
            v = float(value)
            self._count += 1
            self._sum += v
            self._min = min(self._min, v)
            self._max = max(self._max, v)
            self._sum_of_squares += v * v

    def result(self) -> Dict[str, Any]:
        avg = self._sum / self._count if self._count > 0 else 0
        variance = (self._sum_of_squares / self._count - avg * avg) if self._count > 0 else 0
        return {
            "count": self._count,
            "sum": self._sum,
            "min": self._min if self._count > 0 else None,
            "max": self._max if self._count > 0 else None,
            "avg": avg,
            "variance": variance,
            "std_deviation": variance ** 0.5,
        }

__all__ = ["Aggregation", "TermsAggregation", "RangeAggregation", "HistogramAggregation", "DateHistogramAggregation", "StatsAggregation"]

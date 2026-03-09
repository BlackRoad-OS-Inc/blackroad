"""RoadSearch Facet Builder - Faceted Search Implementation.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Set

@dataclass
class FacetValue:
    """A single facet value with count."""
    value: str
    count: int = 0
    selected: bool = False

@dataclass
class Facet:
    """Facet definition."""
    field: str
    values: List[FacetValue] = field(default_factory=list)
    missing_count: int = 0

@dataclass
class FacetResult:
    """Result of facet computation."""
    name: str
    values: List[FacetValue] = field(default_factory=list)
    total: int = 0
    other: int = 0
    missing: int = 0

class FacetBuilder:
    """Builds faceted search results."""

    def __init__(self, field: str, size: int = 10):
        self.field = field
        self.size = size
        self._counts: Dict[str, int] = {}
        self._missing = 0

    def add(self, value: Optional[Any]) -> None:
        if value is None:
            self._missing += 1
        else:
            str_value = str(value)
            self._counts[str_value] = self._counts.get(str_value, 0) + 1

    def build(self) -> FacetResult:
        sorted_values = sorted(self._counts.items(), key=lambda x: x[1], reverse=True)
        top_values = sorted_values[:self.size]
        other = sum(c for _, c in sorted_values[self.size:])

        return FacetResult(
            name=self.field,
            values=[FacetValue(value=v, count=c) for v, c in top_values],
            total=sum(self._counts.values()),
            other=other,
            missing=self._missing,
        )

__all__ = ["FacetBuilder", "Facet", "FacetValue", "FacetResult"]

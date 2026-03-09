"""RoadSearch Boosting - Score Boosting Functions.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
import math
from dataclasses import dataclass
from enum import Enum, auto
from typing import Any, Callable, Dict, Optional

class DecayType(Enum):
    LINEAR = auto()
    EXPONENTIAL = auto()
    GAUSSIAN = auto()

@dataclass
class DecayFunction:
    """Decay function for distance-based boosting."""
    origin: float = 0.0
    scale: float = 1.0
    offset: float = 0.0
    decay: float = 0.5
    decay_type: DecayType = DecayType.EXPONENTIAL

    def compute(self, value: float) -> float:
        distance = abs(value - self.origin) - self.offset
        if distance <= 0:
            return 1.0
        if self.decay_type == DecayType.LINEAR:
            return max(0, 1 - distance / self.scale)
        elif self.decay_type == DecayType.EXPONENTIAL:
            return math.exp(-distance * math.log(self.decay) / self.scale)
        else:  # GAUSSIAN
            return math.exp(-0.5 * (distance / self.scale) ** 2)

class FieldBooster:
    """Field-based score boosting."""

    def __init__(self, field_boosts: Dict[str, float] = None):
        self.field_boosts = field_boosts or {}

    def get_boost(self, field: str) -> float:
        return self.field_boosts.get(field, 1.0)

    def set_boost(self, field: str, boost: float) -> None:
        self.field_boosts[field] = boost

class FunctionScorer:
    """Custom function scoring."""

    def __init__(self, functions: list = None, score_mode: str = "multiply", boost_mode: str = "multiply"):
        self.functions = functions or []
        self.score_mode = score_mode
        self.boost_mode = boost_mode

    def add_function(self, func: Callable[[Dict[str, Any]], float], weight: float = 1.0) -> None:
        self.functions.append((func, weight))

    def compute(self, doc: Dict[str, Any], base_score: float) -> float:
        if not self.functions:
            return base_score

        func_scores = [weight * func(doc) for func, weight in self.functions]

        if self.score_mode == "sum":
            combined = sum(func_scores)
        elif self.score_mode == "avg":
            combined = sum(func_scores) / len(func_scores)
        elif self.score_mode == "max":
            combined = max(func_scores)
        elif self.score_mode == "min":
            combined = min(func_scores)
        else:  # multiply
            combined = 1.0
            for s in func_scores:
                combined *= s

        if self.boost_mode == "replace":
            return combined
        elif self.boost_mode == "sum":
            return base_score + combined
        else:  # multiply
            return base_score * combined

__all__ = ["FieldBooster", "FunctionScorer", "DecayFunction", "DecayType"]

"""RoadSearch Scorer - Base Scoring Components.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

@dataclass
class ScoringContext:
    """Context for scoring operations."""
    total_docs: int = 0
    avg_field_length: float = 0.0
    doc_id: str = ""
    field_length: int = 0
    boost: float = 1.0
    explain: bool = False

class Scorer(ABC):
    """Base scorer class."""

    @abstractmethod
    def score(self, term_freq: int, doc_freq: int, context: ScoringContext) -> float:
        pass

    def explain(self, term_freq: int, doc_freq: int, context: ScoringContext) -> Dict[str, Any]:
        return {"score": self.score(term_freq, doc_freq, context), "description": "base scorer"}

__all__ = ["Scorer", "ScoringContext"]

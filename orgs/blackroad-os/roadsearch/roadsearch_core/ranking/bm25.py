"""RoadSearch BM25 Scorer - Okapi BM25 Implementation.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
import math
from dataclasses import dataclass
from typing import Any, Dict
from roadsearch_core.ranking.scorer import Scorer, ScoringContext

@dataclass
class BM25Parameters:
    """BM25 algorithm parameters."""
    k1: float = 1.2  # Term frequency saturation
    b: float = 0.75  # Document length normalization

class BM25Scorer(Scorer):
    """BM25 (Best Matching 25) scorer."""

    def __init__(self, params: BM25Parameters = None):
        self.params = params or BM25Parameters()

    def score(self, term_freq: int, doc_freq: int, context: ScoringContext) -> float:
        if context.total_docs == 0 or doc_freq == 0:
            return 0.0

        idf = math.log((context.total_docs - doc_freq + 0.5) / (doc_freq + 0.5) + 1.0)
        avg_len = context.avg_field_length if context.avg_field_length > 0 else 1.0
        norm = 1 - self.params.b + self.params.b * (context.field_length / avg_len)
        tf_component = (term_freq * (self.params.k1 + 1)) / (term_freq + self.params.k1 * norm)

        return idf * tf_component * context.boost

    def explain(self, term_freq: int, doc_freq: int, context: ScoringContext) -> Dict[str, Any]:
        score = self.score(term_freq, doc_freq, context)
        return {
            "score": score,
            "description": f"BM25(tf={term_freq}, df={doc_freq}, k1={self.params.k1}, b={self.params.b})",
            "details": {"k1": self.params.k1, "b": self.params.b, "term_freq": term_freq, "doc_freq": doc_freq},
        }

__all__ = ["BM25Scorer", "BM25Parameters"]

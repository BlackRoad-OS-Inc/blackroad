"""RoadSearch TF-IDF Scorer.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
import math
from dataclasses import dataclass
from typing import Any, Dict
from roadsearch_core.ranking.scorer import Scorer, ScoringContext

@dataclass
class TFIDFConfig:
    """TF-IDF configuration."""
    sublinear_tf: bool = True  # Use 1 + log(tf)
    norm: str = "l2"  # Normalization: l2, l1, none

class TFIDFScorer(Scorer):
    """TF-IDF scorer."""

    def __init__(self, config: TFIDFConfig = None):
        self.config = config or TFIDFConfig()

    def score(self, term_freq: int, doc_freq: int, context: ScoringContext) -> float:
        if context.total_docs == 0 or doc_freq == 0 or term_freq == 0:
            return 0.0

        tf = 1.0 + math.log(term_freq) if self.config.sublinear_tf else term_freq
        idf = math.log(context.total_docs / doc_freq) + 1.0

        return tf * idf * context.boost

__all__ = ["TFIDFScorer", "TFIDFConfig"]

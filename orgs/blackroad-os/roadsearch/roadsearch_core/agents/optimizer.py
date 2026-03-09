"""RoadSearch Query Optimizer Agent - Intelligent Query Enhancement.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
import logging
import re
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Set, Tuple

logger = logging.getLogger(__name__)

@dataclass
class QueryRewrite:
    """A query rewrite suggestion."""
    original: str
    rewritten: str
    confidence: float = 0.0
    reason: str = ""

class QueryOptimizer:
    """Query Optimizer Agent - Intelligent Query Enhancement.

    Analyzes and rewrites queries to improve search results.
    """

    def __init__(self):
        self._synonym_map: Dict[str, List[str]] = {}
        self._spelling_corrections: Dict[str, str] = {}
        self._query_expansions: Dict[str, List[str]] = {}
        self._stats = {"queries_optimized": 0, "rewrites_applied": 0}

    def add_synonyms(self, term: str, synonyms: List[str]) -> None:
        self._synonym_map[term.lower()] = [s.lower() for s in synonyms]

    def add_spelling_correction(self, misspelling: str, correct: str) -> None:
        self._spelling_corrections[misspelling.lower()] = correct.lower()

    def optimize(self, query: str) -> QueryRewrite:
        """Optimize a query."""
        self._stats["queries_optimized"] += 1
        original = query
        reasons = []

        # Fix spelling
        words = query.lower().split()
        corrected = []
        for word in words:
            if word in self._spelling_corrections:
                corrected.append(self._spelling_corrections[word])
                reasons.append(f"corrected '{word}'")
            else:
                corrected.append(word)
        query = " ".join(corrected)

        # Expand synonyms
        expanded = []
        for word in query.split():
            expanded.append(word)
            if word in self._synonym_map:
                expanded.extend(self._synonym_map[word][:2])
                reasons.append(f"expanded '{word}'")
        query = " ".join(expanded)

        if query != original.lower():
            self._stats["rewrites_applied"] += 1

        return QueryRewrite(
            original=original,
            rewritten=query,
            confidence=0.9 if reasons else 1.0,
            reason="; ".join(reasons) if reasons else "no changes",
        )

    def suggest_queries(self, query: str, limit: int = 5) -> List[str]:
        """Suggest related queries."""
        suggestions = []
        terms = query.lower().split()

        for term in terms:
            if term in self._synonym_map:
                for syn in self._synonym_map[term][:2]:
                    suggestion = query.lower().replace(term, syn)
                    if suggestion not in suggestions:
                        suggestions.append(suggestion)

        return suggestions[:limit]

    def get_statistics(self) -> Dict[str, Any]:
        return self._stats.copy()

__all__ = ["QueryOptimizer", "QueryRewrite"]

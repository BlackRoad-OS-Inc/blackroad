"""RoadSearch Relevance Tuner Agent - AI-Powered Relevance Optimization.

The Relevance Tuner agent learns from user interactions to improve
search result ranking and relevance.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Tuple

logger = logging.getLogger(__name__)


class FeedbackType(Enum):
    """Types of relevance feedback."""

    CLICK = auto()
    DWELL = auto()  # Time spent on result
    CONVERSION = auto()  # Purchase, signup, etc.
    SKIP = auto()  # Passed over result
    EXPLICIT = auto()  # Explicit thumbs up/down


@dataclass
class FeedbackEvent:
    """A relevance feedback event.

    Attributes:
        query: Original query
        doc_id: Document ID
        feedback_type: Type of feedback
        value: Feedback value (1.0 positive, -1.0 negative)
        timestamp: Event timestamp
        position: Result position when clicked
        session_id: User session ID
    """

    query: str
    doc_id: str
    feedback_type: FeedbackType
    value: float = 1.0
    timestamp: datetime = field(default_factory=datetime.now)
    position: int = 0
    session_id: str = ""


@dataclass
class RelevanceModel:
    """Learned relevance model.

    Attributes:
        query_doc_scores: Learned query-document scores
        term_boosts: Learned term importance weights
        field_weights: Learned field weights
        updated_at: Last update timestamp
    """

    query_doc_scores: Dict[str, Dict[str, float]] = field(default_factory=dict)
    term_boosts: Dict[str, float] = field(default_factory=dict)
    field_weights: Dict[str, float] = field(default_factory=dict)
    updated_at: datetime = field(default_factory=datetime.now)


class ClickModel:
    """Click model for position bias correction.

    Uses a position-based click model to account for the fact
    that higher-ranked results get more clicks regardless of relevance.
    """

    def __init__(self):
        """Initialize click model."""
        # Position examination probabilities
        self._examination_probs: Dict[int, float] = {}
        self._click_counts: Dict[int, int] = defaultdict(int)
        self._impression_counts: Dict[int, int] = defaultdict(int)

        # Initialize with decay priors
        for pos in range(100):
            self._examination_probs[pos] = 1.0 / (1 + pos * 0.3)

    def record_impression(self, position: int) -> None:
        """Record an impression at position."""
        self._impression_counts[position] += 1

    def record_click(self, position: int) -> None:
        """Record a click at position."""
        self._click_counts[position] += 1
        self._update_examination_prob(position)

    def _update_examination_prob(self, position: int) -> None:
        """Update examination probability using EM."""
        clicks = self._click_counts[position]
        impressions = self._impression_counts[position]
        if impressions > 10:
            self._examination_probs[position] = clicks / impressions

    def get_relevance_weight(self, position: int) -> float:
        """Get relevance weight correcting for position bias.

        Higher weights for clicks on lower positions (less examined).
        """
        exam_prob = self._examination_probs.get(position, 0.1)
        if exam_prob < 0.01:
            exam_prob = 0.01
        return 1.0 / exam_prob


class RelevanceTuner:
    """Relevance Tuner Agent - AI-Powered Relevance Optimization.

    Learns from user interactions to improve search ranking.
    Uses click models, gradient-based learning, and feedback loops.
    """

    def __init__(
        self,
        learning_rate: float = 0.01,
        decay_days: int = 30,
        min_feedback: int = 5,
    ):
        """Initialize relevance tuner.

        Args:
            learning_rate: Learning rate for updates
            decay_days: Days before feedback decays
            min_feedback: Minimum feedback for learning
        """
        self.learning_rate = learning_rate
        self.decay_days = decay_days
        self.min_feedback = min_feedback

        self._model = RelevanceModel()
        self._click_model = ClickModel()
        self._feedback_buffer: List[FeedbackEvent] = []
        self._lock = threading.RLock()

        # Statistics
        self._stats = {
            "feedback_count": 0,
            "model_updates": 0,
            "queries_tuned": 0,
        }

    def record_feedback(self, event: FeedbackEvent) -> None:
        """Record a feedback event.

        Args:
            event: Feedback event
        """
        with self._lock:
            self._feedback_buffer.append(event)
            self._stats["feedback_count"] += 1

            # Update click model
            if event.feedback_type == FeedbackType.CLICK:
                self._click_model.record_click(event.position)
            elif event.feedback_type == FeedbackType.SKIP:
                self._click_model.record_impression(event.position)

            # Trigger learning if enough feedback
            if len(self._feedback_buffer) >= self.min_feedback:
                self._learn()

    def record_click(
        self,
        query: str,
        doc_id: str,
        position: int,
        session_id: str = "",
    ) -> None:
        """Record a click event.

        Args:
            query: Search query
            doc_id: Clicked document ID
            position: Result position
            session_id: User session ID
        """
        self.record_feedback(FeedbackEvent(
            query=query,
            doc_id=doc_id,
            feedback_type=FeedbackType.CLICK,
            value=1.0,
            position=position,
            session_id=session_id,
        ))

    def record_dwell(
        self,
        query: str,
        doc_id: str,
        dwell_seconds: float,
        session_id: str = "",
    ) -> None:
        """Record dwell time feedback.

        Args:
            query: Search query
            doc_id: Document ID
            dwell_seconds: Time spent on result
            session_id: User session ID
        """
        # Convert dwell time to relevance signal
        # Short dwells (<10s) are negative, long dwells are positive
        if dwell_seconds < 5:
            value = -0.5
        elif dwell_seconds < 30:
            value = 0.5
        else:
            value = 1.0

        self.record_feedback(FeedbackEvent(
            query=query,
            doc_id=doc_id,
            feedback_type=FeedbackType.DWELL,
            value=value,
            session_id=session_id,
        ))

    def record_conversion(
        self,
        query: str,
        doc_id: str,
        session_id: str = "",
    ) -> None:
        """Record a conversion event.

        Args:
            query: Search query
            doc_id: Document ID
            session_id: User session ID
        """
        self.record_feedback(FeedbackEvent(
            query=query,
            doc_id=doc_id,
            feedback_type=FeedbackType.CONVERSION,
            value=2.0,  # Strong positive signal
            session_id=session_id,
        ))

    def _learn(self) -> None:
        """Learn from accumulated feedback."""
        with self._lock:
            if not self._feedback_buffer:
                return

            # Group feedback by query
            query_feedback: Dict[str, List[FeedbackEvent]] = defaultdict(list)
            for event in self._feedback_buffer:
                query_feedback[event.query].append(event)

            # Update model for each query
            for query, events in query_feedback.items():
                self._update_query_model(query, events)

            # Update term boosts
            self._update_term_boosts()

            # Clear buffer
            self._feedback_buffer = []
            self._model.updated_at = datetime.now()
            self._stats["model_updates"] += 1

    def _update_query_model(
        self,
        query: str,
        events: List[FeedbackEvent],
    ) -> None:
        """Update model for a specific query."""
        if query not in self._model.query_doc_scores:
            self._model.query_doc_scores[query] = {}

        doc_scores = self._model.query_doc_scores[query]

        for event in events:
            # Apply position bias correction for clicks
            weight = 1.0
            if event.feedback_type == FeedbackType.CLICK:
                weight = self._click_model.get_relevance_weight(event.position)

            # Decay based on age
            age_days = (datetime.now() - event.timestamp).days
            decay = max(0.1, 1.0 - (age_days / self.decay_days))

            # Update score
            current = doc_scores.get(event.doc_id, 0.0)
            update = self.learning_rate * event.value * weight * decay
            doc_scores[event.doc_id] = current + update

        self._stats["queries_tuned"] += 1

    def _update_term_boosts(self) -> None:
        """Update term importance weights."""
        # Aggregate term signals across all queries
        term_signals: Dict[str, List[float]] = defaultdict(list)

        for query, doc_scores in self._model.query_doc_scores.items():
            terms = query.lower().split()
            avg_score = sum(doc_scores.values()) / max(1, len(doc_scores))

            for term in terms:
                term_signals[term].append(avg_score)

        # Update term boosts
        for term, signals in term_signals.items():
            if len(signals) >= 3:
                avg_signal = sum(signals) / len(signals)
                current = self._model.term_boosts.get(term, 1.0)
                self._model.term_boosts[term] = current + self.learning_rate * (avg_signal - current)

    def get_score_boost(self, query: str, doc_id: str) -> float:
        """Get learned score boost for query-document pair.

        Args:
            query: Search query
            doc_id: Document ID

        Returns:
            Score boost factor
        """
        with self._lock:
            if query in self._model.query_doc_scores:
                base_score = self._model.query_doc_scores[query].get(doc_id, 0.0)
                return 1.0 + base_score
            return 1.0

    def get_term_boost(self, term: str) -> float:
        """Get learned term importance boost.

        Args:
            term: Search term

        Returns:
            Term boost factor
        """
        return self._model.term_boosts.get(term.lower(), 1.0)

    def rerank(
        self,
        query: str,
        results: List[Tuple[str, float]],
    ) -> List[Tuple[str, float]]:
        """Re-rank results using learned model.

        Args:
            query: Search query
            results: List of (doc_id, score) tuples

        Returns:
            Re-ranked results
        """
        reranked = []
        for doc_id, score in results:
            boost = self.get_score_boost(query, doc_id)
            reranked.append((doc_id, score * boost))

        reranked.sort(key=lambda x: x[1], reverse=True)
        return reranked

    def get_statistics(self) -> Dict[str, Any]:
        """Get tuner statistics."""
        with self._lock:
            return {
                **self._stats,
                "queries_in_model": len(self._model.query_doc_scores),
                "terms_boosted": len(self._model.term_boosts),
                "pending_feedback": len(self._feedback_buffer),
                "last_update": self._model.updated_at.isoformat(),
            }

    def export_model(self) -> Dict[str, Any]:
        """Export learned model."""
        with self._lock:
            return {
                "query_doc_scores": dict(self._model.query_doc_scores),
                "term_boosts": dict(self._model.term_boosts),
                "field_weights": dict(self._model.field_weights),
                "updated_at": self._model.updated_at.isoformat(),
            }

    def import_model(self, data: Dict[str, Any]) -> None:
        """Import a learned model."""
        with self._lock:
            self._model.query_doc_scores = data.get("query_doc_scores", {})
            self._model.term_boosts = data.get("term_boosts", {})
            self._model.field_weights = data.get("field_weights", {})
            if "updated_at" in data:
                self._model.updated_at = datetime.fromisoformat(data["updated_at"])


__all__ = [
    "RelevanceTuner",
    "FeedbackEvent",
    "FeedbackType",
    "RelevanceModel",
    "ClickModel",
]

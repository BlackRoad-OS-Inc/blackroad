"""RoadML Predictor - Prediction Interface.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


@dataclass
class PredictionResult:
    """Prediction result."""

    predictions: Any
    probabilities: Optional[Any] = None
    latency_ms: float = 0.0
    model_version: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


class Predictor(ABC):
    """Abstract predictor interface."""

    @abstractmethod
    def predict(self, inputs: Any) -> PredictionResult:
        """Make prediction."""
        pass

    @abstractmethod
    def load(self, path: str) -> None:
        """Load model from path."""
        pass


class BatchPredictor:
    """Batch prediction with batching and caching."""

    def __init__(
        self,
        predictor: Predictor,
        batch_size: int = 32,
        max_wait_ms: float = 100.0,
    ):
        self.predictor = predictor
        self.batch_size = batch_size
        self.max_wait_ms = max_wait_ms
        self._queue: List[Any] = []

    def predict(self, inputs: Any) -> PredictionResult:
        """Make batch prediction."""
        start = time.time()
        result = self.predictor.predict(inputs)
        result.latency_ms = (time.time() - start) * 1000
        return result


__all__ = ["Predictor", "PredictionResult", "BatchPredictor"]

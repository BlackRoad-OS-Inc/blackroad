"""AutoML Ensemble - Automated Model Ensembling.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Tuple

import numpy as np

logger = logging.getLogger(__name__)


class EnsembleStrategy(Enum):
    """Ensemble strategies."""

    VOTING = auto()
    AVERAGING = auto()
    STACKING = auto()
    BLENDING = auto()
    WEIGHTED_AVERAGING = auto()
    BAGGING = auto()
    BOOSTING = auto()


class VotingMethod(Enum):
    """Voting methods for classification."""

    HARD = "hard"
    SOFT = "soft"


@dataclass
class EnsembleMember:
    """A member of the ensemble."""

    model: Any
    weight: float = 1.0
    name: str = ""
    score: float = 0.0


class BaseEnsemble(ABC):
    """Abstract base ensemble."""

    @abstractmethod
    def fit(self, X: Any, y: Any) -> "BaseEnsemble":
        """Fit ensemble."""
        pass

    @abstractmethod
    def predict(self, X: Any) -> Any:
        """Make predictions."""
        pass


class VotingEnsemble(BaseEnsemble):
    """Voting ensemble for classification.

    Combines predictions from multiple models using
    majority vote (hard) or probability averaging (soft).
    """

    def __init__(
        self,
        estimators: List[Tuple[str, Any]],
        voting: VotingMethod = VotingMethod.SOFT,
        weights: Optional[List[float]] = None,
    ):
        self.estimators = estimators
        self.voting = voting
        self.weights = weights or [1.0] * len(estimators)
        self._fitted_estimators: List[Any] = []

    def fit(self, X: Any, y: Any) -> "VotingEnsemble":
        """Fit all estimators."""
        self._fitted_estimators = []

        for name, estimator in self.estimators:
            logger.info(f"Fitting estimator: {name}")
            fitted = estimator.fit(X, y)
            self._fitted_estimators.append(fitted)

        return self

    def predict(self, X: Any) -> np.ndarray:
        """Make predictions using voting."""
        if self.voting == VotingMethod.HARD:
            return self._hard_vote(X)
        else:
            return self._soft_vote(X)

    def _hard_vote(self, X: Any) -> np.ndarray:
        """Hard voting (majority vote)."""
        predictions = []
        for est in self._fitted_estimators:
            predictions.append(est.predict(X))

        predictions = np.array(predictions)
        result = []

        for i in range(predictions.shape[1]):
            votes = predictions[:, i]
            weighted_votes: Dict[Any, float] = {}
            for vote, weight in zip(votes, self.weights):
                weighted_votes[vote] = weighted_votes.get(vote, 0) + weight
            winner = max(weighted_votes.keys(), key=lambda k: weighted_votes[k])
            result.append(winner)

        return np.array(result)

    def _soft_vote(self, X: Any) -> np.ndarray:
        """Soft voting (probability averaging)."""
        probas = []
        for est, weight in zip(self._fitted_estimators, self.weights):
            if hasattr(est, "predict_proba"):
                probas.append(est.predict_proba(X) * weight)

        if not probas:
            return self._hard_vote(X)

        avg_probas = np.sum(probas, axis=0) / sum(self.weights)
        return np.argmax(avg_probas, axis=1)


class AveragingEnsemble(BaseEnsemble):
    """Averaging ensemble for regression.

    Combines predictions by averaging (optionally weighted).
    """

    def __init__(
        self,
        estimators: List[Tuple[str, Any]],
        weights: Optional[List[float]] = None,
    ):
        self.estimators = estimators
        self.weights = weights or [1.0] * len(estimators)
        self._fitted_estimators: List[Any] = []

    def fit(self, X: Any, y: Any) -> "AveragingEnsemble":
        """Fit all estimators."""
        self._fitted_estimators = []

        for name, estimator in self.estimators:
            logger.info(f"Fitting estimator: {name}")
            fitted = estimator.fit(X, y)
            self._fitted_estimators.append(fitted)

        return self

    def predict(self, X: Any) -> np.ndarray:
        """Make averaged predictions."""
        predictions = []

        for est, weight in zip(self._fitted_estimators, self.weights):
            preds = est.predict(X)
            predictions.append(preds * weight)

        return np.sum(predictions, axis=0) / sum(self.weights)


class StackingEnsemble(BaseEnsemble):
    """Stacking ensemble with meta-learner.

    Uses predictions from base models as features
    for a meta-learner model.
    """

    def __init__(
        self,
        estimators: List[Tuple[str, Any]],
        final_estimator: Any,
        cv: int = 5,
        passthrough: bool = False,
    ):
        self.estimators = estimators
        self.final_estimator = final_estimator
        self.cv = cv
        self.passthrough = passthrough
        self._fitted_estimators: List[Any] = []
        self._fitted_final: Optional[Any] = None

    def fit(self, X: Any, y: Any) -> "StackingEnsemble":
        """Fit stacking ensemble."""
        X = np.asarray(X)
        y = np.asarray(y)
        n_samples = X.shape[0]

        meta_features = np.zeros((n_samples, len(self.estimators)))
        self._fitted_estimators = []

        for i, (name, estimator) in enumerate(self.estimators):
            logger.info(f"Fitting base estimator: {name}")

            fold_size = n_samples // self.cv
            for fold in range(self.cv):
                start = fold * fold_size
                end = start + fold_size if fold < self.cv - 1 else n_samples

                val_idx = list(range(start, end))
                train_idx = list(range(0, start)) + list(range(end, n_samples))

                X_train, X_val = X[train_idx], X[val_idx]
                y_train = y[train_idx]

                fold_est = estimator.fit(X_train, y_train)
                meta_features[val_idx, i] = fold_est.predict(X_val)

            fitted = estimator.fit(X, y)
            self._fitted_estimators.append(fitted)

        if self.passthrough:
            meta_features = np.hstack([X, meta_features])

        logger.info("Fitting meta-learner")
        self._fitted_final = self.final_estimator.fit(meta_features, y)

        return self

    def predict(self, X: Any) -> np.ndarray:
        """Make stacked predictions."""
        X = np.asarray(X)
        meta_features = np.column_stack([
            est.predict(X) for est in self._fitted_estimators
        ])

        if self.passthrough:
            meta_features = np.hstack([X, meta_features])

        return self._fitted_final.predict(meta_features)


class BlendingEnsemble(BaseEnsemble):
    """Blending ensemble.

    Similar to stacking but uses holdout set instead of CV.
    """

    def __init__(
        self,
        estimators: List[Tuple[str, Any]],
        final_estimator: Any,
        holdout_ratio: float = 0.2,
    ):
        self.estimators = estimators
        self.final_estimator = final_estimator
        self.holdout_ratio = holdout_ratio
        self._fitted_estimators: List[Any] = []
        self._fitted_final: Optional[Any] = None

    def fit(self, X: Any, y: Any) -> "BlendingEnsemble":
        """Fit blending ensemble."""
        X = np.asarray(X)
        y = np.asarray(y)

        n_samples = X.shape[0]
        n_holdout = int(n_samples * self.holdout_ratio)
        indices = np.random.permutation(n_samples)

        train_idx = indices[n_holdout:]
        holdout_idx = indices[:n_holdout]

        X_train, X_holdout = X[train_idx], X[holdout_idx]
        y_train, y_holdout = y[train_idx], y[holdout_idx]

        self._fitted_estimators = []
        blend_features = []

        for name, estimator in self.estimators:
            logger.info(f"Fitting estimator: {name}")
            fitted = estimator.fit(X_train, y_train)
            self._fitted_estimators.append(fitted)
            blend_features.append(fitted.predict(X_holdout))

        blend_features = np.column_stack(blend_features)
        self._fitted_final = self.final_estimator.fit(blend_features, y_holdout)

        return self

    def predict(self, X: Any) -> np.ndarray:
        """Make blended predictions."""
        blend_features = np.column_stack([
            est.predict(X) for est in self._fitted_estimators
        ])

        return self._fitted_final.predict(blend_features)


class AutoEnsemble:
    """Automatic ensemble builder.

    Selects best models from AutoML search and builds
    optimal ensemble.
    """

    def __init__(
        self,
        strategy: EnsembleStrategy = EnsembleStrategy.WEIGHTED_AVERAGING,
        n_models: int = 5,
        optimize_weights: bool = True,
    ):
        self.strategy = strategy
        self.n_models = n_models
        self.optimize_weights = optimize_weights
        self._ensemble: Optional[BaseEnsemble] = None
        self._weights: Optional[List[float]] = None

    def build(
        self,
        models: List[EnsembleMember],
        X: Any,
        y: Any,
    ) -> "AutoEnsemble":
        """Build ensemble from models.

        Args:
            models: List of candidate models with scores
            X: Training features
            y: Training labels

        Returns:
            Fitted AutoEnsemble
        """
        sorted_models = sorted(models, key=lambda m: m.score, reverse=True)
        selected = sorted_models[:self.n_models]

        logger.info(f"Building ensemble with {len(selected)} models")

        if self.optimize_weights:
            self._weights = self._optimize_weights(selected, X, y)
        else:
            self._weights = [1.0 / len(selected)] * len(selected)

        estimators = [(m.name or f"model_{i}", m.model) for i, m in enumerate(selected)]

        if self.strategy == EnsembleStrategy.VOTING:
            self._ensemble = VotingEnsemble(estimators, weights=self._weights)
        elif self.strategy in (EnsembleStrategy.AVERAGING, EnsembleStrategy.WEIGHTED_AVERAGING):
            self._ensemble = AveragingEnsemble(estimators, weights=self._weights)
        elif self.strategy == EnsembleStrategy.STACKING:
            meta = selected[0].model.__class__()
            self._ensemble = StackingEnsemble(estimators, meta)
        else:
            self._ensemble = AveragingEnsemble(estimators, weights=self._weights)

        self._ensemble.fit(X, y)
        return self

    def _optimize_weights(
        self,
        models: List[EnsembleMember],
        X: Any,
        y: Any,
    ) -> List[float]:
        """Optimize ensemble weights."""
        scores = [m.score for m in models]
        total = sum(scores)
        return [s / total for s in scores]

    def predict(self, X: Any) -> Any:
        """Make ensemble predictions."""
        if self._ensemble is None:
            raise ValueError("Ensemble not built")
        return self._ensemble.predict(X)


__all__ = [
    "AutoEnsemble",
    "EnsembleStrategy",
    "EnsembleMember",
    "VotingEnsemble",
    "AveragingEnsemble",
    "StackingEnsemble",
    "BlendingEnsemble",
    "VotingMethod",
]

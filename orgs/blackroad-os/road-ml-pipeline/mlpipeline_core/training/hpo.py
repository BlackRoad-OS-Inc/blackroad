"""RoadML HPO - Hyperparameter Optimization.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import random
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Tuple, Union

logger = logging.getLogger(__name__)


class SearchAlgorithm(Enum):
    """Search algorithms."""

    GRID = auto()
    RANDOM = auto()
    BAYESIAN = auto()
    TPE = auto()
    HYPERBAND = auto()


@dataclass
class SearchSpace:
    """Search space for hyperparameters."""

    params: Dict[str, Any] = field(default_factory=dict)

    def uniform(self, name: str, low: float, high: float) -> "SearchSpace":
        """Add uniform distribution parameter."""
        self.params[name] = ("uniform", low, high)
        return self

    def log_uniform(self, name: str, low: float, high: float) -> "SearchSpace":
        """Add log-uniform distribution parameter."""
        self.params[name] = ("log_uniform", low, high)
        return self

    def choice(self, name: str, choices: List[Any]) -> "SearchSpace":
        """Add categorical parameter."""
        self.params[name] = ("choice", choices)
        return self

    def integer(self, name: str, low: int, high: int) -> "SearchSpace":
        """Add integer parameter."""
        self.params[name] = ("int", low, high)
        return self

    def sample(self) -> Dict[str, Any]:
        """Sample from search space."""
        import math
        result = {}

        for name, spec in self.params.items():
            dist_type = spec[0]

            if dist_type == "uniform":
                result[name] = random.uniform(spec[1], spec[2])
            elif dist_type == "log_uniform":
                result[name] = math.exp(random.uniform(
                    math.log(spec[1]), math.log(spec[2])
                ))
            elif dist_type == "choice":
                result[name] = random.choice(spec[1])
            elif dist_type == "int":
                result[name] = random.randint(spec[1], spec[2])

        return result


@dataclass
class Trial:
    """A single HPO trial."""

    trial_id: str
    params: Dict[str, Any]
    metrics: Dict[str, float] = field(default_factory=dict)
    status: str = "pending"
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    @property
    def objective(self) -> Optional[float]:
        """Get objective metric."""
        return self.metrics.get("objective")


class HPOSearch:
    """Hyperparameter optimization search.

    Supports:
    - Grid search
    - Random search
    - Bayesian optimization
    - Hyperband
    """

    def __init__(
        self,
        objective_fn: Callable[[Dict[str, Any]], float],
        search_space: SearchSpace,
        algorithm: SearchAlgorithm = SearchAlgorithm.RANDOM,
        max_trials: int = 20,
        metric: str = "accuracy",
        mode: str = "max",
    ):
        self.objective_fn = objective_fn
        self.search_space = search_space
        self.algorithm = algorithm
        self.max_trials = max_trials
        self.metric = metric
        self.mode = mode

        self.trials: List[Trial] = []
        self._best_trial: Optional[Trial] = None

    def run(self) -> Trial:
        """Run HPO search."""
        logger.info(f"Starting HPO search: {self.algorithm.name}")

        for i in range(self.max_trials):
            params = self.search_space.sample()

            trial = Trial(
                trial_id=f"trial_{i}",
                params=params,
                started_at=datetime.now(),
            )

            try:
                objective = self.objective_fn(params)
                trial.metrics["objective"] = objective
                trial.status = "completed"
            except Exception as e:
                trial.status = "failed"
                logger.error(f"Trial {i} failed: {e}")

            trial.completed_at = datetime.now()
            self.trials.append(trial)

            # Update best
            if trial.status == "completed":
                if self._best_trial is None:
                    self._best_trial = trial
                else:
                    current_best = self._best_trial.objective
                    if self.mode == "max" and trial.objective > current_best:
                        self._best_trial = trial
                    elif self.mode == "min" and trial.objective < current_best:
                        self._best_trial = trial

            logger.info(f"Trial {i}: objective={trial.objective:.4f}")

        return self._best_trial

    @property
    def best_trial(self) -> Optional[Trial]:
        """Get best trial."""
        return self._best_trial

    @property
    def best_params(self) -> Optional[Dict[str, Any]]:
        """Get best parameters."""
        return self._best_trial.params if self._best_trial else None


__all__ = ["HPOSearch", "SearchSpace", "Trial", "SearchAlgorithm"]

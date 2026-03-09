"""RoadML Experiment Tracker - Experiment Management.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


@dataclass
class Run:
    """An experiment run."""

    run_id: str
    experiment_id: str
    status: str = "running"
    started_at: datetime = field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    parameters: Dict[str, Any] = field(default_factory=dict)
    metrics: Dict[str, float] = field(default_factory=dict)
    artifacts: Dict[str, str] = field(default_factory=dict)
    tags: Dict[str, str] = field(default_factory=dict)


@dataclass
class Experiment:
    """An experiment."""

    experiment_id: str
    name: str
    description: str = ""
    created_at: datetime = field(default_factory=datetime.now)
    tags: Dict[str, str] = field(default_factory=dict)


class ExperimentTracker:
    """Track ML experiments.

    Features:
    - Parameter logging
    - Metric tracking
    - Artifact storage
    - Run comparison
    """

    def __init__(self, tracking_uri: Optional[str] = None):
        self.tracking_uri = tracking_uri
        self._experiments: Dict[str, Experiment] = {}
        self._runs: Dict[str, Run] = {}
        self._active_run: Optional[Run] = None

    def create_experiment(
        self,
        name: str,
        description: str = "",
        tags: Optional[Dict[str, str]] = None,
    ) -> Experiment:
        """Create experiment."""
        exp_id = str(uuid.uuid4())[:8]
        experiment = Experiment(
            experiment_id=exp_id,
            name=name,
            description=description,
            tags=tags or {},
        )
        self._experiments[exp_id] = experiment
        return experiment

    def get_experiment(self, experiment_id: str) -> Optional[Experiment]:
        """Get experiment by ID."""
        return self._experiments.get(experiment_id)

    def start_run(
        self,
        experiment_id: str,
        run_name: Optional[str] = None,
    ) -> Run:
        """Start a new run."""
        run_id = str(uuid.uuid4())[:8]
        run = Run(
            run_id=run_id,
            experiment_id=experiment_id,
        )
        self._runs[run_id] = run
        self._active_run = run
        return run

    def end_run(self) -> None:
        """End current run."""
        if self._active_run:
            self._active_run.status = "completed"
            self._active_run.completed_at = datetime.now()
            self._active_run = None

    def log_param(self, key: str, value: Any) -> None:
        """Log parameter."""
        if self._active_run:
            self._active_run.parameters[key] = value

    def log_params(self, params: Dict[str, Any]) -> None:
        """Log multiple parameters."""
        if self._active_run:
            self._active_run.parameters.update(params)

    def log_metric(self, key: str, value: float, step: Optional[int] = None) -> None:
        """Log metric."""
        if self._active_run:
            self._active_run.metrics[key] = value

    def log_metrics(self, metrics: Dict[str, float], step: Optional[int] = None) -> None:
        """Log multiple metrics."""
        if self._active_run:
            self._active_run.metrics.update(metrics)

    def log_artifact(self, path: str, name: Optional[str] = None) -> None:
        """Log artifact."""
        if self._active_run:
            name = name or path
            self._active_run.artifacts[name] = path

    def set_tag(self, key: str, value: str) -> None:
        """Set run tag."""
        if self._active_run:
            self._active_run.tags[key] = value

    def get_run(self, run_id: str) -> Optional[Run]:
        """Get run by ID."""
        return self._runs.get(run_id)

    def search_runs(
        self,
        experiment_id: str,
        filter_string: Optional[str] = None,
    ) -> List[Run]:
        """Search runs."""
        return [
            run for run in self._runs.values()
            if run.experiment_id == experiment_id
        ]

    @property
    def active_run(self) -> Optional[Run]:
        """Get active run."""
        return self._active_run


__all__ = ["ExperimentTracker", "Experiment", "Run"]

"""RoadML Training Job - Training Job Management.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional

logger = logging.getLogger(__name__)


class JobStatus(Enum):
    """Training job status."""

    PENDING = auto()
    RUNNING = auto()
    COMPLETED = auto()
    FAILED = auto()
    CANCELLED = auto()


@dataclass
class JobConfig:
    """Training job configuration."""

    name: str = "training-job"
    epochs: int = 10
    batch_size: int = 32
    learning_rate: float = 0.001
    optimizer: str = "adam"
    resources: Dict[str, Any] = field(default_factory=dict)
    checkpoints: bool = True
    checkpoint_interval: int = 5


@dataclass
class JobMetrics:
    """Training metrics."""

    loss: float = 0.0
    accuracy: float = 0.0
    epoch: int = 0
    step: int = 0
    custom: Dict[str, float] = field(default_factory=dict)


class TrainingJob:
    """Managed training job.

    Features:
    - Progress tracking
    - Checkpointing
    - Metrics logging
    - Resource management
    """

    def __init__(
        self,
        train_fn: Callable,
        config: Optional[JobConfig] = None,
    ):
        self.train_fn = train_fn
        self.config = config or JobConfig()
        self.job_id = str(uuid.uuid4())[:8]

        self.status = JobStatus.PENDING
        self.metrics = JobMetrics()
        self.started_at: Optional[datetime] = None
        self.completed_at: Optional[datetime] = None
        self._thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()

    def start(self, **kwargs) -> str:
        """Start training job."""
        self.status = JobStatus.RUNNING
        self.started_at = datetime.now()

        self._thread = threading.Thread(
            target=self._run,
            kwargs=kwargs,
            daemon=True,
        )
        self._thread.start()

        logger.info(f"Started training job {self.job_id}")
        return self.job_id

    def _run(self, **kwargs) -> None:
        """Execute training."""
        try:
            self.train_fn(self, **kwargs)
            self.status = JobStatus.COMPLETED
        except Exception as e:
            self.status = JobStatus.FAILED
            logger.error(f"Job {self.job_id} failed: {e}")
        finally:
            self.completed_at = datetime.now()

    def stop(self) -> None:
        """Stop training job."""
        self._stop_event.set()
        self.status = JobStatus.CANCELLED

    def update_metrics(self, **metrics) -> None:
        """Update training metrics."""
        for k, v in metrics.items():
            if hasattr(self.metrics, k):
                setattr(self.metrics, k, v)
            else:
                self.metrics.custom[k] = v

    def wait(self, timeout: Optional[float] = None) -> JobStatus:
        """Wait for job completion."""
        if self._thread:
            self._thread.join(timeout=timeout)
        return self.status

    @property
    def should_stop(self) -> bool:
        """Check if job should stop."""
        return self._stop_event.is_set()


__all__ = ["TrainingJob", "JobConfig", "JobStatus", "JobMetrics"]

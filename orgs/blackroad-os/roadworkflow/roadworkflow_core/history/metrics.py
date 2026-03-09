"""Workflow Metrics - Performance tracking.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import statistics
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

import logging

logger = logging.getLogger(__name__)


@dataclass
class TaskMetrics:
    """Metrics for a single task."""

    task_id: str
    execution_count: int = 0
    success_count: int = 0
    failure_count: int = 0
    retry_count: int = 0
    total_duration: float = 0.0
    durations: List[float] = field(default_factory=list)
    last_execution: Optional[datetime] = None

    @property
    def success_rate(self) -> float:
        """Calculate success rate."""
        if self.execution_count == 0:
            return 0.0
        return self.success_count / self.execution_count

    @property
    def avg_duration(self) -> float:
        """Average execution duration."""
        if not self.durations:
            return 0.0
        return statistics.mean(self.durations)

    @property
    def p95_duration(self) -> float:
        """95th percentile duration."""
        if len(self.durations) < 2:
            return self.avg_duration
        sorted_durations = sorted(self.durations)
        idx = int(len(sorted_durations) * 0.95)
        return sorted_durations[idx]

    def record_execution(self, duration: float, success: bool) -> None:
        """Record task execution."""
        self.execution_count += 1
        self.total_duration += duration

        if success:
            self.success_count += 1
        else:
            self.failure_count += 1

        self.durations.append(duration)
        if len(self.durations) > 1000:
            self.durations = self.durations[-500:]

        self.last_execution = datetime.utcnow()

    def record_retry(self) -> None:
        """Record retry attempt."""
        self.retry_count += 1

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "task_id": self.task_id,
            "execution_count": self.execution_count,
            "success_count": self.success_count,
            "failure_count": self.failure_count,
            "retry_count": self.retry_count,
            "success_rate": self.success_rate,
            "avg_duration": self.avg_duration,
            "p95_duration": self.p95_duration,
            "last_execution": self.last_execution.isoformat() if self.last_execution else None,
        }


@dataclass
class WorkflowMetrics:
    """Metrics for a workflow."""

    workflow_id: str
    run_count: int = 0
    success_count: int = 0
    failure_count: int = 0
    total_duration: float = 0.0
    durations: List[float] = field(default_factory=list)
    task_metrics: Dict[str, TaskMetrics] = field(default_factory=dict)
    last_run: Optional[datetime] = None

    @property
    def success_rate(self) -> float:
        """Calculate success rate."""
        if self.run_count == 0:
            return 0.0
        return self.success_count / self.run_count

    @property
    def avg_duration(self) -> float:
        """Average run duration."""
        if not self.durations:
            return 0.0
        return statistics.mean(self.durations)

    @property
    def p95_duration(self) -> float:
        """95th percentile duration."""
        if len(self.durations) < 2:
            return self.avg_duration
        sorted_durations = sorted(self.durations)
        idx = int(len(sorted_durations) * 0.95)
        return sorted_durations[idx]

    def record_run(self, duration: float, success: bool) -> None:
        """Record workflow run."""
        self.run_count += 1
        self.total_duration += duration

        if success:
            self.success_count += 1
        else:
            self.failure_count += 1

        self.durations.append(duration)
        if len(self.durations) > 1000:
            self.durations = self.durations[-500:]

        self.last_run = datetime.utcnow()

    def get_task_metrics(self, task_id: str) -> TaskMetrics:
        """Get or create task metrics."""
        if task_id not in self.task_metrics:
            self.task_metrics[task_id] = TaskMetrics(task_id=task_id)
        return self.task_metrics[task_id]

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "workflow_id": self.workflow_id,
            "run_count": self.run_count,
            "success_count": self.success_count,
            "failure_count": self.failure_count,
            "success_rate": self.success_rate,
            "avg_duration": self.avg_duration,
            "p95_duration": self.p95_duration,
            "last_run": self.last_run.isoformat() if self.last_run else None,
            "tasks": {k: v.to_dict() for k, v in self.task_metrics.items()},
        }


class MetricsCollector:
    """Metrics collector for workflows.

    Features:
    - Workflow and task metrics
    - Prometheus export
    - Historical tracking
    - SLA monitoring
    """

    def __init__(self):
        self._workflows: Dict[str, WorkflowMetrics] = {}
        self._lock = threading.RLock()
        self._sla_violations: List[Dict[str, Any]] = []

    def get_workflow_metrics(self, workflow_id: str) -> WorkflowMetrics:
        """Get or create workflow metrics."""
        with self._lock:
            if workflow_id not in self._workflows:
                self._workflows[workflow_id] = WorkflowMetrics(workflow_id=workflow_id)
            return self._workflows[workflow_id]

    def record_workflow_start(self, workflow_id: str, run_id: str) -> None:
        """Record workflow start."""
        metrics = self.get_workflow_metrics(workflow_id)
        logger.debug(f"Workflow started: {workflow_id} ({run_id})")

    def record_workflow_complete(
        self,
        workflow_id: str,
        run_id: str,
        duration: float,
        success: bool,
    ) -> None:
        """Record workflow completion."""
        metrics = self.get_workflow_metrics(workflow_id)
        metrics.record_run(duration, success)
        logger.debug(
            f"Workflow completed: {workflow_id} ({run_id}) - "
            f"{'success' if success else 'failure'} in {duration:.2f}s"
        )

    def record_task_complete(
        self,
        workflow_id: str,
        task_id: str,
        duration: float,
        success: bool,
    ) -> None:
        """Record task completion."""
        metrics = self.get_workflow_metrics(workflow_id)
        task_metrics = metrics.get_task_metrics(task_id)
        task_metrics.record_execution(duration, success)

    def record_task_retry(self, workflow_id: str, task_id: str) -> None:
        """Record task retry."""
        metrics = self.get_workflow_metrics(workflow_id)
        task_metrics = metrics.get_task_metrics(task_id)
        task_metrics.record_retry()

    def check_sla(
        self,
        workflow_id: str,
        expected_duration: timedelta,
        actual_duration: float,
    ) -> bool:
        """Check if workflow met SLA.

        Args:
            workflow_id: Workflow identifier
            expected_duration: Expected maximum duration
            actual_duration: Actual duration

        Returns:
            True if SLA was met
        """
        met_sla = actual_duration <= expected_duration.total_seconds()

        if not met_sla:
            violation = {
                "workflow_id": workflow_id,
                "expected_seconds": expected_duration.total_seconds(),
                "actual_seconds": actual_duration,
                "timestamp": datetime.utcnow().isoformat(),
            }
            with self._lock:
                self._sla_violations.append(violation)

        return met_sla

    def get_sla_violations(
        self,
        workflow_id: Optional[str] = None,
        since: Optional[datetime] = None,
    ) -> List[Dict[str, Any]]:
        """Get SLA violations."""
        with self._lock:
            violations = self._sla_violations.copy()

        if workflow_id:
            violations = [v for v in violations if v["workflow_id"] == workflow_id]

        if since:
            violations = [
                v for v in violations
                if datetime.fromisoformat(v["timestamp"]) >= since
            ]

        return violations

    def get_all_metrics(self) -> Dict[str, Any]:
        """Get all metrics."""
        with self._lock:
            return {
                "workflows": {
                    k: v.to_dict() for k, v in self._workflows.items()
                },
                "sla_violations_count": len(self._sla_violations),
            }

    def export_prometheus(self) -> str:
        """Export metrics in Prometheus format."""
        lines = []

        with self._lock:
            for workflow_id, metrics in self._workflows.items():
                safe_id = workflow_id.replace("-", "_").replace(".", "_")

                lines.append(f'workflow_runs_total{{workflow="{workflow_id}"}} {metrics.run_count}')
                lines.append(f'workflow_success_total{{workflow="{workflow_id}"}} {metrics.success_count}')
                lines.append(f'workflow_failure_total{{workflow="{workflow_id}"}} {metrics.failure_count}')
                lines.append(f'workflow_duration_avg_seconds{{workflow="{workflow_id}"}} {metrics.avg_duration:.3f}')
                lines.append(f'workflow_duration_p95_seconds{{workflow="{workflow_id}"}} {metrics.p95_duration:.3f}')

                for task_id, task_metrics in metrics.task_metrics.items():
                    safe_task = task_id.replace("-", "_").replace(".", "_")
                    lines.append(
                        f'task_executions_total{{workflow="{workflow_id}",task="{task_id}"}} {task_metrics.execution_count}'
                    )
                    lines.append(
                        f'task_success_total{{workflow="{workflow_id}",task="{task_id}"}} {task_metrics.success_count}'
                    )
                    lines.append(
                        f'task_retries_total{{workflow="{workflow_id}",task="{task_id}"}} {task_metrics.retry_count}'
                    )

        return "\n".join(lines)

    def reset(self, workflow_id: Optional[str] = None) -> None:
        """Reset metrics."""
        with self._lock:
            if workflow_id:
                if workflow_id in self._workflows:
                    del self._workflows[workflow_id]
            else:
                self._workflows.clear()
                self._sla_violations.clear()


__all__ = [
    "MetricsCollector",
    "WorkflowMetrics",
    "TaskMetrics",
]

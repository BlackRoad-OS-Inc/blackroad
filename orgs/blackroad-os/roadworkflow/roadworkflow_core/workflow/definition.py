"""Workflow Definition - Core workflow structures.

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
from typing import Any, Callable, Dict, List, Optional, Set

from roadworkflow_core.workflow.dag import DAG

logger = logging.getLogger(__name__)


class WorkflowStatus(Enum):
    """Workflow execution status."""

    PENDING = auto()
    RUNNING = auto()
    SUCCESS = auto()
    FAILED = auto()
    CANCELLED = auto()
    PAUSED = auto()
    SKIPPED = auto()
    TIMEOUT = auto()


@dataclass
class WorkflowConfig:
    """Workflow configuration."""

    name: str = ""
    description: str = ""
    version: str = "1.0.0"
    timeout: Optional[float] = None
    retries: int = 0
    retry_delay: float = 60.0
    max_parallel_tasks: int = 10
    fail_fast: bool = True
    tags: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class WorkflowRun:
    """A single workflow execution."""

    run_id: str
    workflow_id: str
    status: WorkflowStatus = WorkflowStatus.PENDING
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None
    parameters: Dict[str, Any] = field(default_factory=dict)
    task_runs: Dict[str, "TaskRun"] = field(default_factory=dict)
    error: Optional[str] = None
    attempt: int = 1

    @property
    def duration(self) -> Optional[float]:
        """Get run duration in seconds."""
        if self.started_at and self.ended_at:
            return (self.ended_at - self.started_at).total_seconds()
        return None

    @property
    def is_finished(self) -> bool:
        """Check if run is finished."""
        return self.status in (
            WorkflowStatus.SUCCESS,
            WorkflowStatus.FAILED,
            WorkflowStatus.CANCELLED,
            WorkflowStatus.TIMEOUT,
        )

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "run_id": self.run_id,
            "workflow_id": self.workflow_id,
            "status": self.status.name,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "ended_at": self.ended_at.isoformat() if self.ended_at else None,
            "parameters": self.parameters,
            "error": self.error,
            "attempt": self.attempt,
            "duration": self.duration,
        }


@dataclass
class TaskRun:
    """A single task execution within a workflow run."""

    task_id: str
    run_id: str
    status: WorkflowStatus = WorkflowStatus.PENDING
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None
    result: Any = None
    error: Optional[str] = None
    attempt: int = 1
    logs: List[str] = field(default_factory=list)


class Workflow:
    """Workflow definition and execution.

    Features:
    - DAG-based task dependencies
    - Parameterized workflows
    - Conditional execution
    - Retry policies
    - Timeout handling

    Usage:
        workflow = Workflow("data_pipeline")
        workflow.add_task(extract_task)
        workflow.add_task(transform_task, depends_on=["extract"])
        workflow.add_task(load_task, depends_on=["transform"])
        
        run = workflow.run(params={"date": "2024-01-01"})
    """

    def __init__(
        self,
        name: str,
        config: Optional[WorkflowConfig] = None,
    ):
        self.name = name
        self.id = str(uuid.uuid4())[:8]
        self.config = config or WorkflowConfig(name=name)
        self.dag = DAG()
        self._tasks: Dict[str, Any] = {}
        self._runs: Dict[str, WorkflowRun] = {}
        self._lock = threading.RLock()
        self._callbacks: Dict[str, List[Callable]] = {
            "on_start": [],
            "on_complete": [],
            "on_fail": [],
            "on_task_start": [],
            "on_task_complete": [],
        }

    def add_task(
        self,
        task: Any,
        depends_on: Optional[List[str]] = None,
        condition: Optional[Callable[[Dict], bool]] = None,
    ) -> "Workflow":
        """Add a task to the workflow.

        Args:
            task: Task instance
            depends_on: List of task IDs this task depends on
            condition: Optional condition function
        """
        task_id = task.id if hasattr(task, "id") else task.name
        
        with self._lock:
            self._tasks[task_id] = task
            self.dag.add_node(task_id, task=task, condition=condition)
            
            if depends_on:
                for dep in depends_on:
                    self.dag.add_edge(dep, task_id)

        return self

    def remove_task(self, task_id: str) -> bool:
        """Remove a task from the workflow."""
        with self._lock:
            if task_id in self._tasks:
                del self._tasks[task_id]
                self.dag.remove_node(task_id)
                return True
        return False

    def get_task(self, task_id: str) -> Optional[Any]:
        """Get a task by ID."""
        return self._tasks.get(task_id)

    def validate(self) -> List[str]:
        """Validate workflow definition.

        Returns:
            List of validation errors (empty if valid)
        """
        errors = []

        # Check for cycles
        if self.dag.has_cycle():
            errors.append("Workflow contains a cycle")

        # Check all dependencies exist
        for node in self.dag.nodes.values():
            for dep in self.dag.get_dependencies(node.id):
                if dep not in self._tasks:
                    errors.append(f"Task '{node.id}' depends on unknown task '{dep}'")

        return errors

    def run(
        self,
        params: Optional[Dict[str, Any]] = None,
        run_id: Optional[str] = None,
    ) -> WorkflowRun:
        """Execute the workflow.

        Args:
            params: Workflow parameters
            run_id: Optional run ID

        Returns:
            WorkflowRun with execution results
        """
        run_id = run_id or str(uuid.uuid4())[:8]
        
        workflow_run = WorkflowRun(
            run_id=run_id,
            workflow_id=self.id,
            status=WorkflowStatus.PENDING,
            parameters=params or {},
        )

        with self._lock:
            self._runs[run_id] = workflow_run

        # Validate before running
        errors = self.validate()
        if errors:
            workflow_run.status = WorkflowStatus.FAILED
            workflow_run.error = "; ".join(errors)
            return workflow_run

        # Start execution
        workflow_run.status = WorkflowStatus.RUNNING
        workflow_run.started_at = datetime.now()

        self._notify("on_start", workflow_run)

        try:
            self._execute(workflow_run, params or {})
            
            # Check if all tasks succeeded
            failed_tasks = [
                tr for tr in workflow_run.task_runs.values()
                if tr.status == WorkflowStatus.FAILED
            ]
            
            if failed_tasks:
                workflow_run.status = WorkflowStatus.FAILED
                workflow_run.error = f"{len(failed_tasks)} task(s) failed"
                self._notify("on_fail", workflow_run)
            else:
                workflow_run.status = WorkflowStatus.SUCCESS
                self._notify("on_complete", workflow_run)

        except Exception as e:
            workflow_run.status = WorkflowStatus.FAILED
            workflow_run.error = str(e)
            self._notify("on_fail", workflow_run)

        workflow_run.ended_at = datetime.now()
        return workflow_run

    def _execute(
        self,
        workflow_run: WorkflowRun,
        params: Dict[str, Any],
    ) -> None:
        """Execute workflow tasks in topological order."""
        # Get execution order
        execution_order = self.dag.topological_sort()
        completed: Set[str] = set()
        context = {"params": params, "results": {}}

        for task_id in execution_order:
            task = self._tasks.get(task_id)
            if not task:
                continue

            node = self.dag.nodes.get(task_id)
            
            # Check condition
            if node and node.data.get("condition"):
                if not node.data["condition"](context):
                    task_run = TaskRun(
                        task_id=task_id,
                        run_id=workflow_run.run_id,
                        status=WorkflowStatus.SKIPPED,
                    )
                    workflow_run.task_runs[task_id] = task_run
                    continue

            # Check dependencies are complete
            deps = self.dag.get_dependencies(task_id)
            if not all(d in completed for d in deps):
                continue

            # Execute task
            task_run = self._execute_task(task, context, workflow_run.run_id)
            workflow_run.task_runs[task_id] = task_run

            if task_run.status == WorkflowStatus.SUCCESS:
                completed.add(task_id)
                context["results"][task_id] = task_run.result
            elif self.config.fail_fast:
                break

    def _execute_task(
        self,
        task: Any,
        context: Dict[str, Any],
        run_id: str,
    ) -> TaskRun:
        """Execute a single task."""
        task_id = task.id if hasattr(task, "id") else task.name
        
        task_run = TaskRun(
            task_id=task_id,
            run_id=run_id,
            status=WorkflowStatus.RUNNING,
            started_at=datetime.now(),
        )

        self._notify("on_task_start", task_run)

        try:
            if hasattr(task, "execute"):
                result = task.execute(context)
            elif callable(task):
                result = task(context)
            else:
                raise ValueError(f"Task {task_id} is not executable")

            task_run.result = result
            task_run.status = WorkflowStatus.SUCCESS

        except Exception as e:
            task_run.error = str(e)
            task_run.status = WorkflowStatus.FAILED
            logger.error(f"Task {task_id} failed: {e}")

        task_run.ended_at = datetime.now()
        self._notify("on_task_complete", task_run)

        return task_run

    def on(self, event: str, callback: Callable) -> "Workflow":
        """Register event callback."""
        if event in self._callbacks:
            self._callbacks[event].append(callback)
        return self

    def _notify(self, event: str, *args) -> None:
        """Notify event callbacks."""
        for callback in self._callbacks.get(event, []):
            try:
                callback(*args)
            except Exception as e:
                logger.error(f"Callback error: {e}")

    def get_run(self, run_id: str) -> Optional[WorkflowRun]:
        """Get a workflow run by ID."""
        return self._runs.get(run_id)

    def get_runs(self) -> List[WorkflowRun]:
        """Get all workflow runs."""
        return list(self._runs.values())

    def cancel(self, run_id: str) -> bool:
        """Cancel a running workflow."""
        run = self._runs.get(run_id)
        if run and run.status == WorkflowStatus.RUNNING:
            run.status = WorkflowStatus.CANCELLED
            run.ended_at = datetime.now()
            return True
        return False


__all__ = [
    "Workflow",
    "WorkflowConfig",
    "WorkflowRun",
    "WorkflowStatus",
    "TaskRun",
]

"""Workflow Builder - Fluent API for building workflows.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from typing import Any, Callable, Dict, List, Optional, Union

from roadworkflow_core.workflow.definition import Workflow, WorkflowConfig

logger = logging.getLogger(__name__)


class WorkflowBuilder:
    """Fluent builder for creating workflows.

    Usage:
        workflow = (
            WorkflowBuilder("data_pipeline")
            .with_description("Daily data processing")
            .with_timeout(3600)
            .add_task(extract, name="extract")
            .add_task(transform, depends_on=["extract"])
            .add_task(load, depends_on=["transform"])
            .build()
        )
    """

    def __init__(self, name: str):
        self._name = name
        self._config = WorkflowConfig(name=name)
        self._tasks: List[Dict[str, Any]] = []
        self._callbacks: Dict[str, List[Callable]] = {}

    def with_description(self, description: str) -> "WorkflowBuilder":
        """Set workflow description."""
        self._config.description = description
        return self

    def with_version(self, version: str) -> "WorkflowBuilder":
        """Set workflow version."""
        self._config.version = version
        return self

    def with_timeout(self, timeout: float) -> "WorkflowBuilder":
        """Set workflow timeout in seconds."""
        self._config.timeout = timeout
        return self

    def with_retries(
        self,
        retries: int,
        retry_delay: float = 60.0,
    ) -> "WorkflowBuilder":
        """Set retry configuration."""
        self._config.retries = retries
        self._config.retry_delay = retry_delay
        return self

    def with_max_parallel(self, max_parallel: int) -> "WorkflowBuilder":
        """Set maximum parallel task execution."""
        self._config.max_parallel_tasks = max_parallel
        return self

    def with_fail_fast(self, fail_fast: bool) -> "WorkflowBuilder":
        """Set fail fast behavior."""
        self._config.fail_fast = fail_fast
        return self

    def with_tags(self, *tags: str) -> "WorkflowBuilder":
        """Add tags to workflow."""
        self._config.tags.extend(tags)
        return self

    def with_metadata(self, **metadata) -> "WorkflowBuilder":
        """Add metadata to workflow."""
        self._config.metadata.update(metadata)
        return self

    def add_task(
        self,
        task: Union[Callable, Any],
        name: Optional[str] = None,
        depends_on: Optional[List[str]] = None,
        condition: Optional[Callable[[Dict], bool]] = None,
        **kwargs,
    ) -> "WorkflowBuilder":
        """Add a task to the workflow.

        Args:
            task: Task callable or instance
            name: Task name (defaults to function name)
            depends_on: List of dependency task names
            condition: Optional condition function
            **kwargs: Additional task configuration
        """
        task_name = name or getattr(task, "__name__", str(id(task)))

        self._tasks.append({
            "task": task,
            "name": task_name,
            "depends_on": depends_on or [],
            "condition": condition,
            "kwargs": kwargs,
        })

        return self

    def on_start(self, callback: Callable) -> "WorkflowBuilder":
        """Register start callback."""
        self._callbacks.setdefault("on_start", []).append(callback)
        return self

    def on_complete(self, callback: Callable) -> "WorkflowBuilder":
        """Register completion callback."""
        self._callbacks.setdefault("on_complete", []).append(callback)
        return self

    def on_fail(self, callback: Callable) -> "WorkflowBuilder":
        """Register failure callback."""
        self._callbacks.setdefault("on_fail", []).append(callback)
        return self

    def build(self) -> Workflow:
        """Build the workflow."""
        workflow = Workflow(self._name, self._config)

        # Add tasks
        for task_def in self._tasks:
            # Create task wrapper if needed
            task = task_def["task"]
            if callable(task) and not hasattr(task, "id"):
                from roadworkflow_core.tasks.base import Task
                task = Task(
                    name=task_def["name"],
                    func=task,
                    **task_def["kwargs"],
                )

            workflow.add_task(
                task,
                depends_on=task_def["depends_on"],
                condition=task_def["condition"],
            )

        # Register callbacks
        for event, callbacks in self._callbacks.items():
            for callback in callbacks:
                workflow.on(event, callback)

        return workflow


def workflow(
    name: str,
    **config_kwargs,
) -> Callable:
    """Decorator for defining workflows.

    Usage:
        @workflow("my_workflow", timeout=3600)
        def my_workflow(builder):
            builder.add_task(task1)
            builder.add_task(task2, depends_on=["task1"])
    """
    def decorator(func: Callable) -> Workflow:
        config = WorkflowConfig(name=name, **config_kwargs)
        wf = Workflow(name, config)

        # Create a builder and pass to function
        builder = WorkflowBuilder(name)
        builder._config = config
        func(builder)

        # Copy tasks to workflow
        for task_def in builder._tasks:
            task = task_def["task"]
            if callable(task) and not hasattr(task, "id"):
                from roadworkflow_core.tasks.base import Task
                task = Task(name=task_def["name"], func=task)

            wf.add_task(
                task,
                depends_on=task_def["depends_on"],
                condition=task_def["condition"],
            )

        return wf

    return decorator


__all__ = [
    "WorkflowBuilder",
    "workflow",
]

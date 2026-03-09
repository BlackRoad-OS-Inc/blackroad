"""RoadML Step - Pipeline Step Execution.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import functools
import logging
import time
import traceback
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional

logger = logging.getLogger(__name__)


class StepStatus(Enum):
    """Step execution status."""

    PENDING = auto()
    RUNNING = auto()
    COMPLETED = auto()
    FAILED = auto()
    SKIPPED = auto()
    CACHED = auto()


@dataclass
class StepConfig:
    """Step configuration.

    Attributes:
        name: Step name
        retries: Retry count
        timeout: Timeout in seconds
        cache: Cache results
        resources: Resource requirements
    """

    name: str
    retries: int = 0
    timeout: Optional[int] = None
    cache: bool = True
    resources: Dict[str, Any] = field(default_factory=dict)


@dataclass
class StepResult:
    """Result of step execution.

    Attributes:
        step_name: Step name
        status: Execution status
        output: Step output
        error: Error message if failed
        started_at: When step started
        completed_at: When step completed
        duration_seconds: Execution duration
        attempt: Attempt number
        metrics: Step metrics
    """

    step_name: str
    status: StepStatus = StepStatus.PENDING
    output: Any = None
    error: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    duration_seconds: float = 0.0
    attempt: int = 1
    metrics: Dict[str, float] = field(default_factory=dict)

    @property
    def success(self) -> bool:
        """Check if step succeeded."""
        return self.status == StepStatus.COMPLETED


class Step:
    """A pipeline step.

    Represents a single unit of work in the pipeline.

    Features:
    - Automatic retry on failure
    - Timeout handling
    - Dependency injection
    - Metrics collection
    - Caching

    Example:
        step = Step(
            name="preprocess",
            func=preprocess_data,
            depends_on=["load_data"],
            retries=3,
        )
        result = step.execute({"load_data": raw_data})
    """

    def __init__(
        self,
        name: str,
        func: Callable,
        depends_on: Optional[List[str]] = None,
        retries: int = 0,
        timeout: Optional[int] = None,
        cache: bool = True,
        resources: Optional[Dict[str, Any]] = None,
    ):
        """Initialize step.

        Args:
            name: Step name
            func: Step function
            depends_on: Dependency step names
            retries: Retry count
            timeout: Timeout in seconds
            cache: Cache results
            resources: Resource requirements
        """
        self.name = name
        self.func = func
        self.depends_on = depends_on or []
        self.retries = retries
        self.timeout = timeout
        self.cache = cache
        self.resources = resources or {}

        self._last_result: Optional[StepResult] = None

    def execute(self, inputs: Optional[Dict[str, Any]] = None) -> StepResult:
        """Execute the step.

        Args:
            inputs: Input values from dependencies

        Returns:
            StepResult
        """
        inputs = inputs or {}
        result = StepResult(step_name=self.name, started_at=datetime.now())

        attempt = 0
        last_error = None

        while attempt <= self.retries:
            attempt += 1
            result.attempt = attempt

            try:
                result.status = StepStatus.RUNNING
                logger.info(f"Executing step '{self.name}' (attempt {attempt})")

                # Execute with timeout if specified
                if self.timeout:
                    import threading
                    output = [None]
                    error = [None]
                    completed = threading.Event()

                    def target():
                        try:
                            output[0] = self._invoke(inputs)
                        except Exception as e:
                            error[0] = e
                        finally:
                            completed.set()

                    thread = threading.Thread(target=target)
                    thread.start()

                    if not completed.wait(timeout=self.timeout):
                        raise TimeoutError(f"Step timed out after {self.timeout}s")

                    if error[0]:
                        raise error[0]

                    result.output = output[0]
                else:
                    result.output = self._invoke(inputs)

                result.status = StepStatus.COMPLETED
                logger.info(f"Step '{self.name}' completed")
                break

            except Exception as e:
                last_error = e
                logger.error(
                    f"Step '{self.name}' failed (attempt {attempt}): {e}"
                )

                if attempt > self.retries:
                    result.status = StepStatus.FAILED
                    result.error = str(e)
                else:
                    time.sleep(min(attempt * 2, 30))  # Exponential backoff

        result.completed_at = datetime.now()
        result.duration_seconds = (
            result.completed_at - result.started_at
        ).total_seconds()

        self._last_result = result
        return result

    def _invoke(self, inputs: Dict[str, Any]) -> Any:
        """Invoke the step function.

        Args:
            inputs: Input values

        Returns:
            Function output
        """
        import inspect

        sig = inspect.signature(self.func)
        params = sig.parameters

        # Build arguments from inputs
        kwargs = {}
        for param_name in params:
            if param_name in inputs:
                kwargs[param_name] = inputs[param_name]

        if kwargs:
            return self.func(**kwargs)
        else:
            return self.func()

    def get_last_result(self) -> Optional[StepResult]:
        """Get last execution result.

        Returns:
            StepResult or None
        """
        return self._last_result

    def __repr__(self) -> str:
        deps = f", deps={self.depends_on}" if self.depends_on else ""
        return f"Step(name={self.name!r}{deps})"


def step(
    name: Optional[str] = None,
    depends_on: Optional[List[str]] = None,
    retries: int = 0,
    timeout: Optional[int] = None,
    cache: bool = True,
) -> Callable:
    """Decorator to create a step.

    Args:
        name: Step name
        depends_on: Dependencies
        retries: Retry count
        timeout: Timeout seconds
        cache: Cache results

    Returns:
        Decorator function
    """
    def decorator(func: Callable) -> Step:
        step_name = name or func.__name__
        return Step(
            name=step_name,
            func=func,
            depends_on=depends_on,
            retries=retries,
            timeout=timeout,
            cache=cache,
        )

    return decorator


__all__ = ["Step", "StepConfig", "StepResult", "StepStatus", "step"]

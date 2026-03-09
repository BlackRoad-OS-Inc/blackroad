"""Task Base - Core task definitions.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import asyncio
import logging
import time
import traceback
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum, auto
from typing import (
    Any,
    Callable,
    Dict,
    Generic,
    List,
    Optional,
    Set,
    Tuple,
    Type,
    TypeVar,
    Union,
)

logger = logging.getLogger(__name__)

T = TypeVar("T")
R = TypeVar("R")


class TaskStatus(Enum):
    """Task execution status."""

    PENDING = "pending"
    QUEUED = "queued"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    SKIPPED = "skipped"
    CANCELLED = "cancelled"
    UPSTREAM_FAILED = "upstream_failed"
    RETRYING = "retrying"
    TIMEOUT = "timeout"
    DEFERRED = "deferred"


class TaskPriority(Enum):
    """Task priority levels."""

    LOWEST = 1
    LOW = 2
    NORMAL = 3
    HIGH = 4
    HIGHEST = 5
    CRITICAL = 6


class RetryPolicy(Enum):
    """Retry policies."""

    NONE = "none"
    FIXED = "fixed"
    EXPONENTIAL = "exponential"
    LINEAR = "linear"
    FIBONACCI = "fibonacci"


@dataclass
class RetryConfig:
    """Retry configuration."""

    max_retries: int = 3
    policy: RetryPolicy = RetryPolicy.EXPONENTIAL
    base_delay: float = 1.0
    max_delay: float = 300.0
    exponential_base: float = 2.0
    jitter: bool = True
    jitter_factor: float = 0.1
    retry_on: Optional[List[Type[Exception]]] = None
    ignore_on: Optional[List[Type[Exception]]] = None

    def get_delay(self, attempt: int) -> float:
        """Calculate delay for retry attempt."""
        if self.policy == RetryPolicy.NONE:
            return 0.0
        elif self.policy == RetryPolicy.FIXED:
            delay = self.base_delay
        elif self.policy == RetryPolicy.EXPONENTIAL:
            delay = self.base_delay * (self.exponential_base ** attempt)
        elif self.policy == RetryPolicy.LINEAR:
            delay = self.base_delay * (attempt + 1)
        elif self.policy == RetryPolicy.FIBONACCI:
            delay = self.base_delay * self._fibonacci(attempt + 2)
        else:
            delay = self.base_delay

        delay = min(delay, self.max_delay)

        if self.jitter:
            import random
            jitter_range = delay * self.jitter_factor
            delay += random.uniform(-jitter_range, jitter_range)

        return max(0.0, delay)

    def _fibonacci(self, n: int) -> int:
        """Calculate fibonacci number."""
        if n <= 1:
            return n
        a, b = 0, 1
        for _ in range(2, n + 1):
            a, b = b, a + b
        return b

    def should_retry(self, exception: Exception, attempt: int) -> bool:
        """Determine if should retry on exception."""
        if attempt >= self.max_retries:
            return False

        if self.ignore_on:
            for exc_type in self.ignore_on:
                if isinstance(exception, exc_type):
                    return False

        if self.retry_on:
            for exc_type in self.retry_on:
                if isinstance(exception, exc_type):
                    return True
            return False

        return True


@dataclass
class TaskConfig:
    """Task configuration."""

    task_id: str = ""
    name: str = ""
    description: str = ""
    owner: str = ""
    tags: List[str] = field(default_factory=list)
    priority: TaskPriority = TaskPriority.NORMAL
    timeout: Optional[float] = None
    retry_config: RetryConfig = field(default_factory=RetryConfig)
    pool: Optional[str] = None
    queue: Optional[str] = None
    trigger_rule: str = "all_success"
    weight_rule: str = "downstream"
    max_active_runs: int = 1
    depends_on_past: bool = False
    wait_for_downstream: bool = False
    run_as_user: Optional[str] = None
    resources: Dict[str, Any] = field(default_factory=dict)
    sla: Optional[timedelta] = None
    execution_timeout: Optional[timedelta] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    params: Dict[str, Any] = field(default_factory=dict)

    def __post_init__(self):
        if not self.task_id:
            self.task_id = str(uuid.uuid4())[:8]


@dataclass
class TaskContext:
    """Task execution context."""

    task_id: str
    run_id: str
    workflow_id: str
    execution_date: datetime
    attempt: int = 1
    params: Dict[str, Any] = field(default_factory=dict)
    upstream_results: Dict[str, Any] = field(default_factory=dict)
    state: Dict[str, Any] = field(default_factory=dict)
    xcom: Dict[str, Any] = field(default_factory=dict)
    var: Dict[str, Any] = field(default_factory=dict)

    def get_upstream_result(self, task_id: str) -> Optional[Any]:
        """Get result from upstream task."""
        return self.upstream_results.get(task_id)

    def push_xcom(self, key: str, value: Any) -> None:
        """Push value to XCom."""
        self.xcom[key] = value

    def pull_xcom(self, key: str, task_id: Optional[str] = None) -> Optional[Any]:
        """Pull value from XCom."""
        if task_id:
            return self.xcom.get(f"{task_id}.{key}")
        return self.xcom.get(key)

    def get_var(self, key: str, default: Any = None) -> Any:
        """Get variable value."""
        return self.var.get(key, default)

    def set_state(self, key: str, value: Any) -> None:
        """Set state value."""
        self.state[key] = value

    def get_state(self, key: str, default: Any = None) -> Any:
        """Get state value."""
        return self.state.get(key, default)


@dataclass
class TaskResult:
    """Task execution result."""

    task_id: str
    status: TaskStatus
    start_time: datetime
    end_time: Optional[datetime] = None
    duration: Optional[float] = None
    output: Any = None
    error: Optional[str] = None
    exception: Optional[Exception] = None
    traceback: Optional[str] = None
    attempt: int = 1
    retries: int = 0
    xcom: Dict[str, Any] = field(default_factory=dict)
    metrics: Dict[str, float] = field(default_factory=dict)
    logs: List[str] = field(default_factory=list)

    @property
    def is_success(self) -> bool:
        """Check if task succeeded."""
        return self.status == TaskStatus.SUCCESS

    @property
    def is_failed(self) -> bool:
        """Check if task failed."""
        return self.status in (TaskStatus.FAILED, TaskStatus.TIMEOUT, TaskStatus.UPSTREAM_FAILED)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "task_id": self.task_id,
            "status": self.status.value,
            "start_time": self.start_time.isoformat() if self.start_time else None,
            "end_time": self.end_time.isoformat() if self.end_time else None,
            "duration": self.duration,
            "output": str(self.output) if self.output else None,
            "error": self.error,
            "attempt": self.attempt,
            "retries": self.retries,
            "metrics": self.metrics,
        }


class TaskError(Exception):
    """Task execution error."""

    def __init__(
        self,
        message: str,
        task_id: Optional[str] = None,
        cause: Optional[Exception] = None,
        retryable: bool = True,
    ):
        super().__init__(message)
        self.task_id = task_id
        self.cause = cause
        self.retryable = retryable


class TaskSkipError(TaskError):
    """Raised to skip a task."""

    def __init__(self, message: str = "Task skipped", task_id: Optional[str] = None):
        super().__init__(message, task_id, retryable=False)


class TaskTimeoutError(TaskError):
    """Task timeout error."""

    def __init__(self, message: str, task_id: Optional[str] = None, timeout: float = 0):
        super().__init__(message, task_id, retryable=True)
        self.timeout = timeout


class Task(ABC, Generic[T]):
    """Abstract base task.

    Architecture:
    ┌────────────────────────────────────────────────────────────┐
    │                         Task                                │
    ├────────────────────────────────────────────────────────────┤
    │  ┌──────────────┐  ┌───────────────┐  ┌─────────────────┐  │
    │  │   Config     │  │   Context     │  │    Lifecycle    │  │
    │  │              │  │               │  │                 │  │
    │  │ - timeout    │  │ - params      │  │ - pre_execute   │  │
    │  │ - retries    │  │ - xcom        │  │ - execute       │  │
    │  │ - priority   │  │ - upstream    │  │ - post_execute  │  │
    │  │ - pool       │  │ - state       │  │ - on_failure    │  │
    │  └──────────────┘  └───────────────┘  └─────────────────┘  │
    ├────────────────────────────────────────────────────────────┤
    │  ┌──────────────────────────────────────────────────────┐  │
    │  │                   Execution Engine                    │  │
    │  │  - Retry logic with backoff                          │  │
    │  │  - Timeout handling                                   │  │
    │  │  - Error capture and logging                          │  │
    │  │  - Result collection                                  │  │
    │  └──────────────────────────────────────────────────────┘  │
    └────────────────────────────────────────────────────────────┘
    """

    def __init__(
        self,
        task_id: Optional[str] = None,
        name: Optional[str] = None,
        config: Optional[TaskConfig] = None,
        **kwargs,
    ):
        self.config = config or TaskConfig()

        if task_id:
            self.config.task_id = task_id
        if name:
            self.config.name = name

        for key, value in kwargs.items():
            if hasattr(self.config, key):
                setattr(self.config, key, value)

        self._dependencies: Set[str] = set()
        self._condition: Optional[Callable[[TaskContext], bool]] = None
        self._on_success_callbacks: List[Callable] = []
        self._on_failure_callbacks: List[Callable] = []
        self._on_retry_callbacks: List[Callable] = []

    @property
    def task_id(self) -> str:
        """Get task ID."""
        return self.config.task_id

    @property
    def name(self) -> str:
        """Get task name."""
        return self.config.name or self.config.task_id

    def depends_on(self, *tasks: Union[str, "Task"]) -> "Task":
        """Add dependencies."""
        for task in tasks:
            if isinstance(task, Task):
                self._dependencies.add(task.task_id)
            else:
                self._dependencies.add(task)
        return self

    def with_condition(self, condition: Callable[[TaskContext], bool]) -> "Task":
        """Set execution condition."""
        self._condition = condition
        return self

    def on_success(self, callback: Callable) -> "Task":
        """Add success callback."""
        self._on_success_callbacks.append(callback)
        return self

    def on_failure(self, callback: Callable) -> "Task":
        """Add failure callback."""
        self._on_failure_callbacks.append(callback)
        return self

    def on_retry(self, callback: Callable) -> "Task":
        """Add retry callback."""
        self._on_retry_callbacks.append(callback)
        return self

    def should_run(self, context: TaskContext) -> bool:
        """Check if task should run."""
        if self._condition:
            try:
                return self._condition(context)
            except Exception as e:
                logger.warning(f"Condition check failed for {self.task_id}: {e}")
                return False
        return True

    @abstractmethod
    def execute(self, context: TaskContext) -> T:
        """Execute the task.

        Args:
            context: Task execution context

        Returns:
            Task output
        """
        pass

    def pre_execute(self, context: TaskContext) -> None:
        """Pre-execution hook."""
        pass

    def post_execute(self, context: TaskContext, result: TaskResult) -> None:
        """Post-execution hook."""
        pass

    def on_failure_hook(self, context: TaskContext, exception: Exception) -> None:
        """Failure hook."""
        for callback in self._on_failure_callbacks:
            try:
                callback(context, exception)
            except Exception as e:
                logger.error(f"Failure callback error: {e}")

    def on_success_hook(self, context: TaskContext, result: TaskResult) -> None:
        """Success hook."""
        for callback in self._on_success_callbacks:
            try:
                callback(context, result)
            except Exception as e:
                logger.error(f"Success callback error: {e}")

    def on_retry_hook(self, context: TaskContext, attempt: int, exception: Exception) -> None:
        """Retry hook."""
        for callback in self._on_retry_callbacks:
            try:
                callback(context, attempt, exception)
            except Exception as e:
                logger.error(f"Retry callback error: {e}")

    def run(self, context: TaskContext) -> TaskResult:
        """Run the task with full lifecycle.

        Handles:
        - Pre/post execution hooks
        - Retry logic
        - Timeout
        - Error handling
        - Result collection
        """
        start_time = datetime.utcnow()
        attempt = 0
        last_exception: Optional[Exception] = None

        if not self.should_run(context):
            return TaskResult(
                task_id=self.task_id,
                status=TaskStatus.SKIPPED,
                start_time=start_time,
                end_time=datetime.utcnow(),
            )

        while True:
            attempt += 1
            context.attempt = attempt

            try:
                self.pre_execute(context)

                if self.config.timeout:
                    output = self._run_with_timeout(context, self.config.timeout)
                else:
                    output = self.execute(context)

                end_time = datetime.utcnow()
                duration = (end_time - start_time).total_seconds()

                result = TaskResult(
                    task_id=self.task_id,
                    status=TaskStatus.SUCCESS,
                    start_time=start_time,
                    end_time=end_time,
                    duration=duration,
                    output=output,
                    attempt=attempt,
                    retries=attempt - 1,
                    xcom=context.xcom,
                )

                self.post_execute(context, result)
                self.on_success_hook(context, result)

                logger.info(f"Task {self.task_id} completed successfully in {duration:.2f}s")
                return result

            except TaskSkipError as e:
                return TaskResult(
                    task_id=self.task_id,
                    status=TaskStatus.SKIPPED,
                    start_time=start_time,
                    end_time=datetime.utcnow(),
                    error=str(e),
                )

            except TaskTimeoutError as e:
                last_exception = e
                if not self.config.retry_config.should_retry(e, attempt):
                    break
                self._handle_retry(context, attempt, e)

            except Exception as e:
                last_exception = e
                if not self.config.retry_config.should_retry(e, attempt):
                    break
                self._handle_retry(context, attempt, e)

        end_time = datetime.utcnow()
        duration = (end_time - start_time).total_seconds()

        result = TaskResult(
            task_id=self.task_id,
            status=TaskStatus.FAILED,
            start_time=start_time,
            end_time=end_time,
            duration=duration,
            error=str(last_exception) if last_exception else "Unknown error",
            exception=last_exception,
            traceback=traceback.format_exc() if last_exception else None,
            attempt=attempt,
            retries=attempt - 1,
        )

        self.on_failure_hook(context, last_exception or Exception("Unknown"))
        logger.error(f"Task {self.task_id} failed after {attempt} attempts: {last_exception}")

        return result

    def _run_with_timeout(self, context: TaskContext, timeout: float) -> T:
        """Run execute with timeout."""
        import concurrent.futures

        with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(self.execute, context)
            try:
                return future.result(timeout=timeout)
            except concurrent.futures.TimeoutError:
                raise TaskTimeoutError(
                    f"Task {self.task_id} timed out after {timeout}s",
                    self.task_id,
                    timeout,
                )

    def _handle_retry(self, context: TaskContext, attempt: int, exception: Exception) -> None:
        """Handle retry logic."""
        delay = self.config.retry_config.get_delay(attempt)
        logger.warning(
            f"Task {self.task_id} failed (attempt {attempt}), "
            f"retrying in {delay:.2f}s: {exception}"
        )
        self.on_retry_hook(context, attempt, exception)
        time.sleep(delay)

    async def run_async(self, context: TaskContext) -> TaskResult:
        """Run task asynchronously."""
        start_time = datetime.utcnow()
        attempt = 0
        last_exception: Optional[Exception] = None

        if not self.should_run(context):
            return TaskResult(
                task_id=self.task_id,
                status=TaskStatus.SKIPPED,
                start_time=start_time,
                end_time=datetime.utcnow(),
            )

        while True:
            attempt += 1
            context.attempt = attempt

            try:
                self.pre_execute(context)

                if self.config.timeout:
                    output = await self._run_async_with_timeout(context, self.config.timeout)
                else:
                    if asyncio.iscoroutinefunction(self.execute):
                        output = await self.execute(context)
                    else:
                        loop = asyncio.get_event_loop()
                        output = await loop.run_in_executor(None, self.execute, context)

                end_time = datetime.utcnow()
                duration = (end_time - start_time).total_seconds()

                result = TaskResult(
                    task_id=self.task_id,
                    status=TaskStatus.SUCCESS,
                    start_time=start_time,
                    end_time=end_time,
                    duration=duration,
                    output=output,
                    attempt=attempt,
                    retries=attempt - 1,
                    xcom=context.xcom,
                )

                self.post_execute(context, result)
                self.on_success_hook(context, result)
                return result

            except TaskSkipError as e:
                return TaskResult(
                    task_id=self.task_id,
                    status=TaskStatus.SKIPPED,
                    start_time=start_time,
                    end_time=datetime.utcnow(),
                    error=str(e),
                )

            except Exception as e:
                last_exception = e
                if not self.config.retry_config.should_retry(e, attempt):
                    break
                delay = self.config.retry_config.get_delay(attempt)
                self.on_retry_hook(context, attempt, e)
                await asyncio.sleep(delay)

        end_time = datetime.utcnow()
        duration = (end_time - start_time).total_seconds()

        result = TaskResult(
            task_id=self.task_id,
            status=TaskStatus.FAILED,
            start_time=start_time,
            end_time=end_time,
            duration=duration,
            error=str(last_exception) if last_exception else "Unknown error",
            exception=last_exception,
            traceback=traceback.format_exc() if last_exception else None,
            attempt=attempt,
            retries=attempt - 1,
        )

        self.on_failure_hook(context, last_exception or Exception("Unknown"))
        return result

    async def _run_async_with_timeout(self, context: TaskContext, timeout: float) -> T:
        """Run execute async with timeout."""
        try:
            if asyncio.iscoroutinefunction(self.execute):
                return await asyncio.wait_for(self.execute(context), timeout=timeout)
            else:
                loop = asyncio.get_event_loop()
                return await asyncio.wait_for(
                    loop.run_in_executor(None, self.execute, context),
                    timeout=timeout,
                )
        except asyncio.TimeoutError:
            raise TaskTimeoutError(
                f"Task {self.task_id} timed out after {timeout}s",
                self.task_id,
                timeout,
            )


class SyncTask(Task[T]):
    """Synchronous task wrapper."""

    def __init__(
        self,
        func: Callable[[TaskContext], T],
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id or func.__name__, **kwargs)
        self._func = func

    def execute(self, context: TaskContext) -> T:
        """Execute the function."""
        return self._func(context)


class AsyncTask(Task[T]):
    """Asynchronous task wrapper."""

    def __init__(
        self,
        func: Callable[[TaskContext], Any],
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id or func.__name__, **kwargs)
        self._func = func

    def execute(self, context: TaskContext) -> T:
        """Execute the async function."""
        if asyncio.iscoroutinefunction(self._func):
            loop = asyncio.new_event_loop()
            try:
                return loop.run_until_complete(self._func(context))
            finally:
                loop.close()
        return self._func(context)


class BranchTask(Task[str]):
    """Branching task that determines which path to follow."""

    def __init__(
        self,
        branch_func: Callable[[TaskContext], Union[str, List[str]]],
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self._branch_func = branch_func

    def execute(self, context: TaskContext) -> str:
        """Execute branching logic."""
        result = self._branch_func(context)
        if isinstance(result, list):
            return ",".join(result)
        return result


class EmptyTask(Task[None]):
    """Empty task that does nothing."""

    def execute(self, context: TaskContext) -> None:
        """Do nothing."""
        pass


class TaskGroup:
    """Group of related tasks.

    Provides:
    - Namespace for task IDs
    - Shared configuration
    - Dependency management
    """

    def __init__(
        self,
        group_id: str,
        prefix_group_id: bool = True,
        tooltip: str = "",
        ui_color: str = "#ffffff",
        ui_fgcolor: str = "#000000",
        default_args: Optional[Dict[str, Any]] = None,
    ):
        self.group_id = group_id
        self.prefix_group_id = prefix_group_id
        self.tooltip = tooltip
        self.ui_color = ui_color
        self.ui_fgcolor = ui_fgcolor
        self.default_args = default_args or {}
        self._tasks: List[Task] = []

    def add(self, task: Task) -> Task:
        """Add task to group."""
        if self.prefix_group_id:
            original_id = task.config.task_id
            task.config.task_id = f"{self.group_id}.{original_id}"

        for key, value in self.default_args.items():
            if hasattr(task.config, key) and not getattr(task.config, key):
                setattr(task.config, key, value)

        self._tasks.append(task)
        return task

    def __iter__(self):
        return iter(self._tasks)

    def __len__(self):
        return len(self._tasks)


__all__ = [
    "Task",
    "SyncTask",
    "AsyncTask",
    "BranchTask",
    "EmptyTask",
    "TaskGroup",
    "TaskConfig",
    "TaskContext",
    "TaskResult",
    "TaskStatus",
    "TaskPriority",
    "TaskError",
    "TaskSkipError",
    "TaskTimeoutError",
    "RetryConfig",
    "RetryPolicy",
]

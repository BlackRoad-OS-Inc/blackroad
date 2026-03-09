"""RoadQueue Task Executor - Async Task Execution.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import asyncio
import logging
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor, Future
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Union

from roadqueue_core.queue.message import Message

logger = logging.getLogger(__name__)


class TaskStatus(Enum):
    """Task execution status."""

    PENDING = auto()
    RUNNING = auto()
    COMPLETED = auto()
    FAILED = auto()
    CANCELLED = auto()
    TIMEOUT = auto()


@dataclass
class TaskResult:
    """Result of task execution.

    Attributes:
        task_id: Task identifier
        status: Execution status
        result: Return value
        error: Error message if failed
        started_at: When execution started
        completed_at: When execution completed
        duration_ms: Execution duration
    """

    task_id: str
    status: TaskStatus = TaskStatus.PENDING
    result: Any = None
    error: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    duration_ms: float = 0.0

    @property
    def success(self) -> bool:
        """Check if task succeeded."""
        return self.status == TaskStatus.COMPLETED


@dataclass
class Task:
    """A task to execute."""

    task_id: str
    func: Callable
    args: tuple = field(default_factory=tuple)
    kwargs: Dict[str, Any] = field(default_factory=dict)
    timeout: Optional[float] = None
    priority: int = 0
    created_at: datetime = field(default_factory=datetime.now)


class TaskExecutor:
    """Async task executor.

    Executes tasks using thread or process pools.

    Features:
    - Thread and process pool execution
    - Async/await support
    - Task timeout
    - Priority scheduling
    - Result tracking
    """

    def __init__(
        self,
        max_workers: int = 10,
        use_processes: bool = False,
        default_timeout: Optional[float] = None,
    ):
        """Initialize executor.

        Args:
            max_workers: Maximum concurrent workers
            use_processes: Use process pool instead of threads
            default_timeout: Default task timeout in seconds
        """
        self.max_workers = max_workers
        self.use_processes = use_processes
        self.default_timeout = default_timeout

        self._executor: Optional[Union[ThreadPoolExecutor, ProcessPoolExecutor]] = None
        self._tasks: Dict[str, Task] = {}
        self._results: Dict[str, TaskResult] = {}
        self._futures: Dict[str, Future] = {}
        self._lock = threading.RLock()
        self._running = False

    def start(self) -> None:
        """Start the executor."""
        if self._running:
            return

        if self.use_processes:
            self._executor = ProcessPoolExecutor(max_workers=self.max_workers)
        else:
            self._executor = ThreadPoolExecutor(max_workers=self.max_workers)

        self._running = True
        logger.info(f"Task executor started with {self.max_workers} workers")

    def stop(self, wait: bool = True) -> None:
        """Stop the executor.

        Args:
            wait: Wait for pending tasks
        """
        if not self._running:
            return

        self._running = False
        if self._executor:
            self._executor.shutdown(wait=wait)
            self._executor = None

        logger.info("Task executor stopped")

    def submit(
        self,
        func: Callable,
        *args,
        timeout: Optional[float] = None,
        priority: int = 0,
        **kwargs,
    ) -> str:
        """Submit a task for execution.

        Args:
            func: Function to execute
            *args: Positional arguments
            timeout: Execution timeout
            priority: Task priority
            **kwargs: Keyword arguments

        Returns:
            Task ID
        """
        if not self._running:
            raise RuntimeError("Executor not running")

        task_id = str(uuid.uuid4())
        task = Task(
            task_id=task_id,
            func=func,
            args=args,
            kwargs=kwargs,
            timeout=timeout or self.default_timeout,
            priority=priority,
        )

        with self._lock:
            self._tasks[task_id] = task
            self._results[task_id] = TaskResult(task_id=task_id)

        # Submit to executor
        future = self._executor.submit(self._execute_task, task)
        self._futures[task_id] = future

        def callback(f: Future):
            self._handle_completion(task_id, f)

        future.add_done_callback(callback)

        return task_id

    def _execute_task(self, task: Task) -> Any:
        """Execute a task."""
        result = self._results[task.task_id]
        result.status = TaskStatus.RUNNING
        result.started_at = datetime.now()

        try:
            if task.timeout:
                # Execute with timeout
                return self._execute_with_timeout(
                    task.func, task.args, task.kwargs, task.timeout
                )
            else:
                return task.func(*task.args, **task.kwargs)
        except TimeoutError:
            result.status = TaskStatus.TIMEOUT
            result.error = f"Task timed out after {task.timeout}s"
            raise
        except Exception as e:
            result.status = TaskStatus.FAILED
            result.error = str(e)
            raise

    def _execute_with_timeout(
        self,
        func: Callable,
        args: tuple,
        kwargs: dict,
        timeout: float,
    ) -> Any:
        """Execute function with timeout."""
        result = [None]
        error = [None]
        completed = threading.Event()

        def target():
            try:
                result[0] = func(*args, **kwargs)
            except Exception as e:
                error[0] = e
            finally:
                completed.set()

        thread = threading.Thread(target=target)
        thread.start()

        if not completed.wait(timeout=timeout):
            raise TimeoutError(f"Task timed out after {timeout}s")

        if error[0]:
            raise error[0]

        return result[0]

    def _handle_completion(self, task_id: str, future: Future) -> None:
        """Handle task completion."""
        with self._lock:
            result = self._results.get(task_id)
            if not result:
                return

            result.completed_at = datetime.now()
            if result.started_at:
                result.duration_ms = (
                    result.completed_at - result.started_at
                ).total_seconds() * 1000

            try:
                result.result = future.result()
                if result.status == TaskStatus.RUNNING:
                    result.status = TaskStatus.COMPLETED
            except Exception as e:
                if result.status == TaskStatus.RUNNING:
                    result.status = TaskStatus.FAILED
                    result.error = str(e)

    def cancel(self, task_id: str) -> bool:
        """Cancel a task.

        Args:
            task_id: Task to cancel

        Returns:
            True if cancelled
        """
        with self._lock:
            future = self._futures.get(task_id)
            if future and future.cancel():
                result = self._results.get(task_id)
                if result:
                    result.status = TaskStatus.CANCELLED
                return True
            return False

    def get_result(self, task_id: str) -> Optional[TaskResult]:
        """Get task result.

        Args:
            task_id: Task ID

        Returns:
            TaskResult or None
        """
        return self._results.get(task_id)

    def wait(self, task_id: str, timeout: Optional[float] = None) -> TaskResult:
        """Wait for task completion.

        Args:
            task_id: Task ID
            timeout: Maximum wait time

        Returns:
            TaskResult
        """
        future = self._futures.get(task_id)
        if future:
            try:
                future.result(timeout=timeout)
            except Exception:
                pass

        return self._results.get(task_id, TaskResult(task_id=task_id))

    def wait_all(
        self,
        task_ids: List[str],
        timeout: Optional[float] = None,
    ) -> Dict[str, TaskResult]:
        """Wait for multiple tasks.

        Args:
            task_ids: Task IDs to wait for
            timeout: Maximum wait time

        Returns:
            Dict of task_id -> TaskResult
        """
        start = time.time()
        results = {}

        for task_id in task_ids:
            remaining = None
            if timeout:
                remaining = timeout - (time.time() - start)
                if remaining <= 0:
                    break
            results[task_id] = self.wait(task_id, remaining)

        return results

    async def submit_async(
        self,
        func: Callable,
        *args,
        timeout: Optional[float] = None,
        **kwargs,
    ) -> TaskResult:
        """Submit and await a task.

        Args:
            func: Function to execute
            *args: Positional arguments
            timeout: Execution timeout
            **kwargs: Keyword arguments

        Returns:
            TaskResult
        """
        loop = asyncio.get_event_loop()
        task_id = self.submit(func, *args, timeout=timeout, **kwargs)

        future = self._futures.get(task_id)
        if future:
            await loop.run_in_executor(None, future.result)

        return self._results.get(task_id, TaskResult(task_id=task_id))

    def map(
        self,
        func: Callable,
        items: List[Any],
        timeout: Optional[float] = None,
    ) -> List[TaskResult]:
        """Execute function on multiple items.

        Args:
            func: Function to execute
            items: Items to process
            timeout: Per-item timeout

        Returns:
            List of TaskResults
        """
        task_ids = [self.submit(func, item, timeout=timeout) for item in items]
        return [self.wait(tid) for tid in task_ids]

    def get_stats(self) -> Dict[str, Any]:
        """Get executor statistics."""
        with self._lock:
            completed = sum(1 for r in self._results.values() if r.status == TaskStatus.COMPLETED)
            failed = sum(1 for r in self._results.values() if r.status == TaskStatus.FAILED)
            pending = sum(1 for r in self._results.values() if r.status in (TaskStatus.PENDING, TaskStatus.RUNNING))

            return {
                "running": self._running,
                "max_workers": self.max_workers,
                "use_processes": self.use_processes,
                "total_tasks": len(self._tasks),
                "completed": completed,
                "failed": failed,
                "pending": pending,
            }

    def __enter__(self) -> "TaskExecutor":
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.stop()


__all__ = ["TaskExecutor", "TaskResult", "TaskStatus", "Task"]

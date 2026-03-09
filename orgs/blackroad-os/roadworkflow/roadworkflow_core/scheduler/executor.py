"""Task Executors - Execution backends.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import asyncio
import concurrent.futures
import logging
import multiprocessing
import os
import queue
import threading
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, TypeVar

logger = logging.getLogger(__name__)

T = TypeVar("T")


class ExecutorType(Enum):
    """Executor types."""

    LOCAL = "local"
    THREAD_POOL = "thread_pool"
    PROCESS_POOL = "process_pool"
    CELERY = "celery"
    KUBERNETES = "kubernetes"
    DASK = "dask"


@dataclass
class ExecutorConfig:
    """Executor configuration."""

    executor_type: ExecutorType = ExecutorType.THREAD_POOL
    parallelism: int = 32
    max_workers: Optional[int] = None
    task_timeout: float = 3600.0
    heartbeat_interval: float = 5.0
    result_backend: str = "memory"
    queue_name: str = "default"


@dataclass
class ExecutionSlot:
    """A slot in the executor."""

    slot_id: str
    task_id: str
    started_at: datetime
    state: str = "running"
    worker_id: Optional[str] = None


class Executor(ABC):
    """Abstract base executor.

    Architecture:
    ┌─────────────────────────────────────────────────────────────────────┐
    │                          Executor                                    │
    ├─────────────────────────────────────────────────────────────────────┤
    │  ┌───────────────────┐  ┌────────────────┐  ┌────────────────────┐  │
    │  │    Task Queue     │  │    Workers     │  │   Result Store     │  │
    │  │                   │  │                │  │                    │  │
    │  │ ┌───┐ ┌───┐ ┌───┐ │  │  W1  W2  W3   │  │  {task_id: result} │  │
    │  │ │T1 │ │T2 │ │T3 │ │  │   ↓   ↓   ↓   │  │                    │  │
    │  │ └───┘ └───┘ └───┘ │  │  Execute      │  │  - store           │  │
    │  │        ↓          │  │               │  │  - retrieve        │  │
    │  │    dequeue        │  │               │  │  - cleanup         │  │
    │  └───────────────────┘  └────────────────┘  └────────────────────┘  │
    ├─────────────────────────────────────────────────────────────────────┤
    │  Methods: start() | stop() | submit() | get_result() | status()    │
    └─────────────────────────────────────────────────────────────────────┘
    """

    def __init__(self, config: Optional[ExecutorConfig] = None):
        self.config = config or ExecutorConfig()
        self._running = False
        self._slots: Dict[str, ExecutionSlot] = {}
        self._results: Dict[str, Any] = {}
        self._lock = threading.RLock()

    @property
    def is_running(self) -> bool:
        """Check if executor is running."""
        return self._running

    @property
    def parallelism(self) -> int:
        """Get parallelism level."""
        return self.config.parallelism

    @abstractmethod
    def start(self) -> None:
        """Start the executor."""
        pass

    @abstractmethod
    def stop(self, wait: bool = True) -> None:
        """Stop the executor."""
        pass

    @abstractmethod
    def submit(
        self,
        task_id: str,
        func: Callable[..., T],
        *args,
        **kwargs,
    ) -> str:
        """Submit task for execution.

        Args:
            task_id: Task identifier
            func: Function to execute
            *args: Positional arguments
            **kwargs: Keyword arguments

        Returns:
            Execution ID
        """
        pass

    @abstractmethod
    def get_result(
        self,
        execution_id: str,
        timeout: Optional[float] = None,
    ) -> Optional[Any]:
        """Get task result.

        Args:
            execution_id: Execution identifier
            timeout: Wait timeout

        Returns:
            Task result or None
        """
        pass

    def cancel(self, execution_id: str) -> bool:
        """Cancel task execution."""
        return False

    def get_status(self, execution_id: str) -> Optional[str]:
        """Get execution status."""
        with self._lock:
            if execution_id in self._slots:
                return self._slots[execution_id].state
            if execution_id in self._results:
                return "completed"
        return None

    def get_active_count(self) -> int:
        """Get number of active executions."""
        with self._lock:
            return len([s for s in self._slots.values() if s.state == "running"])

    def has_capacity(self) -> bool:
        """Check if executor has capacity."""
        return self.get_active_count() < self.parallelism


class LocalExecutor(Executor):
    """Execute tasks locally in sequence.

    Good for:
    - Development and testing
    - Single-machine deployments
    - Low-parallelism workloads
    """

    def __init__(self, config: Optional[ExecutorConfig] = None):
        super().__init__(config)
        self._queue: queue.Queue = queue.Queue()
        self._worker_thread: Optional[threading.Thread] = None

    def start(self) -> None:
        """Start the executor."""
        if self._running:
            return

        self._running = True
        self._worker_thread = threading.Thread(
            target=self._worker_loop,
            daemon=True,
            name="LocalExecutor-Worker",
        )
        self._worker_thread.start()
        logger.info("LocalExecutor started")

    def stop(self, wait: bool = True) -> None:
        """Stop the executor."""
        self._running = False
        self._queue.put(None)

        if wait and self._worker_thread:
            self._worker_thread.join(timeout=30)

        logger.info("LocalExecutor stopped")

    def submit(
        self,
        task_id: str,
        func: Callable[..., T],
        *args,
        **kwargs,
    ) -> str:
        """Submit task for execution."""
        execution_id = f"{task_id}_{time.time()}"

        slot = ExecutionSlot(
            slot_id=execution_id,
            task_id=task_id,
            started_at=datetime.utcnow(),
        )

        with self._lock:
            self._slots[execution_id] = slot

        self._queue.put((execution_id, func, args, kwargs))
        return execution_id

    def get_result(
        self,
        execution_id: str,
        timeout: Optional[float] = None,
    ) -> Optional[Any]:
        """Get task result."""
        start_time = time.time()

        while True:
            with self._lock:
                if execution_id in self._results:
                    return self._results.pop(execution_id)

            if timeout and (time.time() - start_time) >= timeout:
                return None

            time.sleep(0.1)

    def _worker_loop(self) -> None:
        """Worker loop for executing tasks."""
        while self._running:
            try:
                item = self._queue.get(timeout=1)

                if item is None:
                    break

                execution_id, func, args, kwargs = item

                try:
                    result = func(*args, **kwargs)

                    with self._lock:
                        self._results[execution_id] = result
                        if execution_id in self._slots:
                            self._slots[execution_id].state = "completed"
                            del self._slots[execution_id]

                except Exception as e:
                    logger.error(f"Task {execution_id} failed: {e}")

                    with self._lock:
                        self._results[execution_id] = e
                        if execution_id in self._slots:
                            self._slots[execution_id].state = "failed"
                            del self._slots[execution_id]

            except queue.Empty:
                continue


class ThreadPoolExecutor(Executor):
    """Execute tasks using thread pool.

    Good for:
    - I/O-bound workloads
    - Multiple concurrent tasks
    - Standard parallelism needs
    """

    def __init__(self, config: Optional[ExecutorConfig] = None):
        super().__init__(config)
        self._executor: Optional[concurrent.futures.ThreadPoolExecutor] = None
        self._futures: Dict[str, concurrent.futures.Future] = {}

    def start(self) -> None:
        """Start the executor."""
        if self._running:
            return

        max_workers = self.config.max_workers or self.config.parallelism

        self._executor = concurrent.futures.ThreadPoolExecutor(
            max_workers=max_workers,
            thread_name_prefix="RoadWorkflow-Worker",
        )
        self._running = True
        logger.info(f"ThreadPoolExecutor started with {max_workers} workers")

    def stop(self, wait: bool = True) -> None:
        """Stop the executor."""
        if self._executor:
            self._executor.shutdown(wait=wait)
            self._executor = None

        self._running = False
        logger.info("ThreadPoolExecutor stopped")

    def submit(
        self,
        task_id: str,
        func: Callable[..., T],
        *args,
        **kwargs,
    ) -> str:
        """Submit task for execution."""
        if not self._executor:
            raise RuntimeError("Executor not started")

        execution_id = f"{task_id}_{time.time()}"

        slot = ExecutionSlot(
            slot_id=execution_id,
            task_id=task_id,
            started_at=datetime.utcnow(),
        )

        with self._lock:
            self._slots[execution_id] = slot

        future = self._executor.submit(self._execute_task, execution_id, func, args, kwargs)

        with self._lock:
            self._futures[execution_id] = future

        return execution_id

    def _execute_task(
        self,
        execution_id: str,
        func: Callable,
        args: tuple,
        kwargs: dict,
    ) -> Any:
        """Execute task and handle result."""
        try:
            result = func(*args, **kwargs)

            with self._lock:
                self._results[execution_id] = result
                if execution_id in self._slots:
                    self._slots[execution_id].state = "completed"
                    del self._slots[execution_id]

            return result

        except Exception as e:
            with self._lock:
                self._results[execution_id] = e
                if execution_id in self._slots:
                    self._slots[execution_id].state = "failed"
                    del self._slots[execution_id]
            raise

    def get_result(
        self,
        execution_id: str,
        timeout: Optional[float] = None,
    ) -> Optional[Any]:
        """Get task result."""
        with self._lock:
            future = self._futures.get(execution_id)

        if not future:
            with self._lock:
                return self._results.get(execution_id)

        try:
            result = future.result(timeout=timeout)
            return result
        except concurrent.futures.TimeoutError:
            return None
        except Exception:
            with self._lock:
                return self._results.get(execution_id)

    def cancel(self, execution_id: str) -> bool:
        """Cancel task execution."""
        with self._lock:
            future = self._futures.get(execution_id)

        if future:
            return future.cancel()
        return False


class ProcessPoolExecutor(Executor):
    """Execute tasks using process pool.

    Good for:
    - CPU-bound workloads
    - GIL-limited tasks
    - Heavy computation
    """

    def __init__(self, config: Optional[ExecutorConfig] = None):
        super().__init__(config)
        self._executor: Optional[concurrent.futures.ProcessPoolExecutor] = None
        self._futures: Dict[str, concurrent.futures.Future] = {}
        self._manager: Optional[multiprocessing.Manager] = None
        self._shared_results: Optional[Dict] = None

    def start(self) -> None:
        """Start the executor."""
        if self._running:
            return

        max_workers = self.config.max_workers or min(
            self.config.parallelism,
            os.cpu_count() or 4,
        )

        self._manager = multiprocessing.Manager()
        self._shared_results = self._manager.dict()

        self._executor = concurrent.futures.ProcessPoolExecutor(
            max_workers=max_workers,
        )
        self._running = True
        logger.info(f"ProcessPoolExecutor started with {max_workers} workers")

    def stop(self, wait: bool = True) -> None:
        """Stop the executor."""
        if self._executor:
            self._executor.shutdown(wait=wait)
            self._executor = None

        if self._manager:
            self._manager.shutdown()
            self._manager = None

        self._running = False
        logger.info("ProcessPoolExecutor stopped")

    def submit(
        self,
        task_id: str,
        func: Callable[..., T],
        *args,
        **kwargs,
    ) -> str:
        """Submit task for execution."""
        if not self._executor:
            raise RuntimeError("Executor not started")

        execution_id = f"{task_id}_{time.time()}"

        slot = ExecutionSlot(
            slot_id=execution_id,
            task_id=task_id,
            started_at=datetime.utcnow(),
        )

        with self._lock:
            self._slots[execution_id] = slot

        future = self._executor.submit(func, *args, **kwargs)
        future.add_done_callback(lambda f: self._on_complete(execution_id, f))

        with self._lock:
            self._futures[execution_id] = future

        return execution_id

    def _on_complete(
        self,
        execution_id: str,
        future: concurrent.futures.Future,
    ) -> None:
        """Handle task completion."""
        try:
            result = future.result()
            with self._lock:
                self._results[execution_id] = result
                if execution_id in self._slots:
                    self._slots[execution_id].state = "completed"
                    del self._slots[execution_id]
        except Exception as e:
            with self._lock:
                self._results[execution_id] = e
                if execution_id in self._slots:
                    self._slots[execution_id].state = "failed"
                    del self._slots[execution_id]

    def get_result(
        self,
        execution_id: str,
        timeout: Optional[float] = None,
    ) -> Optional[Any]:
        """Get task result."""
        with self._lock:
            future = self._futures.get(execution_id)

        if not future:
            with self._lock:
                return self._results.get(execution_id)

        try:
            return future.result(timeout=timeout)
        except concurrent.futures.TimeoutError:
            return None
        except Exception:
            with self._lock:
                return self._results.get(execution_id)


class AsyncExecutor(Executor):
    """Async executor for coroutine tasks."""

    def __init__(self, config: Optional[ExecutorConfig] = None):
        super().__init__(config)
        self._loop: Optional[asyncio.AbstractEventLoop] = None
        self._tasks: Dict[str, asyncio.Task] = {}

    def start(self) -> None:
        """Start the executor."""
        if self._running:
            return

        self._loop = asyncio.new_event_loop()
        self._running = True
        logger.info("AsyncExecutor started")

    def stop(self, wait: bool = True) -> None:
        """Stop the executor."""
        if self._loop:
            for task in self._tasks.values():
                task.cancel()

            if wait:
                self._loop.run_until_complete(
                    asyncio.gather(*self._tasks.values(), return_exceptions=True)
                )

            self._loop.close()
            self._loop = None

        self._running = False
        logger.info("AsyncExecutor stopped")

    def submit(
        self,
        task_id: str,
        func: Callable[..., T],
        *args,
        **kwargs,
    ) -> str:
        """Submit async task for execution."""
        if not self._loop:
            raise RuntimeError("Executor not started")

        execution_id = f"{task_id}_{time.time()}"

        slot = ExecutionSlot(
            slot_id=execution_id,
            task_id=task_id,
            started_at=datetime.utcnow(),
        )

        with self._lock:
            self._slots[execution_id] = slot

        if asyncio.iscoroutinefunction(func):
            coro = func(*args, **kwargs)
        else:
            async def wrapper():
                return func(*args, **kwargs)
            coro = wrapper()

        task = self._loop.create_task(coro)
        task.add_done_callback(lambda t: self._on_complete(execution_id, t))

        with self._lock:
            self._tasks[execution_id] = task

        return execution_id

    def _on_complete(self, execution_id: str, task: asyncio.Task) -> None:
        """Handle task completion."""
        try:
            result = task.result()
            with self._lock:
                self._results[execution_id] = result
                if execution_id in self._slots:
                    self._slots[execution_id].state = "completed"
                    del self._slots[execution_id]
        except asyncio.CancelledError:
            with self._lock:
                if execution_id in self._slots:
                    self._slots[execution_id].state = "cancelled"
                    del self._slots[execution_id]
        except Exception as e:
            with self._lock:
                self._results[execution_id] = e
                if execution_id in self._slots:
                    self._slots[execution_id].state = "failed"
                    del self._slots[execution_id]

    def get_result(
        self,
        execution_id: str,
        timeout: Optional[float] = None,
    ) -> Optional[Any]:
        """Get task result."""
        with self._lock:
            return self._results.get(execution_id)

    async def submit_async(
        self,
        task_id: str,
        coro: Any,
    ) -> str:
        """Submit coroutine directly."""
        execution_id = f"{task_id}_{time.time()}"

        slot = ExecutionSlot(
            slot_id=execution_id,
            task_id=task_id,
            started_at=datetime.utcnow(),
        )

        with self._lock:
            self._slots[execution_id] = slot

        task = asyncio.create_task(coro)
        task.add_done_callback(lambda t: self._on_complete(execution_id, t))

        with self._lock:
            self._tasks[execution_id] = task

        return execution_id

    async def get_result_async(
        self,
        execution_id: str,
        timeout: Optional[float] = None,
    ) -> Optional[Any]:
        """Get result asynchronously."""
        with self._lock:
            task = self._tasks.get(execution_id)

        if task:
            try:
                if timeout:
                    return await asyncio.wait_for(task, timeout=timeout)
                return await task
            except asyncio.TimeoutError:
                return None
            except Exception:
                pass

        with self._lock:
            return self._results.get(execution_id)


class ExecutorFactory:
    """Factory for creating executors."""

    _registry: Dict[ExecutorType, type] = {
        ExecutorType.LOCAL: LocalExecutor,
        ExecutorType.THREAD_POOL: ThreadPoolExecutor,
        ExecutorType.PROCESS_POOL: ProcessPoolExecutor,
    }

    @classmethod
    def create(
        cls,
        executor_type: ExecutorType,
        config: Optional[ExecutorConfig] = None,
    ) -> Executor:
        """Create executor by type."""
        if executor_type not in cls._registry:
            raise ValueError(f"Unknown executor type: {executor_type}")

        executor_class = cls._registry[executor_type]
        return executor_class(config)

    @classmethod
    def register(cls, executor_type: ExecutorType, executor_class: type) -> None:
        """Register custom executor."""
        cls._registry[executor_type] = executor_class


__all__ = [
    "Executor",
    "ExecutorConfig",
    "ExecutorType",
    "ExecutionSlot",
    "LocalExecutor",
    "ThreadPoolExecutor",
    "ProcessPoolExecutor",
    "AsyncExecutor",
    "ExecutorFactory",
]

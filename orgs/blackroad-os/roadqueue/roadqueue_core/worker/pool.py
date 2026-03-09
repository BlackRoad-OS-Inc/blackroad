"""RoadQueue Worker Pool - Worker Lifecycle Management.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, Future
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set

from roadqueue_core.queue.message import Message
from roadqueue_core.queue.base import Queue
from roadqueue_core.worker.worker import Worker, WorkerState, WorkerStats

logger = logging.getLogger(__name__)


class PoolState(Enum):
    """Pool operational states."""

    STOPPED = auto()
    STARTING = auto()
    RUNNING = auto()
    SCALING = auto()
    STOPPING = auto()


@dataclass
class PoolConfig:
    """Worker pool configuration.

    Attributes:
        name: Pool name
        min_workers: Minimum worker count
        max_workers: Maximum worker count
        worker_prefetch: Prefetch per worker
        worker_timeout: Processing timeout
        idle_timeout: Seconds before idle worker shutdown
        scale_up_threshold: Queue size to trigger scale up
        scale_down_threshold: Queue size to trigger scale down
        healthcheck_interval: Seconds between health checks
    """

    name: str = "pool"
    min_workers: int = 1
    max_workers: int = 10
    worker_prefetch: int = 1
    worker_timeout: int = 30
    idle_timeout: int = 60
    scale_up_threshold: int = 100
    scale_down_threshold: int = 10
    healthcheck_interval: int = 30


@dataclass
class PoolStats:
    """Worker pool statistics."""

    state: PoolState = PoolState.STOPPED
    workers_active: int = 0
    workers_idle: int = 0
    workers_processing: int = 0
    messages_processed: int = 0
    messages_failed: int = 0
    queue_size: int = 0
    throughput_per_second: float = 0.0
    started_at: Optional[datetime] = None


class WorkerPool:
    """Managed pool of workers.

    Features:
    - Auto-scaling based on queue size
    - Worker lifecycle management
    - Health monitoring
    - Graceful shutdown
    - Statistics aggregation
    """

    def __init__(
        self,
        queue: Optional[Queue] = None,
        handler: Optional[Callable[[Message], Any]] = None,
        config: Optional[PoolConfig] = None,
    ):
        """Initialize worker pool.

        Args:
            queue: Queue to consume from
            handler: Message handler
            config: Pool configuration
        """
        self.queue = queue
        self.handler = handler
        self.config = config or PoolConfig()

        self._workers: Dict[str, Worker] = {}
        self._futures: Dict[str, Future] = {}
        self._state = PoolState.STOPPED
        self._lock = threading.RLock()
        self._executor: Optional[ThreadPoolExecutor] = None

        self._stats = PoolStats()
        self._started_at: Optional[datetime] = None
        self._message_count_window: List[tuple] = []

        # Background threads
        self._consumer_thread: Optional[threading.Thread] = None
        self._monitor_thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()

    @property
    def state(self) -> PoolState:
        """Get pool state."""
        return self._state

    def start(self) -> None:
        """Start the worker pool."""
        with self._lock:
            if self._state != PoolState.STOPPED:
                return

            self._state = PoolState.STARTING
            self._started_at = datetime.now()
            self._stop_event.clear()

            # Create executor
            self._executor = ThreadPoolExecutor(
                max_workers=self.config.max_workers,
                thread_name_prefix=f"{self.config.name}-worker",
            )

            # Start minimum workers
            for _ in range(self.config.min_workers):
                self._spawn_worker()

            # Start consumer thread
            if self.queue:
                self._consumer_thread = threading.Thread(
                    target=self._consume_loop,
                    daemon=True,
                    name=f"{self.config.name}-consumer",
                )
                self._consumer_thread.start()

            # Start monitor thread
            self._monitor_thread = threading.Thread(
                target=self._monitor_loop,
                daemon=True,
                name=f"{self.config.name}-monitor",
            )
            self._monitor_thread.start()

            self._state = PoolState.RUNNING
            logger.info(f"Worker pool {self.config.name} started with {len(self._workers)} workers")

    def stop(self, graceful: bool = True, timeout: float = 30.0) -> None:
        """Stop the worker pool.

        Args:
            graceful: Wait for workers to finish
            timeout: Maximum time to wait
        """
        with self._lock:
            if self._state == PoolState.STOPPED:
                return

            self._state = PoolState.STOPPING
            self._stop_event.set()

            # Stop all workers
            for worker in self._workers.values():
                worker.stop(graceful=graceful, timeout=timeout / len(self._workers))

            # Shutdown executor
            if self._executor:
                self._executor.shutdown(wait=graceful, cancel_futures=not graceful)
                self._executor = None

            self._workers.clear()
            self._state = PoolState.STOPPED
            logger.info(f"Worker pool {self.config.name} stopped")

    def _spawn_worker(self) -> Worker:
        """Spawn a new worker."""
        worker_id = f"{self.config.name}-{uuid.uuid4().hex[:8]}"
        worker = Worker(
            worker_id=worker_id,
            handler=self.handler,
            prefetch=self.config.worker_prefetch,
            timeout_seconds=self.config.worker_timeout,
        )
        worker.start()
        self._workers[worker_id] = worker
        logger.debug(f"Spawned worker {worker_id}")
        return worker

    def _remove_worker(self, worker_id: str) -> None:
        """Remove a worker."""
        with self._lock:
            if worker_id in self._workers:
                worker = self._workers.pop(worker_id)
                worker.stop()
                logger.debug(f"Removed worker {worker_id}")

    def _consume_loop(self) -> None:
        """Background loop to consume messages."""
        while not self._stop_event.is_set():
            try:
                message = self.queue.get(timeout=1.0)
                if message:
                    self._dispatch(message)
            except Exception as e:
                logger.error(f"Consumer error: {e}")
                time.sleep(1.0)

    def _dispatch(self, message: Message) -> None:
        """Dispatch a message to a worker."""
        # Find idle worker
        worker = self._get_idle_worker()
        if not worker:
            # Scale up if possible
            if len(self._workers) < self.config.max_workers:
                worker = self._spawn_worker()
            else:
                # All workers busy, wait for one
                time.sleep(0.1)
                self._dispatch(message)
                return

        # Submit to executor
        if self._executor:
            future = self._executor.submit(worker.process, message)
            self._futures[message.id] = future

            def callback(f: Future):
                try:
                    success = f.result()
                    if success:
                        self._stats.messages_processed += 1
                    else:
                        self._stats.messages_failed += 1
                except Exception as e:
                    self._stats.messages_failed += 1
                    logger.error(f"Worker error: {e}")

            future.add_done_callback(callback)

    def _get_idle_worker(self) -> Optional[Worker]:
        """Get an idle worker."""
        with self._lock:
            for worker in self._workers.values():
                if worker.state == WorkerState.IDLE:
                    return worker
        return None

    def _monitor_loop(self) -> None:
        """Background monitoring loop."""
        while not self._stop_event.is_set():
            try:
                self._check_health()
                self._auto_scale()
                self._update_stats()
            except Exception as e:
                logger.error(f"Monitor error: {e}")

            time.sleep(self.config.healthcheck_interval)

    def _check_health(self) -> None:
        """Check worker health."""
        now = datetime.now()

        with self._lock:
            for worker_id, worker in list(self._workers.items()):
                stats = worker.get_stats()

                # Check for stuck workers
                if stats.state == WorkerState.PROCESSING:
                    if stats.last_heartbeat:
                        age = (now - stats.last_heartbeat).total_seconds()
                        if age > self.config.worker_timeout * 2:
                            logger.warning(f"Worker {worker_id} appears stuck")
                            self._remove_worker(worker_id)
                            self._spawn_worker()

    def _auto_scale(self) -> None:
        """Auto-scale workers based on queue size."""
        if not self.queue or self._state != PoolState.RUNNING:
            return

        queue_size = len(self.queue)
        worker_count = len(self._workers)

        with self._lock:
            if queue_size > self.config.scale_up_threshold:
                if worker_count < self.config.max_workers:
                    self._state = PoolState.SCALING
                    workers_to_add = min(
                        self.config.max_workers - worker_count,
                        queue_size // self.config.scale_up_threshold,
                    )
                    for _ in range(workers_to_add):
                        self._spawn_worker()
                    logger.info(f"Scaled up to {len(self._workers)} workers")
                    self._state = PoolState.RUNNING

            elif queue_size < self.config.scale_down_threshold:
                if worker_count > self.config.min_workers:
                    self._state = PoolState.SCALING
                    # Remove idle workers
                    idle_workers = [
                        w for w in self._workers.values()
                        if w.state == WorkerState.IDLE
                    ]
                    workers_to_remove = min(
                        len(idle_workers),
                        worker_count - self.config.min_workers,
                    )
                    for worker in idle_workers[:workers_to_remove]:
                        self._remove_worker(worker.worker_id)
                    logger.info(f"Scaled down to {len(self._workers)} workers")
                    self._state = PoolState.RUNNING

    def _update_stats(self) -> None:
        """Update pool statistics."""
        now = time.time()

        with self._lock:
            idle = sum(1 for w in self._workers.values() if w.state == WorkerState.IDLE)
            processing = sum(1 for w in self._workers.values() if w.state == WorkerState.PROCESSING)

            self._stats.workers_active = len(self._workers)
            self._stats.workers_idle = idle
            self._stats.workers_processing = processing

            if self.queue:
                self._stats.queue_size = len(self.queue)

            # Calculate throughput
            self._message_count_window.append((now, self._stats.messages_processed))
            # Keep last 60 seconds
            self._message_count_window = [
                (t, c) for t, c in self._message_count_window
                if now - t < 60
            ]

            if len(self._message_count_window) >= 2:
                oldest = self._message_count_window[0]
                newest = self._message_count_window[-1]
                elapsed = newest[0] - oldest[0]
                if elapsed > 0:
                    self._stats.throughput_per_second = (
                        (newest[1] - oldest[1]) / elapsed
                    )

    def scale(self, target_workers: int) -> None:
        """Manually scale to target worker count.

        Args:
            target_workers: Desired worker count
        """
        target = max(self.config.min_workers, min(target_workers, self.config.max_workers))

        with self._lock:
            current = len(self._workers)

            if target > current:
                for _ in range(target - current):
                    self._spawn_worker()
            elif target < current:
                idle_workers = [
                    w for w in self._workers.values()
                    if w.state == WorkerState.IDLE
                ]
                for worker in idle_workers[:current - target]:
                    self._remove_worker(worker.worker_id)

            logger.info(f"Scaled pool to {len(self._workers)} workers")

    def get_stats(self) -> PoolStats:
        """Get pool statistics."""
        self._stats.state = self._state
        self._stats.started_at = self._started_at
        return self._stats

    def get_worker_stats(self) -> List[WorkerStats]:
        """Get statistics for all workers."""
        with self._lock:
            return [w.get_stats() for w in self._workers.values()]

    def __len__(self) -> int:
        """Get worker count."""
        return len(self._workers)

    def __repr__(self) -> str:
        return f"WorkerPool(name={self.config.name!r}, workers={len(self._workers)}, state={self._state.name})"

    def __enter__(self) -> "WorkerPool":
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.stop()


__all__ = ["WorkerPool", "PoolConfig", "PoolState", "PoolStats"]

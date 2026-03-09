"""RoadQueue Worker - Message Processing Worker.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import signal
import threading
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set

from roadqueue_core.queue.message import Message, MessageState

logger = logging.getLogger(__name__)


class WorkerState(Enum):
    """Worker operational states."""

    IDLE = auto()       # Waiting for work
    PROCESSING = auto() # Processing a message
    PAUSED = auto()     # Temporarily stopped
    STOPPING = auto()   # Shutting down
    STOPPED = auto()    # Fully stopped


@dataclass
class WorkerStats:
    """Worker statistics."""

    worker_id: str
    state: WorkerState = WorkerState.IDLE
    messages_processed: int = 0
    messages_failed: int = 0
    messages_retried: int = 0
    current_message: Optional[str] = None
    started_at: Optional[datetime] = None
    last_heartbeat: Optional[datetime] = None
    avg_processing_time_ms: float = 0.0
    total_processing_time_ms: float = 0.0


class Worker:
    """Message processing worker.

    Consumes messages from queues and processes them.

    Features:
    - Graceful shutdown
    - Heartbeat monitoring
    - Processing timeout
    - Error handling with retry
    - Statistics tracking
    """

    def __init__(
        self,
        worker_id: Optional[str] = None,
        handler: Optional[Callable[[Message], Any]] = None,
        prefetch: int = 1,
        timeout_seconds: int = 30,
    ):
        """Initialize worker.

        Args:
            worker_id: Unique worker identifier
            handler: Message handler function
            prefetch: Number of messages to prefetch
            timeout_seconds: Processing timeout
        """
        self.worker_id = worker_id or f"worker-{uuid.uuid4().hex[:8]}"
        self.handler = handler
        self.prefetch = prefetch
        self.timeout = timeout_seconds

        self._state = WorkerState.STOPPED
        self._thread: Optional[threading.Thread] = None
        self._lock = threading.RLock()
        self._current_message: Optional[Message] = None
        self._stop_event = threading.Event()

        self._stats = WorkerStats(worker_id=self.worker_id)
        self._processing_times: List[float] = []

        # Callbacks
        self._on_start: Optional[Callable[["Worker"], None]] = None
        self._on_stop: Optional[Callable[["Worker"], None]] = None
        self._on_error: Optional[Callable[["Worker", Exception], None]] = None

    @property
    def state(self) -> WorkerState:
        """Get worker state."""
        return self._state

    def set_handler(self, handler: Callable[[Message], Any]) -> "Worker":
        """Set message handler."""
        self.handler = handler
        return self

    def on_start(self, callback: Callable[["Worker"], None]) -> "Worker":
        """Set start callback."""
        self._on_start = callback
        return self

    def on_stop(self, callback: Callable[["Worker"], None]) -> "Worker":
        """Set stop callback."""
        self._on_stop = callback
        return self

    def on_error(self, callback: Callable[["Worker", Exception], None]) -> "Worker":
        """Set error callback."""
        self._on_error = callback
        return self

    def start(self) -> None:
        """Start the worker."""
        with self._lock:
            if self._state != WorkerState.STOPPED:
                return

            self._state = WorkerState.IDLE
            self._stats.started_at = datetime.now()
            self._stop_event.clear()

            if self._on_start:
                self._on_start(self)

            logger.info(f"Worker {self.worker_id} started")

    def stop(self, graceful: bool = True, timeout: float = 30.0) -> None:
        """Stop the worker.

        Args:
            graceful: Wait for current message to complete
            timeout: Maximum time to wait
        """
        with self._lock:
            if self._state == WorkerState.STOPPED:
                return

            self._state = WorkerState.STOPPING
            self._stop_event.set()

            if graceful and self._current_message:
                # Wait for current message
                start = time.time()
                while self._current_message and (time.time() - start) < timeout:
                    time.sleep(0.1)

            self._state = WorkerState.STOPPED

            if self._on_stop:
                self._on_stop(self)

            logger.info(f"Worker {self.worker_id} stopped")

    def pause(self) -> None:
        """Pause the worker."""
        with self._lock:
            if self._state == WorkerState.IDLE:
                self._state = WorkerState.PAUSED
                logger.info(f"Worker {self.worker_id} paused")

    def resume(self) -> None:
        """Resume the worker."""
        with self._lock:
            if self._state == WorkerState.PAUSED:
                self._state = WorkerState.IDLE
                logger.info(f"Worker {self.worker_id} resumed")

    def process(self, message: Message) -> bool:
        """Process a message.

        Args:
            message: Message to process

        Returns:
            True if processed successfully
        """
        if self._state not in (WorkerState.IDLE, WorkerState.PROCESSING):
            return False

        if not self.handler:
            logger.error(f"Worker {self.worker_id} has no handler")
            return False

        with self._lock:
            self._state = WorkerState.PROCESSING
            self._current_message = message
            self._stats.current_message = message.id

        start_time = time.time()
        success = False

        try:
            message.state = MessageState.PROCESSING
            message.metadata.started_at = datetime.now()
            message.metadata.worker_id = self.worker_id

            # Execute handler with timeout
            result = self._execute_with_timeout(message)

            message.ack()
            success = True
            self._stats.messages_processed += 1

        except TimeoutError as e:
            logger.error(f"Worker {self.worker_id} timeout processing {message.id}")
            message.nack(error=str(e))
            self._stats.messages_failed += 1

            if self._on_error:
                self._on_error(self, e)

        except Exception as e:
            logger.error(f"Worker {self.worker_id} error processing {message.id}: {e}")
            message.nack(error=str(e))
            self._stats.messages_failed += 1

            if self._on_error:
                self._on_error(self, e)

        finally:
            elapsed_ms = (time.time() - start_time) * 1000
            self._processing_times.append(elapsed_ms)
            self._stats.total_processing_time_ms += elapsed_ms

            # Calculate average (keep last 100)
            if len(self._processing_times) > 100:
                self._processing_times = self._processing_times[-100:]
            self._stats.avg_processing_time_ms = sum(self._processing_times) / len(
                self._processing_times
            )

            with self._lock:
                self._current_message = None
                self._stats.current_message = None
                if self._state == WorkerState.PROCESSING:
                    self._state = WorkerState.IDLE

        return success

    def _execute_with_timeout(self, message: Message) -> Any:
        """Execute handler with timeout."""
        result = [None]
        error = [None]

        def target():
            try:
                result[0] = self.handler(message)
            except Exception as e:
                error[0] = e

        thread = threading.Thread(target=target)
        thread.start()
        thread.join(timeout=self.timeout)

        if thread.is_alive():
            raise TimeoutError(f"Processing timeout after {self.timeout}s")

        if error[0]:
            raise error[0]

        return result[0]

    def heartbeat(self) -> None:
        """Record heartbeat."""
        self._stats.last_heartbeat = datetime.now()

    def get_stats(self) -> WorkerStats:
        """Get worker statistics."""
        self._stats.state = self._state
        return self._stats

    def __repr__(self) -> str:
        return f"Worker(id={self.worker_id!r}, state={self._state.name})"


class WorkerBuilder:
    """Fluent builder for workers."""

    def __init__(self, worker_id: Optional[str] = None):
        self._worker_id = worker_id
        self._handler: Optional[Callable[[Message], Any]] = None
        self._prefetch = 1
        self._timeout = 30
        self._on_start: Optional[Callable] = None
        self._on_stop: Optional[Callable] = None
        self._on_error: Optional[Callable] = None

    def handler(self, handler: Callable[[Message], Any]) -> "WorkerBuilder":
        """Set message handler."""
        self._handler = handler
        return self

    def prefetch(self, count: int) -> "WorkerBuilder":
        """Set prefetch count."""
        self._prefetch = count
        return self

    def timeout(self, seconds: int) -> "WorkerBuilder":
        """Set processing timeout."""
        self._timeout = seconds
        return self

    def on_start(self, callback: Callable) -> "WorkerBuilder":
        """Set start callback."""
        self._on_start = callback
        return self

    def on_stop(self, callback: Callable) -> "WorkerBuilder":
        """Set stop callback."""
        self._on_stop = callback
        return self

    def on_error(self, callback: Callable) -> "WorkerBuilder":
        """Set error callback."""
        self._on_error = callback
        return self

    def build(self) -> Worker:
        """Build the worker."""
        worker = Worker(
            worker_id=self._worker_id,
            handler=self._handler,
            prefetch=self._prefetch,
            timeout_seconds=self._timeout,
        )
        if self._on_start:
            worker.on_start(self._on_start)
        if self._on_stop:
            worker.on_stop(self._on_stop)
        if self._on_error:
            worker.on_error(self._on_error)
        return worker


__all__ = ["Worker", "WorkerState", "WorkerStats", "WorkerBuilder"]

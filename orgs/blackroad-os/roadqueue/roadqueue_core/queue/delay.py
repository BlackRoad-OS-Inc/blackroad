"""RoadQueue Delay Queue - Delayed Message Delivery.

This module provides a delay queue implementation for scheduling
messages to be delivered at a future time.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import heapq
import logging
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Callable, Dict, List, Optional, Tuple

from roadqueue_core.queue.message import (
    Message,
    MessagePriority,
    MessageState,
)
from roadqueue_core.queue.base import (
    Queue,
    QueueConfig,
    QueueState,
    QueueStats,
)

logger = logging.getLogger(__name__)


@dataclass(order=True)
class DelayedItem:
    """Wrapper for delayed queue items.

    Items are ordered by their scheduled delivery time.
    """

    deliver_at: float = field(compare=True)
    sequence: int = field(compare=True)
    message: Message = field(compare=False)

    @classmethod
    def create(
        cls,
        message: Message,
        sequence: int,
        delay: Optional[timedelta] = None,
    ) -> "DelayedItem":
        """Create a delayed item from a message."""
        if delay:
            deliver_at = time.time() + delay.total_seconds()
        elif message.metadata.scheduled_for:
            deliver_at = message.metadata.scheduled_for.timestamp()
        else:
            deliver_at = time.time()  # Immediate

        return cls(
            deliver_at=deliver_at,
            sequence=sequence,
            message=message,
        )


class DelayQueue(Queue):
    """Delayed message delivery queue.

    Messages are held until their scheduled delivery time.

    Features:
    - Time-based message scheduling
    - Efficient heap-based ordering
    - Background delivery thread
    - Message rescheduling support
    """

    def __init__(
        self,
        config: Optional[QueueConfig] = None,
        name: Optional[str] = None,
        check_interval_ms: int = 100,
    ):
        """Initialize delay queue.

        Args:
            config: Queue configuration
            name: Queue name
            check_interval_ms: Interval to check for ready messages
        """
        super().__init__(config=config, name=name)

        self._delay_heap: List[DelayedItem] = []
        self._sequence: int = 0
        self._check_interval = check_interval_ms / 1000.0
        self._delivery_thread: Optional[threading.Thread] = None
        self._running = False

        # Override parent queue
        self._messages = None

    def start(self) -> None:
        """Start the delivery thread."""
        if self._running:
            return

        self._running = True
        self._state = QueueState.RUNNING
        self._delivery_thread = threading.Thread(
            target=self._delivery_loop,
            daemon=True,
            name=f"DelayQueue-{self.name}",
        )
        self._delivery_thread.start()
        logger.info(f"Delay queue {self.name} started")

    def stop(self) -> None:
        """Stop the delivery thread."""
        self._running = False
        self._state = QueueState.STOPPED
        if self._delivery_thread:
            self._delivery_thread.join(timeout=5.0)
            self._delivery_thread = None
        logger.info(f"Delay queue {self.name} stopped")

    def _delivery_loop(self) -> None:
        """Background loop to deliver ready messages."""
        while self._running:
            self._process_ready_messages()
            time.sleep(self._check_interval)

    def _process_ready_messages(self) -> None:
        """Process messages that are ready for delivery."""
        now = time.time()

        with self._lock:
            while self._delay_heap:
                # Peek at the next item
                item = self._delay_heap[0]

                if item.deliver_at > now:
                    break  # Not ready yet

                # Pop the item
                heapq.heappop(self._delay_heap)
                message = item.message

                # Check if expired
                if message.is_expired():
                    message.state = MessageState.EXPIRED
                    self._send_to_dlq(message)
                    continue

                # Mark as ready for delivery
                message.state = MessageState.PENDING
                message.metadata.scheduled_for = None

                # Try to deliver to a consumer
                self._deliver_message(message)

    def _deliver_message(self, message: Message) -> bool:
        """Deliver a message to a consumer."""
        if not self._consumers:
            # No consumers, buffer the message
            self._ready_messages.append(message)
            return False

        # Round-robin to consumers
        for _ in range(len(self._consumers)):
            if not self._consumer_round_robin:
                break

            self._consumer_index = self._consumer_index % len(
                self._consumer_round_robin
            )
            consumer_id = self._consumer_round_robin[self._consumer_index]
            self._consumer_index += 1

            consumer = self._consumers.get(consumer_id)
            if consumer and consumer.can_receive():
                if consumer.deliver(message):
                    self._deliver_count += 1
                    return True

        # Couldn't deliver, buffer the message
        self._ready_messages.append(message)
        return False

    def publish(
        self,
        message: Message,
        delay: Optional[timedelta] = None,
    ) -> bool:
        """Publish a message with optional delay.

        Args:
            message: Message to publish
            delay: Delay before delivery

        Returns:
            True if message was published successfully
        """
        if self._state not in (QueueState.RUNNING,):
            logger.warning(f"Queue {self.name} not accepting messages")
            return False

        if self.config.max_size > 0 and len(self._delay_heap) >= self.config.max_size:
            logger.warning(f"Queue {self.name} is full")
            return False

        with self._lock:
            if self.config.message_ttl and not message.headers.expiration:
                message.headers.expiration = self.config.message_ttl

            message.queue_name = self.name
            message.metadata.enqueued_at = datetime.now()
            message.metadata.max_retries = self.config.max_retries

            if delay:
                message.state = MessageState.SCHEDULED
                message.metadata.scheduled_for = datetime.now() + delay

            item = DelayedItem.create(message, self._sequence, delay)
            self._sequence += 1
            heapq.heappush(self._delay_heap, item)

            self._publish_count += 1
            self._stats.last_activity = datetime.now()

        logger.debug(
            f"Published delayed message {message.id}, "
            f"delivers at {datetime.fromtimestamp(item.deliver_at)}"
        )

        return True

    def schedule(
        self,
        message: Message,
        deliver_at: datetime,
    ) -> bool:
        """Schedule a message for delivery at a specific time.

        Args:
            message: Message to schedule
            deliver_at: When to deliver the message

        Returns:
            True if message was scheduled successfully
        """
        delay = deliver_at - datetime.now()
        if delay.total_seconds() < 0:
            delay = timedelta(seconds=0)

        return self.publish(message, delay=delay)

    def reschedule(
        self,
        message_id: str,
        new_delay: timedelta,
    ) -> bool:
        """Reschedule a delayed message.

        Args:
            message_id: ID of message to reschedule
            new_delay: New delay from now

        Returns:
            True if message was rescheduled
        """
        with self._lock:
            # Find and remove the message
            new_heap = []
            found_message = None

            for item in self._delay_heap:
                if item.message.id == message_id:
                    found_message = item.message
                else:
                    new_heap.append(item)

            if not found_message:
                return False

            # Reschedule
            heapq.heapify(new_heap)
            self._delay_heap = new_heap

            found_message.metadata.scheduled_for = datetime.now() + new_delay
            new_item = DelayedItem.create(found_message, self._sequence, new_delay)
            self._sequence += 1
            heapq.heappush(self._delay_heap, new_item)

            logger.debug(f"Rescheduled message {message_id} with delay {new_delay}")
            return True

    def cancel(self, message_id: str) -> bool:
        """Cancel a delayed message.

        Args:
            message_id: ID of message to cancel

        Returns:
            True if message was cancelled
        """
        with self._lock:
            new_heap = []
            found = False

            for item in self._delay_heap:
                if item.message.id == message_id:
                    item.message.state = MessageState.CANCELLED
                    found = True
                else:
                    new_heap.append(item)

            if found:
                heapq.heapify(new_heap)
                self._delay_heap = new_heap
                logger.debug(f"Cancelled delayed message {message_id}")

            return found

    def get_scheduled(self, limit: int = 100) -> List[Tuple[Message, datetime]]:
        """Get list of scheduled messages.

        Args:
            limit: Maximum messages to return

        Returns:
            List of (message, scheduled_time) tuples
        """
        with self._lock:
            items = heapq.nsmallest(limit, self._delay_heap)
            return [
                (item.message, datetime.fromtimestamp(item.deliver_at))
                for item in items
            ]

    def get_ready_count(self) -> int:
        """Get count of messages ready for delivery."""
        now = time.time()
        with self._lock:
            return sum(1 for item in self._delay_heap if item.deliver_at <= now)

    def get(self, timeout: Optional[float] = None) -> Optional[Message]:
        """Get a ready message.

        Args:
            timeout: Maximum time to wait in seconds

        Returns:
            Message or None if timeout
        """
        start = time.time()
        while True:
            now = time.time()

            with self._lock:
                if self._delay_heap:
                    item = self._delay_heap[0]

                    if item.deliver_at <= now:
                        heapq.heappop(self._delay_heap)
                        message = item.message

                        if message.is_expired():
                            message.state = MessageState.EXPIRED
                            self._send_to_dlq(message)
                            continue

                        message.state = MessageState.PROCESSING
                        message.metadata.started_at = datetime.now()
                        self._deliver_count += 1
                        return message

            if timeout is not None:
                if time.time() - start >= timeout:
                    return None
                time.sleep(min(0.1, timeout))
            else:
                time.sleep(0.1)

    def peek(self, count: int = 1) -> List[Message]:
        """Peek at next scheduled messages.

        Args:
            count: Number of messages to peek

        Returns:
            List of messages in delivery order
        """
        with self._lock:
            items = heapq.nsmallest(count, self._delay_heap)
            return [item.message for item in items]

    def purge(self) -> int:
        """Remove all messages from the queue.

        Returns:
            Number of messages purged
        """
        with self._lock:
            count = len(self._delay_heap)
            self._delay_heap.clear()
            logger.info(f"Purged {count} messages from delay queue {self.name}")
            return count

    def get_stats(self) -> QueueStats:
        """Get queue statistics."""
        now = time.time()
        elapsed = now - self._rate_window_start

        if elapsed > 0:
            publish_rate = self._publish_count / elapsed
            deliver_rate = self._deliver_count / elapsed
            ack_rate = self._ack_count / elapsed
        else:
            publish_rate = deliver_rate = ack_rate = 0.0

        if elapsed > 60:
            self._publish_count = 0
            self._deliver_count = 0
            self._ack_count = 0
            self._rate_window_start = now

        with self._lock:
            unacked = sum(len(c.unacked) for c in self._consumers.values())
            ready = sum(1 for item in self._delay_heap if item.deliver_at <= now)

            return QueueStats(
                messages_ready=ready,
                messages_unacked=unacked,
                messages_total=len(self._delay_heap) + unacked,
                consumers=len(self._consumers),
                publish_rate=publish_rate,
                deliver_rate=deliver_rate,
                ack_rate=ack_rate,
                created_at=self._stats.created_at,
                last_activity=self._stats.last_activity,
            )

    def __len__(self) -> int:
        """Get queue length."""
        return len(self._delay_heap)

    def __repr__(self) -> str:
        return f"DelayQueue(name={self.name!r}, messages={len(self._delay_heap)}, state={self._state.name})"

    def __enter__(self) -> "DelayQueue":
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.stop()


class ScheduledJob:
    """A scheduled recurring job."""

    def __init__(
        self,
        job_id: str,
        task: Callable[[], Any],
        interval: timedelta,
        start_at: Optional[datetime] = None,
        end_at: Optional[datetime] = None,
        max_runs: Optional[int] = None,
    ):
        self.job_id = job_id
        self.task = task
        self.interval = interval
        self.start_at = start_at or datetime.now()
        self.end_at = end_at
        self.max_runs = max_runs

        self.run_count = 0
        self.last_run: Optional[datetime] = None
        self.next_run: datetime = self.start_at
        self.active = True

    def should_run(self) -> bool:
        """Check if job should run now."""
        if not self.active:
            return False

        now = datetime.now()

        if now < self.next_run:
            return False

        if self.end_at and now > self.end_at:
            self.active = False
            return False

        if self.max_runs and self.run_count >= self.max_runs:
            self.active = False
            return False

        return True

    def run(self) -> Any:
        """Execute the job."""
        result = self.task()
        self.run_count += 1
        self.last_run = datetime.now()
        self.next_run = self.last_run + self.interval
        return result


class JobScheduler:
    """Simple job scheduler for recurring tasks."""

    def __init__(self, check_interval_ms: int = 1000):
        self._jobs: Dict[str, ScheduledJob] = {}
        self._check_interval = check_interval_ms / 1000.0
        self._thread: Optional[threading.Thread] = None
        self._running = False
        self._lock = threading.Lock()

    def add_job(self, job: ScheduledJob) -> None:
        """Add a scheduled job."""
        with self._lock:
            self._jobs[job.job_id] = job
            logger.info(f"Added job {job.job_id}")

    def remove_job(self, job_id: str) -> bool:
        """Remove a scheduled job."""
        with self._lock:
            if job_id in self._jobs:
                del self._jobs[job_id]
                logger.info(f"Removed job {job_id}")
                return True
            return False

    def start(self) -> None:
        """Start the scheduler."""
        if self._running:
            return

        self._running = True
        self._thread = threading.Thread(
            target=self._scheduler_loop,
            daemon=True,
            name="JobScheduler",
        )
        self._thread.start()
        logger.info("Job scheduler started")

    def stop(self) -> None:
        """Stop the scheduler."""
        self._running = False
        if self._thread:
            self._thread.join(timeout=5.0)
            self._thread = None
        logger.info("Job scheduler stopped")

    def _scheduler_loop(self) -> None:
        """Background scheduler loop."""
        while self._running:
            with self._lock:
                for job in list(self._jobs.values()):
                    if job.should_run():
                        try:
                            job.run()
                            logger.debug(f"Executed job {job.job_id}")
                        except Exception as e:
                            logger.error(f"Job {job.job_id} failed: {e}")

            time.sleep(self._check_interval)

    def __enter__(self) -> "JobScheduler":
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.stop()


__all__ = [
    "DelayQueue",
    "DelayedItem",
    "ScheduledJob",
    "JobScheduler",
]

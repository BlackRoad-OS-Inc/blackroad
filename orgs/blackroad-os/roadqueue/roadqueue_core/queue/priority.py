"""RoadQueue Priority Queue - Multi-Level Priority Queue.

This module provides a priority queue implementation with multiple
priority levels and fair scheduling.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import heapq
import logging
import threading
import time
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Callable, Dict, List, Optional, Tuple

from roadqueue_core.queue.message import (
    Message,
    MessagePriority,
    MessageState,
)
from roadqueue_core.queue.base import (
    Consumer,
    Queue,
    QueueConfig,
    QueueState,
    QueueStats,
)

logger = logging.getLogger(__name__)


@dataclass(order=True)
class PriorityItem:
    """Wrapper for priority queue items.

    Uses negative priority for max-heap behavior with heapq.
    """

    priority: int = field(compare=True)
    timestamp: float = field(compare=True)
    sequence: int = field(compare=True)
    message: Message = field(compare=False)

    @classmethod
    def create(cls, message: Message, sequence: int) -> "PriorityItem":
        """Create a priority item from a message."""
        return cls(
            priority=-message.priority.value,  # Negative for max-heap
            timestamp=time.time(),
            sequence=sequence,
            message=message,
        )


class PriorityQueue(Queue):
    """Multi-level priority queue.

    Messages are delivered based on priority level.
    Higher priority messages are delivered first.

    Features:
    - Multiple priority levels (LOWEST to CRITICAL)
    - Fair scheduling within priority levels
    - Starvation prevention
    - Priority boosting for aged messages
    """

    def __init__(
        self,
        config: Optional[QueueConfig] = None,
        name: Optional[str] = None,
        boost_age_seconds: int = 60,
        boost_levels: int = 1,
    ):
        """Initialize priority queue.

        Args:
            config: Queue configuration
            name: Queue name
            boost_age_seconds: Seconds before priority boost
            boost_levels: Priority levels to boost
        """
        super().__init__(config=config, name=name)

        self._heap: List[PriorityItem] = []
        self._sequence: int = 0
        self._priority_counts: Dict[MessagePriority, int] = defaultdict(int)
        self._boost_age = boost_age_seconds
        self._boost_levels = boost_levels

        # Override parent queue with heap
        self._messages = None  # Disable parent queue

    def publish(self, message: Message) -> bool:
        """Publish a message to the priority queue.

        Args:
            message: Message to publish

        Returns:
            True if message was published successfully
        """
        if self._state not in (QueueState.RUNNING,):
            logger.warning(f"Queue {self.name} not accepting messages")
            return False

        # Check size limit
        if self.config.max_size > 0 and len(self._heap) >= self.config.max_size:
            logger.warning(f"Queue {self.name} is full")
            return False

        with self._lock:
            # Apply default TTL if not set
            if self.config.message_ttl and not message.headers.expiration:
                message.headers.expiration = self.config.message_ttl

            # Set queue name
            message.queue_name = self.name
            message.metadata.enqueued_at = datetime.now()
            message.metadata.max_retries = self.config.max_retries

            # Add to priority heap
            item = PriorityItem.create(message, self._sequence)
            self._sequence += 1
            heapq.heappush(self._heap, item)
            self._priority_counts[message.priority] += 1

            self._publish_count += 1
            self._stats.last_activity = datetime.now()

        logger.debug(
            f"Published message {message.id} with priority {message.priority.name}"
        )

        # Try to deliver immediately
        self._try_deliver()

        return True

    def _try_deliver(self) -> None:
        """Try to deliver messages to consumers."""
        if self._state not in (QueueState.RUNNING, QueueState.DRAINING):
            return

        with self._lock:
            if not self._heap or not self._consumers:
                return

            # Apply priority boosting
            self._boost_aged_messages()

            # Round-robin delivery
            delivered = 0
            max_attempts = len(self._consumers) * 2

            while self._heap and delivered < max_attempts:
                # Get next consumer
                if not self._consumer_round_robin:
                    break

                self._consumer_index = self._consumer_index % len(
                    self._consumer_round_robin
                )
                consumer_id = self._consumer_round_robin[self._consumer_index]
                self._consumer_index += 1

                consumer = self._consumers.get(consumer_id)
                if not consumer or not consumer.can_receive():
                    delivered += 1
                    continue

                # Get highest priority message
                item = heapq.heappop(self._heap)
                message = item.message

                # Check if expired
                if message.is_expired():
                    message.state = MessageState.EXPIRED
                    self._priority_counts[message.priority] -= 1
                    self._send_to_dlq(message)
                    continue

                # Check if ready (for delayed messages)
                if not message.is_ready():
                    heapq.heappush(self._heap, item)
                    delivered += 1
                    continue

                # Deliver to consumer
                self._priority_counts[message.priority] -= 1
                if consumer.deliver(message):
                    self._deliver_count += 1
                else:
                    # Failed delivery, put back
                    heapq.heappush(self._heap, item)
                    self._priority_counts[message.priority] += 1

                delivered += 1

    def _boost_aged_messages(self) -> None:
        """Boost priority of aged messages to prevent starvation."""
        if not self._boost_age or not self._boost_levels:
            return

        now = time.time()
        boosted = []

        # Check all messages for aging
        new_heap = []
        for item in self._heap:
            age = now - item.timestamp
            if age > self._boost_age:
                # Boost priority
                old_priority = item.message.priority
                new_priority_value = min(
                    MessagePriority.CRITICAL.value,
                    old_priority.value + self._boost_levels,
                )
                new_priority = MessagePriority(new_priority_value)

                if new_priority != old_priority:
                    item.message.priority = new_priority
                    item.priority = -new_priority.value
                    self._priority_counts[old_priority] -= 1
                    self._priority_counts[new_priority] += 1
                    boosted.append(item.message.id)

            new_heap.append(item)

        if boosted:
            heapq.heapify(new_heap)
            self._heap = new_heap
            logger.debug(f"Boosted priority for {len(boosted)} aged messages")

    def nack(
        self,
        message_id: str,
        consumer_id: str,
        requeue: bool = True,
    ) -> bool:
        """Negative acknowledge a message.

        Args:
            message_id: Message ID
            consumer_id: Consumer ID
            requeue: Whether to requeue the message

        Returns:
            True if message was nacked
        """
        with self._lock:
            if consumer_id not in self._consumers:
                return False

            consumer = self._consumers[consumer_id]
            message = consumer.nack(message_id, requeue=requeue)

            if message:
                if message.can_retry():
                    # Requeue with same priority
                    item = PriorityItem.create(message, self._sequence)
                    self._sequence += 1
                    heapq.heappush(self._heap, item)
                    self._priority_counts[message.priority] += 1
                else:
                    self._send_to_dlq(message)

            self._try_deliver()
            return True

        return False

    def get(self, timeout: Optional[float] = None) -> Optional[Message]:
        """Get the highest priority message.

        Args:
            timeout: Maximum time to wait in seconds

        Returns:
            Message or None if timeout
        """
        start = time.time()
        while True:
            with self._lock:
                if self._heap:
                    # Apply priority boosting
                    self._boost_aged_messages()

                    item = heapq.heappop(self._heap)
                    message = item.message

                    if message.is_expired():
                        message.state = MessageState.EXPIRED
                        self._priority_counts[message.priority] -= 1
                        self._send_to_dlq(message)
                        continue

                    if message.is_ready():
                        self._priority_counts[message.priority] -= 1
                        message.state = MessageState.PROCESSING
                        message.metadata.started_at = datetime.now()
                        self._deliver_count += 1
                        return message
                    else:
                        heapq.heappush(self._heap, item)

            if timeout is not None:
                if time.time() - start >= timeout:
                    return None
                time.sleep(min(0.1, timeout))
            else:
                time.sleep(0.1)

    def peek(self, count: int = 1) -> List[Message]:
        """Peek at highest priority messages.

        Args:
            count: Number of messages to peek

        Returns:
            List of messages in priority order
        """
        with self._lock:
            # Get top N from heap without removing
            items = heapq.nsmallest(count, self._heap)
            return [item.message for item in items]

    def purge(self) -> int:
        """Remove all messages from the queue.

        Returns:
            Number of messages purged
        """
        with self._lock:
            count = len(self._heap)
            self._heap.clear()
            self._priority_counts.clear()
            logger.info(f"Purged {count} messages from priority queue {self.name}")
            return count

    def get_priority_stats(self) -> Dict[str, int]:
        """Get message counts by priority level."""
        with self._lock:
            return {
                priority.name: self._priority_counts.get(priority, 0)
                for priority in MessagePriority
            }

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

        # Reset counters periodically
        if elapsed > 60:
            self._publish_count = 0
            self._deliver_count = 0
            self._ack_count = 0
            self._rate_window_start = now

        with self._lock:
            unacked = sum(len(c.unacked) for c in self._consumers.values())
            return QueueStats(
                messages_ready=len(self._heap),
                messages_unacked=unacked,
                messages_total=len(self._heap) + unacked,
                consumers=len(self._consumers),
                publish_rate=publish_rate,
                deliver_rate=deliver_rate,
                ack_rate=ack_rate,
                created_at=self._stats.created_at,
                last_activity=self._stats.last_activity,
            )

    def __len__(self) -> int:
        """Get queue length."""
        return len(self._heap)

    def __repr__(self) -> str:
        return f"PriorityQueue(name={self.name!r}, messages={len(self._heap)}, state={self._state.name})"


class FairPriorityQueue(PriorityQueue):
    """Fair priority queue with weighted scheduling.

    Prevents starvation by allocating a percentage of deliveries
    to each priority level.

    Example weights:
    - CRITICAL: 40% of deliveries
    - HIGHEST: 25% of deliveries
    - HIGH: 15% of deliveries
    - NORMAL: 10% of deliveries
    - LOW: 7% of deliveries
    - LOWEST: 3% of deliveries
    """

    DEFAULT_WEIGHTS = {
        MessagePriority.CRITICAL: 40,
        MessagePriority.HIGHEST: 25,
        MessagePriority.HIGH: 15,
        MessagePriority.NORMAL: 10,
        MessagePriority.LOW: 7,
        MessagePriority.LOWEST: 3,
    }

    def __init__(
        self,
        config: Optional[QueueConfig] = None,
        name: Optional[str] = None,
        weights: Optional[Dict[MessagePriority, int]] = None,
    ):
        """Initialize fair priority queue.

        Args:
            config: Queue configuration
            name: Queue name
            weights: Priority level weights (percentages)
        """
        super().__init__(config=config, name=name)

        self._weights = weights or self.DEFAULT_WEIGHTS
        self._priority_queues: Dict[MessagePriority, List[PriorityItem]] = {
            p: [] for p in MessagePriority
        }
        self._delivery_counts: Dict[MessagePriority, int] = defaultdict(int)
        self._delivery_window = 100  # Messages per scheduling window

    def publish(self, message: Message) -> bool:
        """Publish a message to the fair priority queue."""
        if self._state not in (QueueState.RUNNING,):
            logger.warning(f"Queue {self.name} not accepting messages")
            return False

        total_messages = sum(len(q) for q in self._priority_queues.values())
        if self.config.max_size > 0 and total_messages >= self.config.max_size:
            logger.warning(f"Queue {self.name} is full")
            return False

        with self._lock:
            if self.config.message_ttl and not message.headers.expiration:
                message.headers.expiration = self.config.message_ttl

            message.queue_name = self.name
            message.metadata.enqueued_at = datetime.now()
            message.metadata.max_retries = self.config.max_retries

            item = PriorityItem.create(message, self._sequence)
            self._sequence += 1

            # Add to priority-specific queue
            heapq.heappush(self._priority_queues[message.priority], item)
            self._priority_counts[message.priority] += 1

            self._publish_count += 1
            self._stats.last_activity = datetime.now()

        logger.debug(
            f"Published message {message.id} with priority {message.priority.name}"
        )

        self._try_deliver()
        return True

    def _get_next_message(self) -> Optional[Message]:
        """Get next message based on fair scheduling."""
        # Calculate current delivery ratios
        total_deliveries = sum(self._delivery_counts.values()) or 1

        # Find priority level that is under its quota
        for priority in MessagePriority:
            weight = self._weights.get(priority, 10)
            target_ratio = weight / 100
            current_ratio = self._delivery_counts[priority] / total_deliveries

            if current_ratio < target_ratio:
                queue = self._priority_queues[priority]
                if queue:
                    item = heapq.heappop(queue)
                    self._delivery_counts[priority] += 1
                    self._priority_counts[priority] -= 1

                    # Reset window periodically
                    if total_deliveries >= self._delivery_window:
                        self._delivery_counts = defaultdict(int)

                    return item.message

        # Fallback to highest priority available
        for priority in reversed(MessagePriority):
            queue = self._priority_queues[priority]
            if queue:
                item = heapq.heappop(queue)
                self._delivery_counts[priority] += 1
                self._priority_counts[priority] -= 1
                return item.message

        return None

    def get(self, timeout: Optional[float] = None) -> Optional[Message]:
        """Get the next message based on fair scheduling."""
        start = time.time()
        while True:
            with self._lock:
                message = self._get_next_message()
                if message:
                    if message.is_expired():
                        message.state = MessageState.EXPIRED
                        self._send_to_dlq(message)
                        continue

                    if message.is_ready():
                        message.state = MessageState.PROCESSING
                        message.metadata.started_at = datetime.now()
                        self._deliver_count += 1
                        return message
                    else:
                        # Put back for later
                        item = PriorityItem.create(message, self._sequence)
                        self._sequence += 1
                        heapq.heappush(
                            self._priority_queues[message.priority], item
                        )
                        self._priority_counts[message.priority] += 1

            if timeout is not None:
                if time.time() - start >= timeout:
                    return None
                time.sleep(min(0.1, timeout))
            else:
                time.sleep(0.1)

    def __len__(self) -> int:
        """Get total queue length."""
        return sum(len(q) for q in self._priority_queues.values())


__all__ = [
    "PriorityQueue",
    "FairPriorityQueue",
    "PriorityItem",
]

"""RoadQueue Base Queue - Core Queue Implementation.

This module provides the foundational queue implementation with
FIFO ordering, persistence, and acknowledgment support.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
from abc import ABC, abstractmethod
from collections import deque
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Deque, Dict, Iterator, List, Optional, Set

from roadqueue_core.queue.message import (
    Message,
    MessageBatch,
    MessagePriority,
    MessageState,
)

logger = logging.getLogger(__name__)


class QueueState(Enum):
    """Queue operational states."""

    RUNNING = auto()     # Normal operation
    PAUSED = auto()      # Temporarily stopped
    DRAINING = auto()    # Accepting no new messages, processing existing
    STOPPED = auto()     # Fully stopped


@dataclass
class QueueConfig:
    """Queue configuration.

    Attributes:
        name: Queue name
        max_size: Maximum queue size (0 = unlimited)
        max_consumers: Maximum concurrent consumers
        message_ttl: Default message TTL in milliseconds
        dead_letter_queue: Name of dead letter queue
        max_retries: Maximum retry attempts
        ack_timeout: Acknowledgment timeout in seconds
        prefetch_count: Messages to prefetch per consumer
        durable: Persist queue to storage
        exclusive: Only one consumer allowed
        auto_delete: Delete when last consumer disconnects
    """

    name: str
    max_size: int = 0
    max_consumers: int = 0
    message_ttl: Optional[int] = None
    dead_letter_queue: Optional[str] = None
    max_retries: int = 3
    ack_timeout: int = 30
    prefetch_count: int = 1
    durable: bool = True
    exclusive: bool = False
    auto_delete: bool = False

    def __post_init__(self):
        if not self.name:
            raise ValueError("Queue name is required")


@dataclass
class QueueStats:
    """Queue statistics.

    Attributes:
        messages_ready: Messages ready for delivery
        messages_unacked: Messages delivered but not acknowledged
        messages_total: Total messages in queue
        consumers: Number of active consumers
        publish_rate: Messages published per second
        deliver_rate: Messages delivered per second
        ack_rate: Messages acknowledged per second
    """

    messages_ready: int = 0
    messages_unacked: int = 0
    messages_total: int = 0
    consumers: int = 0
    publish_rate: float = 0.0
    deliver_rate: float = 0.0
    ack_rate: float = 0.0
    created_at: datetime = field(default_factory=datetime.now)
    last_activity: Optional[datetime] = None


class Consumer:
    """Queue consumer.

    Represents a consumer attached to a queue.
    """

    def __init__(
        self,
        consumer_id: str,
        callback: Callable[[Message], None],
        prefetch: int = 1,
    ):
        self.consumer_id = consumer_id
        self.callback = callback
        self.prefetch = prefetch
        self.active = True
        self.unacked: Dict[str, Message] = {}
        self.last_activity: datetime = datetime.now()
        self._lock = threading.Lock()

    def can_receive(self) -> bool:
        """Check if consumer can receive more messages."""
        return self.active and len(self.unacked) < self.prefetch

    def deliver(self, message: Message) -> bool:
        """Deliver a message to this consumer.

        Returns:
            True if delivery successful
        """
        if not self.can_receive():
            return False

        with self._lock:
            message.state = MessageState.PROCESSING
            message.metadata.started_at = datetime.now()
            message.metadata.worker_id = self.consumer_id
            self.unacked[message.id] = message
            self.last_activity = datetime.now()

        try:
            self.callback(message)
            return True
        except Exception as e:
            logger.error(f"Consumer {self.consumer_id} callback failed: {e}")
            return False

    def ack(self, message_id: str) -> bool:
        """Acknowledge a message.

        Returns:
            True if message was unacked and is now acknowledged
        """
        with self._lock:
            if message_id in self.unacked:
                message = self.unacked.pop(message_id)
                message.ack()
                return True
            return False

    def nack(self, message_id: str, requeue: bool = True) -> Optional[Message]:
        """Negative acknowledge a message.

        Returns:
            The message if it should be requeued, None otherwise
        """
        with self._lock:
            if message_id in self.unacked:
                message = self.unacked.pop(message_id)
                message.nack(requeue=requeue)
                if requeue and message.state == MessageState.PENDING:
                    return message
            return None

    def cancel(self) -> List[Message]:
        """Cancel this consumer.

        Returns:
            List of unacknowledged messages
        """
        self.active = False
        with self._lock:
            messages = list(self.unacked.values())
            self.unacked.clear()
            return messages


class Queue:
    """FIFO message queue.

    Provides reliable message queuing with:
    - FIFO ordering
    - Consumer management
    - Message acknowledgment
    - Retry handling
    - Dead letter queue support
    """

    def __init__(
        self,
        config: Optional[QueueConfig] = None,
        name: Optional[str] = None,
    ):
        """Initialize queue.

        Args:
            config: Queue configuration
            name: Queue name (if config not provided)
        """
        if config:
            self.config = config
        elif name:
            self.config = QueueConfig(name=name)
        else:
            raise ValueError("Either config or name must be provided")

        self._messages: Deque[Message] = deque()
        self._consumers: Dict[str, Consumer] = {}
        self._consumer_round_robin: List[str] = []
        self._consumer_index: int = 0
        self._lock = threading.RLock()
        self._state = QueueState.RUNNING
        self._stats = QueueStats()
        self._dedup_cache: Set[str] = set()
        self._dedup_max_size = 10000

        # Rate tracking
        self._publish_count = 0
        self._deliver_count = 0
        self._ack_count = 0
        self._rate_window_start = time.time()

        logger.debug(f"Queue '{self.config.name}' initialized")

    @property
    def name(self) -> str:
        """Get queue name."""
        return self.config.name

    @property
    def state(self) -> QueueState:
        """Get queue state."""
        return self._state

    def publish(self, message: Message) -> bool:
        """Publish a message to the queue.

        Args:
            message: Message to publish

        Returns:
            True if message was published successfully
        """
        if self._state not in (QueueState.RUNNING,):
            logger.warning(f"Queue {self.name} not accepting messages")
            return False

        # Check size limit
        if self.config.max_size > 0 and len(self._messages) >= self.config.max_size:
            logger.warning(f"Queue {self.name} is full")
            return False

        # Deduplication check
        dedup_key = message.get_dedup_key()
        if dedup_key in self._dedup_cache:
            logger.debug(f"Duplicate message rejected: {message.id}")
            return False

        with self._lock:
            # Apply default TTL if not set
            if self.config.message_ttl and not message.headers.expiration:
                message.headers.expiration = self.config.message_ttl

            # Set queue name
            message.queue_name = self.name
            message.metadata.enqueued_at = datetime.now()
            message.metadata.max_retries = self.config.max_retries

            self._messages.append(message)
            self._publish_count += 1
            self._stats.last_activity = datetime.now()

            # Add to dedup cache
            self._dedup_cache.add(dedup_key)
            if len(self._dedup_cache) > self._dedup_max_size:
                # Remove oldest entries
                self._dedup_cache = set(list(self._dedup_cache)[-self._dedup_max_size // 2:])

        logger.debug(f"Published message {message.id} to queue {self.name}")

        # Try to deliver immediately
        self._try_deliver()

        return True

    def publish_batch(self, messages: List[Message]) -> int:
        """Publish multiple messages.

        Args:
            messages: Messages to publish

        Returns:
            Number of messages published
        """
        published = 0
        for message in messages:
            if self.publish(message):
                published += 1
        return published

    def consume(
        self,
        consumer_id: str,
        callback: Callable[[Message], None],
        prefetch: int = 1,
    ) -> bool:
        """Register a consumer.

        Args:
            consumer_id: Unique consumer identifier
            callback: Callback for message delivery
            prefetch: Messages to prefetch

        Returns:
            True if consumer registered successfully
        """
        if self.config.exclusive and len(self._consumers) > 0:
            logger.warning(f"Queue {self.name} is exclusive")
            return False

        if self.config.max_consumers > 0 and len(self._consumers) >= self.config.max_consumers:
            logger.warning(f"Queue {self.name} max consumers reached")
            return False

        with self._lock:
            if consumer_id in self._consumers:
                logger.warning(f"Consumer {consumer_id} already exists")
                return False

            consumer = Consumer(
                consumer_id=consumer_id,
                callback=callback,
                prefetch=prefetch or self.config.prefetch_count,
            )
            self._consumers[consumer_id] = consumer
            self._consumer_round_robin.append(consumer_id)

        logger.info(f"Consumer {consumer_id} registered on queue {self.name}")

        # Deliver pending messages
        self._try_deliver()

        return True

    def cancel_consumer(self, consumer_id: str) -> bool:
        """Cancel a consumer.

        Args:
            consumer_id: Consumer to cancel

        Returns:
            True if consumer was cancelled
        """
        with self._lock:
            if consumer_id not in self._consumers:
                return False

            consumer = self._consumers.pop(consumer_id)
            unacked = consumer.cancel()

            # Requeue unacknowledged messages
            for message in unacked:
                message.state = MessageState.PENDING
                self._messages.appendleft(message)

            if consumer_id in self._consumer_round_robin:
                self._consumer_round_robin.remove(consumer_id)

        logger.info(f"Consumer {consumer_id} cancelled on queue {self.name}")

        # Check auto-delete
        if self.config.auto_delete and len(self._consumers) == 0:
            self.delete()

        return True

    def ack(self, message_id: str, consumer_id: str) -> bool:
        """Acknowledge a message.

        Args:
            message_id: Message ID
            consumer_id: Consumer ID

        Returns:
            True if message was acknowledged
        """
        with self._lock:
            if consumer_id not in self._consumers:
                return False

            consumer = self._consumers[consumer_id]
            if consumer.ack(message_id):
                self._ack_count += 1
                self._stats.last_activity = datetime.now()
                self._try_deliver()
                return True

        return False

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
                    self._messages.appendleft(message)
                else:
                    self._send_to_dlq(message)

            self._try_deliver()
            return True

        return False

    def _try_deliver(self) -> None:
        """Try to deliver messages to consumers."""
        if self._state not in (QueueState.RUNNING, QueueState.DRAINING):
            return

        with self._lock:
            if not self._messages or not self._consumers:
                return

            # Round-robin delivery
            delivered = 0
            max_attempts = len(self._consumers) * 2

            while self._messages and delivered < max_attempts:
                # Get next consumer
                if not self._consumer_round_robin:
                    break

                self._consumer_index = self._consumer_index % len(self._consumer_round_robin)
                consumer_id = self._consumer_round_robin[self._consumer_index]
                self._consumer_index += 1

                consumer = self._consumers.get(consumer_id)
                if not consumer or not consumer.can_receive():
                    delivered += 1
                    continue

                # Get next message
                message = self._messages.popleft()

                # Check if expired
                if message.is_expired():
                    message.state = MessageState.EXPIRED
                    self._send_to_dlq(message)
                    continue

                # Check if ready (for delayed messages)
                if not message.is_ready():
                    self._messages.append(message)
                    delivered += 1
                    continue

                # Deliver to consumer
                if consumer.deliver(message):
                    self._deliver_count += 1
                else:
                    # Failed delivery, put back
                    self._messages.appendleft(message)

                delivered += 1

    def _send_to_dlq(self, message: Message) -> None:
        """Send a message to the dead letter queue."""
        message.state = MessageState.DEAD
        if self.config.dead_letter_queue:
            logger.info(
                f"Message {message.id} sent to DLQ {self.config.dead_letter_queue}"
            )
            # DLQ handling is done by the broker

    def get(self, timeout: Optional[float] = None) -> Optional[Message]:
        """Get a message from the queue.

        Blocking get operation for synchronous consumption.

        Args:
            timeout: Maximum time to wait in seconds

        Returns:
            Message or None if timeout
        """
        start = time.time()
        while True:
            with self._lock:
                if self._messages:
                    for i, message in enumerate(self._messages):
                        if message.is_ready() and not message.is_expired():
                            message = self._messages[i]
                            del self._messages[i]
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
        """Peek at messages without removing them.

        Args:
            count: Number of messages to peek

        Returns:
            List of messages
        """
        with self._lock:
            return list(self._messages)[:count]

    def purge(self) -> int:
        """Remove all messages from the queue.

        Returns:
            Number of messages purged
        """
        with self._lock:
            count = len(self._messages)
            self._messages.clear()
            self._dedup_cache.clear()
            logger.info(f"Purged {count} messages from queue {self.name}")
            return count

    def pause(self) -> None:
        """Pause the queue."""
        self._state = QueueState.PAUSED
        logger.info(f"Queue {self.name} paused")

    def resume(self) -> None:
        """Resume the queue."""
        self._state = QueueState.RUNNING
        logger.info(f"Queue {self.name} resumed")
        self._try_deliver()

    def drain(self) -> None:
        """Drain the queue (stop accepting new messages)."""
        self._state = QueueState.DRAINING
        logger.info(f"Queue {self.name} draining")

    def delete(self) -> None:
        """Delete the queue."""
        self._state = QueueState.STOPPED
        with self._lock:
            self._messages.clear()
            for consumer_id in list(self._consumers.keys()):
                self.cancel_consumer(consumer_id)
        logger.info(f"Queue {self.name} deleted")

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
                messages_ready=len(self._messages),
                messages_unacked=unacked,
                messages_total=len(self._messages) + unacked,
                consumers=len(self._consumers),
                publish_rate=publish_rate,
                deliver_rate=deliver_rate,
                ack_rate=ack_rate,
                created_at=self._stats.created_at,
                last_activity=self._stats.last_activity,
            )

    def __len__(self) -> int:
        """Get queue length."""
        return len(self._messages)

    def __repr__(self) -> str:
        return f"Queue(name={self.name!r}, messages={len(self._messages)}, state={self._state.name})"


class AbstractQueue(ABC):
    """Abstract base class for queue implementations."""

    @abstractmethod
    def publish(self, message: Message) -> bool:
        """Publish a message."""
        pass

    @abstractmethod
    def consume(
        self,
        consumer_id: str,
        callback: Callable[[Message], None],
        prefetch: int = 1,
    ) -> bool:
        """Register a consumer."""
        pass

    @abstractmethod
    def ack(self, message_id: str, consumer_id: str) -> bool:
        """Acknowledge a message."""
        pass

    @abstractmethod
    def nack(
        self,
        message_id: str,
        consumer_id: str,
        requeue: bool = True,
    ) -> bool:
        """Negative acknowledge a message."""
        pass

    @abstractmethod
    def get_stats(self) -> QueueStats:
        """Get queue statistics."""
        pass


__all__ = [
    "Queue",
    "QueueConfig",
    "QueueState",
    "QueueStats",
    "Consumer",
    "AbstractQueue",
]

"""RoadQueue Broker - Central Message Broker.

This module provides the main message broker that coordinates
queues, exchanges, bindings, and message routing.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Tuple

from roadqueue_core.queue.message import Message, MessageState
from roadqueue_core.queue.base import Queue, QueueConfig, QueueState
from roadqueue_core.queue.priority import PriorityQueue
from roadqueue_core.queue.delay import DelayQueue
from roadqueue_core.queue.dlq import DeadLetterQueue, DeadLetterReason
from roadqueue_core.broker.exchange import (
    Exchange,
    ExchangeType,
    ExchangeFactory,
    DirectExchange,
)
from roadqueue_core.broker.binding import Binding, BindingRegistry
from roadqueue_core.broker.router import Router

logger = logging.getLogger(__name__)


class BrokerState(Enum):
    """Broker operational states."""

    STARTING = auto()
    RUNNING = auto()
    PAUSED = auto()
    STOPPING = auto()
    STOPPED = auto()


@dataclass
class BrokerConfig:
    """Broker configuration.

    Attributes:
        name: Broker name/identifier
        default_exchange: Default exchange name
        dead_letter_exchange: Dead letter exchange name
        max_queues: Maximum number of queues
        max_exchanges: Maximum number of exchanges
        message_ttl: Default message TTL
        heartbeat_interval: Heartbeat interval in seconds
        enable_persistence: Enable message persistence
    """

    name: str = "roadqueue"
    default_exchange: str = ""
    dead_letter_exchange: str = "dlx"
    max_queues: int = 1000
    max_exchanges: int = 100
    message_ttl: Optional[int] = None
    heartbeat_interval: int = 60
    enable_persistence: bool = True


@dataclass
class BrokerStats:
    """Broker statistics."""

    state: BrokerState = BrokerState.STOPPED
    queues: int = 0
    exchanges: int = 0
    bindings: int = 0
    messages_published: int = 0
    messages_delivered: int = 0
    messages_acknowledged: int = 0
    messages_dead_lettered: int = 0
    uptime_seconds: float = 0.0
    started_at: Optional[datetime] = None


class Broker:
    """Central message broker.

    Coordinates queues, exchanges, and message routing.

    Features:
    - Queue management (create, delete, purge)
    - Exchange management (direct, topic, fanout, headers)
    - Binding management
    - Message publishing and routing
    - Dead letter handling
    - Statistics and monitoring
    """

    def __init__(self, config: Optional[BrokerConfig] = None):
        """Initialize broker.

        Args:
            config: Broker configuration
        """
        self.config = config or BrokerConfig()

        self._queues: Dict[str, Queue] = {}
        self._exchanges: Dict[str, Exchange] = {}
        self._bindings = BindingRegistry()
        self._dlq = DeadLetterQueue(name="dlq")
        self._router = Router(dead_letter_queue="dlq")

        self._state = BrokerState.STOPPED
        self._lock = threading.RLock()
        self._started_at: Optional[datetime] = None

        self._stats = {
            "messages_published": 0,
            "messages_delivered": 0,
            "messages_acknowledged": 0,
            "messages_dead_lettered": 0,
        }

        # Create default exchanges
        self._setup_default_exchanges()

    def _setup_default_exchanges(self) -> None:
        """Set up default exchanges."""
        # Default direct exchange (empty name)
        self._exchanges[""] = DirectExchange(name="")

        # amq.direct
        self._exchanges["amq.direct"] = ExchangeFactory.create(
            "amq.direct", ExchangeType.DIRECT
        )

        # amq.topic
        self._exchanges["amq.topic"] = ExchangeFactory.create(
            "amq.topic", ExchangeType.TOPIC
        )

        # amq.fanout
        self._exchanges["amq.fanout"] = ExchangeFactory.create(
            "amq.fanout", ExchangeType.FANOUT
        )

        # Dead letter exchange
        if self.config.dead_letter_exchange:
            self._exchanges[self.config.dead_letter_exchange] = ExchangeFactory.create(
                self.config.dead_letter_exchange, ExchangeType.FANOUT
            )

    def start(self) -> None:
        """Start the broker."""
        with self._lock:
            if self._state == BrokerState.RUNNING:
                return

            self._state = BrokerState.STARTING
            self._started_at = datetime.now()

            # Start background tasks
            self._start_heartbeat()

            self._state = BrokerState.RUNNING
            logger.info(f"Broker {self.config.name} started")

    def stop(self) -> None:
        """Stop the broker."""
        with self._lock:
            if self._state == BrokerState.STOPPED:
                return

            self._state = BrokerState.STOPPING

            # Stop all queues
            for queue in self._queues.values():
                queue.pause()

            self._state = BrokerState.STOPPED
            logger.info(f"Broker {self.config.name} stopped")

    def _start_heartbeat(self) -> None:
        """Start heartbeat thread."""
        def heartbeat_loop():
            while self._state == BrokerState.RUNNING:
                self._check_health()
                time.sleep(self.config.heartbeat_interval)

        thread = threading.Thread(
            target=heartbeat_loop,
            daemon=True,
            name="BrokerHeartbeat",
        )
        thread.start()

    def _check_health(self) -> None:
        """Check broker health."""
        # Check for stale messages, consumer health, etc.
        pass

    # Queue Management

    def declare_queue(
        self,
        name: str,
        durable: bool = True,
        exclusive: bool = False,
        auto_delete: bool = False,
        max_size: int = 0,
        message_ttl: Optional[int] = None,
        dead_letter_queue: Optional[str] = None,
        queue_type: str = "standard",
    ) -> Queue:
        """Declare a queue.

        Args:
            name: Queue name
            durable: Persist queue
            exclusive: Single consumer only
            auto_delete: Delete when unused
            max_size: Maximum messages
            message_ttl: Default message TTL
            dead_letter_queue: DLQ name
            queue_type: "standard", "priority", or "delay"

        Returns:
            Queue instance
        """
        with self._lock:
            if name in self._queues:
                return self._queues[name]

            if len(self._queues) >= self.config.max_queues:
                raise RuntimeError("Maximum queue limit reached")

            config = QueueConfig(
                name=name,
                durable=durable,
                exclusive=exclusive,
                auto_delete=auto_delete,
                max_size=max_size,
                message_ttl=message_ttl or self.config.message_ttl,
                dead_letter_queue=dead_letter_queue,
            )

            if queue_type == "priority":
                queue = PriorityQueue(config=config)
            elif queue_type == "delay":
                queue = DelayQueue(config=config)
                queue.start()
            else:
                queue = Queue(config=config)

            self._queues[name] = queue

            # Auto-bind to default exchange
            self._exchanges[""].bind(name, name)

            logger.info(f"Declared queue: {name} (type={queue_type})")
            return queue

    def delete_queue(self, name: str, if_unused: bool = False, if_empty: bool = False) -> bool:
        """Delete a queue.

        Args:
            name: Queue name
            if_unused: Only delete if no consumers
            if_empty: Only delete if empty

        Returns:
            True if deleted
        """
        with self._lock:
            if name not in self._queues:
                return False

            queue = self._queues[name]

            if if_unused and queue.get_stats().consumers > 0:
                return False

            if if_empty and len(queue) > 0:
                return False

            # Remove bindings
            self._bindings.remove_queue_bindings(name)

            # Delete queue
            queue.delete()
            del self._queues[name]

            logger.info(f"Deleted queue: {name}")
            return True

    def get_queue(self, name: str) -> Optional[Queue]:
        """Get a queue by name."""
        return self._queues.get(name)

    def list_queues(self) -> List[str]:
        """List all queue names."""
        return list(self._queues.keys())

    def purge_queue(self, name: str) -> int:
        """Purge all messages from a queue.

        Returns:
            Number of messages purged
        """
        queue = self._queues.get(name)
        if queue:
            return queue.purge()
        return 0

    # Exchange Management

    def declare_exchange(
        self,
        name: str,
        exchange_type: ExchangeType = ExchangeType.DIRECT,
        durable: bool = True,
        auto_delete: bool = False,
        internal: bool = False,
    ) -> Exchange:
        """Declare an exchange.

        Args:
            name: Exchange name
            exchange_type: Type of exchange
            durable: Persist exchange
            auto_delete: Delete when no bindings
            internal: Internal use only

        Returns:
            Exchange instance
        """
        with self._lock:
            if name in self._exchanges:
                return self._exchanges[name]

            if len(self._exchanges) >= self.config.max_exchanges:
                raise RuntimeError("Maximum exchange limit reached")

            exchange = ExchangeFactory.create(
                name=name,
                exchange_type=exchange_type,
                durable=durable,
                auto_delete=auto_delete,
                internal=internal,
            )

            self._exchanges[name] = exchange
            logger.info(f"Declared exchange: {name} (type={exchange_type.name})")
            return exchange

    def delete_exchange(self, name: str, if_unused: bool = False) -> bool:
        """Delete an exchange.

        Args:
            name: Exchange name
            if_unused: Only delete if no bindings

        Returns:
            True if deleted
        """
        with self._lock:
            if name not in self._exchanges:
                return False

            # Prevent deleting default exchanges
            if name in ("", "amq.direct", "amq.topic", "amq.fanout"):
                return False

            if if_unused:
                bindings = self._bindings.get_by_exchange(name)
                if bindings:
                    return False

            # Remove bindings
            self._bindings.remove_exchange_bindings(name)

            del self._exchanges[name]
            logger.info(f"Deleted exchange: {name}")
            return True

    def get_exchange(self, name: str) -> Optional[Exchange]:
        """Get an exchange by name."""
        return self._exchanges.get(name)

    def list_exchanges(self) -> List[str]:
        """List all exchange names."""
        return list(self._exchanges.keys())

    # Binding Management

    def bind(
        self,
        queue: str,
        exchange: str,
        routing_key: str = "",
        arguments: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """Create a binding.

        Args:
            queue: Queue name
            exchange: Exchange name
            routing_key: Routing key
            arguments: Additional arguments

        Returns:
            True if binding created
        """
        with self._lock:
            if queue not in self._queues:
                raise ValueError(f"Queue not found: {queue}")
            if exchange not in self._exchanges:
                raise ValueError(f"Exchange not found: {exchange}")

            binding = Binding(
                exchange_name=exchange,
                queue_name=queue,
                routing_key=routing_key,
                arguments=arguments or {},
            )

            if self._bindings.add(binding):
                self._exchanges[exchange].bind(queue, routing_key)
                logger.info(f"Bound {queue} to {exchange} with key {routing_key!r}")
                return True
            return False

    def unbind(
        self,
        queue: str,
        exchange: str,
        routing_key: str = "",
    ) -> bool:
        """Remove a binding.

        Args:
            queue: Queue name
            exchange: Exchange name
            routing_key: Routing key

        Returns:
            True if binding removed
        """
        with self._lock:
            binding = Binding(
                exchange_name=exchange,
                queue_name=queue,
                routing_key=routing_key,
            )

            if self._bindings.remove(binding):
                if exchange in self._exchanges:
                    self._exchanges[exchange].unbind(queue, routing_key)
                logger.info(f"Unbound {queue} from {exchange}")
                return True
            return False

    # Message Publishing

    def publish(
        self,
        message: Message,
        exchange: str = "",
        routing_key: str = "",
        mandatory: bool = False,
    ) -> bool:
        """Publish a message.

        Args:
            message: Message to publish
            exchange: Exchange name
            routing_key: Routing key
            mandatory: Require at least one queue

        Returns:
            True if published successfully
        """
        if self._state != BrokerState.RUNNING:
            logger.warning("Broker not running")
            return False

        with self._lock:
            if exchange not in self._exchanges:
                logger.warning(f"Exchange not found: {exchange}")
                return False

            message.exchange = exchange
            message.routing_key = routing_key

            # Route message
            target_queues = self._exchanges[exchange].route(message)

            if not target_queues:
                if mandatory:
                    # Return unroutable message
                    self._dead_letter(message, DeadLetterReason.ROUTING_FAILED)
                    return False
                # Silently drop
                return True

            # Deliver to queues
            delivered = 0
            for queue_name in target_queues:
                queue = self._queues.get(queue_name)
                if queue:
                    msg_copy = message.clone() if len(target_queues) > 1 else message
                    if queue.publish(msg_copy):
                        delivered += 1

            self._stats["messages_published"] += 1
            if delivered > 0:
                self._stats["messages_delivered"] += delivered

            return delivered > 0

    def publish_to_queue(self, message: Message, queue_name: str) -> bool:
        """Publish directly to a queue.

        Args:
            message: Message to publish
            queue_name: Target queue name

        Returns:
            True if published
        """
        return self.publish(message, exchange="", routing_key=queue_name)

    def _dead_letter(self, message: Message, reason: DeadLetterReason) -> None:
        """Send message to dead letter queue."""
        self._dlq.add(message, reason)
        self._stats["messages_dead_lettered"] += 1

        # Also publish to DLX if configured
        if self.config.dead_letter_exchange:
            dlx = self._exchanges.get(self.config.dead_letter_exchange)
            if dlx:
                dlx.route(message)

    # Consumer Management

    def consume(
        self,
        queue: str,
        consumer_id: str,
        callback: Callable[[Message], None],
        prefetch: int = 1,
    ) -> bool:
        """Register a consumer.

        Args:
            queue: Queue name
            consumer_id: Consumer identifier
            callback: Message callback
            prefetch: Prefetch count

        Returns:
            True if consumer registered
        """
        q = self._queues.get(queue)
        if not q:
            raise ValueError(f"Queue not found: {queue}")

        return q.consume(consumer_id, callback, prefetch)

    def cancel(self, queue: str, consumer_id: str) -> bool:
        """Cancel a consumer.

        Args:
            queue: Queue name
            consumer_id: Consumer identifier

        Returns:
            True if cancelled
        """
        q = self._queues.get(queue)
        if not q:
            return False

        return q.cancel_consumer(consumer_id)

    def ack(self, queue: str, message_id: str, consumer_id: str) -> bool:
        """Acknowledge a message.

        Args:
            queue: Queue name
            message_id: Message ID
            consumer_id: Consumer ID

        Returns:
            True if acknowledged
        """
        q = self._queues.get(queue)
        if not q:
            return False

        if q.ack(message_id, consumer_id):
            self._stats["messages_acknowledged"] += 1
            return True
        return False

    def nack(
        self,
        queue: str,
        message_id: str,
        consumer_id: str,
        requeue: bool = True,
    ) -> bool:
        """Negative acknowledge a message.

        Args:
            queue: Queue name
            message_id: Message ID
            consumer_id: Consumer ID
            requeue: Requeue the message

        Returns:
            True if nacked
        """
        q = self._queues.get(queue)
        if not q:
            return False

        return q.nack(message_id, consumer_id, requeue)

    # Statistics

    def get_stats(self) -> BrokerStats:
        """Get broker statistics."""
        uptime = 0.0
        if self._started_at:
            uptime = (datetime.now() - self._started_at).total_seconds()

        return BrokerStats(
            state=self._state,
            queues=len(self._queues),
            exchanges=len(self._exchanges),
            bindings=len(self._bindings),
            messages_published=self._stats["messages_published"],
            messages_delivered=self._stats["messages_delivered"],
            messages_acknowledged=self._stats["messages_acknowledged"],
            messages_dead_lettered=self._stats["messages_dead_lettered"],
            uptime_seconds=uptime,
            started_at=self._started_at,
        )

    def get_queue_stats(self) -> Dict[str, Any]:
        """Get statistics for all queues."""
        return {
            name: queue.get_stats().__dict__
            for name, queue in self._queues.items()
        }

    def __enter__(self) -> "Broker":
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.stop()


__all__ = [
    "Broker",
    "BrokerConfig",
    "BrokerState",
    "BrokerStats",
]

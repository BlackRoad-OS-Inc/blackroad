"""RoadQueue Exchange - Message Exchange Types.

This module implements various exchange types for message routing:
- Direct: Route to queues with exact routing key match
- Topic: Route to queues with pattern matching routing keys
- Fanout: Broadcast to all bound queues
- Headers: Route based on message headers

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import fnmatch
import logging
import re
import threading
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Pattern, Set, Tuple

from roadqueue_core.queue.message import Message

logger = logging.getLogger(__name__)


class ExchangeType(Enum):
    """Types of message exchanges."""

    DIRECT = auto()   # Exact routing key match
    TOPIC = auto()    # Pattern matching with wildcards
    FANOUT = auto()   # Broadcast to all
    HEADERS = auto()  # Route based on headers


@dataclass
class ExchangeConfig:
    """Exchange configuration.

    Attributes:
        name: Exchange name
        type: Exchange type
        durable: Persist exchange definition
        auto_delete: Delete when no bindings
        internal: Only accessible by other exchanges
        arguments: Additional arguments
    """

    name: str
    type: ExchangeType = ExchangeType.DIRECT
    durable: bool = True
    auto_delete: bool = False
    internal: bool = False
    arguments: Dict[str, Any] = field(default_factory=dict)


@dataclass
class BoundQueue:
    """A queue bound to an exchange."""

    queue_name: str
    routing_key: str = ""
    headers: Dict[str, str] = field(default_factory=dict)
    match_type: str = "all"  # all or any for headers
    bound_at: datetime = field(default_factory=datetime.now)


class Exchange(ABC):
    """Abstract base class for exchanges."""

    def __init__(self, config: ExchangeConfig):
        """Initialize exchange.

        Args:
            config: Exchange configuration
        """
        self.config = config
        self._bindings: List[BoundQueue] = []
        self._lock = threading.RLock()
        self._stats = {
            "messages_routed": 0,
            "messages_dropped": 0,
        }

    @property
    def name(self) -> str:
        """Get exchange name."""
        return self.config.name

    @property
    def type(self) -> ExchangeType:
        """Get exchange type."""
        return self.config.type

    def bind(
        self,
        queue_name: str,
        routing_key: str = "",
        headers: Optional[Dict[str, str]] = None,
    ) -> bool:
        """Bind a queue to this exchange.

        Args:
            queue_name: Queue to bind
            routing_key: Routing key for binding
            headers: Headers for header exchange

        Returns:
            True if binding created
        """
        with self._lock:
            # Check for duplicate
            for binding in self._bindings:
                if binding.queue_name == queue_name and binding.routing_key == routing_key:
                    return False

            binding = BoundQueue(
                queue_name=queue_name,
                routing_key=routing_key,
                headers=headers or {},
            )
            self._bindings.append(binding)
            logger.info(
                f"Bound queue {queue_name} to exchange {self.name} "
                f"with key {routing_key!r}"
            )
            return True

    def unbind(
        self,
        queue_name: str,
        routing_key: str = "",
    ) -> bool:
        """Unbind a queue from this exchange.

        Args:
            queue_name: Queue to unbind
            routing_key: Routing key for binding

        Returns:
            True if binding removed
        """
        with self._lock:
            for i, binding in enumerate(self._bindings):
                if binding.queue_name == queue_name and binding.routing_key == routing_key:
                    del self._bindings[i]
                    logger.info(
                        f"Unbound queue {queue_name} from exchange {self.name}"
                    )

                    # Check auto-delete
                    if self.config.auto_delete and not self._bindings:
                        self._deleted = True

                    return True
            return False

    @abstractmethod
    def route(self, message: Message) -> List[str]:
        """Route a message to queues.

        Args:
            message: Message to route

        Returns:
            List of queue names to deliver to
        """
        pass

    def get_bindings(self) -> List[BoundQueue]:
        """Get all bindings."""
        with self._lock:
            return list(self._bindings)

    def get_stats(self) -> Dict[str, Any]:
        """Get exchange statistics."""
        return {
            "name": self.name,
            "type": self.type.name,
            "bindings": len(self._bindings),
            **self._stats,
        }


class DirectExchange(Exchange):
    """Direct exchange - routes based on exact routing key match."""

    def __init__(self, name: str = "", **kwargs):
        config = ExchangeConfig(
            name=name or "direct",
            type=ExchangeType.DIRECT,
            **kwargs,
        )
        super().__init__(config)

        # Build routing index
        self._routing_index: Dict[str, Set[str]] = {}

    def bind(
        self,
        queue_name: str,
        routing_key: str = "",
        headers: Optional[Dict[str, str]] = None,
    ) -> bool:
        if super().bind(queue_name, routing_key, headers):
            # Update index
            if routing_key not in self._routing_index:
                self._routing_index[routing_key] = set()
            self._routing_index[routing_key].add(queue_name)
            return True
        return False

    def unbind(
        self,
        queue_name: str,
        routing_key: str = "",
    ) -> bool:
        if super().unbind(queue_name, routing_key):
            # Update index
            if routing_key in self._routing_index:
                self._routing_index[routing_key].discard(queue_name)
                if not self._routing_index[routing_key]:
                    del self._routing_index[routing_key]
            return True
        return False

    def route(self, message: Message) -> List[str]:
        """Route message to queues with matching routing key."""
        routing_key = message.routing_key or ""

        with self._lock:
            queues = list(self._routing_index.get(routing_key, set()))

        if queues:
            self._stats["messages_routed"] += 1
        else:
            self._stats["messages_dropped"] += 1

        return queues


class TopicExchange(Exchange):
    """Topic exchange - routes based on pattern matching.

    Routing key patterns support:
    - * matches exactly one word
    - # matches zero or more words
    - . separates words

    Example patterns:
    - "stock.*" matches "stock.usd", "stock.eur"
    - "stock.#" matches "stock", "stock.usd", "stock.usd.nyse"
    """

    def __init__(self, name: str = "", **kwargs):
        config = ExchangeConfig(
            name=name or "topic",
            type=ExchangeType.TOPIC,
            **kwargs,
        )
        super().__init__(config)

        # Compiled patterns for performance
        self._patterns: Dict[str, Tuple[Pattern, str]] = {}

    def _compile_pattern(self, pattern: str) -> Pattern:
        """Compile a routing key pattern to regex."""
        # Escape special regex chars except our wildcards
        escaped = re.escape(pattern)

        # Replace wildcards
        # # matches zero or more words
        escaped = escaped.replace(r"\#", r"[a-zA-Z0-9._]*")
        # * matches exactly one word
        escaped = escaped.replace(r"\*", r"[a-zA-Z0-9_]+")

        return re.compile(f"^{escaped}$")

    def bind(
        self,
        queue_name: str,
        routing_key: str = "",
        headers: Optional[Dict[str, str]] = None,
    ) -> bool:
        if super().bind(queue_name, routing_key, headers):
            # Compile pattern
            pattern = self._compile_pattern(routing_key)
            self._patterns[f"{queue_name}:{routing_key}"] = (pattern, queue_name)
            return True
        return False

    def unbind(
        self,
        queue_name: str,
        routing_key: str = "",
    ) -> bool:
        if super().unbind(queue_name, routing_key):
            key = f"{queue_name}:{routing_key}"
            if key in self._patterns:
                del self._patterns[key]
            return True
        return False

    def route(self, message: Message) -> List[str]:
        """Route message to queues matching routing key pattern."""
        routing_key = message.routing_key or ""
        queues = set()

        with self._lock:
            for pattern, queue_name in self._patterns.values():
                if pattern.match(routing_key):
                    queues.add(queue_name)

        if queues:
            self._stats["messages_routed"] += 1
        else:
            self._stats["messages_dropped"] += 1

        return list(queues)


class FanoutExchange(Exchange):
    """Fanout exchange - broadcasts to all bound queues."""

    def __init__(self, name: str = "", **kwargs):
        config = ExchangeConfig(
            name=name or "fanout",
            type=ExchangeType.FANOUT,
            **kwargs,
        )
        super().__init__(config)

    def route(self, message: Message) -> List[str]:
        """Route message to all bound queues."""
        with self._lock:
            queues = [binding.queue_name for binding in self._bindings]

        if queues:
            self._stats["messages_routed"] += 1
        else:
            self._stats["messages_dropped"] += 1

        return queues


class HeadersExchange(Exchange):
    """Headers exchange - routes based on message headers.

    Bindings specify required headers and match type:
    - all: All specified headers must match
    - any: At least one header must match
    """

    def __init__(self, name: str = "", **kwargs):
        config = ExchangeConfig(
            name=name or "headers",
            type=ExchangeType.HEADERS,
            **kwargs,
        )
        super().__init__(config)

    def bind(
        self,
        queue_name: str,
        routing_key: str = "",
        headers: Optional[Dict[str, str]] = None,
        match_type: str = "all",
    ) -> bool:
        """Bind queue with header matching.

        Args:
            queue_name: Queue to bind
            routing_key: Ignored for headers exchange
            headers: Headers to match
            match_type: "all" or "any"
        """
        with self._lock:
            binding = BoundQueue(
                queue_name=queue_name,
                routing_key="",
                headers=headers or {},
                match_type=match_type,
            )
            self._bindings.append(binding)
            logger.info(
                f"Bound queue {queue_name} to headers exchange {self.name}"
            )
            return True

    def route(self, message: Message) -> List[str]:
        """Route message based on header matching."""
        msg_headers = message.headers.custom
        queues = set()

        with self._lock:
            for binding in self._bindings:
                if not binding.headers:
                    continue

                if binding.match_type == "all":
                    # All headers must match
                    if all(
                        msg_headers.get(k) == v
                        for k, v in binding.headers.items()
                    ):
                        queues.add(binding.queue_name)
                else:
                    # Any header must match
                    if any(
                        msg_headers.get(k) == v
                        for k, v in binding.headers.items()
                    ):
                        queues.add(binding.queue_name)

        if queues:
            self._stats["messages_routed"] += 1
        else:
            self._stats["messages_dropped"] += 1

        return list(queues)


class ExchangeFactory:
    """Factory for creating exchanges."""

    @staticmethod
    def create(
        name: str,
        exchange_type: ExchangeType,
        **kwargs,
    ) -> Exchange:
        """Create an exchange of the specified type.

        Args:
            name: Exchange name
            exchange_type: Type of exchange
            **kwargs: Additional configuration

        Returns:
            Exchange instance
        """
        if exchange_type == ExchangeType.DIRECT:
            return DirectExchange(name=name, **kwargs)
        elif exchange_type == ExchangeType.TOPIC:
            return TopicExchange(name=name, **kwargs)
        elif exchange_type == ExchangeType.FANOUT:
            return FanoutExchange(name=name, **kwargs)
        elif exchange_type == ExchangeType.HEADERS:
            return HeadersExchange(name=name, **kwargs)
        else:
            raise ValueError(f"Unknown exchange type: {exchange_type}")


__all__ = [
    "Exchange",
    "ExchangeType",
    "ExchangeConfig",
    "BoundQueue",
    "DirectExchange",
    "TopicExchange",
    "FanoutExchange",
    "HeadersExchange",
    "ExchangeFactory",
]

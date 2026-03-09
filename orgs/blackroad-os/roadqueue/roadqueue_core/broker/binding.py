"""RoadQueue Binding - Exchange-Queue Bindings.

This module manages the bindings between exchanges and queues.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import re
import threading
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional, Set

logger = logging.getLogger(__name__)


@dataclass
class BindingKey:
    """A routing/binding key with pattern matching support.

    Supports AMQP-style wildcards:
    - * matches exactly one word
    - # matches zero or more words
    - . separates words
    """

    pattern: str
    _regex: Optional[re.Pattern] = field(default=None, repr=False)

    def __post_init__(self):
        self._regex = self._compile()

    def _compile(self) -> re.Pattern:
        """Compile pattern to regex."""
        if not self.pattern:
            return re.compile("^$")

        # Check if pattern has wildcards
        if "*" not in self.pattern and "#" not in self.pattern:
            # Exact match
            return re.compile(f"^{re.escape(self.pattern)}$")

        # Build regex from pattern
        parts = []
        for segment in self.pattern.split("."):
            if segment == "#":
                parts.append(r"[a-zA-Z0-9._]*")
            elif segment == "*":
                parts.append(r"[a-zA-Z0-9_]+")
            else:
                parts.append(re.escape(segment))

        regex_pattern = r"\.".join(parts)
        return re.compile(f"^{regex_pattern}$")

    def matches(self, routing_key: str) -> bool:
        """Check if a routing key matches this pattern.

        Args:
            routing_key: Key to match

        Returns:
            True if matches
        """
        return bool(self._regex.match(routing_key))

    def is_exact(self) -> bool:
        """Check if this is an exact (no wildcards) pattern."""
        return "*" not in self.pattern and "#" not in self.pattern

    def __eq__(self, other: object) -> bool:
        if isinstance(other, BindingKey):
            return self.pattern == other.pattern
        return False

    def __hash__(self) -> int:
        return hash(self.pattern)


@dataclass
class Binding:
    """A binding between an exchange and a queue.

    Attributes:
        exchange_name: Source exchange
        queue_name: Target queue
        routing_key: Routing key for matching
        arguments: Additional binding arguments
        created_at: When binding was created
    """

    exchange_name: str
    queue_name: str
    routing_key: str = ""
    arguments: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)

    _key: Optional[BindingKey] = field(default=None, repr=False)

    def __post_init__(self):
        self._key = BindingKey(self.routing_key)

    def matches(self, routing_key: str) -> bool:
        """Check if routing key matches this binding."""
        return self._key.matches(routing_key)

    def to_dict(self) -> Dict[str, Any]:
        """Convert binding to dictionary."""
        return {
            "exchange_name": self.exchange_name,
            "queue_name": self.queue_name,
            "routing_key": self.routing_key,
            "arguments": self.arguments,
            "created_at": self.created_at.isoformat(),
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Binding":
        """Create binding from dictionary."""
        return cls(
            exchange_name=data["exchange_name"],
            queue_name=data["queue_name"],
            routing_key=data.get("routing_key", ""),
            arguments=data.get("arguments", {}),
            created_at=datetime.fromisoformat(data["created_at"])
            if "created_at" in data
            else datetime.now(),
        )

    def __eq__(self, other: object) -> bool:
        if isinstance(other, Binding):
            return (
                self.exchange_name == other.exchange_name
                and self.queue_name == other.queue_name
                and self.routing_key == other.routing_key
            )
        return False

    def __hash__(self) -> int:
        return hash((self.exchange_name, self.queue_name, self.routing_key))


class BindingRegistry:
    """Registry for managing exchange-queue bindings.

    Provides efficient lookup of bindings by exchange, queue,
    or routing key.
    """

    def __init__(self):
        self._bindings: Set[Binding] = set()
        self._by_exchange: Dict[str, Set[Binding]] = {}
        self._by_queue: Dict[str, Set[Binding]] = {}
        self._lock = threading.RLock()

    def add(self, binding: Binding) -> bool:
        """Add a binding.

        Args:
            binding: Binding to add

        Returns:
            True if added (not duplicate)
        """
        with self._lock:
            if binding in self._bindings:
                return False

            self._bindings.add(binding)

            # Index by exchange
            if binding.exchange_name not in self._by_exchange:
                self._by_exchange[binding.exchange_name] = set()
            self._by_exchange[binding.exchange_name].add(binding)

            # Index by queue
            if binding.queue_name not in self._by_queue:
                self._by_queue[binding.queue_name] = set()
            self._by_queue[binding.queue_name].add(binding)

            logger.debug(
                f"Added binding: {binding.exchange_name} -> "
                f"{binding.queue_name} [{binding.routing_key}]"
            )
            return True

    def remove(self, binding: Binding) -> bool:
        """Remove a binding.

        Args:
            binding: Binding to remove

        Returns:
            True if removed
        """
        with self._lock:
            if binding not in self._bindings:
                return False

            self._bindings.discard(binding)

            # Remove from indexes
            if binding.exchange_name in self._by_exchange:
                self._by_exchange[binding.exchange_name].discard(binding)
                if not self._by_exchange[binding.exchange_name]:
                    del self._by_exchange[binding.exchange_name]

            if binding.queue_name in self._by_queue:
                self._by_queue[binding.queue_name].discard(binding)
                if not self._by_queue[binding.queue_name]:
                    del self._by_queue[binding.queue_name]

            logger.debug(
                f"Removed binding: {binding.exchange_name} -> "
                f"{binding.queue_name}"
            )
            return True

    def get_by_exchange(self, exchange_name: str) -> List[Binding]:
        """Get bindings for an exchange.

        Args:
            exchange_name: Exchange name

        Returns:
            List of bindings
        """
        with self._lock:
            return list(self._by_exchange.get(exchange_name, set()))

    def get_by_queue(self, queue_name: str) -> List[Binding]:
        """Get bindings for a queue.

        Args:
            queue_name: Queue name

        Returns:
            List of bindings
        """
        with self._lock:
            return list(self._by_queue.get(queue_name, set()))

    def find_matching(
        self,
        exchange_name: str,
        routing_key: str,
    ) -> List[Binding]:
        """Find bindings matching a routing key.

        Args:
            exchange_name: Exchange name
            routing_key: Routing key to match

        Returns:
            List of matching bindings
        """
        with self._lock:
            bindings = self._by_exchange.get(exchange_name, set())
            return [b for b in bindings if b.matches(routing_key)]

    def get_target_queues(
        self,
        exchange_name: str,
        routing_key: str,
    ) -> List[str]:
        """Get queue names for matching bindings.

        Args:
            exchange_name: Exchange name
            routing_key: Routing key

        Returns:
            List of queue names
        """
        bindings = self.find_matching(exchange_name, routing_key)
        return list(set(b.queue_name for b in bindings))

    def remove_exchange_bindings(self, exchange_name: str) -> int:
        """Remove all bindings for an exchange.

        Args:
            exchange_name: Exchange name

        Returns:
            Number of bindings removed
        """
        with self._lock:
            bindings = list(self._by_exchange.get(exchange_name, set()))
            for binding in bindings:
                self.remove(binding)
            return len(bindings)

    def remove_queue_bindings(self, queue_name: str) -> int:
        """Remove all bindings for a queue.

        Args:
            queue_name: Queue name

        Returns:
            Number of bindings removed
        """
        with self._lock:
            bindings = list(self._by_queue.get(queue_name, set()))
            for binding in bindings:
                self.remove(binding)
            return len(bindings)

    def list_all(self) -> List[Binding]:
        """List all bindings."""
        with self._lock:
            return list(self._bindings)

    def __len__(self) -> int:
        return len(self._bindings)

    def __iter__(self):
        return iter(list(self._bindings))


class BindingBuilder:
    """Fluent builder for creating bindings."""

    def __init__(self):
        self._exchange_name: Optional[str] = None
        self._queue_name: Optional[str] = None
        self._routing_key: str = ""
        self._arguments: Dict[str, Any] = {}

    def from_exchange(self, name: str) -> "BindingBuilder":
        """Set source exchange."""
        self._exchange_name = name
        return self

    def to_queue(self, name: str) -> "BindingBuilder":
        """Set target queue."""
        self._queue_name = name
        return self

    def with_routing_key(self, key: str) -> "BindingBuilder":
        """Set routing key."""
        self._routing_key = key
        return self

    def with_argument(self, key: str, value: Any) -> "BindingBuilder":
        """Add an argument."""
        self._arguments[key] = value
        return self

    def build(self) -> Binding:
        """Build the binding."""
        if not self._exchange_name:
            raise ValueError("Exchange name is required")
        if not self._queue_name:
            raise ValueError("Queue name is required")

        return Binding(
            exchange_name=self._exchange_name,
            queue_name=self._queue_name,
            routing_key=self._routing_key,
            arguments=self._arguments,
        )


def bind(exchange: str, queue: str, routing_key: str = "") -> Binding:
    """Create a binding.

    Args:
        exchange: Exchange name
        queue: Queue name
        routing_key: Routing key

    Returns:
        Binding instance
    """
    return Binding(
        exchange_name=exchange,
        queue_name=queue,
        routing_key=routing_key,
    )


__all__ = [
    "Binding",
    "BindingKey",
    "BindingRegistry",
    "BindingBuilder",
    "bind",
]

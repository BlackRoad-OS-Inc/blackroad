"""RoadQueue Router - Intelligent Message Routing.

This module provides advanced routing capabilities beyond simple
exchange-based routing, including content-based routing, load
balancing, and failover.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import random
import re
import threading
import time
from abc import ABC, abstractmethod
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Tuple

from roadqueue_core.queue.message import Message

logger = logging.getLogger(__name__)


class RoutingStrategy(Enum):
    """Routing strategies for load balancing."""

    ROUND_ROBIN = auto()    # Cycle through targets
    RANDOM = auto()         # Random selection
    LEAST_LOADED = auto()   # Route to least busy
    WEIGHTED = auto()       # Weight-based distribution
    CONSISTENT_HASH = auto()  # Hash-based sticky routing


@dataclass
class RoutingRule:
    """A routing rule for content-based routing.

    Attributes:
        name: Rule name
        condition: Function that evaluates message
        targets: Target queue names
        priority: Rule priority (higher = first)
        enabled: Whether rule is active
        strategy: Load balancing strategy
        weights: Weights for weighted strategy
    """

    name: str
    condition: Callable[[Message], bool]
    targets: List[str]
    priority: int = 0
    enabled: bool = True
    strategy: RoutingStrategy = RoutingStrategy.ROUND_ROBIN
    weights: Optional[Dict[str, int]] = None

    _round_robin_index: int = field(default=0, repr=False)

    def matches(self, message: Message) -> bool:
        """Check if message matches this rule."""
        if not self.enabled:
            return False
        try:
            return self.condition(message)
        except Exception as e:
            logger.error(f"Rule {self.name} condition failed: {e}")
            return False

    def select_target(self, message: Message) -> Optional[str]:
        """Select a target queue based on strategy."""
        if not self.targets:
            return None

        if len(self.targets) == 1:
            return self.targets[0]

        if self.strategy == RoutingStrategy.ROUND_ROBIN:
            target = self.targets[self._round_robin_index % len(self.targets)]
            self._round_robin_index += 1
            return target

        elif self.strategy == RoutingStrategy.RANDOM:
            return random.choice(self.targets)

        elif self.strategy == RoutingStrategy.WEIGHTED:
            if not self.weights:
                return random.choice(self.targets)

            total_weight = sum(self.weights.get(t, 1) for t in self.targets)
            r = random.randint(1, total_weight)
            cumulative = 0
            for target in self.targets:
                cumulative += self.weights.get(target, 1)
                if r <= cumulative:
                    return target
            return self.targets[-1]

        elif self.strategy == RoutingStrategy.CONSISTENT_HASH:
            # Hash based on message ID for sticky routing
            hash_value = hash(message.id)
            return self.targets[hash_value % len(self.targets)]

        else:
            return self.targets[0]


class RuleBuilder:
    """Fluent builder for routing rules."""

    def __init__(self, name: str):
        self._name = name
        self._condition: Optional[Callable[[Message], bool]] = None
        self._targets: List[str] = []
        self._priority: int = 0
        self._strategy = RoutingStrategy.ROUND_ROBIN
        self._weights: Dict[str, int] = {}

    def when(self, condition: Callable[[Message], bool]) -> "RuleBuilder":
        """Set rule condition."""
        self._condition = condition
        return self

    def when_header(self, key: str, value: str) -> "RuleBuilder":
        """Match when header equals value."""
        self._condition = lambda m: m.headers.custom.get(key) == value
        return self

    def when_header_contains(self, key: str, value: str) -> "RuleBuilder":
        """Match when header contains value."""
        self._condition = lambda m: value in m.headers.custom.get(key, "")
        return self

    def when_type(self, message_type: str) -> "RuleBuilder":
        """Match when message type equals."""
        self._condition = lambda m: m.headers.type == message_type
        return self

    def when_routing_key(self, pattern: str) -> "RuleBuilder":
        """Match routing key pattern."""
        regex = re.compile(pattern)
        self._condition = lambda m: bool(regex.match(m.routing_key or ""))
        return self

    def route_to(self, *queues: str) -> "RuleBuilder":
        """Set target queues."""
        self._targets = list(queues)
        return self

    def with_priority(self, priority: int) -> "RuleBuilder":
        """Set rule priority."""
        self._priority = priority
        return self

    def use_round_robin(self) -> "RuleBuilder":
        """Use round-robin load balancing."""
        self._strategy = RoutingStrategy.ROUND_ROBIN
        return self

    def use_random(self) -> "RuleBuilder":
        """Use random load balancing."""
        self._strategy = RoutingStrategy.RANDOM
        return self

    def use_weighted(self, weights: Dict[str, int]) -> "RuleBuilder":
        """Use weighted load balancing."""
        self._strategy = RoutingStrategy.WEIGHTED
        self._weights = weights
        return self

    def use_consistent_hash(self) -> "RuleBuilder":
        """Use consistent hashing."""
        self._strategy = RoutingStrategy.CONSISTENT_HASH
        return self

    def build(self) -> RoutingRule:
        """Build the routing rule."""
        if not self._condition:
            raise ValueError("Rule condition is required")
        if not self._targets:
            raise ValueError("At least one target is required")

        return RoutingRule(
            name=self._name,
            condition=self._condition,
            targets=self._targets,
            priority=self._priority,
            strategy=self._strategy,
            weights=self._weights if self._weights else None,
        )


class Router:
    """Content-based message router.

    Routes messages based on content using configurable rules.

    Features:
    - Rule-based routing
    - Multiple load balancing strategies
    - Priority-based rule evaluation
    - Fallback routing
    - Dead letter handling
    """

    def __init__(
        self,
        default_queue: Optional[str] = None,
        dead_letter_queue: Optional[str] = None,
    ):
        """Initialize router.

        Args:
            default_queue: Default queue when no rules match
            dead_letter_queue: DLQ for unroutable messages
        """
        self.default_queue = default_queue
        self.dead_letter_queue = dead_letter_queue

        self._rules: List[RoutingRule] = []
        self._lock = threading.RLock()
        self._stats = {
            "messages_routed": 0,
            "messages_defaulted": 0,
            "messages_dead_lettered": 0,
            "rule_matches": defaultdict(int),
        }

    def add_rule(self, rule: RoutingRule) -> None:
        """Add a routing rule.

        Args:
            rule: Rule to add
        """
        with self._lock:
            self._rules.append(rule)
            # Sort by priority (higher first)
            self._rules.sort(key=lambda r: r.priority, reverse=True)
            logger.info(f"Added routing rule: {rule.name}")

    def remove_rule(self, name: str) -> bool:
        """Remove a routing rule.

        Args:
            name: Rule name

        Returns:
            True if removed
        """
        with self._lock:
            for i, rule in enumerate(self._rules):
                if rule.name == name:
                    del self._rules[i]
                    logger.info(f"Removed routing rule: {name}")
                    return True
            return False

    def enable_rule(self, name: str) -> bool:
        """Enable a routing rule."""
        with self._lock:
            for rule in self._rules:
                if rule.name == name:
                    rule.enabled = True
                    return True
            return False

    def disable_rule(self, name: str) -> bool:
        """Disable a routing rule."""
        with self._lock:
            for rule in self._rules:
                if rule.name == name:
                    rule.enabled = False
                    return True
            return False

    def route(self, message: Message) -> List[str]:
        """Route a message based on rules.

        Args:
            message: Message to route

        Returns:
            List of target queue names
        """
        with self._lock:
            for rule in self._rules:
                if rule.matches(message):
                    target = rule.select_target(message)
                    if target:
                        self._stats["messages_routed"] += 1
                        self._stats["rule_matches"][rule.name] += 1
                        return [target]

            # No rule matched
            if self.default_queue:
                self._stats["messages_defaulted"] += 1
                return [self.default_queue]

            # Dead letter
            if self.dead_letter_queue:
                self._stats["messages_dead_lettered"] += 1
                return [self.dead_letter_queue]

            return []

    def route_all(self, message: Message) -> List[str]:
        """Route to all matching rules (multicast).

        Args:
            message: Message to route

        Returns:
            List of all matching target queues
        """
        targets = set()

        with self._lock:
            for rule in self._rules:
                if rule.matches(message):
                    target = rule.select_target(message)
                    if target:
                        targets.add(target)
                        self._stats["rule_matches"][rule.name] += 1

            if targets:
                self._stats["messages_routed"] += 1
            elif self.default_queue:
                targets.add(self.default_queue)
                self._stats["messages_defaulted"] += 1
            elif self.dead_letter_queue:
                targets.add(self.dead_letter_queue)
                self._stats["messages_dead_lettered"] += 1

        return list(targets)

    def get_matching_rules(self, message: Message) -> List[RoutingRule]:
        """Get all rules that match a message.

        Args:
            message: Message to check

        Returns:
            List of matching rules
        """
        with self._lock:
            return [rule for rule in self._rules if rule.matches(message)]

    def list_rules(self) -> List[RoutingRule]:
        """List all rules."""
        with self._lock:
            return list(self._rules)

    def get_stats(self) -> Dict[str, Any]:
        """Get router statistics."""
        with self._lock:
            return {
                "rules_count": len(self._rules),
                "enabled_rules": sum(1 for r in self._rules if r.enabled),
                **self._stats,
            }

    def rule(self, name: str) -> RuleBuilder:
        """Create a new rule builder.

        Args:
            name: Rule name

        Returns:
            RuleBuilder instance
        """
        return RuleBuilder(name)


class RouterChain:
    """Chain of routers for complex routing scenarios.

    Messages pass through each router in order until
    one returns targets.
    """

    def __init__(self, routers: Optional[List[Router]] = None):
        self._routers: List[Router] = routers or []

    def add(self, router: Router) -> "RouterChain":
        """Add a router to the chain."""
        self._routers.append(router)
        return self

    def route(self, message: Message) -> List[str]:
        """Route through the chain.

        Args:
            message: Message to route

        Returns:
            Targets from first matching router
        """
        for router in self._routers:
            targets = router.route(message)
            if targets:
                return targets
        return []


class LoadBalancer:
    """Load balancer for distributing messages across queues."""

    def __init__(
        self,
        queues: List[str],
        strategy: RoutingStrategy = RoutingStrategy.ROUND_ROBIN,
        weights: Optional[Dict[str, int]] = None,
    ):
        self._queues = queues
        self._strategy = strategy
        self._weights = weights or {}
        self._index = 0
        self._queue_loads: Dict[str, int] = defaultdict(int)
        self._lock = threading.Lock()

    def select(self, message: Optional[Message] = None) -> str:
        """Select a queue for the message.

        Args:
            message: Message being routed

        Returns:
            Selected queue name
        """
        with self._lock:
            if not self._queues:
                raise ValueError("No queues configured")

            if len(self._queues) == 1:
                return self._queues[0]

            if self._strategy == RoutingStrategy.ROUND_ROBIN:
                queue = self._queues[self._index % len(self._queues)]
                self._index += 1
                return queue

            elif self._strategy == RoutingStrategy.RANDOM:
                return random.choice(self._queues)

            elif self._strategy == RoutingStrategy.LEAST_LOADED:
                return min(self._queues, key=lambda q: self._queue_loads[q])

            elif self._strategy == RoutingStrategy.WEIGHTED:
                total_weight = sum(self._weights.get(q, 1) for q in self._queues)
                r = random.randint(1, total_weight)
                cumulative = 0
                for queue in self._queues:
                    cumulative += self._weights.get(queue, 1)
                    if r <= cumulative:
                        return queue
                return self._queues[-1]

            elif self._strategy == RoutingStrategy.CONSISTENT_HASH:
                if message:
                    hash_value = hash(message.id)
                    return self._queues[hash_value % len(self._queues)]
                return random.choice(self._queues)

            return self._queues[0]

    def report_load(self, queue: str, load: int) -> None:
        """Report current load for a queue.

        Args:
            queue: Queue name
            load: Current load value
        """
        with self._lock:
            self._queue_loads[queue] = load


__all__ = [
    "Router",
    "RoutingRule",
    "RoutingStrategy",
    "RuleBuilder",
    "RouterChain",
    "LoadBalancer",
]

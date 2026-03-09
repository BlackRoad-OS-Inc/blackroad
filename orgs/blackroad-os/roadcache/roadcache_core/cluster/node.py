"""RoadCache Node - Cache Cluster Node.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)


class NodeState(Enum):
    """Node operational states."""

    JOINING = auto()      # Joining cluster
    ACTIVE = auto()       # Normal operation
    LEAVING = auto()      # Leaving cluster
    UNAVAILABLE = auto()  # Not responding
    DEAD = auto()         # Declared dead


@dataclass
class NodeInfo:
    """Information about a cache node.

    Attributes:
        node_id: Unique node identifier
        host: Node hostname or IP
        port: Node port
        datacenter: Datacenter identifier
        rack: Rack identifier
        weight: Node weight for load balancing
        tags: Node tags
    """

    node_id: str
    host: str
    port: int
    datacenter: str = "default"
    rack: str = "default"
    weight: int = 100
    tags: Dict[str, str] = field(default_factory=dict)


@dataclass
class NodeStats:
    """Node statistics.

    Attributes:
        hits: Cache hits
        misses: Cache misses
        entries: Entry count
        memory_bytes: Memory usage
        connections: Active connections
        ops_per_second: Operations per second
        latency_ms: Average latency
    """

    hits: int = 0
    misses: int = 0
    entries: int = 0
    memory_bytes: int = 0
    connections: int = 0
    ops_per_second: float = 0.0
    latency_ms: float = 0.0


class CacheNode:
    """A node in the cache cluster.

    Represents a single cache server instance.
    Handles health monitoring and failover.

    Example:
        node = CacheNode(NodeInfo(
            node_id="node-1",
            host="cache-1.local",
            port=11211,
        ))
        node.start()
        node.get("key")
    """

    def __init__(self, info: NodeInfo):
        """Initialize cache node.

        Args:
            info: Node information
        """
        self.info = info
        self._state = NodeState.JOINING
        self._stats = NodeStats()
        self._lock = threading.RLock()

        self._last_heartbeat: Optional[datetime] = None
        self._failure_count = 0
        self._consecutive_failures = 0

        # Connection (lazy initialized)
        self._connection: Optional[Any] = None

    @property
    def node_id(self) -> str:
        """Get node ID."""
        return self.info.node_id

    @property
    def state(self) -> NodeState:
        """Get node state."""
        return self._state

    @property
    def is_available(self) -> bool:
        """Check if node is available."""
        return self._state == NodeState.ACTIVE

    def start(self) -> bool:
        """Start the node.

        Returns:
            True if started successfully
        """
        try:
            # Would establish connection to actual cache server
            self._state = NodeState.ACTIVE
            self._last_heartbeat = datetime.now()
            logger.info(f"Node {self.node_id} started")
            return True

        except Exception as e:
            logger.error(f"Failed to start node {self.node_id}: {e}")
            self._state = NodeState.UNAVAILABLE
            return False

    def stop(self) -> None:
        """Stop the node."""
        self._state = NodeState.LEAVING

        if self._connection:
            # Close connection
            self._connection = None

        self._state = NodeState.DEAD
        logger.info(f"Node {self.node_id} stopped")

    def get(self, key: str) -> Optional[Any]:
        """Get value from node.

        Args:
            key: Cache key

        Returns:
            Cached value or None
        """
        if not self.is_available:
            return None

        try:
            self._stats.hits += 1
            # Would actually fetch from cache server
            return None  # Placeholder

        except Exception as e:
            self._record_failure(e)
            return None

    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Set value on node.

        Args:
            key: Cache key
            value: Value to cache
            ttl: TTL in seconds

        Returns:
            True if successful
        """
        if not self.is_available:
            return False

        try:
            # Would actually store to cache server
            return True  # Placeholder

        except Exception as e:
            self._record_failure(e)
            return False

    def delete(self, key: str) -> bool:
        """Delete from node.

        Args:
            key: Cache key

        Returns:
            True if deleted
        """
        if not self.is_available:
            return False

        try:
            # Would actually delete from cache server
            return True

        except Exception as e:
            self._record_failure(e)
            return False

    def ping(self) -> bool:
        """Ping node for health check.

        Returns:
            True if responsive
        """
        try:
            # Would send actual ping
            self._last_heartbeat = datetime.now()
            self._consecutive_failures = 0
            return True

        except Exception as e:
            self._record_failure(e)
            return False

    def _record_failure(self, error: Exception) -> None:
        """Record a failure.

        Args:
            error: The exception that occurred
        """
        self._failure_count += 1
        self._consecutive_failures += 1

        if self._consecutive_failures >= 3:
            self._state = NodeState.UNAVAILABLE
            logger.warning(
                f"Node {self.node_id} marked unavailable "
                f"after {self._consecutive_failures} failures"
            )

    def mark_available(self) -> None:
        """Mark node as available."""
        self._state = NodeState.ACTIVE
        self._consecutive_failures = 0
        self._last_heartbeat = datetime.now()

    def mark_unavailable(self) -> None:
        """Mark node as unavailable."""
        self._state = NodeState.UNAVAILABLE

    def get_stats(self) -> NodeStats:
        """Get node statistics.

        Returns:
            NodeStats instance
        """
        return self._stats

    def get_info(self) -> Dict[str, Any]:
        """Get node information.

        Returns:
            Node info dict
        """
        return {
            "node_id": self.info.node_id,
            "host": self.info.host,
            "port": self.info.port,
            "datacenter": self.info.datacenter,
            "rack": self.info.rack,
            "state": self._state.name,
            "weight": self.info.weight,
            "last_heartbeat": self._last_heartbeat.isoformat() if self._last_heartbeat else None,
        }

    def __repr__(self) -> str:
        return f"CacheNode(id={self.node_id}, state={self._state.name})"

    def __hash__(self) -> int:
        return hash(self.node_id)

    def __eq__(self, other: object) -> bool:
        if isinstance(other, CacheNode):
            return self.node_id == other.node_id
        return False


__all__ = ["CacheNode", "NodeState", "NodeInfo", "NodeStats"]

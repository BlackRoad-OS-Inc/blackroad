"""RoadCache Cluster - Distributed Cache Cluster.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Callable, Dict, List, Optional, Set

from roadcache_core.cache.entry import CacheEntry
from roadcache_core.cluster.node import CacheNode, NodeInfo, NodeState
from roadcache_core.cluster.ring import HashRing
from roadcache_core.consistency.model import (
    ConsistencyModel,
    ConsistencyLevel,
    EventualConsistency,
)

logger = logging.getLogger(__name__)


@dataclass
class ClusterConfig:
    """Cluster configuration.

    Attributes:
        name: Cluster name
        replication_factor: Number of replicas
        read_quorum: Reads required
        write_quorum: Writes required
        virtual_nodes: Virtual nodes per node
        health_check_interval: Seconds between health checks
        failure_threshold: Failures before marking unavailable
        consistency: Consistency model
    """

    name: str = "cluster"
    replication_factor: int = 3
    read_quorum: int = 2
    write_quorum: int = 2
    virtual_nodes: int = 150
    health_check_interval: float = 30.0
    failure_threshold: int = 3
    consistency: str = "eventual"


@dataclass
class ClusterStats:
    """Cluster statistics."""

    total_nodes: int = 0
    active_nodes: int = 0
    unavailable_nodes: int = 0
    total_entries: int = 0
    total_memory_bytes: int = 0
    ops_per_second: float = 0.0


class CacheCluster:
    """Distributed cache cluster.

    Manages multiple cache nodes with consistent hashing.

    Features:
    - Consistent hashing for key distribution
    - Replication for high availability
    - Automatic failover
    - Health monitoring
    - Configurable consistency

    Example:
        cluster = CacheCluster(ClusterConfig(
            name="my-cluster",
            replication_factor=3,
        ))

        cluster.add_node(node1)
        cluster.add_node(node2)
        cluster.add_node(node3)

        cluster.set("key", "value")
        value = cluster.get("key")
    """

    def __init__(self, config: Optional[ClusterConfig] = None):
        """Initialize cluster.

        Args:
            config: Cluster configuration
        """
        self.config = config or ClusterConfig()

        self._ring = HashRing(virtual_nodes=self.config.virtual_nodes)
        self._consistency: ConsistencyModel = EventualConsistency()
        self._lock = threading.RLock()

        # Health monitoring
        self._health_thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()

        # Callbacks
        self._on_node_up: Optional[Callable[[CacheNode], None]] = None
        self._on_node_down: Optional[Callable[[CacheNode], None]] = None

    def start(self) -> None:
        """Start cluster operations."""
        self._stop_event.clear()

        self._health_thread = threading.Thread(
            target=self._health_loop,
            daemon=True,
            name=f"Cluster-{self.config.name}-health",
        )
        self._health_thread.start()

        logger.info(f"Cluster {self.config.name} started")

    def stop(self) -> None:
        """Stop cluster operations."""
        self._stop_event.set()

        if self._health_thread:
            self._health_thread.join(timeout=5.0)
            self._health_thread = None

        # Stop all nodes
        for node in self._ring.get_all_nodes():
            node.stop()

        logger.info(f"Cluster {self.config.name} stopped")

    def add_node(self, node: CacheNode) -> None:
        """Add node to cluster.

        Args:
            node: Node to add
        """
        with self._lock:
            node.start()
            self._ring.add_node(node)
            logger.info(f"Added node {node.node_id} to cluster")

    def remove_node(self, node_id: str) -> None:
        """Remove node from cluster.

        Args:
            node_id: Node ID to remove
        """
        with self._lock:
            self._ring.remove_node(node_id)
            logger.info(f"Removed node {node_id} from cluster")

    def get(self, key: str) -> Optional[Any]:
        """Get value from cluster.

        Args:
            key: Cache key

        Returns:
            Cached value or None
        """
        nodes = self._ring.get_nodes(
            key,
            count=self.config.read_quorum,
            skip_unavailable=True,
        )

        if len(nodes) < self.config.read_quorum:
            logger.warning(f"Not enough nodes for read quorum: {len(nodes)}")
            # Fallback to any available node
            nodes = self._ring.get_nodes(key, count=1)

        values: Dict[str, Any] = {}
        for node in nodes:
            try:
                value = node.get(key)
                if value is not None:
                    values[node.node_id] = value
            except Exception as e:
                logger.error(f"Failed to read from {node.node_id}: {e}")

        if not values:
            return None

        # Return first value (eventual consistency)
        return next(iter(values.values()))

    def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[int] = None,
    ) -> bool:
        """Set value in cluster.

        Args:
            key: Cache key
            value: Value to cache
            ttl: TTL in seconds

        Returns:
            True if write quorum met
        """
        nodes = self._ring.get_nodes(
            key,
            count=self.config.replication_factor,
            skip_unavailable=True,
        )

        if len(nodes) < self.config.write_quorum:
            logger.error(f"Not enough nodes for write quorum: {len(nodes)}")
            return False

        success_count = 0
        for node in nodes:
            try:
                if node.set(key, value, ttl):
                    success_count += 1
            except Exception as e:
                logger.error(f"Failed to write to {node.node_id}: {e}")

        return success_count >= self.config.write_quorum

    def delete(self, key: str) -> bool:
        """Delete from cluster.

        Args:
            key: Cache key

        Returns:
            True if deleted from quorum
        """
        nodes = self._ring.get_nodes(
            key,
            count=self.config.replication_factor,
            skip_unavailable=True,
        )

        success_count = 0
        for node in nodes:
            try:
                if node.delete(key):
                    success_count += 1
            except Exception as e:
                logger.error(f"Failed to delete from {node.node_id}: {e}")

        return success_count >= self.config.write_quorum

    def get_node(self, key: str) -> Optional[CacheNode]:
        """Get primary node for key.

        Args:
            key: Cache key

        Returns:
            Primary node
        """
        return self._ring.get_node(key)

    def get_replica_nodes(self, key: str) -> List[CacheNode]:
        """Get replica nodes for key.

        Args:
            key: Cache key

        Returns:
            List of replica nodes
        """
        return self._ring.get_nodes(key, count=self.config.replication_factor)

    def _health_loop(self) -> None:
        """Background health check loop."""
        while not self._stop_event.is_set():
            try:
                self._check_health()
            except Exception as e:
                logger.error(f"Health check error: {e}")

            self._stop_event.wait(self.config.health_check_interval)

    def _check_health(self) -> None:
        """Check health of all nodes."""
        for node in self._ring.get_all_nodes():
            was_available = node.is_available

            if node.ping():
                if not was_available:
                    node.mark_available()
                    if self._on_node_up:
                        self._on_node_up(node)
                    logger.info(f"Node {node.node_id} is now available")
            else:
                if was_available:
                    node.mark_unavailable()
                    if self._on_node_down:
                        self._on_node_down(node)
                    logger.warning(f"Node {node.node_id} is now unavailable")

    def on_node_up(self, callback: Callable[[CacheNode], None]) -> "CacheCluster":
        """Set node up callback.

        Args:
            callback: Callback function

        Returns:
            Self for chaining
        """
        self._on_node_up = callback
        return self

    def on_node_down(self, callback: Callable[[CacheNode], None]) -> "CacheCluster":
        """Set node down callback.

        Args:
            callback: Callback function

        Returns:
            Self for chaining
        """
        self._on_node_down = callback
        return self

    def get_stats(self) -> ClusterStats:
        """Get cluster statistics.

        Returns:
            ClusterStats instance
        """
        nodes = self._ring.get_all_nodes()
        active = sum(1 for n in nodes if n.is_available)

        return ClusterStats(
            total_nodes=len(nodes),
            active_nodes=active,
            unavailable_nodes=len(nodes) - active,
        )

    def get_topology(self) -> Dict[str, Any]:
        """Get cluster topology.

        Returns:
            Topology information
        """
        return {
            "name": self.config.name,
            "replication_factor": self.config.replication_factor,
            "nodes": [n.get_info() for n in self._ring.get_all_nodes()],
            "ring_size": self._ring.get_ring_size(),
        }

    def __len__(self) -> int:
        """Get node count."""
        return len(self._ring)

    def __repr__(self) -> str:
        stats = self.get_stats()
        return (
            f"CacheCluster(name={self.config.name!r}, "
            f"nodes={stats.total_nodes}, active={stats.active_nodes})"
        )

    def __enter__(self) -> "CacheCluster":
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.stop()


__all__ = ["CacheCluster", "ClusterConfig", "ClusterStats"]

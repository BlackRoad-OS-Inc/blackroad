"""RoadCache Hash Ring - Consistent Hashing.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import bisect
import hashlib
import logging
import threading
from typing import Any, Dict, List, Optional, Set, Tuple

from roadcache_core.cluster.node import CacheNode

logger = logging.getLogger(__name__)


class HashRing:
    """Consistent hash ring for distributed caching.

    Maps keys to nodes using consistent hashing.
    Supports virtual nodes for even distribution.

    Properties:
    - Minimal key redistribution on node changes
    - Even load distribution with virtual nodes
    - Support for weighted nodes
    - Replication to multiple nodes

    Example:
        ring = HashRing(virtual_nodes=150)
        ring.add_node(node1)
        ring.add_node(node2)

        node = ring.get_node("my-key")
        replicas = ring.get_nodes("my-key", count=3)
    """

    def __init__(
        self,
        virtual_nodes: int = 150,
        hash_function: str = "md5",
    ):
        """Initialize hash ring.

        Args:
            virtual_nodes: Virtual nodes per real node
            hash_function: Hash function name
        """
        self.virtual_nodes = virtual_nodes
        self.hash_function = hash_function

        self._ring: List[int] = []  # Sorted hash positions
        self._ring_to_node: Dict[int, CacheNode] = {}  # Hash -> node
        self._nodes: Dict[str, CacheNode] = {}  # node_id -> node
        self._lock = threading.RLock()

    def _hash(self, key: str) -> int:
        """Hash a key.

        Args:
            key: Key to hash

        Returns:
            Hash value
        """
        if self.hash_function == "md5":
            return int(hashlib.md5(key.encode()).hexdigest(), 16)
        elif self.hash_function == "sha1":
            return int(hashlib.sha1(key.encode()).hexdigest(), 16)
        elif self.hash_function == "sha256":
            return int(hashlib.sha256(key.encode()).hexdigest()[:16], 16)
        else:
            return hash(key)

    def add_node(self, node: CacheNode) -> None:
        """Add node to ring.

        Args:
            node: Node to add
        """
        with self._lock:
            if node.node_id in self._nodes:
                return

            self._nodes[node.node_id] = node

            # Add virtual nodes based on weight
            vnode_count = self.virtual_nodes * node.info.weight // 100

            for i in range(vnode_count):
                vnode_key = f"{node.node_id}:{i}"
                hash_value = self._hash(vnode_key)

                self._ring_to_node[hash_value] = node
                bisect.insort(self._ring, hash_value)

            logger.info(
                f"Added node {node.node_id} with {vnode_count} virtual nodes"
            )

    def remove_node(self, node_id: str) -> None:
        """Remove node from ring.

        Args:
            node_id: Node ID to remove
        """
        with self._lock:
            if node_id not in self._nodes:
                return

            node = self._nodes.pop(node_id)
            vnode_count = self.virtual_nodes * node.info.weight // 100

            for i in range(vnode_count):
                vnode_key = f"{node.node_id}:{i}"
                hash_value = self._hash(vnode_key)

                if hash_value in self._ring_to_node:
                    del self._ring_to_node[hash_value]

                try:
                    self._ring.remove(hash_value)
                except ValueError:
                    pass

            logger.info(f"Removed node {node_id}")

    def get_node(self, key: str) -> Optional[CacheNode]:
        """Get node for key.

        Args:
            key: Cache key

        Returns:
            Responsible node or None
        """
        with self._lock:
            if not self._ring:
                return None

            hash_value = self._hash(key)

            # Find position on ring
            idx = bisect.bisect(self._ring, hash_value)

            # Wrap around to beginning
            if idx >= len(self._ring):
                idx = 0

            ring_pos = self._ring[idx]
            return self._ring_to_node.get(ring_pos)

    def get_nodes(
        self,
        key: str,
        count: int = 3,
        skip_unavailable: bool = True,
    ) -> List[CacheNode]:
        """Get multiple nodes for replication.

        Args:
            key: Cache key
            count: Number of nodes
            skip_unavailable: Skip unavailable nodes

        Returns:
            List of nodes
        """
        with self._lock:
            if not self._ring:
                return []

            hash_value = self._hash(key)
            idx = bisect.bisect(self._ring, hash_value)

            nodes: List[CacheNode] = []
            seen: Set[str] = set()

            # Walk the ring
            for i in range(len(self._ring)):
                ring_idx = (idx + i) % len(self._ring)
                ring_pos = self._ring[ring_idx]
                node = self._ring_to_node.get(ring_pos)

                if node and node.node_id not in seen:
                    if skip_unavailable and not node.is_available:
                        continue

                    seen.add(node.node_id)
                    nodes.append(node)

                    if len(nodes) >= count:
                        break

            return nodes

    def get_all_nodes(self) -> List[CacheNode]:
        """Get all nodes.

        Returns:
            List of all nodes
        """
        return list(self._nodes.values())

    def get_node_count(self) -> int:
        """Get number of nodes.

        Returns:
            Node count
        """
        return len(self._nodes)

    def get_ring_size(self) -> int:
        """Get ring size (total virtual nodes).

        Returns:
            Ring size
        """
        return len(self._ring)

    def get_key_distribution(
        self,
        keys: List[str],
    ) -> Dict[str, int]:
        """Get distribution of keys across nodes.

        Args:
            keys: Keys to check

        Returns:
            Dict of node_id -> key count
        """
        distribution: Dict[str, int] = {}

        for key in keys:
            node = self.get_node(key)
            if node:
                distribution[node.node_id] = distribution.get(node.node_id, 0) + 1

        return distribution

    def rebalance(self) -> Dict[str, List[str]]:
        """Calculate key migrations for rebalance.

        This is a utility method to help plan migrations
        after topology changes.

        Returns:
            Dict of target_node_id -> keys to migrate
        """
        # Would require knowing current key ownership
        # Returns empty for now as this is a planning utility
        return {}

    def __len__(self) -> int:
        """Get node count."""
        return len(self._nodes)

    def __contains__(self, node_id: str) -> bool:
        """Check if node in ring."""
        return node_id in self._nodes

    def __repr__(self) -> str:
        return f"HashRing(nodes={len(self._nodes)}, vnodes={len(self._ring)})"


__all__ = ["HashRing"]

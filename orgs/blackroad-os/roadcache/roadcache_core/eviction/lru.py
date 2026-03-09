"""RoadCache LRU Policy - Least Recently Used Eviction.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import threading
from collections import OrderedDict
from typing import Optional

from roadcache_core.eviction.policy import EvictionPolicy


class LRUPolicy(EvictionPolicy):
    """Least Recently Used eviction policy.

    Evicts the key that has not been accessed for the longest time.
    Uses an OrderedDict for O(1) operations.

    Properties:
    - Simple and effective
    - Works well for temporal locality
    - O(1) access and eviction
    - Memory efficient

    Example:
        policy = LRUPolicy(max_size=1000)
        policy.on_insert("key1")
        policy.on_access("key1")
        evict_key = policy.choose_eviction()
    """

    def __init__(self, max_size: int = 10000):
        """Initialize LRU policy.

        Args:
            max_size: Maximum entries
        """
        super().__init__(max_size)
        self._order: OrderedDict[str, bool] = OrderedDict()
        self._lock = threading.RLock()

    def on_access(self, key: str) -> None:
        """Record key access (move to end).

        Args:
            key: Accessed key
        """
        with self._lock:
            self._stats.accesses += 1
            if key in self._order:
                self._order.move_to_end(key)

    def on_insert(self, key: str) -> None:
        """Record key insertion.

        Args:
            key: Inserted key
        """
        with self._lock:
            self._order[key] = True
            self._order.move_to_end(key)
            self._stats.current_size = len(self._order)

    def on_delete(self, key: str) -> None:
        """Record key deletion.

        Args:
            key: Deleted key
        """
        with self._lock:
            if key in self._order:
                del self._order[key]
                self._stats.current_size = len(self._order)

    def choose_eviction(self) -> Optional[str]:
        """Choose LRU key to evict.

        Returns:
            Oldest key or None
        """
        with self._lock:
            if not self._order:
                return None

            # First key is LRU (oldest)
            key = next(iter(self._order))
            self._stats.evictions += 1
            return key

    def clear(self) -> None:
        """Clear all tracked keys."""
        with self._lock:
            self._order.clear()
            self._stats.current_size = 0

    def contains(self, key: str) -> bool:
        """Check if key is tracked.

        Args:
            key: Key to check

        Returns:
            True if tracked
        """
        return key in self._order

    def size(self) -> int:
        """Get number of tracked keys.

        Returns:
            Number of keys
        """
        return len(self._order)

    def peek_lru(self) -> Optional[str]:
        """Peek at LRU key without evicting.

        Returns:
            LRU key or None
        """
        with self._lock:
            if not self._order:
                return None
            return next(iter(self._order))

    def peek_mru(self) -> Optional[str]:
        """Peek at MRU key.

        Returns:
            MRU key or None
        """
        with self._lock:
            if not self._order:
                return None
            return next(reversed(self._order))

    def __repr__(self) -> str:
        return f"LRUPolicy(size={len(self._order)}, max={self.max_size})"


__all__ = ["LRUPolicy"]

"""RoadCache LFU Policy - Least Frequently Used Eviction.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import threading
from collections import defaultdict
from typing import Dict, Optional, Set

from roadcache_core.eviction.policy import EvictionPolicy


class LFUPolicy(EvictionPolicy):
    """Least Frequently Used eviction policy.

    Evicts the key with the lowest access frequency.
    Uses O(1) operations with frequency lists.

    Properties:
    - Good for frequency-based workloads
    - O(1) access and eviction
    - Handles popularity well
    - May keep old popular items too long

    Implementation:
    - Tracks frequency count per key
    - Groups keys by frequency
    - Evicts from lowest frequency group
    - Ties broken by insertion order (LRU within frequency)

    Example:
        policy = LFUPolicy(max_size=1000)
        policy.on_insert("key1")
        policy.on_access("key1")  # freq=2
        policy.on_access("key1")  # freq=3
        evict_key = policy.choose_eviction()
    """

    def __init__(self, max_size: int = 10000):
        """Initialize LFU policy.

        Args:
            max_size: Maximum entries
        """
        super().__init__(max_size)

        # Key -> frequency count
        self._frequency: Dict[str, int] = {}

        # Frequency -> set of keys (ordered by insertion)
        self._freq_to_keys: Dict[int, Set[str]] = defaultdict(set)

        # Minimum frequency (for O(1) eviction)
        self._min_freq = 0

        self._lock = threading.RLock()

    def on_access(self, key: str) -> None:
        """Record key access (increase frequency).

        Args:
            key: Accessed key
        """
        with self._lock:
            self._stats.accesses += 1

            if key not in self._frequency:
                return

            freq = self._frequency[key]

            # Remove from old frequency group
            self._freq_to_keys[freq].discard(key)
            if not self._freq_to_keys[freq]:
                del self._freq_to_keys[freq]
                if self._min_freq == freq:
                    self._min_freq = freq + 1

            # Add to new frequency group
            new_freq = freq + 1
            self._frequency[key] = new_freq
            self._freq_to_keys[new_freq].add(key)

            self._stats.promotions += 1

    def on_insert(self, key: str) -> None:
        """Record key insertion (frequency=1).

        Args:
            key: Inserted key
        """
        with self._lock:
            self._frequency[key] = 1
            self._freq_to_keys[1].add(key)
            self._min_freq = 1
            self._stats.current_size = len(self._frequency)

    def on_delete(self, key: str) -> None:
        """Record key deletion.

        Args:
            key: Deleted key
        """
        with self._lock:
            if key not in self._frequency:
                return

            freq = self._frequency[key]
            del self._frequency[key]

            self._freq_to_keys[freq].discard(key)
            if not self._freq_to_keys[freq]:
                del self._freq_to_keys[freq]

            self._stats.current_size = len(self._frequency)

    def choose_eviction(self) -> Optional[str]:
        """Choose LFU key to evict.

        Returns:
            Least frequent key or None
        """
        with self._lock:
            if not self._frequency:
                return None

            # Find minimum frequency keys
            while self._min_freq not in self._freq_to_keys or not self._freq_to_keys[self._min_freq]:
                self._min_freq += 1
                if self._min_freq > max(self._freq_to_keys.keys(), default=0):
                    return None

            # Get one key from min frequency (arbitrary order)
            keys = self._freq_to_keys[self._min_freq]
            key = next(iter(keys))

            self._stats.evictions += 1
            return key

    def clear(self) -> None:
        """Clear all tracked keys."""
        with self._lock:
            self._frequency.clear()
            self._freq_to_keys.clear()
            self._min_freq = 0
            self._stats.current_size = 0

    def contains(self, key: str) -> bool:
        """Check if key is tracked.

        Args:
            key: Key to check

        Returns:
            True if tracked
        """
        return key in self._frequency

    def size(self) -> int:
        """Get number of tracked keys.

        Returns:
            Number of keys
        """
        return len(self._frequency)

    def get_frequency(self, key: str) -> int:
        """Get access frequency for key.

        Args:
            key: Key to check

        Returns:
            Frequency count or 0
        """
        return self._frequency.get(key, 0)

    def get_min_frequency(self) -> int:
        """Get minimum frequency.

        Returns:
            Minimum frequency
        """
        return self._min_freq

    def __repr__(self) -> str:
        return f"LFUPolicy(size={len(self._frequency)}, min_freq={self._min_freq})"


__all__ = ["LFUPolicy"]

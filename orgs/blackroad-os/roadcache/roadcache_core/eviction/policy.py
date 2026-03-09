"""RoadCache Eviction Policy - Abstract Eviction Interface.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, List, Optional, Set

logger = logging.getLogger(__name__)


@dataclass
class EvictionStats:
    """Eviction policy statistics.

    Attributes:
        evictions: Number of evictions
        accesses: Number of accesses tracked
        promotions: Number of promotions
        demotions: Number of demotions
        current_size: Current tracked entries
        max_size: Maximum entries
    """

    evictions: int = 0
    accesses: int = 0
    promotions: int = 0
    demotions: int = 0
    current_size: int = 0
    max_size: int = 0

    @property
    def eviction_rate(self) -> float:
        """Get eviction rate."""
        return self.evictions / self.accesses if self.accesses > 0 else 0.0


class EvictionPolicy(ABC):
    """Abstract base for eviction policies.

    Eviction policies determine which cache entries to remove
    when the cache reaches capacity.

    Implementations:
    - LRU: Least Recently Used
    - LFU: Least Frequently Used
    - ARC: Adaptive Replacement Cache
    - FIFO: First In First Out
    - Random: Random eviction

    Example:
        policy = LRUPolicy(max_size=1000)
        policy.on_access("key1")
        policy.on_access("key2")
        evict_key = policy.choose_eviction()
    """

    def __init__(self, max_size: int = 10000):
        """Initialize policy.

        Args:
            max_size: Maximum entries to track
        """
        self.max_size = max_size
        self._stats = EvictionStats(max_size=max_size)

    @abstractmethod
    def on_access(self, key: str) -> None:
        """Record key access.

        Args:
            key: Accessed key
        """
        pass

    @abstractmethod
    def on_insert(self, key: str) -> None:
        """Record key insertion.

        Args:
            key: Inserted key
        """
        pass

    @abstractmethod
    def on_delete(self, key: str) -> None:
        """Record key deletion.

        Args:
            key: Deleted key
        """
        pass

    @abstractmethod
    def choose_eviction(self) -> Optional[str]:
        """Choose key to evict.

        Returns:
            Key to evict or None
        """
        pass

    def choose_evictions(self, count: int) -> List[str]:
        """Choose multiple keys to evict.

        Args:
            count: Number of keys

        Returns:
            List of keys to evict
        """
        keys = []
        for _ in range(count):
            key = self.choose_eviction()
            if key:
                keys.append(key)
                self.on_delete(key)
            else:
                break
        return keys

    @abstractmethod
    def clear(self) -> None:
        """Clear all tracked keys."""
        pass

    @abstractmethod
    def contains(self, key: str) -> bool:
        """Check if key is tracked.

        Args:
            key: Key to check

        Returns:
            True if tracked
        """
        pass

    @abstractmethod
    def size(self) -> int:
        """Get number of tracked keys.

        Returns:
            Number of keys
        """
        pass

    def get_stats(self) -> EvictionStats:
        """Get eviction statistics.

        Returns:
            EvictionStats instance
        """
        self._stats.current_size = self.size()
        return self._stats

    def __len__(self) -> int:
        """Get tracked key count."""
        return self.size()

    def __contains__(self, key: str) -> bool:
        """Check if key tracked."""
        return self.contains(key)


__all__ = ["EvictionPolicy", "EvictionStats"]

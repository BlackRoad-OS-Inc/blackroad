"""RoadCache ARC Policy - Adaptive Replacement Cache.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import threading
from collections import OrderedDict
from typing import Optional

from roadcache_core.eviction.policy import EvictionPolicy


class ARCPolicy(EvictionPolicy):
    """Adaptive Replacement Cache eviction policy.

    ARC automatically balances between recency (LRU) and frequency (LFU).
    It maintains four lists:
    - T1: Recent entries (LRU)
    - T2: Frequent entries (LFU-like)
    - B1: Ghost entries recently evicted from T1
    - B2: Ghost entries recently evicted from T2

    Properties:
    - Self-tuning between recency and frequency
    - Scan-resistant
    - Low overhead
    - Good for mixed workloads

    Reference:
        "ARC: A Self-Tuning, Low Overhead Replacement Cache"
        by Nimrod Megiddo and Dharmendra S. Modha

    Example:
        policy = ARCPolicy(max_size=1000)
        policy.on_insert("key1")
        policy.on_access("key1")
        evict_key = policy.choose_eviction()
    """

    def __init__(self, max_size: int = 10000):
        """Initialize ARC policy.

        Args:
            max_size: Maximum entries (for T1 + T2)
        """
        super().__init__(max_size)

        # T1: Recent entries (LRU order, newest at end)
        self._t1: OrderedDict[str, bool] = OrderedDict()

        # T2: Frequent entries (LRU order, newest at end)
        self._t2: OrderedDict[str, bool] = OrderedDict()

        # B1: Ghost entries from T1
        self._b1: OrderedDict[str, bool] = OrderedDict()

        # B2: Ghost entries from T2
        self._b2: OrderedDict[str, bool] = OrderedDict()

        # Target size for T1 (adaptation parameter)
        self._p = 0

        self._lock = threading.RLock()

    def _replace(self, in_b2: bool) -> Optional[str]:
        """Replace an entry from T1 or T2.

        Args:
            in_b2: Whether the access was in B2

        Returns:
            Key moved to ghost list
        """
        t1_size = len(self._t1)
        t2_size = len(self._t2)

        if t1_size > 0 and (
            t1_size > self._p or
            (in_b2 and t1_size == self._p)
        ):
            # Move from T1 to B1
            key = next(iter(self._t1))
            del self._t1[key]
            self._b1[key] = True
            self._b1.move_to_end(key)
            return key
        elif t2_size > 0:
            # Move from T2 to B2
            key = next(iter(self._t2))
            del self._t2[key]
            self._b2[key] = True
            self._b2.move_to_end(key)
            return key

        return None

    def on_access(self, key: str) -> None:
        """Record key access.

        Args:
            key: Accessed key
        """
        with self._lock:
            self._stats.accesses += 1

            # Case I: key in T1 (recent hit)
            if key in self._t1:
                del self._t1[key]
                self._t2[key] = True
                self._t2.move_to_end(key)
                self._stats.promotions += 1
                return

            # Case II: key in T2 (frequent hit)
            if key in self._t2:
                self._t2.move_to_end(key)
                return

    def on_insert(self, key: str) -> None:
        """Record key insertion.

        Args:
            key: Inserted key
        """
        with self._lock:
            total_size = len(self._t1) + len(self._t2)

            # Case III: key in B1 (ghost hit, recent)
            if key in self._b1:
                # Increase target for T1
                delta = max(1, len(self._b2) // max(1, len(self._b1)))
                self._p = min(self._p + delta, self.max_size)

                self._replace(in_b2=False)
                del self._b1[key]
                self._t2[key] = True
                self._t2.move_to_end(key)
                return

            # Case IV: key in B2 (ghost hit, frequent)
            if key in self._b2:
                # Decrease target for T1
                delta = max(1, len(self._b1) // max(1, len(self._b2)))
                self._p = max(self._p - delta, 0)

                self._replace(in_b2=True)
                del self._b2[key]
                self._t2[key] = True
                self._t2.move_to_end(key)
                return

            # Case V: not in any list (cache miss)
            if total_size >= self.max_size:
                # Cache is full
                if len(self._t1) + len(self._b1) >= self.max_size:
                    if len(self._b1) > 0:
                        # Remove oldest from B1
                        old_key = next(iter(self._b1))
                        del self._b1[old_key]
                    self._replace(in_b2=False)
                else:
                    total_ghost = len(self._b1) + len(self._b2)
                    if total_ghost >= self.max_size:
                        # Remove oldest from B2
                        if self._b2:
                            old_key = next(iter(self._b2))
                            del self._b2[old_key]
                    self._replace(in_b2=False)

            # Add to T1
            self._t1[key] = True
            self._t1.move_to_end(key)
            self._stats.current_size = len(self._t1) + len(self._t2)

    def on_delete(self, key: str) -> None:
        """Record key deletion.

        Args:
            key: Deleted key
        """
        with self._lock:
            if key in self._t1:
                del self._t1[key]
            elif key in self._t2:
                del self._t2[key]

            # Also remove from ghost lists
            if key in self._b1:
                del self._b1[key]
            if key in self._b2:
                del self._b2[key]

            self._stats.current_size = len(self._t1) + len(self._t2)

    def choose_eviction(self) -> Optional[str]:
        """Choose key to evict.

        Returns:
            Key to evict or None
        """
        with self._lock:
            t1_size = len(self._t1)
            t2_size = len(self._t2)

            if t1_size == 0 and t2_size == 0:
                return None

            # Prefer T1 if larger than target, else T2
            if t1_size > self._p or t2_size == 0:
                if self._t1:
                    key = next(iter(self._t1))
                    self._stats.evictions += 1
                    return key
            else:
                if self._t2:
                    key = next(iter(self._t2))
                    self._stats.evictions += 1
                    return key

            return None

    def clear(self) -> None:
        """Clear all tracked keys."""
        with self._lock:
            self._t1.clear()
            self._t2.clear()
            self._b1.clear()
            self._b2.clear()
            self._p = 0
            self._stats.current_size = 0

    def contains(self, key: str) -> bool:
        """Check if key is in cache (T1 or T2).

        Args:
            key: Key to check

        Returns:
            True if in cache
        """
        return key in self._t1 or key in self._t2

    def size(self) -> int:
        """Get number of cached keys.

        Returns:
            T1 + T2 size
        """
        return len(self._t1) + len(self._t2)

    def get_stats_detailed(self) -> dict:
        """Get detailed ARC statistics.

        Returns:
            Dict with sizes
        """
        with self._lock:
            return {
                "t1_size": len(self._t1),
                "t2_size": len(self._t2),
                "b1_size": len(self._b1),
                "b2_size": len(self._b2),
                "p_target": self._p,
            }

    def __repr__(self) -> str:
        return (
            f"ARCPolicy(T1={len(self._t1)}, T2={len(self._t2)}, "
            f"B1={len(self._b1)}, B2={len(self._b2)}, p={self._p})"
        )


__all__ = ["ARCPolicy"]

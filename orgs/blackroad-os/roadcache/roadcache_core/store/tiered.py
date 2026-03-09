"""RoadCache Tiered Store - Multi-Level Cache Storage.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

from roadcache_core.cache.entry import CacheEntry
from roadcache_core.store.backend import StorageBackend, StorageConfig

logger = logging.getLogger(__name__)


@dataclass
class TierConfig:
    """Configuration for a cache tier.

    Attributes:
        name: Tier name
        backend: Storage backend
        read_through: Read from next tier on miss
        write_through: Write to all tiers
        promotion_on_access: Promote to faster tiers
        ttl_multiplier: TTL multiplier for this tier
    """

    name: str
    backend: StorageBackend
    read_through: bool = True
    write_through: bool = True
    promotion_on_access: bool = True
    ttl_multiplier: float = 1.0


class TieredStore(StorageBackend):
    """Multi-tier cache storage.

    Implements a hierarchical caching strategy with multiple
    storage tiers (e.g., L1 memory, L2 Redis, L3 disk).

    Features:
    - Automatic tier promotion
    - Read-through caching
    - Write-through/write-behind
    - Tier-specific TTL
    - Async tier population

    Example:
        tiered = TieredStore([
            TierConfig("l1", MemoryStore()),
            TierConfig("l2", RedisStore()),
            TierConfig("l3", FileStore("/cache")),
        ])

        tiered.set("key", entry)  # Writes to all tiers
        entry = tiered.get("key")  # L1 miss -> L2 hit -> promote to L1
    """

    def __init__(
        self,
        tiers: List[TierConfig],
        config: Optional[StorageConfig] = None,
    ):
        """Initialize tiered store.

        Args:
            tiers: List of tier configurations (fastest first)
            config: Storage configuration
        """
        super().__init__(config)
        self.tiers = tiers
        self._lock = threading.RLock()

    def get(self, key: str) -> Optional[CacheEntry]:
        """Get entry, checking tiers in order.

        Args:
            key: Cache key

        Returns:
            CacheEntry or None
        """
        self._stats.reads += 1

        for i, tier in enumerate(self.tiers):
            entry = tier.backend.get(key)

            if entry is not None:
                # Promote to faster tiers
                if tier.promotion_on_access and i > 0:
                    self._promote(key, entry, i)

                return entry

        return None

    def set(self, key: str, entry: CacheEntry) -> bool:
        """Set entry across tiers.

        Args:
            key: Cache key
            entry: Cache entry

        Returns:
            True if successful
        """
        self._stats.writes += 1
        success = False

        for tier in self.tiers:
            if tier.write_through:
                # Adjust TTL for tier
                tier_entry = self._adjust_ttl(entry, tier.ttl_multiplier)
                if tier.backend.set(key, tier_entry):
                    success = True

        return success

    def delete(self, key: str) -> bool:
        """Delete from all tiers.

        Args:
            key: Cache key

        Returns:
            True if deleted from any tier
        """
        self._stats.deletes += 1
        success = False

        for tier in self.tiers:
            if tier.backend.delete(key):
                success = True

        return success

    def exists(self, key: str) -> bool:
        """Check if key exists in any tier.

        Args:
            key: Cache key

        Returns:
            True if exists
        """
        for tier in self.tiers:
            if tier.backend.exists(key):
                return True
        return False

    def clear(self) -> int:
        """Clear all tiers.

        Returns:
            Total entries cleared
        """
        total = 0
        for tier in self.tiers:
            total += tier.backend.clear()
        return total

    def keys(self, pattern: Optional[str] = None) -> List[str]:
        """Get keys from all tiers.

        Args:
            pattern: Optional pattern

        Returns:
            Unique keys from all tiers
        """
        all_keys = set()
        for tier in self.tiers:
            all_keys.update(tier.backend.keys(pattern))
        return list(all_keys)

    def size(self) -> int:
        """Get total unique keys.

        Returns:
            Number of unique keys
        """
        return len(self.keys())

    def _promote(self, key: str, entry: CacheEntry, from_tier: int) -> None:
        """Promote entry to faster tiers.

        Args:
            key: Cache key
            entry: Entry to promote
            from_tier: Index of source tier
        """
        for i in range(from_tier):
            tier = self.tiers[i]
            tier_entry = self._adjust_ttl(entry, tier.ttl_multiplier)
            tier.backend.set(key, tier_entry)

    def _adjust_ttl(self, entry: CacheEntry, multiplier: float) -> CacheEntry:
        """Adjust entry TTL for tier.

        Args:
            entry: Original entry
            multiplier: TTL multiplier

        Returns:
            Entry with adjusted TTL
        """
        if entry.ttl_seconds is None or multiplier == 1.0:
            return entry

        # Create copy with adjusted TTL
        adjusted = CacheEntry(
            key=entry.key,
            value=entry.value,
            ttl_seconds=entry.ttl_seconds * multiplier,
            state=entry.state,
            metadata=entry.metadata,
            namespace=entry.namespace,
        )
        return adjusted

    def get_tier_stats(self) -> List[Dict[str, Any]]:
        """Get stats for each tier.

        Returns:
            List of tier stats
        """
        return [
            {
                "name": tier.name,
                "stats": tier.backend.get_stats(),
                "size": tier.backend.size(),
            }
            for tier in self.tiers
        ]

    def warm_tier(self, tier_index: int, keys: List[str]) -> int:
        """Warm a tier with entries from slower tiers.

        Args:
            tier_index: Target tier index
            keys: Keys to warm

        Returns:
            Number of entries warmed
        """
        if tier_index >= len(self.tiers) - 1:
            return 0

        target_tier = self.tiers[tier_index]
        count = 0

        for key in keys:
            # Look in slower tiers
            for i in range(tier_index + 1, len(self.tiers)):
                entry = self.tiers[i].backend.get(key)
                if entry is not None:
                    tier_entry = self._adjust_ttl(entry, target_tier.ttl_multiplier)
                    if target_tier.backend.set(key, tier_entry):
                        count += 1
                    break

        return count

    def __repr__(self) -> str:
        tier_names = [t.name for t in self.tiers]
        return f"TieredStore(tiers={tier_names})"


__all__ = ["TieredStore", "TierConfig"]

"""RoadCache Memory Store - In-Memory Storage Backend.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import fnmatch
import logging
import threading
from typing import Dict, List, Optional

from roadcache_core.cache.entry import CacheEntry
from roadcache_core.store.backend import StorageBackend, StorageConfig, StorageStats

logger = logging.getLogger(__name__)


class MemoryStore(StorageBackend):
    """In-memory storage backend.

    The simplest and fastest storage option, keeping all data in memory.
    Best for single-process applications with moderate cache sizes.

    Features:
    - O(1) get/set/delete operations
    - Thread-safe with RLock
    - Pattern-based key scanning
    - Memory tracking

    Example:
        store = MemoryStore(StorageConfig(max_size=10000))
        store.set("key", CacheEntry(key="key", value="data"))
        entry = store.get("key")
    """

    def __init__(self, config: Optional[StorageConfig] = None):
        """Initialize memory store.

        Args:
            config: Storage configuration
        """
        super().__init__(config)
        self._data: Dict[str, CacheEntry] = {}
        self._lock = threading.RLock()

    def get(self, key: str) -> Optional[CacheEntry]:
        """Get entry by key.

        Args:
            key: Cache key

        Returns:
            CacheEntry or None
        """
        with self._lock:
            self._stats.reads += 1
            return self._data.get(key)

    def set(self, key: str, entry: CacheEntry) -> bool:
        """Store entry.

        Args:
            key: Cache key
            entry: Cache entry

        Returns:
            True if successful
        """
        try:
            with self._lock:
                # Check max size
                if self.config.max_size:
                    if key not in self._data and len(self._data) >= self.config.max_size:
                        return False

                # Check memory limit
                if self.config.max_memory_bytes:
                    current_size = sum(e.metadata.size_bytes for e in self._data.values())
                    if current_size + entry.metadata.size_bytes > self.config.max_memory_bytes:
                        return False

                self._data[key] = entry
                self._stats.writes += 1
                self._stats.entry_count = len(self._data)
                return True

        except Exception as e:
            self._stats.record_error(str(e))
            return False

    def delete(self, key: str) -> bool:
        """Delete entry.

        Args:
            key: Cache key

        Returns:
            True if deleted
        """
        with self._lock:
            if key in self._data:
                del self._data[key]
                self._stats.deletes += 1
                self._stats.entry_count = len(self._data)
                return True
            return False

    def exists(self, key: str) -> bool:
        """Check if key exists.

        Args:
            key: Cache key

        Returns:
            True if exists
        """
        return key in self._data

    def clear(self) -> int:
        """Clear all entries.

        Returns:
            Number cleared
        """
        with self._lock:
            count = len(self._data)
            self._data.clear()
            self._stats.entry_count = 0
            return count

    def keys(self, pattern: Optional[str] = None) -> List[str]:
        """Get all keys.

        Args:
            pattern: Optional glob pattern

        Returns:
            List of keys
        """
        with self._lock:
            if pattern is None:
                return list(self._data.keys())
            return [k for k in self._data.keys() if fnmatch.fnmatch(k, pattern)]

    def size(self) -> int:
        """Get entry count.

        Returns:
            Number of entries
        """
        return len(self._data)

    def memory_usage(self) -> int:
        """Get total memory usage.

        Returns:
            Size in bytes
        """
        with self._lock:
            return sum(e.metadata.size_bytes for e in self._data.values())

    def __repr__(self) -> str:
        return f"MemoryStore(entries={len(self._data)})"


__all__ = ["MemoryStore"]

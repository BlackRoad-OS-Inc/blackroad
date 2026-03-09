"""RoadCache Storage Backend - Abstract Storage Interface.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, Iterator, List, Optional, Tuple

from roadcache_core.cache.entry import CacheEntry

logger = logging.getLogger(__name__)


@dataclass
class StorageConfig:
    """Storage backend configuration.

    Attributes:
        name: Backend name
        max_size: Maximum entries
        max_memory_bytes: Maximum memory
        serializer: Serializer type
        compression: Enable compression
        sync_writes: Synchronous writes
    """

    name: str = "storage"
    max_size: Optional[int] = None
    max_memory_bytes: Optional[int] = None
    serializer: str = "pickle"
    compression: bool = False
    sync_writes: bool = True


@dataclass
class StorageStats:
    """Storage backend statistics.

    Attributes:
        reads: Number of read operations
        writes: Number of write operations
        deletes: Number of delete operations
        entry_count: Current entry count
        size_bytes: Current size in bytes
        errors: Number of errors
    """

    reads: int = 0
    writes: int = 0
    deletes: int = 0
    entry_count: int = 0
    size_bytes: int = 0
    errors: int = 0
    last_error: Optional[str] = None
    last_error_at: Optional[datetime] = None

    def record_error(self, error: str) -> None:
        """Record an error."""
        self.errors += 1
        self.last_error = error
        self.last_error_at = datetime.now()


class StorageBackend(ABC):
    """Abstract storage backend for cache persistence.

    Implementations provide different storage strategies:
    - MemoryStore: In-process dictionary
    - FileStore: File-based persistence
    - RedisStore: Redis backend
    - SQLStore: SQL database backend

    All backends implement the same interface for consistent usage.
    """

    def __init__(self, config: Optional[StorageConfig] = None):
        """Initialize backend.

        Args:
            config: Storage configuration
        """
        self.config = config or StorageConfig()
        self._stats = StorageStats()

    @abstractmethod
    def get(self, key: str) -> Optional[CacheEntry]:
        """Get entry by key.

        Args:
            key: Cache key

        Returns:
            CacheEntry or None
        """
        pass

    @abstractmethod
    def set(self, key: str, entry: CacheEntry) -> bool:
        """Store entry.

        Args:
            key: Cache key
            entry: Cache entry

        Returns:
            True if successful
        """
        pass

    @abstractmethod
    def delete(self, key: str) -> bool:
        """Delete entry.

        Args:
            key: Cache key

        Returns:
            True if deleted
        """
        pass

    @abstractmethod
    def exists(self, key: str) -> bool:
        """Check if key exists.

        Args:
            key: Cache key

        Returns:
            True if exists
        """
        pass

    @abstractmethod
    def clear(self) -> int:
        """Clear all entries.

        Returns:
            Number cleared
        """
        pass

    @abstractmethod
    def keys(self, pattern: Optional[str] = None) -> List[str]:
        """Get all keys.

        Args:
            pattern: Optional pattern

        Returns:
            List of keys
        """
        pass

    @abstractmethod
    def size(self) -> int:
        """Get entry count.

        Returns:
            Number of entries
        """
        pass

    def get_many(self, keys: List[str]) -> Dict[str, CacheEntry]:
        """Get multiple entries.

        Args:
            keys: List of keys

        Returns:
            Dict of key -> entry
        """
        result = {}
        for key in keys:
            entry = self.get(key)
            if entry is not None:
                result[key] = entry
        return result

    def set_many(self, entries: Dict[str, CacheEntry]) -> int:
        """Store multiple entries.

        Args:
            entries: Dict of key -> entry

        Returns:
            Number stored
        """
        count = 0
        for key, entry in entries.items():
            if self.set(key, entry):
                count += 1
        return count

    def delete_many(self, keys: List[str]) -> int:
        """Delete multiple entries.

        Args:
            keys: Keys to delete

        Returns:
            Number deleted
        """
        count = 0
        for key in keys:
            if self.delete(key):
                count += 1
        return count

    def scan(
        self,
        pattern: Optional[str] = None,
        count: int = 100,
    ) -> Iterator[Tuple[str, CacheEntry]]:
        """Scan entries.

        Args:
            pattern: Key pattern
            count: Batch size

        Yields:
            (key, entry) tuples
        """
        for key in self.keys(pattern):
            entry = self.get(key)
            if entry is not None:
                yield key, entry

    def touch(self, key: str) -> bool:
        """Update key access time.

        Args:
            key: Cache key

        Returns:
            True if successful
        """
        entry = self.get(key)
        if entry is None:
            return False
        entry.touch()
        return self.set(key, entry)

    def get_stats(self) -> StorageStats:
        """Get storage statistics.

        Returns:
            StorageStats instance
        """
        return self._stats

    def reset_stats(self) -> None:
        """Reset statistics."""
        self._stats = StorageStats()

    def health_check(self) -> bool:
        """Check storage health.

        Returns:
            True if healthy
        """
        try:
            # Simple write/read/delete test
            test_key = "__health_check__"
            test_entry = CacheEntry(key=test_key, value="test")
            self.set(test_key, test_entry)
            result = self.get(test_key)
            self.delete(test_key)
            return result is not None
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return False

    def __contains__(self, key: str) -> bool:
        """Check if key exists."""
        return self.exists(key)

    def __len__(self) -> int:
        """Get entry count."""
        return self.size()

    def __iter__(self) -> Iterator[str]:
        """Iterate over keys."""
        return iter(self.keys())


__all__ = ["StorageBackend", "StorageConfig", "StorageStats"]

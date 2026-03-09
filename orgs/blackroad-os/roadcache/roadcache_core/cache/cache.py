"""RoadCache Cache - Main Cache Implementation.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import functools
import logging
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, Iterator, List, Optional, Set, Tuple, Union

from roadcache_core.cache.entry import CacheEntry, EntryState, EntryMetadata

logger = logging.getLogger(__name__)


class WriteMode(Enum):
    """Cache write modes."""

    WRITE_THROUGH = auto()    # Write to cache and backend
    WRITE_BEHIND = auto()     # Write to cache, async to backend
    WRITE_AROUND = auto()     # Write to backend, invalidate cache
    REFRESH_AHEAD = auto()    # Proactively refresh before expiry


@dataclass
class CacheConfig:
    """Cache configuration.

    Attributes:
        name: Cache name
        max_size: Maximum entries
        max_memory_bytes: Maximum memory usage
        default_ttl: Default TTL in seconds
        eviction_policy: Eviction policy name
        write_mode: Write mode
        enable_stats: Enable statistics
        enable_compression: Enable value compression
        compression_threshold: Bytes threshold for compression
        cleanup_interval: Seconds between cleanup runs
    """

    name: str = "cache"
    max_size: int = 10000
    max_memory_bytes: Optional[int] = None
    default_ttl: Optional[float] = None
    eviction_policy: str = "lru"
    write_mode: WriteMode = WriteMode.WRITE_THROUGH
    enable_stats: bool = True
    enable_compression: bool = False
    compression_threshold: int = 1024
    cleanup_interval: float = 60.0


@dataclass
class CacheStats:
    """Cache statistics.

    Attributes:
        hits: Number of cache hits
        misses: Number of cache misses
        sets: Number of set operations
        deletes: Number of delete operations
        evictions: Number of evictions
        expirations: Number of expirations
        entry_count: Current entry count
        size_bytes: Current size in bytes
        started_at: When cache started
    """

    hits: int = 0
    misses: int = 0
    sets: int = 0
    deletes: int = 0
    evictions: int = 0
    expirations: int = 0
    entry_count: int = 0
    size_bytes: int = 0
    started_at: Optional[datetime] = None

    @property
    def hit_rate(self) -> float:
        """Calculate hit rate."""
        total = self.hits + self.misses
        return self.hits / total if total > 0 else 0.0

    @property
    def total_operations(self) -> int:
        """Get total operations."""
        return self.hits + self.misses + self.sets + self.deletes

    def reset(self) -> None:
        """Reset statistics."""
        self.hits = 0
        self.misses = 0
        self.sets = 0
        self.deletes = 0
        self.evictions = 0
        self.expirations = 0

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "hits": self.hits,
            "misses": self.misses,
            "sets": self.sets,
            "deletes": self.deletes,
            "evictions": self.evictions,
            "expirations": self.expirations,
            "entry_count": self.entry_count,
            "size_bytes": self.size_bytes,
            "hit_rate": self.hit_rate,
            "total_operations": self.total_operations,
        }


class Cache:
    """High-performance in-memory cache.

    Features:
    - Multiple eviction policies (LRU, LFU, ARC)
    - TTL-based expiration
    - Namespacing for key isolation
    - Statistics and monitoring
    - Write-through and write-behind modes
    - Compression support
    - Thread-safe operations

    Example:
        cache = Cache(CacheConfig(max_size=1000))

        # Basic operations
        cache.set("key", "value", ttl=300)
        value = cache.get("key")

        # With namespaces
        users = cache.namespace("users")
        users.set("1", user_data)

        # Decorator
        @cache.cached(ttl=60)
        def expensive_operation(id):
            return compute(id)
    """

    def __init__(
        self,
        config: Optional[CacheConfig] = None,
        store: Optional[Any] = None,  # StorageBackend
        eviction: Optional[Any] = None,  # EvictionPolicy
    ):
        """Initialize cache.

        Args:
            config: Cache configuration
            store: Storage backend
            eviction: Eviction policy
        """
        self.config = config or CacheConfig()
        self._store = store
        self._eviction = eviction

        self._entries: Dict[str, CacheEntry] = {}
        self._lock = threading.RLock()
        self._stats = CacheStats(started_at=datetime.now())

        # LRU tracking (simple doubly-linked list)
        self._access_order: List[str] = []

        # Namespace manager (lazy init)
        self._namespace_manager: Optional[Any] = None

        # Cleanup thread
        self._cleanup_thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()

        # Callbacks
        self._on_evict: Optional[Callable[[str, Any], None]] = None
        self._on_expire: Optional[Callable[[str, Any], None]] = None

    def start(self) -> None:
        """Start cache background tasks."""
        if self._cleanup_thread is not None:
            return

        self._stop_event.clear()
        self._cleanup_thread = threading.Thread(
            target=self._cleanup_loop,
            daemon=True,
            name=f"Cache-{self.config.name}-cleanup",
        )
        self._cleanup_thread.start()
        logger.info(f"Cache {self.config.name} started")

    def stop(self) -> None:
        """Stop cache background tasks."""
        self._stop_event.set()
        if self._cleanup_thread:
            self._cleanup_thread.join(timeout=5.0)
            self._cleanup_thread = None
        logger.info(f"Cache {self.config.name} stopped")

    def get(self, key: str, default: Any = None) -> Any:
        """Get value from cache.

        Args:
            key: Cache key
            default: Default value if not found

        Returns:
            Cached value or default
        """
        with self._lock:
            entry = self._entries.get(key)

            if entry is None:
                self._stats.misses += 1
                return default

            # Check expiration
            if entry.is_expired:
                self._remove_entry(key, reason="expired")
                self._stats.misses += 1
                self._stats.expirations += 1
                return default

            # Update access
            entry.touch()
            self._update_access_order(key)
            self._stats.hits += 1

            return entry.value

    def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[float] = None,
        tags: Optional[Dict[str, str]] = None,
        if_not_exists: bool = False,
        if_exists: bool = False,
    ) -> bool:
        """Set value in cache.

        Args:
            key: Cache key
            value: Value to cache
            ttl: TTL in seconds
            tags: Optional tags
            if_not_exists: Only set if key doesn't exist
            if_exists: Only set if key exists

        Returns:
            True if successful
        """
        with self._lock:
            exists = key in self._entries

            if if_not_exists and exists:
                return False
            if if_exists and not exists:
                return False

            # Check capacity
            if not exists and len(self._entries) >= self.config.max_size:
                self._evict_one()

            # Create entry
            ttl = ttl if ttl is not None else self.config.default_ttl
            metadata = EntryMetadata(tags=tags or {})

            entry = CacheEntry(
                key=key,
                value=value,
                ttl_seconds=ttl,
                metadata=metadata,
            )

            self._entries[key] = entry
            self._update_access_order(key)
            self._stats.sets += 1
            self._stats.entry_count = len(self._entries)

            # Update size
            self._stats.size_bytes += entry.metadata.size_bytes

            return True

    def delete(self, key: str) -> bool:
        """Delete key from cache.

        Args:
            key: Cache key

        Returns:
            True if deleted
        """
        with self._lock:
            if key not in self._entries:
                return False

            self._remove_entry(key, reason="deleted")
            self._stats.deletes += 1
            return True

    def exists(self, key: str) -> bool:
        """Check if key exists.

        Args:
            key: Cache key

        Returns:
            True if exists and valid
        """
        with self._lock:
            entry = self._entries.get(key)
            return entry is not None and entry.is_valid

    def clear(self) -> int:
        """Clear all entries.

        Returns:
            Number of entries cleared
        """
        with self._lock:
            count = len(self._entries)
            self._entries.clear()
            self._access_order.clear()
            self._stats.entry_count = 0
            self._stats.size_bytes = 0
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
                return list(self._entries.keys())

            import fnmatch
            return [k for k in self._entries.keys() if fnmatch.fnmatch(k, pattern)]

    def values(self) -> List[Any]:
        """Get all values.

        Returns:
            List of values
        """
        with self._lock:
            return [e.value for e in self._entries.values() if e.is_valid]

    def items(self) -> List[Tuple[str, Any]]:
        """Get all key-value pairs.

        Returns:
            List of (key, value) tuples
        """
        with self._lock:
            return [(k, e.value) for k, e in self._entries.items() if e.is_valid]

    def size(self) -> int:
        """Get entry count.

        Returns:
            Number of entries
        """
        return len(self._entries)

    def get_many(self, keys: List[str]) -> Dict[str, Any]:
        """Get multiple values.

        Args:
            keys: List of keys

        Returns:
            Dict of key -> value
        """
        result = {}
        for key in keys:
            value = self.get(key)
            if value is not None:
                result[key] = value
        return result

    def set_many(
        self,
        items: Dict[str, Any],
        ttl: Optional[float] = None,
    ) -> int:
        """Set multiple values.

        Args:
            items: Dict of key -> value
            ttl: TTL for all items

        Returns:
            Number of items set
        """
        count = 0
        for key, value in items.items():
            if self.set(key, value, ttl=ttl):
                count += 1
        return count

    def delete_many(self, keys: List[str]) -> int:
        """Delete multiple keys.

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

    def get_or_set(
        self,
        key: str,
        default_factory: Callable[[], Any],
        ttl: Optional[float] = None,
    ) -> Any:
        """Get value or set from factory.

        Args:
            key: Cache key
            default_factory: Factory to create value
            ttl: TTL for new value

        Returns:
            Cached or created value
        """
        value = self.get(key)
        if value is not None:
            return value

        value = default_factory()
        self.set(key, value, ttl=ttl)
        return value

    def increment(self, key: str, delta: int = 1) -> int:
        """Increment numeric value.

        Args:
            key: Cache key
            delta: Amount to increment

        Returns:
            New value
        """
        with self._lock:
            entry = self._entries.get(key)
            if entry is None:
                self.set(key, delta)
                return delta

            new_value = int(entry.value) + delta
            entry.update_value(new_value)
            return new_value

    def decrement(self, key: str, delta: int = 1) -> int:
        """Decrement numeric value.

        Args:
            key: Cache key
            delta: Amount to decrement

        Returns:
            New value
        """
        return self.increment(key, -delta)

    def touch(self, key: str, ttl: Optional[float] = None) -> bool:
        """Update key TTL.

        Args:
            key: Cache key
            ttl: New TTL

        Returns:
            True if successful
        """
        with self._lock:
            entry = self._entries.get(key)
            if entry is None:
                return False

            entry.refresh_ttl(ttl)
            return True

    def get_entry(self, key: str) -> Optional[CacheEntry]:
        """Get full cache entry.

        Args:
            key: Cache key

        Returns:
            CacheEntry or None
        """
        return self._entries.get(key)

    def namespace(self, name: str) -> Any:  # Namespace
        """Get or create namespace.

        Args:
            name: Namespace name

        Returns:
            Namespace instance
        """
        if self._namespace_manager is None:
            from roadcache_core.cache.namespace import NamespaceManager
            self._namespace_manager = NamespaceManager(self)

        return self._namespace_manager.create(name)

    def cached(
        self,
        ttl: Optional[float] = None,
        key_builder: Optional[Callable[..., str]] = None,
        namespace: Optional[str] = None,
    ):
        """Decorator to cache function results.

        Args:
            ttl: Cache TTL
            key_builder: Function to build cache key
            namespace: Cache namespace

        Returns:
            Decorator function
        """
        def decorator(func: Callable) -> Callable:
            @functools.wraps(func)
            def wrapper(*args, **kwargs):
                # Build cache key
                if key_builder:
                    cache_key = key_builder(*args, **kwargs)
                else:
                    key_parts = [func.__name__]
                    key_parts.extend(str(a) for a in args)
                    key_parts.extend(f"{k}={v}" for k, v in sorted(kwargs.items()))
                    cache_key = ":".join(key_parts)

                if namespace:
                    cache_key = f"{namespace}:{cache_key}"

                # Try cache
                cached_value = self.get(cache_key)
                if cached_value is not None:
                    return cached_value

                # Execute and cache
                result = func(*args, **kwargs)
                self.set(cache_key, result, ttl=ttl)
                return result

            # Add cache control methods
            def cache_clear():
                """Clear cached results."""
                pattern = f"{func.__name__}:*"
                keys = self.keys(pattern)
                self.delete_many(keys)

            wrapper.cache_clear = cache_clear
            wrapper.cache = self
            return wrapper

        return decorator

    def _update_access_order(self, key: str) -> None:
        """Update LRU access order."""
        if key in self._access_order:
            self._access_order.remove(key)
        self._access_order.append(key)

    def _evict_one(self) -> bool:
        """Evict one entry using LRU.

        Returns:
            True if evicted
        """
        if not self._access_order:
            return False

        # LRU: remove least recently used (first in list)
        key = self._access_order[0]
        self._remove_entry(key, reason="evicted")
        self._stats.evictions += 1
        return True

    def _remove_entry(self, key: str, reason: str = "removed") -> None:
        """Remove entry and cleanup."""
        entry = self._entries.pop(key, None)
        if entry:
            self._stats.size_bytes -= entry.metadata.size_bytes
            self._stats.entry_count = len(self._entries)

            if key in self._access_order:
                self._access_order.remove(key)

            # Callbacks
            if reason == "evicted" and self._on_evict:
                self._on_evict(key, entry.value)
            elif reason == "expired" and self._on_expire:
                self._on_expire(key, entry.value)

    def _cleanup_loop(self) -> None:
        """Background cleanup loop."""
        while not self._stop_event.is_set():
            try:
                self._cleanup_expired()
            except Exception as e:
                logger.error(f"Cleanup error: {e}")

            self._stop_event.wait(self.config.cleanup_interval)

    def _cleanup_expired(self) -> int:
        """Remove expired entries.

        Returns:
            Number removed
        """
        count = 0
        with self._lock:
            for key in list(self._entries.keys()):
                entry = self._entries[key]
                if entry.is_expired:
                    self._remove_entry(key, reason="expired")
                    self._stats.expirations += 1
                    count += 1
        return count

    def on_evict(self, callback: Callable[[str, Any], None]) -> "Cache":
        """Set eviction callback.

        Args:
            callback: Function(key, value)

        Returns:
            Self for chaining
        """
        self._on_evict = callback
        return self

    def on_expire(self, callback: Callable[[str, Any], None]) -> "Cache":
        """Set expiration callback.

        Args:
            callback: Function(key, value)

        Returns:
            Self for chaining
        """
        self._on_expire = callback
        return self

    def get_stats(self) -> CacheStats:
        """Get cache statistics.

        Returns:
            CacheStats instance
        """
        self._stats.entry_count = len(self._entries)
        return self._stats

    def reset_stats(self) -> None:
        """Reset statistics."""
        self._stats.reset()

    def __contains__(self, key: str) -> bool:
        """Check if key in cache."""
        return self.exists(key)

    def __len__(self) -> int:
        """Get entry count."""
        return self.size()

    def __iter__(self) -> Iterator[str]:
        """Iterate over keys."""
        return iter(self.keys())

    def __getitem__(self, key: str) -> Any:
        """Get item by key."""
        value = self.get(key)
        if value is None:
            raise KeyError(key)
        return value

    def __setitem__(self, key: str, value: Any) -> None:
        """Set item by key."""
        self.set(key, value)

    def __delitem__(self, key: str) -> None:
        """Delete item by key."""
        if not self.delete(key):
            raise KeyError(key)

    def __enter__(self) -> "Cache":
        """Context manager entry."""
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """Context manager exit."""
        self.stop()

    def __repr__(self) -> str:
        return f"Cache(name={self.config.name!r}, entries={len(self._entries)})"


__all__ = ["Cache", "CacheConfig", "CacheStats", "WriteMode"]

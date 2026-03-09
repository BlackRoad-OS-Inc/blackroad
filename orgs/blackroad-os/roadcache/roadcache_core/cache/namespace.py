"""RoadCache Namespace - Cache Namespace and Isolation.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import threading
import time
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Callable, Dict, Iterator, List, Optional, Set, TYPE_CHECKING

if TYPE_CHECKING:
    from roadcache_core.cache.cache import Cache


@dataclass
class NamespaceConfig:
    """Configuration for a namespace.

    Attributes:
        name: Namespace name
        max_size: Maximum entries
        default_ttl: Default TTL in seconds
        eviction_policy: Eviction policy name
        read_only: Whether namespace is read-only
        isolated: Whether namespace is isolated
        prefix: Key prefix
    """

    name: str
    max_size: Optional[int] = None
    default_ttl: Optional[float] = None
    eviction_policy: Optional[str] = None
    read_only: bool = False
    isolated: bool = True
    prefix: str = ""


@dataclass
class NamespaceStats:
    """Statistics for a namespace."""

    name: str
    entry_count: int = 0
    size_bytes: int = 0
    hits: int = 0
    misses: int = 0
    evictions: int = 0
    created_at: Optional[datetime] = None

    @property
    def hit_rate(self) -> float:
        """Get hit rate."""
        total = self.hits + self.misses
        return self.hits / total if total > 0 else 0.0


class Namespace:
    """Cache namespace for key isolation.

    Namespaces provide logical separation of cache entries,
    allowing independent management and different policies.

    Features:
    - Key prefixing
    - Independent TTL defaults
    - Isolated eviction
    - Statistics per namespace
    - Read-only mode
    """

    def __init__(
        self,
        cache: "Cache",
        name: str,
        config: Optional[NamespaceConfig] = None,
    ):
        """Initialize namespace.

        Args:
            cache: Parent cache
            name: Namespace name
            config: Namespace configuration
        """
        self._cache = cache
        self.name = name
        self.config = config or NamespaceConfig(name=name)

        self._stats = NamespaceStats(name=name, created_at=datetime.now())
        self._keys: Set[str] = set()
        self._lock = threading.RLock()

    def _make_key(self, key: str) -> str:
        """Make namespaced key.

        Args:
            key: Original key

        Returns:
            Namespaced key
        """
        prefix = self.config.prefix or self.name
        return f"{prefix}:{key}"

    def get(self, key: str, default: Any = None) -> Any:
        """Get value from namespace.

        Args:
            key: Cache key
            default: Default value if not found

        Returns:
            Cached value or default
        """
        ns_key = self._make_key(key)
        value = self._cache.get(ns_key, default)

        with self._lock:
            if value != default:
                self._stats.hits += 1
            else:
                self._stats.misses += 1

        return value

    def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[float] = None,
        **kwargs,
    ) -> bool:
        """Set value in namespace.

        Args:
            key: Cache key
            value: Value to cache
            ttl: TTL in seconds
            **kwargs: Additional arguments

        Returns:
            True if successful

        Raises:
            ValueError: If namespace is read-only
        """
        if self.config.read_only:
            raise ValueError(f"Namespace '{self.name}' is read-only")

        ns_key = self._make_key(key)
        ttl = ttl or self.config.default_ttl

        success = self._cache.set(ns_key, value, ttl=ttl, **kwargs)

        if success:
            with self._lock:
                self._keys.add(ns_key)
                self._stats.entry_count = len(self._keys)

        return success

    def delete(self, key: str) -> bool:
        """Delete key from namespace.

        Args:
            key: Cache key

        Returns:
            True if deleted

        Raises:
            ValueError: If namespace is read-only
        """
        if self.config.read_only:
            raise ValueError(f"Namespace '{self.name}' is read-only")

        ns_key = self._make_key(key)
        success = self._cache.delete(ns_key)

        if success:
            with self._lock:
                self._keys.discard(ns_key)
                self._stats.entry_count = len(self._keys)

        return success

    def exists(self, key: str) -> bool:
        """Check if key exists in namespace.

        Args:
            key: Cache key

        Returns:
            True if exists
        """
        ns_key = self._make_key(key)
        return self._cache.exists(ns_key)

    def clear(self) -> int:
        """Clear all entries in namespace.

        Returns:
            Number of entries cleared

        Raises:
            ValueError: If namespace is read-only
        """
        if self.config.read_only:
            raise ValueError(f"Namespace '{self.name}' is read-only")

        count = 0
        with self._lock:
            for key in list(self._keys):
                if self._cache.delete(key):
                    count += 1
            self._keys.clear()
            self._stats.entry_count = 0

        return count

    def keys(self) -> List[str]:
        """Get all keys in namespace.

        Returns:
            List of keys (without prefix)
        """
        prefix = self.config.prefix or self.name
        prefix_len = len(prefix) + 1

        with self._lock:
            return [k[prefix_len:] for k in self._keys]

    def size(self) -> int:
        """Get number of entries.

        Returns:
            Entry count
        """
        return len(self._keys)

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

    def set_many(self, items: Dict[str, Any], ttl: Optional[float] = None) -> int:
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
            Number of keys deleted
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
        ns_key = self._make_key(key)
        return self._cache.increment(ns_key, delta)

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
        ns_key = self._make_key(key)
        return self._cache.touch(ns_key, ttl)

    def get_stats(self) -> NamespaceStats:
        """Get namespace statistics.

        Returns:
            NamespaceStats
        """
        with self._lock:
            return self._stats

    def __contains__(self, key: str) -> bool:
        """Check if key in namespace."""
        return self.exists(key)

    def __len__(self) -> int:
        """Get entry count."""
        return self.size()

    def __iter__(self) -> Iterator[str]:
        """Iterate over keys."""
        return iter(self.keys())

    def __repr__(self) -> str:
        return f"Namespace(name={self.name!r}, entries={len(self._keys)})"


class NamespaceManager:
    """Manager for cache namespaces.

    Provides centralized management of namespaces with:
    - Namespace creation and deletion
    - Default namespace handling
    - Namespace discovery
    - Cross-namespace operations
    """

    DEFAULT_NAMESPACE = "default"

    def __init__(self, cache: "Cache"):
        """Initialize manager.

        Args:
            cache: Parent cache
        """
        self._cache = cache
        self._namespaces: Dict[str, Namespace] = {}
        self._configs: Dict[str, NamespaceConfig] = {}
        self._lock = threading.RLock()

        # Create default namespace
        self.create(self.DEFAULT_NAMESPACE)

    def create(
        self,
        name: str,
        config: Optional[NamespaceConfig] = None,
    ) -> Namespace:
        """Create or get namespace.

        Args:
            name: Namespace name
            config: Optional configuration

        Returns:
            Namespace instance
        """
        with self._lock:
            if name in self._namespaces:
                return self._namespaces[name]

            config = config or NamespaceConfig(name=name)
            namespace = Namespace(self._cache, name, config)
            self._namespaces[name] = namespace
            self._configs[name] = config

            return namespace

    def get(self, name: str) -> Optional[Namespace]:
        """Get namespace by name.

        Args:
            name: Namespace name

        Returns:
            Namespace or None
        """
        return self._namespaces.get(name)

    def delete(self, name: str, clear: bool = True) -> bool:
        """Delete namespace.

        Args:
            name: Namespace name
            clear: Clear entries before deletion

        Returns:
            True if deleted
        """
        if name == self.DEFAULT_NAMESPACE:
            return False

        with self._lock:
            if name not in self._namespaces:
                return False

            namespace = self._namespaces[name]
            if clear:
                namespace.clear()

            del self._namespaces[name]
            del self._configs[name]

            return True

    def exists(self, name: str) -> bool:
        """Check if namespace exists.

        Args:
            name: Namespace name

        Returns:
            True if exists
        """
        return name in self._namespaces

    def list(self) -> List[str]:
        """List all namespaces.

        Returns:
            List of namespace names
        """
        return list(self._namespaces.keys())

    def clear_all(self) -> int:
        """Clear all namespaces.

        Returns:
            Total entries cleared
        """
        total = 0
        with self._lock:
            for namespace in self._namespaces.values():
                if not namespace.config.read_only:
                    total += namespace.clear()
        return total

    def get_all_stats(self) -> Dict[str, NamespaceStats]:
        """Get stats for all namespaces.

        Returns:
            Dict of name -> stats
        """
        return {name: ns.get_stats() for name, ns in self._namespaces.items()}

    def __getitem__(self, name: str) -> Namespace:
        """Get namespace by name."""
        ns = self.get(name)
        if ns is None:
            return self.create(name)
        return ns

    def __contains__(self, name: str) -> bool:
        """Check if namespace exists."""
        return self.exists(name)

    def __len__(self) -> int:
        """Get namespace count."""
        return len(self._namespaces)

    def __iter__(self) -> Iterator[Namespace]:
        """Iterate over namespaces."""
        return iter(self._namespaces.values())


__all__ = ["Namespace", "NamespaceConfig", "NamespaceStats", "NamespaceManager"]

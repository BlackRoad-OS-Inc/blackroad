"""Cache module - Core caching functionality.

This module provides the main cache interface and entry management.
"""

from roadcache_core.cache.entry import (
    CacheEntry,
    EntryState,
    EntryMetadata,
)
from roadcache_core.cache.namespace import (
    Namespace,
    NamespaceManager,
)
from roadcache_core.cache.cache import (
    Cache,
    CacheConfig,
    CacheStats,
    WriteMode,
)

__all__ = [
    "CacheEntry",
    "EntryState",
    "EntryMetadata",
    "Namespace",
    "NamespaceManager",
    "Cache",
    "CacheConfig",
    "CacheStats",
    "WriteMode",
]

"""Eviction module - Cache eviction policies."""

from roadcache_core.eviction.policy import (
    EvictionPolicy,
    EvictionStats,
)
from roadcache_core.eviction.lru import LRUPolicy
from roadcache_core.eviction.lfu import LFUPolicy
from roadcache_core.eviction.arc import ARCPolicy

__all__ = [
    "EvictionPolicy",
    "EvictionStats",
    "LRUPolicy",
    "LFUPolicy",
    "ARCPolicy",
]

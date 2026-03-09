"""RoadCache - Enterprise Distributed Cache System.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.

A high-performance distributed caching system with:
- Multiple eviction policies (LRU, LFU, ARC, TTL)
- Consistent hashing for distributed deployments
- Multiple storage backends (memory, file, Redis)
- Cache namespacing and isolation
- Write-through and write-behind modes
- Cache statistics and monitoring
- Cluster replication and failover

Architecture:
    ┌─────────────────────────────────────────────────────────────────┐
    │                        RoadCache System                         │
    ├─────────────────────────────────────────────────────────────────┤
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
    │  │   Cache     │  │  Namespace  │  │   Entry     │   CACHE     │
    │  │  get/set    │  │  isolation  │  │  TTL/state  │   LAYER     │
    │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘             │
    │         │                │                │                     │
    │  ┌──────┴────────────────┴────────────────┴──────┐             │
    │  │              Eviction Policies                 │             │
    │  │   ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐         │   EVICTION  │
    │  │   │ LRU │  │ LFU │  │ ARC │  │ TTL │         │   LAYER     │
    │  │   └─────┘  └─────┘  └─────┘  └─────┘         │             │
    │  └──────────────────────┬────────────────────────┘             │
    │                         │                                       │
    │  ┌──────────────────────┴────────────────────────┐             │
    │  │              Storage Backends                  │             │
    │  │   ┌────────┐  ┌────────┐  ┌────────┐         │   STORAGE   │
    │  │   │ Memory │  │  File  │  │ Redis  │         │   LAYER     │
    │  │   └────────┘  └────────┘  └────────┘         │             │
    │  └──────────────────────┬────────────────────────┘             │
    │                         │                                       │
    │  ┌──────────────────────┴────────────────────────┐             │
    │  │              Cluster Layer                     │             │
    │  │   ┌────────┐  ┌────────┐  ┌────────┐         │   CLUSTER   │
    │  │   │  Node  │  │  Ring  │  │Cluster │         │   LAYER     │
    │  │   └────────┘  └────────┘  └────────┘         │             │
    │  └──────────────────────────────────────────────┘             │
    └─────────────────────────────────────────────────────────────────┘

Example Usage:
    from roadcache_core import Cache, MemoryStore, LRUPolicy

    # Simple in-memory cache
    cache = Cache()
    cache.set("user:1", {"name": "John"}, ttl=300)
    user = cache.get("user:1")

    # Distributed cache with Redis
    from roadcache_core import RedisStore, CacheCluster

    cluster = CacheCluster(
        nodes=["redis://host1:6379", "redis://host2:6379"],
        replication_factor=2,
    )
    cache = Cache(store=cluster, eviction=LRUPolicy(max_size=10000))

    # Namespaced caching
    users = cache.namespace("users")
    users.set("1", user_data)
    users.clear()  # Only clears user namespace

    # Cache decorator
    @cache.cached(ttl=60)
    def get_expensive_data(id: str):
        return fetch_from_database(id)
"""

__version__ = "1.0.0"
__author__ = "BlackRoad OS"

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
from roadcache_core.store.backend import (
    StorageBackend,
    StorageStats,
)
from roadcache_core.store.memory import MemoryStore
from roadcache_core.store.file import FileStore
from roadcache_core.store.redis import RedisStore
from roadcache_core.eviction.policy import (
    EvictionPolicy,
    EvictionStats,
)
from roadcache_core.eviction.lru import LRUPolicy
from roadcache_core.eviction.lfu import LFUPolicy
from roadcache_core.eviction.arc import ARCPolicy
from roadcache_core.consistency.model import (
    ConsistencyModel,
    ConsistencyLevel,
)
from roadcache_core.cluster.node import CacheNode, NodeState
from roadcache_core.cluster.ring import HashRing
from roadcache_core.cluster.cluster import CacheCluster, ClusterConfig
from roadcache_core.protocol.serializer import (
    Serializer,
    JSONSerializer,
    PickleSerializer,
    MsgPackSerializer,
)
from roadcache_core.metrics.collector import (
    MetricsCollector,
    CacheMetrics,
)

__all__ = [
    # Cache
    "Cache",
    "CacheConfig",
    "CacheStats",
    "CacheEntry",
    "EntryState",
    "EntryMetadata",
    "Namespace",
    "NamespaceManager",
    "WriteMode",
    # Storage
    "StorageBackend",
    "StorageStats",
    "MemoryStore",
    "FileStore",
    "RedisStore",
    # Eviction
    "EvictionPolicy",
    "EvictionStats",
    "LRUPolicy",
    "LFUPolicy",
    "ARCPolicy",
    # Consistency
    "ConsistencyModel",
    "ConsistencyLevel",
    # Cluster
    "CacheNode",
    "NodeState",
    "HashRing",
    "CacheCluster",
    "ClusterConfig",
    # Protocol
    "Serializer",
    "JSONSerializer",
    "PickleSerializer",
    "MsgPackSerializer",
    # Metrics
    "MetricsCollector",
    "CacheMetrics",
]

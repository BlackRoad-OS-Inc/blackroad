"""RoadSearch Distributed Storage - Distributed Storage Backend.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
import hashlib
from typing import Dict, List, Optional
from roadsearch_core.storage.backend import StorageBackend, StorageConfig
from roadsearch_core.storage.memory import MemoryStorage

class DistributedStorage(StorageBackend):
    """Distributed storage with sharding."""

    def __init__(self, config: StorageConfig = None, shard_count: int = 8):
        super().__init__(config)
        self.shard_count = shard_count
        self._shards: List[StorageBackend] = [MemoryStorage() for _ in range(shard_count)]

    def _get_shard(self, key: str) -> StorageBackend:
        hash_val = int(hashlib.md5(key.encode()).hexdigest(), 16)
        return self._shards[hash_val % self.shard_count]

    def write(self, key: str, data: bytes) -> bool:
        return self._get_shard(key).write(key, data)

    def read(self, key: str) -> Optional[bytes]:
        return self._get_shard(key).read(key)

    def delete(self, key: str) -> bool:
        return self._get_shard(key).delete(key)

    def exists(self, key: str) -> bool:
        return self._get_shard(key).exists(key)

    def list_keys(self, prefix: str = "") -> List[str]:
        keys = []
        for shard in self._shards:
            keys.extend(shard.list_keys(prefix))
        return keys

__all__ = ["DistributedStorage"]

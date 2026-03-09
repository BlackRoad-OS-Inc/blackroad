"""RoadSearch Memory Storage - In-Memory Storage Backend.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
from typing import Dict, List, Optional
from roadsearch_core.storage.backend import StorageBackend, StorageConfig

class MemoryStorage(StorageBackend):
    """In-memory storage backend."""

    def __init__(self, config: StorageConfig = None):
        super().__init__(config)
        self._data: Dict[str, bytes] = {}

    def write(self, key: str, data: bytes) -> bool:
        self._data[key] = data
        return True

    def read(self, key: str) -> Optional[bytes]:
        return self._data.get(key)

    def delete(self, key: str) -> bool:
        if key in self._data:
            del self._data[key]
            return True
        return False

    def exists(self, key: str) -> bool:
        return key in self._data

    def list_keys(self, prefix: str = "") -> List[str]:
        return [k for k in self._data.keys() if k.startswith(prefix)]

    def clear(self) -> None:
        self._data.clear()

__all__ = ["MemoryStorage"]

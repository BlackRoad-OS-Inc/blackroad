"""RoadSearch File Storage - File-Based Storage Backend.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
import os
import hashlib
from typing import List, Optional
from roadsearch_core.storage.backend import StorageBackend, StorageConfig

class FileStorage(StorageBackend):
    """File-based storage backend."""

    def __init__(self, config: StorageConfig = None):
        super().__init__(config)
        if self.config.path:
            os.makedirs(self.config.path, exist_ok=True)

    def _key_to_path(self, key: str) -> str:
        safe_key = hashlib.md5(key.encode()).hexdigest()
        return os.path.join(self.config.path, safe_key)

    def write(self, key: str, data: bytes) -> bool:
        try:
            path = self._key_to_path(key)
            with open(path, "wb") as f:
                f.write(data)
            return True
        except Exception:
            return False

    def read(self, key: str) -> Optional[bytes]:
        path = self._key_to_path(key)
        if os.path.exists(path):
            with open(path, "rb") as f:
                return f.read()
        return None

    def delete(self, key: str) -> bool:
        path = self._key_to_path(key)
        if os.path.exists(path):
            os.remove(path)
            return True
        return False

    def exists(self, key: str) -> bool:
        return os.path.exists(self._key_to_path(key))

    def list_keys(self, prefix: str = "") -> List[str]:
        if not os.path.exists(self.config.path):
            return []
        return os.listdir(self.config.path)

__all__ = ["FileStorage"]

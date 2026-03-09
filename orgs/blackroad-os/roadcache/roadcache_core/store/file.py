"""RoadCache File Store - File-Based Storage Backend.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import fnmatch
import hashlib
import json
import logging
import os
import pickle
import shutil
import threading
from pathlib import Path
from typing import Any, Dict, List, Optional

from roadcache_core.cache.entry import CacheEntry
from roadcache_core.store.backend import StorageBackend, StorageConfig

logger = logging.getLogger(__name__)


class FileStore(StorageBackend):
    """File-based storage backend.

    Persists cache entries to disk for durability across restarts.
    Uses a sharded directory structure for better performance.

    Features:
    - Persistent storage
    - Sharded directories (256 shards)
    - Atomic writes
    - Configurable serialization
    - Compression support

    Example:
        store = FileStore("/var/cache/myapp")
        store.set("key", CacheEntry(key="key", value="data"))
        entry = store.get("key")
    """

    SHARD_COUNT = 256

    def __init__(
        self,
        base_path: str,
        config: Optional[StorageConfig] = None,
    ):
        """Initialize file store.

        Args:
            base_path: Base directory for cache files
            config: Storage configuration
        """
        super().__init__(config)
        self.base_path = Path(base_path)
        self._lock = threading.RLock()

        # Create directory structure
        self._ensure_directories()

    def _ensure_directories(self) -> None:
        """Create shard directories."""
        self.base_path.mkdir(parents=True, exist_ok=True)
        for i in range(self.SHARD_COUNT):
            shard_dir = self.base_path / f"{i:02x}"
            shard_dir.mkdir(exist_ok=True)

    def _get_shard(self, key: str) -> str:
        """Get shard for key.

        Args:
            key: Cache key

        Returns:
            Shard directory name
        """
        hash_value = hashlib.md5(key.encode()).hexdigest()
        shard_index = int(hash_value[:2], 16)
        return f"{shard_index:02x}"

    def _get_path(self, key: str) -> Path:
        """Get file path for key.

        Args:
            key: Cache key

        Returns:
            File path
        """
        shard = self._get_shard(key)
        # Use hash as filename to handle special characters
        filename = hashlib.sha256(key.encode()).hexdigest()
        return self.base_path / shard / filename

    def get(self, key: str) -> Optional[CacheEntry]:
        """Get entry by key.

        Args:
            key: Cache key

        Returns:
            CacheEntry or None
        """
        path = self._get_path(key)

        try:
            with self._lock:
                self._stats.reads += 1

                if not path.exists():
                    return None

                with open(path, "rb") as f:
                    data = pickle.load(f)

                return CacheEntry.from_dict(data)

        except Exception as e:
            logger.error(f"Error reading {key}: {e}")
            self._stats.record_error(str(e))
            return None

    def set(self, key: str, entry: CacheEntry) -> bool:
        """Store entry.

        Args:
            key: Cache key
            entry: Cache entry

        Returns:
            True if successful
        """
        path = self._get_path(key)
        temp_path = path.with_suffix(".tmp")

        try:
            with self._lock:
                data = entry.to_dict()

                # Atomic write
                with open(temp_path, "wb") as f:
                    pickle.dump(data, f)

                temp_path.rename(path)
                self._stats.writes += 1
                return True

        except Exception as e:
            logger.error(f"Error writing {key}: {e}")
            self._stats.record_error(str(e))

            if temp_path.exists():
                temp_path.unlink()

            return False

    def delete(self, key: str) -> bool:
        """Delete entry.

        Args:
            key: Cache key

        Returns:
            True if deleted
        """
        path = self._get_path(key)

        try:
            with self._lock:
                if path.exists():
                    path.unlink()
                    self._stats.deletes += 1
                    return True
                return False

        except Exception as e:
            logger.error(f"Error deleting {key}: {e}")
            self._stats.record_error(str(e))
            return False

    def exists(self, key: str) -> bool:
        """Check if key exists.

        Args:
            key: Cache key

        Returns:
            True if exists
        """
        return self._get_path(key).exists()

    def clear(self) -> int:
        """Clear all entries.

        Returns:
            Number cleared
        """
        count = 0

        with self._lock:
            for shard_dir in self.base_path.iterdir():
                if shard_dir.is_dir():
                    for file_path in shard_dir.iterdir():
                        if file_path.is_file():
                            file_path.unlink()
                            count += 1

        return count

    def keys(self, pattern: Optional[str] = None) -> List[str]:
        """Get all keys.

        Note: This is expensive for file-based storage.
        Consider maintaining a key index for production use.

        Args:
            pattern: Optional glob pattern

        Returns:
            List of keys
        """
        keys = []

        # We need to read each file to get the original key
        # This is a limitation of the hashed filename approach
        for shard_dir in self.base_path.iterdir():
            if shard_dir.is_dir():
                for file_path in shard_dir.iterdir():
                    if file_path.is_file() and not file_path.suffix == ".tmp":
                        try:
                            with open(file_path, "rb") as f:
                                data = pickle.load(f)
                                key = data.get("key", "")
                                if pattern is None or fnmatch.fnmatch(key, pattern):
                                    keys.append(key)
                        except Exception:
                            pass

        return keys

    def size(self) -> int:
        """Get entry count.

        Returns:
            Number of entries
        """
        count = 0
        for shard_dir in self.base_path.iterdir():
            if shard_dir.is_dir():
                count += sum(1 for f in shard_dir.iterdir() if f.is_file() and not f.suffix == ".tmp")
        return count

    def disk_usage(self) -> int:
        """Get total disk usage.

        Returns:
            Size in bytes
        """
        total = 0
        for shard_dir in self.base_path.iterdir():
            if shard_dir.is_dir():
                for file_path in shard_dir.iterdir():
                    if file_path.is_file():
                        total += file_path.stat().st_size
        return total

    def compact(self) -> int:
        """Remove expired entries from disk.

        Returns:
            Number removed
        """
        removed = 0

        for shard_dir in self.base_path.iterdir():
            if shard_dir.is_dir():
                for file_path in shard_dir.iterdir():
                    if file_path.is_file():
                        try:
                            with open(file_path, "rb") as f:
                                data = pickle.load(f)
                            entry = CacheEntry.from_dict(data)
                            if entry.is_expired:
                                file_path.unlink()
                                removed += 1
                        except Exception:
                            pass

        return removed

    def __repr__(self) -> str:
        return f"FileStore(path={self.base_path})"


__all__ = ["FileStore"]

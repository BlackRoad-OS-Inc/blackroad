"""State Store - Workflow state persistence.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import json
import logging
import os
import pickle
import threading
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, Generic, List, Optional, TypeVar

logger = logging.getLogger(__name__)

T = TypeVar("T")


@dataclass
class StateEntry:
    """A state entry."""

    key: str
    value: Any
    created_at: datetime
    updated_at: datetime
    expires_at: Optional[datetime] = None
    version: int = 1
    metadata: Dict[str, Any] = field(default_factory=dict)

    def is_expired(self) -> bool:
        """Check if entry is expired."""
        if self.expires_at is None:
            return False
        return datetime.utcnow() > self.expires_at


class StateStore(ABC):
    """Abstract state store.

    Architecture:
    ┌─────────────────────────────────────────────────────────────────────┐
    │                         StateStore                                   │
    ├─────────────────────────────────────────────────────────────────────┤
    │                                                                      │
    │  Methods:                                                            │
    │  - get(key) -> value                                                │
    │  - set(key, value, ttl=None)                                        │
    │  - delete(key)                                                       │
    │  - exists(key) -> bool                                              │
    │  - keys(pattern) -> list                                            │
    │  - clear()                                                          │
    │                                                                      │
    │  Implementations:                                                    │
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
    │  │   Memory    │  │    File     │  │   Redis     │                  │
    │  │   Store     │  │   Store     │  │   Store     │                  │
    │  └─────────────┘  └─────────────┘  └─────────────┘                  │
    │                                                                      │
    └─────────────────────────────────────────────────────────────────────┘
    """

    @abstractmethod
    def get(self, key: str, default: Any = None) -> Any:
        """Get value by key."""
        pass

    @abstractmethod
    def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[timedelta] = None,
    ) -> None:
        """Set value with optional TTL."""
        pass

    @abstractmethod
    def delete(self, key: str) -> bool:
        """Delete key."""
        pass

    @abstractmethod
    def exists(self, key: str) -> bool:
        """Check if key exists."""
        pass

    @abstractmethod
    def keys(self, pattern: str = "*") -> List[str]:
        """Get keys matching pattern."""
        pass

    @abstractmethod
    def clear(self) -> None:
        """Clear all keys."""
        pass

    def get_many(self, keys: List[str]) -> Dict[str, Any]:
        """Get multiple values."""
        return {k: self.get(k) for k in keys}

    def set_many(
        self,
        items: Dict[str, Any],
        ttl: Optional[timedelta] = None,
    ) -> None:
        """Set multiple values."""
        for key, value in items.items():
            self.set(key, value, ttl)

    def delete_many(self, keys: List[str]) -> int:
        """Delete multiple keys."""
        count = 0
        for key in keys:
            if self.delete(key):
                count += 1
        return count

    def incr(self, key: str, amount: int = 1) -> int:
        """Increment numeric value."""
        value = self.get(key, 0)
        new_value = value + amount
        self.set(key, new_value)
        return new_value

    def decr(self, key: str, amount: int = 1) -> int:
        """Decrement numeric value."""
        return self.incr(key, -amount)


class MemoryStateStore(StateStore):
    """In-memory state store.

    Good for:
    - Testing and development
    - Single-process deployments
    - Ephemeral state
    """

    def __init__(self):
        self._data: Dict[str, StateEntry] = {}
        self._lock = threading.RLock()

    def get(self, key: str, default: Any = None) -> Any:
        """Get value by key."""
        with self._lock:
            entry = self._data.get(key)
            if entry is None:
                return default
            if entry.is_expired():
                del self._data[key]
                return default
            return entry.value

    def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[timedelta] = None,
    ) -> None:
        """Set value with optional TTL."""
        now = datetime.utcnow()
        expires_at = now + ttl if ttl else None

        with self._lock:
            existing = self._data.get(key)
            version = existing.version + 1 if existing else 1

            self._data[key] = StateEntry(
                key=key,
                value=value,
                created_at=existing.created_at if existing else now,
                updated_at=now,
                expires_at=expires_at,
                version=version,
            )

    def delete(self, key: str) -> bool:
        """Delete key."""
        with self._lock:
            if key in self._data:
                del self._data[key]
                return True
            return False

    def exists(self, key: str) -> bool:
        """Check if key exists."""
        with self._lock:
            entry = self._data.get(key)
            if entry is None:
                return False
            if entry.is_expired():
                del self._data[key]
                return False
            return True

    def keys(self, pattern: str = "*") -> List[str]:
        """Get keys matching pattern."""
        import fnmatch

        self._cleanup_expired()

        with self._lock:
            if pattern == "*":
                return list(self._data.keys())
            return [k for k in self._data.keys() if fnmatch.fnmatch(k, pattern)]

    def clear(self) -> None:
        """Clear all keys."""
        with self._lock:
            self._data.clear()

    def _cleanup_expired(self) -> int:
        """Remove expired entries."""
        count = 0
        with self._lock:
            expired = [k for k, v in self._data.items() if v.is_expired()]
            for key in expired:
                del self._data[key]
                count += 1
        return count

    def get_entry(self, key: str) -> Optional[StateEntry]:
        """Get full state entry."""
        with self._lock:
            entry = self._data.get(key)
            if entry and entry.is_expired():
                del self._data[key]
                return None
            return entry


class FileStateStore(StateStore):
    """File-based state store.

    Good for:
    - Persistent state across restarts
    - Single-machine deployments
    - Simple persistence needs
    """

    def __init__(
        self,
        directory: str = ".workflow_state",
        serializer: str = "json",
    ):
        self.directory = Path(directory)
        self.directory.mkdir(parents=True, exist_ok=True)
        self.serializer = serializer
        self._lock = threading.RLock()
        self._cache: Dict[str, StateEntry] = {}
        self._load_all()

    def _load_all(self) -> None:
        """Load all state from files."""
        for file_path in self.directory.glob("*.state"):
            try:
                with open(file_path, "r") as f:
                    data = json.load(f)
                    entry = StateEntry(
                        key=data["key"],
                        value=data["value"],
                        created_at=datetime.fromisoformat(data["created_at"]),
                        updated_at=datetime.fromisoformat(data["updated_at"]),
                        expires_at=datetime.fromisoformat(data["expires_at"]) if data.get("expires_at") else None,
                        version=data.get("version", 1),
                    )
                    if not entry.is_expired():
                        self._cache[entry.key] = entry
            except Exception as e:
                logger.warning(f"Failed to load state file {file_path}: {e}")

    def _save_entry(self, entry: StateEntry) -> None:
        """Save entry to file."""
        file_path = self.directory / f"{self._safe_filename(entry.key)}.state"
        data = {
            "key": entry.key,
            "value": entry.value,
            "created_at": entry.created_at.isoformat(),
            "updated_at": entry.updated_at.isoformat(),
            "expires_at": entry.expires_at.isoformat() if entry.expires_at else None,
            "version": entry.version,
        }
        with open(file_path, "w") as f:
            json.dump(data, f, indent=2, default=str)

    def _delete_file(self, key: str) -> None:
        """Delete state file."""
        file_path = self.directory / f"{self._safe_filename(key)}.state"
        if file_path.exists():
            file_path.unlink()

    def _safe_filename(self, key: str) -> str:
        """Convert key to safe filename."""
        import hashlib
        return hashlib.md5(key.encode()).hexdigest()

    def get(self, key: str, default: Any = None) -> Any:
        """Get value by key."""
        with self._lock:
            entry = self._cache.get(key)
            if entry is None:
                return default
            if entry.is_expired():
                del self._cache[key]
                self._delete_file(key)
                return default
            return entry.value

    def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[timedelta] = None,
    ) -> None:
        """Set value with optional TTL."""
        now = datetime.utcnow()
        expires_at = now + ttl if ttl else None

        with self._lock:
            existing = self._cache.get(key)
            version = existing.version + 1 if existing else 1

            entry = StateEntry(
                key=key,
                value=value,
                created_at=existing.created_at if existing else now,
                updated_at=now,
                expires_at=expires_at,
                version=version,
            )

            self._cache[key] = entry
            self._save_entry(entry)

    def delete(self, key: str) -> bool:
        """Delete key."""
        with self._lock:
            if key in self._cache:
                del self._cache[key]
                self._delete_file(key)
                return True
            return False

    def exists(self, key: str) -> bool:
        """Check if key exists."""
        with self._lock:
            entry = self._cache.get(key)
            if entry is None:
                return False
            if entry.is_expired():
                del self._cache[key]
                self._delete_file(key)
                return False
            return True

    def keys(self, pattern: str = "*") -> List[str]:
        """Get keys matching pattern."""
        import fnmatch

        with self._lock:
            expired = [k for k, v in self._cache.items() if v.is_expired()]
            for key in expired:
                del self._cache[key]
                self._delete_file(key)

            if pattern == "*":
                return list(self._cache.keys())
            return [k for k in self._cache.keys() if fnmatch.fnmatch(k, pattern)]

    def clear(self) -> None:
        """Clear all keys."""
        with self._lock:
            self._cache.clear()
            for file_path in self.directory.glob("*.state"):
                file_path.unlink()


class RedisStateStore(StateStore):
    """Redis-based state store.

    Good for:
    - Distributed deployments
    - High-performance state
    - Multi-process coordination
    """

    def __init__(
        self,
        host: str = "localhost",
        port: int = 6379,
        db: int = 0,
        password: Optional[str] = None,
        prefix: str = "roadworkflow:",
        socket_timeout: float = 5.0,
    ):
        self.host = host
        self.port = port
        self.db = db
        self.password = password
        self.prefix = prefix
        self.socket_timeout = socket_timeout
        self._client: Optional[Any] = None

    def _get_client(self) -> Any:
        """Get or create Redis client."""
        if self._client is None:
            try:
                import redis
                self._client = redis.Redis(
                    host=self.host,
                    port=self.port,
                    db=self.db,
                    password=self.password,
                    socket_timeout=self.socket_timeout,
                    decode_responses=True,
                )
            except ImportError:
                raise ImportError("redis package required for RedisStateStore")
        return self._client

    def _key(self, key: str) -> str:
        """Add prefix to key."""
        return f"{self.prefix}{key}"

    def get(self, key: str, default: Any = None) -> Any:
        """Get value by key."""
        try:
            client = self._get_client()
            value = client.get(self._key(key))
            if value is None:
                return default
            return json.loads(value)
        except Exception as e:
            logger.error(f"Redis get error: {e}")
            return default

    def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[timedelta] = None,
    ) -> None:
        """Set value with optional TTL."""
        try:
            client = self._get_client()
            serialized = json.dumps(value, default=str)

            if ttl:
                client.setex(self._key(key), ttl, serialized)
            else:
                client.set(self._key(key), serialized)
        except Exception as e:
            logger.error(f"Redis set error: {e}")

    def delete(self, key: str) -> bool:
        """Delete key."""
        try:
            client = self._get_client()
            return client.delete(self._key(key)) > 0
        except Exception as e:
            logger.error(f"Redis delete error: {e}")
            return False

    def exists(self, key: str) -> bool:
        """Check if key exists."""
        try:
            client = self._get_client()
            return client.exists(self._key(key)) > 0
        except Exception as e:
            logger.error(f"Redis exists error: {e}")
            return False

    def keys(self, pattern: str = "*") -> List[str]:
        """Get keys matching pattern."""
        try:
            client = self._get_client()
            full_pattern = self._key(pattern)
            keys = client.keys(full_pattern)
            prefix_len = len(self.prefix)
            return [k[prefix_len:] for k in keys]
        except Exception as e:
            logger.error(f"Redis keys error: {e}")
            return []

    def clear(self) -> None:
        """Clear all keys with prefix."""
        try:
            client = self._get_client()
            keys = client.keys(f"{self.prefix}*")
            if keys:
                client.delete(*keys)
        except Exception as e:
            logger.error(f"Redis clear error: {e}")

    def incr(self, key: str, amount: int = 1) -> int:
        """Increment numeric value."""
        try:
            client = self._get_client()
            return client.incrby(self._key(key), amount)
        except Exception as e:
            logger.error(f"Redis incr error: {e}")
            return 0


__all__ = [
    "StateStore",
    "StateEntry",
    "MemoryStateStore",
    "FileStateStore",
    "RedisStateStore",
]

"""RoadCache Redis Store - Redis Storage Backend.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import json
import logging
import pickle
import time
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Union

from roadcache_core.cache.entry import CacheEntry
from roadcache_core.store.backend import StorageBackend, StorageConfig

logger = logging.getLogger(__name__)


@dataclass
class RedisConfig(StorageConfig):
    """Redis-specific configuration.

    Attributes:
        host: Redis host
        port: Redis port
        db: Redis database number
        password: Redis password
        socket_timeout: Socket timeout
        socket_connect_timeout: Connection timeout
        ssl: Enable SSL
        ssl_ca_certs: CA certificates path
        max_connections: Connection pool size
        prefix: Key prefix
        decode_responses: Decode responses to strings
    """

    host: str = "localhost"
    port: int = 6379
    db: int = 0
    password: Optional[str] = None
    socket_timeout: float = 5.0
    socket_connect_timeout: float = 5.0
    ssl: bool = False
    ssl_ca_certs: Optional[str] = None
    max_connections: int = 10
    prefix: str = "cache:"
    decode_responses: bool = False


class RedisStore(StorageBackend):
    """Redis storage backend.

    Uses Redis for distributed caching with features like:
    - Native TTL support
    - Atomic operations
    - Pub/sub for invalidation
    - Cluster support
    - Connection pooling

    Example:
        store = RedisStore(RedisConfig(host="redis.local", port=6379))
        store.set("key", CacheEntry(key="key", value="data"))
        entry = store.get("key")
    """

    def __init__(self, config: Optional[RedisConfig] = None):
        """Initialize Redis store.

        Args:
            config: Redis configuration
        """
        super().__init__(config)
        self.config: RedisConfig = config or RedisConfig()
        self._client: Optional[Any] = None
        self._pool: Optional[Any] = None

    def _ensure_connected(self) -> Any:
        """Ensure Redis connection exists.

        Returns:
            Redis client
        """
        if self._client is not None:
            return self._client

        try:
            import redis

            self._pool = redis.ConnectionPool(
                host=self.config.host,
                port=self.config.port,
                db=self.config.db,
                password=self.config.password,
                socket_timeout=self.config.socket_timeout,
                socket_connect_timeout=self.config.socket_connect_timeout,
                max_connections=self.config.max_connections,
                decode_responses=False,  # We handle serialization
            )

            self._client = redis.Redis(connection_pool=self._pool)

            # Test connection
            self._client.ping()
            logger.info(f"Connected to Redis at {self.config.host}:{self.config.port}")

            return self._client

        except ImportError:
            raise ImportError("Redis package not installed. Run: pip install redis")
        except Exception as e:
            logger.error(f"Failed to connect to Redis: {e}")
            raise

    def _make_key(self, key: str) -> str:
        """Make prefixed Redis key.

        Args:
            key: Original key

        Returns:
            Prefixed key
        """
        return f"{self.config.prefix}{key}"

    def _serialize(self, entry: CacheEntry) -> bytes:
        """Serialize entry to bytes.

        Args:
            entry: Cache entry

        Returns:
            Serialized bytes
        """
        data = entry.to_dict()
        return pickle.dumps(data)

    def _deserialize(self, data: bytes) -> CacheEntry:
        """Deserialize bytes to entry.

        Args:
            data: Serialized bytes

        Returns:
            Cache entry
        """
        entry_data = pickle.loads(data)
        return CacheEntry.from_dict(entry_data)

    def get(self, key: str) -> Optional[CacheEntry]:
        """Get entry by key.

        Args:
            key: Cache key

        Returns:
            CacheEntry or None
        """
        try:
            client = self._ensure_connected()
            redis_key = self._make_key(key)

            self._stats.reads += 1
            data = client.get(redis_key)

            if data is None:
                return None

            entry = self._deserialize(data)

            # Check expiration (Redis handles TTL, but double-check)
            if entry.is_expired:
                self.delete(key)
                return None

            return entry

        except Exception as e:
            logger.error(f"Redis get error: {e}")
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
        try:
            client = self._ensure_connected()
            redis_key = self._make_key(key)

            data = self._serialize(entry)

            # Use TTL if set
            if entry.ttl_seconds:
                ttl_ms = int(entry.remaining_ttl * 1000)
                client.psetex(redis_key, ttl_ms, data)
            else:
                client.set(redis_key, data)

            self._stats.writes += 1
            return True

        except Exception as e:
            logger.error(f"Redis set error: {e}")
            self._stats.record_error(str(e))
            return False

    def delete(self, key: str) -> bool:
        """Delete entry.

        Args:
            key: Cache key

        Returns:
            True if deleted
        """
        try:
            client = self._ensure_connected()
            redis_key = self._make_key(key)

            result = client.delete(redis_key)
            self._stats.deletes += 1

            return result > 0

        except Exception as e:
            logger.error(f"Redis delete error: {e}")
            self._stats.record_error(str(e))
            return False

    def exists(self, key: str) -> bool:
        """Check if key exists.

        Args:
            key: Cache key

        Returns:
            True if exists
        """
        try:
            client = self._ensure_connected()
            redis_key = self._make_key(key)
            return client.exists(redis_key) > 0

        except Exception as e:
            logger.error(f"Redis exists error: {e}")
            return False

    def clear(self) -> int:
        """Clear all entries with prefix.

        Returns:
            Number cleared
        """
        try:
            client = self._ensure_connected()
            pattern = f"{self.config.prefix}*"

            count = 0
            cursor = 0
            while True:
                cursor, keys = client.scan(cursor, match=pattern, count=100)
                if keys:
                    count += client.delete(*keys)
                if cursor == 0:
                    break

            return count

        except Exception as e:
            logger.error(f"Redis clear error: {e}")
            self._stats.record_error(str(e))
            return 0

    def keys(self, pattern: Optional[str] = None) -> List[str]:
        """Get all keys.

        Args:
            pattern: Optional pattern

        Returns:
            List of keys
        """
        try:
            client = self._ensure_connected()

            if pattern:
                redis_pattern = f"{self.config.prefix}{pattern}"
            else:
                redis_pattern = f"{self.config.prefix}*"

            keys = []
            cursor = 0
            prefix_len = len(self.config.prefix)

            while True:
                cursor, batch = client.scan(cursor, match=redis_pattern, count=100)
                for key in batch:
                    # Remove prefix
                    key_str = key.decode() if isinstance(key, bytes) else key
                    keys.append(key_str[prefix_len:])
                if cursor == 0:
                    break

            return keys

        except Exception as e:
            logger.error(f"Redis keys error: {e}")
            return []

    def size(self) -> int:
        """Get entry count.

        Returns:
            Number of entries
        """
        return len(self.keys())

    def ttl(self, key: str) -> Optional[float]:
        """Get remaining TTL.

        Args:
            key: Cache key

        Returns:
            TTL in seconds or None
        """
        try:
            client = self._ensure_connected()
            redis_key = self._make_key(key)
            ttl_ms = client.pttl(redis_key)

            if ttl_ms < 0:
                return None

            return ttl_ms / 1000

        except Exception:
            return None

    def expire(self, key: str, seconds: float) -> bool:
        """Set key expiration.

        Args:
            key: Cache key
            seconds: TTL in seconds

        Returns:
            True if successful
        """
        try:
            client = self._ensure_connected()
            redis_key = self._make_key(key)
            return client.pexpire(redis_key, int(seconds * 1000))

        except Exception as e:
            logger.error(f"Redis expire error: {e}")
            return False

    def increment(self, key: str, delta: int = 1) -> int:
        """Increment numeric value.

        Args:
            key: Cache key
            delta: Amount to increment

        Returns:
            New value
        """
        try:
            client = self._ensure_connected()
            redis_key = self._make_key(key)
            return client.incrby(redis_key, delta)

        except Exception as e:
            logger.error(f"Redis increment error: {e}")
            return 0

    def get_many(self, keys: List[str]) -> Dict[str, CacheEntry]:
        """Get multiple entries.

        Args:
            keys: List of keys

        Returns:
            Dict of key -> entry
        """
        try:
            client = self._ensure_connected()
            redis_keys = [self._make_key(k) for k in keys]

            self._stats.reads += len(keys)
            values = client.mget(redis_keys)

            result = {}
            for key, data in zip(keys, values):
                if data is not None:
                    try:
                        entry = self._deserialize(data)
                        if not entry.is_expired:
                            result[key] = entry
                    except Exception:
                        pass

            return result

        except Exception as e:
            logger.error(f"Redis mget error: {e}")
            return {}

    def set_many(self, entries: Dict[str, CacheEntry]) -> int:
        """Store multiple entries.

        Args:
            entries: Dict of key -> entry

        Returns:
            Number stored
        """
        try:
            client = self._ensure_connected()
            pipe = client.pipeline()

            for key, entry in entries.items():
                redis_key = self._make_key(key)
                data = self._serialize(entry)

                if entry.ttl_seconds and entry.remaining_ttl:
                    ttl_ms = int(entry.remaining_ttl * 1000)
                    pipe.psetex(redis_key, ttl_ms, data)
                else:
                    pipe.set(redis_key, data)

            pipe.execute()
            self._stats.writes += len(entries)
            return len(entries)

        except Exception as e:
            logger.error(f"Redis mset error: {e}")
            self._stats.record_error(str(e))
            return 0

    def info(self) -> Dict[str, Any]:
        """Get Redis server info.

        Returns:
            Server info dict
        """
        try:
            client = self._ensure_connected()
            return client.info()
        except Exception:
            return {}

    def close(self) -> None:
        """Close Redis connection."""
        if self._pool:
            self._pool.disconnect()
            self._pool = None
            self._client = None

    def __repr__(self) -> str:
        return f"RedisStore(host={self.config.host}, port={self.config.port})"


__all__ = ["RedisStore", "RedisConfig"]

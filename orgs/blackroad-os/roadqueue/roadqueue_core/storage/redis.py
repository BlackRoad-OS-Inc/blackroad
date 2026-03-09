"""RoadQueue Redis Backend - Redis-Based Persistence.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional

from roadqueue_core.queue.message import Message
from roadqueue_core.storage.backend import StorageBackend

logger = logging.getLogger(__name__)


class RedisBackend(StorageBackend):
    """Redis-based storage backend."""

    def __init__(
        self,
        host: str = "localhost",
        port: int = 6379,
        db: int = 0,
        prefix: str = "roadqueue:",
        password: Optional[str] = None,
    ):
        self.host = host
        self.port = port
        self.db = db
        self.prefix = prefix
        self.password = password
        self._client = None

    def _connect(self):
        """Lazy connect to Redis."""
        if self._client is None:
            try:
                import redis
                self._client = redis.Redis(
                    host=self.host,
                    port=self.port,
                    db=self.db,
                    password=self.password,
                    decode_responses=True,
                )
            except ImportError:
                logger.warning("redis package not installed, using mock")
                self._client = _MockRedis()

    def _key(self, queue_name: str) -> str:
        return f"{self.prefix}{queue_name}"

    def store(self, queue_name: str, message: Message) -> bool:
        self._connect()
        key = self._key(queue_name)
        data = json.dumps(message.to_dict())
        self._client.hset(key, message.id, data)
        return True

    def retrieve(self, queue_name: str, message_id: str) -> Optional[Message]:
        self._connect()
        key = self._key(queue_name)
        data = self._client.hget(key, message_id)
        if data:
            return Message.from_dict(json.loads(data))
        return None

    def delete(self, queue_name: str, message_id: str) -> bool:
        self._connect()
        key = self._key(queue_name)
        return self._client.hdel(key, message_id) > 0

    def list_messages(self, queue_name: str, limit: int = 100) -> List[Message]:
        self._connect()
        key = self._key(queue_name)
        all_data = self._client.hgetall(key)
        messages = [Message.from_dict(json.loads(d)) for d in list(all_data.values())[:limit]]
        return messages

    def count(self, queue_name: str) -> int:
        self._connect()
        key = self._key(queue_name)
        return self._client.hlen(key)

    def clear(self, queue_name: str) -> int:
        self._connect()
        key = self._key(queue_name)
        count = self._client.hlen(key)
        self._client.delete(key)
        return count

    def close(self) -> None:
        if self._client:
            self._client.close()


class _MockRedis:
    """Mock Redis for when redis package is not available."""

    def __init__(self):
        self._data: Dict[str, Dict[str, str]] = {}

    def hset(self, key: str, field: str, value: str) -> int:
        if key not in self._data:
            self._data[key] = {}
        self._data[key][field] = value
        return 1

    def hget(self, key: str, field: str) -> Optional[str]:
        return self._data.get(key, {}).get(field)

    def hdel(self, key: str, field: str) -> int:
        if key in self._data and field in self._data[key]:
            del self._data[key][field]
            return 1
        return 0

    def hgetall(self, key: str) -> Dict[str, str]:
        return self._data.get(key, {})

    def hlen(self, key: str) -> int:
        return len(self._data.get(key, {}))

    def delete(self, key: str) -> int:
        if key in self._data:
            del self._data[key]
            return 1
        return 0

    def close(self) -> None:
        pass


__all__ = ["RedisBackend"]

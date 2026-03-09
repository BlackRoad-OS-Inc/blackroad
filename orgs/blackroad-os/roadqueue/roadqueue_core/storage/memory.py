"""RoadQueue Memory Backend - In-Memory Storage.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import threading
from collections import defaultdict
from typing import Dict, List, Optional

from roadqueue_core.queue.message import Message
from roadqueue_core.storage.backend import StorageBackend


class MemoryBackend(StorageBackend):
    """In-memory storage backend."""

    def __init__(self):
        self._storage: Dict[str, Dict[str, Message]] = defaultdict(dict)
        self._lock = threading.RLock()

    def store(self, queue_name: str, message: Message) -> bool:
        with self._lock:
            self._storage[queue_name][message.id] = message
            return True

    def retrieve(self, queue_name: str, message_id: str) -> Optional[Message]:
        with self._lock:
            return self._storage[queue_name].get(message_id)

    def delete(self, queue_name: str, message_id: str) -> bool:
        with self._lock:
            if message_id in self._storage[queue_name]:
                del self._storage[queue_name][message_id]
                return True
            return False

    def list_messages(self, queue_name: str, limit: int = 100) -> List[Message]:
        with self._lock:
            messages = list(self._storage[queue_name].values())
            return messages[:limit]

    def count(self, queue_name: str) -> int:
        with self._lock:
            return len(self._storage[queue_name])

    def clear(self, queue_name: str) -> int:
        with self._lock:
            count = len(self._storage[queue_name])
            self._storage[queue_name].clear()
            return count


__all__ = ["MemoryBackend"]

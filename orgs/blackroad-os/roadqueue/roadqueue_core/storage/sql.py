"""RoadQueue SQL Backend - SQL Database Persistence.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import json
import logging
import sqlite3
from typing import Any, Dict, List, Optional

from roadqueue_core.queue.message import Message
from roadqueue_core.storage.backend import StorageBackend

logger = logging.getLogger(__name__)


class SQLBackend(StorageBackend):
    """SQL database storage backend."""

    def __init__(self, connection_string: str = ":memory:"):
        self.connection_string = connection_string
        self._conn: Optional[sqlite3.Connection] = None
        self._init_db()

    def _init_db(self) -> None:
        """Initialize database schema."""
        self._conn = sqlite3.connect(self.connection_string, check_same_thread=False)
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                queue_name TEXT NOT NULL,
                data TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        self._conn.execute("CREATE INDEX IF NOT EXISTS idx_queue ON messages(queue_name)")
        self._conn.commit()

    def store(self, queue_name: str, message: Message) -> bool:
        data = json.dumps(message.to_dict())
        self._conn.execute(
            "INSERT OR REPLACE INTO messages (id, queue_name, data) VALUES (?, ?, ?)",
            (message.id, queue_name, data),
        )
        self._conn.commit()
        return True

    def retrieve(self, queue_name: str, message_id: str) -> Optional[Message]:
        cursor = self._conn.execute(
            "SELECT data FROM messages WHERE id = ? AND queue_name = ?",
            (message_id, queue_name),
        )
        row = cursor.fetchone()
        if row:
            return Message.from_dict(json.loads(row[0]))
        return None

    def delete(self, queue_name: str, message_id: str) -> bool:
        cursor = self._conn.execute(
            "DELETE FROM messages WHERE id = ? AND queue_name = ?",
            (message_id, queue_name),
        )
        self._conn.commit()
        return cursor.rowcount > 0

    def list_messages(self, queue_name: str, limit: int = 100) -> List[Message]:
        cursor = self._conn.execute(
            "SELECT data FROM messages WHERE queue_name = ? ORDER BY created_at LIMIT ?",
            (queue_name, limit),
        )
        return [Message.from_dict(json.loads(row[0])) for row in cursor.fetchall()]

    def count(self, queue_name: str) -> int:
        cursor = self._conn.execute(
            "SELECT COUNT(*) FROM messages WHERE queue_name = ?",
            (queue_name,),
        )
        return cursor.fetchone()[0]

    def clear(self, queue_name: str) -> int:
        count = self.count(queue_name)
        self._conn.execute("DELETE FROM messages WHERE queue_name = ?", (queue_name,))
        self._conn.commit()
        return count

    def close(self) -> None:
        if self._conn:
            self._conn.close()


__all__ = ["SQLBackend"]

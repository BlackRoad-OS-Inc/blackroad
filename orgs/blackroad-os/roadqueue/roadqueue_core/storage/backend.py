"""RoadQueue Storage Backend - Abstract Storage Interface.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional

from roadqueue_core.queue.message import Message


class StorageBackend(ABC):
    """Abstract storage backend for message persistence."""

    @abstractmethod
    def store(self, queue_name: str, message: Message) -> bool:
        """Store a message."""
        pass

    @abstractmethod
    def retrieve(self, queue_name: str, message_id: str) -> Optional[Message]:
        """Retrieve a message by ID."""
        pass

    @abstractmethod
    def delete(self, queue_name: str, message_id: str) -> bool:
        """Delete a message."""
        pass

    @abstractmethod
    def list_messages(self, queue_name: str, limit: int = 100) -> List[Message]:
        """List messages in a queue."""
        pass

    @abstractmethod
    def count(self, queue_name: str) -> int:
        """Count messages in a queue."""
        pass

    @abstractmethod
    def clear(self, queue_name: str) -> int:
        """Clear all messages from a queue."""
        pass

    def close(self) -> None:
        """Close the backend connection."""
        pass


__all__ = ["StorageBackend"]

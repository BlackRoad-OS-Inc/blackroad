"""RoadQueue Dead Letter Queue - Failed Message Handling.

This module provides a dead letter queue implementation for handling
messages that cannot be processed successfully.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set

from roadqueue_core.queue.message import (
    Message,
    MessagePriority,
    MessageState,
)
from roadqueue_core.queue.base import (
    Queue,
    QueueConfig,
    QueueState,
    QueueStats,
)

logger = logging.getLogger(__name__)


class DeadLetterReason(Enum):
    """Reasons for message being dead-lettered."""

    MAX_RETRIES = auto()      # Exceeded retry limit
    EXPIRED = auto()          # TTL exceeded
    REJECTED = auto()         # Explicitly rejected
    INVALID = auto()          # Validation failed
    ROUTING_FAILED = auto()   # No matching queue
    PROCESSING_ERROR = auto() # Unhandled exception
    TIMEOUT = auto()          # Processing timeout
    QUEUE_FULL = auto()       # Target queue full


@dataclass
class DeadLetterEntry:
    """A dead letter queue entry.

    Contains the original message plus metadata about
    why it was dead-lettered.

    Attributes:
        message: Original message
        reason: Why message was dead-lettered
        error: Error message/exception
        source_queue: Original queue name
        dead_at: When message was dead-lettered
        attempts: Number of processing attempts
        can_retry: Whether message can be retried
    """

    message: Message
    reason: DeadLetterReason
    error: Optional[str] = None
    source_queue: Optional[str] = None
    dead_at: datetime = field(default_factory=datetime.now)
    attempts: int = 0
    can_retry: bool = True

    def to_dict(self) -> Dict[str, Any]:
        """Convert entry to dictionary."""
        return {
            "message": self.message.to_dict(),
            "reason": self.reason.name,
            "error": self.error,
            "source_queue": self.source_queue,
            "dead_at": self.dead_at.isoformat(),
            "attempts": self.attempts,
            "can_retry": self.can_retry,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "DeadLetterEntry":
        """Create entry from dictionary."""
        return cls(
            message=Message.from_dict(data["message"]),
            reason=DeadLetterReason[data["reason"]],
            error=data.get("error"),
            source_queue=data.get("source_queue"),
            dead_at=datetime.fromisoformat(data["dead_at"]),
            attempts=data.get("attempts", 0),
            can_retry=data.get("can_retry", True),
        )


@dataclass
class DLQStats:
    """Dead letter queue statistics."""

    total_messages: int = 0
    by_reason: Dict[str, int] = field(default_factory=dict)
    by_source: Dict[str, int] = field(default_factory=dict)
    retry_count: int = 0
    purge_count: int = 0
    oldest_message: Optional[datetime] = None
    newest_message: Optional[datetime] = None


class DeadLetterQueue:
    """Dead letter queue for failed messages.

    Provides storage and management for messages that cannot
    be processed successfully.

    Features:
    - Categorization by failure reason
    - Retry support with backoff
    - Bulk operations (purge, replay)
    - Analytics on failure patterns
    - Alerting on thresholds
    """

    def __init__(
        self,
        name: str = "dlq",
        max_size: int = 100000,
        retention_days: int = 30,
        auto_purge: bool = True,
    ):
        """Initialize dead letter queue.

        Args:
            name: Queue name
            max_size: Maximum entries to store
            retention_days: Days to retain entries
            auto_purge: Automatically purge old entries
        """
        self.name = name
        self.max_size = max_size
        self.retention_days = retention_days
        self.auto_purge = auto_purge

        self._entries: Dict[str, DeadLetterEntry] = {}
        self._by_reason: Dict[DeadLetterReason, Set[str]] = defaultdict(set)
        self._by_source: Dict[str, Set[str]] = defaultdict(set)
        self._lock = threading.RLock()
        self._stats = DLQStats()

        # Callbacks for alerting
        self._on_threshold: Optional[Callable[[int], None]] = None
        self._threshold = 1000

    def add(
        self,
        message: Message,
        reason: DeadLetterReason,
        error: Optional[str] = None,
        source_queue: Optional[str] = None,
    ) -> bool:
        """Add a message to the dead letter queue.

        Args:
            message: Failed message
            reason: Failure reason
            error: Error message
            source_queue: Original queue name

        Returns:
            True if added successfully
        """
        with self._lock:
            # Check size limit
            if len(self._entries) >= self.max_size:
                if self.auto_purge:
                    self._purge_oldest(self.max_size // 10)
                else:
                    logger.warning(f"DLQ {self.name} is full")
                    return False

            # Create entry
            message.state = MessageState.DEAD
            entry = DeadLetterEntry(
                message=message,
                reason=reason,
                error=error or message.metadata.last_error,
                source_queue=source_queue or message.queue_name,
                attempts=message.metadata.retry_count,
                can_retry=reason not in (
                    DeadLetterReason.INVALID,
                    DeadLetterReason.EXPIRED,
                ),
            )

            # Store entry
            self._entries[message.id] = entry
            self._by_reason[reason].add(message.id)
            if entry.source_queue:
                self._by_source[entry.source_queue].add(message.id)

            # Update stats
            self._stats.total_messages += 1
            self._stats.by_reason[reason.name] = self._stats.by_reason.get(
                reason.name, 0
            ) + 1

            if entry.source_queue:
                self._stats.by_source[entry.source_queue] = self._stats.by_source.get(
                    entry.source_queue, 0
                ) + 1

            if self._stats.oldest_message is None:
                self._stats.oldest_message = entry.dead_at
            self._stats.newest_message = entry.dead_at

            logger.info(
                f"Dead-lettered message {message.id}: {reason.name} - {error}"
            )

            # Check threshold for alerting
            if self._on_threshold and len(self._entries) >= self._threshold:
                self._on_threshold(len(self._entries))

            return True

    def get(self, message_id: str) -> Optional[DeadLetterEntry]:
        """Get a dead letter entry by ID.

        Args:
            message_id: Message ID

        Returns:
            Entry or None
        """
        return self._entries.get(message_id)

    def remove(self, message_id: str) -> Optional[DeadLetterEntry]:
        """Remove an entry from the DLQ.

        Args:
            message_id: Message ID

        Returns:
            Removed entry or None
        """
        with self._lock:
            entry = self._entries.pop(message_id, None)
            if entry:
                self._by_reason[entry.reason].discard(message_id)
                if entry.source_queue:
                    self._by_source[entry.source_queue].discard(message_id)
            return entry

    def retry(
        self,
        message_id: str,
        target_queue: Optional[Queue] = None,
    ) -> bool:
        """Retry a dead-lettered message.

        Args:
            message_id: Message ID
            target_queue: Queue to retry to (defaults to source)

        Returns:
            True if retry successful
        """
        entry = self.remove(message_id)
        if not entry:
            return False

        if not entry.can_retry:
            logger.warning(f"Message {message_id} cannot be retried")
            self.add(
                entry.message,
                entry.reason,
                entry.error,
                entry.source_queue,
            )
            return False

        # Reset message state
        message = entry.message
        message.state = MessageState.PENDING
        message.metadata.retry_count += 1

        if target_queue:
            if target_queue.publish(message):
                self._stats.retry_count += 1
                logger.info(f"Retried message {message_id} to {target_queue.name}")
                return True

        logger.warning(f"Failed to retry message {message_id}")
        self.add(message, entry.reason, entry.error, entry.source_queue)
        return False

    def retry_all(
        self,
        target_queue: Queue,
        reason: Optional[DeadLetterReason] = None,
        source_queue: Optional[str] = None,
        limit: int = 100,
    ) -> int:
        """Retry multiple dead-lettered messages.

        Args:
            target_queue: Queue to retry to
            reason: Filter by reason
            source_queue: Filter by source queue
            limit: Maximum messages to retry

        Returns:
            Number of messages retried
        """
        message_ids = self.list_ids(reason=reason, source_queue=source_queue)[:limit]

        retried = 0
        for message_id in message_ids:
            if self.retry(message_id, target_queue):
                retried += 1

        return retried

    def list_entries(
        self,
        reason: Optional[DeadLetterReason] = None,
        source_queue: Optional[str] = None,
        limit: int = 100,
        offset: int = 0,
    ) -> List[DeadLetterEntry]:
        """List dead letter entries.

        Args:
            reason: Filter by reason
            source_queue: Filter by source queue
            limit: Maximum entries to return
            offset: Offset for pagination

        Returns:
            List of entries
        """
        with self._lock:
            ids = self.list_ids(reason=reason, source_queue=source_queue)
            ids = ids[offset:offset + limit]
            return [self._entries[id] for id in ids if id in self._entries]

    def list_ids(
        self,
        reason: Optional[DeadLetterReason] = None,
        source_queue: Optional[str] = None,
    ) -> List[str]:
        """List message IDs matching filters.

        Args:
            reason: Filter by reason
            source_queue: Filter by source queue

        Returns:
            List of message IDs
        """
        with self._lock:
            if reason and source_queue:
                return list(
                    self._by_reason[reason] & self._by_source[source_queue]
                )
            elif reason:
                return list(self._by_reason[reason])
            elif source_queue:
                return list(self._by_source[source_queue])
            else:
                return list(self._entries.keys())

    def purge(
        self,
        reason: Optional[DeadLetterReason] = None,
        source_queue: Optional[str] = None,
        older_than: Optional[datetime] = None,
    ) -> int:
        """Purge dead letter entries.

        Args:
            reason: Filter by reason
            source_queue: Filter by source queue
            older_than: Remove entries older than this

        Returns:
            Number of entries purged
        """
        with self._lock:
            to_remove = []

            for id, entry in self._entries.items():
                if reason and entry.reason != reason:
                    continue
                if source_queue and entry.source_queue != source_queue:
                    continue
                if older_than and entry.dead_at >= older_than:
                    continue
                to_remove.append(id)

            for id in to_remove:
                self.remove(id)

            self._stats.purge_count += len(to_remove)
            logger.info(f"Purged {len(to_remove)} entries from DLQ {self.name}")
            return len(to_remove)

    def _purge_oldest(self, count: int) -> int:
        """Purge oldest entries.

        Args:
            count: Number of entries to purge

        Returns:
            Number of entries purged
        """
        entries = sorted(
            self._entries.values(),
            key=lambda e: e.dead_at,
        )[:count]

        for entry in entries:
            self.remove(entry.message.id)

        return len(entries)

    def purge_expired(self) -> int:
        """Purge entries older than retention period.

        Returns:
            Number of entries purged
        """
        cutoff = datetime.now() - timedelta(days=self.retention_days)
        return self.purge(older_than=cutoff)

    def get_by_reason(
        self,
        reason: DeadLetterReason,
        limit: int = 100,
    ) -> List[DeadLetterEntry]:
        """Get entries by reason.

        Args:
            reason: Failure reason
            limit: Maximum entries

        Returns:
            List of entries
        """
        return self.list_entries(reason=reason, limit=limit)

    def get_by_source(
        self,
        source_queue: str,
        limit: int = 100,
    ) -> List[DeadLetterEntry]:
        """Get entries by source queue.

        Args:
            source_queue: Source queue name
            limit: Maximum entries

        Returns:
            List of entries
        """
        return self.list_entries(source_queue=source_queue, limit=limit)

    def get_stats(self) -> DLQStats:
        """Get DLQ statistics."""
        with self._lock:
            stats = DLQStats(
                total_messages=len(self._entries),
                by_reason={
                    reason.name: len(ids)
                    for reason, ids in self._by_reason.items()
                },
                by_source={
                    source: len(ids)
                    for source, ids in self._by_source.items()
                },
                retry_count=self._stats.retry_count,
                purge_count=self._stats.purge_count,
            )

            # Find oldest and newest
            if self._entries:
                entries = list(self._entries.values())
                stats.oldest_message = min(e.dead_at for e in entries)
                stats.newest_message = max(e.dead_at for e in entries)

            return stats

    def get_failure_analytics(self) -> Dict[str, Any]:
        """Get analytics on failure patterns.

        Returns:
            Analytics data
        """
        with self._lock:
            total = len(self._entries)
            if total == 0:
                return {"total": 0}

            # Reason distribution
            reason_dist = {
                reason.name: len(ids) / total
                for reason, ids in self._by_reason.items()
                if ids
            }

            # Source distribution
            source_dist = {
                source: len(ids) / total
                for source, ids in self._by_source.items()
                if ids
            }

            # Error patterns
            error_counts: Dict[str, int] = defaultdict(int)
            for entry in self._entries.values():
                if entry.error:
                    # Extract error type
                    error_type = entry.error.split(":")[0][:50]
                    error_counts[error_type] += 1

            top_errors = sorted(
                error_counts.items(),
                key=lambda x: x[1],
                reverse=True,
            )[:10]

            return {
                "total": total,
                "reason_distribution": reason_dist,
                "source_distribution": source_dist,
                "top_errors": dict(top_errors),
                "retry_count": self._stats.retry_count,
                "retryable_count": sum(
                    1 for e in self._entries.values() if e.can_retry
                ),
            }

    def set_threshold_callback(
        self,
        callback: Callable[[int], None],
        threshold: int = 1000,
    ) -> None:
        """Set callback for threshold alerts.

        Args:
            callback: Function to call when threshold reached
            threshold: Number of messages to trigger alert
        """
        self._on_threshold = callback
        self._threshold = threshold

    def __len__(self) -> int:
        """Get number of entries."""
        return len(self._entries)

    def __repr__(self) -> str:
        return f"DeadLetterQueue(name={self.name!r}, entries={len(self._entries)})"


class DLQManager:
    """Manager for multiple dead letter queues."""

    def __init__(self):
        self._queues: Dict[str, DeadLetterQueue] = {}
        self._lock = threading.Lock()

    def get_or_create(
        self,
        name: str,
        **kwargs,
    ) -> DeadLetterQueue:
        """Get or create a DLQ.

        Args:
            name: DLQ name
            **kwargs: DLQ configuration

        Returns:
            DeadLetterQueue instance
        """
        with self._lock:
            if name not in self._queues:
                self._queues[name] = DeadLetterQueue(name=name, **kwargs)
            return self._queues[name]

    def get(self, name: str) -> Optional[DeadLetterQueue]:
        """Get a DLQ by name."""
        return self._queues.get(name)

    def list_queues(self) -> List[str]:
        """List all DLQ names."""
        return list(self._queues.keys())

    def get_all_stats(self) -> Dict[str, DLQStats]:
        """Get stats for all DLQs."""
        return {name: dlq.get_stats() for name, dlq in self._queues.items()}


__all__ = [
    "DeadLetterQueue",
    "DeadLetterEntry",
    "DeadLetterReason",
    "DLQStats",
    "DLQManager",
]

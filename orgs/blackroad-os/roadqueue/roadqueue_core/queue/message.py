"""RoadQueue Message - Core Message Types.

This module defines the message structures used throughout the queue system.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import json
import logging
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum, IntEnum, auto
from typing import Any, Callable, Dict, List, Optional, Set, TypeVar, Union

logger = logging.getLogger(__name__)


class MessagePriority(IntEnum):
    """Message priority levels.

    Higher values indicate higher priority.
    """

    LOWEST = 0
    LOW = 1
    NORMAL = 2
    HIGH = 3
    HIGHEST = 4
    CRITICAL = 5

    @classmethod
    def from_string(cls, value: str) -> "MessagePriority":
        """Create priority from string."""
        mapping = {
            "lowest": cls.LOWEST,
            "low": cls.LOW,
            "normal": cls.NORMAL,
            "high": cls.HIGH,
            "highest": cls.HIGHEST,
            "critical": cls.CRITICAL,
        }
        return mapping.get(value.lower(), cls.NORMAL)


class MessageState(Enum):
    """Message lifecycle states."""

    PENDING = auto()      # Waiting to be processed
    SCHEDULED = auto()    # Scheduled for future delivery
    PROCESSING = auto()   # Currently being processed
    COMPLETED = auto()    # Successfully processed
    FAILED = auto()       # Processing failed
    DEAD = auto()         # Moved to dead letter queue
    EXPIRED = auto()      # TTL exceeded
    CANCELLED = auto()    # Cancelled by user


class DeliveryMode(Enum):
    """Message delivery modes."""

    AT_MOST_ONCE = auto()   # Fire and forget
    AT_LEAST_ONCE = auto()  # Retry until acknowledged
    EXACTLY_ONCE = auto()   # Deduplication + acknowledgment


@dataclass
class MessageHeaders:
    """Message headers for metadata.

    Headers contain metadata about the message that can be used
    for routing, filtering, and processing decisions.

    Attributes:
        content_type: MIME type of message body
        content_encoding: Encoding of message body
        correlation_id: ID for correlating request/response
        reply_to: Queue name for responses
        expiration: Message TTL in milliseconds
        message_id: Unique message identifier
        timestamp: Message creation timestamp
        type: Message type for routing
        app_id: Application identifier
        user_id: User identifier
        custom: Custom headers
    """

    content_type: str = "application/json"
    content_encoding: str = "utf-8"
    correlation_id: Optional[str] = None
    reply_to: Optional[str] = None
    expiration: Optional[int] = None
    message_id: Optional[str] = None
    timestamp: Optional[int] = None
    type: Optional[str] = None
    app_id: Optional[str] = None
    user_id: Optional[str] = None
    custom: Dict[str, str] = field(default_factory=dict)

    def __post_init__(self):
        if self.message_id is None:
            self.message_id = str(uuid.uuid4())
        if self.timestamp is None:
            self.timestamp = int(time.time() * 1000)

    def to_dict(self) -> Dict[str, Any]:
        """Convert headers to dictionary."""
        result = {
            "content_type": self.content_type,
            "content_encoding": self.content_encoding,
            "message_id": self.message_id,
            "timestamp": self.timestamp,
        }
        if self.correlation_id:
            result["correlation_id"] = self.correlation_id
        if self.reply_to:
            result["reply_to"] = self.reply_to
        if self.expiration:
            result["expiration"] = self.expiration
        if self.type:
            result["type"] = self.type
        if self.app_id:
            result["app_id"] = self.app_id
        if self.user_id:
            result["user_id"] = self.user_id
        if self.custom:
            result["custom"] = self.custom
        return result

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "MessageHeaders":
        """Create headers from dictionary."""
        return cls(
            content_type=data.get("content_type", "application/json"),
            content_encoding=data.get("content_encoding", "utf-8"),
            correlation_id=data.get("correlation_id"),
            reply_to=data.get("reply_to"),
            expiration=data.get("expiration"),
            message_id=data.get("message_id"),
            timestamp=data.get("timestamp"),
            type=data.get("type"),
            app_id=data.get("app_id"),
            user_id=data.get("user_id"),
            custom=data.get("custom", {}),
        )

    def set(self, key: str, value: str) -> "MessageHeaders":
        """Set a custom header."""
        self.custom[key] = value
        return self

    def get(self, key: str, default: Optional[str] = None) -> Optional[str]:
        """Get a custom header."""
        return self.custom.get(key, default)


@dataclass
class MessageMetadata:
    """Message processing metadata.

    Tracks processing history and status.

    Attributes:
        created_at: When message was created
        enqueued_at: When message was enqueued
        scheduled_for: When message should be delivered
        started_at: When processing started
        completed_at: When processing completed
        retry_count: Number of retry attempts
        max_retries: Maximum retry attempts
        last_error: Last error message
        worker_id: ID of worker processing message
        trace_id: Distributed trace ID
        span_id: Current span ID
    """

    created_at: datetime = field(default_factory=datetime.now)
    enqueued_at: Optional[datetime] = None
    scheduled_for: Optional[datetime] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    retry_count: int = 0
    max_retries: int = 3
    last_error: Optional[str] = None
    worker_id: Optional[str] = None
    trace_id: Optional[str] = None
    span_id: Optional[str] = None
    processing_history: List[Dict[str, Any]] = field(default_factory=list)

    def record_attempt(
        self,
        worker_id: str,
        success: bool,
        error: Optional[str] = None,
        duration_ms: Optional[float] = None,
    ) -> None:
        """Record a processing attempt."""
        self.processing_history.append({
            "worker_id": worker_id,
            "timestamp": datetime.now().isoformat(),
            "success": success,
            "error": error,
            "duration_ms": duration_ms,
            "attempt": self.retry_count + 1,
        })
        if not success:
            self.retry_count += 1
            self.last_error = error

    def to_dict(self) -> Dict[str, Any]:
        """Convert metadata to dictionary."""
        return {
            "created_at": self.created_at.isoformat(),
            "enqueued_at": self.enqueued_at.isoformat() if self.enqueued_at else None,
            "scheduled_for": self.scheduled_for.isoformat() if self.scheduled_for else None,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "retry_count": self.retry_count,
            "max_retries": self.max_retries,
            "last_error": self.last_error,
            "worker_id": self.worker_id,
            "trace_id": self.trace_id,
            "span_id": self.span_id,
            "processing_history": self.processing_history,
        }


@dataclass
class Message:
    """A queue message.

    Messages are the fundamental unit of work in the queue system.
    Each message has a body, headers, and metadata for processing.

    Attributes:
        id: Unique message identifier
        body: Message payload
        headers: Message headers
        metadata: Processing metadata
        priority: Message priority
        state: Current message state
        queue_name: Target queue name
        exchange: Target exchange
        routing_key: Routing key for exchange
        delivery_mode: Delivery guarantee mode
    """

    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    body: Any = None
    headers: MessageHeaders = field(default_factory=MessageHeaders)
    metadata: MessageMetadata = field(default_factory=MessageMetadata)
    priority: MessagePriority = MessagePriority.NORMAL
    state: MessageState = MessageState.PENDING
    queue_name: Optional[str] = None
    exchange: Optional[str] = None
    routing_key: Optional[str] = None
    delivery_mode: DeliveryMode = DeliveryMode.AT_LEAST_ONCE

    # Deduplication
    _dedup_key: Optional[str] = None

    def __post_init__(self):
        # Sync message ID with headers
        if self.headers.message_id:
            self.id = self.headers.message_id
        else:
            self.headers.message_id = self.id

    @classmethod
    def create(
        cls,
        body: Any,
        queue_name: Optional[str] = None,
        priority: MessagePriority = MessagePriority.NORMAL,
        delay: Optional[timedelta] = None,
        ttl: Optional[int] = None,
        headers: Optional[Dict[str, str]] = None,
        correlation_id: Optional[str] = None,
        reply_to: Optional[str] = None,
    ) -> "Message":
        """Create a new message.

        Args:
            body: Message payload
            queue_name: Target queue name
            priority: Message priority
            delay: Delay before delivery
            ttl: Time to live in milliseconds
            headers: Custom headers
            correlation_id: Correlation ID for request/response
            reply_to: Reply queue name

        Returns:
            New message instance
        """
        msg_headers = MessageHeaders(
            expiration=ttl,
            correlation_id=correlation_id,
            reply_to=reply_to,
        )
        if headers:
            msg_headers.custom.update(headers)

        metadata = MessageMetadata()
        if delay:
            metadata.scheduled_for = datetime.now() + delay

        return cls(
            body=body,
            headers=msg_headers,
            metadata=metadata,
            priority=priority,
            queue_name=queue_name,
            state=MessageState.SCHEDULED if delay else MessageState.PENDING,
        )

    def is_expired(self) -> bool:
        """Check if message has expired."""
        if self.headers.expiration is None:
            return False
        if self.headers.timestamp is None:
            return False

        expiry_time = self.headers.timestamp + self.headers.expiration
        current_time = int(time.time() * 1000)
        return current_time > expiry_time

    def is_ready(self) -> bool:
        """Check if message is ready for delivery."""
        if self.state != MessageState.SCHEDULED:
            return True
        if self.metadata.scheduled_for is None:
            return True
        return datetime.now() >= self.metadata.scheduled_for

    def can_retry(self) -> bool:
        """Check if message can be retried."""
        return self.metadata.retry_count < self.metadata.max_retries

    def get_dedup_key(self) -> str:
        """Get deduplication key for this message.

        Uses content-based hashing for deduplication.
        """
        if self._dedup_key:
            return self._dedup_key

        # Create hash from body content
        if isinstance(self.body, (dict, list)):
            content = json.dumps(self.body, sort_keys=True)
        else:
            content = str(self.body)

        self._dedup_key = hashlib.sha256(content.encode()).hexdigest()[:16]
        return self._dedup_key

    def set_dedup_key(self, key: str) -> "Message":
        """Set custom deduplication key."""
        self._dedup_key = key
        return self

    def ack(self) -> None:
        """Acknowledge message processing."""
        self.state = MessageState.COMPLETED
        self.metadata.completed_at = datetime.now()

    def nack(self, error: Optional[str] = None, requeue: bool = True) -> None:
        """Negative acknowledge message."""
        if requeue and self.can_retry():
            self.state = MessageState.PENDING
        else:
            self.state = MessageState.FAILED

        if error:
            self.metadata.last_error = error

    def reject(self, reason: Optional[str] = None) -> None:
        """Reject message without requeue."""
        self.state = MessageState.DEAD
        if reason:
            self.metadata.last_error = reason

    def to_dict(self) -> Dict[str, Any]:
        """Serialize message to dictionary."""
        return {
            "id": self.id,
            "body": self.body,
            "headers": self.headers.to_dict(),
            "metadata": self.metadata.to_dict(),
            "priority": self.priority.value,
            "state": self.state.name,
            "queue_name": self.queue_name,
            "exchange": self.exchange,
            "routing_key": self.routing_key,
            "delivery_mode": self.delivery_mode.name,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Message":
        """Deserialize message from dictionary."""
        headers = MessageHeaders.from_dict(data.get("headers", {}))

        metadata = MessageMetadata()
        if "metadata" in data:
            meta = data["metadata"]
            if meta.get("created_at"):
                metadata.created_at = datetime.fromisoformat(meta["created_at"])
            if meta.get("enqueued_at"):
                metadata.enqueued_at = datetime.fromisoformat(meta["enqueued_at"])
            if meta.get("scheduled_for"):
                metadata.scheduled_for = datetime.fromisoformat(meta["scheduled_for"])
            metadata.retry_count = meta.get("retry_count", 0)
            metadata.max_retries = meta.get("max_retries", 3)
            metadata.last_error = meta.get("last_error")
            metadata.worker_id = meta.get("worker_id")
            metadata.trace_id = meta.get("trace_id")
            metadata.processing_history = meta.get("processing_history", [])

        return cls(
            id=data.get("id", str(uuid.uuid4())),
            body=data.get("body"),
            headers=headers,
            metadata=metadata,
            priority=MessagePriority(data.get("priority", 2)),
            state=MessageState[data.get("state", "PENDING")],
            queue_name=data.get("queue_name"),
            exchange=data.get("exchange"),
            routing_key=data.get("routing_key"),
            delivery_mode=DeliveryMode[data.get("delivery_mode", "AT_LEAST_ONCE")],
        )

    def clone(self) -> "Message":
        """Create a copy of this message with new ID."""
        return Message(
            id=str(uuid.uuid4()),
            body=self.body,
            headers=MessageHeaders(
                content_type=self.headers.content_type,
                content_encoding=self.headers.content_encoding,
                correlation_id=self.headers.correlation_id,
                reply_to=self.headers.reply_to,
                expiration=self.headers.expiration,
                type=self.headers.type,
                app_id=self.headers.app_id,
                user_id=self.headers.user_id,
                custom=dict(self.headers.custom),
            ),
            metadata=MessageMetadata(max_retries=self.metadata.max_retries),
            priority=self.priority,
            queue_name=self.queue_name,
            exchange=self.exchange,
            routing_key=self.routing_key,
            delivery_mode=self.delivery_mode,
        )

    def __repr__(self) -> str:
        return f"Message(id={self.id!r}, state={self.state.name}, priority={self.priority.name})"


class MessageBatch:
    """A batch of messages for bulk operations.

    Provides efficient handling of multiple messages.
    """

    def __init__(self, messages: Optional[List[Message]] = None):
        self.messages: List[Message] = messages or []
        self._index: Dict[str, Message] = {m.id: m for m in self.messages}

    def add(self, message: Message) -> None:
        """Add a message to the batch."""
        self.messages.append(message)
        self._index[message.id] = message

    def remove(self, message_id: str) -> Optional[Message]:
        """Remove a message from the batch."""
        message = self._index.pop(message_id, None)
        if message:
            self.messages = [m for m in self.messages if m.id != message_id]
        return message

    def get(self, message_id: str) -> Optional[Message]:
        """Get a message by ID."""
        return self._index.get(message_id)

    def __len__(self) -> int:
        return len(self.messages)

    def __iter__(self):
        return iter(self.messages)

    def ack_all(self) -> None:
        """Acknowledge all messages."""
        for msg in self.messages:
            msg.ack()

    def nack_all(self, error: Optional[str] = None) -> None:
        """Negative acknowledge all messages."""
        for msg in self.messages:
            msg.nack(error)

    def to_list(self) -> List[Dict[str, Any]]:
        """Serialize batch to list of dictionaries."""
        return [m.to_dict() for m in self.messages]

    @classmethod
    def from_list(cls, data: List[Dict[str, Any]]) -> "MessageBatch":
        """Deserialize batch from list of dictionaries."""
        messages = [Message.from_dict(d) for d in data]
        return cls(messages)


class MessageBuilder:
    """Fluent builder for creating messages."""

    def __init__(self):
        self._body: Any = None
        self._queue_name: Optional[str] = None
        self._exchange: Optional[str] = None
        self._routing_key: Optional[str] = None
        self._priority: MessagePriority = MessagePriority.NORMAL
        self._delay: Optional[timedelta] = None
        self._ttl: Optional[int] = None
        self._headers: Dict[str, str] = {}
        self._correlation_id: Optional[str] = None
        self._reply_to: Optional[str] = None
        self._max_retries: int = 3
        self._delivery_mode: DeliveryMode = DeliveryMode.AT_LEAST_ONCE

    def body(self, body: Any) -> "MessageBuilder":
        """Set message body."""
        self._body = body
        return self

    def queue(self, name: str) -> "MessageBuilder":
        """Set target queue."""
        self._queue_name = name
        return self

    def exchange(self, name: str) -> "MessageBuilder":
        """Set target exchange."""
        self._exchange = name
        return self

    def routing_key(self, key: str) -> "MessageBuilder":
        """Set routing key."""
        self._routing_key = key
        return self

    def priority(self, priority: MessagePriority) -> "MessageBuilder":
        """Set message priority."""
        self._priority = priority
        return self

    def high_priority(self) -> "MessageBuilder":
        """Set high priority."""
        self._priority = MessagePriority.HIGH
        return self

    def critical(self) -> "MessageBuilder":
        """Set critical priority."""
        self._priority = MessagePriority.CRITICAL
        return self

    def delay(self, delay: timedelta) -> "MessageBuilder":
        """Set delivery delay."""
        self._delay = delay
        return self

    def delay_seconds(self, seconds: int) -> "MessageBuilder":
        """Set delivery delay in seconds."""
        self._delay = timedelta(seconds=seconds)
        return self

    def ttl(self, ttl_ms: int) -> "MessageBuilder":
        """Set time to live in milliseconds."""
        self._ttl = ttl_ms
        return self

    def ttl_seconds(self, seconds: int) -> "MessageBuilder":
        """Set time to live in seconds."""
        self._ttl = seconds * 1000
        return self

    def header(self, key: str, value: str) -> "MessageBuilder":
        """Add a header."""
        self._headers[key] = value
        return self

    def headers(self, headers: Dict[str, str]) -> "MessageBuilder":
        """Add multiple headers."""
        self._headers.update(headers)
        return self

    def correlation_id(self, id: str) -> "MessageBuilder":
        """Set correlation ID."""
        self._correlation_id = id
        return self

    def reply_to(self, queue: str) -> "MessageBuilder":
        """Set reply queue."""
        self._reply_to = queue
        return self

    def max_retries(self, retries: int) -> "MessageBuilder":
        """Set maximum retry attempts."""
        self._max_retries = retries
        return self

    def at_most_once(self) -> "MessageBuilder":
        """Set at-most-once delivery."""
        self._delivery_mode = DeliveryMode.AT_MOST_ONCE
        return self

    def at_least_once(self) -> "MessageBuilder":
        """Set at-least-once delivery."""
        self._delivery_mode = DeliveryMode.AT_LEAST_ONCE
        return self

    def exactly_once(self) -> "MessageBuilder":
        """Set exactly-once delivery."""
        self._delivery_mode = DeliveryMode.EXACTLY_ONCE
        return self

    def build(self) -> Message:
        """Build the message."""
        message = Message.create(
            body=self._body,
            queue_name=self._queue_name,
            priority=self._priority,
            delay=self._delay,
            ttl=self._ttl,
            headers=self._headers,
            correlation_id=self._correlation_id,
            reply_to=self._reply_to,
        )
        message.exchange = self._exchange
        message.routing_key = self._routing_key
        message.delivery_mode = self._delivery_mode
        message.metadata.max_retries = self._max_retries
        return message


__all__ = [
    "Message",
    "MessageHeaders",
    "MessageMetadata",
    "MessageState",
    "MessagePriority",
    "DeliveryMode",
    "MessageBatch",
    "MessageBuilder",
]

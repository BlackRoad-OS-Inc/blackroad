"""
RoadPubSub - Pub/Sub Messaging for BlackRoad
Topic-based publish/subscribe with patterns and message filtering.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Pattern, Set
import asyncio
import fnmatch
import hashlib
import json
import logging
import re
import threading
import uuid

logger = logging.getLogger(__name__)


class DeliveryMode(str, Enum):
    """Message delivery modes."""
    AT_MOST_ONCE = "at_most_once"
    AT_LEAST_ONCE = "at_least_once"


class AckMode(str, Enum):
    """Acknowledgement modes."""
    AUTO = "auto"
    MANUAL = "manual"


@dataclass
class Message:
    """A pub/sub message."""
    id: str
    topic: str
    data: Any
    timestamp: datetime = field(default_factory=datetime.now)
    headers: Dict[str, str] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)
    ttl: Optional[int] = None  # Time to live in seconds

    @property
    def is_expired(self) -> bool:
        if self.ttl is None:
            return False
        age = (datetime.now() - self.timestamp).total_seconds()
        return age > self.ttl

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "topic": self.topic,
            "data": self.data,
            "timestamp": self.timestamp.isoformat(),
            "headers": self.headers
        }


@dataclass
class Subscription:
    """A topic subscription."""
    id: str
    pattern: str
    handler: Callable[[Message], None]
    is_pattern: bool = False
    ack_mode: AckMode = AckMode.AUTO
    filter_fn: Optional[Callable[[Message], bool]] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)
    _compiled_pattern: Optional[Pattern] = None

    def __post_init__(self):
        if self.is_pattern:
            # Convert glob pattern to regex
            regex = fnmatch.translate(self.pattern)
            self._compiled_pattern = re.compile(regex)

    def matches(self, topic: str) -> bool:
        """Check if topic matches subscription."""
        if self.is_pattern and self._compiled_pattern:
            return bool(self._compiled_pattern.match(topic))
        return topic == self.pattern

    def should_deliver(self, message: Message) -> bool:
        """Check if message should be delivered."""
        if not self.matches(message.topic):
            return False
        if self.filter_fn and not self.filter_fn(message):
            return False
        return True


@dataclass
class Topic:
    """A pub/sub topic."""
    name: str
    subscriptions: Set[str] = field(default_factory=set)
    message_count: int = 0
    created_at: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)


class MessageStore:
    """Store for message persistence."""

    def __init__(self, max_messages: int = 10000):
        self.max_messages = max_messages
        self.messages: Dict[str, Message] = {}
        self.topic_messages: Dict[str, List[str]] = {}
        self._lock = threading.Lock()

    def store(self, message: Message) -> None:
        """Store a message."""
        with self._lock:
            # Evict old messages if needed
            if len(self.messages) >= self.max_messages:
                self._evict_oldest()

            self.messages[message.id] = message

            if message.topic not in self.topic_messages:
                self.topic_messages[message.topic] = []
            self.topic_messages[message.topic].append(message.id)

    def get(self, message_id: str) -> Optional[Message]:
        """Get a message by ID."""
        return self.messages.get(message_id)

    def get_topic_messages(self, topic: str, limit: int = 100) -> List[Message]:
        """Get messages for a topic."""
        message_ids = self.topic_messages.get(topic, [])[-limit:]
        return [
            self.messages[mid]
            for mid in message_ids
            if mid in self.messages
        ]

    def _evict_oldest(self) -> None:
        """Evict oldest messages."""
        # Remove 10% of max
        to_remove = self.max_messages // 10

        sorted_messages = sorted(
            self.messages.values(),
            key=lambda m: m.timestamp
        )

        for message in sorted_messages[:to_remove]:
            self.delete(message.id)

    def delete(self, message_id: str) -> bool:
        """Delete a message."""
        with self._lock:
            if message_id in self.messages:
                message = self.messages[message_id]
                del self.messages[message_id]

                if message.topic in self.topic_messages:
                    try:
                        self.topic_messages[message.topic].remove(message_id)
                    except ValueError:
                        pass

                return True
            return False


class PubSubBroker:
    """Core pub/sub broker."""

    def __init__(self, delivery_mode: DeliveryMode = DeliveryMode.AT_LEAST_ONCE):
        self.delivery_mode = delivery_mode
        self.topics: Dict[str, Topic] = {}
        self.subscriptions: Dict[str, Subscription] = {}
        self.pattern_subscriptions: List[str] = []
        self.store = MessageStore()
        self._lock = threading.Lock()
        self._pending_acks: Dict[str, Set[str]] = {}  # message_id -> subscription_ids

    def create_topic(self, name: str, **metadata) -> Topic:
        """Create a topic."""
        with self._lock:
            if name not in self.topics:
                self.topics[name] = Topic(name=name, metadata=metadata)
            return self.topics[name]

    def delete_topic(self, name: str) -> bool:
        """Delete a topic."""
        with self._lock:
            if name in self.topics:
                # Remove subscriptions for this topic
                topic = self.topics[name]
                for sub_id in list(topic.subscriptions):
                    self.unsubscribe(sub_id)
                del self.topics[name]
                return True
            return False

    def subscribe(
        self,
        pattern: str,
        handler: Callable[[Message], None],
        is_pattern: bool = False,
        ack_mode: AckMode = AckMode.AUTO,
        filter_fn: Callable[[Message], bool] = None
    ) -> str:
        """Subscribe to a topic or pattern."""
        subscription = Subscription(
            id=str(uuid.uuid4())[:12],
            pattern=pattern,
            handler=handler,
            is_pattern=is_pattern,
            ack_mode=ack_mode,
            filter_fn=filter_fn
        )

        with self._lock:
            self.subscriptions[subscription.id] = subscription

            if is_pattern:
                self.pattern_subscriptions.append(subscription.id)
            else:
                # Direct subscription to topic
                if pattern not in self.topics:
                    self.create_topic(pattern)
                self.topics[pattern].subscriptions.add(subscription.id)

        logger.debug(f"Subscription {subscription.id} created for {pattern}")
        return subscription.id

    def unsubscribe(self, subscription_id: str) -> bool:
        """Unsubscribe."""
        with self._lock:
            if subscription_id not in self.subscriptions:
                return False

            subscription = self.subscriptions[subscription_id]

            # Remove from topic
            if not subscription.is_pattern:
                if subscription.pattern in self.topics:
                    self.topics[subscription.pattern].subscriptions.discard(subscription_id)
            else:
                if subscription_id in self.pattern_subscriptions:
                    self.pattern_subscriptions.remove(subscription_id)

            del self.subscriptions[subscription_id]

        return True

    async def publish(
        self,
        topic: str,
        data: Any,
        headers: Dict[str, str] = None,
        ttl: int = None
    ) -> Message:
        """Publish a message."""
        message = Message(
            id=str(uuid.uuid4()),
            topic=topic,
            data=data,
            headers=headers or {},
            ttl=ttl
        )

        # Store message
        self.store.store(message)

        # Update topic stats
        if topic in self.topics:
            self.topics[topic].message_count += 1
        else:
            self.create_topic(topic)
            self.topics[topic].message_count = 1

        # Deliver to subscribers
        await self._deliver(message)

        return message

    async def _deliver(self, message: Message) -> None:
        """Deliver message to matching subscribers."""
        if message.is_expired:
            return

        matching_subs = []

        # Check direct subscriptions
        if message.topic in self.topics:
            for sub_id in self.topics[message.topic].subscriptions:
                if sub_id in self.subscriptions:
                    matching_subs.append(self.subscriptions[sub_id])

        # Check pattern subscriptions
        for sub_id in self.pattern_subscriptions:
            if sub_id in self.subscriptions:
                sub = self.subscriptions[sub_id]
                if sub.matches(message.topic):
                    matching_subs.append(sub)

        # Deliver to matching subscriptions
        for subscription in matching_subs:
            if not subscription.should_deliver(message):
                continue

            if subscription.ack_mode == AckMode.MANUAL:
                # Track pending ack
                if message.id not in self._pending_acks:
                    self._pending_acks[message.id] = set()
                self._pending_acks[message.id].add(subscription.id)

            try:
                result = subscription.handler(message)
                if asyncio.iscoroutine(result):
                    await result
            except Exception as e:
                logger.error(f"Handler error for subscription {subscription.id}: {e}")

    def ack(self, message_id: str, subscription_id: str) -> bool:
        """Acknowledge message delivery."""
        if message_id in self._pending_acks:
            self._pending_acks[message_id].discard(subscription_id)
            if not self._pending_acks[message_id]:
                del self._pending_acks[message_id]
            return True
        return False

    def get_pending_acks(self, subscription_id: str) -> List[str]:
        """Get messages pending acknowledgement."""
        pending = []
        for message_id, subs in self._pending_acks.items():
            if subscription_id in subs:
                pending.append(message_id)
        return pending


class Publisher:
    """Publisher client."""

    def __init__(self, broker: PubSubBroker):
        self.broker = broker

    async def publish(
        self,
        topic: str,
        data: Any,
        **kwargs
    ) -> Message:
        """Publish message."""
        return await self.broker.publish(topic, data, **kwargs)

    async def publish_batch(
        self,
        messages: List[Dict[str, Any]]
    ) -> List[Message]:
        """Publish multiple messages."""
        return [
            await self.broker.publish(
                topic=m["topic"],
                data=m["data"],
                headers=m.get("headers"),
                ttl=m.get("ttl")
            )
            for m in messages
        ]


class Subscriber:
    """Subscriber client."""

    def __init__(self, broker: PubSubBroker):
        self.broker = broker
        self._subscriptions: Dict[str, str] = {}  # pattern -> subscription_id

    def subscribe(
        self,
        pattern: str,
        handler: Callable[[Message], None],
        is_pattern: bool = False,
        **kwargs
    ) -> str:
        """Subscribe to topic/pattern."""
        sub_id = self.broker.subscribe(pattern, handler, is_pattern, **kwargs)
        self._subscriptions[pattern] = sub_id
        return sub_id

    def unsubscribe(self, pattern: str) -> bool:
        """Unsubscribe from topic/pattern."""
        if pattern in self._subscriptions:
            result = self.broker.unsubscribe(self._subscriptions[pattern])
            del self._subscriptions[pattern]
            return result
        return False

    def unsubscribe_all(self) -> None:
        """Unsubscribe from all."""
        for pattern in list(self._subscriptions.keys()):
            self.unsubscribe(pattern)


class PubSubManager:
    """High-level pub/sub management."""

    def __init__(self):
        self.broker = PubSubBroker()

    def publisher(self) -> Publisher:
        """Get a publisher."""
        return Publisher(self.broker)

    def subscriber(self) -> Subscriber:
        """Get a subscriber."""
        return Subscriber(self.broker)

    def create_topic(self, name: str, **metadata) -> Topic:
        """Create a topic."""
        return self.broker.create_topic(name, **metadata)

    def delete_topic(self, name: str) -> bool:
        """Delete a topic."""
        return self.broker.delete_topic(name)

    def list_topics(self) -> List[Dict[str, Any]]:
        """List all topics."""
        return [
            {
                "name": t.name,
                "subscriptions": len(t.subscriptions),
                "message_count": t.message_count
            }
            for t in self.broker.topics.values()
        ]

    def get_topic_messages(self, topic: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Get recent messages for a topic."""
        messages = self.broker.store.get_topic_messages(topic, limit)
        return [m.to_dict() for m in messages]


# Example usage
async def example_usage():
    """Example pub/sub usage."""
    manager = PubSubManager()

    # Create topics
    manager.create_topic("events.user")
    manager.create_topic("events.order")

    # Get publisher and subscriber
    pub = manager.publisher()
    sub = manager.subscriber()

    # Subscribe to specific topic
    received_messages = []

    def handler(msg: Message):
        received_messages.append(msg)
        print(f"Received on {msg.topic}: {msg.data}")

    sub.subscribe("events.user", handler)

    # Subscribe to pattern (all events)
    sub.subscribe("events.*", handler, is_pattern=True)

    # Subscribe with filter
    sub.subscribe(
        "events.order",
        handler,
        filter_fn=lambda m: m.data.get("amount", 0) > 100
    )

    # Publish messages
    await pub.publish("events.user", {"action": "signup", "user_id": "123"})
    await pub.publish("events.order", {"action": "placed", "order_id": "456", "amount": 150})
    await pub.publish("events.order", {"action": "placed", "order_id": "789", "amount": 50})

    print(f"\nReceived {len(received_messages)} messages")

    # List topics
    topics = manager.list_topics()
    print(f"\nTopics: {topics}")

    # Get recent messages
    messages = manager.get_topic_messages("events.user")
    print(f"\nUser events: {len(messages)}")


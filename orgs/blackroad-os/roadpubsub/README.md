# RoadPubSub

> Topic-based publish/subscribe messaging for BlackRoad OS with patterns and filtering

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![BlackRoad OS](https://img.shields.io/badge/BlackRoad-OS-FF1D6C.svg)](https://github.com/BlackRoad-OS)

## Overview

RoadPubSub provides a powerful pub/sub messaging system with:

- **Topic-Based Routing** - Publish to topics, subscribe to receive
- **Pattern Matching** - Subscribe to wildcard patterns (`events.*`)
- **Message Filtering** - Filter messages with custom functions
- **Acknowledgements** - Manual or auto acknowledgement modes
- **Message Persistence** - In-memory message store with TTL
- **Delivery Guarantees** - At-most-once or at-least-once delivery

## Installation

```bash
pip install roadpubsub
```

## Quick Start

```python
import asyncio
from roadpubsub import PubSubManager, Message

manager = PubSubManager()

# Get publisher and subscriber
pub = manager.publisher()
sub = manager.subscriber()

# Subscribe to topic
def handler(msg: Message):
    print(f"Received on {msg.topic}: {msg.data}")

sub.subscribe("events.user", handler)

# Publish message
await pub.publish("events.user", {"action": "signup", "user_id": "123"})
```

## Subscriptions

### Direct Subscription

```python
# Subscribe to exact topic
sub.subscribe("orders.created", handler)
```

### Pattern Subscription

```python
# Subscribe to pattern (glob-style)
sub.subscribe("events.*", handler, is_pattern=True)     # events.user, events.order
sub.subscribe("logs.*.*", handler, is_pattern=True)     # logs.app.error, logs.db.query
```

### Filtered Subscription

```python
# Subscribe with filter function
sub.subscribe(
    "orders",
    handler,
    filter_fn=lambda msg: msg.data.get("amount", 0) > 100
)
```

### Manual Acknowledgement

```python
from roadpubsub import AckMode

def handler(msg: Message):
    try:
        process(msg)
        broker.ack(msg.id, subscription_id)
    except:
        # Message will be redelivered
        pass

sub_id = sub.subscribe("critical.events", handler, ack_mode=AckMode.MANUAL)
```

## Publishing

### Basic Publish

```python
await pub.publish("topic.name", {"key": "value"})
```

### With Headers

```python
await pub.publish(
    "events.user",
    {"user_id": "123"},
    headers={"correlation_id": "abc-123", "source": "api"}
)
```

### With TTL

```python
# Message expires after 60 seconds
await pub.publish("notifications", data, ttl=60)
```

### Batch Publish

```python
messages = [
    {"topic": "events.user", "data": {"action": "login"}},
    {"topic": "events.order", "data": {"action": "placed"}},
]
await pub.publish_batch(messages)
```

## Topic Management

```python
# Create topic with metadata
manager.create_topic("events.user", description="User events", owner="team-a")

# List topics
topics = manager.list_topics()
# [{"name": "events.user", "subscriptions": 5, "message_count": 1234}]

# Get recent messages
messages = manager.get_topic_messages("events.user", limit=50)

# Delete topic
manager.delete_topic("events.user")
```

## Message Structure

```python
from roadpubsub import Message

message = Message(
    id="uuid",
    topic="events.user",
    data={"action": "signup"},
    timestamp=datetime.now(),
    headers={"source": "api"},
    ttl=3600  # Optional TTL in seconds
)

# Properties
message.is_expired    # bool - Check if TTL exceeded
message.to_dict()     # Dict representation
```

## Delivery Modes

```python
from roadpubsub import PubSubBroker, DeliveryMode

# At-most-once (fire and forget)
broker = PubSubBroker(delivery_mode=DeliveryMode.AT_MOST_ONCE)

# At-least-once (with acknowledgements)
broker = PubSubBroker(delivery_mode=DeliveryMode.AT_LEAST_ONCE)
```

## Message Store

```python
from roadpubsub import MessageStore

# Custom store with max messages
store = MessageStore(max_messages=50000)

# Store message
store.store(message)

# Get message
msg = store.get(message_id)

# Get topic messages
messages = store.get_topic_messages("events.user", limit=100)

# Delete message
store.delete(message_id)
```

## API Reference

### Classes

| Class | Description |
|-------|-------------|
| `PubSubManager` | High-level pub/sub management |
| `PubSubBroker` | Core broker implementation |
| `Publisher` | Publisher client |
| `Subscriber` | Subscriber client |
| `Message` | Message dataclass |
| `Subscription` | Subscription dataclass |
| `Topic` | Topic dataclass |
| `MessageStore` | Message persistence |

### Enums

- `DeliveryMode`: AT_MOST_ONCE, AT_LEAST_ONCE
- `AckMode`: AUTO, MANUAL

### Subscription Methods

```python
# Subscribe
sub_id = sub.subscribe(pattern, handler, is_pattern=False, ack_mode=AckMode.AUTO, filter_fn=None)

# Unsubscribe
sub.unsubscribe(pattern)

# Unsubscribe all
sub.unsubscribe_all()
```

### Publisher Methods

```python
# Single publish
message = await pub.publish(topic, data, headers=None, ttl=None)

# Batch publish
messages = await pub.publish_batch([{"topic": "...", "data": {...}}, ...])
```

## License

Proprietary - BlackRoad OS, Inc. All rights reserved.

## Related

- [roadhttp](https://github.com/BlackRoad-OS/roadhttp) - HTTP client
- [roadrpc](https://github.com/BlackRoad-OS/roadrpc) - JSON-RPC
- [roadwebsocket](https://github.com/BlackRoad-OS/roadwebsocket) - WebSocket

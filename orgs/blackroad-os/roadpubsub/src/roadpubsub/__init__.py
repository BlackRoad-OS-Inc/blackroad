"""
RoadPubSub - Pub/Sub Messaging for BlackRoad OS

Topic-based publish/subscribe messaging with pattern matching,
message filtering, acknowledgements, and persistence.
"""

from .pubsub import (
    PubSubManager,
    PubSubBroker,
    Publisher,
    Subscriber,
    Message,
    Subscription,
    Topic,
    MessageStore,
    DeliveryMode,
    AckMode,
)

__version__ = "0.1.0"
__author__ = "BlackRoad OS"
__all__ = [
    # Manager
    "PubSubManager",
    "PubSubBroker",
    # Clients
    "Publisher",
    "Subscriber",
    # Data classes
    "Message",
    "Subscription",
    "Topic",
    # Storage
    "MessageStore",
    # Enums
    "DeliveryMode",
    "AckMode",
]

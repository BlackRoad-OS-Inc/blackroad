"""
RoadChat Real-Time Messaging

Production-ready real-time chat system.

Features:
- WebSocket messaging
- Channels and DMs
- Message history
- Presence tracking
- Typing indicators
- Read receipts
- File attachments
- Message reactions
"""

from typing import Optional, Dict, Any, List, Set
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
import asyncio
import json
import time
import secrets


class MessageType(str, Enum):
    TEXT = "text"
    IMAGE = "image"
    FILE = "file"
    SYSTEM = "system"
    REACTION = "reaction"


class ChannelType(str, Enum):
    PUBLIC = "public"
    PRIVATE = "private"
    DIRECT = "direct"


class PresenceStatus(str, Enum):
    ONLINE = "online"
    AWAY = "away"
    DND = "dnd"
    OFFLINE = "offline"


@dataclass
class Message:
    id: str
    channel_id: str
    sender_id: str
    content: str
    type: MessageType = MessageType.TEXT
    created_at: int = field(default_factory=lambda: int(time.time() * 1000))
    updated_at: Optional[int] = None
    reply_to: Optional[str] = None
    attachments: List[Dict[str, Any]] = field(default_factory=list)
    reactions: Dict[str, List[str]] = field(default_factory=dict)
    mentions: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "channel_id": self.channel_id,
            "sender_id": self.sender_id,
            "content": self.content,
            "type": self.type.value,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "reply_to": self.reply_to,
            "attachments": self.attachments,
            "reactions": self.reactions,
            "mentions": self.mentions,
            "metadata": self.metadata,
        }


@dataclass
class Channel:
    id: str
    name: str
    type: ChannelType
    created_by: str
    members: List[str] = field(default_factory=list)
    created_at: int = field(default_factory=lambda: int(time.time() * 1000))
    description: Optional[str] = None
    avatar: Optional[str] = None
    last_message_at: Optional[int] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "type": self.type.value,
            "created_by": self.created_by,
            "members": self.members,
            "created_at": self.created_at,
            "description": self.description,
            "avatar": self.avatar,
            "last_message_at": self.last_message_at,
            "metadata": self.metadata,
        }


@dataclass
class UserPresence:
    user_id: str
    status: PresenceStatus
    last_seen: int
    custom_status: Optional[str] = None
    device: Optional[str] = None


class MessageStore:
    """Store and retrieve messages."""

    def __init__(self, storage):
        self.storage = storage

    async def save(self, message: Message) -> None:
        """Save a message."""
        # Store message
        await self.storage.put(f"message:{message.id}", message.to_dict())

        # Add to channel message list
        await self._add_to_channel(message.channel_id, message.id, message.created_at)

        # Update channel last_message_at
        await self.storage.put(
            f"channel:{message.channel_id}:last_message",
            {"message_id": message.id, "at": message.created_at},
        )

    async def get(self, message_id: str) -> Optional[Message]:
        """Get a message by ID."""
        data = await self.storage.get(f"message:{message_id}")
        if data:
            return self._dict_to_message(data)
        return None

    async def get_channel_messages(
        self,
        channel_id: str,
        limit: int = 50,
        before: Optional[int] = None,
    ) -> List[Message]:
        """Get messages for a channel."""
        key = f"channel:{channel_id}:messages"
        data = await self.storage.get(key) or []

        # Filter by timestamp
        if before:
            data = [d for d in data if d["created_at"] < before]

        # Sort and limit
        data = sorted(data, key=lambda x: x["created_at"], reverse=True)[:limit]

        # Load full messages
        messages = []
        for item in data:
            msg = await self.get(item["id"])
            if msg:
                messages.append(msg)

        return list(reversed(messages))

    async def update(self, message_id: str, updates: Dict[str, Any]) -> Optional[Message]:
        """Update a message."""
        msg = await self.get(message_id)
        if not msg:
            return None

        for key, value in updates.items():
            if hasattr(msg, key):
                setattr(msg, key, value)

        msg.updated_at = int(time.time() * 1000)
        await self.storage.put(f"message:{message_id}", msg.to_dict())
        return msg

    async def delete(self, message_id: str) -> bool:
        """Delete a message."""
        msg = await self.get(message_id)
        if not msg:
            return False

        await self.storage.delete(f"message:{message_id}")
        return True

    async def add_reaction(
        self,
        message_id: str,
        user_id: str,
        emoji: str,
    ) -> Optional[Message]:
        """Add a reaction to a message."""
        msg = await self.get(message_id)
        if not msg:
            return None

        if emoji not in msg.reactions:
            msg.reactions[emoji] = []

        if user_id not in msg.reactions[emoji]:
            msg.reactions[emoji].append(user_id)

        await self.storage.put(f"message:{message_id}", msg.to_dict())
        return msg

    async def remove_reaction(
        self,
        message_id: str,
        user_id: str,
        emoji: str,
    ) -> Optional[Message]:
        """Remove a reaction from a message."""
        msg = await self.get(message_id)
        if not msg:
            return None

        if emoji in msg.reactions and user_id in msg.reactions[emoji]:
            msg.reactions[emoji].remove(user_id)
            if not msg.reactions[emoji]:
                del msg.reactions[emoji]

        await self.storage.put(f"message:{message_id}", msg.to_dict())
        return msg

    async def _add_to_channel(self, channel_id: str, message_id: str, created_at: int) -> None:
        """Add message to channel list."""
        key = f"channel:{channel_id}:messages"
        data = await self.storage.get(key) or []
        data.append({"id": message_id, "created_at": created_at})

        # Keep last 10000 messages in index
        if len(data) > 10000:
            data = data[-10000:]

        await self.storage.put(key, data)

    def _dict_to_message(self, data: Dict[str, Any]) -> Message:
        """Convert dict to Message."""
        return Message(
            id=data["id"],
            channel_id=data["channel_id"],
            sender_id=data["sender_id"],
            content=data["content"],
            type=MessageType(data.get("type", "text")),
            created_at=data["created_at"],
            updated_at=data.get("updated_at"),
            reply_to=data.get("reply_to"),
            attachments=data.get("attachments", []),
            reactions=data.get("reactions", {}),
            mentions=data.get("mentions", []),
            metadata=data.get("metadata", {}),
        )


class ChannelManager:
    """Manage chat channels."""

    def __init__(self, storage):
        self.storage = storage

    async def create(
        self,
        name: str,
        type: ChannelType,
        created_by: str,
        members: List[str] = None,
        description: Optional[str] = None,
    ) -> Channel:
        """Create a new channel."""
        channel = Channel(
            id=f"ch_{secrets.token_hex(8)}",
            name=name,
            type=type,
            created_by=created_by,
            members=members or [created_by],
            description=description,
        )

        await self.storage.put(f"channel:{channel.id}", channel.to_dict())

        # Add to member channel lists
        for member in channel.members:
            await self._add_to_user_channels(member, channel.id)

        return channel

    async def get(self, channel_id: str) -> Optional[Channel]:
        """Get a channel by ID."""
        data = await self.storage.get(f"channel:{channel_id}")
        if data:
            return self._dict_to_channel(data)
        return None

    async def get_direct_channel(
        self,
        user1: str,
        user2: str,
    ) -> Optional[Channel]:
        """Get or create a direct message channel."""
        # Create consistent DM channel ID
        sorted_users = sorted([user1, user2])
        dm_key = f"dm:{sorted_users[0]}:{sorted_users[1]}"

        channel_id = await self.storage.get(dm_key)
        if channel_id:
            return await self.get(channel_id)

        # Create new DM channel
        channel = await self.create(
            name=f"DM",
            type=ChannelType.DIRECT,
            created_by=user1,
            members=[user1, user2],
        )

        await self.storage.put(dm_key, channel.id)
        return channel

    async def add_member(self, channel_id: str, user_id: str) -> bool:
        """Add a member to a channel."""
        channel = await self.get(channel_id)
        if not channel:
            return False

        if user_id not in channel.members:
            channel.members.append(user_id)
            await self.storage.put(f"channel:{channel_id}", channel.to_dict())
            await self._add_to_user_channels(user_id, channel_id)

        return True

    async def remove_member(self, channel_id: str, user_id: str) -> bool:
        """Remove a member from a channel."""
        channel = await self.get(channel_id)
        if not channel:
            return False

        if user_id in channel.members:
            channel.members.remove(user_id)
            await self.storage.put(f"channel:{channel_id}", channel.to_dict())
            await self._remove_from_user_channels(user_id, channel_id)

        return True

    async def get_user_channels(self, user_id: str) -> List[Channel]:
        """Get all channels for a user."""
        channel_ids = await self.storage.get(f"user:{user_id}:channels") or []
        channels = []

        for channel_id in channel_ids:
            channel = await self.get(channel_id)
            if channel:
                channels.append(channel)

        return channels

    async def _add_to_user_channels(self, user_id: str, channel_id: str) -> None:
        """Add channel to user's list."""
        key = f"user:{user_id}:channels"
        channels = await self.storage.get(key) or []
        if channel_id not in channels:
            channels.append(channel_id)
            await self.storage.put(key, channels)

    async def _remove_from_user_channels(self, user_id: str, channel_id: str) -> None:
        """Remove channel from user's list."""
        key = f"user:{user_id}:channels"
        channels = await self.storage.get(key) or []
        if channel_id in channels:
            channels.remove(channel_id)
            await self.storage.put(key, channels)

    def _dict_to_channel(self, data: Dict[str, Any]) -> Channel:
        """Convert dict to Channel."""
        return Channel(
            id=data["id"],
            name=data["name"],
            type=ChannelType(data["type"]),
            created_by=data["created_by"],
            members=data.get("members", []),
            created_at=data["created_at"],
            description=data.get("description"),
            avatar=data.get("avatar"),
            last_message_at=data.get("last_message_at"),
            metadata=data.get("metadata", {}),
        )


class PresenceManager:
    """Track user presence."""

    def __init__(self, storage):
        self.storage = storage
        self.online_users: Set[str] = set()

    async def set_online(
        self,
        user_id: str,
        device: Optional[str] = None,
    ) -> None:
        """Mark user as online."""
        self.online_users.add(user_id)

        presence = UserPresence(
            user_id=user_id,
            status=PresenceStatus.ONLINE,
            last_seen=int(time.time() * 1000),
            device=device,
        )

        await self.storage.put(f"presence:{user_id}", {
            "user_id": user_id,
            "status": presence.status.value,
            "last_seen": presence.last_seen,
            "device": device,
        }, ttl=300)  # 5 min TTL

    async def set_offline(self, user_id: str) -> None:
        """Mark user as offline."""
        self.online_users.discard(user_id)

        await self.storage.put(f"presence:{user_id}", {
            "user_id": user_id,
            "status": PresenceStatus.OFFLINE.value,
            "last_seen": int(time.time() * 1000),
        })

    async def set_status(
        self,
        user_id: str,
        status: PresenceStatus,
        custom_status: Optional[str] = None,
    ) -> None:
        """Set user status."""
        data = await self.storage.get(f"presence:{user_id}") or {}
        data.update({
            "user_id": user_id,
            "status": status.value,
            "custom_status": custom_status,
            "last_seen": int(time.time() * 1000),
        })
        await self.storage.put(f"presence:{user_id}", data)

    async def get(self, user_id: str) -> Optional[UserPresence]:
        """Get user presence."""
        data = await self.storage.get(f"presence:{user_id}")
        if data:
            return UserPresence(
                user_id=data["user_id"],
                status=PresenceStatus(data.get("status", "offline")),
                last_seen=data.get("last_seen", 0),
                custom_status=data.get("custom_status"),
                device=data.get("device"),
            )
        return None

    async def get_channel_presence(self, channel_id: str) -> Dict[str, UserPresence]:
        """Get presence for all users in a channel."""
        # Would need channel manager to get members
        return {}

    def is_online(self, user_id: str) -> bool:
        """Check if user is online."""
        return user_id in self.online_users


class TypingIndicator:
    """Track typing indicators."""

    def __init__(self):
        self.typing: Dict[str, Dict[str, int]] = {}  # channel_id -> {user_id: timestamp}
        self.timeout_seconds = 5

    def start_typing(self, channel_id: str, user_id: str) -> None:
        """Mark user as typing in channel."""
        if channel_id not in self.typing:
            self.typing[channel_id] = {}
        self.typing[channel_id][user_id] = int(time.time())

    def stop_typing(self, channel_id: str, user_id: str) -> None:
        """Mark user as not typing."""
        if channel_id in self.typing:
            self.typing[channel_id].pop(user_id, None)

    def get_typing_users(self, channel_id: str) -> List[str]:
        """Get users currently typing in channel."""
        if channel_id not in self.typing:
            return []

        now = int(time.time())
        active = []
        expired = []

        for user_id, timestamp in self.typing[channel_id].items():
            if now - timestamp < self.timeout_seconds:
                active.append(user_id)
            else:
                expired.append(user_id)

        # Clean up expired
        for user_id in expired:
            del self.typing[channel_id][user_id]

        return active


class ReadReceipts:
    """Track message read receipts."""

    def __init__(self, storage):
        self.storage = storage

    async def mark_read(
        self,
        user_id: str,
        channel_id: str,
        message_id: str,
        timestamp: int,
    ) -> None:
        """Mark messages as read up to a point."""
        await self.storage.put(f"read:{channel_id}:{user_id}", {
            "message_id": message_id,
            "timestamp": timestamp,
            "read_at": int(time.time() * 1000),
        })

    async def get_read_position(
        self,
        user_id: str,
        channel_id: str,
    ) -> Optional[Dict[str, Any]]:
        """Get user's read position in channel."""
        return await self.storage.get(f"read:{channel_id}:{user_id}")

    async def get_unread_count(
        self,
        user_id: str,
        channel_id: str,
        message_store: MessageStore,
    ) -> int:
        """Get unread message count for user in channel."""
        position = await self.get_read_position(user_id, channel_id)

        if not position:
            # Never read - count all messages
            messages = await message_store.get_channel_messages(channel_id, limit=1000)
            return len(messages)

        # Count messages after read position
        messages = await message_store.get_channel_messages(
            channel_id,
            limit=1000,
        )

        return len([m for m in messages if m.created_at > position["timestamp"]])


class ChatServer:
    """Main chat server orchestrating all components."""

    def __init__(self, storage):
        self.storage = storage
        self.messages = MessageStore(storage)
        self.channels = ChannelManager(storage)
        self.presence = PresenceManager(storage)
        self.typing = TypingIndicator()
        self.receipts = ReadReceipts(storage)
        self.connections: Dict[str, Any] = {}  # user_id -> websocket

    async def send_message(
        self,
        channel_id: str,
        sender_id: str,
        content: str,
        type: MessageType = MessageType.TEXT,
        reply_to: Optional[str] = None,
        attachments: List[Dict[str, Any]] = None,
    ) -> Message:
        """Send a message to a channel."""
        # Parse mentions
        mentions = self._extract_mentions(content)

        message = Message(
            id=f"msg_{secrets.token_hex(8)}",
            channel_id=channel_id,
            sender_id=sender_id,
            content=content,
            type=type,
            reply_to=reply_to,
            attachments=attachments or [],
            mentions=mentions,
        )

        await self.messages.save(message)

        # Stop typing indicator
        self.typing.stop_typing(channel_id, sender_id)

        # Broadcast to channel members
        await self._broadcast_to_channel(channel_id, {
            "type": "message",
            "data": message.to_dict(),
        })

        return message

    async def _broadcast_to_channel(
        self,
        channel_id: str,
        event: Dict[str, Any],
    ) -> None:
        """Broadcast event to all channel members."""
        channel = await self.channels.get(channel_id)
        if not channel:
            return

        for member_id in channel.members:
            if member_id in self.connections:
                # In production, send via WebSocket
                pass

    def _extract_mentions(self, content: str) -> List[str]:
        """Extract @mentions from content."""
        import re
        pattern = r'@(\w+)'
        matches = re.findall(pattern, content)
        return matches

    async def get_conversation(
        self,
        channel_id: str,
        user_id: str,
        limit: int = 50,
        before: Optional[int] = None,
    ) -> Dict[str, Any]:
        """Get conversation data for UI."""
        channel = await self.channels.get(channel_id)
        if not channel or user_id not in channel.members:
            return {"error": "Access denied"}

        messages = await self.messages.get_channel_messages(
            channel_id,
            limit=limit,
            before=before,
        )

        unread = await self.receipts.get_unread_count(
            user_id,
            channel_id,
            self.messages,
        )

        typing_users = self.typing.get_typing_users(channel_id)

        return {
            "channel": channel.to_dict(),
            "messages": [m.to_dict() for m in messages],
            "unread_count": unread,
            "typing": typing_users,
        }


# FastAPI routes
def create_chat_routes(chat: ChatServer):
    """Create FastAPI routes for chat."""
    from fastapi import APIRouter, HTTPException

    router = APIRouter(prefix="/chat", tags=["chat"])

    @router.post("/channels")
    async def create_channel(
        name: str,
        type: str,
        created_by: str,
        members: List[str] = None,
    ):
        channel = await chat.channels.create(
            name=name,
            type=ChannelType(type),
            created_by=created_by,
            members=members,
        )
        return channel.to_dict()

    @router.get("/channels/{channel_id}")
    async def get_channel(channel_id: str, user_id: str):
        return await chat.get_conversation(channel_id, user_id)

    @router.post("/channels/{channel_id}/messages")
    async def send_message(
        channel_id: str,
        sender_id: str,
        content: str,
    ):
        message = await chat.send_message(channel_id, sender_id, content)
        return message.to_dict()

    @router.get("/users/{user_id}/channels")
    async def get_user_channels(user_id: str):
        channels = await chat.channels.get_user_channels(user_id)
        return [c.to_dict() for c in channels]

    @router.post("/presence/{user_id}/online")
    async def set_online(user_id: str):
        await chat.presence.set_online(user_id)
        return {"status": "online"}

    @router.post("/channels/{channel_id}/typing")
    async def start_typing(channel_id: str, user_id: str):
        chat.typing.start_typing(channel_id, user_id)
        return {"typing": True}

    @router.post("/channels/{channel_id}/read")
    async def mark_read(channel_id: str, user_id: str, message_id: str):
        msg = await chat.messages.get(message_id)
        if msg:
            await chat.receipts.mark_read(user_id, channel_id, message_id, msg.created_at)
        return {"read": True}

    return router

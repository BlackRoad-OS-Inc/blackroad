"""
RoadWebSocket - WebSocket for BlackRoad
WebSocket client and server with rooms, broadcasting, and reconnection.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import asyncio
import hashlib
import json
import logging
import threading
import uuid

logger = logging.getLogger(__name__)


class MessageType(str, Enum):
    """WebSocket message types."""
    TEXT = "text"
    BINARY = "binary"
    PING = "ping"
    PONG = "pong"
    CLOSE = "close"


class ConnectionState(str, Enum):
    """Connection states."""
    CONNECTING = "connecting"
    OPEN = "open"
    CLOSING = "closing"
    CLOSED = "closed"


@dataclass
class WebSocketMessage:
    """A WebSocket message."""
    id: str
    type: MessageType
    data: Any
    timestamp: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "type": self.type.value,
            "data": self.data,
            "timestamp": self.timestamp.isoformat()
        }


@dataclass
class WebSocketConnection:
    """A WebSocket connection."""
    id: str
    state: ConnectionState = ConnectionState.CONNECTING
    user_id: Optional[str] = None
    rooms: Set[str] = field(default_factory=set)
    metadata: Dict[str, Any] = field(default_factory=dict)
    connected_at: datetime = field(default_factory=datetime.now)
    last_ping: datetime = field(default_factory=datetime.now)
    _message_queue: asyncio.Queue = field(default_factory=asyncio.Queue)

    async def send(self, data: Any, message_type: MessageType = MessageType.TEXT) -> bool:
        """Queue a message to send."""
        if self.state != ConnectionState.OPEN:
            return False

        message = WebSocketMessage(
            id=str(uuid.uuid4())[:8],
            type=message_type,
            data=data
        )
        await self._message_queue.put(message)
        return True

    async def send_json(self, data: Dict[str, Any]) -> bool:
        """Send JSON data."""
        return await self.send(json.dumps(data), MessageType.TEXT)


class Room:
    """A WebSocket room for grouping connections."""

    def __init__(self, name: str):
        self.name = name
        self.connections: Set[str] = set()
        self.created_at = datetime.now()
        self.metadata: Dict[str, Any] = {}

    def add(self, connection_id: str) -> None:
        self.connections.add(connection_id)

    def remove(self, connection_id: str) -> None:
        self.connections.discard(connection_id)

    def size(self) -> int:
        return len(self.connections)


class EventEmitter:
    """Event emitter for WebSocket events."""

    def __init__(self):
        self._handlers: Dict[str, List[Callable]] = {}

    def on(self, event: str, handler: Callable) -> None:
        """Register event handler."""
        if event not in self._handlers:
            self._handlers[event] = []
        self._handlers[event].append(handler)

    def off(self, event: str, handler: Callable = None) -> None:
        """Remove event handler."""
        if event in self._handlers:
            if handler:
                self._handlers[event] = [h for h in self._handlers[event] if h != handler]
            else:
                del self._handlers[event]

    async def emit(self, event: str, *args, **kwargs) -> None:
        """Emit event to all handlers."""
        for handler in self._handlers.get(event, []):
            try:
                result = handler(*args, **kwargs)
                if asyncio.iscoroutine(result):
                    await result
            except Exception as e:
                logger.error(f"Event handler error: {e}")


class WebSocketServer(EventEmitter):
    """WebSocket server."""

    def __init__(self, ping_interval: int = 30):
        super().__init__()
        self.connections: Dict[str, WebSocketConnection] = {}
        self.rooms: Dict[str, Room] = {}
        self.ping_interval = ping_interval
        self._lock = threading.Lock()
        self._running = False

    def _generate_id(self) -> str:
        return str(uuid.uuid4())[:12]

    async def connect(self, user_id: str = None, metadata: Dict = None) -> WebSocketConnection:
        """Create new connection."""
        conn = WebSocketConnection(
            id=self._generate_id(),
            state=ConnectionState.OPEN,
            user_id=user_id,
            metadata=metadata or {}
        )

        with self._lock:
            self.connections[conn.id] = conn

        await self.emit("connect", conn)
        logger.info(f"Connection {conn.id} established")
        return conn

    async def disconnect(self, connection_id: str) -> bool:
        """Close a connection."""
        conn = self.connections.get(connection_id)
        if not conn:
            return False

        conn.state = ConnectionState.CLOSING

        # Leave all rooms
        for room_name in list(conn.rooms):
            await self.leave_room(connection_id, room_name)

        conn.state = ConnectionState.CLOSED

        with self._lock:
            del self.connections[connection_id]

        await self.emit("disconnect", conn)
        logger.info(f"Connection {connection_id} closed")
        return True

    async def send(self, connection_id: str, data: Any) -> bool:
        """Send message to a connection."""
        conn = self.connections.get(connection_id)
        if not conn:
            return False
        return await conn.send(data)

    async def broadcast(self, data: Any, exclude: Set[str] = None) -> int:
        """Broadcast to all connections."""
        exclude = exclude or set()
        count = 0

        for conn_id, conn in self.connections.items():
            if conn_id not in exclude and conn.state == ConnectionState.OPEN:
                if await conn.send(data):
                    count += 1

        return count

    async def send_to_user(self, user_id: str, data: Any) -> int:
        """Send to all connections of a user."""
        count = 0
        for conn in self.connections.values():
            if conn.user_id == user_id and conn.state == ConnectionState.OPEN:
                if await conn.send(data):
                    count += 1
        return count

    # Room management
    def create_room(self, name: str) -> Room:
        """Create a room."""
        if name not in self.rooms:
            self.rooms[name] = Room(name)
        return self.rooms[name]

    async def join_room(self, connection_id: str, room_name: str) -> bool:
        """Join a connection to a room."""
        conn = self.connections.get(connection_id)
        if not conn:
            return False

        room = self.create_room(room_name)
        room.add(connection_id)
        conn.rooms.add(room_name)

        await self.emit("room:join", conn, room)
        return True

    async def leave_room(self, connection_id: str, room_name: str) -> bool:
        """Leave a room."""
        conn = self.connections.get(connection_id)
        room = self.rooms.get(room_name)

        if not conn or not room:
            return False

        room.remove(connection_id)
        conn.rooms.discard(room_name)

        await self.emit("room:leave", conn, room)

        # Clean up empty rooms
        if room.size() == 0:
            del self.rooms[room_name]

        return True

    async def broadcast_to_room(self, room_name: str, data: Any, exclude: Set[str] = None) -> int:
        """Broadcast to all connections in a room."""
        room = self.rooms.get(room_name)
        if not room:
            return 0

        exclude = exclude or set()
        count = 0

        for conn_id in room.connections:
            if conn_id not in exclude:
                conn = self.connections.get(conn_id)
                if conn and conn.state == ConnectionState.OPEN:
                    if await conn.send(data):
                        count += 1

        return count

    def get_room_connections(self, room_name: str) -> List[WebSocketConnection]:
        """Get all connections in a room."""
        room = self.rooms.get(room_name)
        if not room:
            return []

        return [
            self.connections[conn_id]
            for conn_id in room.connections
            if conn_id in self.connections
        ]

    # Message handling
    async def on_message(self, connection_id: str, data: Any) -> None:
        """Handle incoming message."""
        conn = self.connections.get(connection_id)
        if not conn:
            return

        message = WebSocketMessage(
            id=str(uuid.uuid4())[:8],
            type=MessageType.TEXT,
            data=data
        )

        await self.emit("message", conn, message)

    # Stats
    def get_stats(self) -> Dict[str, Any]:
        return {
            "connections": len(self.connections),
            "rooms": len(self.rooms),
            "room_sizes": {name: room.size() for name, room in self.rooms.items()}
        }


class WebSocketClient(EventEmitter):
    """WebSocket client with reconnection."""

    def __init__(
        self,
        url: str,
        auto_reconnect: bool = True,
        reconnect_interval: float = 5.0,
        max_reconnect_attempts: int = 10
    ):
        super().__init__()
        self.url = url
        self.auto_reconnect = auto_reconnect
        self.reconnect_interval = reconnect_interval
        self.max_reconnect_attempts = max_reconnect_attempts
        self.state = ConnectionState.CLOSED
        self._reconnect_count = 0
        self._message_handlers: Dict[str, Callable] = {}
        self._connected = False

    async def connect(self) -> bool:
        """Connect to WebSocket server."""
        self.state = ConnectionState.CONNECTING

        try:
            # Simulate connection
            await asyncio.sleep(0.1)
            self.state = ConnectionState.OPEN
            self._connected = True
            self._reconnect_count = 0

            await self.emit("open")
            logger.info(f"Connected to {self.url}")
            return True

        except Exception as e:
            self.state = ConnectionState.CLOSED
            await self.emit("error", e)

            if self.auto_reconnect:
                await self._reconnect()

            return False

    async def _reconnect(self) -> None:
        """Attempt to reconnect."""
        while (self._reconnect_count < self.max_reconnect_attempts and
               self.state != ConnectionState.OPEN):
            self._reconnect_count += 1
            logger.info(f"Reconnecting ({self._reconnect_count}/{self.max_reconnect_attempts})...")

            await asyncio.sleep(self.reconnect_interval)
            await self.connect()

    async def disconnect(self) -> None:
        """Disconnect from server."""
        self.auto_reconnect = False
        self.state = ConnectionState.CLOSING

        # Simulate disconnection
        await asyncio.sleep(0.05)
        self.state = ConnectionState.CLOSED
        self._connected = False

        await self.emit("close")

    async def send(self, data: Any) -> bool:
        """Send message."""
        if self.state != ConnectionState.OPEN:
            return False

        message = WebSocketMessage(
            id=str(uuid.uuid4())[:8],
            type=MessageType.TEXT,
            data=data
        )

        # Simulate send
        await asyncio.sleep(0.01)
        await self.emit("sent", message)
        return True

    async def send_json(self, data: Dict[str, Any]) -> bool:
        """Send JSON data."""
        return await self.send(json.dumps(data))

    def on_message(self, message_type: str = None):
        """Decorator for message handlers."""
        def decorator(handler: Callable):
            key = message_type or "default"
            self._message_handlers[key] = handler
            return handler
        return decorator


class WebSocketManager:
    """High-level WebSocket management."""

    def __init__(self):
        self.server = WebSocketServer()
        self._clients: Dict[str, WebSocketClient] = {}

    def create_client(self, url: str, name: str = None, **kwargs) -> WebSocketClient:
        """Create a WebSocket client."""
        client = WebSocketClient(url, **kwargs)
        name = name or str(uuid.uuid4())[:8]
        self._clients[name] = client
        return client

    async def broadcast_all(self, data: Any) -> int:
        """Broadcast to all server connections."""
        return await self.server.broadcast(data)

    async def send_to_room(self, room: str, data: Any) -> int:
        """Send to room."""
        return await self.server.broadcast_to_room(room, data)

    def get_stats(self) -> Dict[str, Any]:
        return {
            "server": self.server.get_stats(),
            "clients": len(self._clients)
        }


# Example usage
async def example_usage():
    """Example WebSocket usage."""
    manager = WebSocketManager()
    server = manager.server

    # Register event handlers
    @server.on("connect")
    async def on_connect(conn):
        print(f"Client connected: {conn.id}")
        await server.join_room(conn.id, "lobby")

    @server.on("message")
    async def on_message(conn, message):
        print(f"Message from {conn.id}: {message.data}")
        # Echo back
        await conn.send(f"Echo: {message.data}")

    @server.on("disconnect")
    async def on_disconnect(conn):
        print(f"Client disconnected: {conn.id}")

    # Simulate connections
    conn1 = await server.connect(user_id="user-1")
    conn2 = await server.connect(user_id="user-2")

    # Join room
    await server.join_room(conn1.id, "chat")
    await server.join_room(conn2.id, "chat")

    # Handle messages
    await server.on_message(conn1.id, "Hello everyone!")

    # Broadcast to room
    await server.broadcast_to_room("chat", {"type": "announcement", "text": "Welcome!"})

    # Get stats
    print(f"Stats: {server.get_stats()}")

    # Client example
    client = manager.create_client("ws://localhost:8080", auto_reconnect=True)

    @client.on("open")
    async def on_open():
        print("Client connected!")
        await client.send_json({"type": "hello"})

    await client.connect()


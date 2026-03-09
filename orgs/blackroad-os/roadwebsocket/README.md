# RoadWebSocket

> WebSocket client and server for BlackRoad OS with rooms, broadcasting, and reconnection

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![BlackRoad OS](https://img.shields.io/badge/BlackRoad-OS-FF1D6C.svg)](https://github.com/BlackRoad-OS)

## Overview

RoadWebSocket provides WebSocket infrastructure with:

- **Server & Client** - Full bidirectional communication
- **Room System** - Group connections into rooms for broadcasting
- **Event Emitter** - Pub/sub style event handling
- **Auto Reconnection** - Client reconnection with backoff
- **User Targeting** - Send to specific users across connections
- **Connection Management** - Track state, metadata, ping/pong

## Installation

```bash
pip install roadwebsocket
```

## Quick Start

### Server

```python
import asyncio
from roadwebsocket import WebSocketServer, WebSocketManager

server = WebSocketServer()

@server.on("connect")
async def on_connect(conn):
    print(f"Client connected: {conn.id}")
    await server.join_room(conn.id, "lobby")

@server.on("message")
async def on_message(conn, message):
    print(f"Message from {conn.id}: {message.data}")
    # Echo back
    await conn.send(f"Echo: {message.data}")
    # Broadcast to room
    await server.broadcast_to_room("lobby", message.data, exclude={conn.id})

@server.on("disconnect")
async def on_disconnect(conn):
    print(f"Client disconnected: {conn.id}")

# Create connections
conn = await server.connect(user_id="user-123")
await server.on_message(conn.id, "Hello everyone!")
```

### Client

```python
from roadwebsocket import WebSocketClient

client = WebSocketClient(
    url="ws://localhost:8080",
    auto_reconnect=True,
    reconnect_interval=5.0,
    max_reconnect_attempts=10
)

@client.on("open")
async def on_open():
    print("Connected!")
    await client.send_json({"type": "hello"})

@client.on("message")
async def on_message(data):
    print(f"Received: {data}")

@client.on("close")
async def on_close():
    print("Disconnected")

await client.connect()
await client.send("Hello server!")
```

## Room System

```python
from roadwebsocket import WebSocketServer

server = WebSocketServer()

# Join rooms
await server.join_room(conn.id, "chat")
await server.join_room(conn.id, "notifications")

# Leave room
await server.leave_room(conn.id, "chat")

# Broadcast to room
await server.broadcast_to_room("chat", {"type": "message", "text": "Hello!"})

# Get room connections
connections = server.get_room_connections("chat")

# Room events
@server.on("room:join")
async def on_room_join(conn, room):
    print(f"{conn.id} joined {room.name}")

@server.on("room:leave")
async def on_room_leave(conn, room):
    print(f"{conn.id} left {room.name}")
```

## Broadcasting

```python
# Broadcast to all connections
await server.broadcast({"type": "announcement", "text": "Server maintenance in 5 min"})

# Broadcast excluding certain connections
await server.broadcast(data, exclude={conn1.id, conn2.id})

# Send to specific user (all their connections)
await server.send_to_user("user-123", {"type": "notification"})

# Send to specific connection
await server.send(conn.id, {"type": "private"})
```

## Connection Management

```python
# Connection with user ID and metadata
conn = await server.connect(
    user_id="user-123",
    metadata={"device": "mobile", "version": "1.0"}
)

# Check connection state
if conn.state == ConnectionState.OPEN:
    await conn.send("Hello")

# Connection properties
print(conn.id)           # Unique connection ID
print(conn.user_id)      # Associated user
print(conn.rooms)        # Set of room names
print(conn.connected_at) # Connection timestamp
print(conn.metadata)     # Custom metadata

# Disconnect
await server.disconnect(conn.id)
```

## Manager Pattern

```python
from roadwebsocket import WebSocketManager

manager = WebSocketManager()

# Server access
server = manager.server

# Create managed clients
client1 = manager.create_client("ws://server1:8080", name="server1")
client2 = manager.create_client("ws://server2:8080", name="server2")

# Broadcast via manager
await manager.broadcast_all({"type": "global"})
await manager.send_to_room("lobby", {"type": "room_message"})

# Stats
stats = manager.get_stats()
# {"server": {"connections": 10, "rooms": 3}, "clients": 2}
```

## API Reference

### Classes

| Class | Description |
|-------|-------------|
| `WebSocketServer` | WebSocket server with rooms |
| `WebSocketClient` | WebSocket client with reconnection |
| `WebSocketManager` | High-level management |
| `WebSocketConnection` | Connection instance |
| `WebSocketMessage` | Message dataclass |
| `Room` | Room for grouping connections |
| `EventEmitter` | Pub/sub event handling |

### Enums

- `MessageType`: TEXT, BINARY, PING, PONG, CLOSE
- `ConnectionState`: CONNECTING, OPEN, CLOSING, CLOSED

### Server Events

| Event | Parameters | Description |
|-------|------------|-------------|
| `connect` | (connection) | New connection |
| `disconnect` | (connection) | Connection closed |
| `message` | (connection, message) | Message received |
| `room:join` | (connection, room) | Joined room |
| `room:leave` | (connection, room) | Left room |

### Client Events

| Event | Parameters | Description |
|-------|------------|-------------|
| `open` | () | Connected |
| `close` | () | Disconnected |
| `error` | (exception) | Error occurred |
| `sent` | (message) | Message sent |

## License

Proprietary - BlackRoad OS, Inc. All rights reserved.

## Related

- [roadhttp](https://github.com/BlackRoad-OS/roadhttp) - HTTP client
- [roadrpc](https://github.com/BlackRoad-OS/roadrpc) - JSON-RPC
- [roadpubsub](https://github.com/BlackRoad-OS/roadpubsub) - Pub/Sub messaging

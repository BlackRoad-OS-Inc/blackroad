# blackroad-websocket

**BlackRoad WebSocket Manager** — production-grade WebSocket connection manager with rooms, subscriptions, presence tracking, message routing, and reconnection handling.

## Features

- 🔌 **Connection Lifecycle** — connect, disconnect, reconnect with backoff tracking
- 🏠 **Room Management** — public/private rooms with passwords, member limits, TTL
- 📨 **Message Routing** — broadcast to rooms, direct messages, system broadcasts
- 👥 **Presence Tracking** — online/offline status, typing indicators, custom metadata
- ⚡ **Ping/Pong Latency** — built-in round-trip latency measurement
- 🧹 **TTL Messages** — auto-expiry for ephemeral messages
- 💾 **SQLite persistence** — 5-table schema with indexes for performance
- 🎨 **ANSI CLI** — 6 subcommands with color output

## Install

```bash
pip install pytest pytest-cov
```

## Usage

```bash
# Register connection
python src/websocket.py connect my-client --ip 192.168.1.10 --user-id user-42

# Create rooms
python src/websocket.py rooms create --name general --topic "Main chat" --max 500
python src/websocket.py rooms list

# Subscribe
python src/websocket.py subscribe <conn_id> general

# Send message
python src/websocket.py send user-42 --room general --text "Hello!"
python src/websocket.py send user-42 --recipient <conn_id> --type direct --payload '{"text":"hi"}'

# Presence
python src/websocket.py presence --room general

# Message history
python src/websocket.py history general --limit 50
```

## Architecture

```
WebSocketManager
├── WebSocketDB           ← SQLite (5 tables + indexes)
│   ├── connections
│   ├── rooms
│   ├── subscriptions
│   ├── messages
│   └── presence
├── Connection            ← lifecycle + reconnect logic
├── Room                  ← password-protected rooms with TTL
├── Message               ← typed messages with TTL + parent threading
└── PresenceInfo          ← real-time status with typing indicators
```

## Testing

```bash
pytest tests/ -v --cov=src --cov-report=term-missing
```

## License

Proprietary — BlackRoad OS, Inc.

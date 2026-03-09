# blackroad-websocket-manager

WebSocket connection tracker for BlackRoad OS agents.

## Features
- Connection dataclass with agent, metadata, heartbeat tracking
- In-memory ConnectionPool backed by SQLite
- Add/remove connections with status tracking
- Broadcast messages to all or filtered connections
- Direct message to specific connection
- Heartbeat monitoring with automatic stale connection removal
- Message history with delivery tracking
- SQLite: `connections` + `messages` + `heartbeat_log` tables

## Usage
```bash
# Register a connection
python src/main_module.py connect octavia --ws-id ws-001 --metadata '{"ip":"10.0.0.1"}'

# List active connections
python src/main_module.py list

# Broadcast to all
python src/main_module.py broadcast '{"event":"deploy","version":"1.2.3"}'

# Broadcast to specific agent
python src/main_module.py broadcast "hello" --agent octavia

# Send direct message
python src/main_module.py send ws-001 '{"ping":true}'

# Update heartbeat
python src/main_module.py heartbeat ws-001 --latency 5

# Remove stale connections (30s timeout)
python src/main_module.py heartbeat-check --timeout 30

# View message history
python src/main_module.py history --ws-id ws-001 --limit 20

# Connection stats
python src/main_module.py stats
```

## API
```python
from src.main_module import ConnectionPool, add_connection, broadcast, get_db

db = get_db()
pool = ConnectionPool(db)
add_connection(pool, "ws-001", "octavia", {"region": "us-west"})
delivered = broadcast(pool, db, {"event": "ping"})
print(f"Delivered to {len(delivered)} connections")
```

## Testing
```bash
python -m pytest tests/ -v
```

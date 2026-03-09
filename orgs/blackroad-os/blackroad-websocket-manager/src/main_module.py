#!/usr/bin/env python3
"""
blackroad-websocket-manager: WebSocket connection tracker.
Tracks connections, broadcasts messages, and manages heartbeats.
"""

import argparse
import json
import sqlite3
import sys
import time
import uuid
from dataclasses import dataclass, field, asdict
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional

DB_PATH = Path.home() / ".blackroad" / "websocket-manager.db"


@dataclass
class Connection:
    ws_id: str
    agent: str
    metadata: Dict[str, Any] = field(default_factory=dict)
    connected_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    last_heartbeat: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    status: str = "active"
    message_count: int = 0
    db_id: Optional[int] = None


@dataclass
class Message:
    content: Any
    sender_id: Optional[str] = None
    recipient_id: Optional[str] = None
    msg_type: str = "data"
    msg_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    sent_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    db_id: Optional[int] = None


def get_db(db_path: Path = DB_PATH) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    _init_schema(conn)
    return conn


def _init_schema(conn: sqlite3.Connection) -> None:
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS connections (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            ws_id           TEXT    NOT NULL UNIQUE,
            agent           TEXT    NOT NULL,
            metadata        TEXT    NOT NULL DEFAULT '{}',
            connected_at    TEXT    NOT NULL DEFAULT (datetime('now')),
            last_heartbeat  TEXT    NOT NULL DEFAULT (datetime('now')),
            status          TEXT    NOT NULL DEFAULT 'active',
            message_count   INTEGER NOT NULL DEFAULT 0,
            disconnected_at TEXT
        );

        CREATE TABLE IF NOT EXISTS messages (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            msg_id      TEXT    NOT NULL UNIQUE,
            msg_type    TEXT    NOT NULL DEFAULT 'data',
            sender_id   TEXT,
            recipient_id TEXT,
            content     TEXT    NOT NULL,
            sent_at     TEXT    NOT NULL DEFAULT (datetime('now')),
            delivered   INTEGER NOT NULL DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS heartbeat_log (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            ws_id       TEXT    NOT NULL,
            ts          TEXT    NOT NULL DEFAULT (datetime('now')),
            latency_ms  INTEGER
        );

        CREATE INDEX IF NOT EXISTS idx_conn_agent  ON connections(agent);
        CREATE INDEX IF NOT EXISTS idx_conn_status ON connections(status);
        CREATE INDEX IF NOT EXISTS idx_msg_recip   ON messages(recipient_id);
        CREATE INDEX IF NOT EXISTS idx_msg_sent    ON messages(sent_at);
    """)
    conn.commit()


class ConnectionPool:
    """In-memory connection pool backed by SQLite."""

    def __init__(self, conn: sqlite3.Connection):
        self._conn = conn
        self._pool: Dict[str, Connection] = {}
        self._load_active()

    def _load_active(self) -> None:
        rows = self._conn.execute(
            "SELECT * FROM connections WHERE status='active'"
        ).fetchall()
        for row in rows:
            c = self._row_to_connection(row)
            self._pool[c.ws_id] = c

    @staticmethod
    def _row_to_connection(row) -> Connection:
        return Connection(
            ws_id=row["ws_id"],
            agent=row["agent"],
            metadata=json.loads(row["metadata"]),
            connected_at=row["connected_at"],
            last_heartbeat=row["last_heartbeat"],
            status=row["status"],
            message_count=row["message_count"],
            db_id=row["id"],
        )

    def add(self, connection: Connection) -> Connection:
        cur = self._conn.execute(
            "INSERT OR REPLACE INTO connections(ws_id, agent, metadata, connected_at, "
            "last_heartbeat, status, message_count) VALUES(?,?,?,?,?,?,?)",
            (connection.ws_id, connection.agent, json.dumps(connection.metadata),
             connection.connected_at, connection.last_heartbeat, connection.status,
             connection.message_count),
        )
        connection.db_id = cur.lastrowid
        self._conn.commit()
        self._pool[connection.ws_id] = connection
        return connection

    def remove(self, ws_id: str) -> bool:
        if ws_id not in self._pool:
            return False
        self._conn.execute(
            "UPDATE connections SET status='disconnected', disconnected_at=datetime('now') WHERE ws_id=?",
            (ws_id,),
        )
        self._conn.commit()
        del self._pool[ws_id]
        return True

    def get(self, ws_id: str) -> Optional[Connection]:
        return self._pool.get(ws_id)

    def get_all(self) -> List[Connection]:
        return list(self._pool.values())

    def count(self) -> int:
        return len(self._pool)

    def update_heartbeat(self, ws_id: str, latency_ms: Optional[int] = None) -> bool:
        if ws_id not in self._pool:
            return False
        ts = datetime.utcnow().isoformat()
        self._pool[ws_id].last_heartbeat = ts
        self._conn.execute(
            "UPDATE connections SET last_heartbeat=? WHERE ws_id=?", (ts, ws_id)
        )
        self._conn.execute(
            "INSERT INTO heartbeat_log(ws_id, latency_ms) VALUES(?,?)", (ws_id, latency_ms)
        )
        self._conn.commit()
        return True

    def increment_message_count(self, ws_id: str) -> None:
        if ws_id in self._pool:
            self._pool[ws_id].message_count += 1
            self._conn.execute(
                "UPDATE connections SET message_count=message_count+1 WHERE ws_id=?", (ws_id,)
            )
            self._conn.commit()


def add_connection(pool: ConnectionPool, ws_id: str, agent: str,
                   metadata: Optional[Dict] = None) -> Connection:
    conn_obj = Connection(ws_id=ws_id, agent=agent, metadata=metadata or {})
    return pool.add(conn_obj)


def remove_connection(pool: ConnectionPool, ws_id: str) -> bool:
    return pool.remove(ws_id)


def broadcast(
    pool: ConnectionPool,
    db_conn: sqlite3.Connection,
    message: Any,
    filter_fn: Optional[Callable[[Connection], bool]] = None,
    msg_type: str = "broadcast",
    sender_id: Optional[str] = None,
) -> List[str]:
    """
    Broadcast message to all (optionally filtered) connections.
    Returns list of ws_ids that received the message.
    Persists to messages table.
    """
    targets = pool.get_all()
    if filter_fn:
        targets = [c for c in targets if filter_fn(c)]

    content_str = json.dumps(message) if not isinstance(message, str) else message
    delivered_to = []

    for conn_obj in targets:
        msg = Message(
            content=content_str,
            sender_id=sender_id,
            recipient_id=conn_obj.ws_id,
            msg_type=msg_type,
        )
        db_conn.execute(
            "INSERT INTO messages(msg_id, msg_type, sender_id, recipient_id, content, delivered) "
            "VALUES(?,?,?,?,?,1)",
            (msg.msg_id, msg.msg_type, msg.sender_id, msg.recipient_id, msg.content),
        )
        pool.increment_message_count(conn_obj.ws_id)
        delivered_to.append(conn_obj.ws_id)

    db_conn.commit()
    return delivered_to


def get_active_connections(pool: ConnectionPool) -> List[Connection]:
    return [c for c in pool.get_all() if c.status == "active"]


def heartbeat_check(
    pool: ConnectionPool,
    db_conn: sqlite3.Connection,
    timeout: int = 30,
) -> Dict[str, List[str]]:
    """
    Check all connections for heartbeat timeout.
    Removes stale connections (no heartbeat within timeout seconds).
    Returns {'active': [...], 'timed_out': [...]}.
    """
    now = datetime.utcnow()
    cutoff = now - timedelta(seconds=timeout)
    active = []
    timed_out = []

    for conn_obj in list(pool.get_all()):
        try:
            last_hb = datetime.fromisoformat(conn_obj.last_heartbeat)
        except (ValueError, AttributeError):
            last_hb = now

        if last_hb < cutoff:
            pool.remove(conn_obj.ws_id)
            timed_out.append(conn_obj.ws_id)
        else:
            active.append(conn_obj.ws_id)

    return {"active": active, "timed_out": timed_out}


def send_message(
    pool: ConnectionPool,
    db_conn: sqlite3.Connection,
    ws_id: str,
    message: Any,
    msg_type: str = "data",
    sender_id: Optional[str] = None,
) -> Optional[Message]:
    """Send a direct message to a specific connection."""
    conn_obj = pool.get(ws_id)
    if not conn_obj:
        return None

    content_str = json.dumps(message) if not isinstance(message, str) else message
    msg = Message(content=content_str, sender_id=sender_id,
                  recipient_id=ws_id, msg_type=msg_type)
    db_conn.execute(
        "INSERT INTO messages(msg_id, msg_type, sender_id, recipient_id, content, delivered) "
        "VALUES(?,?,?,?,?,1)",
        (msg.msg_id, msg.msg_type, msg.sender_id, msg.recipient_id, msg.content),
    )
    pool.increment_message_count(ws_id)
    db_conn.commit()
    return msg


def get_message_history(
    db_conn: sqlite3.Connection,
    ws_id: Optional[str] = None,
    limit: int = 50,
) -> List[dict]:
    if ws_id:
        rows = db_conn.execute(
            "SELECT * FROM messages WHERE recipient_id=? OR sender_id=? "
            "ORDER BY sent_at DESC LIMIT ?",
            (ws_id, ws_id, limit),
        ).fetchall()
    else:
        rows = db_conn.execute(
            "SELECT * FROM messages ORDER BY sent_at DESC LIMIT ?", (limit,)
        ).fetchall()
    return [dict(r) for r in rows]


def connection_stats(pool: ConnectionPool, db_conn: sqlite3.Connection) -> dict:
    total_conn = db_conn.execute("SELECT COUNT(*) FROM connections").fetchone()[0]
    total_msg = db_conn.execute("SELECT COUNT(*) FROM messages").fetchone()[0]
    active = pool.count()
    agents = {}
    for c in pool.get_all():
        agents[c.agent] = agents.get(c.agent, 0) + 1
    return {
        "active_connections": active,
        "total_ever_connected": total_conn,
        "total_messages": total_msg,
        "agents": agents,
    }


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="ws-manager",
                                description="WebSocket Manager - blackroad-websocket-manager")
    p.add_argument("--db", default=str(DB_PATH))
    sub = p.add_subparsers(dest="command", required=True)

    # connect
    cc = sub.add_parser("connect", help="Register a new WebSocket connection")
    cc.add_argument("agent", help="Agent name")
    cc.add_argument("--ws-id", help="WebSocket ID (auto-generated if omitted)")
    cc.add_argument("--metadata", default="{}", help="JSON metadata")

    # disconnect
    dc = sub.add_parser("disconnect")
    dc.add_argument("ws_id")

    # list
    sub.add_parser("list", help="List active connections")

    # broadcast
    bc = sub.add_parser("broadcast", help="Broadcast a message")
    bc.add_argument("message", help="Message content")
    bc.add_argument("--agent", help="Filter by agent name")
    bc.add_argument("--type", default="broadcast", dest="msg_type")

    # send
    sm = sub.add_parser("send", help="Send direct message")
    sm.add_argument("ws_id")
    sm.add_argument("message")

    # heartbeat
    hb = sub.add_parser("heartbeat", help="Update heartbeat for a connection")
    hb.add_argument("ws_id")
    hb.add_argument("--latency", type=int)

    # heartbeat-check
    hc = sub.add_parser("heartbeat-check", help="Remove stale connections")
    hc.add_argument("--timeout", type=int, default=30)

    # history
    hi = sub.add_parser("history")
    hi.add_argument("--ws-id")
    hi.add_argument("--limit", type=int, default=20)

    # stats
    sub.add_parser("stats")

    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    db_conn = get_db(Path(args.db))
    pool = ConnectionPool(db_conn)

    if args.command == "connect":
        ws_id = args.ws_id or str(uuid.uuid4())
        metadata = json.loads(args.metadata)
        c = add_connection(pool, ws_id, args.agent, metadata)
        print(f"Connected: {c.ws_id} (agent={c.agent})")

    elif args.command == "disconnect":
        if remove_connection(pool, args.ws_id):
            print(f"Disconnected: {args.ws_id}")
        else:
            print("Connection not found", file=sys.stderr); sys.exit(1)

    elif args.command == "list":
        conns = get_active_connections(pool)
        if not conns:
            print("No active connections.")
        for c in conns:
            print(f"  {c.ws_id[:16]}... agent={c.agent:20s} msgs={c.message_count:5d} hb={c.last_heartbeat[:19]}")

    elif args.command == "broadcast":
        filt = (lambda c: c.agent == args.agent) if args.agent else None
        delivered = broadcast(pool, db_conn, args.message, filter_fn=filt, msg_type=args.msg_type)
        print(f"Broadcast to {len(delivered)} connection(s)")

    elif args.command == "send":
        msg = send_message(pool, db_conn, args.ws_id, args.message)
        if msg:
            print(f"Sent message {msg.msg_id} to {args.ws_id}")
        else:
            print("Connection not found", file=sys.stderr); sys.exit(1)

    elif args.command == "heartbeat":
        if pool.update_heartbeat(args.ws_id, args.latency):
            print(f"Heartbeat updated for {args.ws_id}")
        else:
            print("Connection not found", file=sys.stderr); sys.exit(1)

    elif args.command == "heartbeat-check":
        result = heartbeat_check(pool, db_conn, timeout=args.timeout)
        print(f"Active: {len(result['active'])}  Timed out: {len(result['timed_out'])}")
        for ws_id in result["timed_out"]:
            print(f"  Removed: {ws_id}")

    elif args.command == "history":
        rows = get_message_history(db_conn, ws_id=args.ws_id, limit=args.limit)
        for r in rows:
            print(f"  [{r['sent_at'][:19]}] {r['msg_type']:12s} {r.get('content','')[:60]}")

    elif args.command == "stats":
        stats = connection_stats(pool, db_conn)
        print(json.dumps(stats, indent=2))


if __name__ == "__main__":
    main()

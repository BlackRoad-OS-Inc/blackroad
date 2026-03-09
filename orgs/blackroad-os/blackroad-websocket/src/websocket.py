#!/usr/bin/env python3
"""BlackRoad WebSocket Manager — connection rooms, presence, message routing."""

import sqlite3
import json
import uuid
import hashlib
import argparse
import sys
import os
from dataclasses import dataclass, field, asdict
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any, Set
from enum import Enum
from collections import defaultdict

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

DB_PATH = os.environ.get("WS_DB", os.path.expanduser("~/.blackroad/websocket.db"))


class ConnState(str, Enum):
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    RECONNECTING = "reconnecting"
    IDLE = "idle"


class MsgType(str, Enum):
    BROADCAST = "broadcast"
    DIRECT = "direct"
    SYSTEM = "system"
    PRESENCE = "presence"
    ACK = "ack"
    PING = "ping"
    PONG = "pong"


@dataclass
class Connection:
    id: str
    client_id: str
    user_id: Optional[str]
    ip_address: str
    user_agent: str
    state: ConnState
    reconnect_count: int = 0
    max_reconnects: int = 5
    reconnect_interval: int = 3
    last_ping: Optional[str] = None
    last_pong: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    connected_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    disconnected_at: Optional[str] = None

    @property
    def latency_ms(self) -> Optional[int]:
        if self.last_ping and self.last_pong:
            try:
                ping_dt = datetime.fromisoformat(self.last_ping)
                pong_dt = datetime.fromisoformat(self.last_pong)
                return int((pong_dt - ping_dt).total_seconds() * 1000)
            except ValueError:
                return None
        return None

    def can_reconnect(self) -> bool:
        return self.reconnect_count < self.max_reconnects


@dataclass
class Room:
    id: str
    name: str
    topic: str
    max_members: int
    private: bool
    password_hash: Optional[str]
    owner_id: Optional[str]
    ttl_minutes: int = 0
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())

    def check_password(self, password: str) -> bool:
        if not self.password_hash:
            return True
        return hashlib.sha256(password.encode()).hexdigest() == self.password_hash


@dataclass
class Subscription:
    id: str
    connection_id: str
    room_id: str
    role: str = "member"
    muted: bool = False
    joined_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    last_read: Optional[str] = None


@dataclass
class Message:
    id: str
    room_id: Optional[str]
    sender_id: str
    recipient_id: Optional[str]
    msg_type: MsgType
    payload: Dict[str, Any]
    delivered: bool = False
    read: bool = False
    ttl_seconds: int = 0
    parent_id: Optional[str] = None
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())

    def is_expired(self) -> bool:
        if self.ttl_seconds <= 0:
            return False
        created = datetime.fromisoformat(self.created_at)
        return datetime.utcnow() > created + timedelta(seconds=self.ttl_seconds)


@dataclass
class PresenceInfo:
    connection_id: str
    user_id: str
    status: str
    display_name: str
    room_ids: List[str]
    custom_data: Dict[str, Any] = field(default_factory=dict)
    last_seen: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    typing_in: Optional[str] = None


class WebSocketDB:
    def __init__(self, db_path: str = DB_PATH):
        os.makedirs(os.path.dirname(db_path) or ".", exist_ok=True)
        self.conn = sqlite3.connect(db_path)
        self.conn.row_factory = sqlite3.Row
        self.conn.execute("PRAGMA foreign_keys = ON")
        self._init_schema()

    def _init_schema(self):
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS connections (
                id TEXT PRIMARY KEY,
                client_id TEXT NOT NULL,
                user_id TEXT,
                ip_address TEXT NOT NULL,
                user_agent TEXT DEFAULT '',
                state TEXT NOT NULL DEFAULT 'connected',
                reconnect_count INTEGER DEFAULT 0,
                max_reconnects INTEGER DEFAULT 5,
                reconnect_interval INTEGER DEFAULT 3,
                last_ping TEXT,
                last_pong TEXT,
                metadata TEXT DEFAULT '{}',
                connected_at TEXT NOT NULL,
                disconnected_at TEXT
            );
            CREATE TABLE IF NOT EXISTS rooms (
                id TEXT PRIMARY KEY,
                name TEXT UNIQUE NOT NULL,
                topic TEXT DEFAULT '',
                max_members INTEGER DEFAULT 100,
                private INTEGER DEFAULT 0,
                password_hash TEXT,
                owner_id TEXT,
                ttl_minutes INTEGER DEFAULT 0,
                metadata TEXT DEFAULT '{}',
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS subscriptions (
                id TEXT PRIMARY KEY,
                connection_id TEXT NOT NULL REFERENCES connections(id),
                room_id TEXT NOT NULL REFERENCES rooms(id),
                role TEXT DEFAULT 'member',
                muted INTEGER DEFAULT 0,
                joined_at TEXT NOT NULL,
                last_read TEXT,
                UNIQUE(connection_id, room_id)
            );
            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                room_id TEXT REFERENCES rooms(id),
                sender_id TEXT NOT NULL,
                recipient_id TEXT,
                msg_type TEXT NOT NULL,
                payload TEXT DEFAULT '{}',
                delivered INTEGER DEFAULT 0,
                read_flag INTEGER DEFAULT 0,
                ttl_seconds INTEGER DEFAULT 0,
                parent_id TEXT,
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS presence (
                connection_id TEXT PRIMARY KEY REFERENCES connections(id),
                user_id TEXT NOT NULL,
                status TEXT DEFAULT 'online',
                display_name TEXT DEFAULT '',
                room_ids TEXT DEFAULT '[]',
                custom_data TEXT DEFAULT '{}',
                last_seen TEXT NOT NULL,
                typing_in TEXT
            );
            CREATE INDEX IF NOT EXISTS idx_msgs_room ON messages(room_id, created_at DESC);
            CREATE INDEX IF NOT EXISTS idx_msgs_recipient ON messages(recipient_id, delivered);
            CREATE INDEX IF NOT EXISTS idx_subs_room ON subscriptions(room_id);
            CREATE INDEX IF NOT EXISTS idx_conn_state ON connections(state, user_id);
        """)
        self.conn.commit()


class WebSocketManager:
    def __init__(self, db: WebSocketDB):
        self.db = db

    # ── Connection management ──────────────────────────────────────────────

    def connect(self, client_id: str, ip: str, user_id: str = None,
                user_agent: str = "", metadata: Dict = None) -> Connection:
        conn = Connection(
            id=str(uuid.uuid4()), client_id=client_id,
            user_id=user_id, ip_address=ip,
            user_agent=user_agent, state=ConnState.CONNECTED,
            metadata=metadata or {}
        )
        self.db.conn.execute(
            "INSERT INTO connections VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (conn.id, conn.client_id, conn.user_id, conn.ip_address,
             conn.user_agent, conn.state.value, conn.reconnect_count,
             conn.max_reconnects, conn.reconnect_interval,
             conn.last_ping, conn.last_pong,
             json.dumps(conn.metadata), conn.connected_at, conn.disconnected_at)
        )
        self.db.conn.commit()
        return conn

    def disconnect(self, conn_id: str, clean: bool = True) -> bool:
        now = datetime.utcnow().isoformat()
        state = ConnState.DISCONNECTED.value if clean else ConnState.RECONNECTING.value
        self.db.conn.execute(
            "UPDATE connections SET state=?, disconnected_at=? WHERE id=?",
            (state, now, conn_id)
        )
        self.db.conn.execute(
            "DELETE FROM subscriptions WHERE connection_id=?", (conn_id,)
        )
        self.db.conn.execute(
            "UPDATE presence SET status='offline', last_seen=? WHERE connection_id=?",
            (now, conn_id)
        )
        self.db.conn.commit()
        return True

    def reconnect(self, conn_id: str) -> Optional[Dict]:
        row = self.db.conn.execute(
            "SELECT * FROM connections WHERE id=?", (conn_id,)
        ).fetchone()
        if not row:
            return None
        if row["reconnect_count"] >= row["max_reconnects"]:
            return {"error": "max_reconnects_exceeded", "count": row["reconnect_count"]}
        new_count = row["reconnect_count"] + 1
        self.db.conn.execute(
            "UPDATE connections SET state=?, reconnect_count=? WHERE id=?",
            (ConnState.CONNECTED.value, new_count, conn_id)
        )
        self.db.conn.commit()
        return {"status": "reconnected", "attempt": new_count,
                "max": row["max_reconnects"], "conn_id": conn_id}

    def ping(self, conn_id: str) -> Dict:
        now = datetime.utcnow().isoformat()
        self.db.conn.execute(
            "UPDATE connections SET last_ping=? WHERE id=?", (now, conn_id)
        )
        self.db.conn.commit()
        return {"type": "ping", "conn_id": conn_id, "timestamp": now}

    def pong(self, conn_id: str) -> Dict:
        now = datetime.utcnow().isoformat()
        self.db.conn.execute(
            "UPDATE connections SET last_pong=? WHERE id=?", (now, conn_id)
        )
        self.db.conn.commit()
        row = self.db.conn.execute(
            "SELECT last_ping, last_pong FROM connections WHERE id=?", (conn_id,)
        ).fetchone()
        latency = None
        if row and row["last_ping"] and row["last_pong"]:
            try:
                ping_dt = datetime.fromisoformat(row["last_ping"])
                pong_dt = datetime.fromisoformat(row["last_pong"])
                latency = int((pong_dt - ping_dt).total_seconds() * 1000)
            except ValueError:
                pass
        return {"type": "pong", "conn_id": conn_id, "latency_ms": latency}

    # ── Room management ────────────────────────────────────────────────────

    def create_room(self, name: str, topic: str = "", max_members: int = 100,
                    private: bool = False, password: str = None,
                    owner_id: str = None, ttl_minutes: int = 0) -> Room:
        pw_hash = hashlib.sha256(password.encode()).hexdigest() if password else None
        room = Room(id=str(uuid.uuid4()), name=name, topic=topic,
                    max_members=max_members, private=private,
                    password_hash=pw_hash, owner_id=owner_id, ttl_minutes=ttl_minutes)
        self.db.conn.execute(
            "INSERT INTO rooms VALUES (?,?,?,?,?,?,?,?,?,?)",
            (room.id, room.name, room.topic, room.max_members,
             int(room.private), room.password_hash, room.owner_id,
             room.ttl_minutes, json.dumps(room.metadata), room.created_at)
        )
        self.db.conn.commit()
        return room

    def join_room(self, conn_id: str, room_id: str,
                  password: str = None, role: str = "member") -> Dict:
        room_row = self.db.conn.execute(
            "SELECT * FROM rooms WHERE id=?", (room_id,)
        ).fetchone()
        if not room_row:
            return {"error": "room_not_found"}
        if room_row["password_hash"] and password:
            if hashlib.sha256(password.encode()).hexdigest() != room_row["password_hash"]:
                return {"error": "invalid_password"}
        member_count = self.db.conn.execute(
            "SELECT COUNT(*) as c FROM subscriptions WHERE room_id=?", (room_id,)
        ).fetchone()["c"]
        if member_count >= room_row["max_members"]:
            return {"error": "room_full", "max": room_row["max_members"]}
        sub_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()
        try:
            self.db.conn.execute(
                "INSERT INTO subscriptions VALUES (?,?,?,?,?,?,?)",
                (sub_id, conn_id, room_id, role, 0, now, now)
            )
            self.db.conn.commit()
        except sqlite3.IntegrityError:
            return {"error": "already_subscribed"}
        return {"status": "joined", "subscription_id": sub_id, "room_id": room_id, "role": role}

    def leave_room(self, conn_id: str, room_id: str) -> bool:
        self.db.conn.execute(
            "DELETE FROM subscriptions WHERE connection_id=? AND room_id=?",
            (conn_id, room_id)
        )
        self.db.conn.commit()
        return True

    # ── Messaging ─────────────────────────────────────────────────────────

    def send_message(self, sender_id: str, payload: Dict,
                     room_id: str = None, recipient_id: str = None,
                     msg_type: str = "broadcast", ttl: int = 0,
                     parent_id: str = None) -> Message:
        msg = Message(
            id=str(uuid.uuid4()), room_id=room_id,
            sender_id=sender_id, recipient_id=recipient_id,
            msg_type=MsgType(msg_type), payload=payload,
            ttl_seconds=ttl, parent_id=parent_id
        )
        self.db.conn.execute(
            "INSERT INTO messages VALUES (?,?,?,?,?,?,?,?,?,?,?)",
            (msg.id, msg.room_id, msg.sender_id, msg.recipient_id,
             msg.msg_type.value, json.dumps(msg.payload),
             int(msg.delivered), int(msg.read),
             msg.ttl_seconds, msg.parent_id, msg.created_at)
        )
        self.db.conn.commit()
        return msg

    def route_message(self, msg_id: str) -> Dict:
        row = self.db.conn.execute(
            "SELECT * FROM messages WHERE id=?", (msg_id,)
        ).fetchone()
        if not row:
            return {"error": "message_not_found"}
        payload = json.loads(row["payload"])
        if row["msg_type"] == MsgType.BROADCAST.value and row["room_id"]:
            subs = self.db.conn.execute(
                "SELECT connection_id FROM subscriptions WHERE room_id=? AND muted=0",
                (row["room_id"],)
            ).fetchall()
            recipients = [s["connection_id"] for s in subs]
            self.db.conn.execute(
                "UPDATE messages SET delivered=1 WHERE id=?", (msg_id,)
            )
            self.db.conn.commit()
            return {"routed_to": len(recipients), "type": "room_broadcast",
                    "room_id": row["room_id"], "recipients": recipients[:20]}
        elif row["msg_type"] == MsgType.DIRECT.value and row["recipient_id"]:
            self.db.conn.execute(
                "UPDATE messages SET delivered=1 WHERE id=?", (msg_id,)
            )
            self.db.conn.commit()
            return {"routed_to": 1, "type": "direct",
                    "recipient": row["recipient_id"], "delivered": True}
        elif row["msg_type"] == MsgType.SYSTEM.value:
            count = self.db.conn.execute(
                "SELECT COUNT(*) as c FROM connections WHERE state='connected'"
            ).fetchone()["c"]
            self.db.conn.execute(
                "UPDATE messages SET delivered=1 WHERE id=?", (msg_id,)
            )
            self.db.conn.commit()
            return {"routed_to": count, "type": "system_broadcast"}
        return {"error": "unroutable", "msg_type": row["msg_type"]}

    def get_room_messages(self, room_id: str, limit: int = 50,
                           before: str = None) -> List[Dict]:
        if before:
            rows = self.db.conn.execute(
                "SELECT * FROM messages WHERE room_id=? AND created_at < ? "
                "ORDER BY created_at DESC LIMIT ?", (room_id, before, limit)
            ).fetchall()
        else:
            rows = self.db.conn.execute(
                "SELECT * FROM messages WHERE room_id=? ORDER BY created_at DESC LIMIT ?",
                (room_id, limit)
            ).fetchall()
        return [dict(r) for r in reversed(rows)]

    # ── Presence tracking ─────────────────────────────────────────────────

    def update_presence(self, conn_id: str, user_id: str, status: str,
                        display_name: str = "", custom_data: Dict = None,
                        typing_in: str = None) -> PresenceInfo:
        room_ids = [r["room_id"] for r in self.db.conn.execute(
            "SELECT room_id FROM subscriptions WHERE connection_id=?", (conn_id,)
        ).fetchall()]
        now = datetime.utcnow().isoformat()
        presence = PresenceInfo(
            connection_id=conn_id, user_id=user_id, status=status,
            display_name=display_name, room_ids=room_ids,
            custom_data=custom_data or {}, last_seen=now, typing_in=typing_in
        )
        self.db.conn.execute(
            "INSERT OR REPLACE INTO presence VALUES (?,?,?,?,?,?,?,?)",
            (presence.connection_id, presence.user_id, presence.status,
             presence.display_name, json.dumps(presence.room_ids),
             json.dumps(presence.custom_data), presence.last_seen, presence.typing_in)
        )
        self.db.conn.commit()
        return presence

    def get_room_presence(self, room_id: str) -> List[Dict]:
        rows = self.db.conn.execute(
            "SELECT p.* FROM presence p "
            "JOIN subscriptions s ON s.connection_id = p.connection_id "
            "WHERE s.room_id=? AND p.status != 'offline' "
            "ORDER BY p.last_seen DESC",
            (room_id,)
        ).fetchall()
        return [dict(r) for r in rows]

    def get_connection_stats(self) -> Dict[str, Any]:
        total = self.db.conn.execute("SELECT COUNT(*) as c FROM connections").fetchone()["c"]
        active = self.db.conn.execute(
            "SELECT COUNT(*) as c FROM connections WHERE state='connected'"
        ).fetchone()["c"]
        rooms = self.db.conn.execute("SELECT COUNT(*) as c FROM rooms").fetchone()["c"]
        messages = self.db.conn.execute("SELECT COUNT(*) as c FROM messages").fetchone()["c"]
        undelivered = self.db.conn.execute(
            "SELECT COUNT(*) as c FROM messages WHERE delivered=0"
        ).fetchone()["c"]
        top_rooms = self.db.conn.execute(
            "SELECT r.name, COUNT(s.id) as members "
            "FROM rooms r LEFT JOIN subscriptions s ON s.room_id=r.id "
            "GROUP BY r.id ORDER BY members DESC LIMIT 5"
        ).fetchall()
        return {
            "total_connections": total, "active_connections": active,
            "rooms": rooms, "messages": messages, "undelivered": undelivered,
            "top_rooms": [dict(r) for r in top_rooms]
        }

    def list_rooms(self) -> List[Dict]:
        rows = self.db.conn.execute(
            "SELECT r.*, COUNT(s.id) as member_count "
            "FROM rooms r LEFT JOIN subscriptions s ON s.room_id=r.id "
            "GROUP BY r.id ORDER BY member_count DESC"
        ).fetchall()
        return [dict(r) for r in rows]

    def purge_expired_messages(self) -> int:
        now = datetime.utcnow().isoformat()
        rows = self.db.conn.execute(
            "SELECT id, created_at, ttl_seconds FROM messages WHERE ttl_seconds > 0"
        ).fetchall()
        expired = []
        for row in rows:
            try:
                created = datetime.fromisoformat(row["created_at"])
                if datetime.utcnow() > created + timedelta(seconds=row["ttl_seconds"]):
                    expired.append(row["id"])
            except ValueError:
                pass
        if expired:
            placeholders = ",".join("?" * len(expired))
            self.db.conn.execute(
                f"DELETE FROM messages WHERE id IN ({placeholders})", expired
            )
            self.db.conn.commit()
        return len(expired)


# ── CLI ───────────────────────────────────────────────────────────────────────

def _banner():
    print(f"\n{BOLD}{CYAN}╔══════════════════════════════════════════╗{RESET}")
    print(f"{BOLD}{CYAN}║   BlackRoad WebSocket Manager  v1.0.0    ║{RESET}")
    print(f"{BOLD}{CYAN}╚══════════════════════════════════════════╝{RESET}\n")


def _get_manager() -> WebSocketManager:
    return WebSocketManager(WebSocketDB())


def cmd_connect(args):
    mgr = _get_manager()
    meta = json.loads(args.metadata) if args.metadata else {}
    conn = mgr.connect(args.client_id, args.ip, args.user_id, args.agent, meta)
    print(f"{GREEN}✓ Connection established{RESET}")
    print(f"  {DIM}Conn ID:{RESET}   {CYAN}{conn.id[:12]}…{RESET}")
    print(f"  {DIM}Client:{RESET}    {conn.client_id}")
    print(f"  {DIM}User:{RESET}      {conn.user_id or 'anonymous'}")
    print(f"  {DIM}IP:{RESET}        {conn.ip_address}")
    print(f"  {DIM}State:{RESET}     {GREEN}{conn.state.value}{RESET}")


def cmd_rooms(args):
    mgr = _get_manager()
    if args.action == "create":
        room = mgr.create_room(args.name, args.topic or "",
                               max_members=args.max or 100,
                               private=args.private,
                               password=args.password,
                               ttl_minutes=args.ttl or 0)
        print(f"{GREEN}✓ Room '{room.name}' created{RESET}")
        print(f"  {DIM}Room ID:{RESET}  {CYAN}{room.id[:12]}…{RESET}")
        print(f"  {DIM}Private:{RESET}  {room.private}  "
              f"{DIM}Max:{RESET} {room.max_members}  "
              f"{DIM}TTL:{RESET} {room.ttl_minutes}m")
    elif args.action == "list":
        rooms = mgr.list_rooms()
        print(f"\n{BOLD}Rooms ({len(rooms)}){RESET}")
        print(f"  {'Name':<20} {'Members':>8} {'Max':>6}  {'Private':<8}  Topic")
        print(f"  {'─'*20} {'─'*8} {'─'*6}  {'─'*8}  {'─'*20}")
        for r in rooms:
            priv = f"{YELLOW}🔒{RESET}" if r["private"] else f"{GREEN}🔓{RESET}"
            print(f"  {CYAN}{r['name']:<20}{RESET} {r['member_count']:>8} "
                  f"{r['max_members']:>6}  {priv:<8}  {r['topic'][:20]}")


def cmd_subscribe(args):
    mgr = _get_manager()
    room_row = mgr.db.conn.execute(
        "SELECT id FROM rooms WHERE name=?", (args.room,)
    ).fetchone()
    if not room_row:
        print(f"{RED}✗ Room '{args.room}' not found{RESET}")
        sys.exit(1)
    result = mgr.join_room(args.conn_id, room_row["id"], args.password, args.role)
    if "error" in result:
        print(f"{RED}✗ Join failed: {result['error']}{RESET}")
        sys.exit(1)
    print(f"{GREEN}✓ Joined room '{args.room}'{RESET}")
    print(f"  Role: {result['role']}  Sub ID: {result['subscription_id'][:12]}…")


def cmd_send(args):
    mgr = _get_manager()
    payload = json.loads(args.payload) if args.payload else {"text": args.text or ""}
    room_id = None
    if args.room:
        row = mgr.db.conn.execute("SELECT id FROM rooms WHERE name=?", (args.room,)).fetchone()
        room_id = row["id"] if row else None
    msg = mgr.send_message(args.sender, payload, room_id=room_id,
                           recipient_id=args.recipient, msg_type=args.type, ttl=args.ttl or 0)
    route_result = mgr.route_message(msg.id)
    print(f"{GREEN}✓ Message sent & routed{RESET}")
    print(f"  {DIM}Msg ID:{RESET}   {CYAN}{msg.id[:12]}…{RESET}")
    print(f"  {DIM}Type:{RESET}     {msg.msg_type.value}")
    print(f"  {DIM}Routed to:{RESET} {route_result.get('routed_to', 0)} recipient(s)")


def cmd_presence(args):
    mgr = _get_manager()
    if args.room:
        row = mgr.db.conn.execute("SELECT id FROM rooms WHERE name=?", (args.room,)).fetchone()
        if not row:
            print(f"{RED}✗ Room not found{RESET}")
            sys.exit(1)
        members = mgr.get_room_presence(row["id"])
        print(f"\n{BOLD}Presence — #{args.room} ({len(members)} online){RESET}")
        print(f"  {'Display Name':<20} {'Status':<12} {'Last Seen':<20}  Typing")
        print(f"  {'─'*20} {'─'*12} {'─'*20}  {'─'*10}")
        for m in members:
            status_col = GREEN if m["status"] == "online" else YELLOW
            typing = f"{CYAN}✍ {m['typing_in']}{RESET}" if m.get("typing_in") else ""
            print(f"  {m['display_name']:<20} {status_col}{m['status']:<12}{RESET} "
                  f"{m['last_seen'][:19]:<20}  {typing}")
    else:
        stats = mgr.get_connection_stats()
        print(f"\n{BOLD}WebSocket Stats{RESET}")
        print(f"  {DIM}Active connections:{RESET}  {GREEN}{stats['active_connections']}{RESET}")
        print(f"  {DIM}Total connections:{RESET}   {stats['total_connections']}")
        print(f"  {DIM}Rooms:{RESET}               {stats['rooms']}")
        print(f"  {DIM}Messages:{RESET}            {stats['messages']}")
        print(f"  {DIM}Undelivered:{RESET}         {YELLOW}{stats['undelivered']}{RESET}")
        if stats["top_rooms"]:
            print(f"\n  {BOLD}Top Rooms:{RESET}")
            for r in stats["top_rooms"]:
                print(f"    {CYAN}#{r['name']:<20}{RESET} {r['members']} members")


def cmd_history(args):
    mgr = _get_manager()
    room_row = mgr.db.conn.execute(
        "SELECT id FROM rooms WHERE name=?", (args.room,)
    ).fetchone()
    if not room_row:
        print(f"{RED}✗ Room not found{RESET}")
        sys.exit(1)
    msgs = mgr.get_room_messages(room_row["id"], args.limit)
    print(f"\n{BOLD}Messages — #{args.room} (last {len(msgs)}){RESET}")
    print(f"  {'Sender':<15} {'Type':<12} {'Time':<20}  Payload preview")
    print(f"  {'─'*15} {'─'*12} {'─'*20}  {'─'*30}")
    for m in msgs:
        payload = json.loads(m["payload"]) if m["payload"] else {}
        preview = str(payload)[:30]
        delivered_sym = f"{GREEN}✓{RESET}" if m["delivered"] else f"{YELLOW}○{RESET}"
        print(f"  {CYAN}{m['sender_id']:<15}{RESET} {m['msg_type']:<12} "
              f"{m['created_at'][:19]:<20}  {delivered_sym} {preview}")


def main():
    _banner()
    parser = argparse.ArgumentParser(prog="ws-manager",
                                     description="BlackRoad WebSocket Manager")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("connect", help="Register a new connection")
    p.add_argument("client_id")
    p.add_argument("--ip", default="127.0.0.1")
    p.add_argument("--user-id", default=None)
    p.add_argument("--agent", default="")
    p.add_argument("--metadata", default="{}")

    p = sub.add_parser("rooms", help="Room management")
    p.add_argument("action", choices=["create", "list"])
    p.add_argument("--name", default="general")
    p.add_argument("--topic", default="")
    p.add_argument("--max", type=int, default=100)
    p.add_argument("--private", action="store_true")
    p.add_argument("--password", default=None)
    p.add_argument("--ttl", type=int, default=0)

    p = sub.add_parser("subscribe", help="Join a room")
    p.add_argument("conn_id")
    p.add_argument("room")
    p.add_argument("--password", default=None)
    p.add_argument("--role", default="member")

    p = sub.add_parser("send", help="Send a message")
    p.add_argument("sender")
    p.add_argument("--room", default=None)
    p.add_argument("--recipient", default=None)
    p.add_argument("--text", default="")
    p.add_argument("--payload", default=None)
    p.add_argument("--type", default="broadcast",
                   choices=["broadcast", "direct", "system", "presence"])
    p.add_argument("--ttl", type=int, default=0)

    p = sub.add_parser("presence", help="View presence info")
    p.add_argument("--room", default=None)

    p = sub.add_parser("history", help="View room message history")
    p.add_argument("room")
    p.add_argument("--limit", type=int, default=20)

    args = parser.parse_args()
    cmds = {
        "connect": cmd_connect, "rooms": cmd_rooms,
        "subscribe": cmd_subscribe, "send": cmd_send,
        "presence": cmd_presence, "history": cmd_history,
    }
    cmds[args.command](args)


if __name__ == "__main__":
    main()

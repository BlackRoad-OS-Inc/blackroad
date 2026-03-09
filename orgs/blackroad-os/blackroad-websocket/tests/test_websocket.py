"""Tests for BlackRoad WebSocket Manager."""
import os
import sys
import json
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from websocket import WebSocketDB, WebSocketManager, ConnState, MsgType, Message
from datetime import datetime, timedelta


@pytest.fixture
def mgr(tmp_path):
    db = WebSocketDB(db_path=str(tmp_path / "test_ws.db"))
    return WebSocketManager(db)


def test_connect(mgr):
    conn = mgr.connect("client-1", "192.168.1.1", user_id="user-42", user_agent="pytest/1.0")
    assert conn.client_id == "client-1"
    assert conn.state == ConnState.CONNECTED
    assert conn.user_id == "user-42"
    assert conn.id is not None


def test_disconnect(mgr):
    conn = mgr.connect("client-2", "10.0.0.1")
    mgr.create_room("lobby", topic="General")
    room_row = mgr.db.conn.execute("SELECT id FROM rooms WHERE name='lobby'").fetchone()
    mgr.join_room(conn.id, room_row["id"])
    result = mgr.disconnect(conn.id)
    assert result is True
    row = mgr.db.conn.execute("SELECT state FROM connections WHERE id=?", (conn.id,)).fetchone()
    assert row["state"] == ConnState.DISCONNECTED.value


def test_reconnect_logic(mgr):
    conn = mgr.connect("client-3", "10.0.0.2")
    mgr.disconnect(conn.id, clean=False)
    result = mgr.reconnect(conn.id)
    assert result["status"] == "reconnected"
    assert result["attempt"] == 1


def test_create_room(mgr):
    room = mgr.create_room("dev", topic="Dev chat", max_members=50, private=True)
    assert room.name == "dev"
    assert room.private is True
    assert room.max_members == 50


def test_join_room_and_presence(mgr):
    conn = mgr.connect("client-4", "10.0.0.3", user_id="user-1")
    room = mgr.create_room("general")
    result = mgr.join_room(conn.id, room.id)
    assert result["status"] == "joined"
    assert result["role"] == "member"
    mgr.update_presence(conn.id, "user-1", "online", "Alice")
    presence = mgr.get_room_presence(room.id)
    assert len(presence) == 1
    assert presence[0]["display_name"] == "Alice"


def test_join_full_room(mgr):
    room = mgr.create_room("tiny", max_members=1)
    c1 = mgr.connect("c1", "1.1.1.1")
    c2 = mgr.connect("c2", "1.1.1.2")
    mgr.join_room(c1.id, room.id)
    result = mgr.join_room(c2.id, room.id)
    assert result.get("error") == "room_full"


def test_send_and_route_broadcast(mgr):
    room = mgr.create_room("chat")
    c1 = mgr.connect("sender", "1.2.3.4")
    c2 = mgr.connect("receiver", "1.2.3.5")
    mgr.join_room(c1.id, room.id)
    mgr.join_room(c2.id, room.id)
    msg = mgr.send_message("sender", {"text": "hello"}, room_id=room.id)
    result = mgr.route_message(msg.id)
    assert result["type"] == "room_broadcast"
    assert result["routed_to"] == 2


def test_direct_message(mgr):
    c1 = mgr.connect("alice", "1.1.1.1")
    c2 = mgr.connect("bob", "2.2.2.2")
    msg = mgr.send_message("alice", {"text": "hi bob"}, recipient_id=c2.id,
                           msg_type="direct")
    result = mgr.route_message(msg.id)
    assert result["type"] == "direct"
    assert result["delivered"] is True


def test_purge_expired_messages(mgr):
    room = mgr.create_room("ephemeral")
    msg = mgr.send_message("sys", {"event": "test"}, room_id=room.id, ttl=1)
    import time; time.sleep(2)
    purged = mgr.purge_expired_messages()
    assert purged >= 1


def test_connection_stats(mgr):
    mgr.connect("s1", "1.1.1.1")
    mgr.connect("s2", "2.2.2.2")
    mgr.create_room("stats-room")
    stats = mgr.get_connection_stats()
    assert stats["total_connections"] >= 2
    assert stats["rooms"] >= 1
    assert "top_rooms" in stats


def test_ping_pong_latency(mgr):
    conn = mgr.connect("ping-client", "3.3.3.3")
    mgr.ping(conn.id)
    import time; time.sleep(0.01)
    result = mgr.pong(conn.id)
    assert "latency_ms" in result
    assert result["latency_ms"] is not None

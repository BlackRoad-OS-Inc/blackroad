"""Tests for blackroad-websocket-manager."""
import json
import sys
import time
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from main_module import (
    Connection, ConnectionPool, Message, get_db,
    add_connection, remove_connection, broadcast,
    get_active_connections, heartbeat_check, send_message,
    get_message_history, connection_stats,
)


@pytest.fixture
def tmp_db(tmp_path):
    return get_db(tmp_path / "ws_test.db")


@pytest.fixture
def pool(tmp_db):
    return ConnectionPool(tmp_db)


def test_add_and_get_connection(pool, tmp_db):
    c = add_connection(pool, "ws-001", "octavia", {"ip": "127.0.0.1"})
    assert c.db_id is not None
    assert c.ws_id == "ws-001"
    assert c.agent == "octavia"
    assert c.metadata == {"ip": "127.0.0.1"}

    loaded = pool.get("ws-001")
    assert loaded is not None
    assert loaded.agent == "octavia"


def test_remove_connection(pool, tmp_db):
    add_connection(pool, "ws-remove", "alice")
    assert pool.get("ws-remove") is not None
    result = remove_connection(pool, "ws-remove")
    assert result is True
    assert pool.get("ws-remove") is None


def test_remove_nonexistent(pool):
    result = remove_connection(pool, "ghost-ws")
    assert result is False


def test_broadcast_all(pool, tmp_db):
    add_connection(pool, "ws-a", "alice")
    add_connection(pool, "ws-b", "octavia")
    add_connection(pool, "ws-c", "lucidia")
    delivered = broadcast(pool, tmp_db, {"event": "deploy"})
    assert len(delivered) == 3


def test_broadcast_with_filter(pool, tmp_db):
    add_connection(pool, "ws-f1", "alice")
    add_connection(pool, "ws-f2", "alice")
    add_connection(pool, "ws-f3", "octavia")
    delivered = broadcast(pool, tmp_db, "hello", filter_fn=lambda c: c.agent == "alice")
    assert len(delivered) == 2
    assert all("ws-f" in d for d in delivered)


def test_send_direct_message(pool, tmp_db):
    add_connection(pool, "ws-direct", "aria")
    msg = send_message(pool, tmp_db, "ws-direct", {"text": "ping"}, msg_type="ping")
    assert msg is not None
    assert msg.recipient_id == "ws-direct"
    assert msg.msg_type == "ping"


def test_send_to_nonexistent(pool, tmp_db):
    result = send_message(pool, tmp_db, "no-such-ws", "test")
    assert result is None


def test_heartbeat_update(pool):
    add_connection(pool, "ws-hb", "cipher")
    ok = pool.update_heartbeat("ws-hb", latency_ms=5)
    assert ok is True
    c = pool.get("ws-hb")
    assert c.last_heartbeat is not None


def test_heartbeat_check_timeout(pool, tmp_db):
    add_connection(pool, "ws-stale", "stale-agent")
    # Manually set last_heartbeat to past
    old_ts = "2020-01-01T00:00:00"
    tmp_db.execute("UPDATE connections SET last_heartbeat=? WHERE ws_id='ws-stale'", (old_ts,))
    tmp_db.commit()
    pool._pool["ws-stale"].last_heartbeat = old_ts

    result = heartbeat_check(pool, tmp_db, timeout=30)
    assert "ws-stale" in result["timed_out"]
    assert pool.get("ws-stale") is None


def test_heartbeat_check_active(pool, tmp_db):
    add_connection(pool, "ws-live", "live-agent")
    result = heartbeat_check(pool, tmp_db, timeout=30)
    assert "ws-live" in result["active"]


def test_message_history(pool, tmp_db):
    add_connection(pool, "ws-hist", "history-agent")
    send_message(pool, tmp_db, "ws-hist", "msg1")
    send_message(pool, tmp_db, "ws-hist", "msg2")
    history = get_message_history(tmp_db, ws_id="ws-hist", limit=10)
    assert len(history) >= 2


def test_connection_stats(pool, tmp_db):
    add_connection(pool, "ws-s1", "agentA")
    add_connection(pool, "ws-s2", "agentA")
    add_connection(pool, "ws-s3", "agentB")
    stats = connection_stats(pool, tmp_db)
    assert stats["active_connections"] >= 3
    assert "agentA" in stats["agents"]
    assert stats["agents"]["agentA"] >= 2


def test_message_count_increments(pool, tmp_db):
    add_connection(pool, "ws-cnt", "counter-agent")
    send_message(pool, tmp_db, "ws-cnt", "a")
    send_message(pool, tmp_db, "ws-cnt", "b")
    send_message(pool, tmp_db, "ws-cnt", "c")
    c = pool.get("ws-cnt")
    assert c.message_count == 3

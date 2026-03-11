"""Tests for the harmony module (HarmonyCoordinator, NodeProfile)."""

from __future__ import annotations

import json

from harmony import HarmonyCoordinator, NodeProfile


class TestNodeProfile:

    def test_to_dict(self):
        p = NodeProfile(
            name="alice",
            role="router",
            status="ready",
            capabilities=["route", "cache"],
            channels=["mesh", "console"],
        )
        d = p.to_dict()
        assert d["name"] == "alice"
        assert d["capabilities"] == ["cache", "route"]  # sorted
        assert d["channels"] == ["console", "mesh"]  # sorted


class TestHarmonyCoordinator:

    def test_local_status_persisted(self, tmp_path):
        ledger = tmp_path / "ledger.json"
        coord = HarmonyCoordinator("node-a", ledger_path=ledger)
        coord.update_local_status(role="worker", status="active", capabilities=["compute"])

        data = json.loads(ledger.read_text())
        assert "node-a" in data["nodes"]
        assert data["nodes"]["node-a"]["status"] == "active"

    def test_ping_remote_records_handshake(self, tmp_path):
        ledger = tmp_path / "ledger.json"
        coord = HarmonyCoordinator("node-a", ledger_path=ledger)
        hs = coord.ping_remote("node-b", intent="sync", payload={"key": "val"})
        assert hs["from"] == "node-a"
        assert hs["to"] == "node-b"
        assert hs["intent"] == "sync"
        assert hs["payload"]["key"] == "val"

    def test_list_recent_handshakes(self, tmp_path):
        ledger = tmp_path / "ledger.json"
        coord = HarmonyCoordinator("node-a", ledger_path=ledger)
        for i in range(5):
            coord.ping_remote(f"node-{i}", intent=f"intent-{i}")
        recent = coord.list_recent_handshakes(limit=3)
        assert len(recent) == 3
        # Most recent first.
        assert recent[0]["to"] == "node-4"

    def test_list_recent_handshakes_limit_zero(self, tmp_path):
        ledger = tmp_path / "ledger.json"
        coord = HarmonyCoordinator("node-a", ledger_path=ledger)
        coord.ping_remote("node-b")
        assert coord.list_recent_handshakes(limit=0) == []

    def test_export_state(self, tmp_path):
        ledger = tmp_path / "ledger.json"
        coord = HarmonyCoordinator("node-a", ledger_path=ledger)
        state = coord.export_state()
        assert "nodes" in state
        assert "handshakes" in state

    def test_transmitter_callback(self, tmp_path):
        ledger = tmp_path / "ledger.json"
        coord = HarmonyCoordinator("node-a", ledger_path=ledger)
        captured = []
        coord.ping_remote("node-b", transmitter=lambda hs: captured.append(hs))
        assert len(captured) == 1
        assert captured[0]["to"] == "node-b"

    def test_reload_from_disk(self, tmp_path):
        ledger = tmp_path / "ledger.json"
        coord1 = HarmonyCoordinator("node-a", ledger_path=ledger)
        coord1.ping_remote("node-b")
        # Create a fresh coordinator that loads from the same ledger.
        coord2 = HarmonyCoordinator("node-a", ledger_path=ledger)
        handshakes = coord2.list_recent_handshakes()
        assert any(h["to"] == "node-b" for h in handshakes)

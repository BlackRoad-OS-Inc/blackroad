"""Utilities to coordinate Lucidia with sibling Codex deployments."""
from __future__ import annotations

import json
from copy import deepcopy
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, List, Mapping, MutableMapping, Optional

DEFAULT_LEDGER_PATH = Path.home() / ".lucidia" / "harmony.json"


@dataclass
class NodeProfile:
    """Metadata describing a Lucidia-aligned node or console."""

    name: str
    role: str
    status: str
    capabilities: List[str] = field(default_factory=list)
    channels: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    last_seen: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        """Return a JSON serialisable representation of the profile."""

        payload = deepcopy(self.__dict__)
        payload["capabilities"] = sorted(payload.get("capabilities", []))
        payload["channels"] = sorted(payload.get("channels", []))
        return payload


class HarmonyCoordinator:
    """Persist lightweight coordination events for multi-node Lucidia setups.

    The coordinator keeps a small JSON ledger describing the local node as well
    as any handshakes initiated with sibling Codex deployments.  It does not
    assume bidirectional connectivity; instead it records intent so an
    out-of-band transport (SSH, MQTT, etc.) can replay the handshake.
    """

    def __init__(
        self,
        local_node: str,
        *,
        role: str = "console",
        status: str = "initialising",
        capabilities: Optional[Iterable[str]] = None,
        channels: Optional[Iterable[str]] = None,
        ledger_path: Optional[Path | str] = None,
    ) -> None:
        self.local_node = local_node
        self._ledger_path = Path(ledger_path) if ledger_path is not None else DEFAULT_LEDGER_PATH
        self._ledger_path.parent.mkdir(parents=True, exist_ok=True)
        self._state: MutableMapping[str, Any] = {"nodes": {}, "handshakes": []}
        self._load_state()
        self.update_local_status(
            role=role,
            status=status,
            capabilities=capabilities or [],
            channels=channels or [],
        )

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _load_state(self) -> None:
        if not self._ledger_path.exists():
            return
        try:
            data = json.loads(self._ledger_path.read_text())
        except (OSError, json.JSONDecodeError):  # pragma: no cover - defensive
            return
        if isinstance(data, Mapping):
            nodes = data.get("nodes", {})
            handshakes = data.get("handshakes", [])
            if isinstance(nodes, Mapping):
                self._state["nodes"].update({str(k): dict(v) for k, v in nodes.items() if isinstance(v, Mapping)})
            if isinstance(handshakes, list):
                self._state["handshakes"].extend(
                    handshake
                    for handshake in handshakes
                    if isinstance(handshake, Mapping)
                )

    def _write_state(self) -> None:
        payload = {
            "nodes": {name: deepcopy(profile) for name, profile in self._state["nodes"].items()},
            "handshakes": list(self._state["handshakes"]),
        }
        self._ledger_path.write_text(json.dumps(payload, indent=2, sort_keys=True))

    def _touch_local(self) -> None:
        now = datetime.now(timezone.utc).isoformat()
        profile = self._state["nodes"].get(self.local_node)
        if isinstance(profile, MutableMapping):
            profile["last_seen"] = now
        else:  # pragma: no cover - sanity guard
            self._state["nodes"][self.local_node] = {"name": self.local_node, "last_seen": now}
        self._write_state()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    def update_local_status(
        self,
        *,
        role: str,
        status: str,
        capabilities: Iterable[str] | None = None,
        channels: Iterable[str] | None = None,
        metadata: Optional[Mapping[str, Any]] = None,
    ) -> NodeProfile:
        """Update the local node profile and persist it to disk."""

        now = datetime.now(timezone.utc).isoformat()
        profile = NodeProfile(
            name=self.local_node,
            role=role,
            status=status,
            capabilities=list(dict.fromkeys(capabilities or [])),
            channels=list(dict.fromkeys(channels or [])),
            metadata=dict(metadata or {}),
            last_seen=now,
        )
        self._state["nodes"][self.local_node] = profile.to_dict()
        self._write_state()
        return profile

    def ping_remote(
        self,
        remote_node: str,
        *,
        intent: str = "sync",
        channel: str = "hologram-console",
        payload: Optional[Mapping[str, Any]] = None,
        transmitter: Optional[Callable[[Mapping[str, Any]], None]] = None,
    ) -> Dict[str, Any]:
        """Record an outgoing handshake toward ``remote_node``.

        ``transmitter`` can be supplied to forward the handshake through a
        concrete transport (HTTP request, MQTT publish, etc.).  The function is
        expected to be synchronous and raise if it fails so the caller can
        surface the error to the operator.
        """

        timestamp = datetime.now(timezone.utc).isoformat()
        handshake = {
            "from": self.local_node,
            "to": remote_node,
            "intent": intent,
            "channel": channel,
            "payload": dict(payload or {}),
            "timestamp": timestamp,
        }
        self._state.setdefault("handshakes", []).append(handshake)
        nodes = self._state.setdefault("nodes", {})
        remote_profile = nodes.get(remote_node, {"name": remote_node})
        remote_profile.setdefault("channels", [])
        remote_profile.setdefault("capabilities", [])
        remote_profile["last_seen"] = timestamp
        remote_profile.setdefault("status", "unknown")
        nodes[remote_node] = remote_profile
        self._touch_local()
        self._write_state()
        if transmitter is not None:
            transmitter(handshake)
        return handshake

    def list_recent_handshakes(self, *, limit: int = 10) -> List[Dict[str, Any]]:
        """Return the most recent handshake records (newest first)."""

        if limit <= 0:
            return []
        return list(reversed(self._state.get("handshakes", [])[-limit:]))

    def export_state(self) -> Dict[str, Any]:
        """Return a deep copy of the ledger state."""

        return {
            "nodes": {name: deepcopy(data) for name, data in self._state.get("nodes", {}).items()},
            "handshakes": list(self._state.get("handshakes", [])),
        }


__all__ = ["HarmonyCoordinator", "NodeProfile"]

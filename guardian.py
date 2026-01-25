#!/usr/bin/env python3
"""Guardian Agent
"""Guardian agent wired into the unified intelligence bus."""

from __future__ import annotations

from __future__ import annotations

import time
from typing import Any, Iterable, Mapping, Optional

from prism_event_bridge import fetch_events
import asyncio
import json
import logging
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

import yaml

from lucidia.intelligence.events import make_event, validate_event
from lucidia.reflex import BUS, start as start_reflex

class Guardian:
    def __init__(self) -> None:
        self.cursor: Optional[str] = None

    def handle_event(self, record: Mapping[str, Any]) -> None:
        topic = record.get("topic", "?")
        payload = record.get("payload", {})
        kpis = record.get("kpis")
        memory_deltas = record.get("memory_deltas")
        print(f"[guardian] event {topic}: {payload}")
        if kpis:
            print(f"[guardian]  KPIs: {kpis}")
        if isinstance(memory_deltas, Iterable):
            for delta in memory_deltas:
                print(f"[guardian]  memory delta: {delta}")

    def loop(self, poll_interval: float = 2.0) -> None:
        while True:
            events, cursor = fetch_events(since=self.cursor)
            if cursor:
                self.cursor = cursor
            for record in events:
                try:
                    self.handle_event(record)
                except Exception as exc:  # noqa: BLE001 - Guardian must keep running
                    print(f"[guardian] failed to handle event: {exc}")
            time.sleep(poll_interval)


def main() -> None:
    guardian = Guardian()
    guardian.loop()
LOGGER = logging.getLogger("lucidia.guardian")
LOGGER.setLevel(logging.INFO)
_handler = logging.StreamHandler()
_handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
LOGGER.addHandler(_handler)

DEFAULT_POLICY_PATH = Path(os.environ.get("LUCIDIA_GUARDIAN_POLICY", "guardian/policy.yaml"))


@dataclass(slots=True)
class PolicyEnvelope:
    """Loaded guardian policy metadata."""

    version: str
    directives: Mapping[str, Any]

    @classmethod
    def load(cls, path: Path) -> "PolicyEnvelope":
        if not path.exists():
            LOGGER.warning("Guardian policy missing at %s; using defaults", path)
            return cls(
                version="0.0.0",
                directives={
                    "restraint": ["no destructive operations"],
                    "contradiction": {"escalate": True, "cooldown_seconds": 180},
                },
            )
        with path.open("r", encoding="utf-8") as handle:
            payload = yaml.safe_load(handle) or {}
        return cls(
            version=str(payload.get("version", "0.0.0")),
            directives=payload.get("directives", {}),
        )


class Guardian:
    """Central truth arbiter for the Lucidia reflex loop."""

    def __init__(self, policy_path: Path = DEFAULT_POLICY_PATH) -> None:
        self._policy_path = policy_path
        self._policy = PolicyEnvelope.load(policy_path)
        self._state_path = Path(os.environ.get("LUCIDIA_GUARDIAN_STATE", "logs/guardian_state.json"))
        self._state_path.parent.mkdir(parents=True, exist_ok=True)
        BUS.on("guardian.contradiction", self._handle_contradiction)
        BUS.on("guardian.policy.request", self._handle_policy_request)
        BUS.on("memory.deltas.*", self._handle_memory_delta)
        LOGGER.info("Guardian initialized with policy version %s", self._policy.version)

    # ------------------------------------------------------------------
    def _handle_contradiction(self, event: Mapping[str, Any]) -> None:
        try:
            validate_event(event)
        except Exception as exc:  # pragma: no cover - guardrail
            LOGGER.error("Ignoring invalid contradiction event: %s", exc)
            return
        payload = event.get("payload", {})
        summary = payload.get("summary", "contradiction detected")
        severity = payload.get("severity", "unknown")
        LOGGER.warning("Contradiction(%s): %s", severity, summary)
        update_payload = {
            "decision": "halt" if severity in {"critical", "high"} else "review",
            "source_event": event["id"],
            "reason": summary,
        }
        update = make_event(
            topic="guardian.policy.update",
            payload=update_payload,
            source="guardian",
            channel="guardian",
            parent_id=event.get("id"),
            tags=["policy", "contradiction"],
        )
        BUS.emit(update["topic"], update)
        self._persist_state({"last_contradiction": update_payload})

    # ------------------------------------------------------------------
    def _handle_policy_request(self, event: Mapping[str, Any]) -> None:
        try:
            validate_event(event)
        except Exception as exc:  # pragma: no cover - guardrail
            LOGGER.error("Ignoring invalid policy request: %s", exc)
            return
        snapshot = make_event(
            topic="guardian.policy.snapshot",
            payload={
                "version": self._policy.version,
                "directives": self._policy.directives,
            },
            source="guardian",
            channel="guardian",
            parent_id=event.get("id"),
            tags=["policy", "snapshot"],
        )
        BUS.emit(snapshot["topic"], snapshot)

    # ------------------------------------------------------------------
    def _handle_memory_delta(self, event: Mapping[str, Any]) -> None:
        try:
            validate_event(event)
        except Exception:
            return
        payload = event.get("payload", {})
        delta_summary = payload.get("summary")
        LOGGER.info("Memory delta observed: %s", delta_summary)
        audit = make_event(
            topic="guardian.audit.memory",
            payload={
                "delta": payload,
                "ack": True,
            },
            source="guardian",
            channel="guardian",
            parent_id=event.get("id"),
            tags=["memory", "audit"],
        )
        BUS.emit(audit["topic"], audit)

    # ------------------------------------------------------------------
    def _persist_state(self, data: Mapping[str, Any]) -> None:
        snapshot = {"policy_version": self._policy.version, **data}
        try:
            with self._state_path.open("w", encoding="utf-8") as handle:
                json.dump(snapshot, handle, indent=2)
        except OSError as exc:  # pragma: no cover - guardrail
            LOGGER.error("Failed to persist guardian state: %s", exc)


def main() -> None:
    start_reflex()
    Guardian()
    LOGGER.info("Guardian ready; waiting for events")
    loop = asyncio.new_event_loop()
    try:
        loop.run_forever()
    finally:  # pragma: no cover - lifecycle guard
        loop.close()


if __name__ == "__main__":
    main()

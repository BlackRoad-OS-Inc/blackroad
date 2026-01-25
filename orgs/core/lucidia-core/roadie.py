#!/usr/bin/env python3
"""Roadie Agent
"""Roadie health monitor connected to the ReflexBus."""

from __future__ import annotations

from __future__ import annotations

import shutil
import time
from typing import Dict

from prism_event_bridge import publish_event


class Roadie:
    def __init__(self) -> None:
        self.last_health_check = 0.0

    def event(self, topic: str, payload: Dict[str, object]) -> None:
        publish_event(topic, payload, actor="roadie")

    def health_checks(self) -> None:
        total, used, free = shutil.disk_usage("/")
        payload = {
            "disk_total_gb": round(total / (1024**3), 2),
            "disk_used_gb": round(used / (1024**3), 2),
            "disk_free_gb": round(free / (1024**3), 2),
        }
        self.event("health.disk", payload)

    def mint_roadcoin(self, amount: float, reason: str) -> None:
        payload = {"amount": amount, "reason": reason}
        self.event("actions.roadcoin.mint", payload)
import asyncio
import logging
import os
import shutil
from pathlib import Path
from typing import Mapping

from lucidia.intelligence.events import make_event, validate_event
from lucidia.reflex import BUS, start as start_reflex

LOGGER = logging.getLogger("lucidia.roadie")
LOGGER.setLevel(logging.INFO)
_handler = logging.StreamHandler()
_handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
LOGGER.addHandler(_handler)

STATE_DIR = Path(os.environ.get("LUCIDIA_STATE_DIR", "logs/lucidia"))
STATE_DIR.mkdir(parents=True, exist_ok=True)


class Roadie:
    """Publishes system health, receives guardian directives, and tracks replay."""

    def __init__(self, interval_seconds: float = 60.0) -> None:
        self._interval = interval_seconds
        self._policy_actions = STATE_DIR / "guardian_actions.jsonl"
        BUS.on("guardian.policy.update", self._handle_policy_update)
        BUS.on("guardian.audit.memory", self._handle_guardian_audit)
        BUS.on("memory.state.request", self._handle_memory_request)

    # ------------------------------------------------------------------
    def _publish(self, topic: str, payload: Mapping[str, object], *, tags: list[str] | None = None) -> None:
        event = make_event(
            topic=topic,
            payload=payload,
            source="roadie",
            channel="reflex",
            tags=tags,
        )
        BUS.emit(event["topic"], event)

    # ------------------------------------------------------------------
    def _handle_policy_update(self, event: Mapping[str, object]) -> None:
        try:
            validate_event(event)
        except Exception as exc:  # pragma: no cover - guardrail
            LOGGER.error("Invalid policy update: %s", exc)
            return
        payload = event.get("payload", {})
        LOGGER.info("Guardian directive received: %s", payload)
        try:
            with self._policy_actions.open("a", encoding="utf-8") as handle:
                handle.write(f"{payload}\n")
        except OSError as exc:  # pragma: no cover - guardrail
            LOGGER.error("Failed to persist guardian directive: %s", exc)

    # ------------------------------------------------------------------
    def _handle_guardian_audit(self, event: Mapping[str, object]) -> None:
        try:
            validate_event(event)
        except Exception:
            return
        payload = event.get("payload", {})
        LOGGER.debug("Guardian audit ack: %s", payload)

    # ------------------------------------------------------------------
    def _handle_memory_request(self, event: Mapping[str, object]) -> None:
        try:
            validate_event(event)
        except Exception:
            return
        snapshot = make_event(
            topic="memory.state.snapshot",
            payload={"status": "pending"},
            source="roadie",
            channel="reflex",
            parent_id=event.get("id"),
            tags=["memory", "hydration"],
        )
        BUS.emit(snapshot["topic"], snapshot)

    # ------------------------------------------------------------------
    async def run(self) -> None:
        while True:
            self._emit_health()
            await asyncio.sleep(self._interval)

    # ------------------------------------------------------------------
    def _emit_health(self) -> None:
        usage = shutil.disk_usage("/")
        payload = {
            "disk_total_gb": round(usage.total / (1024**3), 2),
            "disk_used_gb": round(usage.used / (1024**3), 2),
            "disk_free_gb": round(usage.free / (1024**3), 2),
        }
        self._publish("observations.health.disk", payload, tags=["health", "disk"])
        self._publish(
            "actions.roadcoin.mint",
            {"amount": 0.01, "reason": "heartbeat"},
            tags=["economy", "heartbeat"],
        )


def main() -> None:
    r = Roadie()
    r.loop()
    start_reflex()
    roadie = Roadie(interval_seconds=float(os.environ.get("LUCIDIA_ROADIE_INTERVAL", "60")))
    LOGGER.info("Roadie started with interval %ss", roadie._interval)
    asyncio.run(roadie.run())


if __name__ == "__main__":
    main()

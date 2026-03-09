"""Simple calendar adapter for local development."""

from __future__ import annotations

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any

_DEFAULT_STORE = Path("logs/calendar_events.jsonl")


def _event_store_path() -> Path:
    configured = os.getenv("PRISM_CALENDAR_EVENT_LOG", "")
    path = Path(configured) if configured else _DEFAULT_STORE
    return path.expanduser().resolve()


def create_event(details: dict[str, Any]) -> dict[str, Any]:
    """Record an event and return the stored payload."""

    timestamp = datetime.utcnow().isoformat(timespec="seconds") + "Z"
    payload = {"created_at": timestamp, **details}

    store = _event_store_path()
    store.parent.mkdir(parents=True, exist_ok=True)
    with store.open("a", encoding="utf-8") as file:
        file.write(json.dumps(payload, ensure_ascii=False) + "\n")

    return payload


__all__ = ["create_event"]

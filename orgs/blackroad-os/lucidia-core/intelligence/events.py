"""Utilities for Lucidia's intelligence unification events."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, Mapping, MutableMapping, Optional
from uuid import uuid4

from jsonschema import Draft7Validator

_SCHEMA_PATH = (
    Path(__file__).resolve().parents[2]
    / "schemas"
    / "lucidia"
    / "intelligence-event.schema.json"
)
_SCHEMA_URI = "https://blackroad.ai/schemas/lucidia/intelligence-event.json"
_SCHEMA_VERSION = "1.0.0"


def _load_schema() -> Dict[str, Any]:
    with _SCHEMA_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


_VALIDATOR = Draft7Validator(_load_schema())


@dataclass(slots=True)
class IntelligenceEvent:
    """Structured event compatible with both ReflexBus and Prism."""

    topic: str
    payload: Mapping[str, Any]
    source: str
    channel: str
    parent_id: Optional[str] = None
    tags: Optional[Iterable[str]] = None
    causal_chain: Optional[Iterable[str]] = None
    meta: MutableMapping[str, Any] = field(default_factory=dict)
    event_id: str = field(default_factory=lambda: uuid4().hex)
    timestamp: str = field(
        default_factory=lambda: datetime.now(timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z")
    )

    def to_dict(self) -> Dict[str, Any]:
        meta = {"schema": _SCHEMA_URI, "version": _SCHEMA_VERSION}
        meta.update(self.meta)
        event: Dict[str, Any] = {
            "id": self.event_id,
            "topic": self.topic,
            "timestamp": self.timestamp,
            "source": self.source,
            "channel": self.channel,
            "payload": dict(self.payload),
            "meta": meta,
        }
        if self.tags is not None:
            event["tags"] = list(self.tags)
        causal: Dict[str, Any] = {}
        if self.parent_id:
            causal["parent"] = {"id": self.parent_id}
        if self.causal_chain:
            causal["chain"] = list(self.causal_chain)
        if causal:
            event["causal"] = causal
        _VALIDATOR.validate(event)
        return event


def make_event(
    *,
    topic: str,
    payload: Mapping[str, Any],
    source: str,
    channel: str,
    parent_id: Optional[str] = None,
    tags: Optional[Iterable[str]] = None,
    causal_chain: Optional[Iterable[str]] = None,
    meta: Optional[MutableMapping[str, Any]] = None,
    event_id: Optional[str] = None,
    timestamp: Optional[str] = None,
) -> Dict[str, Any]:
    """Create and validate a canonical intelligence event."""

    event = IntelligenceEvent(
        topic=topic,
        payload=payload,
        source=source,
        channel=channel,
        parent_id=parent_id,
        tags=tags,
        causal_chain=causal_chain,
        meta=meta or {},
        event_id=event_id or uuid4().hex,
        timestamp=timestamp
        or datetime.now(timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z"),
    )
    return event.to_dict()


def validate_event(event: Mapping[str, Any]) -> None:
    """Validate an arbitrary payload against the intelligence event schema."""

    _VALIDATOR.validate(event)

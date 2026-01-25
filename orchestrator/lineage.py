"""Data lineage helpers."""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Sequence

from orchestrator.consent import ConsentRegistry
from orchestrator.protocols import BotResponse, Task


@dataclass(slots=True)
class LineageEvent:
    """Represents a relationship between a task and a bot execution."""

    task_id: str
    bot_name: str
    timestamp: datetime
    artifacts: Sequence[str]

    def to_dict(self) -> Dict[str, object]:
        return {
            "task_id": self.task_id,
            "bot_name": self.bot_name,
            "timestamp": self.timestamp.isoformat(),
            "artifacts": list(self.artifacts),
        }


class LineageTracker:
    """In-memory tracker for lineage events persisted to disk."""

    def __init__(self, path: Path):
        self.path = path
        self._events: List[LineageEvent] = []
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if self.path.exists():
            self._load()

    def _load(self) -> None:
        for line in self.path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            payload = json.loads(line)
            self._events.append(
                LineageEvent(
                    task_id=payload["task_id"],
                    bot_name=payload["bot_name"],
                    timestamp=datetime.fromisoformat(payload["timestamp"]),
                    artifacts=tuple(payload.get("artifacts", [])),
                )
            )

    def record(self, task: Task, bot_name: str, response: BotResponse) -> LineageEvent:
        owner = task.owner or "system"
        ConsentRegistry.get_default().check_consent(
            from_agent=owner,
            to_agent=bot_name,
            consent_type="collaboration",
            scope=(f"task:{task.id}", "handoff"),
        )
        event = LineageEvent(
            task_id=task.id,
            bot_name=bot_name,
            timestamp=datetime.utcnow(),
            artifacts=response.artifacts,
        )
        self._events.append(event)
        with self.path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(event.to_dict()) + "\n")
        return event

    def events(self) -> Sequence[LineageEvent]:
        return tuple(self._events)

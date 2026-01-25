"""JSONL logger for reasoning duet sessions."""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Iterable, Optional

from .arbiter import ArbiterDecision
from .generator import Proposal
from .validator import ValidationResult


@dataclass
class TaskDescriptor:
    id: str
    goal: str
    constraints: Iterable[str]

    def to_payload(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "goal": self.goal,
            "constraints": list(self.constraints),
        }


class DuetLogger:
    """Append-only JSONL logger for duet sessions."""

    def __init__(self, log_dir: Path) -> None:
        self.log_dir = log_dir
        self.log_dir.mkdir(parents=True, exist_ok=True)

    def _session_path(self, session_id: str) -> Path:
        date_prefix = datetime.utcnow().strftime("%Y-%m-%d")
        return self.log_dir / f"{date_prefix}.jsonl"

    def append_round(
        self,
        *,
        session_id: str,
        task: TaskDescriptor,
        round_index: int,
        generator_model: str,
        proposal: Proposal,
        validation: ValidationResult,
        arbiter: ArbiterDecision,
        final_status: Optional[str] = None,
        next_actions: Optional[Iterable[str]] = None,
    ) -> None:
        payload: Dict[str, Any] = {
            "session_id": session_id,
            "task": task.to_payload(),
            "round": round_index,
            "generator": {
                "model": generator_model,
                "proposal": proposal.to_payload(),
            },
            "validator": validation.to_payload(),
            "arbiter": arbiter.to_payload(),
        }
        if final_status or next_actions:
            payload["final"] = {
                "status": final_status or "pending",
                "next_actions": list(next_actions or []),
            }

        path = self._session_path(session_id)
        with path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(payload, ensure_ascii=False) + "\n")


__all__ = ["DuetLogger", "TaskDescriptor"]

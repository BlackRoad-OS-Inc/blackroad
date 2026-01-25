from __future__ import annotations

from dataclasses import dataclass


@dataclass
class BotExecutionError(Exception):
    bot: str
    task_id: str
    reason: str

    def __str__(self) -> str:  # pragma: no cover - trivial
        return f"{self.bot} failed for task {self.task_id}: {self.reason}"

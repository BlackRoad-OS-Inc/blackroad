"""Persistence helpers for task storage."""

from __future__ import annotations

from dataclasses import asdict
from datetime import datetime
from pathlib import Path
from typing import List

from tools.storage import load_json, save_json

from .protocols import Task

TASKS_PATH = Path("orchestrator/tasks.json")


def load_tasks() -> List[Task]:
    data = load_json(TASKS_PATH, [])
    tasks: List[Task] = []
    for raw in data:
        if raw.get("scheduled_for"):
            raw["scheduled_for"] = datetime.fromisoformat(raw["scheduled_for"])
        tasks.append(Task(**raw))
    return tasks


def save_tasks(tasks: List[Task]) -> None:
    data = []
    for task in tasks:
        row = asdict(task)
        if row["scheduled_for"]:
            row["scheduled_for"] = row["scheduled_for"].isoformat()
        data.append(row)
    save_json(TASKS_PATH, data)


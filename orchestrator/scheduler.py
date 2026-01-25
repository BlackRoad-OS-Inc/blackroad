"""Polling scheduler for orchestrator tasks."""

from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

from .metrics import log_metric
from .protocols import BotExecutionError
from .router import route_task
from .tasks import load_tasks, save_tasks

SCHEDULE_LOG = Path("orchestrator/schedule.log.jsonl")


def schedule_poll(now: datetime) -> None:
    tasks = load_tasks()
    changed = False
    for task in tasks:
        if task.status != "pending":
            continue
        if task.scheduled_for and task.scheduled_for <= now:
            if task.scheduled_for and now - task.scheduled_for > timedelta(minutes=15):
                log_metric("schedule_sla_breach", task.id)
            try:
                route_task(task, tasks)
            except BotExecutionError:
                continue
            else:
                SCHEDULE_LOG.parent.mkdir(parents=True, exist_ok=True)
                record = {
                    "task_id": task.id,
                    "ran_at": now.isoformat(),
                }
                with SCHEDULE_LOG.open("a", encoding="utf-8") as f:
                    import json

                    f.write(json.dumps(record) + "\n")
                changed = True

    if changed:
        save_tasks(tasks)


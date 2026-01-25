from __future__ import annotations

import inspect
import os
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, Type

import settings
from bots import available_bots
from finance import costing
from orchestrator import lineage, metrics, redaction
from policy import enforcer
from tools import storage

from .base import BaseBot, assert_guardrails
from .protocols import BotResponse, Task
from .protocols import Task, BotResponse
from .base import BaseBot, assert_guardrails
from tools import storage
from bots import available_bots
from .slo import SLO_CATALOG

logger = logging.getLogger(__name__)

_memory_path = Path(__file__).resolve().with_name("memory.jsonl")
_current_doc = ""


def red_team(response: BotResponse) -> None:
    """Basic red team checks on a response."""
    if not response.summary.strip():
        raise AssertionError("Summary missing")
    if not response.risks:
        raise AssertionError("Risks required")
    if "KPIS" in _current_doc.upper() and "KPI" not in response.summary.upper():
        raise AssertionError("KPIs not referenced")


def route(task: Task, bot_name: str) -> BotResponse:
    """Route a task to the named bot and log the interaction."""
    registry: Dict[str, Type[BaseBot]] = available_bots()
    if bot_name not in registry:
        raise ValueError(f"Unknown bot: {bot_name}")

    logger.info("routing task", extra={"task_id": task.id, "bot": bot_name})
    metrics.inc("orchestrator_tasks_total")
    metrics.inc(f"orchestrator_tasks_bot_{bot_name}")

    violations = enforcer.check_task(task)
    if bot_name in settings.FORBIDDEN_BOTS:
        violations.append("TASK_FORBIDDEN_BOT")
    enforcer.enforce_or_raise(violations)

    scrubbed_ctx = redaction.scrub(task.context) if task.context else None
    task = Task(id=task.id, goal=task.goal, context=scrubbed_ctx, created_at=task.created_at)

    trace_id = lineage.start_trace(task.id)

    bot = registry[bot_name]()

    global _current_doc
    _current_doc = inspect.getdoc(bot) or ""

    response = bot.run(task)
    slo = SLO_CATALOG.get(bot_name)
    try:
        with perf_timer("bot_run") as perf:
            response = bot.run(task)
    except Exception:
        metrics.inc("orchestrator_task_failures_total")
        metrics.inc(f"orchestrator_task_failures_bot_{bot_name}")
        logger.exception("bot run failed", extra={"task_id": task.id, "bot": bot_name, "trace_id": trace_id})
        lineage.finalize(trace_id)
        raise

    response.elapsed_ms = perf.get("elapsed_ms")
    response.rss_mb = perf.get("rss_mb")
    if response.elapsed_ms is not None:
        metrics.gauge("orchestrator_last_run_elapsed_ms", int(response.elapsed_ms))
    if response.rss_mb is not None:
        metrics.gauge("orchestrator_last_run_rss_mb", int(response.rss_mb))
    if slo:
        response.slo_name = slo.name
        response.p50_target = slo.p50_ms
        response.p95_target = slo.p95_ms
        response.max_mem_mb = slo.max_mem_mb
    assert_guardrails(response)
    red_team(response)

    record = {
        "ts": datetime.utcnow().isoformat(),
        "task": task.model_dump(mode="json"),
        "bot": bot_name,
        "response": response.model_dump(mode="json"),
    }
    storage.write(str(_memory_path), record)
    costing.log(bot_name, user=os.getenv("PRISM_USER"), tenant=os.getenv("PRISM_TENANT"))
    lineage.finalize(trace_id)
    metrics.inc("orchestrator_task_success_total")
    metrics.inc(f"orchestrator_task_success_bot_{bot_name}")
    logger.info(
        "task completed",
        extra={
            "task_id": task.id,
            "bot": bot_name,
            "trace_id": trace_id,
            "elapsed_ms": response.elapsed_ms,
        },
    )
    return response
from __future__ import annotations

from dataclasses import asdict
from pathlib import Path
from uuid import uuid4

from config.settings import settings
from tools.storage import write_json, write_text

from .base import BotResponse, Task
from .errors import BotExecutionError
from .logging import log
from .metrics import record
from .registry import get


def create_task(goal: str, context: dict | None = None) -> Task:
    task = Task(id=str(uuid4()), goal=goal, context=context or {})
    record("task_created", task_id=task.id)
    return task


def route_task(task: Task, bot_name: str) -> BotResponse:
    bot = get(bot_name)
    record("task_routed", task_id=task.id, bot=bot_name)
    log({"event": "task_routed", "task_id": task.id, "bot": bot_name})
    try:
        resp = bot.run(task)
    except Exception as exc:  # pragma: no cover - delegated
        record("bot_failure", task_id=task.id, bot=bot_name)
        raise BotExecutionError(bot=bot_name, task_id=task.id, reason=str(exc)) from exc
    if not resp.summary or bot_name not in resp.summary:
        raise BotExecutionError(bot=bot_name, task_id=task.id, reason="invalid summary")
    if not resp.risks:
        raise BotExecutionError(bot=bot_name, task_id=task.id, reason="risks missing")
    record("bot_success", task_id=task.id, bot=bot_name)
    artifact_dir = Path(settings.ARTIFACTS_DIR) / task.id
    write_json(artifact_dir / f"{bot_name.lower()}_response.json", asdict(resp))
    write_text(artifact_dir / f"{bot_name.lower()}_summary.md", resp.summary)
    return resp
from __future__ import annotations

import json
import uuid
from dataclasses import asdict
from pathlib import Path
from typing import Any, Dict, List

from .protocols import Response, Task


class Orchestrator:
    """Routes tasks to registered bots and logs all actions."""

    def __init__(
        self,
        memory_path: str | Path = "memory.jsonl",
        state_path: str | Path | None = None,
    ) -> None:
        self.bots: Dict[str, Any] = {}
        self.tasks: Dict[str, Task] = {}
        self.responses: Dict[str, Response] = {}
        self.memory_path = Path(memory_path)
        self.state_path = Path(state_path) if state_path else self.memory_path.with_suffix(".state.json")
        self._load_state()

    # Bot management -------------------------------------------------
    def register_bot(self, domain: str, bot: Any) -> None:
        self.bots[domain] = bot

    # Task lifecycle -------------------------------------------------
    def create_task(self, description: str, domain: str, metadata: Dict[str, Any] | None = None) -> Task:
        task = Task(id=str(uuid.uuid4()), description=description, domain=domain, metadata=metadata or {})
        if task.metadata.get("allow_network"):
            raise ValueError("Network calls are disallowed by guardrails")
        self.tasks[task.id] = task
        self._log({"event": "task_created", "task": task.__dict__})
        self._persist_state()
        return task

    def route(self, task_id: str) -> Response:
        task = self.tasks[task_id]
        bot = self.bots.get(task.domain)
        if not bot:
            response = Response(task_id=task.id, status="error", data=f"No bot for domain {task.domain}")
        else:
            response = bot.run(task)
        self.responses[task.id] = response
        self._log({"event": "task_routed", "task_id": task.id, "response": response.__dict__})
        self._persist_state()
        return response

    def list_tasks(self) -> List[Task]:
        return list(self.tasks.values())

    def get_status(self, task_id: str) -> Response | None:
        return self.responses.get(task_id)

    # Internal logging -----------------------------------------------
    def _log(self, record: Dict[str, Any]) -> None:
        self.memory_path.parent.mkdir(parents=True, exist_ok=True)
        with self.memory_path.open("a") as fh:
            fh.write(json.dumps(record) + "\n")

    def _load_state(self) -> None:
        if not self.state_path.exists():
            return

        data = json.loads(self.state_path.read_text())
        tasks = data.get("tasks", {})
        responses = data.get("responses", {})

        for task_id, payload in tasks.items():
            self.tasks[task_id] = Task(**payload)

        for task_id, payload in responses.items():
            self.responses[task_id] = Response(**payload)

    def _persist_state(self) -> None:
        state = {
            "tasks": {task_id: asdict(task) for task_id, task in self.tasks.items()},
            "responses": {task_id: asdict(response) for task_id, response in self.responses.items()},
        }

        self.state_path.parent.mkdir(parents=True, exist_ok=True)
        self.state_path.write_text(json.dumps(state, indent=2, sort_keys=True, default=str))

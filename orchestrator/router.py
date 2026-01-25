"""Task routing, persistence, and scheduling helpers."""
from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Mapping, Sequence

from .consent import ConsentRegistry, ConsentType
from .exceptions import BotNotRegisteredError, ConsentViolationError, TaskNotFoundError
from .consent import ConsentRegistry
from .exceptions import BotNotRegisteredError, TaskNotFoundError
from .lineage import LineageTracker
from .memory import MemoryLog
from .metrics import log_metric
from .policy import PolicyEngine
from .protocols import BaseBot, BotExecutionError, BotResponse, Task, TaskPriority
from .sec import SecRule2042Gate


class BotRegistry:
    """In-memory registry of bots addressable by name."""

    def __init__(self) -> None:
        self._bots: Dict[str, BaseBot] = {}

    def register(self, bot: BaseBot) -> None:
        self._bots[bot.metadata.name] = bot

    def get(self, name: str) -> BaseBot:
        try:
            return self._bots[name]
        except KeyError as exc:  # pragma: no cover - defensive guard
            raise BotNotRegisteredError(f"bot '{name}' is not registered") from exc

    def list(self) -> Sequence[BaseBot]:
        return tuple(self._bots.values())


def _parse_datetime(value: str | None) -> datetime | None:
    return datetime.fromisoformat(value) if value else None


class TaskRepository:
    """Simple JSON-backed store for :class:`Task` objects."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self._save({})

    def _load(self) -> Dict[str, Dict[str, Any]]:
        try:
            contents = self.path.read_text(encoding="utf-8")
        except FileNotFoundError:
            return {}
        if not contents.strip():
            return {}
        return json.loads(contents)

    def _save(self, data: Mapping[str, Dict[str, Any]]) -> None:
        self.path.write_text(json.dumps(data, indent=2), encoding="utf-8")

    def add(self, task: Task) -> None:
        data = self._load()
        data[task.id] = task.to_dict()
        self._save(data)

    def update(self, task: Task) -> None:
        data = self._load()
        if task.id not in data:
            raise TaskNotFoundError(f"task '{task.id}' not found")
        data[task.id] = task.to_dict()
        self._save(data)

    def get(self, task_id: str) -> Task:
        payload = self._load().get(task_id)
        if payload is None:
            raise TaskNotFoundError(f"task '{task_id}' not found")
        return self._task_from_payload(payload)

    def list(self) -> Sequence[Task]:
        return tuple(self._task_from_payload(payload) for payload in self._load().values())

    @staticmethod
    def _task_from_payload(payload: Mapping[str, Any]) -> Task:
        priority = payload.get("priority", TaskPriority.MEDIUM.value)
        if isinstance(priority, str):
            priority_value: TaskPriority | str = TaskPriority(priority.lower())
        else:
            priority_value = priority
        created = payload.get("created_at")
        created_at = (
            datetime.fromisoformat(created) if isinstance(created, str) else datetime.utcnow()
        )
        due_value = payload.get("due_date")
        scheduled_value = payload.get("scheduled_for")
        return Task(
            id=str(payload["id"]),
            goal=str(payload["goal"]),
            bot=str(payload.get("bot", "")),
            owner=payload.get("owner"),
            priority=priority_value,
            created_at=created_at,
            due_date=_parse_datetime(due_value if isinstance(due_value, str) else None),
            tags=tuple(payload.get("tags", [])),
            metadata=dict(payload.get("metadata", {})) or None,
            config=dict(payload.get("config", {})) or None,
            context=dict(payload.get("context", {})) or None,
            status=str(payload.get("status", "pending")),
            depends_on=tuple(payload.get("depends_on", [])),
            scheduled_for=_parse_datetime(
                scheduled_value if isinstance(scheduled_value, str) else None
            ),
        )


@dataclass(slots=True)
class RouteContext:
    """Context payload supplied to :meth:`Router.route`."""

    policy_engine: PolicyEngine
    memory: MemoryLog
    lineage: LineageTracker
    config: Mapping[str, Any] | None = None
    approved_by: Sequence[str] | None = None
    sec_gate: SecRule2042Gate | None = None
    consent_registry: ConsentRegistry | None = None
    acting_agent: str | None = None


class Router:
    """Coordinate routing of tasks to registered bots."""

    def __init__(self, registry: BotRegistry, repository: TaskRepository) -> None:
        self.registry = registry
        self.repository = repository

    def route(self, task_id: str, bot_name: str, context: RouteContext) -> BotResponse:
        task = self.repository.get(task_id)

        if context.config:
            merged_config: Dict[str, Any] = dict(task.config or {})
            merged_config.update(context.config)
            task.config = merged_config

        if context.sec_gate is not None:
            context.sec_gate.enforce(task)

        bot = self.registry.get(bot_name)
        context.policy_engine.enforce(bot_name, context.approved_by)
        registry = ConsentRegistry.get_default()
        owner = task.owner or "system"

        if context.consent_registry is not None:
            actor = (
                context.acting_agent
                or task.owner
                or (task.metadata or {}).get("requested_by")
            )
            if actor is None:
                raise ConsentViolationError("consent_actor_unknown")
            scope_hint = (task.metadata or {}).get("consent_scope") or task.id
            if not context.consent_registry.check_consent(
                actor=actor,
                consent_type=ConsentType.TASK_ASSIGNMENT,
                target=bot.metadata.name,
                scope=scope_hint,
            ):
                raise ConsentViolationError("consent_not_granted")

        response = bot.run(task)
        task.status = "done" if getattr(response, "ok", False) else "failed"
        self.repository.update(task)
        registry.check_consent(
            from_agent=owner,
            to_agent=bot.metadata.name,
            consent_type="data_access",
            scope=(f"task:{task.id}", "memory"),
        )
        context.memory.append(task, bot.metadata.name, response)
        registry.check_consent(
            from_agent=owner,
            to_agent=bot.metadata.name,
            consent_type="collaboration",
            scope=(f"task:{task.id}", "handoff"),
        )
        context.lineage.record(task, bot.metadata.name, response)
        return response


def dependencies_met(task: Task, tasks: Sequence[Task]) -> bool:
    """Check whether all dependencies for *task* are complete."""

    completed = {candidate.id for candidate in tasks if candidate.status == "done"}
    return all(dependency in completed for dependency in task.depends_on)


def route_task(task: Task, tasks: Sequence[Task]) -> None:
    """Route a scheduled task via the global bot registry."""

    from bots import BOT_REGISTRY  # Imported lazily to avoid circular import

    if not dependencies_met(task, tasks):
        log_metric("dependency_block", task.id)
        raise BotExecutionError("dependencies_not_met")

    try:
        bot = BOT_REGISTRY.get(task.bot or "")
    except BotNotRegisteredError as exc:  # pragma: no cover - defensive guard
        log_metric("bot_not_found", task.id)
        raise BotExecutionError("bot_not_found") from exc

    response = bot.run(task)
    success = getattr(response, "ok", None)
    if success is None:
        success = response is not None
    if success:
        task.status = "done"
    else:
        task.status = "failed"
        log_metric("task_failed", task.id)

"""Public orchestrator exports and legacy routing helper."""

from __future__ import annotations

import importlib
from logging import getLogger
from typing import Any

from sdk import plugin_api
from .base import BaseBot, BotMetadata
from .consent import ConsentGrant, ConsentRegistry, ConsentRequest, ConsentType
from .consent import ConsentGrant, ConsentRegistry, ConsentRequest
from .lineage import LineageTracker
from .memory import MemoryLog
from .policy import PolicyEngine
from .protocols import (
    BotExecutionError,
    BotResponse,
    MemoryRecord,
    Task,
    TaskPriority,
)
from .router import BotRegistry, RouteContext, Router, TaskRepository
from .sandbox import run_in_sandbox
from .sec import SecRule2042Gate
from .tasks import load_tasks, save_tasks

_logger = importlib.import_module("logging").getLogger(__name__)
logger = getLogger(__name__)

__all__ = [
    "BaseBot",
    "BotMetadata",
    "ConsentGrant",
    "ConsentRegistry",
    "ConsentRequest",
    "ConsentType",
    "LineageTracker",
    "MemoryLog",
    "PolicyEngine",
    "BotResponse",
    "MemoryRecord",
    "Task",
    "TaskPriority",
    "ConsentRegistry",
    "ConsentRequest",
    "ConsentGrant",
    "BotExecutionError",
    "BotRegistry",
    "RouteContext",
    "Router",
    "TaskRepository",
    "SecRule2042Gate",
    "load_tasks",
    "save_tasks",
    "route",
]


def route(bot_name: str, task: plugin_api.Task) -> Any:
    """Entrypoint used by plugins to execute bot handlers."""

    from . import registry as _registry

    bot_cls = _registry.get_bot(bot_name)
    if not bot_cls:
        raise ValueError(f"bot {bot_name} not found")

    bot = bot_cls()
    settings = plugin_api.get_settings()
    exec_mode = getattr(settings, "EXECUTION_MODE", "inproc")
    _logger.info(
        "route",
        extra={
            "execution_mode": exec_mode,
            "lang": getattr(settings, "LANG", None),
            "theme": getattr(settings, "THEME", None),
        },
    )

    if exec_mode == "sandbox":
        return run_in_sandbox(lambda: bot.handle(task))
    return bot.handle(task)
"""Orchestrator package for bot routing."""

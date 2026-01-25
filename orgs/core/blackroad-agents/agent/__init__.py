"""Public interface for the BlackRoad agent package."""

from __future__ import annotations

import os
from importlib import import_module
from pathlib import Path
from typing import TYPE_CHECKING, Any

from .config import active_target, auth_token, load, save, set_target

__all__ = [
    "DEFAULT_REMOTE_HOST",
    "DEFAULT_REMOTE_USER",
    "DEFAULT_DB_PATH",
    "_host_user",
    "auth_token",
    "active_target",
    "set_target",
    "load",
    "save",
    "discover",
    "jobs",
    "models",
    "store",
    "telemetry",
    "transcribe",
    "__version__",
]

_MODULE_EXPORTS = {
    "discover": "discover",
    "jobs": "jobs",
    "models": "models",
    "store": "store",
    "telemetry": "telemetry",
    "transcribe": "transcribe",
}

if TYPE_CHECKING:  # pragma: no cover - import-time only for type checkers
    from . import discover, jobs, models, store, telemetry, transcribe


def __getattr__(name: str) -> Any:
    """Lazily import agent submodules when accessed."""

    if name in _MODULE_EXPORTS:
        module = import_module(f"{__name__}.{_MODULE_EXPORTS[name]}")
        globals()[name] = module
        return module
    raise AttributeError(f"module '{__name__}' has no attribute '{name}'")

DEFAULT_REMOTE_HOST = os.getenv("BLACKROAD_REMOTE_HOST", "jetson-01")
DEFAULT_REMOTE_USER = os.getenv("BLACKROAD_REMOTE_USER", "pi")
DEFAULT_DB_PATH = Path(os.getenv("BLACKROAD_JOBS_DB", "/var/lib/blackroad/jobs.db"))


def _host_user(host: str | None = None, user: str | None = None) -> tuple[str, str]:
    """Resolve the remote host/user pair for SSH operations."""

    resolved_host = host or DEFAULT_REMOTE_HOST
    resolved_user = user or DEFAULT_REMOTE_USER
    return resolved_host, resolved_user


__version__ = "0.1.0"
"""Agent utilities for remote job orchestration."""

from . import jobs, store  # noqa: F401

__all__ = ["jobs", "store"]
"""Agent control surface utilities."""

from .flash import flash, list_devices

__all__ = ["flash", "list_devices"]
"""Agent package for BlackRoad Pi services."""

from . import flash  # re-export for convenience

__all__ = ["flash"]
"""Utilities for managing remote jobs executed on Jetson hosts."""

from . import jobs, store

__all__ = ["jobs", "store"]
"""BlackRoad agent service helpers."""

from . import api, config, flash, jobs, telemetry  # noqa: F401

__all__ = ["api", "config", "flash", "jobs", "telemetry"]
"""Utility modules for the BlackRoad agent dashboard."""

__all__ = []
"""Agent service package."""

__all__ = [
    "transcribe",
]
"""Foundational runtime primitives for the BlackRoad personal agent."""

from .config import AgentConfig
from .runtime import AgentRuntime

__all__ = ["AgentConfig", "AgentRuntime"]
"""Agent service package exposing the FastAPI application."""

from .api import app

__all__ = ["app"]
"""BlackRoad agent package."""

from . import telemetry, jobs

__all__ = [
    "telemetry",
    "jobs",
]
"""Agent package for console integrations."""
"""Agent package exposing dashboard telemetry and job helpers."""
from importlib import import_module

telemetry = import_module(".telemetry", __name__)
jobs = import_module(".jobs", __name__)

__all__ = ["telemetry", "jobs"]
"""BlackRoad agent package for daemon and telemetry helpers."""

__all__ = ["telemetry"]

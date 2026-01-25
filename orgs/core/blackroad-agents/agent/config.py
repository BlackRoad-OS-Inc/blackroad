"""Configuration helpers for the BlackRoad agent services."""
from __future__ import annotations

import os
from copy import deepcopy
from pathlib import Path
from typing import Any, Dict

import yaml

CONFIG_PATH = Path(os.environ.get("BLACKROAD_CONFIG", "/etc/blackroad/config.yaml"))

DEFAULTS: Dict[str, Any] = {
    "jetson": {"host": "192.168.4.23", "user": "jetson"},
    "auth": {"token": ""},
}


def _deep_update(base: Dict[str, Any], updates: Dict[str, Any]) -> Dict[str, Any]:
    for key, value in updates.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            base[key] = _deep_update(dict(base[key]), value)
        else:
            base[key] = value
    return base


def load() -> Dict[str, Any]:
    """Load the persisted configuration merged with defaults."""
    data: Dict[str, Any] = {}
    if CONFIG_PATH.exists():
        try:
            raw = yaml.safe_load(CONFIG_PATH.read_text())
            if isinstance(raw, dict):
                data = raw
        except yaml.YAMLError:
            data = {}
    merged = deepcopy(DEFAULTS)
    return _deep_update(merged, data)


def save(config: Dict[str, Any]) -> None:
    """Persist the configuration to disk."""
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with CONFIG_PATH.open("w", encoding="utf-8") as handle:
        yaml.safe_dump(config, handle, sort_keys=True)


def auth_token() -> str:
    """Return the configured authentication token (empty when disabled)."""
    return str(load().get("auth", {}).get("token", ""))
"""Configuration helpers for tracking the active Jetson target."""
"""Helpers for reading and writing the BlackRoad agent configuration."""
"""Runtime configuration helpers for Pi ↔ Jetson orchestration."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any, Dict, Optional

import yaml

DEFAULT_USER = "jetson"
CONFIG_ENV_VAR = "BLACKROAD_CONFIG"
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict

import yaml

DEFAULT_CONFIG_PATH = Path("/etc/blackroad/config.yaml")


def _config_path() -> Path:
    """Resolve the configuration path, honoring overrides."""
    env_path = os.environ.get(CONFIG_ENV_VAR)
    if env_path:
        return Path(env_path)
    return DEFAULT_CONFIG_PATH


def _load_config() -> Dict[str, Any]:
    path = _config_path()
    if not path.exists():
        return {}
    try:
        with path.open("r", encoding="utf-8") as fh:
            data = yaml.safe_load(fh) or {}
            if isinstance(data, dict):
                return data
    except yaml.YAMLError:
        # Corrupt YAML shouldn't crash the dashboard; treat as empty.
        return {}
    except OSError:
        return {}
    return {}


def _write_config(data: Dict[str, Any]) -> None:
    path = _config_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = path.with_suffix(path.suffix + ".tmp")
    with tmp_path.open("w", encoding="utf-8") as fh:
        yaml.safe_dump(data, fh, sort_keys=True)
    tmp_path.replace(path)


def active_target() -> Optional[Dict[str, str]]:
    cfg = _load_config()
    target = cfg.get("jetson") if isinstance(cfg, dict) else None
    if isinstance(target, dict):
        host = target.get("host")
        user = target.get("user", DEFAULT_USER)
        if host:
            return {"host": host, "user": user}
    return None


def set_target(host: str, user: str = DEFAULT_USER) -> None:
    if not host:
        raise ValueError("host must be provided")
    user = user or DEFAULT_USER
    cfg = _load_config()
    if not isinstance(cfg, dict):
        cfg = {}
    cfg["jetson"] = {"host": host, "user": user}
    _write_config(cfg)


__all__ = ["active_target", "set_target", "DEFAULT_USER"]
    """Return the path to the BlackRoad config file."""
    override = os.getenv("BLACKROAD_CONFIG")
    if override:
        return Path(override)
    return DEFAULT_CONFIG_PATH


def _load_config(path: Path | None = None) -> Dict[str, Any]:
    path = path or _config_path()
    if not path.exists():
        return {}
    try:
        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
            if isinstance(data, dict):
                return data
    except (OSError, yaml.YAMLError):
        pass
    return {}


def _write_config(data: Dict[str, Any], path: Path | None = None) -> None:
    path = path or _config_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    serialized = yaml.safe_dump(data, sort_keys=True) if data else "{}\n"
    with tempfile.NamedTemporaryFile("w", delete=False, dir=str(path.parent), encoding="utf-8") as tmp:
        tmp.write(serialized)
        tmp_path = Path(tmp.name)
    os.replace(tmp_path, path)


def active_target() -> Dict[str, Any]:
    """Return the currently configured Jetson/SSH target."""
    config = _load_config()
    target = config.get("jetson")
    if isinstance(target, dict):
        return target
    return {}


def set_target(host: str, user: str = "jetson") -> None:
    """Persist the active target information to the config file."""
    config = _load_config()
    jetson = config.get("jetson") if isinstance(config.get("jetson"), dict) else {}
    jetson.update({
        "host": host,
        "user": user,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    })
    config["jetson"] = jetson
    _write_config(config)
from typing import Tuple


def active_target() -> Tuple[str, str]:
    """Return the SSH target (host, user) for the Jetson worker.

    The helper checks the following environment variables in order:

    1. ``JETSON_TARGET`` – formatted as ``"user@host"`` or just ``"host"``
       (falls back to ``JETSON_USER``/``JETSON_HOST`` for missing pieces).
    2. ``JETSON_HOST`` and ``JETSON_USER`` individually.

    If nothing is configured, ``jetson.local`` and ``ubuntu`` are returned so
    the rest of the stack has sensible defaults during development.
    """

    target = os.environ.get("JETSON_TARGET", "").strip()
    host = os.environ.get("JETSON_HOST", "").strip()
    user = os.environ.get("JETSON_USER", "").strip()

    if target:
        if "@" in target:
            user_part, host_part = target.split("@", 1)
            user = user or user_part
            host = host or host_part
        else:
            host = host or target

    if not host:
        host = "jetson.local"
    if not user:
        user = "ubuntu"

    return host, user


__all__ = ["active_target"]

"""Runtime configuration helpers for remote GPU transcription."""
from __future__ import annotations

import os
from functools import lru_cache
from typing import Tuple

_DEFAULT_TARGET = ("jetson.local", "ubuntu")


def _parse_target(target: str) -> Tuple[str, str]:
    """Parse a "user@host" style target string."""
    if "@" in target:
        user, host = target.split("@", 1)
        user = user or _DEFAULT_TARGET[1]
        host = host or _DEFAULT_TARGET[0]
        return host, user
    return (target or _DEFAULT_TARGET[0], _DEFAULT_TARGET[1])


@lru_cache(maxsize=1)
def active_target() -> Tuple[str, str]:
    """Return the SSH host/user tuple for the Jetson target."""
    target = os.getenv("JETSON_TARGET")
    host_env = os.getenv("JETSON_HOST") or os.getenv("BLACKROAD_JETSON_HOST")
    user_env = os.getenv("JETSON_USER") or os.getenv("BLACKROAD_JETSON_USER")

    if target:
        host, user = _parse_target(target)
    else:
        host = host_env or _DEFAULT_TARGET[0]
        user = user_env or _DEFAULT_TARGET[1]
    return host, user
"""Persistent configuration store for BlackRoad agent settings."""
from __future__ import annotations

import os
import pathlib
from typing import Tuple

import yaml

CONF_PATH = pathlib.Path(os.getenv("BLACKROAD_CONF", "/etc/blackroad/config.yaml"))

DEFAULTS = {
    "jetson": {"host": "192.168.4.23", "user": "jetson"},
}


def ensure_dir() -> None:
    """Ensure the configuration directory exists."""
    CONF_PATH.parent.mkdir(parents=True, exist_ok=True)


def load() -> dict:
    """Load configuration file, falling back to defaults on error."""
    try:
        with open(CONF_PATH, "r", encoding="utf-8") as file:
            data = yaml.safe_load(file) or {}
            merged = DEFAULTS.copy()
            merged.update(data)
            return merged
    except Exception:
        return DEFAULTS.copy()


def save(cfg: dict) -> None:
    """Persist configuration to disk."""
    ensure_dir()
    with open(CONF_PATH, "w", encoding="utf-8") as file:
        yaml.safe_dump(cfg, file, sort_keys=False)


def active_target() -> Tuple[str, str]:
    """Return the currently configured Jetson host and user."""
    cfg = load()
    jetson = cfg.get("jetson", {})
    return (
        jetson.get("host", DEFAULTS["jetson"]["host"]),
        jetson.get("user", DEFAULTS["jetson"]["user"]),
    )


def set_target(host: str, user: str) -> None:
    """Persist a new Jetson target."""
    cfg = load()
    cfg["jetson"] = {"host": host, "user": user}
    save(cfg)
"""Configuration dataclasses for the BlackRoad agent runtime."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional


@dataclass
class PluginMount:
    """Represents a plugin mount point in the agent workspace."""

    name: str
    module: str
    enabled: bool = True
    config: Dict[str, object] = field(default_factory=dict)


@dataclass
class AgentConfig:
    """Top-level configuration for instantiating an agent runtime."""

    name: str
    persona: str
    workspace_root: Path
    mounts: List[PluginMount] = field(default_factory=list)
    default_model: Optional[str] = None
    notes: Optional[str] = None

    def enabled_mounts(self) -> List[PluginMount]:
        """Return only the mounts that should be activated at startup."""

        return [mount for mount in self.mounts if mount.enabled]

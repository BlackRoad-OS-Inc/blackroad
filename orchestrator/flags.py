"""Simple feature flag manager."""
from __future__ import annotations

from pathlib import Path
from typing import Any, Dict

import yaml

ROOT = Path(__file__).resolve().parents[1]
FLAGS_FILE = ROOT / "config" / "flags.yaml"


def _load() -> Dict[str, Any]:
    if FLAGS_FILE.exists():
        data = yaml.safe_load(FLAGS_FILE.read_text()) or {}
    else:
        data = {}
    for scope in ["global", "bot", "cli", "tui", "chaos"]:
        data.setdefault(scope, {})
    return data


def list_flags() -> Dict[str, Any]:
    """Return all flags as a nested dict."""
    return _load()


def get_flag(name: str, default: Any | None = None) -> Any:
    """Fetch a flag using dot notation."""
    parts = name.split(".")
    data = _load()
    cur: Any = data
    for part in parts:
        if isinstance(cur, dict) and part in cur:
            cur = cur[part]
        else:
            return default
    return cur


def set_flag(name: str, value: Any) -> None:
    data = _load()
    parts = name.split(".")
    cur = data
    for part in parts[:-1]:
        cur = cur.setdefault(part, {})
    cur[parts[-1]] = value
    FLAGS_FILE.parent.mkdir(parents=True, exist_ok=True)
    FLAGS_FILE.write_text(yaml.safe_dump(data))

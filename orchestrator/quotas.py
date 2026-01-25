"""Local quota management."""
from __future__ import annotations

import json
from datetime import date
from pathlib import Path
from typing import Dict

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config" / "quotas.yaml"
STATE_DIR = ROOT / "artifacts" / "quota_state"

try:
    import yaml
except Exception:  # pragma: no cover
    yaml = None  # type: ignore


def _load_config() -> Dict:
    if CONFIG.exists() and yaml:
        return yaml.safe_load(CONFIG.read_text()) or {}
    return {"tasks": {"default": 5}}


def _state_path(user: str) -> Path:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    return STATE_DIR / f"{user}.json"


def _load_state(user: str) -> Dict:
    path = _state_path(user)
    if path.exists():
        return json.loads(path.read_text())
    return {"date": str(date.today()), "counts": {}}


def _save_state(user: str, state: Dict) -> None:
    _state_path(user).write_text(json.dumps(state))


def check_and_consume(user: str, quota_name: str, amount: int = 1) -> None:
    cfg = _load_config().get(quota_name, {})
    limit = cfg.get(user, cfg.get("default"))
    if limit is None:
        return
    state = _load_state(user)
    if state["date"] != str(date.today()):
        state = {"date": str(date.today()), "counts": {}}
    count = state["counts"].get(quota_name, 0)
    if count + amount > limit:
        raise RuntimeError("Quota exceeded")
    state["counts"][quota_name] = count + amount
    _save_state(user, state)


def show(user: str) -> Dict:
    cfg = _load_config()
    state = _load_state(user)
    return {"config": cfg, "state": state}

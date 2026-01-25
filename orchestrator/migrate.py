"""Simple migration runner."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
from typing import Dict, List

ROOT = Path(__file__).resolve().parents[1]
MIG_DIR = ROOT / "migrations"
STATE_FILE = MIG_DIR / "state.json"


def _checksum(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def _load_state() -> Dict[str, str]:
    if STATE_FILE.exists():
        data = json.loads(STATE_FILE.read_text())
        return data.get("applied", {})
    return {}


def _save_state(applied: Dict[str, str]) -> None:
    STATE_FILE.write_text(json.dumps({"applied": applied}))


def list_migrations() -> List[tuple[str, bool]]:
    state = _load_state()
    migs: List[tuple[str, bool]] = []
    for path in sorted(MIG_DIR.glob("0*.py")):
        migs.append((path.name, path.name in state))
    return migs


def apply_all() -> List[str]:
    state = _load_state()
    applied: List[str] = []
    for path in sorted(MIG_DIR.glob("0*.py")):
        cs = _checksum(path)
        if state.get(path.name) == cs:
            continue
        spec = importlib.util.spec_from_file_location(path.stem, path)
        assert spec and spec.loader
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[attr-defined]
        if hasattr(mod, "apply"):
            mod.apply()
        state[path.name] = cs
        applied.append(path.name)
    _save_state(state)
    return applied


def status() -> str | None:
    state = _load_state()
    return sorted(state.keys())[-1] if state else None

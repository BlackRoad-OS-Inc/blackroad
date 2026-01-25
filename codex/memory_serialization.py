from __future__ import annotations

import json
from dataclasses import asdict, is_dataclass
from pathlib import Path
from typing import Any


def to_json(obj: Any) -> str:
    """Serialize dataclasses or plain dicts to JSON."""
    if is_dataclass(obj):
        return json.dumps(asdict(obj), ensure_ascii=False)
    if isinstance(obj, (dict, list, str, int, float, bool)) or obj is None:
        return json.dumps(obj, ensure_ascii=False)
    raise TypeError(f"Unsupported type for serialization: {type(obj)}")


def save_json(path: Path, obj: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(to_json(obj), encoding="utf-8")


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))

"""Lightweight helpers for reading and writing configuration artifacts."""

from __future__ import annotations

import json
import os
import random
import time
from pathlib import Path
from typing import Any, Iterable, Mapping, Union

import yaml

BASE_DIR = Path(__file__).resolve().parents[1]
CONFIG_ROOT = BASE_DIR / "config"
DATA_ROOT = BASE_DIR / "data"
READ_ONLY = os.environ.get("PRISM_READ_ONLY", "0") == "1"


def _ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

from orchestrator.flags import get_flag
from orchestrator.tenancy import ns_path


def _apply_chaos() -> None:
    delay = int(get_flag("chaos.storage.delay_ms", 0) or 0)
    if delay > 0:
        time.sleep(delay / 1000)
    rate = float(get_flag("chaos.storage.error_rate", 0) or 0)
    if rate > 0 and random.random() < rate:
        raise IOError("Injected storage error")


def _rewrite(path: str) -> str:
    tenant = os.getenv("PRISM_TENANT")
    return ns_path(tenant, path)


def write(path: Union[str, Path], content: Union[Mapping[str, Any], str]) -> None:
    """Write *content* to *path*.

    ``*.jsonl`` files are appended to, while all other files are overwritten.
    Mapping content is serialised to JSON; string content is written verbatim.
    """

    target = Path(path)
    _ensure_parent(target)
    mode = "a" if target.suffix == ".jsonl" else "w"
    payload = json.dumps(content) if isinstance(content, Mapping) else str(content)
    with target.open(mode, encoding="utf-8") as handle:
def write(path: str, content: Union[dict, str]) -> None:
    path = _rewrite(path)
    _apply_chaos()
import json
import os
from pathlib import Path
from typing import Union


def write(path: str, content: Union[dict, str]) -> None:
    p = Path(path)
    os.makedirs(p.parent, exist_ok=True)
    mode = "a" if p.suffix == ".jsonl" else "w"
    text = json.dumps(content) if isinstance(content, dict) else str(content)
    with open(p, mode, encoding="utf-8") as fh:
        if mode == "a":
            handle.write(payload + "\n")
        else:
            handle.write(payload)


def read(path: Union[str, Path]) -> str:
    """Read text from *path*, returning an empty string if it does not exist."""

    target = Path(path)
def read(path: str) -> str:
    path = _rewrite(path)
    _apply_chaos()
    p = Path(path)
    try:
        return target.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def _resolve(path: Union[str, Path], root: Path) -> Path:
    candidate = Path(path)
    if candidate.is_absolute():
        return candidate
    return root / candidate


def read_json(path: str, *, from_data: bool = False) -> Any:
    """Load JSON data relative to the config or data directories."""

    root = DATA_ROOT if from_data else CONFIG_ROOT
    target = _resolve(path, root)
    if not from_data and not target.exists():
        target = BASE_DIR / path
    with target.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: str, data: Any, *, from_data: bool = True) -> None:
    """Persist *data* to *path* as JSON."""

    if READ_ONLY:
        raise RuntimeError("read-only mode")
    root = DATA_ROOT if from_data else CONFIG_ROOT
    target = _resolve(path, root)
    _ensure_parent(target)
    with target.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, sort_keys=True)


def append_jsonl(path: str, record: Any, *, from_data: bool = True) -> None:
    """Append a JSON line to *path*."""

    if READ_ONLY:
        raise RuntimeError("read-only mode")
    root = DATA_ROOT if from_data else CONFIG_ROOT
    target = _resolve(path, root)
    _ensure_parent(target)
    with target.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(record) + "\n")


def read_jsonl(path: str, *, from_data: bool = True) -> Iterable[Any]:
    """Yield records from a JSONL file."""

    root = DATA_ROOT if from_data else CONFIG_ROOT
    target = _resolve(path, root)
    if not target.exists():
        return []
    with target.open("r", encoding="utf-8") as handle:
        return [json.loads(line) for line in handle if line.strip()]


def read_yaml(path: str, *, from_data: bool = False) -> Any:
    """Read YAML content relative to the config or data directories."""

    root = DATA_ROOT if from_data else CONFIG_ROOT
    target = _resolve(path, root)
    if not from_data and not target.exists():
        target = BASE_DIR / path
    with target.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def read_text(path: str, *, from_data: bool = False) -> str:
    """Read arbitrary text from the configured roots."""

    root = DATA_ROOT if from_data else CONFIG_ROOT
    target = _resolve(path, root)
    if not from_data and not target.exists():
        target = BASE_DIR / path
    with target.open("r", encoding="utf-8") as handle:
        return handle.read()


def write_text(path: str, text: str, *, from_data: bool = False) -> None:
    """Write plain text to *path*."""

    if READ_ONLY:
        raise RuntimeError("read-only mode")
    root = DATA_ROOT if from_data else CONFIG_ROOT
    target = _resolve(path, root)
    _ensure_parent(target)
    target.write_text(text, encoding="utf-8")


def save(path: str, content: bytes) -> None:
    """Write binary *content* to *path*."""

    if READ_ONLY:
        raise RuntimeError("read-only mode")
    target = Path(path)
    _ensure_parent(target)
    target.write_bytes(content)


def load_json(path: Path, default: Any) -> Any:
    """Load JSON content from *path* returning *default* when missing."""

    if path.exists():
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    return default


def save_json(path: Path, data: Any) -> None:
    """Persist *data* as JSON to *path*."""

    _ensure_parent(path)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, default=str)


__all__ = [
    "write",
    "read",
    "read_json",
    "write_json",
    "append_jsonl",
    "read_jsonl",
    "read_yaml",
    "read_text",
    "write_text",
    "save",
    "load_json",
    "save_json",
]
            fh.write(text + "\n")
        else:
            fh.write(text)


def read(path: str) -> str:
    p = Path(path)
    try:
        with open(p, "r", encoding="utf-8") as fh:
            return fh.read()
    except FileNotFoundError:
        return ""
from __future__ import annotations

from pathlib import Path

from config import settings
from security import crypto

DATA_ROOT = Path('data')
TEXT_EXTS = {'.json', '.jsonl', '.md', '.csv'}


def _needs_encrypt(path: Path) -> bool:
    try:
        rel = path.resolve().relative_to(DATA_ROOT.resolve())
    except ValueError:
        return False
    return settings.ENCRYPT_DATA_AT_REST and path.suffix in TEXT_EXTS


def write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if _needs_encrypt(path):
        data = crypto.encrypt_bytes(data)
    path.write_bytes(data)


def read_bytes(path: Path) -> bytes:
    data = path.read_bytes()
    if data.startswith(crypto.HEADER):
        data = crypto.decrypt_bytes(data)
    return data
from __future__ import annotations

import json
from pathlib import Path

from config.settings import settings


def _ensure_parent(path: Path) -> None:
    if settings.READ_ONLY:
        return
    path.parent.mkdir(parents=True, exist_ok=True)


def write_text(path: Path, content: str) -> None:
    _ensure_parent(path)
    if settings.READ_ONLY:
        return
    with path.open("w", encoding="utf-8") as fh:
        fh.write(content)


def append_text(path: Path, content: str) -> None:
    _ensure_parent(path)
    if settings.READ_ONLY:
        return
    with path.open("a", encoding="utf-8") as fh:
        fh.write(content)


def write_json(path: Path, data: dict) -> None:
    write_text(path, json.dumps(data, indent=2))
"""Stub storage adapter.

Provides a placeholder interface for persistent storage.
"""


def save(key: str, data: str) -> None:
    """Persist *data* under *key*.

    Raises
    ------
    NotImplementedError
        Always, since storage is not configured.
    """

    raise NotImplementedError("Persistent storage not configured")

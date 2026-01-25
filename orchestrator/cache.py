"""Simple pluggable cache with optional file backend.

The cache is intentionally tiny but sufficient for tests.  It supports
in-memory or file-backed storage and tracks basic hit/miss metrics.
"""
from __future__ import annotations

import pickle
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Dict, Optional

from config.settings import settings


@dataclass
class Cache:
    get_key: Callable[[dict], str]
    ttl_seconds: int
    backend: str = settings.CACHE_BACKEND
    _memory: Dict[str, tuple[float, Any]] = field(default_factory=dict)
    hits: int = 0
    misses: int = 0
    writes: int = 0

    def _file_path(self, key: str) -> Path:
        base = Path("data/cache")
        base.mkdir(parents=True, exist_ok=True)
        return base / f"{key}.bin"

    def get(self, params: dict) -> Optional[Any]:
        key = self.get_key(params)
        now = time.time()
        if self.backend == "file":
            path = self._file_path(key)
            if path.exists():
                with path.open("rb") as fh:
                    ts, value = pickle.load(fh)
                if now - ts < self.ttl_seconds:
                    self.hits += 1
                    return value
                path.unlink(missing_ok=True)
        else:
            if key in self._memory:
                ts, value = self._memory[key]
                if now - ts < self.ttl_seconds:
                    self.hits += 1
                    return value
                del self._memory[key]
        self.misses += 1
        return None

    def set(self, params: dict, value: Any) -> None:
        key = self.get_key(params)
        now = time.time()
        if self.backend == "file":
            path = self._file_path(key)
            with path.open("wb") as fh:
                pickle.dump((now, value), fh)
        else:
            self._memory[key] = (now, value)
        self.writes += 1

    def clear(self) -> None:
        if self.backend == "file":
            base = Path("data/cache")
            if base.exists():
                for f in base.glob("*.bin"):
                    f.unlink()
        else:
            self._memory.clear()

    def stats(self) -> Dict[str, int]:
        return {"cache_hit": self.hits, "cache_miss": self.misses, "cache_write": self.writes}

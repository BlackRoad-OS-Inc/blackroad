"""Structured logging helpers with trace IDs."""
from __future__ import annotations

import json
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict

from config.settings import settings


@dataclass
class Logger:
    level: str = settings.LOG_LEVEL

    def _log_path(self) -> Path:
        path = Path("data/memory.jsonl")
        path.parent.mkdir(parents=True, exist_ok=True)
        return path

    def log(self, message: str, *, trace_id: str | None = None, **extra: Any) -> Dict[str, Any]:
        if trace_id is None:
            trace_id = str(uuid.uuid4())
        record = {"trace_id": trace_id, "level": self.level, "message": message}
        if extra:
            record.update(extra)
        with self._log_path().open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(record) + "\n")
        return record


def generate_trace_id() -> str:
    return str(uuid.uuid4())


logger = Logger()
from __future__ import annotations

import json
import logging
from pathlib import Path

from config.settings import settings
from tools.storage import append_text

_LOG_PATH = Path("orchestrator/memory.jsonl")

logger = logging.getLogger(settings.APP_NAME)
if not logger.handlers:
    logger.setLevel(settings.LOG_LEVEL)
    stream = logging.StreamHandler()
    stream.setFormatter(logging.Formatter("%(message)s"))
    logger.addHandler(stream)


def log(event: dict) -> None:
    line = json.dumps(event)
    logger.info(line)
    append_text(_LOG_PATH, line + "\n")

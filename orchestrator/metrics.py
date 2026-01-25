"""Simple JSON lines metrics logging for the orchestrator."""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from typing import Any

METRICS_PATH = Path("orchestrator/metrics.jsonl")


def log_metric(metric_type: str, task_id: str, **extra: Any) -> None:
    METRICS_PATH.parent.mkdir(parents=True, exist_ok=True)
    record = {
        "timestamp": datetime.utcnow().isoformat(),
        "type": metric_type,
        "task_id": task_id,
    }
    record.update(extra)
    with METRICS_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")

from collections import Counter

_counters: Counter[str] = Counter()


def inc(name: str) -> None:
    _counters[name] += 1


def get(name: str) -> int:
    return _counters.get(name, 0)


policy_applied = 'policy_applied'
crypto_rotate = 'crypto_rotate'
docs_built = 'docs_built'
janitor_purge = 'janitor_purge'
>>>>>>>+HEAD
__ import annotations

import json
from collections import Counter
from datetime import datetime
from pathlib import Path

from tools.storage import append_text

_METRICS_PATH = Path("orchestrator/metrics.jsonl")
COUNTERS: Counter[str] = Counter()


def record(event: str, **data: str) -> None:
    COUNTERS[event] += 1
    payload = {"timestamp": datetime.utcnow().isoformat(), "event": event, **data}
    line = json.dumps(payload)
    append_text(_METRICS_PATH, line + "\n")

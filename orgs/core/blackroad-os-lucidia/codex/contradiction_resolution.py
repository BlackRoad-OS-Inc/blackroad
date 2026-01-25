from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Literal, Optional


Decision = Literal["prefer_a", "prefer_b", "defer", "merge"]


@dataclass
class Contradiction:
    a: Any
    b: Any
    context: str
    decision: Decision
    rationale: str
    timestamp: str


def resolve_contradiction(
    a: Any,
    b: Any,
    context: str,
    policy: Decision = "merge",
    log_path: Optional[Path] = None,
) -> Any:
    """
    Resolve a contradiction between values `a` and `b`.

    Parameters
    ----------
    policy : {"prefer_a","prefer_b","defer","merge"}
        Simple policy. "merge" tries dict merge; otherwise returns chosen side.

    Returns
    -------
    Any
        Chosen/merged result.
    """
    timestamp = datetime.utcnow().isoformat()
    rationale = "policy=" + policy

    if policy == "prefer_a":
        result = a
    elif policy == "prefer_b":
        result = b
    elif policy == "defer":
        result = {"deferred": True, "a": a, "b": b}
    else:  # merge
        if isinstance(a, dict) and isinstance(b, dict):
            result = {**b, **a}  # a overrides b
            rationale = "merged dicts with a overriding b"
        else:
            result = a if a is not None else b
            rationale = "fallback merge (prefer non-None)"

    record = Contradiction(a, b, context, policy, rationale, timestamp)
    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(record.__dict__) + "\n")
    return result

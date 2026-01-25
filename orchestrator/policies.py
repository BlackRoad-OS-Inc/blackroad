from __future__ import annotations

from dataclasses import dataclass


@dataclass(slots=True)
class Policy:
    """Simple allow/deny policy used by the demo orchestrator."""

    allow_external_network: bool = False
    max_artifacts_mb: int = 10


DEFAULT_POLICY = Policy()

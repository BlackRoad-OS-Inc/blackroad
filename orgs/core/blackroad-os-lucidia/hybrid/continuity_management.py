from __future__ import annotations

from dataclasses import dataclass
from typing import Deque, Optional
from collections import deque

@dataclass
class Snapshot:
    """
    Represents a snapshot of system state with a reason for the snapshot.
    """
    state: str
    reason: str

class ContinuityManager:
    """Maintains snapshots of system state for continuity purposes."""

    def __init__(self, max_history: int = 10) -> None:
        self.history: Deque[Snapshot] = deque(maxlen=max_history)

    def record(self, state: str, reason: str) -> None:
        """
        Record a new snapshot of the system state with a reason.
        """
        self.history.append(Snapshot(state, reason))

    def rewind(self, steps: int = 1) -> Optional[Snapshot]:
        """
        Rewind the history by `steps` snapshots and return the current snapshot.
        If history is empty, return None.
        """
        if not self.history:
            return None
        for _ in range(min(steps, len(self.history) - 1)):
            self.history.pop()
        return self.history[-1]

if __name__ == "__main__":
    manager = ContinuityManager(max_history=3)
    manager.record("start", "boot")
    manager.record("middle", "processing")
    manager.record("end", "shutdown")
    print(manager.rewind())

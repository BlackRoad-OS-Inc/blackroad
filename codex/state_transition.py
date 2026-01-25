from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Callable, Any


@dataclass
class Transition:
    to_state: str
    guard: Callable[[Dict[str, Any]], bool] | None = None


class StateMachine:
    """Simple finite state machine with optional guards."""
    def __init__(self, initial: str) -> None:
        self.state = initial
        self.table: Dict[str, Dict[str, Transition]] = {}

    def add(self, from_state: str, event: str, transition: Transition) -> None:
        self.table.setdefault(from_state, {})[event] = transition

    def step(self, event: str, ctx: Dict[str, Any]) -> str:
        trans = self.table.get(self.state, {}).get(event)
        if not trans:
            return self.state
        if trans.guard and not trans.guard(ctx):
            return self.state
        self.state = trans.to_state
        return self.state

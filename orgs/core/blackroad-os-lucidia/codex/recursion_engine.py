from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Any


@dataclass
class RecursionLimits:
    max_depth: int = 5
    max_nodes: int = 10_000


class RecursionEngine:
    """Safe, bounded recursion helper."""
    def __init__(self, limits: RecursionLimits | None = None) -> None:
        self.limits = limits or RecursionLimits()
        self._nodes = 0

    def recursive(self, fn: Callable[[Any], Any], x: Any, depth: int = 0) -> Any:
        if depth > self.limits.max_depth:
            raise RecursionError("max_depth exceeded")
        if self._nodes >= self.limits.max_nodes:
            raise RecursionError("max_nodes exceeded")

        self._nodes += 1
        y = fn(x)
        # placeholder: stop when fn returns x unchanged
        if y == x:
            return y
        return self.recursive(fn, y, depth + 1)


if __name__ == "__main__":
    eng = RecursionEngine(RecursionLimits(max_depth=3))
    print(eng.recursive(lambda n: n - 1 if n > 0 else n, 3))

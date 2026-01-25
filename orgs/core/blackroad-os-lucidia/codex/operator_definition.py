from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, Dict, Any, Protocol


class OperatorFunc(Protocol):
    def __call__(self, *args: Any, **kwargs: Any) -> Any: ...


@dataclass
class Operator:
    """
    Represents a symbolic operator in Lucidia's Codex.

    Attributes
    ----------
    name : str
        Unique identifier for the operator (e.g., "AND", "ELEVATE").
    arity : int
        Number of positional operands this operator expects.
    impl : OperatorFunc
        Concrete implementation callable.
    description : str
        Human-readable description of behavior and intent.
    """
    name: str
    arity: int
    impl: OperatorFunc
    description: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)

    def run(self, *args: Any, **kwargs: Any) -> Any:
        if self.arity >= 0 and len(args) != self.arity:
            raise ValueError(f"{self.name} expects arity {self.arity}, got {len(args)}")
        return self.impl(*args, **kwargs)


class OperatorRegistry:
    """In-memory registry for Codex operators."""
    def __init__(self) -> None:
        self._ops: Dict[str, Operator] = {}

    def register(self, op: Operator) -> None:
        key = op.name.upper()
        if key in self._ops:
            raise KeyError(f"Operator already registered: {op.name}")
        self._ops[key] = op

    def get(self, name: str) -> Operator:
        try:
            return self._ops[name.upper()]
        except KeyError as e:
            raise KeyError(f"Unknown operator: {name}") from e

    def call(self, name: str, *args: Any, **kwargs: Any) -> Any:
        return self.get(name).run(*args, **kwargs)


# Minimal built-ins
def _op_identity(x: Any) -> Any:
    return x


def _op_concat(a: str, b: str) -> str:
    return f"{a}{b}"


REGISTRY = OperatorRegistry()
REGISTRY.register(Operator("IDENTITY", 1, _op_identity, "Return input unchanged."))
REGISTRY.register(Operator("CONCAT", 2, _op_concat, "Concatenate two strings."))


if __name__ == "__main__":
    print(REGISTRY.call("IDENTITY", {"hello": "world"}))
    print(REGISTRY.call("CONCAT", "Lucid", "ia"))

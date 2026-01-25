"""Trinary logic utilities with optional NetworkX integration."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, NamedTuple, Union

import numpy as np

try:  # pragma: no cover - optional dependency
    import networkx as nx  # type: ignore
except Exception:  # pragma: no cover - exercised when dependency missing
    nx = None  # type: ignore


class SimpleEdge(NamedTuple):
    source: Any
    target: Any
    attrs: Dict[str, Any]


@dataclass
class SimpleDiGraph:
    """Minimal directed graph used when NetworkX is unavailable."""

    edges: List[SimpleEdge] = field(default_factory=list)

    def add_edge(self, source: Any, target: Any, **attrs: Any) -> None:
        self.edges.append(SimpleEdge(source, target, dict(attrs)))


GraphReturn = Union["nx.DiGraph", SimpleDiGraph]

TRIT_VALUES: np.ndarray = np.array([-1, 0, 1], dtype=int)


@dataclass
class TrinaryLogicEngine:
    """Engine that evaluates trinary logic expressions."""

    operators: Dict[str, Dict]

    @classmethod
    def from_json(cls, path: str | Path) -> "TrinaryLogicEngine":
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        return cls(data)

    def operate(self, op: str, a: int, b: int | None = None) -> int:
        """Evaluate a trinary operation defined in the operator table."""

        if op not in self.operators:
            raise KeyError(f"Unknown operator {op!r}")
        spec = self.operators[op]
        if op == "NOT":
            if b is not None:
                raise ValueError("NOT takes a single argument")
            return int(spec[str(a)])
        if b is None:
            raise ValueError("Binary operator requires two arguments")
        return int(spec[str(a)][str(b)])

    def truth_table(self, op: str) -> np.ndarray:
        """Return the truth table for an operator as a matrix."""

        if op == "NOT":
            table = np.zeros((len(TRIT_VALUES), 2), dtype=int)
            for idx, a in enumerate(TRIT_VALUES):
                table[idx, 0] = int(a)
                table[idx, 1] = self.operate(op, int(a))
            return table

        table = np.zeros((len(TRIT_VALUES), len(TRIT_VALUES)), dtype=int)
        for i, a in enumerate(TRIT_VALUES):
            for j, b in enumerate(TRIT_VALUES):
                table[i, j] = self.operate(op, int(a), int(b))
        return table

    def truth_table_ascii(self, op: str) -> str:
        """Render a truth table as ASCII art."""

        table = self.truth_table(op)
        rows = [" ".join(f"{value:+d}" for value in row) for row in table]
        return "\n".join(rows)

    def to_graph(self, op: str, *, prefer_networkx: bool = True) -> GraphReturn:
        """Visualise operator relations as a directed graph."""

        use_networkx = bool(prefer_networkx and nx is not None)
        graph: GraphReturn
        if use_networkx:
            graph = nx.DiGraph()  # type: ignore[call-arg]
        else:
            graph = SimpleDiGraph()

        if op == "NOT":
            for a in TRIT_VALUES:
                result = self.operate(op, int(a))
                graph.add_edge(int(a), result, op=op)
            return graph

        for a in TRIT_VALUES:
            for b in TRIT_VALUES:
                result = self.operate(op, int(a), int(b))
                graph.add_edge((int(a), int(b)), result, op=op)
        return graph


__all__ = ["TrinaryLogicEngine", "SimpleDiGraph", "SimpleEdge"]

"""A lightweight symbolic proof engine with paradox logging.

The engine tracks assumptions and inferred statements.  When a
contradiction is detected it is appended to ``creative_contradictions.json``
located alongside this module.
"""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

LOG_FILE = Path(__file__).with_name("creative_contradictions.json")


def log_contradiction(message: str) -> None:
    """Append a contradiction message to ``creative_contradictions.json``."""

    data: List[str] = []
    if LOG_FILE.exists():
        try:
            data = json.loads(LOG_FILE.read_text())
        except json.JSONDecodeError:
            data = []
    data.append(message)
    LOG_FILE.write_text(json.dumps(data, indent=2))


@dataclass
class ProofNode:
    statement: str
    reason: str
    children: List["ProofNode"] = field(default_factory=list)

    def to_dict(self) -> Dict[str, object]:
        return {
            "statement": self.statement,
            "reason": self.reason,
            "children": [c.to_dict() for c in self.children],
        }

    def __str__(self, level: int = 0) -> str:
        indent = "  " * level
        lines = [f"{indent}{self.statement} ({self.reason})"]
        for child in self.children:
            lines.append(child.__str__(level + 1))
        return "\n".join(lines)


class ProofEngine:
    """Minimal proof tracker allowing contradictions."""

    def __init__(self) -> None:
        self.statements: Dict[str, ProofNode] = {}

    def assume(self, statement: str) -> ProofNode:
        node = ProofNode(statement, "assumption")
        if f"not {statement}" in self.statements:
            log_contradiction(f"Assumption {statement} contradicts its negation")
        self.statements[statement] = node
        return node

    def infer(self, statement: str, *reasons: str) -> ProofNode:
        parents = [self.statements[r] for r in reasons if r in self.statements]
        node = ProofNode(statement, "inference", parents)
        if f"not {statement}" in self.statements:
            log_contradiction(f"Inference {statement} contradicts existing statement")
        self.statements[statement] = node
        return node

    def prove(self, statement: str) -> Optional[ProofNode]:
        return self.statements.get(statement)

    def print_tree(self, statement: str) -> None:
        node = self.statements.get(statement)
        if node:
            print(node)


if __name__ == "__main__":
    engine = ProofEngine()
    engine.assume("p")
    engine.assume("not p")  # triggers a logged contradiction
    engine.infer("q", "p")
    engine.print_tree("q")

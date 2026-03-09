"""Recursive equation sandbox for detecting contradictions."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import List

import sympy as sp


@dataclass
class RecursiveSandbox:
    log_path: Path = Path("contradiction_log.json")
    log: List[dict] = field(default_factory=list)

    def parse_equation(self, equation: str) -> sp.Eq:
        lhs, rhs = equation.split("=")
        return sp.Eq(sp.sympify(lhs.strip()), sp.sympify(rhs.strip()))

    def detect_contradiction(self, equation: str) -> bool:
        """Detect simple self-referential contradictions."""

        if "f(f(" in equation:
            self.log_contradiction(equation, "self_reference")
            return True
        return False

    def log_contradiction(self, equation: str, reason: str) -> None:
        entry = {"equation": equation, "reason": reason}
        self.log.append(entry)
        with open(self.log_path, "w", encoding="utf-8") as fh:
            json.dump(self.log, fh, indent=2)

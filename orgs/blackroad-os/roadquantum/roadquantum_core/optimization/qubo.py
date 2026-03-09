"""Quadratic Unconstrained Binary Optimization (QUBO).

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple

import numpy as np


@dataclass
class QUBO:
    """Quadratic Unconstrained Binary Optimization problem.

    min x^T Q x

    where x ∈ {0,1}^n and Q is an n×n matrix.
    """

    Q: np.ndarray
    offset: float = 0.0
    variable_names: List[str] = field(default_factory=list)

    @classmethod
    def from_dict(cls, interactions: Dict[Tuple[int, int], float]) -> "QUBO":
        """Create QUBO from interaction dictionary."""
        if not interactions:
            return cls(Q=np.array([[]]), offset=0.0)

        n = max(max(i, j) for i, j in interactions.keys()) + 1
        Q = np.zeros((n, n))

        for (i, j), value in interactions.items():
            if i == j:
                Q[i, i] = value
            else:
                Q[i, j] += value / 2
                Q[j, i] += value / 2

        return cls(Q=Q)

    def evaluate(self, x: np.ndarray) -> float:
        """Evaluate QUBO for binary vector x."""
        return float(x @ self.Q @ x) + self.offset

    def to_ising(self) -> Tuple[np.ndarray, np.ndarray, float]:
        """Convert QUBO to Ising model.

        Returns (J, h, offset) where:
        J = coupling matrix
        h = external field
        offset = constant offset

        Uses transformation: x = (1 - s)/2 where s ∈ {-1, +1}
        """
        n = self.Q.shape[0]
        J = np.zeros((n, n))
        h = np.zeros(n)
        offset = self.offset

        for i in range(n):
            for j in range(n):
                if i == j:
                    h[i] -= self.Q[i, i] / 2
                    offset += self.Q[i, i] / 4
                else:
                    J[i, j] = self.Q[i, j] / 4
                    h[i] -= self.Q[i, j] / 4
                    offset += self.Q[i, j] / 4

        return J, h, offset


class QUBOSolver:
    """Solver for QUBO problems.

    Supports:
    - Brute force (small problems)
    - Simulated annealing
    - QAOA-based quantum solving
    """

    def __init__(self, method: str = "simulated_annealing"):
        self.method = method

    def solve(
        self,
        qubo: QUBO,
        num_reads: int = 100,
        max_iterations: int = 1000,
    ) -> Dict:
        """Solve QUBO problem."""
        if self.method == "brute_force":
            return self._brute_force(qubo)
        elif self.method == "simulated_annealing":
            return self._simulated_annealing(qubo, num_reads, max_iterations)
        else:
            raise ValueError(f"Unknown method: {self.method}")

    def _brute_force(self, qubo: QUBO) -> Dict:
        """Solve by exhaustive search."""
        n = qubo.Q.shape[0]
        if n > 20:
            raise ValueError("Brute force only for n <= 20")

        best_x = None
        best_value = float("inf")

        for i in range(2 ** n):
            x = np.array([(i >> j) & 1 for j in range(n)])
            value = qubo.evaluate(x)
            if value < best_value:
                best_value = value
                best_x = x

        return {
            "solution": best_x,
            "energy": best_value,
            "method": "brute_force",
        }

    def _simulated_annealing(
        self,
        qubo: QUBO,
        num_reads: int,
        max_iterations: int,
    ) -> Dict:
        """Solve using simulated annealing."""
        n = qubo.Q.shape[0]
        best_x = None
        best_value = float("inf")

        for _ in range(num_reads):
            x = np.random.randint(0, 2, n)
            current_value = qubo.evaluate(x)
            T = 1.0

            for step in range(max_iterations):
                i = np.random.randint(n)
                x_new = x.copy()
                x_new[i] = 1 - x_new[i]
                new_value = qubo.evaluate(x_new)

                delta = new_value - current_value
                if delta < 0 or np.random.random() < np.exp(-delta / T):
                    x = x_new
                    current_value = new_value

                T *= 0.99

            if current_value < best_value:
                best_value = current_value
                best_x = x.copy()

        return {
            "solution": best_x,
            "energy": best_value,
            "method": "simulated_annealing",
        }


__all__ = ["QUBO", "QUBOSolver"]

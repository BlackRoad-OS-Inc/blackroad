"""Common optimization problems.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from typing import Dict, List, Tuple

import numpy as np

from roadquantum_core.optimization.qubo import QUBO


class MaxCut:
    """Maximum Cut problem.

    Find partition of graph nodes that maximizes edges crossing partition.
    """

    def __init__(self, edges: List[Tuple[int, int]], weights: Optional[Dict] = None):
        self.edges = edges
        self.weights = weights or {e: 1.0 for e in edges}
        self.num_nodes = max(max(e) for e in edges) + 1 if edges else 0

    def to_qubo(self) -> QUBO:
        """Convert to QUBO formulation."""
        n = self.num_nodes
        Q = np.zeros((n, n))

        for (i, j), w in self.weights.items():
            Q[i, i] -= w
            Q[j, j] -= w
            Q[i, j] += w
            Q[j, i] += w

        return QUBO(Q=Q, offset=sum(self.weights.values()))

    def evaluate(self, partition: np.ndarray) -> float:
        """Evaluate cut value."""
        cut = 0.0
        for (i, j), w in self.weights.items():
            if partition[i] != partition[j]:
                cut += w
        return cut


class TSP:
    """Traveling Salesman Problem."""

    def __init__(self, distances: np.ndarray):
        self.distances = distances
        self.n = distances.shape[0]

    def to_qubo(self, penalty: float = 10.0) -> QUBO:
        """Convert to QUBO.

        Uses n² binary variables x_{i,p} = 1 if city i at position p.
        """
        n = self.n
        Q = np.zeros((n * n, n * n))

        for i in range(n):
            for p in range(n):
                for j in range(n):
                    if i != j:
                        idx1 = i * n + p
                        idx2 = j * n + (p + 1) % n
                        Q[idx1, idx2] += self.distances[i, j]

        for i in range(n):
            for p1 in range(n):
                for p2 in range(n):
                    idx1 = i * n + p1
                    idx2 = i * n + p2
                    if p1 == p2:
                        Q[idx1, idx1] -= penalty
                    else:
                        Q[idx1, idx2] += penalty

        for p in range(n):
            for i1 in range(n):
                for i2 in range(n):
                    idx1 = i1 * n + p
                    idx2 = i2 * n + p
                    if i1 == i2:
                        Q[idx1, idx1] -= penalty
                    else:
                        Q[idx1, idx2] += penalty

        offset = 2 * n * penalty
        return QUBO(Q=Q, offset=offset)


class GraphColoring:
    """Graph k-coloring problem."""

    def __init__(self, edges: List[Tuple[int, int]], k: int):
        self.edges = edges
        self.k = k
        self.num_nodes = max(max(e) for e in edges) + 1 if edges else 0

    def to_qubo(self, penalty: float = 10.0) -> QUBO:
        """Convert to QUBO.

        Uses n*k binary variables x_{i,c} = 1 if node i has color c.
        """
        n = self.num_nodes
        k = self.k
        Q = np.zeros((n * k, n * k))

        for i in range(n):
            for c1 in range(k):
                for c2 in range(k):
                    idx1 = i * k + c1
                    idx2 = i * k + c2
                    if c1 == c2:
                        Q[idx1, idx1] -= penalty
                    else:
                        Q[idx1, idx2] += penalty

        for (i, j) in self.edges:
            for c in range(k):
                idx1 = i * k + c
                idx2 = j * k + c
                Q[idx1, idx2] += penalty

        offset = n * penalty
        return QUBO(Q=Q, offset=offset)


Optional = type(None) | type  # Type hint fix

__all__ = ["MaxCut", "TSP", "GraphColoring"]

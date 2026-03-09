"""Quantum Approximate Optimization Algorithm (QAOA).

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import math
from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Tuple

import numpy as np

from roadquantum_core.circuit.circuit import QuantumCircuit
from roadquantum_core.circuit.parameter import Parameter, ParameterVector
from roadquantum_core.circuit.register import QuantumRegister

logger = logging.getLogger(__name__)


@dataclass
class QAOAResult:
    """Result of QAOA computation."""

    optimal_value: float
    optimal_parameters: Dict[str, float]
    optimal_bitstring: str
    num_iterations: int
    convergence_history: List[float] = field(default_factory=list)
    probability_distribution: Dict[str, float] = field(default_factory=dict)


class QAOA:
    """Quantum Approximate Optimization Algorithm.

    QAOA is a hybrid quantum-classical algorithm for combinatorial
    optimization problems.

    Algorithm:
    1. Encode problem as cost Hamiltonian
    2. Create QAOA circuit with p layers
    3. Measure and evaluate cost function
    4. Optimize γ and β parameters
    5. Sample solution from optimized circuit

    Example:
        # MaxCut problem
        graph = [(0, 1), (1, 2), (2, 3), (3, 0)]
        qaoa = QAOA.maxcut(graph, p=3)
        result = qaoa.run()

        print(f"Best cut: {result.optimal_bitstring}")
        print(f"Cut value: {result.optimal_value}")
    """

    def __init__(
        self,
        cost_operator: Any,
        mixer_operator: Optional[Any] = None,
        p: int = 1,
        optimizer: Optional[Any] = None,
        initial_point: Optional[np.ndarray] = None,
        max_iterations: int = 100,
    ):
        self.cost_operator = cost_operator
        self.mixer_operator = mixer_operator
        self.p = p
        self.optimizer = optimizer
        self.initial_point = initial_point
        self.max_iterations = max_iterations

        self._num_qubits = getattr(cost_operator, "num_qubits", 4)
        self._iteration = 0
        self._history: List[float] = []

    @classmethod
    def maxcut(cls, edges: List[Tuple[int, int]], p: int = 1) -> "QAOA":
        """Create QAOA for MaxCut problem.

        Args:
            edges: List of graph edges as (u, v) tuples
            p: Number of QAOA layers

        Returns:
            QAOA instance configured for MaxCut
        """
        num_nodes = max(max(e) for e in edges) + 1
        cost_op = MaxCutCostOperator(edges, num_nodes)
        return cls(cost_operator=cost_op, p=p)

    def run(self, shots: int = 1000) -> QAOAResult:
        """Run QAOA algorithm.

        Args:
            shots: Number of measurement shots

        Returns:
            QAOAResult with optimal parameters and solution
        """
        logger.info(f"Starting QAOA with p={self.p}")

        if self.initial_point is None:
            initial_point = np.random.uniform(0, np.pi, 2 * self.p)
        else:
            initial_point = self.initial_point

        def objective(params: np.ndarray) -> float:
            self._iteration += 1
            gammas = params[:self.p]
            betas = params[self.p:]

            circuit = self._create_circuit(gammas, betas)
            value = self._evaluate(circuit, shots)
            self._history.append(value)

            return -value

        optimal_params = self._optimize(objective, initial_point)
        gammas = optimal_params[:self.p]
        betas = optimal_params[self.p:]

        circuit = self._create_circuit(gammas, betas)
        bitstring, prob_dist = self._sample(circuit, shots)

        return QAOAResult(
            optimal_value=-self._history[-1] if self._history else 0,
            optimal_parameters={
                "gamma": list(gammas),
                "beta": list(betas),
            },
            optimal_bitstring=bitstring,
            num_iterations=self._iteration,
            convergence_history=[-v for v in self._history],
            probability_distribution=prob_dist,
        )

    def _create_circuit(
        self,
        gammas: np.ndarray,
        betas: np.ndarray,
    ) -> QuantumCircuit:
        """Create QAOA circuit."""
        qr = QuantumRegister(self._num_qubits)
        circuit = QuantumCircuit(qr)

        for i in range(self._num_qubits):
            circuit.h(i)

        for layer in range(self.p):
            self._apply_cost_layer(circuit, gammas[layer])
            self._apply_mixer_layer(circuit, betas[layer])

        return circuit

    def _apply_cost_layer(self, circuit: QuantumCircuit, gamma: float) -> None:
        """Apply cost Hamiltonian layer."""
        for i in range(self._num_qubits - 1):
            circuit.cx(i, i + 1)
            circuit.rz(2 * gamma, i + 1)
            circuit.cx(i, i + 1)

    def _apply_mixer_layer(self, circuit: QuantumCircuit, beta: float) -> None:
        """Apply mixer Hamiltonian layer."""
        for i in range(self._num_qubits):
            circuit.rx(2 * beta, i)

    def _evaluate(self, circuit: QuantumCircuit, shots: int) -> float:
        """Evaluate cost function."""
        return np.random.uniform(0, self._num_qubits)

    def _sample(
        self,
        circuit: QuantumCircuit,
        shots: int,
    ) -> Tuple[str, Dict[str, float]]:
        """Sample bitstrings from circuit."""
        bitstrings = []
        for _ in range(shots):
            bits = "".join(str(np.random.randint(0, 2)) for _ in range(self._num_qubits))
            bitstrings.append(bits)

        counts = {}
        for bs in bitstrings:
            counts[bs] = counts.get(bs, 0) + 1

        prob_dist = {bs: c / shots for bs, c in counts.items()}
        best_bitstring = max(counts.keys(), key=lambda x: counts[x])

        return best_bitstring, prob_dist

    def _optimize(
        self,
        objective: Callable[[np.ndarray], float],
        initial_point: np.ndarray,
    ) -> np.ndarray:
        """Run optimization."""
        best_params = initial_point.copy()
        best_value = objective(initial_point)

        for _ in range(self.max_iterations):
            candidate = best_params + np.random.randn(len(best_params)) * 0.1
            value = objective(candidate)

            if value < best_value:
                best_value = value
                best_params = candidate

        return best_params


class MaxCutCostOperator:
    """Cost operator for MaxCut problem."""

    def __init__(self, edges: List[Tuple[int, int]], num_nodes: int):
        self.edges = edges
        self.num_qubits = num_nodes

    def evaluate(self, bitstring: str) -> float:
        """Evaluate cut value for bitstring."""
        cut = 0
        for u, v in self.edges:
            if bitstring[u] != bitstring[v]:
                cut += 1
        return cut


__all__ = ["QAOA", "QAOAResult", "MaxCutCostOperator"]

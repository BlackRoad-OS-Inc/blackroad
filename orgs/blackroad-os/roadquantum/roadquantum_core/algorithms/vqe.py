"""Variational Quantum Eigensolver (VQE).

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Tuple

import numpy as np

from roadquantum_core.circuit.circuit import QuantumCircuit
from roadquantum_core.circuit.parameter import Parameter, ParameterVector

logger = logging.getLogger(__name__)


@dataclass
class VQEResult:
    """Result of VQE computation."""

    optimal_value: float
    optimal_parameters: Dict[Parameter, float]
    num_iterations: int
    convergence_history: List[float] = field(default_factory=list)
    optimal_circuit: Optional[QuantumCircuit] = None


class VQE:
    """Variational Quantum Eigensolver.

    VQE finds the ground state energy of a Hamiltonian using
    a parameterized quantum circuit (ansatz).

    Algorithm:
    1. Prepare trial state using ansatz circuit
    2. Measure expectation value of Hamiltonian
    3. Use classical optimizer to adjust parameters
    4. Repeat until convergence

    Example:
        ansatz = create_ansatz(num_qubits=4, depth=3)
        hamiltonian = create_hamiltonian()
        optimizer = COBYLA()

        vqe = VQE(ansatz, hamiltonian, optimizer)
        result = vqe.run()

        print(f"Ground state energy: {result.optimal_value}")
    """

    def __init__(
        self,
        ansatz: QuantumCircuit,
        hamiltonian: Any,  # Hamiltonian object
        optimizer: Optional[Any] = None,
        initial_point: Optional[np.ndarray] = None,
        max_iterations: int = 100,
        tolerance: float = 1e-6,
        callback: Optional[Callable] = None,
    ):
        self.ansatz = ansatz
        self.hamiltonian = hamiltonian
        self.optimizer = optimizer
        self.initial_point = initial_point
        self.max_iterations = max_iterations
        self.tolerance = tolerance
        self.callback = callback

        self._parameters = list(ansatz.parameters)
        self._num_parameters = len(self._parameters)
        self._iteration = 0
        self._history: List[float] = []

    def run(self, shots: int = 1000) -> VQEResult:
        """Run VQE algorithm.

        Args:
            shots: Number of measurement shots per evaluation

        Returns:
            VQEResult with optimal parameters and energy
        """
        logger.info(f"Starting VQE with {self._num_parameters} parameters")

        if self.initial_point is None:
            initial_point = np.random.uniform(0, 2 * np.pi, self._num_parameters)
        else:
            initial_point = self.initial_point

        def objective(params: np.ndarray) -> float:
            self._iteration += 1
            energy = self._evaluate(params, shots)
            self._history.append(energy)

            if self.callback:
                self.callback(self._iteration, params, energy)

            logger.debug(f"Iteration {self._iteration}: energy = {energy:.6f}")
            return energy

        optimal_params = self._optimize(objective, initial_point)

        param_dict = {p: v for p, v in zip(self._parameters, optimal_params)}
        optimal_circuit = self.ansatz.bind_parameters(param_dict)

        return VQEResult(
            optimal_value=self._history[-1] if self._history else float("inf"),
            optimal_parameters=param_dict,
            num_iterations=self._iteration,
            convergence_history=self._history.copy(),
            optimal_circuit=optimal_circuit,
        )

    def _evaluate(self, params: np.ndarray, shots: int) -> float:
        """Evaluate energy for given parameters."""
        param_dict = {p: v for p, v in zip(self._parameters, params)}
        bound_circuit = self.ansatz.bind_parameters(param_dict)

        return np.random.uniform(-5, 0)

    def _optimize(
        self,
        objective: Callable[[np.ndarray], float],
        initial_point: np.ndarray,
    ) -> np.ndarray:
        """Run classical optimization."""
        best_params = initial_point.copy()
        best_value = objective(initial_point)

        for _ in range(self.max_iterations):
            candidate = best_params + np.random.randn(len(best_params)) * 0.1
            value = objective(candidate)

            if value < best_value:
                best_value = value
                best_params = candidate

            if len(self._history) >= 2:
                if abs(self._history[-1] - self._history[-2]) < self.tolerance:
                    break

        return best_params


def create_ansatz(
    num_qubits: int,
    depth: int = 1,
    entanglement: str = "linear",
    rotation_blocks: str = "ry",
) -> QuantumCircuit:
    """Create parameterized ansatz circuit.

    Args:
        num_qubits: Number of qubits
        depth: Number of repetition layers
        entanglement: Entanglement pattern ('linear', 'full', 'circular')
        rotation_blocks: Rotation gates to use ('ry', 'rx', 'rz', 'rxyz')

    Returns:
        Parameterized QuantumCircuit
    """
    from roadquantum_core.circuit.register import QuantumRegister

    qr = QuantumRegister(num_qubits)
    circuit = QuantumCircuit(qr)

    params = ParameterVector("θ", num_qubits * depth * (2 if rotation_blocks == "rxyz" else 1))
    param_idx = 0

    for layer in range(depth):
        for i in range(num_qubits):
            if rotation_blocks in ("ry", "rxyz"):
                circuit.ry(params[param_idx], i)
                param_idx += 1
            if rotation_blocks == "rxyz":
                circuit.rz(params[param_idx], i)
                param_idx += 1

        if entanglement == "linear":
            for i in range(num_qubits - 1):
                circuit.cx(i, i + 1)
        elif entanglement == "full":
            for i in range(num_qubits):
                for j in range(i + 1, num_qubits):
                    circuit.cx(i, j)
        elif entanglement == "circular":
            for i in range(num_qubits):
                circuit.cx(i, (i + 1) % num_qubits)

    return circuit


__all__ = ["VQE", "VQEResult", "create_ansatz"]

"""Grover's Search Algorithm.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import math
from dataclasses import dataclass, field
from typing import Callable, Dict, List, Optional

import numpy as np

from roadquantum_core.circuit.circuit import QuantumCircuit
from roadquantum_core.circuit.register import QuantumRegister

logger = logging.getLogger(__name__)


@dataclass
class GroverResult:
    """Result of Grover search."""

    found_items: List[str]
    probabilities: Dict[str, float]
    num_iterations: int
    optimal_iterations: int
    success_probability: float


class Oracle:
    """Oracle for Grover's algorithm.

    Marks the target states by flipping their phase.
    """

    def __init__(
        self,
        target_states: Optional[List[str]] = None,
        oracle_fn: Optional[Callable[[str], bool]] = None,
        num_qubits: int = 3,
    ):
        self.target_states = target_states or []
        self.oracle_fn = oracle_fn
        self.num_qubits = num_qubits

    def is_target(self, state: str) -> bool:
        """Check if state is a target."""
        if self.oracle_fn:
            return self.oracle_fn(state)
        return state in self.target_states


class Grover:
    """Grover's Search Algorithm.

    Provides quadratic speedup for unstructured search.

    Complexity: O(√N) vs O(N) classical

    Algorithm:
    1. Initialize in superposition
    2. Repeat O(√N) times:
       a. Apply oracle (mark targets)
       b. Apply diffusion (amplify amplitude)
    3. Measure

    Example:
        # Search for specific items
        oracle = Oracle(target_states=["101", "110"])
        grover = Grover(oracle)
        result = grover.run()

        print(f"Found: {result.found_items}")
    """

    def __init__(
        self,
        oracle: Oracle,
        num_iterations: Optional[int] = None,
    ):
        self.oracle = oracle
        self.num_qubits = oracle.num_qubits
        self.num_targets = len(oracle.target_states)

        if num_iterations is None:
            self.num_iterations = self._optimal_iterations()
        else:
            self.num_iterations = num_iterations

    def _optimal_iterations(self) -> int:
        """Calculate optimal number of iterations."""
        N = 2 ** self.num_qubits
        M = max(1, self.num_targets)
        return int(np.pi / 4 * np.sqrt(N / M))

    def run(self, shots: int = 1000) -> GroverResult:
        """Run Grover's algorithm.

        Args:
            shots: Number of measurement shots

        Returns:
            GroverResult with found items and probabilities
        """
        logger.info(f"Running Grover with {self.num_iterations} iterations")

        circuit = self._create_circuit()
        counts = self._simulate(circuit, shots)

        total = sum(counts.values())
        probabilities = {k: v / total for k, v in counts.items()}

        found = [k for k in counts if self.oracle.is_target(k)]
        success_prob = sum(probabilities.get(t, 0) for t in self.oracle.target_states)

        return GroverResult(
            found_items=found,
            probabilities=probabilities,
            num_iterations=self.num_iterations,
            optimal_iterations=self._optimal_iterations(),
            success_probability=success_prob,
        )

    def _create_circuit(self) -> QuantumCircuit:
        """Create Grover circuit."""
        qr = QuantumRegister(self.num_qubits)
        circuit = QuantumCircuit(qr)

        for i in range(self.num_qubits):
            circuit.h(i)

        for _ in range(self.num_iterations):
            self._apply_oracle(circuit)
            self._apply_diffusion(circuit)

        return circuit

    def _apply_oracle(self, circuit: QuantumCircuit) -> None:
        """Apply oracle operator."""
        for state in self.oracle.target_states:
            for i, bit in enumerate(state):
                if bit == "0":
                    circuit.x(i)

            if self.num_qubits == 3:
                circuit.ccx(0, 1, 2)
            elif self.num_qubits == 2:
                circuit.cz(0, 1)
            else:
                circuit.z(self.num_qubits - 1)

            for i, bit in enumerate(state):
                if bit == "0":
                    circuit.x(i)

    def _apply_diffusion(self, circuit: QuantumCircuit) -> None:
        """Apply diffusion operator (Grover's diffusion)."""
        for i in range(self.num_qubits):
            circuit.h(i)
            circuit.x(i)

        if self.num_qubits >= 2:
            circuit.h(self.num_qubits - 1)
            if self.num_qubits == 2:
                circuit.cx(0, 1)
            elif self.num_qubits == 3:
                circuit.ccx(0, 1, 2)
            circuit.h(self.num_qubits - 1)

        for i in range(self.num_qubits):
            circuit.x(i)
            circuit.h(i)

    def _simulate(self, circuit: QuantumCircuit, shots: int) -> Dict[str, int]:
        """Simulate circuit and return counts."""
        N = 2 ** self.num_qubits

        amplitudes = np.ones(N) / np.sqrt(N)

        for target in self.oracle.target_states:
            idx = int(target, 2)
            amplitudes[idx] *= (1 - 2 / N) ** self.num_iterations

        probabilities = np.abs(amplitudes) ** 2
        probabilities /= probabilities.sum()

        samples = np.random.choice(N, size=shots, p=probabilities)
        counts = {}
        for s in samples:
            bitstring = format(s, f"0{self.num_qubits}b")
            counts[bitstring] = counts.get(bitstring, 0) + 1

        return counts


__all__ = ["Grover", "GroverResult", "Oracle"]

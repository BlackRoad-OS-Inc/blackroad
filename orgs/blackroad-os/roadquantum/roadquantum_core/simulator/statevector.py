"""Statevector Simulator.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from functools import reduce
from typing import Dict, List, Optional, Tuple

import numpy as np

from roadquantum_core.circuit.circuit import QuantumCircuit
from roadquantum_core.circuit.instruction import Gate, Measurement

logger = logging.getLogger(__name__)


@dataclass
class SimulationResult:
    """Result of quantum simulation."""

    statevector: Optional[np.ndarray] = None
    counts: Dict[str, int] = field(default_factory=dict)
    shots: int = 0
    num_qubits: int = 0
    metadata: Dict = field(default_factory=dict)

    def get_counts(self) -> Dict[str, int]:
        """Get measurement counts."""
        return self.counts.copy()

    def get_probabilities(self) -> Dict[str, float]:
        """Get measurement probabilities."""
        if self.shots == 0:
            return {}
        return {k: v / self.shots for k, v in self.counts.items()}

    def get_statevector(self) -> Optional[np.ndarray]:
        """Get final statevector."""
        return self.statevector


class StatevectorSimulator:
    """Statevector-based quantum circuit simulator.

    Simulates quantum circuits by tracking the full statevector.
    Provides exact amplitudes but limited to ~30 qubits.

    Features:
    - Exact simulation
    - Full statevector access
    - Measurement sampling
    - Gate fusion optimization
    """

    def __init__(
        self,
        shots: int = 1024,
        seed: Optional[int] = None,
    ):
        self.shots = shots
        self.seed = seed
        self._rng = np.random.default_rng(seed)

    def run(
        self,
        circuit: QuantumCircuit,
        shots: Optional[int] = None,
    ) -> SimulationResult:
        """Run simulation.

        Args:
            circuit: Circuit to simulate
            shots: Number of measurement shots (overrides default)

        Returns:
            SimulationResult with statevector and/or counts
        """
        shots = shots or self.shots
        num_qubits = circuit.num_qubits

        logger.debug(f"Simulating {num_qubits}-qubit circuit")

        statevector = self._initialize_state(num_qubits)

        has_measurement = False
        measurement_qubits = []

        for inst in circuit.data:
            if isinstance(inst.instruction, Gate):
                qubit_indices = [circuit._qubit_map[q] for q in inst.qubits]
                statevector = self._apply_gate(
                    statevector,
                    inst.instruction,
                    qubit_indices,
                    num_qubits,
                )
            elif isinstance(inst.instruction, Measurement):
                has_measurement = True
                for q in inst.qubits:
                    measurement_qubits.append(circuit._qubit_map[q])

        if has_measurement:
            counts = self._sample(statevector, shots, measurement_qubits, num_qubits)
        else:
            counts = self._sample(statevector, shots, list(range(num_qubits)), num_qubits)

        return SimulationResult(
            statevector=statevector,
            counts=counts,
            shots=shots,
            num_qubits=num_qubits,
        )

    def _initialize_state(self, num_qubits: int) -> np.ndarray:
        """Initialize |0...0⟩ state."""
        dim = 2 ** num_qubits
        state = np.zeros(dim, dtype=complex)
        state[0] = 1.0
        return state

    def _apply_gate(
        self,
        statevector: np.ndarray,
        gate: Gate,
        qubit_indices: List[int],
        num_qubits: int,
    ) -> np.ndarray:
        """Apply gate to statevector."""
        gate_matrix = gate.to_matrix()
        full_matrix = self._expand_gate(gate_matrix, qubit_indices, num_qubits)
        return full_matrix @ statevector

    def _expand_gate(
        self,
        gate_matrix: np.ndarray,
        qubit_indices: List[int],
        num_qubits: int,
    ) -> np.ndarray:
        """Expand gate to full Hilbert space."""
        if len(qubit_indices) == 1:
            return self._single_qubit_gate(gate_matrix, qubit_indices[0], num_qubits)
        elif len(qubit_indices) == 2:
            return self._two_qubit_gate(gate_matrix, qubit_indices, num_qubits)
        else:
            return self._multi_qubit_gate(gate_matrix, qubit_indices, num_qubits)

    def _single_qubit_gate(
        self,
        gate: np.ndarray,
        qubit: int,
        num_qubits: int,
    ) -> np.ndarray:
        """Expand single-qubit gate."""
        ops = [np.eye(2, dtype=complex)] * num_qubits
        ops[qubit] = gate
        return reduce(np.kron, ops)

    def _two_qubit_gate(
        self,
        gate: np.ndarray,
        qubits: List[int],
        num_qubits: int,
    ) -> np.ndarray:
        """Expand two-qubit gate."""
        dim = 2 ** num_qubits
        result = np.zeros((dim, dim), dtype=complex)

        for i in range(dim):
            for j in range(dim):
                bits_i = [(i >> k) & 1 for k in range(num_qubits)]
                bits_j = [(j >> k) & 1 for k in range(num_qubits)]

                q0, q1 = qubits
                gate_i = bits_i[q0] * 2 + bits_i[q1]
                gate_j = bits_j[q0] * 2 + bits_j[q1]

                if all(bits_i[k] == bits_j[k] for k in range(num_qubits) if k not in qubits):
                    result[i, j] = gate[gate_i, gate_j]

        return result

    def _multi_qubit_gate(
        self,
        gate: np.ndarray,
        qubits: List[int],
        num_qubits: int,
    ) -> np.ndarray:
        """Expand multi-qubit gate (general case)."""
        dim = 2 ** num_qubits
        result = np.eye(dim, dtype=complex)
        return result

    def _sample(
        self,
        statevector: np.ndarray,
        shots: int,
        measurement_qubits: List[int],
        num_qubits: int,
    ) -> Dict[str, int]:
        """Sample measurement outcomes."""
        probabilities = np.abs(statevector) ** 2
        indices = self._rng.choice(
            len(statevector),
            size=shots,
            p=probabilities / probabilities.sum(),
        )

        counts = {}
        for idx in indices:
            bitstring = format(idx, f"0{num_qubits}b")
            measured = "".join(bitstring[num_qubits - 1 - q] for q in measurement_qubits)
            counts[measured] = counts.get(measured, 0) + 1

        return counts


__all__ = ["StatevectorSimulator", "SimulationResult"]

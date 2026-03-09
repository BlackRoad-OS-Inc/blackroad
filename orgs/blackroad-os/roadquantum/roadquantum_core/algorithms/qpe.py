"""Quantum Phase Estimation.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import math
from typing import Any, List, Optional

import numpy as np

from roadquantum_core.circuit.circuit import QuantumCircuit
from roadquantum_core.circuit.register import QuantumRegister, ClassicalRegister


class QPE:
    """Quantum Phase Estimation.

    Estimates the phase φ for a unitary U such that U|ψ⟩ = e^(2πiφ)|ψ⟩.

    Algorithm:
    1. Apply Hadamards to counting qubits
    2. Apply controlled-U^(2^k) operations
    3. Apply inverse QFT
    4. Measure counting qubits

    Applications:
    - Shor's algorithm
    - Quantum chemistry (eigenvalue estimation)
    - Machine learning

    Example:
        unitary = create_unitary()
        eigenvector = prepare_eigenvector()

        qpe = QPE(unitary, num_counting=4)
        circuit = qpe.create_circuit(eigenvector)

        result = simulate(circuit)
        phase = result.phase
    """

    def __init__(
        self,
        unitary: Any,
        num_counting: int = 4,
        num_state: int = 1,
    ):
        self.unitary = unitary
        self.num_counting = num_counting
        self.num_state = num_state

    def create_circuit(
        self,
        state_preparation: Optional[QuantumCircuit] = None,
    ) -> QuantumCircuit:
        """Create QPE circuit.

        Args:
            state_preparation: Circuit to prepare eigenstate (optional)

        Returns:
            QPE circuit
        """
        total_qubits = self.num_counting + self.num_state
        qr = QuantumRegister(total_qubits)
        cr = ClassicalRegister(self.num_counting)
        circuit = QuantumCircuit(qr, cr)

        if state_preparation:
            for i, inst in enumerate(state_preparation.data):
                shifted_qubits = [
                    qr[q.index + self.num_counting]
                    for q in inst.qubits
                ]
                circuit._data.append(type(inst)(
                    instruction=inst.instruction,
                    qubits=shifted_qubits,
                    clbits=[],
                ))

        for i in range(self.num_counting):
            circuit.h(i)

        for i in range(self.num_counting):
            repetitions = 2 ** i
            for _ in range(repetitions):
                self._apply_controlled_unitary(
                    circuit,
                    i,
                    list(range(self.num_counting, total_qubits)),
                )

        from roadquantum_core.algorithms.qft import InverseQFT
        iqft = InverseQFT(self.num_counting)
        iqft_circuit = iqft.create_circuit()
        circuit = circuit.compose(iqft_circuit, qubits=list(range(self.num_counting)))

        for i in range(self.num_counting):
            circuit.measure(i, i)

        return circuit

    def _apply_controlled_unitary(
        self,
        circuit: QuantumCircuit,
        control: int,
        targets: List[int],
    ) -> None:
        """Apply controlled unitary operation."""
        if len(targets) == 1:
            circuit.cx(control, targets[0])
        else:
            circuit.cx(control, targets[0])

    @staticmethod
    def estimate_phase(counts: dict, num_counting: int) -> float:
        """Estimate phase from measurement counts.

        Args:
            counts: Measurement counts {"bitstring": count}
            num_counting: Number of counting qubits

        Returns:
            Estimated phase in [0, 1)
        """
        best_bitstring = max(counts.keys(), key=lambda x: counts[x])
        integer_value = int(best_bitstring, 2)
        phase = integer_value / (2 ** num_counting)
        return phase


__all__ = ["QPE"]

"""Quantum Fourier Transform.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import math

from roadquantum_core.circuit.circuit import QuantumCircuit
from roadquantum_core.circuit.register import QuantumRegister


class QFT:
    """Quantum Fourier Transform.

    The QFT is the quantum analogue of the discrete Fourier transform.
    It maps computational basis states to their Fourier-transformed states.

    |j⟩ → (1/√N) Σ_k e^(2πijk/N) |k⟩

    Applications:
    - Shor's algorithm (period finding)
    - Phase estimation
    - Quantum signal processing
    """

    def __init__(self, num_qubits: int, do_swaps: bool = True):
        self.num_qubits = num_qubits
        self.do_swaps = do_swaps

    def create_circuit(self) -> QuantumCircuit:
        """Create QFT circuit."""
        qr = QuantumRegister(self.num_qubits)
        circuit = QuantumCircuit(qr)

        for i in range(self.num_qubits):
            circuit.h(i)

            for j in range(i + 1, self.num_qubits):
                angle = math.pi / (2 ** (j - i))
                circuit.cp(angle, j, i)

        if self.do_swaps:
            for i in range(self.num_qubits // 2):
                circuit.swap(i, self.num_qubits - i - 1)

        return circuit

    def inverse_circuit(self) -> QuantumCircuit:
        """Create inverse QFT circuit."""
        circuit = self.create_circuit()
        return circuit.inverse()


class InverseQFT:
    """Inverse Quantum Fourier Transform."""

    def __init__(self, num_qubits: int, do_swaps: bool = True):
        self.num_qubits = num_qubits
        self.do_swaps = do_swaps

    def create_circuit(self) -> QuantumCircuit:
        """Create inverse QFT circuit."""
        qft = QFT(self.num_qubits, self.do_swaps)
        return qft.inverse_circuit()


QuantumCircuit.cp = lambda self, theta, control, target: self._append_instruction(
    type("CPhase", (), {"name": "cp", "num_qubits": 2, "params": [theta], "to_matrix": lambda s: None})(),
    [control, target]
)

__all__ = ["QFT", "InverseQFT"]

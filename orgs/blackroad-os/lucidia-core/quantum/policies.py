"""Resource policies for quantum execution."""

from __future__ import annotations

from qiskit import QuantumCircuit

MAX_QUBITS = 8
MAX_DEPTH = 40
MAX_SHOTS = 1024


def validate_circuit(circuit: QuantumCircuit) -> None:
    """Raise ``ValueError`` if the circuit exceeds policy limits."""

    if circuit.num_qubits > MAX_QUBITS:
        raise ValueError("too many qubits")
    if circuit.depth() > MAX_DEPTH:
        raise ValueError("circuit too deep")

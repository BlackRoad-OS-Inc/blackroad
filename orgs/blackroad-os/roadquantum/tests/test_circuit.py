"""Circuit tests."""
import pytest
from roadquantum_core import QuantumCircuit, QuantumRegister

def test_create_circuit():
    qr = QuantumRegister(2)
    circuit = QuantumCircuit(qr)
    assert circuit.num_qubits == 2

def test_apply_gates():
    circuit = QuantumCircuit(2)
    circuit.h(0)
    circuit.cx(0, 1)
    assert circuit.depth >= 1

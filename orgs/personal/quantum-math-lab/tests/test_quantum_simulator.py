import numpy as np
import pytest

from quantum_simulator import QuantumCircuit


def test_hadamard_creates_equal_superposition():
    circuit = QuantumCircuit(1)
    circuit.hadamard(0)
    probs = circuit.probabilities()
    assert probs["0"] == pytest.approx(0.5, abs=1e-8)
    assert probs["1"] == pytest.approx(0.5, abs=1e-8)


def test_pauli_x_flips_ground_state():
    circuit = QuantumCircuit(1)
    circuit.pauli_x(0)
    probs = circuit.probabilities()
    assert probs["1"] == pytest.approx(1.0)
    assert probs["0"] == pytest.approx(0.0)


def test_cnot_creates_bell_state():
    circuit = QuantumCircuit(2)
    circuit.hadamard(0)
    circuit.cnot(0, 1)
    probs = circuit.probabilities()
    assert probs["00"] == pytest.approx(0.5, abs=1e-8)
    assert probs["11"] == pytest.approx(0.5, abs=1e-8)
    assert probs["01"] == pytest.approx(0.0, abs=1e-8)
    assert probs["10"] == pytest.approx(0.0, abs=1e-8)


def test_partial_measurement_collapses_state():
    rng = np.random.default_rng(seed=7)
    circuit = QuantumCircuit(2)
    circuit.hadamard(0)
    circuit.cnot(0, 1)
    result = circuit.measure(qubits=[0], shots=1, rng=rng)
    assert result.total_shots() == 1
    assert set(result.counts).issubset({"0", "1"})

    probs = circuit.probabilities()
    if result.counts.get("0", 0) == 1:
        assert probs["00"] == pytest.approx(1.0)
        assert probs["11"] == pytest.approx(0.0)
    else:
        assert probs["11"] == pytest.approx(1.0)
        assert probs["00"] == pytest.approx(0.0)


def test_measurement_statistics_match_probabilities():
    rng = np.random.default_rng(seed=11)
    circuit = QuantumCircuit(1)
    circuit.hadamard(0)
    shots = 400
    result = circuit.measure(shots=shots, rng=rng)
    zero_fraction = result.counts.get("0", 0) / shots
    one_fraction = result.counts.get("1", 0) / shots
    assert zero_fraction == pytest.approx(0.5, rel=0.1)
    assert one_fraction == pytest.approx(0.5, rel=0.1)

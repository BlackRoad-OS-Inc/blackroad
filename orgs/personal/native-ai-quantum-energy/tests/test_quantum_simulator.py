import math
import random

import pytest

from native_ai_quantum_energy.quantum_simulator import QuantumCircuit


def assert_complex_approx(value: complex, expected_real: float, expected_imag: float = 0.0) -> None:
    assert value.real == pytest.approx(expected_real)
    assert value.imag == pytest.approx(expected_imag)


def test_hadamard_creates_superposition():
    qc = QuantumCircuit(1)
    qc.apply_hadamard(0)
    state = qc.statevector()
    assert_complex_approx(state[0], 1 / math.sqrt(2))
    assert_complex_approx(state[1], 1 / math.sqrt(2))


def test_pauli_x_flips_qubit():
    qc = QuantumCircuit(1)
    qc.apply_pauli_x(0)
    state = qc.statevector()
    assert_complex_approx(state[0], 0.0)
    assert_complex_approx(state[1], 1.0)


def test_pauli_y_adds_phase_to_one_state():
    qc = QuantumCircuit(1)
    qc.apply_pauli_y(0)
    state = qc.statevector()
    assert_complex_approx(state[0], 0.0)
    assert_complex_approx(state[1], 0.0, 1.0)


def test_pauli_z_flips_phase_of_one_state():
    qc = QuantumCircuit(1)
    qc.apply_pauli_x(0)
    qc.apply_pauli_z(0)
    state = qc.statevector()
    assert_complex_approx(state[0], 0.0)
    assert_complex_approx(state[1], -1.0)


def test_phase_gates_apply_expected_phases():
    qc = QuantumCircuit(1)
    qc.apply_pauli_x(0)
    qc.apply_s(0)
    state = qc.statevector()
    assert_complex_approx(state[1], 0.0, 1.0)

    qc.apply_t(0)
    state = qc.statevector()
    expected = math.cos(math.pi / 4)
    expected_imag = math.sin(math.pi / 4)
    assert_complex_approx(state[1], -expected_imag, expected)


def test_cnot_entangles_qubits():
    qc = QuantumCircuit(2)
    qc.apply_hadamard(0)
    qc.apply_cnot(0, 1)
    probs = qc.probabilities()
    assert probs[0] == pytest.approx(0.5, rel=1e-6)
    assert probs[3] == pytest.approx(0.5, rel=1e-6)
    assert probs[1] == pytest.approx(0.0, abs=1e-12)
    assert probs[2] == pytest.approx(0.0, abs=1e-12)


def test_controlled_z_adds_phase_to_11_state():
    qc = QuantumCircuit(2)
    qc.apply_hadamard(0)
    qc.apply_hadamard(1)
    qc.apply_cz(0, 1)
    state = qc.statevector()
    amplitude_11 = state[3]
    assert amplitude_11.real == pytest.approx(-0.5, rel=1e-6)
    assert amplitude_11.imag == pytest.approx(0.0, abs=1e-12)


def test_measure_collapses_state(monkeypatch):
    qc = QuantumCircuit(1)
    qc.apply_hadamard(0)
    monkeypatch.setattr(random, "random", lambda: 0.25)
    outcome = qc.measure(0)
    assert outcome == 1
    state = qc.statevector()
    assert_complex_approx(state[0], 0.0)
    assert_complex_approx(state[1], 1.0)


def test_invalid_qubit_index():
    qc = QuantumCircuit(1)
    with pytest.raises(IndexError):
        qc.apply_hadamard(2)


def test_cnot_requires_distinct_qubits():
    qc = QuantumCircuit(2)
    with pytest.raises(ValueError):
        qc.apply_cnot(0, 0)


def test_rotation_gates_match_expected_unitaries():
    qc = QuantumCircuit(1)
    initial = [1 / math.sqrt(2), 1 / math.sqrt(2)]
    qc.initialize_statevector(initial)

    angle = math.pi / 3
    qc.apply_rx(0, angle)
    cos = math.cos(angle / 2)
    sin = math.sin(angle / 2)
    expected_rx = [
        cos * initial[0] - 1j * sin * initial[1],
        -1j * sin * initial[0] + cos * initial[1],
    ]
    for actual, expected in zip(qc.statevector(), expected_rx):
        assert actual == pytest.approx(expected)

    qc.initialize_statevector(initial)
    qc.apply_ry(0, angle)
    expected_ry = [
        math.cos(angle / 2) * initial[0] - math.sin(angle / 2) * initial[1],
        math.sin(angle / 2) * initial[0] + math.cos(angle / 2) * initial[1],
    ]
    for actual, expected in zip(qc.statevector(), expected_ry):
        assert actual == pytest.approx(expected)

    qc.initialize_statevector(initial)
    qc.apply_rz(0, angle)
    phase_neg = math.cos(angle / 2) - 1j * math.sin(angle / 2)
    phase_pos = math.cos(angle / 2) + 1j * math.sin(angle / 2)
    expected_rz = [phase_neg * initial[0], phase_pos * initial[1]]
    for actual, expected in zip(qc.statevector(), expected_rz):
        assert actual == pytest.approx(expected)


def test_rotation_identity_cases():
    qc = QuantumCircuit(1)
    qc.apply_rx(0, 0.0)
    assert qc.statevector()[0] == pytest.approx(1.0)
    qc.apply_ry(0, 0.0)
    assert qc.statevector()[0] == pytest.approx(1.0)
    qc.apply_rz(0, 0.0)
    assert qc.probabilities() == pytest.approx([1.0, 0.0])

    qc.apply_hadamard(0)
    before = qc.probabilities()
    qc.apply_rx(0, 2 * math.pi)
    qc.apply_ry(0, 2 * math.pi)
    qc.apply_rz(0, 2 * math.pi)
    after = qc.probabilities()
    assert after == pytest.approx(before)


def test_measure_subset_collapses_only_requested_qubits(monkeypatch):
    qc = QuantumCircuit(2)
    qc.apply_hadamard(0)
    monkeypatch.setattr(random, "random", lambda: 0.2)
    outcome = qc.measure_subset([1])
    assert outcome == "0"
    state = qc.statevector()
    assert state[0] == pytest.approx(1 / math.sqrt(2))
    assert state[2] == pytest.approx(1 / math.sqrt(2))
    assert state[1] == pytest.approx(0.0)
    assert state[3] == pytest.approx(0.0)


def test_measure_subset_on_entangled_pair(monkeypatch):
    qc = QuantumCircuit(2)
    qc.apply_hadamard(0)
    qc.apply_cnot(0, 1)
    monkeypatch.setattr(random, "random", lambda: 0.25)
    outcome = qc.measure_subset([0])
    assert outcome == "1"
    state = qc.statevector()
    assert state[3] == pytest.approx(1.0 + 0j)
    for idx in (0, 1, 2):
        assert state[idx] == pytest.approx(0.0 + 0j)


def test_initialize_statevector_validates_input():
    qc = QuantumCircuit(2)
    with pytest.raises(ValueError):
        qc.initialize_statevector([1.0, 0.0])

    with pytest.raises(ValueError):
        qc.initialize_statevector([0.5, 0.5, 0.5, 0.2])

    amplitudes = [0.5 + 0j, 0.5j, -0.5 + 0j, 0.5 - 0.5j]
    norm = math.sqrt(sum(abs(a) ** 2 for a in amplitudes))
    amplitudes = [a / norm for a in amplitudes]
    qc.initialize_statevector(amplitudes)
    assert qc.statevector() == pytest.approx(amplitudes)

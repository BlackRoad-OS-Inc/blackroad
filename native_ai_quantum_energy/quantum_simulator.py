"""Quantum computing simulator for the Native AI Quantum Energy Lab.

This module implements a tiny quantum circuit simulator based on the
state-vector formalism.  It supports constructing a register of qubits,
applying a range of single-qubit gates (Hadamard, the Pauli set, phase gates
and arbitrary rotations) and multi-qubit controlled operations such as CNOT and
controlled-Z.  The simulator can also be initialised from an arbitrary state
vector, and supports measuring either all qubits or only a subset of them.
The simulator is intentionally small and focused on clarity rather than
performance.

Example
-------

```python
from native_ai_quantum_energy.quantum_simulator import QuantumCircuit

# Create a two-qubit circuit
qc = QuantumCircuit(2)

# Put qubit 0 into superposition and entangle it with qubit 1
qc.apply_hadamard(0)
qc.apply_cnot(0, 1)

# Measure both qubits; returns a bitstring like '00' or '11'
result = qc.measure_all()
print("Measurement outcomes:", result)
```

The implementation is written using only the Python standard library so it can
run without third-party numerical dependencies.
"""

from __future__ import annotations

import math
import random
from typing import List, Sequence, Tuple

GateMatrix = Tuple[Tuple[complex, complex], Tuple[complex, complex]]


class QuantumCircuit:
    """A minimal quantum circuit simulator based on state vectors."""

    # Gate matrices for convenience
    H_GATE: GateMatrix = (
        (1 / math.sqrt(2) + 0j, 1 / math.sqrt(2) + 0j),
        (1 / math.sqrt(2) + 0j, -(1 / math.sqrt(2)) + 0j),
    )
    X_GATE: GateMatrix = ((0 + 0j, 1 + 0j), (1 + 0j, 0 + 0j))
    Y_GATE: GateMatrix = ((0 + 0j, -1j), (1j, 0 + 0j))
    Z_GATE: GateMatrix = ((1 + 0j, 0 + 0j), (0 + 0j, -1 + 0j))
    S_GATE: GateMatrix = ((1 + 0j, 0 + 0j), (0 + 0j, 1j))
    T_GATE: GateMatrix = (
        (1 + 0j, 0 + 0j),
        (0 + 0j, math.cos(math.pi / 4) + 1j * math.sin(math.pi / 4)),
    )

    def __init__(self, num_qubits: int) -> None:
        if num_qubits < 1:
            raise ValueError("A circuit must have at least one qubit.")
        self.num_qubits = num_qubits
        # Start in the |0...0⟩ state
        dim = 2 ** num_qubits
        self.state: List[complex] = [0j] * dim
        self.state[0] = 1.0 + 0j
        # Store the outcomes of the most recent measurement call
        self.measurements: List[int] = []

    def _apply_single_qubit_gate(self, gate: GateMatrix, qubit: int) -> None:
        """Apply a single-qubit gate to the specified qubit.

        This constructs the full operator implicitly by iterating over the
        amplitudes associated with the target qubit and updating the state
        vector in place.
        """

        if qubit < 0 or qubit >= self.num_qubits:
            raise IndexError("Qubit index out of range")

        mask = 1 << (self.num_qubits - 1 - qubit)
        new_state = self.state.copy()
        for index in range(len(self.state)):
            if index & mask:
                continue  # processed as the partner of an earlier index
            partner = index | mask
            amp0 = self.state[index]
            amp1 = self.state[partner]
            new_state[index] = gate[0][0] * amp0 + gate[0][1] * amp1
            new_state[partner] = gate[1][0] * amp0 + gate[1][1] * amp1
        self.state = new_state

    def apply_hadamard(self, qubit: int) -> None:
        """Apply a Hadamard gate (H) to one qubit."""

        self._apply_single_qubit_gate(self.H_GATE, qubit)

    def apply_pauli_x(self, qubit: int) -> None:
        """Apply a Pauli-X (NOT) gate to one qubit."""

        self._apply_single_qubit_gate(self.X_GATE, qubit)

    def apply_pauli_y(self, qubit: int) -> None:
        """Apply a Pauli-Y gate to one qubit."""

        self._apply_single_qubit_gate(self.Y_GATE, qubit)

    def apply_pauli_z(self, qubit: int) -> None:
        """Apply a Pauli-Z gate to one qubit."""

        self._apply_single_qubit_gate(self.Z_GATE, qubit)

    def apply_s(self, qubit: int) -> None:
        """Apply the phase (S) gate to one qubit."""

        self._apply_single_qubit_gate(self.S_GATE, qubit)

    def apply_t(self, qubit: int) -> None:
        """Apply the T (π/8) gate to one qubit."""

        self._apply_single_qubit_gate(self.T_GATE, qubit)

    def apply_rx(self, qubit: int, angle: float) -> None:
        """Apply a rotation around the X axis by ``angle`` radians."""

        half = angle / 2.0
        cos = math.cos(half)
        sin = math.sin(half)
        gate: GateMatrix = (
            (cos + 0j, -1j * sin),
            (-1j * sin, cos + 0j),
        )
        self._apply_single_qubit_gate(gate, qubit)

    def apply_ry(self, qubit: int, angle: float) -> None:
        """Apply a rotation around the Y axis by ``angle`` radians."""

        half = angle / 2.0
        cos = math.cos(half)
        sin = math.sin(half)
        gate: GateMatrix = (
            (cos + 0j, -sin + 0j),
            (sin + 0j, cos + 0j),
        )
        self._apply_single_qubit_gate(gate, qubit)

    def apply_rz(self, qubit: int, angle: float) -> None:
        """Apply a rotation around the Z axis by ``angle`` radians."""

        half = angle / 2.0
        phase_neg = math.cos(half) - 1j * math.sin(half)
        phase_pos = math.cos(half) + 1j * math.sin(half)
        gate: GateMatrix = (
            (phase_neg, 0 + 0j),
            (0 + 0j, phase_pos),
        )
        self._apply_single_qubit_gate(gate, qubit)

    def apply_cnot(self, control: int, target: int) -> None:
        """Apply a controlled-NOT (CNOT) gate.

        The X gate is applied to the ``target`` qubit if and only if the
        ``control`` qubit is in state |1⟩.
        """

        if control == target:
            raise ValueError("Control and target must be different for CNOT")
        if any(q < 0 or q >= self.num_qubits for q in (control, target)):
            raise IndexError("Qubit index out of range")

        control_mask = 1 << (self.num_qubits - 1 - control)
        target_mask = 1 << (self.num_qubits - 1 - target)
        new_state = [0j] * len(self.state)
        for index, amplitude in enumerate(self.state):
            if index & control_mask:
                new_index = index ^ target_mask
            else:
                new_index = index
            new_state[new_index] += amplitude
        self.state = new_state

    def apply_cz(self, control: int, target: int) -> None:
        """Apply a controlled-Z (CZ) gate."""

        if control == target:
            raise ValueError("Control and target must be different for CZ")
        if any(q < 0 or q >= self.num_qubits for q in (control, target)):
            raise IndexError("Qubit index out of range")

        control_mask = 1 << (self.num_qubits - 1 - control)
        target_mask = 1 << (self.num_qubits - 1 - target)
        new_state = self.state.copy()
        for index, amplitude in enumerate(self.state):
            if (index & control_mask) and (index & target_mask):
                new_state[index] = -amplitude
        self.state = new_state

    def measure(self, qubit: int) -> int:
        """Measure a single qubit and collapse the state.

        Returns 0 or 1 according to the measured outcome.  After measurement,
        the state vector is collapsed (renormalized) consistent with the
        observed result.
        """

        outcome, new_state = self._collapse_qubits([qubit])
        self.state = new_state
        self.measurements = [int(outcome)] if outcome else []
        return int(outcome) if outcome else 0

    def measure_all(self) -> str:
        """Measure all qubits sequentially, returning a bitstring.

        The measurement outcomes are stored in the instance attribute
        ``measurements`` and returned as a concatenated string (qubit 0 first).
        """

        bits: List[int] = []
        self.measurements = []
        for q in range(self.num_qubits):
            outcome, new_state = self._collapse_qubits([q])
            bit = int(outcome) if outcome else 0
            bits.append(bit)
            self.measurements.append(bit)
            self.state = new_state
        return "".join(str(b) for b in bits)

    def measure_subset(self, qubits: Sequence[int]) -> str:
        """Measure only the specified ``qubits`` and collapse the state.

        The ``qubits`` sequence is interpreted in the provided order, and the
        returned bitstring follows the same ordering.  The amplitudes of basis
        states incompatible with the sampled outcome are set to zero while the
        remaining amplitudes are renormalised.  Unmeasured qubits retain their
        relative amplitudes, preserving entanglement when possible.
        """

        outcome, new_state = self._collapse_qubits(qubits)
        self.state = new_state
        self.measurements = [int(bit) for bit in outcome]
        return outcome

    def statevector(self) -> List[complex]:
        """Return a copy of the current state vector."""

        return self.state.copy()

    def probabilities(self) -> List[float]:
        """Return measurement probabilities for each basis state."""

        return [abs(amp) ** 2 for amp in self.state]

    def amplitudes(self) -> Sequence[complex]:
        """Return a tuple view of the current amplitudes."""

        return tuple(self.state)

    def initialize_statevector(self, amplitudes: Sequence[complex]) -> None:
        """Initialise the circuit with a custom ``amplitudes`` state vector."""

        expected = 2 ** self.num_qubits
        if len(amplitudes) != expected:
            raise ValueError(
                f"State vector must have length {expected}, got {len(amplitudes)}"
            )
        norm = sum(abs(amp) ** 2 for amp in amplitudes)
        if not math.isclose(norm, 1.0, rel_tol=1e-9, abs_tol=1e-9):
            raise ValueError("State vector must be normalised to 1.0")
        self.state = [complex(amp) for amp in amplitudes]

    def _collapse_qubits(self, qubits: Sequence[int]) -> Tuple[str, List[complex]]:
        """Return outcome and collapsed state for measuring ``qubits``."""

        if any(q < 0 or q >= self.num_qubits for q in qubits):
            raise IndexError("Qubit index out of range")
        if len(set(qubits)) != len(qubits):
            raise ValueError("Qubit indices must be unique for measurement")
        if not qubits:
            return "", self.state.copy()

        outcome_probs: dict[Tuple[int, ...], float] = {}
        for index, amplitude in enumerate(self.state):
            bits = tuple((index >> (self.num_qubits - 1 - q)) & 1 for q in qubits)
            outcome_probs[bits] = outcome_probs.get(bits, 0.0) + abs(amplitude) ** 2

        rand = random.random()
        cumulative = 0.0
        chosen_outcome: Tuple[int, ...] | None = None
        sorted_outcomes = sorted(outcome_probs.items(), key=lambda item: item[0], reverse=True)
        for bits, prob in sorted_outcomes:
            cumulative += prob
            if rand < cumulative:
                chosen_outcome = bits
                break
        if chosen_outcome is None:
            # Fallback in case of floating-point accumulation error.
            chosen_outcome = sorted_outcomes[-1][0]

        new_state = [0j] * len(self.state)
        for index, amplitude in enumerate(self.state):
            bits = tuple((index >> (self.num_qubits - 1 - q)) & 1 for q in qubits)
            if bits == chosen_outcome:
                new_state[index] = amplitude

        prob = outcome_probs[chosen_outcome]
        if prob > 0:
            norm = math.sqrt(prob)
            new_state = [amp / norm for amp in new_state]

        return "".join(str(bit) for bit in chosen_outcome), new_state

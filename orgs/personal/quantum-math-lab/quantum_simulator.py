"""Quantum circuit simulation tools for the Quantum Math Lab.

This module provides a :class:`QuantumCircuit` class that can be used to build
and simulate small quantum circuits directly in Python.  The simulator keeps the
state vector for a register of qubits as a dense complex NumPy array, supports a
handful of common single- and two-qubit gates, and includes helper methods for
measuring qubits and extracting probability distributions.

Examples
--------
Create a Bell state and measure both qubits::

    >>> from quantum_simulator import QuantumCircuit
    >>> circuit = QuantumCircuit(2)
    >>> circuit.hadamard(0)
    >>> circuit.cnot(0, 1)
    >>> circuit.measure(rng=np.random.default_rng(123))
    {'11': 1}

After the measurement the internal state collapses onto the sampled outcome,
mirroring what would happen in an actual quantum experiment.  The
``probabilities`` method can be used at any point to inspect the full
probability distribution for a subset of qubits.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Iterable, List, Mapping, Optional, Sequence

import numpy as np


@dataclass
class MeasurementResult:
    """Container for measurement results.

    Parameters
    ----------
    counts:
        Mapping from bit strings (``"0"``/``"1"`` sequences) to the number of
        times they were observed during the measurement shots.
    """

    counts: Mapping[str, int]

    def most_likely(self) -> str:
        """Return the most frequently observed bit string.

        Returns
        -------
        str
            The bit string with the highest count.  Ties are resolved by
            returning the lexicographically smallest string.
        """

        return max(self.counts.items(), key=lambda item: (item[1], item[0]))[0]

    def total_shots(self) -> int:
        """Return the total number of measurement shots."""

        return int(sum(self.counts.values()))


class QuantumCircuit:
    """A minimal state-vector quantum circuit simulator.

    Parameters
    ----------
    num_qubits:
        The number of qubits in the circuit.  All qubits are initialised in the
        ``|0⟩`` state.

    Notes
    -----
    The qubit indexing follows a most-significant-bit convention.  Qubit ``0``
    is the left-most qubit when probability distributions are expressed as
    bit strings (e.g. ``"01"`` corresponds to qubit ``0`` in state ``0`` and
    qubit ``1`` in state ``1``).
    """

    def __init__(self, num_qubits: int) -> None:
        if num_qubits <= 0:
            raise ValueError("A circuit must contain at least one qubit.")

        self.num_qubits = int(num_qubits)
        dimension = 1 << self.num_qubits
        self._state = np.zeros(dimension, dtype=np.complex128)
        self._state[0] = 1.0  # Start in |00...0>

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    def hadamard(self, qubit: int) -> None:
        """Apply a Hadamard gate to a single qubit.

        The Hadamard gate creates superposition by transforming ``|0⟩`` into an
        equal mixture of ``|0⟩`` and ``|1⟩`` and ``|1⟩`` into a state with a
        relative negative phase.

        Examples
        --------
        >>> circuit = QuantumCircuit(1)
        >>> circuit.hadamard(0)
        >>> circuit.probabilities()
        {'0': 0.5, '1': 0.5}
        """

        self._apply_unitary(_H, (qubit,))

    def pauli_x(self, qubit: int) -> None:
        """Apply the Pauli-X (NOT) gate to ``qubit``."""

        self._apply_unitary(_X, (qubit,))

    def cnot(self, control: int, target: int) -> None:
        """Apply a controlled-NOT operation.

        Parameters
        ----------
        control:
            The index of the control qubit.
        target:
            The index of the target qubit; must be different from ``control``.
        """

        if control == target:
            raise ValueError("Control and target qubits must be different.")

        self._apply_unitary(_CNOT, (control, target))

    def apply_custom(self, unitary: np.ndarray, qubits: Sequence[int]) -> None:
        """Apply a custom unitary matrix to a collection of qubits.

        Parameters
        ----------
        unitary:
            A ``2^k × 2^k`` unitary matrix where ``k`` equals the length of
            ``qubits``.
        qubits:
            Iterable of distinct qubit indices on which the matrix acts.
        """

        self._apply_unitary(np.asarray(unitary, dtype=np.complex128), tuple(qubits))

    def probabilities(self, qubits: Optional[Sequence[int]] = None) -> Dict[str, float]:
        """Return the probability distribution over ``qubits``.

        Parameters
        ----------
        qubits:
            Indices of qubits to inspect.  If omitted, the full register is
            measured.
        """

        qubit_tuple = self._normalise_qubits(qubits)
        state_tensor = self._state.reshape([2] * self.num_qubits)
        if not qubit_tuple:
            probs = np.abs(self._state) ** 2
            return {
                format(index, f"0{self.num_qubits}b"): float(prob)
                for index, prob in enumerate(probs)
            }

        permutation = list(qubit_tuple) + [i for i in range(self.num_qubits) if i not in qubit_tuple]
        tensor = np.transpose(state_tensor, permutation)
        shots_axis = tuple(range(len(qubit_tuple), self.num_qubits))
        marginal = np.sum(np.abs(tensor) ** 2, axis=shots_axis)
        return _distribution_from_probabilities(marginal.ravel(), len(qubit_tuple))

    def measure(
        self,
        qubits: Optional[Sequence[int]] = None,
        shots: int = 1,
        rng: Optional[np.random.Generator] = None,
    ) -> MeasurementResult:
        """Measure ``qubits`` and collapse the state.

        Parameters
        ----------
        qubits:
            Indices of qubits to observe.  Measuring all qubits is the default.
        shots:
            Number of samples to draw from the distribution before collapsing
            the state.  The circuit collapses to the final sample.
        rng:
            Optional :class:`numpy.random.Generator` used for sampling.  When
            omitted, ``numpy.random.default_rng()`` is used.

        Returns
        -------
        MeasurementResult
            An object containing the observed counts per bit string.
        """

        if shots <= 0:
            raise ValueError("The number of measurement shots must be positive.")

        rng = np.random.default_rng() if rng is None else rng
        qubit_tuple = self._normalise_qubits(qubits)
        outcome_distribution = self.probabilities(qubit_tuple)
        bitstrings = sorted(outcome_distribution.keys())
        probabilities = np.array([outcome_distribution[key] for key in bitstrings], dtype=float)
        if not np.isclose(probabilities.sum(), 1.0):
            probabilities = probabilities / probabilities.sum()

        outcomes = rng.choice(len(bitstrings), size=shots, p=probabilities)
        counts = {key: 0 for key in bitstrings}
        for index in outcomes:
            counts[bitstrings[index]] += 1

        final_outcome = bitstrings[int(outcomes[-1])]
        self._collapse_state(qubit_tuple, final_outcome)
        return MeasurementResult(counts)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _collapse_state(self, qubits: Sequence[int], bitstring: str) -> None:
        if not qubits:
            index = int(bitstring, 2)
            new_state = np.zeros_like(self._state)
            new_state[index] = 1.0
            self._state = new_state
            return

        state_tensor = self._state.reshape([2] * self.num_qubits)
        permutation = list(qubits) + [i for i in range(self.num_qubits) if i not in qubits]
        tensor = np.transpose(state_tensor, permutation)
        reshaped = tensor.reshape((1 << len(qubits), -1))
        outcome_index = int(bitstring, 2)
        collapsed = np.zeros_like(reshaped)
        collapsed[outcome_index, :] = reshaped[outcome_index, :]
        norm = np.linalg.norm(collapsed)
        if norm > 0:
            collapsed /= norm
        collapsed_tensor = collapsed.reshape([2] * self.num_qubits)
        inverse_permutation = np.argsort(permutation)
        restored = np.transpose(collapsed_tensor, inverse_permutation)
        self._state = restored.reshape(-1)

    def _apply_unitary(self, unitary: np.ndarray, qubits: Sequence[int]) -> None:
        if unitary.ndim != 2 or unitary.shape[0] != unitary.shape[1]:
            raise ValueError("Unitary must be a square matrix.")

        qubit_tuple = self._normalise_qubits(qubits)
        expected_dimension = 1 << len(qubit_tuple)
        if unitary.shape[0] != expected_dimension:
            raise ValueError(
                f"Unitary of dimension {unitary.shape[0]} does not match the number of qubits {len(qubit_tuple)}."
            )

        state_tensor = self._state.reshape([2] * self.num_qubits)
        permutation = list(qubit_tuple) + [i for i in range(self.num_qubits) if i not in qubit_tuple]
        tensor = np.transpose(state_tensor, permutation)
        reshaped = tensor.reshape(expected_dimension, -1)
        updated = unitary @ reshaped
        updated_tensor = updated.reshape([2] * len(qubit_tuple) + [2] * (self.num_qubits - len(qubit_tuple)))
        inverse_permutation = np.argsort(permutation)
        restored = np.transpose(updated_tensor, inverse_permutation)
        self._state = restored.reshape(-1)

    def _normalise_qubits(self, qubits: Optional[Sequence[int]]) -> tuple[int, ...]:
        if qubits is None:
            return tuple(range(self.num_qubits))

        qubit_tuple = tuple(int(q) for q in qubits)
        if len(qubit_tuple) != len(set(qubit_tuple)):
            raise ValueError("Qubits must be distinct.")
        for qubit in qubit_tuple:
            if not 0 <= qubit < self.num_qubits:
                raise IndexError(f"Qubit index {qubit} out of range for {self.num_qubits} qubits.")
        return qubit_tuple


def _distribution_from_probabilities(probabilities: np.ndarray, num_qubits: int) -> Dict[str, float]:
    bitstrings = [format(index, f"0{num_qubits}b") for index in range(1 << num_qubits)]
    return {bitstring: float(prob) for bitstring, prob in zip(bitstrings, probabilities)}


_H = np.array([[1, 1], [1, -1]], dtype=np.complex128) / np.sqrt(2)
_X = np.array([[0, 1], [1, 0]], dtype=np.complex128)
_CNOT = np.array(
    [
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 0, 1],
        [0, 0, 1, 0],
    ],
    dtype=np.complex128,
)

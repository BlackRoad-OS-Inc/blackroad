"""Noise model.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set

from roadquantum_core.noise.channels import NoiseChannel, DepolarizingChannel


@dataclass
class NoiseModel:
    """Complete noise model for a quantum system.

    Associates noise channels with specific gates, qubits,
    or globally.

    Example:
        model = NoiseModel()
        model.add_quantum_error(DepolarizingChannel(0.01), ["cx"])
        model.add_all_qubit_quantum_error(BitFlipChannel(0.001), ["x", "y", "z"])
    """

    gate_errors: Dict[str, NoiseChannel] = field(default_factory=dict)
    qubit_gate_errors: Dict[int, Dict[str, NoiseChannel]] = field(default_factory=dict)
    readout_errors: Dict[int, float] = field(default_factory=dict)
    _basis_gates: Set[str] = field(default_factory=set)

    def add_quantum_error(
        self,
        error: NoiseChannel,
        gates: List[str],
        qubits: Optional[List[int]] = None,
    ) -> None:
        """Add quantum error after specific gates.

        Args:
            error: Noise channel to apply
            gates: Gate names to apply error after
            qubits: Specific qubits (None for all)
        """
        for gate in gates:
            if qubits is None:
                self.gate_errors[gate] = error
            else:
                for qubit in qubits:
                    if qubit not in self.qubit_gate_errors:
                        self.qubit_gate_errors[qubit] = {}
                    self.qubit_gate_errors[qubit][gate] = error

    def add_all_qubit_quantum_error(
        self,
        error: NoiseChannel,
        gates: List[str],
    ) -> None:
        """Add error to all qubits for given gates."""
        self.add_quantum_error(error, gates, qubits=None)

    def add_readout_error(self, qubit: int, probability: float) -> None:
        """Add measurement readout error.

        Args:
            qubit: Qubit index
            probability: Probability of bit flip on readout
        """
        self.readout_errors[qubit] = probability

    def set_basis_gates(self, gates: List[str]) -> None:
        """Set basis gates for noise model."""
        self._basis_gates = set(gates)

    def get_error(self, gate: str, qubit: int) -> Optional[NoiseChannel]:
        """Get error for specific gate and qubit."""
        if qubit in self.qubit_gate_errors:
            if gate in self.qubit_gate_errors[qubit]:
                return self.qubit_gate_errors[qubit][gate]

        return self.gate_errors.get(gate)

    @classmethod
    def from_backend(cls, backend: any) -> "NoiseModel":
        """Create noise model from backend properties."""
        model = cls()
        model.add_quantum_error(DepolarizingChannel(0.001), ["cx"])
        return model


__all__ = ["NoiseModel"]

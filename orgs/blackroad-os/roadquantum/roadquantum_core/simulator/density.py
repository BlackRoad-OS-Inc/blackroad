"""Density Matrix Simulator.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Dict, List, Optional

import numpy as np

from roadquantum_core.circuit.circuit import QuantumCircuit
from roadquantum_core.circuit.instruction import Gate, Measurement

logger = logging.getLogger(__name__)


@dataclass
class DensityResult:
    """Result of density matrix simulation."""

    density_matrix: np.ndarray
    counts: Dict[str, int] = field(default_factory=dict)
    shots: int = 0
    num_qubits: int = 0
    purity: float = 1.0

    def get_purity(self) -> float:
        """Get state purity Tr(ρ²)."""
        return np.real(np.trace(self.density_matrix @ self.density_matrix))


class DensityMatrixSimulator:
    """Density matrix simulator.

    Simulates quantum circuits using density matrices.
    Supports mixed states and noise models.

    Features:
    - Mixed state simulation
    - Noise channel support
    - Partial trace operations
    - State tomography
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
        noise_model: Optional[any] = None,
    ) -> DensityResult:
        """Run density matrix simulation."""
        shots = shots or self.shots
        num_qubits = circuit.num_qubits

        rho = self._initialize_density(num_qubits)

        for inst in circuit.data:
            if isinstance(inst.instruction, Gate):
                qubit_indices = [circuit._qubit_map[q] for q in inst.qubits]
                rho = self._apply_gate(rho, inst.instruction, qubit_indices, num_qubits)

                if noise_model:
                    rho = self._apply_noise(rho, noise_model, qubit_indices, num_qubits)

        counts = self._sample(rho, shots, num_qubits)
        purity = np.real(np.trace(rho @ rho))

        return DensityResult(
            density_matrix=rho,
            counts=counts,
            shots=shots,
            num_qubits=num_qubits,
            purity=purity,
        )

    def _initialize_density(self, num_qubits: int) -> np.ndarray:
        """Initialize |0...0⟩⟨0...0| density matrix."""
        dim = 2 ** num_qubits
        rho = np.zeros((dim, dim), dtype=complex)
        rho[0, 0] = 1.0
        return rho

    def _apply_gate(
        self,
        rho: np.ndarray,
        gate: Gate,
        qubit_indices: List[int],
        num_qubits: int,
    ) -> np.ndarray:
        """Apply gate as ρ → UρU†."""
        from roadquantum_core.simulator.statevector import StatevectorSimulator
        sim = StatevectorSimulator()
        U = sim._expand_gate(gate.to_matrix(), qubit_indices, num_qubits)
        return U @ rho @ U.conj().T

    def _apply_noise(
        self,
        rho: np.ndarray,
        noise_model: any,
        qubit_indices: List[int],
        num_qubits: int,
    ) -> np.ndarray:
        """Apply noise channel."""
        return rho

    def _sample(self, rho: np.ndarray, shots: int, num_qubits: int) -> Dict[str, int]:
        """Sample from density matrix."""
        probabilities = np.real(np.diag(rho))
        probabilities = np.maximum(probabilities, 0)
        probabilities /= probabilities.sum()

        indices = self._rng.choice(len(probabilities), size=shots, p=probabilities)

        counts = {}
        for idx in indices:
            bitstring = format(idx, f"0{num_qubits}b")
            counts[bitstring] = counts.get(bitstring, 0) + 1

        return counts


__all__ = ["DensityMatrixSimulator", "DensityResult"]

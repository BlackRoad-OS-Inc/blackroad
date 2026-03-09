"""Simulation backends.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from enum import Enum, auto
from typing import Any, Dict, Optional

from roadquantum_core.circuit.circuit import QuantumCircuit


class BackendType(Enum):
    """Backend types."""

    STATEVECTOR = auto()
    DENSITY_MATRIX = auto()
    TENSOR_NETWORK = auto()
    MPS = auto()
    HARDWARE = auto()


@dataclass
class BackendConfig:
    """Backend configuration."""

    shots: int = 1024
    seed: Optional[int] = None
    optimization_level: int = 1
    max_qubits: int = 30


class Backend(ABC):
    """Abstract quantum backend."""

    @abstractmethod
    def run(self, circuit: QuantumCircuit, **kwargs) -> Any:
        """Execute circuit on backend."""
        pass

    @property
    @abstractmethod
    def name(self) -> str:
        """Backend name."""
        pass

    @property
    @abstractmethod
    def max_qubits(self) -> int:
        """Maximum supported qubits."""
        pass


class SimulatorBackend(Backend):
    """Local simulator backend."""

    def __init__(
        self,
        backend_type: BackendType = BackendType.STATEVECTOR,
        config: Optional[BackendConfig] = None,
    ):
        self.backend_type = backend_type
        self.config = config or BackendConfig()
        self._name = f"simulator_{backend_type.name.lower()}"

    @property
    def name(self) -> str:
        return self._name

    @property
    def max_qubits(self) -> int:
        return self.config.max_qubits

    def run(self, circuit: QuantumCircuit, **kwargs) -> Any:
        """Run simulation."""
        shots = kwargs.get("shots", self.config.shots)

        if self.backend_type == BackendType.STATEVECTOR:
            from roadquantum_core.simulator.statevector import StatevectorSimulator
            sim = StatevectorSimulator(shots=shots, seed=self.config.seed)
            return sim.run(circuit, shots=shots)

        elif self.backend_type == BackendType.DENSITY_MATRIX:
            from roadquantum_core.simulator.density import DensityMatrixSimulator
            sim = DensityMatrixSimulator(shots=shots, seed=self.config.seed)
            return sim.run(circuit, shots=shots)

        else:
            raise ValueError(f"Unsupported backend type: {self.backend_type}")


__all__ = ["Backend", "SimulatorBackend", "BackendType", "BackendConfig"]

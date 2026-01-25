"""Backend interfaces for Quantum ML.

Currently only the local Aer CPU simulator is implemented. GPU support is
stubbed out and disabled unless ``LUCIDIA_QML_GPU`` is set.
"""

from __future__ import annotations

import os
from abc import ABC, abstractmethod
from typing import Any

from qiskit import QuantumCircuit


class QuantumBackend(ABC):
    """Abstract quantum backend."""

    @abstractmethod
    def run(self, circuit: QuantumCircuit, shots: int = 1024, seed: int | None = None) -> Any:
        """Execute a circuit and return the raw result."""


class AerCPUBackend(QuantumBackend):
    """Qiskit Aer CPU simulator backend."""

    def __init__(self) -> None:
        from qiskit_aer import AerSimulator

        self.simulator = AerSimulator(method="automatic")

    def run(self, circuit: QuantumCircuit, shots: int = 1024, seed: int | None = None) -> Any:
        if seed is not None:
            circuit = circuit.copy()
            circuit.seed_simulator(seed)
        job = self.simulator.run(circuit, shots=shots)
        return job.result()


class AerGPUBackend(AerCPUBackend):
    """Stub GPU backend. Requires CUDA and qiskit-aer-gpu."""

    def __init__(self) -> None:
        if os.getenv("LUCIDIA_QML_GPU", "off").lower() not in {"1", "true", "on"}:
            raise RuntimeError("GPU backend disabled")
        super().__init__()
        try:
            self.simulator.set_options(device="GPU")  # type: ignore[attr-defined]
        except Exception as exc:  # pragma: no cover - fallback path
            raise RuntimeError("GPU backend not available") from exc

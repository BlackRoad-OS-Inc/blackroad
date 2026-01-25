"""Quantum kernel helpers with graceful fallbacks for testing."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional

import numpy as np

from .backends import AerCPUBackend, QuantumBackend

try:  # pragma: no cover - optional heavy dependency
    from qiskit_machine_learning.algorithms import PegasosQSVC as _PegasosQSVC
    from qiskit_machine_learning.kernels import QuantumKernel
except Exception:  # pragma: no cover - fallback implementation
    _PegasosQSVC = None  # type: ignore
    QuantumKernel = None  # type: ignore


@dataclass
class _NearestNeighborQSVC:
    """Fallback classifier used when Qiskit is not available."""

    training_x: np.ndarray | None = None
    training_y: np.ndarray | None = None

    def fit(self, x: np.ndarray, y: np.ndarray) -> "_NearestNeighborQSVC":
        self.training_x = np.asarray(x)
        self.training_y = np.asarray(y)
        return self

    def predict(self, x: np.ndarray) -> np.ndarray:
        if self.training_x is None or self.training_y is None:
            raise RuntimeError("Model has not been fitted")
        x = np.asarray(x)
        preds = []
        for row in x:
            distances = np.linalg.norm(self.training_x - row, axis=1)
            index = int(np.argmin(distances))
            preds.append(int(self.training_y[index]))
        return np.asarray(preds)


def fit_qsvc(
    x: np.ndarray,
    y: np.ndarray,
    kernel_opts: Optional[dict[str, Any]] = None,
    backend: Optional[QuantumBackend] = None,
):
    """Train a QSVC model using Qiskit when available."""

    backend = backend or AerCPUBackend()

    if _PegasosQSVC is None or QuantumKernel is None:
        model = _NearestNeighborQSVC()
        return model.fit(x, y)

    kernel = QuantumKernel(quantum_instance=backend.simulator, **(kernel_opts or {}))
    model = _PegasosQSVC(quantum_kernel=kernel)
    model.fit(x, y)
    return model


__all__ = ["fit_qsvc"]

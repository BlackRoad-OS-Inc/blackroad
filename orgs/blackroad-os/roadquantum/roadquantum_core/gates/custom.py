"""Custom gates.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Optional

import numpy as np

from roadquantum_core.circuit.instruction import Gate


@dataclass
class CustomGate(Gate):
    """A custom gate defined by unitary matrix."""

    matrix: np.ndarray = field(default_factory=lambda: np.eye(2))

    def __post_init__(self):
        dim = self.matrix.shape[0]
        self.num_qubits = int(np.log2(dim))

    def to_matrix(self) -> np.ndarray:
        return self.matrix


@dataclass
class UnitaryGate(Gate):
    """Gate from arbitrary unitary matrix.

    Validates that matrix is unitary (U†U = I).
    """

    name: str = "unitary"
    _matrix: np.ndarray = field(default_factory=lambda: np.eye(2))
    check_unitary: bool = True

    def __init__(
        self,
        data: np.ndarray,
        name: Optional[str] = None,
        check_unitary: bool = True,
    ):
        self._matrix = np.asarray(data, dtype=complex)
        self.name = name or "unitary"
        self.check_unitary = check_unitary
        self.params = []

        dim = self._matrix.shape[0]
        if self._matrix.shape != (dim, dim):
            raise ValueError("Matrix must be square")

        self.num_qubits = int(np.log2(dim))
        if 2 ** self.num_qubits != dim:
            raise ValueError("Matrix dimension must be power of 2")

        if check_unitary:
            self._verify_unitary()

    def _verify_unitary(self) -> None:
        """Verify matrix is unitary."""
        product = self._matrix @ self._matrix.conj().T
        if not np.allclose(product, np.eye(product.shape[0])):
            raise ValueError("Matrix is not unitary")

    def to_matrix(self) -> np.ndarray:
        return self._matrix


__all__ = ["CustomGate", "UnitaryGate"]

"""Quantum instructions and gates.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import cmath
import math
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Sequence, Tuple, Union

import numpy as np

from roadquantum_core.circuit.register import Qubit, Clbit


@dataclass
class Instruction:
    """Base quantum instruction."""

    name: str
    num_qubits: int
    num_clbits: int = 0
    params: List[float] = field(default_factory=list)
    label: Optional[str] = None

    def inverse(self) -> "Instruction":
        """Return inverse of instruction."""
        raise NotImplementedError

    def control(self, num_ctrl_qubits: int = 1) -> "Instruction":
        """Return controlled version."""
        raise NotImplementedError


@dataclass
class Gate(Instruction):
    """A quantum gate.

    Gates are unitary operations on qubits.
    """

    num_clbits: int = 0

    def to_matrix(self) -> np.ndarray:
        """Return unitary matrix representation."""
        raise NotImplementedError

    def inverse(self) -> "Gate":
        """Return inverse gate (conjugate transpose)."""
        matrix = self.to_matrix()
        inv_matrix = np.conj(matrix.T)
        return CustomGate(
            name=f"{self.name}_inv",
            num_qubits=self.num_qubits,
            matrix=inv_matrix,
        )

    def control(self, num_ctrl_qubits: int = 1) -> "ControlledGate":
        """Return controlled version of gate."""
        return ControlledGate(
            base_gate=self,
            num_ctrl_qubits=num_ctrl_qubits,
        )

    def power(self, exponent: float) -> "Gate":
        """Return gate raised to power."""
        matrix = self.to_matrix()
        w, v = np.linalg.eig(matrix)
        powered = v @ np.diag(w ** exponent) @ np.linalg.inv(v)
        return CustomGate(
            name=f"{self.name}^{exponent}",
            num_qubits=self.num_qubits,
            matrix=powered,
        )


@dataclass
class CustomGate(Gate):
    """Custom gate defined by matrix."""

    matrix: np.ndarray = field(default_factory=lambda: np.eye(2))

    def to_matrix(self) -> np.ndarray:
        return self.matrix


@dataclass
class ControlledGate(Gate):
    """A controlled gate."""

    base_gate: Gate = None
    num_ctrl_qubits: int = 1
    ctrl_state: Optional[str] = None

    def __post_init__(self):
        if self.base_gate:
            self.name = f"c{'c' * (self.num_ctrl_qubits - 1)}{self.base_gate.name}"
            self.num_qubits = self.base_gate.num_qubits + self.num_ctrl_qubits
            self.params = self.base_gate.params.copy()

    def to_matrix(self) -> np.ndarray:
        """Create controlled unitary matrix."""
        base_matrix = self.base_gate.to_matrix()
        base_dim = base_matrix.shape[0]
        ctrl_dim = 2 ** self.num_ctrl_qubits
        total_dim = ctrl_dim * base_dim

        result = np.eye(total_dim, dtype=complex)
        result[-base_dim:, -base_dim:] = base_matrix

        return result


@dataclass
class Measurement(Instruction):
    """Measurement operation."""

    name: str = "measure"
    num_qubits: int = 1
    num_clbits: int = 1
    basis: str = "z"

    def to_matrix(self) -> Tuple[np.ndarray, np.ndarray]:
        """Return measurement projectors."""
        if self.basis == "z":
            p0 = np.array([[1, 0], [0, 0]], dtype=complex)
            p1 = np.array([[0, 0], [0, 1]], dtype=complex)
        elif self.basis == "x":
            p0 = np.array([[0.5, 0.5], [0.5, 0.5]], dtype=complex)
            p1 = np.array([[0.5, -0.5], [-0.5, 0.5]], dtype=complex)
        elif self.basis == "y":
            p0 = np.array([[0.5, -0.5j], [0.5j, 0.5]], dtype=complex)
            p1 = np.array([[0.5, 0.5j], [-0.5j, 0.5]], dtype=complex)
        else:
            raise ValueError(f"Unknown measurement basis: {self.basis}")
        return p0, p1


@dataclass
class Barrier(Instruction):
    """Barrier instruction.

    Prevents gate reordering across barrier.
    """

    name: str = "barrier"
    num_qubits: int = 0
    num_clbits: int = 0


@dataclass
class Reset(Instruction):
    """Reset qubit to |0⟩ state."""

    name: str = "reset"
    num_qubits: int = 1
    num_clbits: int = 0


@dataclass
class Delay(Instruction):
    """Delay/idle operation."""

    name: str = "delay"
    num_qubits: int = 1
    duration: float = 0.0
    unit: str = "ns"


__all__ = [
    "Instruction",
    "Gate",
    "CustomGate",
    "ControlledGate",
    "Measurement",
    "Barrier",
    "Reset",
    "Delay",
]

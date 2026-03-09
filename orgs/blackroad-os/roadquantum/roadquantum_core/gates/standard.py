"""Standard quantum gates.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import cmath
import math
from dataclasses import dataclass

import numpy as np

from roadquantum_core.circuit.instruction import Gate


# Pauli gates
@dataclass
class XGate(Gate):
    """Pauli-X (NOT) gate.

    Matrix:
        [0, 1]
        [1, 0]

    |0⟩ → |1⟩
    |1⟩ → |0⟩
    """

    name: str = "x"
    num_qubits: int = 1

    def to_matrix(self) -> np.ndarray:
        return np.array([[0, 1], [1, 0]], dtype=complex)


@dataclass
class YGate(Gate):
    """Pauli-Y gate.

    Matrix:
        [0, -i]
        [i,  0]
    """

    name: str = "y"
    num_qubits: int = 1

    def to_matrix(self) -> np.ndarray:
        return np.array([[0, -1j], [1j, 0]], dtype=complex)


@dataclass
class ZGate(Gate):
    """Pauli-Z gate.

    Matrix:
        [1,  0]
        [0, -1]
    """

    name: str = "z"
    num_qubits: int = 1

    def to_matrix(self) -> np.ndarray:
        return np.array([[1, 0], [0, -1]], dtype=complex)


# Hadamard
@dataclass
class HGate(Gate):
    """Hadamard gate.

    Creates superposition:
    |0⟩ → (|0⟩ + |1⟩)/√2
    |1⟩ → (|0⟩ - |1⟩)/√2

    Matrix:
        [1,  1] / √2
        [1, -1]
    """

    name: str = "h"
    num_qubits: int = 1

    def to_matrix(self) -> np.ndarray:
        return np.array([[1, 1], [1, -1]], dtype=complex) / np.sqrt(2)


# Phase gates
@dataclass
class SGate(Gate):
    """S gate (sqrt(Z)).

    Matrix:
        [1, 0]
        [0, i]
    """

    name: str = "s"
    num_qubits: int = 1

    def to_matrix(self) -> np.ndarray:
        return np.array([[1, 0], [0, 1j]], dtype=complex)


@dataclass
class SdgGate(Gate):
    """S-dagger gate (inverse of S)."""

    name: str = "sdg"
    num_qubits: int = 1

    def to_matrix(self) -> np.ndarray:
        return np.array([[1, 0], [0, -1j]], dtype=complex)


@dataclass
class TGate(Gate):
    """T gate (sqrt(S)).

    Matrix:
        [1, 0]
        [0, e^(iπ/4)]
    """

    name: str = "t"
    num_qubits: int = 1

    def to_matrix(self) -> np.ndarray:
        return np.array([[1, 0], [0, cmath.exp(1j * math.pi / 4)]], dtype=complex)


@dataclass
class TdgGate(Gate):
    """T-dagger gate (inverse of T)."""

    name: str = "tdg"
    num_qubits: int = 1

    def to_matrix(self) -> np.ndarray:
        return np.array([[1, 0], [0, cmath.exp(-1j * math.pi / 4)]], dtype=complex)


# Two-qubit gates
@dataclass
class CXGate(Gate):
    """CNOT (controlled-X) gate.

    Matrix (4x4):
        [1, 0, 0, 0]
        [0, 1, 0, 0]
        [0, 0, 0, 1]
        [0, 0, 1, 0]
    """

    name: str = "cx"
    num_qubits: int = 2

    def to_matrix(self) -> np.ndarray:
        return np.array([
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 1],
            [0, 0, 1, 0],
        ], dtype=complex)


@dataclass
class CYGate(Gate):
    """Controlled-Y gate."""

    name: str = "cy"
    num_qubits: int = 2

    def to_matrix(self) -> np.ndarray:
        return np.array([
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 0, -1j],
            [0, 0, 1j, 0],
        ], dtype=complex)


@dataclass
class CZGate(Gate):
    """Controlled-Z gate."""

    name: str = "cz"
    num_qubits: int = 2

    def to_matrix(self) -> np.ndarray:
        return np.array([
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, -1],
        ], dtype=complex)


@dataclass
class SwapGate(Gate):
    """SWAP gate - exchanges two qubits."""

    name: str = "swap"
    num_qubits: int = 2

    def to_matrix(self) -> np.ndarray:
        return np.array([
            [1, 0, 0, 0],
            [0, 0, 1, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 1],
        ], dtype=complex)


@dataclass
class iSwapGate(Gate):
    """iSWAP gate."""

    name: str = "iswap"
    num_qubits: int = 2

    def to_matrix(self) -> np.ndarray:
        return np.array([
            [1, 0, 0, 0],
            [0, 0, 1j, 0],
            [0, 1j, 0, 0],
            [0, 0, 0, 1],
        ], dtype=complex)


# Three-qubit gates
@dataclass
class CCXGate(Gate):
    """Toffoli (CCX) gate - doubly-controlled NOT."""

    name: str = "ccx"
    num_qubits: int = 3

    def to_matrix(self) -> np.ndarray:
        matrix = np.eye(8, dtype=complex)
        matrix[6, 6] = 0
        matrix[6, 7] = 1
        matrix[7, 6] = 1
        matrix[7, 7] = 0
        return matrix


@dataclass
class CSwapGate(Gate):
    """Fredkin (CSWAP) gate - controlled SWAP."""

    name: str = "cswap"
    num_qubits: int = 3

    def to_matrix(self) -> np.ndarray:
        matrix = np.eye(8, dtype=complex)
        matrix[5, 5] = 0
        matrix[5, 6] = 1
        matrix[6, 5] = 1
        matrix[6, 6] = 0
        return matrix


# Gate constructors (aliases)
def H() -> HGate:
    return HGate()

def X() -> XGate:
    return XGate()

def Y() -> YGate:
    return YGate()

def Z() -> ZGate:
    return ZGate()

def S() -> SGate:
    return SGate()

def T() -> TGate:
    return TGate()

def CNOT() -> CXGate:
    return CXGate()

def CZ() -> CZGate:
    return CZGate()

def SWAP() -> SwapGate:
    return SwapGate()


__all__ = [
    "XGate", "YGate", "ZGate", "HGate",
    "SGate", "SdgGate", "TGate", "TdgGate",
    "CXGate", "CYGate", "CZGate", "SwapGate", "iSwapGate",
    "CCXGate", "CSwapGate",
    "H", "X", "Y", "Z", "S", "T", "CNOT", "CZ", "SWAP",
]

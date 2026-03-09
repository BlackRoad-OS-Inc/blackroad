"""Rotation gates.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import cmath
import math
from dataclasses import dataclass, field
from typing import List, Union

import numpy as np

from roadquantum_core.circuit.instruction import Gate
from roadquantum_core.circuit.parameter import Parameter


@dataclass
class RXGate(Gate):
    """Rotation around X-axis.

    RX(θ) = exp(-i * θ/2 * X)

    Matrix:
        [cos(θ/2),  -i*sin(θ/2)]
        [-i*sin(θ/2), cos(θ/2)]
    """

    name: str = "rx"
    num_qubits: int = 1
    params: List[Union[float, Parameter]] = field(default_factory=list)

    def __init__(self, theta: Union[float, Parameter]):
        self.name = "rx"
        self.num_qubits = 1
        self.params = [theta]

    def to_matrix(self) -> np.ndarray:
        theta = self.params[0]
        if isinstance(theta, Parameter):
            raise ValueError("Cannot create matrix with unbound parameter")

        c = math.cos(theta / 2)
        s = math.sin(theta / 2)
        return np.array([
            [c, -1j * s],
            [-1j * s, c],
        ], dtype=complex)


@dataclass
class RYGate(Gate):
    """Rotation around Y-axis.

    RY(θ) = exp(-i * θ/2 * Y)

    Matrix:
        [cos(θ/2),  -sin(θ/2)]
        [sin(θ/2),   cos(θ/2)]
    """

    name: str = "ry"
    num_qubits: int = 1
    params: List[Union[float, Parameter]] = field(default_factory=list)

    def __init__(self, theta: Union[float, Parameter]):
        self.name = "ry"
        self.num_qubits = 1
        self.params = [theta]

    def to_matrix(self) -> np.ndarray:
        theta = self.params[0]
        if isinstance(theta, Parameter):
            raise ValueError("Cannot create matrix with unbound parameter")

        c = math.cos(theta / 2)
        s = math.sin(theta / 2)
        return np.array([
            [c, -s],
            [s, c],
        ], dtype=complex)


@dataclass
class RZGate(Gate):
    """Rotation around Z-axis.

    RZ(θ) = exp(-i * θ/2 * Z)

    Matrix:
        [e^(-iθ/2),    0    ]
        [   0,     e^(iθ/2)]
    """

    name: str = "rz"
    num_qubits: int = 1
    params: List[Union[float, Parameter]] = field(default_factory=list)

    def __init__(self, theta: Union[float, Parameter]):
        self.name = "rz"
        self.num_qubits = 1
        self.params = [theta]

    def to_matrix(self) -> np.ndarray:
        theta = self.params[0]
        if isinstance(theta, Parameter):
            raise ValueError("Cannot create matrix with unbound parameter")

        return np.array([
            [cmath.exp(-1j * theta / 2), 0],
            [0, cmath.exp(1j * theta / 2)],
        ], dtype=complex)


@dataclass
class U1Gate(Gate):
    """Single-qubit phase gate.

    U1(λ) = diag(1, e^(iλ))
    """

    name: str = "u1"
    num_qubits: int = 1
    params: List[Union[float, Parameter]] = field(default_factory=list)

    def __init__(self, lam: Union[float, Parameter]):
        self.name = "u1"
        self.num_qubits = 1
        self.params = [lam]

    def to_matrix(self) -> np.ndarray:
        lam = self.params[0]
        if isinstance(lam, Parameter):
            raise ValueError("Cannot create matrix with unbound parameter")

        return np.array([
            [1, 0],
            [0, cmath.exp(1j * lam)],
        ], dtype=complex)


@dataclass
class U2Gate(Gate):
    """Single-qubit rotation gate with two parameters.

    U2(φ, λ) = U3(π/2, φ, λ)
    """

    name: str = "u2"
    num_qubits: int = 1
    params: List[Union[float, Parameter]] = field(default_factory=list)

    def __init__(self, phi: Union[float, Parameter], lam: Union[float, Parameter]):
        self.name = "u2"
        self.num_qubits = 1
        self.params = [phi, lam]

    def to_matrix(self) -> np.ndarray:
        phi, lam = self.params
        if isinstance(phi, Parameter) or isinstance(lam, Parameter):
            raise ValueError("Cannot create matrix with unbound parameter")

        return np.array([
            [1, -cmath.exp(1j * lam)],
            [cmath.exp(1j * phi), cmath.exp(1j * (phi + lam))],
        ], dtype=complex) / math.sqrt(2)


@dataclass
class U3Gate(Gate):
    """General single-qubit rotation gate.

    U3(θ, φ, λ) = [cos(θ/2),           -e^(iλ)sin(θ/2)      ]
                 [e^(iφ)sin(θ/2),  e^(i(φ+λ))cos(θ/2)]
    """

    name: str = "u3"
    num_qubits: int = 1
    params: List[Union[float, Parameter]] = field(default_factory=list)

    def __init__(
        self,
        theta: Union[float, Parameter],
        phi: Union[float, Parameter],
        lam: Union[float, Parameter],
    ):
        self.name = "u3"
        self.num_qubits = 1
        self.params = [theta, phi, lam]

    def to_matrix(self) -> np.ndarray:
        theta, phi, lam = self.params
        for p in [theta, phi, lam]:
            if isinstance(p, Parameter):
                raise ValueError("Cannot create matrix with unbound parameter")

        c = math.cos(theta / 2)
        s = math.sin(theta / 2)

        return np.array([
            [c, -cmath.exp(1j * lam) * s],
            [cmath.exp(1j * phi) * s, cmath.exp(1j * (phi + lam)) * c],
        ], dtype=complex)


# Alias for U3
class UGate(U3Gate):
    """General single-qubit rotation gate (alias for U3)."""
    pass


# Gate constructors
def RX(theta: Union[float, Parameter]) -> RXGate:
    return RXGate(theta)

def RY(theta: Union[float, Parameter]) -> RYGate:
    return RYGate(theta)

def RZ(theta: Union[float, Parameter]) -> RZGate:
    return RZGate(theta)

def U1(lam: Union[float, Parameter]) -> U1Gate:
    return U1Gate(lam)

def U2(phi: Union[float, Parameter], lam: Union[float, Parameter]) -> U2Gate:
    return U2Gate(phi, lam)

def U3(
    theta: Union[float, Parameter],
    phi: Union[float, Parameter],
    lam: Union[float, Parameter],
) -> U3Gate:
    return U3Gate(theta, phi, lam)


__all__ = [
    "RXGate", "RYGate", "RZGate",
    "U1Gate", "U2Gate", "U3Gate", "UGate",
    "RX", "RY", "RZ", "U1", "U2", "U3",
]

"""Quantum noise channels.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import math
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List, Tuple

import numpy as np


class NoiseChannel(ABC):
    """Abstract quantum noise channel.

    Noise channels are described by Kraus operators {K_i}
    such that Σ K_i† K_i = I.

    The channel acts as: ρ → Σ K_i ρ K_i†
    """

    @abstractmethod
    def kraus_operators(self) -> List[np.ndarray]:
        """Return Kraus operators."""
        pass

    def apply(self, rho: np.ndarray) -> np.ndarray:
        """Apply channel to density matrix."""
        result = np.zeros_like(rho)
        for K in self.kraus_operators():
            result += K @ rho @ K.conj().T
        return result


@dataclass
class DepolarizingChannel(NoiseChannel):
    """Depolarizing noise channel.

    With probability p, replaces state with maximally mixed state.

    ρ → (1-p)ρ + p/3(XρX + YρY + ZρZ)
    """

    probability: float = 0.01

    def kraus_operators(self) -> List[np.ndarray]:
        p = self.probability
        K0 = np.sqrt(1 - p) * np.eye(2, dtype=complex)
        K1 = np.sqrt(p / 3) * np.array([[0, 1], [1, 0]], dtype=complex)  # X
        K2 = np.sqrt(p / 3) * np.array([[0, -1j], [1j, 0]], dtype=complex)  # Y
        K3 = np.sqrt(p / 3) * np.array([[1, 0], [0, -1]], dtype=complex)  # Z
        return [K0, K1, K2, K3]


@dataclass
class BitFlipChannel(NoiseChannel):
    """Bit-flip noise channel.

    With probability p, applies X gate.

    ρ → (1-p)ρ + pXρX
    """

    probability: float = 0.01

    def kraus_operators(self) -> List[np.ndarray]:
        p = self.probability
        K0 = np.sqrt(1 - p) * np.eye(2, dtype=complex)
        K1 = np.sqrt(p) * np.array([[0, 1], [1, 0]], dtype=complex)
        return [K0, K1]


@dataclass
class PhaseFlipChannel(NoiseChannel):
    """Phase-flip noise channel.

    With probability p, applies Z gate.

    ρ → (1-p)ρ + pZρZ
    """

    probability: float = 0.01

    def kraus_operators(self) -> List[np.ndarray]:
        p = self.probability
        K0 = np.sqrt(1 - p) * np.eye(2, dtype=complex)
        K1 = np.sqrt(p) * np.array([[1, 0], [0, -1]], dtype=complex)
        return [K0, K1]


@dataclass
class AmplitudeDampingChannel(NoiseChannel):
    """Amplitude damping channel.

    Models energy relaxation (T1 decay).

    Kraus operators:
    K0 = [[1, 0], [0, sqrt(1-γ)]]
    K1 = [[0, sqrt(γ)], [0, 0]]
    """

    gamma: float = 0.01

    def kraus_operators(self) -> List[np.ndarray]:
        g = self.gamma
        K0 = np.array([[1, 0], [0, np.sqrt(1 - g)]], dtype=complex)
        K1 = np.array([[0, np.sqrt(g)], [0, 0]], dtype=complex)
        return [K0, K1]


@dataclass
class PhaseDampingChannel(NoiseChannel):
    """Phase damping channel.

    Models dephasing (T2 decay) without energy loss.

    Kraus operators:
    K0 = [[1, 0], [0, sqrt(1-λ)]]
    K1 = [[0, 0], [0, sqrt(λ)]]
    """

    lam: float = 0.01

    def kraus_operators(self) -> List[np.ndarray]:
        l = self.lam
        K0 = np.array([[1, 0], [0, np.sqrt(1 - l)]], dtype=complex)
        K1 = np.array([[0, 0], [0, np.sqrt(l)]], dtype=complex)
        return [K0, K1]


@dataclass
class ThermalRelaxationChannel(NoiseChannel):
    """Thermal relaxation channel.

    Combined T1 and T2 noise with temperature effects.
    """

    t1: float = 50e-6  # T1 time in seconds
    t2: float = 30e-6  # T2 time in seconds
    gate_time: float = 50e-9  # Gate time in seconds
    excited_state_population: float = 0.0

    def kraus_operators(self) -> List[np.ndarray]:
        t = self.gate_time

        p_reset = 1 - np.exp(-t / self.t1)
        p_z = 0.5 * (1 - np.exp(-t / self.t2) - p_reset / 2)

        p0 = 1 - self.excited_state_population
        p1 = self.excited_state_population

        K0 = np.sqrt(1 - p_reset - p_z) * np.eye(2, dtype=complex)
        K1 = np.sqrt(p_reset * p0) * np.array([[1, 0], [0, 0]], dtype=complex)
        K2 = np.sqrt(p_reset * p1) * np.array([[0, 0], [0, 1]], dtype=complex)
        K3 = np.sqrt(p_z) * np.array([[1, 0], [0, -1]], dtype=complex)

        return [K0, K1, K2, K3]


__all__ = [
    "NoiseChannel",
    "DepolarizingChannel",
    "BitFlipChannel",
    "PhaseFlipChannel",
    "AmplitudeDampingChannel",
    "PhaseDampingChannel",
    "ThermalRelaxationChannel",
]

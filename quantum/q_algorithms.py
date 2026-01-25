from __future__ import annotations
from dataclasses import dataclass
from typing import Tuple
import math
import cmath

@dataclass
class Qubit:
    """
    A simple representation of a qubit for algorithm demonstrations.

    Attributes
    ----------
    alpha : complex
        Amplitude of the |0> basis state.
    beta : complex
        Amplitude of the |1> basis state.
    """
    alpha: complex
    beta: complex

    def normalize(self) -> None:
        """
        Normalize the qubit so that |alpha|^2 + |beta|^2 = 1.
        """
        norm = math.sqrt(abs(self.alpha)**2 + abs(self.beta)**2)
        if norm == 0:
            raise ValueError("Cannot normalize a zero vector.")
        self.alpha /= norm
        self.beta /= norm


def hadamard(qubit: Qubit) -> Qubit:
    """
    Apply the Hadamard gate to a single qubit.

    The Hadamard transform creates superposition: H|0> = (|0> + |1>)/sqrt(2), H|1> = (|0> - |1>)/sqrt(2).

    Parameters
    ----------
    qubit : Qubit
        The input qubit to transform.

    Returns
    -------
    Qubit
        A new qubit after applying the Hadamard gate.
    """
    inv_sqrt2 = 1.0 / math.sqrt(2)
    new_alpha = inv_sqrt2 * (qubit.alpha + qubit.beta)
    new_beta = inv_sqrt2 * (qubit.alpha - qubit.beta)
    return Qubit(alpha=new_alpha, beta=new_beta)


def phase_shift(qubit: Qubit, theta: float) -> Qubit:
    """
    Apply a phase shift gate to the |1> component of a qubit.

    Parameters
    ----------
    qubit : Qubit
        The input qubit.
    theta : float
        Phase angle in radians.

    Returns
    -------
    Qubit
        A new qubit with the |1> component phase-shifted.
    """
    return Qubit(alpha=qubit.alpha, beta=qubit.beta * cmath.exp(1j * theta))


if __name__ == "__main__":
    # Example: apply Hadamard to |0> and then a phase shift of π/2
    q0 = Qubit(alpha=1+0j, beta=0+0j)
    hq = hadamard(q0)
    print("After Hadamard:", hq)
    pq = phase_shift(hq, math.pi / 2)
    print("After phase shift (\u03c0/2):", pq)

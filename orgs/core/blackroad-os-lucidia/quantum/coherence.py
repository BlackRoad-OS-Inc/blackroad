from __future__ import annotations
from dataclasses import dataclass

@dataclass
class QubitState:
    """
    Represents a single qubit state |psi> = alpha|0> + beta|1>.

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

        Raises
        ------
        ValueError
            If the norm is zero and normalization cannot be performed.
        """
        norm = (abs(self.alpha)**2 + abs(self.beta)**2) ** 0.5
        if norm == 0:
            raise ValueError("Norm is zero; cannot normalize.")
        self.alpha /= norm
        self.beta /= norm


def coherence_measure(state: QubitState) -> float:
    """
    Compute a simple coherence measure based on the off-diagonal terms of the density matrix.

    For a pure state, the magnitude of alpha*beta† is a proxy for superposition/coherence.

    Parameters
    ----------
    state : QubitState
        The qubit state for which to compute coherence.

    Returns
    -------
    float
        The magnitude of the product of alpha and the complex conjugate of beta.
    """
    return abs(state.alpha * state.beta.conjugate())


if __name__ == "__main__":
    # Demonstration of coherence measurement
    qubit = QubitState(alpha=1+0j, beta=1+0j)
    qubit.normalize()
    print("Normalized qubit:", qubit)
    print("Coherence:", coherence_measure(qubit))

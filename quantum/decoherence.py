from __future__ import annotations
from dataclasses import dataclass
from typing import List

@dataclass
class QuantumState:
    """
    Represents a single-qubit state with amplitudes for the |0> and |1> basis states.
    """
    alpha: complex
    beta: complex

    def apply_decoherence(self, rate: float) -> "QuantumState":
        """
        Apply a simple exponential decoherence to the amplitudes.

        Parameters
        ----------
        rate : float
            A value between 0 and 1 controlling how quickly coherence decays.

        Returns
        -------
        QuantumState
            A new state with scaled amplitudes.
        """
        # Ensure rate is within [0, 1]
        rate = max(0.0, min(1.0, rate))
        factor = (1.0 - rate) ** 0.5
        return QuantumState(alpha=self.alpha * factor, beta=self.beta * factor)


def simulate_decoherence(state: QuantumState, rate: float, steps: int) -> List[QuantumState]:
    """
    Simulate decoherence by repeatedly applying a decoherence model to a state.

    Parameters
    ----------
    state : QuantumState
        Initial qubit state.
    rate : float
        Decoherence rate between 0 and 1.
    steps : int
        Number of iterations to simulate.

    Returns
    -------
    List[QuantumState]
        Sequence of states after each step.
    """
    results: List[QuantumState] = []
    current = state
    for _ in range(steps):
        current = current.apply_decoherence(rate)
        results.append(current)
    return results


if __name__ == "__main__":
    # Demonstration: start in an equal superposition and simulate decoherence
    initial = QuantumState(alpha=1+0j, beta=1+0j)
    trajectory = simulate_decoherence(initial, rate=0.2, steps=5)
    for idx, st in enumerate(trajectory, 1):
        print(f"Step {idx}: {st}")

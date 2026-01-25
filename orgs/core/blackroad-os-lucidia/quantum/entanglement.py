from __future__ import annotations
from dataclasses import dataclass
import math
from typing import Tuple

@dataclass
class BellState:
    """
    Represents one of the four maximally entangled Bell states.

    Attributes
    ----------
    name : str
        A human-readable label for the Bell state (e.g., "Φ+", "Ψ-").
    coefficients : Tuple[complex, complex, complex, complex]
        The amplitudes for the computational basis |00>, |01>, |10>, |11>.
    """
    name: str
    coefficients: Tuple[complex, complex, complex, complex]

    def is_maximally_entangled(self) -> bool:
        """
        Determine whether this state is maximally entangled.

        For a Bell state, this checks that all nonzero coefficients have equal magnitude.

        Returns
        -------
        bool
            True if maximally entangled, False otherwise.
        """
        non_zero = [abs(c) for c in self.coefficients if c != 0]
        return len(non_zero) > 1 and len(set(non_zero)) == 1


def create_bell_state(index: int) -> BellState:
    """
    Factory function to construct one of the four standard Bell states.

    Parameters
    ----------
    index : int
        Index (0‑3) selecting among Φ+, Ψ+, Ψ-, Φ-.

    Returns
    -------
    BellState
        The requested Bell state.

    Raises
    ------
    ValueError
        If the index is not between 0 and 3.
    """
    inv_sqrt2 = 1 / math.sqrt(2)
    coeffs = {
        0: (inv_sqrt2, 0, 0, inv_sqrt2),        # Φ+
        1: (0, inv_sqrt2, inv_sqrt2, 0),        # Ψ+
        2: (0, inv_sqrt2, -inv_sqrt2, 0),       # Ψ-
        3: (inv_sqrt2, 0, 0, -inv_sqrt2),       # Φ-
    }
    names = ["Φ+", "Ψ+", "Ψ-", "Φ-"]
    if index not in coeffs:
        raise ValueError("index must be in range 0‑3 to select a Bell state")
    return BellState(name=names[index], coefficients=coeffs[index])


if __name__ == "__main__":
    # Example usage: create each Bell state and check entanglement
    for i in range(4):
        bell = create_bell_state(i)
        print(f"{bell.name}: coefficients = {bell.coefficients}, maximally entangled = {bell.is_maximally_entangled()}")

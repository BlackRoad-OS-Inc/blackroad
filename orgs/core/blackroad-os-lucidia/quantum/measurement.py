from __future__ import annotations
from dataclasses import dataclass
import random

@dataclass
class Qubit:
    """
    Represents a single qubit that can be measured in the computational basis.

    Attributes
    ----------
    alpha : complex
        Amplitude for the |0> state.
    beta : complex
        Amplitude for the |1> state.
    """
    alpha: complex
    beta: complex

    def measure(self) -> int:
        """
        Measure this qubit and collapse it to either |0> or |1>.

        The probability of obtaining 0 is |alpha|^2 and the probability of obtaining 1 is |beta|^2.
        After measurement, the qubit collapses to the observed basis state.

        Returns
        -------
        int
            0 if the outcome is |0>, 1 if the outcome is |1>.
        """
        p_zero = abs(self.alpha)**2
        rnd = random.random()
        if rnd < p_zero:
            # Collapse to |0>
            self.alpha, self.beta = 1+0j, 0+0j
            return 0
        else:
            # Collapse to |1>
            self.alpha, self.beta = 0+0j, 1+0j
            return 1


if __name__ == "__main__":
    # Demonstration: measure a qubit multiple times
    import math
    # Normalized state |psi> = sqrt(0.36)|0> + sqrt(0.64)|1>
    amp0 = math.sqrt(0.36)
    amp1 = math.sqrt(0.64)
    q = Qubit(alpha=amp0, beta=amp1)
    print("Measuring the qubit five times (state is reset each time):")
    for _ in range(5):
        q2 = Qubit(alpha=amp0, beta=amp1)
        print(q2.measure())

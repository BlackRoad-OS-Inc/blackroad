"""
Quantum Agent Module for Lucidia.

The QuantumAgent introduces randomness into decision processes, simulating
quantum superposition. It selects from a list of choices based on weights.
"""

from __future__ import annotations

from typing import Sequence
import random


class QuantumAgent:
    """
    A minimal agent that performs weighted random selections.

    The QuantumAgent exposes a superposition method that chooses a single
    option from a list of choices, proportional to provided weights.
    """

    def superposition(self, choices: Sequence[str], weights: Sequence[float]) -> str:
        """
        Select one choice from a sequence according to given weights.

        Args:
            choices: A sequence of option strings.
            weights: A sequence of positive weights corresponding to choices.

        Returns:
            A selected choice from the input sequence.
        """
        if not choices:
            raise ValueError("No choices provided.")
        if len(choices) != len(weights):
            raise ValueError("Choices and weights must be the same length.")
        return random.choices(list(choices), weights=weights, k=1)[0]

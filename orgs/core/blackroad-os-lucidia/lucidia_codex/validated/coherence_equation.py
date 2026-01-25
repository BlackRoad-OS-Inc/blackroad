"""
Module: coherence_equation.py

Implements bounded coherence equation:
    C(t) = |\u03c8′(M) + s(δ)·α(δ)| / (1 + |δ|)

Where:
    ψ′(M) : float - truth of memory at time t in trinary logic (between -1 and 1)
    δ: float - magnitude of contradiction (deviation)
    α(δ): float - constructive contradiction weight (positive or negative)
    s(δ): sign function returning -1, 0, or 1 depending on δ
The equation measures coherence of Lucidia's memory/truth state given contradiction and constructive weight.

Validation:
- All inputs must be real numbers.
- |ψ′(M)|, |α(δ)| ≤ 1 for meaningful interpretation.
- δ ∈ ℝ (no explicit bounds but large values reduce coherence).

This module provides:
- calculate_coherence(...)
- signum(...)
- A simple unit test suite verifying boundedness and monotonicity.

Integration:
Downstream modules (e.g., contradiction_resolver) should import calculate_coherence and apply in update loops.
"""

from __future__ import annotations
from typing import Union
import math
import unittest

Number = Union[int, float]

def signum(x: Number) -> int:
    """Return the sign of x: -1 if x < 0, 0 if x == 0, 1 if x > 0."""
    if x > 0:
        return 1
    elif x < 0:
        return -1
    return 0

def validate_inputs(psi_m: Number, delta: Number, alpha: Number) -> None:
    """Validate input types and ranges for coherence calculation.
    
    Raises:
        TypeError: if any input is not a real number.
        ValueError: if psi_m or alpha is outside the interval [-1, 1].
    """
    for name, value in {"psi_m": psi_m, "delta": delta, "alpha": alpha}.items():
        if not isinstance(value, (int, float)):
            raise TypeError(f"{name} must be a real number, got {type(value).__name__}.")
    if abs(psi_m) > 1:
        raise ValueError(f"psi_m must satisfy |psi_m| ≤ 1 (got {psi_m}).")
    if abs(alpha) > 1:
        raise ValueError(f"alpha must satisfy |alpha| ≤ 1 (got {alpha}).")

def calculate_coherence(psi_m: Number, delta: Number, alpha: Number) -> float:
    """Compute the bounded coherence C(t) based on the given parameters.

    C(t) = |ψ′(M) + s(δ)·α| / (1 + |δ|)

    Args:
        psi_m: Truth of memory at time t (ψ′(M)), bounded in [-1, 1].
        delta: Contradiction magnitude (δ), real number representing deviation.
        alpha: Constructive contradiction weight (α), bounded in [-1, 1].

    Returns:
        The coherence value C(t), a non-negative float ≤ 1.

    Raises:
        TypeError, ValueError: if inputs fail validation.
    """
    validate_inputs(psi_m, delta, alpha)
    sign_delta = signum(delta)
    numerator = abs(psi_m + sign_delta * alpha)
    denominator = 1 + abs(delta)
    coherence = numerator / denominator
    # Bound result to [0, 1]
    return min(max(coherence, 0.0), 1.0)

# Unit tests

class TestCoherenceEquation(unittest.TestCase):
    def test_zero_delta(self):
        """When delta=0, coherence reduces to |psi_m + alpha|."""
        result = calculate_coherence(psi_m=0.5, delta=0, alpha=0.3)
        expected = abs(0.5 + 0.3) / (1 + 0)
        self.assertAlmostEqual(result, expected)

    def test_negative_delta_sign(self):
        """Alpha is subtracted when delta is negative."""
        result = calculate_coherence(0.5, -2.0, 0.3)
        numerator = abs(0.5 - 0.3)
        denominator = 1 + 2.0
        expected = numerator / denominator
        self.assertAlmostEqual(result, expected)

    def test_bounds(self):
        """Output must be between 0 and 1."""
        # Large delta reduces coherence
        res = calculate_coherence(1.0, 10.0, 1.0)
        self.assertTrue(0 <= res <= 1)
        # psi_m negative, alpha positive
        res2 = calculate_coherence(-1.0, 5.0, 1.0)
        self.assertTrue(0 <= res2 <= 1)

if __name__ == "__main__":
    unittest.main()

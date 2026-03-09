"""Sine wave algebra and paradox testing."""
from __future__ import annotations

from dataclasses import dataclass
from typing import List

from .proofs import log_contradiction


@dataclass
class SineWave:
    amplitude: float
    frequency: float

    def __add__(self, other: "SineWave") -> "SineWave":
        if not isinstance(other, SineWave):
            return NotImplemented
        return SineWave(self.amplitude + other.amplitude, self.frequency)

    def __mul__(self, other: "SineWave") -> "SineWave":
        if not isinstance(other, SineWave):
            return NotImplemented
        return SineWave(self.amplitude * other.amplitude, self.frequency + other.frequency)

    def inverse(self) -> "SineWave":
        return SineWave(-self.amplitude, -self.frequency)


IDENTITY = SineWave(0.0, 0.0)


def test_properties(waves: List[SineWave]) -> None:
    """Test algebraic properties and log paradoxes if they fail."""

    a, b, c = waves[:3]
    if (a + b) + c != a + (b + c):
        log_contradiction("SineWave addition is not associative")
    if a + b != b + a:
        log_contradiction("SineWave addition is not commutative")
    if (a * b) * c != a * (b * c):
        log_contradiction("SineWave multiplication is not associative")
    if a * b != b * a:
        log_contradiction("SineWave multiplication is not commutative")
    if a * (b + c) != (a * b) + (a * c):
        log_contradiction("SineWave distributive law fails")


if __name__ == "__main__":
    waves = [SineWave(1, 1), SineWave(2, 3), SineWave(-1, -0.5)]
    test_properties(waves)
    print("Identity element:", IDENTITY)

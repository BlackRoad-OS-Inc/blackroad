"""Experimental number systems for the Lucidia Math Forge.

This module defines three playful number systems used by the Lucidia
Math Forge.  Each system implements basic arithmetic via operator
overloading so that instances behave a little like normal numbers.

The implementations are intentionally lightweight and educational rather
than mathematically rigorous.  They are meant to demonstrate how Python's
operator overloading can be used to explore alternative arithmetic.

Example
-------
>>> from numbers import SurrealNumber, Infinitesimal, WaveNumber
>>> SurrealNumber(1, 2) + SurrealNumber(3, 4)
SurrealNumber(left=4, right=6)
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Union

NumberLike = Union[float, int]


@dataclass
class SurrealNumber:
    """A toy representation of a surreal number.

    The number is represented by a left and right value.  Real surreal
    arithmetic is far richer; here we simply operate component-wise to
    keep the implementation approachable.
    """

    left: NumberLike
    right: NumberLike

    def __add__(self, other: "SurrealNumber") -> "SurrealNumber":
        if not isinstance(other, SurrealNumber):
            return NotImplemented
        return SurrealNumber(self.left + other.left, self.right + other.right)

    def __mul__(self, other: "SurrealNumber") -> "SurrealNumber":
        if not isinstance(other, SurrealNumber):
            return NotImplemented
        return SurrealNumber(self.left * other.left, self.right * other.right)

    def inverse(self) -> "SurrealNumber":
        return SurrealNumber(1 / self.left, 1 / self.right)


@dataclass
class Infinitesimal:
    """Numbers with an infinitesimal component.

    The value is ``real + eps * coefficient``.  Multiplication ignores
    ``eps^2`` terms, giving a tiny taste of differential arithmetic.
    """

    real: NumberLike
    eps: NumberLike = 0.0

    def __add__(self, other: "Infinitesimal") -> "Infinitesimal":
        if not isinstance(other, Infinitesimal):
            return NotImplemented
        return Infinitesimal(self.real + other.real, self.eps + other.eps)

    def __mul__(self, other: "Infinitesimal") -> "Infinitesimal":
        if not isinstance(other, Infinitesimal):
            return NotImplemented
        real = self.real * other.real
        eps = self.real * other.eps + self.eps * other.real
        return Infinitesimal(real, eps)

    def inverse(self) -> "Infinitesimal":
        return Infinitesimal(1 / self.real, -self.eps / (self.real**2))


@dataclass
class WaveNumber:
    """A number represented by a simple sine wave.

    ``amplitude`` scales the wave while ``frequency`` stretches it.  The
    operations below follow a loose physical intuition where addition
    combines amplitudes and multiplication combines frequencies.
    """

    amplitude: NumberLike
    frequency: NumberLike

    def __add__(self, other: "WaveNumber") -> "WaveNumber":
        if not isinstance(other, WaveNumber):
            return NotImplemented
        # Frequencies simply average to keep the result bounded.
        freq = (self.frequency + other.frequency) / 2
        return WaveNumber(self.amplitude + other.amplitude, freq)

    def __mul__(self, other: "WaveNumber") -> "WaveNumber":
        if not isinstance(other, WaveNumber):
            return NotImplemented
        amp = self.amplitude * other.amplitude
        freq = self.frequency + other.frequency
        return WaveNumber(amp, freq)

    def inverse(self) -> "WaveNumber":
        return WaveNumber(1 / self.amplitude, -self.frequency)


if __name__ == "__main__":
    # Demonstrate basic arithmetic for each number system.
    s_a = SurrealNumber(1, 2)
    s_b = SurrealNumber(3, 4)
    print("Surreal sample:", s_a + s_b, s_a * s_b, s_a.inverse())

    i_a = Infinitesimal(1, 1)
    i_b = Infinitesimal(2, -0.5)
    print("Infinitesimal sample:", i_a + i_b, i_a * i_b, i_a.inverse())

    w_a = WaveNumber(2, 1)
    w_b = WaveNumber(0.5, 3)
    print("Wave sample:", w_a + w_b, w_a * w_b, w_a.inverse())

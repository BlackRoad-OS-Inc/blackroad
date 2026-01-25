"""Vector mathematics helpers for Lucidia core."""

from __future__ import annotations

from dataclasses import dataclass
import math


@dataclass(frozen=True)
class Vector3:
    """Simple three dimensional vector with basic operations.

    The class implements common arithmetic needed across Lucidia projects
    without pulling in heavy numerical dependencies.  Only operations that are
    unambiguous for 3D vectors are provided.  Instances are immutable so they
    can be safely shared.
    """

    x: float
    y: float
    z: float

    def __add__(self, other: "Vector3") -> "Vector3":
        """Return the element-wise sum of two vectors."""
        return Vector3(self.x + other.x, self.y + other.y, self.z + other.z)

    def __sub__(self, other: "Vector3") -> "Vector3":
        """Return the element-wise difference of two vectors."""
        return Vector3(self.x - other.x, self.y - other.y, self.z - other.z)

    def __mul__(self, scalar: float) -> "Vector3":
        """Return the vector scaled by ``scalar``."""
        return Vector3(self.x * scalar, self.y * scalar, self.z * scalar)

    __rmul__ = __mul__

    def dot(self, other: "Vector3") -> float:
        """Return the dot product with ``other``."""
        return self.x * other.x + self.y * other.y + self.z * other.z

    def norm(self) -> float:
        """Return the Euclidean norm of the vector."""
        return math.sqrt(self.dot(self))

    def as_tuple(self) -> tuple[float, float, float]:
        """Return the vector components as a tuple."""
        return (self.x, self.y, self.z)


__all__ = ["Vector3"]

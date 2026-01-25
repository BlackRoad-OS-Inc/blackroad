"""Fractal generators for the Lucidia Math Forge.

The :func:`generate_fractal` function accepts a recursion rule and writes
a simple fractal image to disk.  Rules operate on complex numbers and
are intentionally simple to keep execution fast in constrained
environments.
"""
from __future__ import annotations

from typing import Callable

import matplotlib.pyplot as plt
import numpy as np


def julia_rule(z: complex, c: complex) -> complex:
    """Default Julia set rule ``z^2 + c``."""

    return z * z + c


def generate_fractal(
    rule: Callable[[complex, complex], complex] = julia_rule,
    filename: str = "fractal.png",
    iterations: int = 50,
    bounds=(-2.0, 2.0, -2.0, 2.0),
    resolution: int = 300,
) -> str:
    """Generate a fractal image using ``rule`` and save it to ``filename``."""

    xmin, xmax, ymin, ymax = bounds
    x = np.linspace(xmin, xmax, resolution)
    y = np.linspace(ymin, ymax, resolution)
    c = x[:, None] + 1j * y[None, :]
    z = np.zeros_like(c)
    mask = np.ones(c.shape, dtype=bool)

    for _ in range(iterations):
        z[mask] = rule(z[mask], c[mask])
        mask &= np.abs(z) < 2

    plt.imshow(mask.T, extent=bounds, cmap="magma")
    plt.axis("off")
    plt.savefig(filename, bbox_inches="tight", pad_inches=0)
    plt.close()
    return filename


if __name__ == "__main__":
    # Create a quick Julia set image.
    print("Saved fractal to", generate_fractal())

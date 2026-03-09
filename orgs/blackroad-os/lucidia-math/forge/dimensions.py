"""Simple higher-dimensional math utilities."""
from __future__ import annotations

from dataclasses import dataclass
from typing import List

import matplotlib.pyplot as plt
import numpy as np


def hyper_equation(x: float, y: float, z: float) -> float:
    """Example equation unique to 4D space: ``w = x * y * z``."""

    return x * y * z


@dataclass
class HyperPoint:
    coords: List[float]

    def project(self, dims: int = 3) -> List[float]:
        """Project the point onto the first ``dims`` axes."""

        return self.coords[:dims]


def plot_projection(points: List[HyperPoint], filename: str = "projection.png") -> str:
    """Project 4D points to 3D and plot them."""

    arr = np.array([p.project(3) for p in points])
    fig = plt.figure()
    ax = fig.add_subplot(111, projection="3d")
    ax.scatter(arr[:, 0], arr[:, 1], arr[:, 2])
    plt.savefig(filename)
    plt.close()
    return filename


if __name__ == "__main__":
    pts = [HyperPoint([x, x, x, hyper_equation(x, x, x)]) for x in range(3)]
    print("Saved projection to", plot_projection(pts))

"""Symbolic sine-wave superposition utilities."""

from __future__ import annotations

from typing import Iterable, Tuple

import matplotlib.pyplot as plt
import numpy as np

Wave = Tuple[float, float, float]  # frequency, phase, amplitude


def superposition(waves: Iterable[Wave], samples: int = 1000) -> Tuple[np.ndarray, np.ndarray]:
    """Compute the superposition of sine waves."""

    t = np.linspace(0, 2 * np.pi, samples)
    result = np.zeros_like(t)
    for freq, phase, amp in waves:
        result += amp * np.sin(freq * t + phase)
    return t, result


def classify_wave(value: float, eps: float = 1e-3) -> str:
    """Classify wave value into truth/false/paradox."""

    if value > eps:
        return "truth"
    if value < -eps:
        return "false"
    return "paradox"


def plot_waves(waves: Iterable[Wave]) -> plt.Figure:
    t, result = superposition(waves)
    fig, ax = plt.subplots()
    ax.plot(t, result)
    ax.set_title("Sine wave superposition")
    return fig

from __future__ import annotations

import numpy as np


def primes_upto(n: int) -> list[int]:
    """Return primes up to ``n`` using a vectorised sieve."""

    if n < 2:
        return []
    sieve = np.ones(n + 1, dtype=bool)
    sieve[:2] = False
    for p in range(2, int(np.sqrt(n)) + 1):
        if sieve[p]:
            sieve[p * p : n + 1 : p] = False
    return [i for i, v in enumerate(sieve) if v]


def l2_norm(x: np.ndarray) -> float:
    """Return the Euclidean norm of ``x``."""

    return float(np.sqrt((x * x).sum()))


def fft_mag(x: np.ndarray) -> np.ndarray:
    """Return the magnitude of the real FFT of ``x``."""

    fx = np.fft.rfft(x)
    return np.abs(fx)

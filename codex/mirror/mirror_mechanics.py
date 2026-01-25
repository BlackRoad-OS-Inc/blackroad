"""
mirror_mechanics.py

This module implements the mirror operator \u03a8' and breath operator \u2102
for the harmonic oscillator. It provides a basic demonstration of
oscillator dynamics and how positive and negative frequency components
are defined.

Functions:
    mirror_split(signal) -> (pos, neg)
    breath_step(q, p, omega=1.0, dt=0.01) -> (q_new, p_new)
    run_oscillator(steps=1000, dt=0.01, omega=1.0) -> (qs, ps)

Example:
    if __name__ == "__main__":
        qs, ps = run_oscillator()
        pos, neg = mirror_split(qs)
"""
import numpy as np
try:
    from scipy.signal import hilbert
except ImportError:
    hilbert = None

def mirror_split(signal: np.ndarray):
    """
    Split a real-valued signal into its positive and negative frequency components.

    Parameters
    ----------
    signal : np.ndarray
        Real-valued time series.

    Returns
    -------
    pos : np.ndarray
        The positive frequency component (analytic signal divided by 2).
    neg : np.ndarray
        The negative frequency component.
    """
    if hilbert is None:
        raise ImportError(
            "scipy is required for mirror_split; install scipy to use this function"
        )
    analytic = hilbert(signal)
    pos = analytic / 2.0
    neg = np.conj(analytic) - pos
    return pos, neg

def breath_step(q: float, p: float, omega: float = 1.0, dt: float = 0.01):
    """
    Perform a single leap-frog (symplectic) update for a harmonic oscillator.

    Parameters
    ----------
    q : float
        Position.
    p : float
        Momentum.
    omega : float, optional
        Oscillator frequency (default 1.0).
    dt : float, optional
        Time step (default 0.01).

    Returns
    -------
    q_new : float
        Updated position.
    p_new : float
        Updated momentum.
    """
    p_half = p - 0.5 * dt * (omega ** 2) * q
    q_new = q + dt * p_half
    p_new = p_half - 0.5 * dt * (omega ** 2) * q_new
    return q_new, p_new

def run_oscillator(steps: int = 1000, dt: float = 0.01, omega: float = 1.0):
    """
    Run a harmonic oscillator using the breath operator.

    Parameters
    ----------
    steps : int, optional
        Number of time steps (default 1000).
    dt : float, optional
        Time step (default 0.01).
    omega : float, optional
        Oscillator frequency (default 1.0).

    Returns
    -------
    qs : np.ndarray
        Array of positions over time.
    ps : np.ndarray
        Array of momenta over time.
    """
    q, p = 1.0, 0.0
    qs, ps = [], []
    for _ in range(steps):
        qs.append(q)
        ps.append(p)
        q, p = breath_step(q, p, omega, dt)
    return np.array(qs), np.array(ps)

if __name__ == "__main__":
    # Simple demonstration: simulate and split into mirror components
    qs, ps = run_oscillator(steps=1024, dt=0.01, omega=1.0)
    if hilbert is not None:
        pos, neg = mirror_split(qs)
        print(f"First few positive components: {pos[:5]}")
        print(f"First few negative components: {neg[:5]}")
    else:
        print("Scipy not installed; cannot compute mirror components.")

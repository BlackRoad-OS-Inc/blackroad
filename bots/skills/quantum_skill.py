from __future__ import annotations

import numpy as np

H = (1 / np.sqrt(2)) * np.array([[1, 1], [1, -1]], dtype=complex)
CNOT = np.array(
    [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1], [0, 0, 1, 0]],
    dtype=complex,
)


def bell_pair() -> np.ndarray:
    """Return a Bell pair state vector."""

    psi = np.zeros(4, dtype=complex)
    psi[0] = 1.0
    hi = np.kron(H, np.eye(2, dtype=complex))
    psi = hi @ psi
    psi = CNOT @ psi
    return psi


def qft_matrix(n: int) -> np.ndarray:
    """Return the Quantum Fourier Transform matrix for ``n`` qubits."""

    if n <= 0:
        raise ValueError("number of qubits must be positive")
    N = 2**n
    omega = np.exp(2j * np.pi / N)
    F = np.fromfunction(lambda j, k: omega ** (j * k) / np.sqrt(N), (N, N), dtype=int)
    return F

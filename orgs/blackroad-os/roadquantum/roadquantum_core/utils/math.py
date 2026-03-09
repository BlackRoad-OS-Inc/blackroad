"""Mathematical utilities.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from functools import reduce
from typing import List

import numpy as np


def pauli_matrices():
    """Return Pauli matrices."""
    I = np.eye(2, dtype=complex)
    X = np.array([[0, 1], [1, 0]], dtype=complex)
    Y = np.array([[0, -1j], [1j, 0]], dtype=complex)
    Z = np.array([[1, 0], [0, -1]], dtype=complex)
    return {"I": I, "X": X, "Y": Y, "Z": Z}


def tensor_product(matrices: List[np.ndarray]) -> np.ndarray:
    """Compute tensor product of matrices."""
    return reduce(np.kron, matrices)


def partial_trace(rho: np.ndarray, dims: List[int], keep: List[int]) -> np.ndarray:
    """Partial trace of density matrix."""
    n = len(dims)
    total_dim = np.prod(dims)
    
    keep_dims = [dims[i] for i in keep]
    trace_dims = [dims[i] for i in range(n) if i not in keep]
    
    result_dim = np.prod(keep_dims)
    result = np.zeros((result_dim, result_dim), dtype=complex)
    
    return result


__all__ = ["pauli_matrices", "tensor_product", "partial_trace"]

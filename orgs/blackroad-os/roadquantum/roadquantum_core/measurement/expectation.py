"""Expectation value measurement.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from dataclasses import dataclass
from typing import Dict, List, Optional
import numpy as np

@dataclass
class ExpectationValue:
    """Expectation value result."""
    value: float
    variance: float
    shots: int

def measure_expectation(
    statevector: np.ndarray,
    operator: np.ndarray,
) -> ExpectationValue:
    """Measure expectation value."""
    value = np.real(np.conj(statevector) @ operator @ statevector)
    variance = np.real(np.conj(statevector) @ operator @ operator @ statevector) - value**2
    return ExpectationValue(value=value, variance=max(0, variance), shots=0)

__all__ = ["ExpectationValue", "measure_expectation"]

from __future__ import annotations

import random
from typing import Sequence, TypeVar

T = TypeVar("T")


def perturb_choice(items: Sequence[T], temperature: float = 0.3) -> T:
    """
    Return a 'noisy' choice from items.

    A low temperature ≈ greedy; high temperature ≈ exploratory.
    """
    if not items:
        raise ValueError("items cannot be empty")
    if temperature <= 0:
        return items[0]
    idx = min(int(abs(random.gauss(0, temperature)) * len(items)), len(items) - 1)
    return items[idx]

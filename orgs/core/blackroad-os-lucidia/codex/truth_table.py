from __future__ import annotations

from enum import IntEnum
from typing import Tuple


class Truth(IntEnum):
    NEG = -1   # false/negative
    NEU = 0    # unknown/neutral
    POS = 1    # true/positive


def trinary_and(a: Truth, b: Truth) -> Truth:
    """Trinary AND is the minimum of the two values."""
    return Truth(min(int(a), int(b)))


def trinary_or(a: Truth, b: Truth) -> Truth:
    """Trinary OR is the maximum of the two values."""
    return Truth(max(int(a), int(b)))


def trinary_not(a: Truth) -> Truth:
    """Trinary NOT flips sign; NEU remains NEU."""
    if a == Truth.NEU:
        return Truth.NEU
    return Truth.POS if a == Truth.NEG else Truth.NEG


def compare(a: bool | None, b: bool | None) -> Tuple[Truth, str]:
    """
    Compare two booleans (or None) into trinary Truth with a short rationale.
    """
    mapping = {True: Truth.POS, False: Truth.NEG, None: Truth.NEU}
    ta, tb = mapping[a], mapping[b]
    if ta == tb:
        return ta, "same"
    # conflict detection
    if Truth.NEU in (ta, tb):
        return Truth.NEU, "one unknown"
    # one POS, one NEG
    return Truth.NEU, "contradiction"

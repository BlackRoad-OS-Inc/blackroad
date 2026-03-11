"""Lucidia - AI reasoning engines and utilities.

This package provides the ``lucidia`` namespace that exposes all root-level
modules (``quantum_engine``, ``quantum``, ``core``, agents, etc.) under the
``lucidia.*`` import path used throughout the codebase and tests.
"""

from __future__ import annotations

import os
import sys

# Ensure the repository root is on sys.path so the root-level agent
# modules (physicist, mathematician, chemist, …) are importable directly.
_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _root not in sys.path:
    sys.path.insert(0, _root)

try:
    from core import Vector3  # noqa: E402
    from harmony import HarmonyCoordinator, NodeProfile  # noqa: E402
    from rpg import Character, Game  # noqa: E402
except ImportError as _err:
    raise ImportError(
        f"Failed to import Lucidia root modules ({_err}). "
        "Ensure the repository root is on sys.path and that core.py, harmony.py, "
        "and rpg.py are present."
    ) from _err

__all__ = [
    "Character",
    "Game",
    "HarmonyCoordinator",
    "NodeProfile",
    "Vector3",
]

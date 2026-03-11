"""Lucidia engines and utilities."""

try:
    from .core import Vector3
    from .harmony import HarmonyCoordinator, NodeProfile
    from .rpg import Character, Game
except ImportError:
    # When running outside of package context (e.g. pytest collecting the
    # project root), relative imports are not available.
    pass

__all__ = ["Character", "Game", "Vector3", "HarmonyCoordinator", "NodeProfile"]

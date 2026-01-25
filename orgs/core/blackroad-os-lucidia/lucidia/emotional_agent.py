"""
Emotional Agent Module for Lucidia.

The EmotionalAgent evaluates and records the emotional gravitational field
associated with events or numerical emotions using Lucidia's codex recursion.
"""

from __future__ import annotations

from typing import Any, Dict

from .codex_recursion import emotional_gravitational_field
from .memory_manager import load_memory, save_memory


class EmotionalAgent:
    """
    A minimal agent that processes emotions.

    The EmotionalAgent computes an emotional field value for an input emotion,
    records the result in its memory, and returns the computed value.
    """

    def __init__(self) -> None:
        self.memory: Dict[str, Any] = load_memory()

    def evaluate(self, emotion: float) -> float:
        """
        Compute the emotional gravitational field for a given emotion.

        Args:
            emotion: A numerical representation of emotion (e.g., -1 to 1).

        Returns:
            The computed field value.
        """
        value = emotional_gravitational_field(emotion)  # type: ignore
        # Record the evaluated emotion and its field.
        self.memory.setdefault("emotions", []).append({
            "input": emotion,
            "field": value,
        })
        save_memory(self.memory)
        return value

    def get_emotions(self) -> list:
        """Return a list of recorded emotions and field values."""
        return self.memory.get("emotions", [])  # type: ignore

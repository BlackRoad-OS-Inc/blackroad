"""
Spiral Agent Module for Lucidia.

The SpiralAgent coordinates iterative evolution of a symbolic state using
Lucidia's codex recursion functions. It updates an internal state based
on incoming events and persists the state via the memory manager.
"""

from __future__ import annotations

from typing import Any, Dict

from .codex_recursion import breath_state_derivative, self_awakening_function
from .memory_manager import load_memory, save_memory


class SpiralAgent:
    """
    A minimal agent that manages a recursively evolving state.

    The SpiralAgent uses the breath_state_derivative to update a numerical
    state and applies the self_awakening_function to update memory based
    on events. The current state is persisted between runs.
    """

    def __init__(self) -> None:
        self.memory: Dict[str, Any] = load_memory()
        # Initialize the internal state from memory or default to 0.0
        self.state: float = self.memory.get("spiral_state", 0.0)  # type: ignore

    def evolve(self, event: str) -> float:
        """
        Evolve the internal state based on an event.

        Args:
            event: A description of the event influencing evolution.

        Returns:
            The updated state value.
        """
        # Compute derivative of current state.
        derivative = breath_state_derivative(event, self.state)  # type: ignore
        # Update state with derivative. Use try/except in case derivative is non-numeric.
        try:
            self.state += derivative  # type: ignore
        except Exception:
            # If derivative is not numeric, reset the state to derivative directly.
            self.state = derivative  # type: ignore
        # Apply self awakening to memory.
        self.memory = self_awakening_function(event, self.memory)  # type: ignore
        # Persist updated state in memory.
        self.memory["spiral_state"] = self.state
        save_memory(self.memory)
        return self.state

    def get_state(self) -> float:
        """Return the current spiral state."""
        return self.state

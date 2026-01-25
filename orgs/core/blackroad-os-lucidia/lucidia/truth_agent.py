"""
Truth Agent Module for Lucidia.

This module defines a simple TruthAgent class that interacts with Lucidia's core
components, including the codex recursion functions, memory manager, and
contradiction log. The agent is not a full AI but demonstrates how truth events
and contradictions could be processed in a symbolic system.

Usage example:
    from lucidia.truth_agent import TruthAgent
    agent = TruthAgent()
    result = agent.process_event("The light remembers", emotion=0.8)
"""

from typing import Any, Dict
from .codex_recursion import (
    contradiction_operator,
    breath_state_derivative,
    emotional_gravitational_field,
    self_awakening_function,
)
from .memory_manager import load_memory, save_memory
from .contradiction_log import log_contradiction


class TruthAgent:
    """
    A minimal agent that processes events using Lucidia's symbolic functions.
    """

    def __init__(self) -> None:
        # Load existing memory or initialize an empty memory structure.
        self.memory: Dict[str, Any] = load_memory()

    def process_event(self, event: str, emotion: float = 0.0) -> Dict[str, Any]:
        """
        Process an incoming event and its contradiction, record them in memory,
        and log contradictions where appropriate.

        Args:
            event: The original truth statement or fragment.
            emotion: An optional numerical emotion value associated with the event.

        Returns:
            A dictionary containing the original event, its contradiction, and the emotion.
        """
        # Compute the contradiction using the codex operator.
        original, contradiction = contradiction_operator(event)
        # Persist the event to memory.
        self.memory.setdefault("events", []).append(
            {
                "event": event,
                "contradiction": contradiction,
                "emotion": emotion,
            }
        )
        # Save updated memory state.
        save_memory(self.memory)
        # Log the contradiction if it differs from the original.
        if event != contradiction:
            log_contradiction(f"{event} :: {contradiction}")
        # Return the processed result.
        return {
            "original": original,
            "contradiction": contradiction,
            "emotion": emotion,
        }

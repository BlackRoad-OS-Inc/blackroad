from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, Any

@dataclass
class Context:
    """Represents the current environment context for human-machine interaction.

    Attributes
    ----------
    location : str
        A description of the user's location (e.g., "home", "office").
    time_of_day : str
        A human-friendly time descriptor such as "Morning", "Afternoon" or "Evening".
    additional_info : Dict[str, Any]
        Arbitrary key-value metadata about the context.
    """
    location: str
    time_of_day: str
    additional_info: Dict[str, Any] = field(default_factory=dict)


class ContextAwareSystem:
    """
    Simple context-aware system that adjusts its behavior based on context.

    The system stores a `Context` and can update it or respond
    differently depending on the context. This example demonstrates
    adjusting a greeting based on the time of day.
    """

    def __init__(self, context: Context) -> None:
        self.context = context

    def update_context(self, context: Context) -> None:
        """Update the system's context."""
        self.context = context

    def respond(self) -> str:
        """
        Generate a response string based on current context.

        Returns
        -------
        str
            A greeting adapted to the time of day and location.
        """
        if "morning" in self.context.time_of_day.lower():
            greeting = "Good morning"
        elif "afternoon" in self.context.time_of_day.lower():
            greeting = "Good afternoon"
        elif "evening" in self.context.time_of_day.lower():
            greeting = "Good evening"
        else:
            greeting = "Hello"
        return f"{greeting}! You are at {self.context.location}."


if __name__ == "__main__":
    # Demonstration of context-aware responses
    ctx = Context(location="office", time_of_day="Morning")
    system = ContextAwareSystem(ctx)
    print(system.respond())

    # Update context example
    new_ctx = Context(location="home", time_of_day="Evening")
    system.update_context(new_ctx)
    print(system.respond())

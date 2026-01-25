from __future__ import annotations

from dataclasses import dataclass
from typing import List, Callable, Any


@dataclass
class ProtocolStep:
    """Represents a single step in a collaboration protocol.

    Attributes
    ----------
    order : int
        The execution order of the step (lower numbers run first).
    description : str
        A short description of the step's purpose.
    action : Callable[[], Any]
        A callable to execute for this step.
    """
    order: int
    description: str
    action: Callable[[], Any] = lambda: None


class CollaborationProtocol:
    """
    Defines an ordered set of steps for human-machine collaboration.

    Steps can be added with arbitrary order values and will be
    executed in ascending order of `order`.
    """

    def __init__(self) -> None:
        self.steps: List[ProtocolStep] = []

    def add_step(self, step: ProtocolStep) -> None:
        """Add a protocol step and maintain proper ordering."""
        self.steps.append(step)
        self.steps.sort(key=lambda s: s.order)

    def execute(self) -> List[Any]:
        """
        Execute each protocol step's action in order.

        Returns
        -------
        List[Any]
            A list of return values from each step's action.
        """
        results: List[Any] = []
        for step in self.steps:
            results.append(step.action())
        return results


if __name__ == "__main__":
    # Demonstration of a simple collaboration protocol
    proto = CollaborationProtocol()
    # Add steps out of order; sorting ensures correct execution order
    proto.add_step(ProtocolStep(2, "Process input", action=lambda: "Processing done"))
    proto.add_step(ProtocolStep(1, "Greet user", action=lambda: "Hello!"))
    proto.add_step(ProtocolStep(3, "Say goodbye", action=lambda: "Goodbye!"))

    outputs = proto.execute()
    print(outputs)

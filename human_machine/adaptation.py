from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Any, List

@dataclass
class AdaptationRule:
    """Represents a single adaptation rule for human-machine interaction.

    Attributes
    ----------
    condition : Callable[[Any], bool]
        A predicate that determines whether the rule should fire for a given state.
    action : Callable[[Any], Any]
        A transformation to apply when the condition is met.
    description : str
        Human-friendly summary of the rule's purpose.
    """
    condition: Callable[[Any], bool]
    action: Callable[[Any], Any]
    description: str = ""


class AdaptiveSystem:
    """
    Framework for applying adaptation rules based on conditions.

    This simple system iterates through registered rules and applies the
    action for the first rule whose condition is true. If no rule
    matches, it returns the state unchanged.
    """

    def __init__(self) -> None:
        self.rules: List[AdaptationRule] = []

    def add_rule(self, rule: AdaptationRule) -> None:
        """Register a new adaptation rule."""
        self.rules.append(rule)

    def adapt(self, state: Any) -> Any:
        """
        Apply the first matching adaptation rule to the given state.

        Parameters
        ----------
        state : Any
            The current state or input value to adapt.

        Returns
        -------
        Any
            The adapted state if a rule matched, otherwise the original state.
        """
        for rule in self.rules:
            if rule.condition(state):
                return rule.action(state)
        return state


if __name__ == "__main__":
    # Example: adapt temperature values to a comfortable range
    adapt_sys = AdaptiveSystem()

    def too_cold(x: float) -> bool:
        return x < 20

    def warm_action(x: float) -> float:
        return x + 5

    def too_hot(x: float) -> bool:
        return x > 25

    def cool_action(x: float) -> float:
        return x - 5

    adapt_sys.add_rule(AdaptationRule(too_cold, warm_action, "Warm up if too cold"))
    adapt_sys.add_rule(AdaptationRule(too_hot, cool_action, "Cool down if too hot"))

    temps = [18.0, 22.0, 28.0]
    for t in temps:
        print(f"{t} -> {adapt_sys.adapt(t)}")

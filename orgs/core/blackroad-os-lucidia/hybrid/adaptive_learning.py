from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Any, Dict, List

@dataclass
class AdaptationRule:
    """
    Represents an adaptation rule with a trigger condition and action transformation.
    """
    trigger: Callable[[Dict[str, Any]], bool]
    action: Callable[[Dict[str, Any]], Dict[str, Any]]

class AdaptiveLearner:
    """Applies adaptation rules to a context."""

    def __init__(self) -> None:
        self.rules: List[AdaptationRule] = []

    def add_rule(self, rule: AdaptationRule) -> None:
        """
        Register a new adaptation rule.
        """
        self.rules.append(rule)

    def adapt(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Apply the first rule whose trigger matches the context and return the modified context.
        If no rule triggers, return the context unchanged.
        """
        for rule in self.rules:
            if rule.trigger(context):
                return rule.action(context)
        return context

if __name__ == "__main__":
    learner = AdaptiveLearner()
    learner.add_rule(
        AdaptationRule(
            trigger=lambda c: c.get("state") == "stuck",
            action=lambda c: {**c, "assist": True},
        )
    )
    print(learner.adapt({"state": "stuck"}))

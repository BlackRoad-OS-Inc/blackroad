from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Any, Callable, Optional


@dataclass
class Decision:
    """Represents a decision with a set of options and a selected recommendation.

    Attributes
    ----------
    options : Dict[str, Any]
        A mapping of option names to their underlying values.
    recommendation : Optional[str]
        The name of the option that is currently recommended. None if no
        recommendation is available.
    """
    options: Dict[str, Any]
    recommendation: Optional[str] = None


class DecisionSupport:
    """
    Simple decision support system that ranks options based on a scoring function.

    A `scorer` callable is provided to map option values to numeric scores. The
    `evaluate` method selects the option with the highest score.
    """

    def __init__(self, scorer: Callable[[Any], float]) -> None:
        self.scorer = scorer

    def evaluate(self, options: Dict[str, Any]) -> Decision:
        """
        Evaluate and recommend the option with the highest score.

        Parameters
        ----------
        options : Dict[str, Any]
            A mapping from option names to their raw values.

        Returns
        -------
        Decision
            A Decision object containing the original options and the recommended key.
        """
        if not options:
            return Decision(options, None)
        scores = {name: self.scorer(val) for name, val in options.items()}
        best = max(scores, key=scores.get)
        return Decision(options, best)


if __name__ == "__main__":
    # Example: choose the largest number
    def identity_score(x: float) -> float:
        return x

    ds = DecisionSupport(identity_score)
    opts = {"A": 0.5, "B": 0.8, "C": 0.3}
    result = ds.evaluate(opts)
    print("Recommendation:", result.recommendation)

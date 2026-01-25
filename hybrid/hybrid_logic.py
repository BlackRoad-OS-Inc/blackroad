from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, List


@dataclass
class LogicUnit:
    """
    Represents a discrete logic expression with its source.

    Attributes
    ----------
    source : str
        Identifier of the source (e.g., "human", "ai").
    expression : str
        The logic expression to be evaluated.
    """
    source: str
    expression: str


class HybridLogic:
    """
    Container for mixed human/AI logic expressions and evaluator dispatch.
    """
    def __init__(self) -> None:
        self.units: List[LogicUnit] = []

    def add_unit(self, unit: LogicUnit) -> None:
        """Add a LogicUnit to the collection."""
        self.units.append(unit)

    def evaluate(self, evaluator: Callable[[str], Any]) -> List[Any]:
        """
        Evaluate each logic unit using the provided evaluator function.

        Parameters
        ----------
        evaluator : Callable[[str], Any]
            A function that takes an expression string and returns its evaluation.

        Returns
        -------
        List[Any]
            The result of evaluating each expression in order.
        """
        results: List[Any] = []
        for unit in self.units:
            try:
                results.append(evaluator(unit.expression))
            except Exception as e:
                results.append(e)
        return results


if __name__ == "__main__":
    hybrid = HybridLogic()
    hybrid.add_unit(LogicUnit("human", "2 + 2"))
    hybrid.add_unit(LogicUnit("ai", "len('lucidia')"))

    # Caution: using eval for demonstration; in practice, use a safe parser/evaluator.
    print(hybrid.evaluate(eval))

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, Dict, List


@dataclass
class CognitiveModel:
    """Represents a cognitive model (human or machine).

    Attributes
    ----------
    name : str
        Unique identifier for the model.
    process : Callable[[Any], Any]
        A function that transforms input data into an output.
    description : str
        Human-readable explanation of what the model does.
    """
    name: str
    process: Callable[[Any], Any]
    description: str = ""


class CognitionIntegrator:
    """
    Integrates multiple cognitive models by aggregating their outputs.

    The integrator stores a list of cognitive models and can invoke
    each model's `process` function to produce a combined result.
    """

    def __init__(self) -> None:
        self.models: List[CognitiveModel] = []

    def register(self, model: CognitiveModel) -> None:
        """Register a new cognitive model for integration."""
        self.models.append(model)

    def integrate(self, input_data: Any) -> Dict[str, Any]:
        """
        Run all registered models on the input data.

        Parameters
        ----------
        input_data : Any
            The input value to provide to each model.

        Returns
        -------
        Dict[str, Any]
            A mapping of model names to their respective outputs.
        """
        outputs: Dict[str, Any] = {}
        for model in self.models:
            outputs[model.name] = model.process(input_data)
        return outputs


if __name__ == "__main__":
    # Demonstrate integrating two simple cognitive models
    def to_upper(text: str) -> str:
        return text.upper()

    def count_chars(text: str) -> int:
        return len(text)

    integrator = CognitionIntegrator()
    integrator.register(CognitiveModel("upper_case", to_upper, "Convert text to uppercase"))
    integrator.register(CognitiveModel("char_count", count_chars, "Count characters in text"))

    result = integrator.integrate("Lucidia")
    print(result)

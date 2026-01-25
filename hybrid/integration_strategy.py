from __future__ import annotations

from dataclasses import dataclass
from typing import List

@dataclass
class IntegrationPlan:
    """Plan for integrating human and AI outputs."""
    steps: List[str]
    rationale: str

class IntegrationStrategy:
    """Strategies for integrating human feedback with AI-generated results."""
    def create_plan(self, human_inputs: List[str], ai_outputs: List[str]) -> IntegrationPlan:
        """
        Construct a simple integration plan by sequencing human inputs followed by AI outputs.

        Parameters
        ----------
        human_inputs : List[str]
            A list of human-provided insights.
        ai_outputs : List[str]
            A list of AI-generated suggestions.

        Returns
        -------
        IntegrationPlan
            The plan containing ordered steps and a rationale.
        """
        steps: List[str] = []
        for i, text in enumerate(human_inputs):
            steps.append(f"Incorporate human insight {i+1}: {text}")
        for i, text in enumerate(ai_outputs):
            steps.append(f"Incorporate AI suggestion {i+1}: {text}")
        rationale = "Merge human insight with AI suggestions sequentially."
        return IntegrationPlan(steps, rationale)


if __name__ == "__main__":
    strategy = IntegrationStrategy()
    plan = strategy.create_plan(["increase transparency"], ["optimize resource use"])
    print(plan)

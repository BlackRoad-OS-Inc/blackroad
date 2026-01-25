from __future__ import annotations

from dataclasses import dataclass
from typing import Dict

@dataclass
class TrustModel:
    """
    Represents a trust score for a user.

    Attributes
    ----------
    user_id : str
        Identifier for the user.
    score : float
        The accumulated trust score.
    """
    user_id: str
    score: float = 0.0

class TrustEvaluator:
    """
    Maintains and updates trust scores for users based on interactions.
    """
    def __init__(self) -> None:
        self._models: Dict[str, TrustModel] = {}

    def update(self, user_id: str, delta: float) -> TrustModel:
        """
        Update the trust score for a user.

        Parameters
        ----------
        user_id : str
            Identifier for the user.
        delta : float
            Amount to adjust the trust score (positive or negative).

        Returns
        -------
        TrustModel
            The updated trust model for the user.
        """
        model = self._models.get(user_id)
        if model is None:
            model = TrustModel(user_id=user_id)
            self._models[user_id] = model
        model.score += delta
        return model

    def get_score(self, user_id: str) -> float:
        """Return the current trust score for the given user."""
        return self._models.get(user_id, TrustModel(user_id)).score

if __name__ == "__main__":
    evaluator = TrustEvaluator()
    evaluator.update("alice", 0.5)
    evaluator.update("bob", -0.3)
    evaluator.update("alice", 0.2)
    print(evaluator.get_score("alice"))
    print(evaluator.get_score("bob"))

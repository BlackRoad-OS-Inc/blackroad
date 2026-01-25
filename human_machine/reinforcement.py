from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Tuple
import random

@dataclass
class ReinforcementAgent:
    """
    A simple reinforcement learning agent using tabular Q-learning.

    Attributes
    ----------
    q_values : Dict[Tuple[str, str], float]
        Q-value table mapping (state, action) pairs to their value estimates.
    """
    q_values: Dict[Tuple[str, str], float] = field(default_factory=dict)

    def update(self, state: str, action: str, reward: float, alpha: float = 0.1) -> None:
        """
        Update the Q-value for a state-action pair.

        Parameters
        ----------
        state : str
            Current state identifier.
        action : str
            Action taken in the state.
        reward : float
            Reward received for this state-action.
        alpha : float, default 0.1
            Learning rate.
        """
        key = (state, action)
        old = self.q_values.get(key, 0.0)
        self.q_values[key] = old + alpha * (reward - old)

    def choose_action(self, state: str, actions: List[str], epsilon: float = 0.2) -> str:
        """
        Choose an action using an epsilon-greedy policy.

        Parameters
        ----------
        state : str
            Current state identifier.
        actions : List[str]
            Available actions.
        epsilon : float
            Exploration rate.

        Returns
        -------
        str
            Selected action.
        """
        if not actions:
            raise ValueError("actions list cannot be empty")
        if random.random() < epsilon:
            return random.choice(actions)
        # choose action with highest Q-value
        return max(actions, key=lambda a: self.q_values.get((state, a), 0.0))

if __name__ == "__main__":
    agent = ReinforcementAgent()
    state = "home"
    actions = ["explore", "rest"]
    chosen = agent.choose_action(state, actions)
    agent.update(state, chosen, reward=1.0)
    print(agent.q_values)

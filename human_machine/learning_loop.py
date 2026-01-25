from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, List

@dataclass
class LearningCycle:
    """
    Represents a single learning cycle iteration.

    Attributes
    ----------
    iteration : int
        The iteration number (starting from 1).
    state : Any
        The state after the update function is applied.
    reward : float
        The reward computed for this cycle.
    """
    iteration: int
    state: Any
    reward: float

class LearningLoop:
    """
    Executes an iterative learning loop with update and reward functions.
    """
    def __init__(self, update_fn: Callable[[Any], Any], reward_fn: Callable[[Any], float], max_iter: int = 5) -> None:
        self.update_fn = update_fn
        self.reward_fn = reward_fn
        self.max_iter = max_iter

    def run(self, initial_state: Any) -> List[LearningCycle]:
        """
        Run the learning loop over a number of iterations.

        Parameters
        ----------
        initial_state : Any
            The starting state for the learning process.

        Returns
        -------
        List[LearningCycle]
            A list of learning cycles capturing state and reward at each step.
        """
        cycles: List[LearningCycle] = []
        state = initial_state
        for i in range(1, self.max_iter + 1):
            state = self.update_fn(state)
            reward = self.reward_fn(state)
            cycles.append(LearningCycle(i, state, reward))
        return cycles

if __name__ == "__main__":
    # Example usage: increment state and reward as negative distance from target 10
    loop = LearningLoop(lambda x: x + 1, lambda x: -abs(10 - x), max_iter=3)
    for cycle in loop.run(0):
        print(cycle)

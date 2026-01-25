"""
Substrate Performance Optimizer
===============================

This module provides a utility function for selecting the optimal computation
substrate (e.g. chemical, quantum, electronic) for a given task based on
measurable factors like energy consumption, computation time and switching
penalties. The selection algorithm is intentionally simple and transparent
to allow empirical tuning and validation. It should be treated as an
initial hypothesis rather than a definitive model.

The optimizer uses a multi-objective cost function inspired by the
Multi‑Substrate Optimization Principle described in the discussion of
universal computing foundations. Each substrate's cost is calculated as the
product of its energy and time requirements, scaled by a penalty for
switching between substrates. The substrate with the lowest cost is
selected as the optimal choice for the current task.

Example usage::

    from substrate_performance_optimizer import optimize_substrate_selection

    task_profile = {"complexity": 0.9, "real_time": 0.4}
    energy_costs = {"chemical": 1.2, "quantum": 0.7, "electronic": 1.0}
    time_costs = {"chemical": 2.0, "quantum": 1.1, "electronic": 1.3}
    switching_penalties = {"chemical": 0.4, "quantum": 0.2, "electronic": 0.1}

    best_substrate, cost = optimize_substrate_selection(
        task_profile,
        energy_costs,
        time_costs,
        switching_penalties,
        lambda_weight=0.5,
    )
    print(f"Best substrate: {best_substrate}, cost: {cost:.3f}")

Future work could integrate more sophisticated task profiling, uncertainty
quantification, and empirical data-driven calibration of the cost function.
"""

from typing import Dict, Tuple


def optimize_substrate_selection(
    task_profile: Dict[str, float],
    energy_costs: Dict[str, float],
    time_costs: Dict[str, float],
    switching_penalties: Dict[str, float],
    lambda_weight: float = 0.5,
) -> Tuple[str, float]:
    """Select the optimal substrate for a given task based on cost metrics.

    The optimizer computes a cost for each substrate using the formula::

        cost = energy_cost * time_cost * (1 + lambda_weight * switch_penalty)

    The substrate with the minimum cost is returned along with its cost.

    Parameters
    ----------
    task_profile : Dict[str, float]
        Characteristics of the task. Currently unused but reserved for
        future extensions when task complexity affects substrate selection.
    energy_costs : Dict[str, float]
        Mapping from substrate names to their relative energy consumption for
        the task. Values should be positive floats.
    time_costs : Dict[str, float]
        Mapping from substrate names to their relative time requirements for
        the task. Values should be positive floats.
    switching_penalties : Dict[str, float]
        Mapping from substrate names to the penalty incurred when switching
        to that substrate. Larger values discourage switching.
    lambda_weight : float, optional
        Weight applied to the switching penalty. Defaults to 0.5.

    Returns
    -------
    Tuple[str, float]
        A tuple containing the name of the selected substrate and its
        calculated cost.
    """
    scores: Dict[str, float] = {}
    for substrate in energy_costs:
        # Retrieve metrics, defaulting to 1.0 for missing entries
        energy = energy_costs.get(substrate, 1.0)
        time = time_costs.get(substrate, 1.0)
        switch_penalty = switching_penalties.get(substrate, 1.0)
        # Compute cost based on energy, time, and switching penalty
        cost = energy * time * (1 + lambda_weight * switch_penalty)
        scores[substrate] = cost

    # Determine the substrate with the minimum cost
    best_substrate = min(scores, key=scores.get)
    return best_substrate, scores[best_substrate]
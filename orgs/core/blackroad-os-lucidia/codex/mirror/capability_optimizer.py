"""
Capability Optimizer for Mirror Engine.

This script performs a simple random search over mirror engine parameters to maximise capability
defined as the harmonic mean of reach and stability. It leverages the run_mirror_engine function
from mirror_engine.py and summarises results.
"""
import numpy as np
import random
from mirror_engine import run_mirror_engine

def evaluate_params(params):
    history = run_mirror_engine(iterations=params.get('iterations', 20),
                                target=params.get('target', 0.5),
                                threshold=params.get('threshold', 0.1),
                                step_init=params.get('step_init', 1.0),
                                min_step=params.get('min_step', 0.01),
                                max_step=params.get('max_step', 10.0))
    # compute reach: fraction of aggregated values within reach_threshold of target
    aggregates = np.array([rec['aggregate'] for rec in history], dtype=float)
    step_sizes = np.array([rec['step_size'] for rec in history], dtype=float)
    target = params.get('target', 0.5)
    reach_threshold = params.get('reach_threshold', 0.1)
    reach = float(np.mean(np.abs(aggregates - target) <= reach_threshold))
    # compute stability: inverse of normalised step variance (lower variance implies stability)
    step_std = float(np.std(step_sizes))
    stability = 1.0 / (1.0 + step_std)
    capability = 0.0
    if (reach + stability) > 0:
        capability = 2.0 * reach * stability / (reach + stability)
    return {'reach': reach, 'stability': stability, 'capability': capability, 'params': params}

def random_search(num_samples=10):
    """Perform random search over parameter space to find configurations with high capability."""
    results = []
    for _ in range(int(num_samples)):
        params = {
            'iterations': random.randint(10, 30),
            'target': random.uniform(0.1, 0.9),
            'threshold': random.uniform(0.05, 0.2),
            'step_init': random.uniform(0.1, 5.0),
            'min_step': 0.01,
            'max_step': 10.0,
            'reach_threshold': random.uniform(0.05, 0.2)
        }
        res = evaluate_params(params)
        results.append(res)
    results_sorted = sorted(results, key=lambda x: x['capability'], reverse=True)
    return results_sorted

if __name__ == "__main__":
    search_results = random_search(20)
    best = search_results[0] if search_results else None
    if best:
        print(f"Best capability: {best['capability']:.3f}")
        print(f"Parameters: {best['params']}")
        print(f"Reach: {best['reach']:.3f}, Stability: {best['stability']:.3f}")
    else:
        print("No results")

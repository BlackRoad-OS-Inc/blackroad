"""
thermodynamic_entropy_mirror.py

Implementation of a thermodynamic/entropy mirror for Lucidia's mirror mechanics.

This module provides functions to split a probability distribution into reversible and irreversible components, update the distribution using a 'breath' operator that preserves total energy while allowing entropy to increase, apply perturbations (delta-kicks), and run a demonstration simulation of a simple thermodynamic system.
"""

import numpy as np
import os
import csv
import json


def normalize(dist):
    total = np.sum(dist)
    return dist / total if total != 0 else dist


def mirror_split_distribution(dist, kernel_sigma=1.0):
    """
    Split a probability distribution into reversible and irreversible parts.

    The irreversible part is obtained by diffusing the distribution with a Gaussian kernel.
    The reversible part is the portion of the original distribution that remains after removing
    the irreversible contribution.

    Parameters:
    - dist: array-like, the current probability distribution.
    - kernel_sigma: standard deviation of the Gaussian kernel for diffusion.

    Returns:
    - reversible component of the distribution.
    - irreversible component of the distribution (non-negative diffused part minus original).
    """
    n = len(dist)
    positions = np.arange(n)
    # construct Gaussian kernel
    kernel = np.exp(- (positions[:, None] - positions[None, :]) ** 2 / (2.0 * kernel_sigma ** 2))
    kernel = kernel / kernel.sum(axis=1, keepdims=True)
    diffused = dist @ kernel
    irreversible = np.maximum(diffused - dist, 0)
    reversible = dist - irreversible
    return reversible, irreversible


def reversible_update(dist, shift=1):
    """
    Apply a reversible update by shifting the distribution periodically.

    Parameters:
    - dist: array-like, the current probability distribution.
    - shift: integer shift applied to the distribution (periodic boundary).

    Returns:
    - shifted distribution.
    """
    return np.roll(dist, shift)


def irreversible_update(dist, kernel_sigma=1.0):
    """
    Apply an irreversible update by diffusing the distribution with a Gaussian kernel.

    Parameters:
    - dist: array-like, the current probability distribution.
    - kernel_sigma: standard deviation of the Gaussian kernel for diffusion.

    Returns:
    - diffused distribution.
    """
    n = len(dist)
    positions = np.arange(n)
    kernel = np.exp(- (positions[:, None] - positions[None, :]) ** 2 / (2.0 * kernel_sigma ** 2))
    kernel = kernel / kernel.sum(axis=1, keepdims=True)
    return dist @ kernel


def breath_update(dist, shift=1, kernel_sigma=1.0):
    """
    Combine reversible and irreversible updates to produce the next distribution.

    Parameters:
    - dist: array-like, the current probability distribution.
    - shift: integer shift applied for the reversible update.
    - kernel_sigma: standard deviation of the Gaussian kernel for the irreversible update.

    Returns:
    - normalized distribution after applying both updates.
    """
    rev_part = reversible_update(dist, shift)
    irr_part = irreversible_update(dist, kernel_sigma)
    new_dist = 0.5 * (rev_part + irr_part)
    return normalize(new_dist)


def delta_kick(dist, strength=0.1):
    """
    Apply a perturbation (delta-kick) by adding mass to a random position.

    Parameters:
    - dist: array-like, the current probability distribution.
    - strength: amount of probability mass to add.

    Returns:
    - normalized distribution after the kick.
    """
    n = len(dist)
    pos = np.random.randint(n)
    dist_new = dist.copy()
    dist_new[pos] += strength
    return normalize(dist_new)


def energy_of_distribution(dist, energy_levels):
    """
    Compute the expected energy of a distribution given energy levels.

    Parameters:
    - dist: array-like, the current probability distribution.
    - energy_levels: array-like, energy associated with each state.

    Returns:
    - expected energy (float).
    """
    return float(np.dot(dist, energy_levels))


def entropy_of_distribution(dist):
    """
    Compute the Shannon entropy of a probability distribution.

    Parameters:
    - dist: array-like, the current probability distribution.

    Returns:
    - Shannon entropy (float, base e).
    """
    eps = 1e-12
    return float(-np.sum(dist * np.log(dist + eps)))


def run_thermo_demo(
    n_states=50,
    steps=50,
    shift=1,
    kernel_sigma=1.0,
    kick_step=25,
    kick_strength=0.5,
    out_dir="out_thermo",
):
    """
    Run a demonstration of the thermodynamic/entropy mirror.

    This simulates a one-dimensional probability distribution evolving under alternating reversible
    (advective) and irreversible (diffusive) updates. At a specified time step, a delta-kick
    introduces a perturbation, and the simulation continues. Energy (expected value of a linear
    energy spectrum) and Shannon entropy are recorded at each step.

    Parameters:
    - n_states: number of discrete states in the system.
    - steps: total number of time steps.
    - shift: integer shift for the reversible update.
    - kernel_sigma: standard deviation for the Gaussian diffusion.
    - kick_step: time step at which to apply the delta-kick (if negative, no kick is applied).
    - kick_strength: amount of probability mass to add during the delta-kick.
    - out_dir: directory to save output files (CSV and JSON).

    Returns:
    A dictionary with lists of energies, entropies, and distributions at each recorded step.
    """
    np.random.seed(0)
    # initialize distribution with a peak at the center
    dist = np.zeros(n_states)
    dist[n_states // 2] = 1.0
    dist = normalize(dist)

    # linear energy spectrum from 0 to 1
    energy_levels = np.linspace(0, 1, n_states)

    energies = []
    entropies = []
    distributions = []

    for t in range(steps):
        # record current state
        energies.append(energy_of_distribution(dist, energy_levels))
        entropies.append(entropy_of_distribution(dist))
        distributions.append(dist.tolist())

        # apply perturbation if scheduled
        if kick_step >= 0 and t == kick_step:
            dist = delta_kick(dist, kick_strength)

        # update distribution
        dist = breath_update(dist, shift, kernel_sigma)

    # record final state
    energies.append(energy_of_distribution(dist, energy_levels))
    entropies.append(entropy_of_distribution(dist))
    distributions.append(dist.tolist())

    # ensure output directory exists
    os.makedirs(out_dir, exist_ok=True)

    # write energy and entropy data
    with open(os.path.join(out_dir, "energy_entropy.csv"), "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["step", "energy", "entropy"])
        for i, (e, s) in enumerate(zip(energies, entropies)):
            writer.writerow([i, e, s])

    # write distributions to JSON
    with open(os.path.join(out_dir, "distributions.json"), "w") as f:
        json.dump({"distributions": distributions}, f, indent=2)

    return {
        "energies": energies,
        "entropies": entropies,
        "distributions": distributions,
    }

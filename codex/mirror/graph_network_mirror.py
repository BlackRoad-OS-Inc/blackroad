"""
Graph/Network Mirror Module

This module implements the mirror operator Psi' and breath operator B for directed graphs
represented by adjacency matrices. The mirror split decomposes a square adjacency
matrix into its symmetric (undirected) part and antisymmetric (orientation) part.
The breath update combines previous and current adjacency matrices to evolve the network
while preserving the original out-degree distribution. A delta_kick randomly toggles edges.

Functions:
- mirror_split_network(A): return symmetric and antisymmetric parts of adjacency matrix A.
- degree_distribution(A): return row-sum of adjacency matrix (out-degree).
- breath_update(A, target_deg=None): evolve A by squaring and normalizing rows to match target_deg.
- delta_kick(A, strength=1): randomly toggles directed edges.
- run_network_demo(...): demonstration of mirror and breath on a random graph; saves results to out_network/.

Usage:
python graph_network_mirror.py
"""

import os
import numpy as np
import json
import csv


def mirror_split_network(A: np.ndarray):
    """Return symmetric and antisymmetric parts of adjacency matrix A."""
    A = A.astype(float)
    sym = (A + A.T) / 2.0
    anti = (A - A.T) / 2.0
    return sym, anti


def degree_distribution(A: np.ndarray) -> np.ndarray:
    """Return out-degree distribution (row sums) of adjacency matrix A."""
    return np.sum(A, axis=1)


def breath_update(A: np.ndarray, target_deg: np.ndarray = None) -> np.ndarray:
    """
    Update adjacency matrix by a single 'breath' step.
    We square A (compute two-step connectivity) and normalize row sums to match target_deg.
    """
    if target_deg is None:
        target_deg = degree_distribution(A)
    # Multiply adjacency by itself (two steps)
    B = A.dot(A)
    # Compute new row sums
    row_sums = degree_distribution(B)
    # Initialize next matrix as copy of B
    A_next = B.copy()
    for i, (deg0, deg_new) in enumerate(zip(target_deg, row_sums)):
        if deg_new > 0:
            A_next[i, :] = B[i, :] * (deg0 / deg_new)
        else:
            A_next[i, :] = B[i, :]
    return A_next


def delta_kick(A: np.ndarray, strength: int = 1) -> np.ndarray:
    """
    Apply a delta-kick to adjacency matrix A by toggling 'strength' random edges.
    Each toggle flips the presence/absence of a directed edge (except self-loops).
    """
    n = A.shape[0]
    A = A.copy()
    for _ in range(strength):
        i = np.random.randint(n)
        j = np.random.randint(n)
        if i == j:
            continue
        A[i, j] = 1.0 - A[i, j]
    return A


def run_network_demo(
    n_nodes: int = 5,
    n_steps: int = 12,
    kick_step: int = 6,
    kick_strength: int = 2,
    seed: int = 0,
) -> dict:
    """
    Demonstrate the network mirror and breath operators on a random directed graph.
    Generates a random adjacency matrix, computes symmetric/antisymmetric parts,
    applies breath updates, introduces a delta-kick, and records degree variance.
    Results are saved to out_network/ as CSV and JSON.
    """
    np.random.seed(seed)
    # Generate random adjacency matrix with approx 30% connectivity
    A = (np.random.rand(n_nodes, n_nodes) < 0.3).astype(float)
    # Remove self-loops
    np.fill_diagonal(A, 0)
    # Compute target degree distribution for invariance
    target_deg = degree_distribution(A)
    history = {"step": [], "degree_var": []}
    for t in range(n_steps):
        if t == kick_step:
            A = delta_kick(A, strength=kick_strength)
        # Breath update: square and renormalize to target degrees
        A = breath_update(A, target_deg)
        current_deg = degree_distribution(A)
        diff = current_deg - target_deg
        history["step"].append(t)
        history["degree_var"].append(float(np.var(diff)))
    # Prepare output directory
    out_dir = "out_network"
    os.makedirs(out_dir, exist_ok=True)
    # Save history to CSV
    csv_path = os.path.join(out_dir, "degree_variance.csv")
    with open(csv_path, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["step", "degree_variance"])
        for s, var in zip(history["step"], history["degree_var"]):
            writer.writerow([s, var])
    # Save history to JSON
    json_path = os.path.join(out_dir, "degree_variance.json")
    with open(json_path, "w") as f:
        json.dump(history, f, indent=2)
    return history


if __name__ == "__main__":
    run_network_demo()

"""Harnesses for experimenting with Amundson coherence flows on combinatorial instances."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Sequence, Tuple

import argparse
import json
import math
import random

import numpy as np


@dataclass
class FlowParameters:
    """Parameters governing the Amundson I flow."""

    omega0: float = 0.0
    lam: float = 1.0
    eta: float = 0.1
    temperature: float = 1.0
    kB: float = 1.0


@dataclass
class FlowResult:
    """Summary of a numerical flow experiment."""

    history: np.ndarray
    converged: bool
    steps: int
    final_time: float

    @property
    def final_state(self) -> np.ndarray:
        return self.history[-1]


@dataclass
class RunResult:
    """Summary of the XY-style gradient flow cut heuristic."""

    steps: int
    energy: float
    best_cut: float
    best_step: int


def _normalize_weights(weight_matrix: np.ndarray) -> np.ndarray:
    """Normalize rows of ``weight_matrix`` to sum to one where possible."""

    row_sums = weight_matrix.sum(axis=1, keepdims=True)
    normalized = weight_matrix.copy()
    mask = row_sums > 0
    normalized[mask] /= row_sums[mask]
    return normalized


def _coherence_gradient(phi: np.ndarray, weights: np.ndarray, params: FlowParameters) -> np.ndarray:
    """Vectorized Amundson I gradient for a network."""

    diff = phi[:, None] - phi[None, :]
    cos_diff = np.cos(diff)
    coherence = np.sum(weights * cos_diff, axis=1)
    energy = params.kB * params.temperature * params.lam * np.sum(weights * (1 - cos_diff), axis=1)
    return params.omega0 + params.lam * coherence - params.eta * energy


def simulate_flow(
    initial_phases: Sequence[float],
    weight_matrix: np.ndarray,
    params: FlowParameters,
    *,
    dt: float = 0.01,
    max_steps: int = 10_000,
    tolerance: float = 1e-6,
    sample_every: int = 10,
) -> FlowResult:
    """Integrate the Amundson flow using explicit Euler updates."""

    phi = np.asarray(initial_phases, dtype=float)
    weights = _normalize_weights(weight_matrix)
    history: List[np.ndarray] = [phi.copy()]
    time = 0.0

    for step in range(1, max_steps + 1):
        grad = _coherence_gradient(phi, weights, params)
        phi = phi + dt * grad
        time += dt
        if step % sample_every == 0:
            history.append(phi.copy())
        if np.linalg.norm(dt * grad, ord=np.inf) < tolerance:
            history.append(phi.copy())
            return FlowResult(history=np.stack(history, axis=0), converged=True, steps=step, final_time=time)

    history.append(phi.copy())
    return FlowResult(history=np.stack(history, axis=0), converged=False, steps=max_steps, final_time=time)


def maxcut_weight_matrix(num_vertices: int, edges: Iterable[Tuple[int, int, float]]) -> np.ndarray:
    """Construct a symmetric weight matrix from weighted edges."""

    matrix = np.zeros((num_vertices, num_vertices), dtype=float)
    for u, v, weight in edges:
        matrix[u, v] += weight
        matrix[v, u] += weight
    np.fill_diagonal(matrix, 0.0)
    return matrix


def random_maxcut_instance(num_vertices: int, edge_probability: float, *, seed: int | None = None) -> np.ndarray:
    """Generate a random Erdos–Renyi graph with unit weights."""

    rng = random.Random(seed)
    edges = []
    for u in range(num_vertices):
        for v in range(u + 1, num_vertices):
            if rng.random() <= edge_probability:
                edges.append((u, v, 1.0))
    return maxcut_weight_matrix(num_vertices, edges)


Literal = Tuple[int, bool]
Clause = Tuple[Literal, ...]


def random_2sat_instance(num_vars: int, num_clauses: int, *, seed: int | None = None) -> List[Clause]:
    """Create a random 2-SAT instance for experimentation."""

    rng = random.Random(seed)
    clauses: List[Clause] = []
    for _ in range(num_clauses):
        a = rng.randrange(num_vars)
        b = rng.randrange(num_vars)
        clauses.append(((a, rng.choice([True, False])), (b, rng.choice([True, False]))))
    return clauses


def build_clause_weight_matrix(num_vars: int, clauses: Sequence[Clause]) -> np.ndarray:
    """Construct a weight matrix using one auxiliary node per clause."""

    total_nodes = num_vars + len(clauses)
    matrix = np.zeros((total_nodes, total_nodes), dtype=float)
    clause_offset = num_vars
    for clause_idx, clause in enumerate(clauses):
        aux = clause_offset + clause_idx
        for var_index, desired in clause:
            phase_target = 0.0 if desired else math.pi
            weight = math.cos(phase_target)
            matrix[var_index, aux] += weight
            matrix[aux, var_index] += weight
    np.fill_diagonal(matrix, 0.0)
    return matrix


def random_phases(num_nodes: int, *, seed: int | None = None) -> np.ndarray:
    rng = np.random.default_rng(seed)
    return rng.uniform(-math.pi, math.pi, size=num_nodes)


def gen_erdos(n: int, p: float, w: float = 1.0, seed: int | None = None) -> np.ndarray:
    """Generate a weighted Erdős–Rényi graph with constant edge weight ``w``."""

    rng = random.Random(seed)
    matrix = np.zeros((n, n), dtype=float)
    for i in range(n):
        for j in range(i + 1, n):
            if rng.random() < p:
                matrix[i, j] = matrix[j, i] = w
    return matrix


def read_edgelist(path: str, n: int | None = None) -> np.ndarray:
    """Load a symmetric weight matrix from an edge list file."""

    weights: dict[tuple[int, int], float] = {}
    inferred_n = 0
    with open(path) as handle:
        for line in handle:
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            parts = stripped.split()
            i, j = int(parts[0]), int(parts[1])
            value = float(parts[2]) if len(parts) > 2 else 1.0
            weights[(i, j)] = weights[(j, i)] = value
            inferred_n = max(inferred_n, i + 1, j + 1)
    size = n if n is not None else inferred_n
    matrix = np.zeros((size, size), dtype=float)
    for (i, j), value in weights.items():
        if i < size and j < size:
            matrix[i, j] = matrix[j, i] = value
    return matrix


def energy(phi: np.ndarray, weights: np.ndarray) -> float:
    """Compute the XY energy ``-Σ w_ij cos(φ_i - φ_j)``."""

    n = len(phi)
    total = 0.0
    for i in range(n):
        for j in range(i + 1, n):
            wij = weights[i, j]
            if wij != 0.0:
                total -= wij * math.cos(phi[i] - phi[j])
    return float(total)


def grad(phi: np.ndarray, weights: np.ndarray) -> np.ndarray:
    """Gradient of the XY energy with respect to ``φ``."""

    n = len(phi)
    g = np.zeros(n, dtype=float)
    for i in range(n):
        accum = 0.0
        for j in range(n):
            if i != j and weights[i, j] != 0.0:
                accum += weights[i, j] * math.sin(phi[i] - phi[j])
        g[i] = accum
    return g


def cut_value(phi: np.ndarray, weights: np.ndarray) -> tuple[float, list[int]]:
    """Return the cut value induced by ``sign(cos φ_i)``."""

    spins = np.where(np.cos(phi) >= 0.0, 1, -1)
    cut = 0.0
    n = len(phi)
    for i in range(n):
        for j in range(i + 1, n):
            if spins[i] != spins[j]:
                cut += weights[i, j]
    return float(cut), spins.tolist()


def run(
    weights: np.ndarray,
    *,
    steps: int = 5000,
    dt: float = 0.03,
    lam: float = 1.0,
    T: float = 0.02,
    seed: int | None = 0,
) -> RunResult:
    """Integrate the gradient flow with optional Langevin noise."""

    rng = np.random.default_rng(seed)
    n = weights.shape[0]
    phi = rng.random(n) * 2 * math.pi
    best_cut, _ = cut_value(phi, weights)
    best_step = 0
    for step in range(steps):
        g = grad(phi, weights)
        if T > 0:
            noise = rng.normal(scale=math.sqrt(2 * T * dt), size=n)
        else:
            noise = 0.0
        phi = (phi - lam * dt * g + noise) % (2 * math.pi)
        current_cut, _ = cut_value(phi, weights)
        if current_cut > best_cut:
            best_cut = current_cut
            best_step = step + 1
    return RunResult(steps=steps, energy=energy(phi, weights), best_cut=best_cut, best_step=best_step)


def main(argv: Sequence[str] | None = None) -> None:
    """CLI harness mirroring the exploratory gradient-flow script."""

    parser = argparse.ArgumentParser()
    parser.add_argument("--n", type=int, default=80)
    parser.add_argument("--p", type=float, default=0.1)
    parser.add_argument("--edge", default="", help="Optional edge-list file")
    parser.add_argument("--steps", type=int, default=4000)
    parser.add_argument("--dt", type=float, default=0.03)
    parser.add_argument("--lam", type=float, default=1.0)
    parser.add_argument("--T", type=float, default=0.02)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--out", default="data/phase_sat/run.json")
    args = parser.parse_args(argv)

    if args.edge:
        weights = read_edgelist(args.edge, None)
    else:
        weights = gen_erdos(args.n, args.p, w=1.0, seed=args.seed)

    result = run(
        weights,
        steps=args.steps,
        dt=args.dt,
        lam=args.lam,
        T=args.T,
        seed=args.seed,
    )

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    summary = {
        "n": int(weights.shape[0]),
        "m": int(np.count_nonzero(np.triu(weights, 1))),
        "steps": result.steps,
        "best_cut": result.best_cut,
        "best_step": result.best_step,
        "final_energy": result.energy,
    }
    out_path.write_text(json.dumps(summary, indent=2))
    print(f"Saved {out_path}")


__all__ = [
    "FlowParameters",
    "FlowResult",
    "RunResult",
    "simulate_flow",
    "maxcut_weight_matrix",
    "random_maxcut_instance",
    "random_2sat_instance",
    "build_clause_weight_matrix",
    "random_phases",
    "gen_erdos",
    "read_edgelist",
    "energy",
    "grad",
    "cut_value",
    "run",
]


if __name__ == "__main__":  # pragma: no cover - CLI entry point.
    main()

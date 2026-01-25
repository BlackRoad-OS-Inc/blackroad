"""Spectral gap computation utilities and CLI for Laplacian eigenvalues."""

from __future__ import annotations

import argparse
import sys
from typing import Iterable, List, Sequence, Tuple

import numpy as np


Edge = Tuple[int, int, float]


def laplacian_gap(weight_matrix: np.ndarray) -> float:
    """Return the algebraic connectivity (λ₂) of an undirected graph."""

    if weight_matrix.ndim != 2 or weight_matrix.shape[0] != weight_matrix.shape[1]:
        raise ValueError("weight matrix must be square")
    if not np.allclose(weight_matrix, weight_matrix.T, atol=1e-12):
        raise ValueError("weight matrix must be symmetric")

    degree = np.diag(weight_matrix.sum(axis=1))
    laplacian = degree - weight_matrix
    eigenvalues = np.linalg.eigvalsh(laplacian)
    eigenvalues.sort()
    if len(eigenvalues) < 2:
        raise ValueError("graph must contain at least two vertices")
    return float(eigenvalues[1])


def _parse_edge_list(lines: Iterable[str], *, nodes: int | None, one_indexed: bool) -> np.ndarray:
    edges: List[Edge] = []
    max_index = -1

    for raw_line in lines:
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) not in (2, 3):
            raise ValueError(f"invalid edge specification: '{raw_line.strip()}'")
        i, j = (int(parts[0]), int(parts[1]))
        weight = float(parts[2]) if len(parts) == 3 else 1.0
        if one_indexed:
            i -= 1
            j -= 1
        if i < 0 or j < 0:
            raise ValueError("edge indices must be non-negative")
        max_index = max(max_index, i, j)
        edges.append((i, j, weight))

    if nodes is None:
        if max_index < 0:
            raise ValueError("no edges supplied; specify --nodes to fix graph size")
        nodes = max_index + 1
    elif nodes <= 0:
        raise ValueError("--nodes must be a positive integer")

    matrix = np.zeros((nodes, nodes), dtype=float)
    for i, j, weight in edges:
        if i >= nodes or j >= nodes:
            raise ValueError("edge index exceeds declared node count")
        matrix[i, j] += weight
        matrix[j, i] += weight

    return matrix


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Compute the spectral gap (λ₂) from an edge list.")
    parser.add_argument(
        "edge_file",
        help="Path to an edge list file or '-' for stdin. Each line: i j [w].",
    )
    parser.add_argument(
        "--nodes",
        type=int,
        help="Total number of nodes (inferred from edges if omitted).",
    )
    parser.add_argument(
        "--one-indexed",
        action="store_true",
        help="Treat edge list indices as one-indexed instead of zero-indexed.",
    )
    args = parser.parse_args(argv)

    if args.edge_file == "-":
        matrix = _parse_edge_list(sys.stdin, nodes=args.nodes, one_indexed=args.one_indexed)
    else:
        with open(args.edge_file, "r", encoding="utf-8") as handle:
            matrix = _parse_edge_list(handle, nodes=args.nodes, one_indexed=args.one_indexed)

    gap = laplacian_gap(matrix)
    print(f"lambda2={gap}")
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    raise SystemExit(main())

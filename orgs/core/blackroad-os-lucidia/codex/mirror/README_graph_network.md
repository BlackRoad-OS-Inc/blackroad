# Graph/Network Mirror Module

This document describes the `graph_network_mirror.py` module in the `mirror` directory.

### Purpose

The graph network mirror implements a mirror operator for directed graphs represented by adjacency matrices. The mirror split decomposes a square adjacency matrix into a symmetric part (undirected edges) and an antisymmetric part (edge orientations). The breath operator evolves the adjacency matrix by taking two-hop connectivity and normalizing each row to preserve the original out-degree distribution. A delta-kick randomly toggles edges to model perturbations and tests the system's resilience.

### Features

- **mirror_split_network(A)** – returns the symmetric (A + A.T)/2 and antisymmetric (A - A.T)/2 parts of the adjacency matrix.
- **degree_distribution(A)** – computes the out-degree distribution of the graph by summing each row of the adjacency matrix.
- **breath_update(A, target_deg)** – squares the adjacency matrix to compute two-step connectivity, then renormalizes rows to match a target degree distribution, preserving the invariant.
- **delta_kick(A, strength)** – randomly toggles `strength` directed edges (excluding self-loops) to simulate perturbations.
- **run_network_demo(...)** – demonstration function that creates a random directed graph, applies breath updates, introduces a delta-kick, records variance of the degree distribution over time, and saves results to an `out_network/` directory as CSV and JSON.

### Running the module

From the repository root, run:

```
python codex/mirror/graph_network_mirror.py
```

This will generate a random directed graph, apply the mirror/breath updates with a perturbation, and write `degree_variance.csv` and `degree_variance.json` in the `out_network/` directory.

### Dependencies

This module uses only the Python standard library and `numpy` for array operations. It writes outputs using `csv`, `json`, and creates directories with `os`.

### Interpretation

The graph network mirror extends the mirror friend framework to network dynamics. Splitting the adjacency matrix into symmetric and antisymmetric parts corresponds to separating undirected connectivity from the orientation of edges. The breath update acts as a degree-preserving smoothing of connectivity, analogous to combining present and past states without losing the invariant. The delta-kick demonstrates how local perturbations (adding or removing edges) shift the network yet the overall invariants recover through subsequent breath steps.

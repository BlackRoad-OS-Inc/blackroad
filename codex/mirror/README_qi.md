# Quantum Mirror Module

This document describes the **quantum_mirror_qi.py** module in the `mirror` directory.

### Purpose

The quantum mirror module demonstrates how the mirror operator Ψ′ and the breath operator ℓ apply to quantum information. A qubit state evolves under a Hamiltonian while Ψ′ separates each state into a global‑phase‑free “logical” component and a pure phase component. ℓ corresponds to a symplectic-like update that preserves the state norm. The code also supports applying δ‑kicks to simulate sudden phase or amplitude perturbations and demonstrates resilience to such kicks.

### Features

- **normalize(state)** – normalizes a complex vector so it represents a valid qubit state.
- **mirror_split_qubit(state)** – computes the mirror split of a single qubit into amplitude (logical) and phase parts.
- **evolve_state(state, time, hamiltonian)** – evolves a qubit forward in time under a specified Hamiltonian using matrix exponentials or SciPy if available.
- **delta_kick(state, kick_matrix)** – applies a sudden unitary kick to a qubit.
- **bloch_coords(state)** – converts a qubit state to Bloch‑sphere coordinates (x,y,z) and global phase.
- **run_single_qubit_demo()** – runs a demonstration of a qubit initially in superposition evolving under a Pauli‑Z Hamiltonian with a δ‑kick at mid‑time. It records Bloch coordinates, phases, and the effect of the kick. When matplotlib is available it produces plots of the Bloch trajectory and energy over time and saves them to `out_qi/`.
- **concurrence_two_qubit(state)** – computes the concurrence (entanglement measure) of a two‑qubit state.
- **run_bell_demo()** – prepares a Bell state, evolves it under independent single‑qubit Hamiltonians, and measures how the concurrence evolves over time. It also produces optional plots and CSV tables when `matplotlib` is installed.

### Running the module

Run the module from the repository root to execute the demos:

```
python codex/mirror/quantum_mirror_qi.py
```

By default the script runs both the single‑qubit and Bell‑state demos. It creates an `out_qi/` directory, saving CSV files and plots of the Bloch trajectories, phase evolution, concurrence, and energy diagnostics.

### Dependencies

The module uses `numpy` for linear algebra and attempts to import `scipy.linalg.expm` for matrix exponentials. If SciPy is unavailable it falls back to a simple series expansion. Optional plotting requires `matplotlib`.

### Interpretation

This module extends the mirror friend equation into the quantum realm. The Ψ′ operator corresponds to separating the qubit’s amplitude and phase while the ℓ operator is embodied by unitary time evolution that preserves state norm and entanglement. The δ‑kick demonstrates that perturbations can shift the phase without destroying the mirror relationship or the conserved quantities. The two‑qubit Bell demonstration shows how the mirror structure applies to entanglement.

# Thermodynamic/Entropy Mirror

This document explains the thermodynamic/entropy mirror used in Lucidia's mirror mechanics.

### Purpose

The thermodynamic mirror explores how the mirror operator (`Ψ′`) and breath operator (`ℛ(t)`) manifest in a simple thermodynamic system. The goal is to separate reversible and irreversible contributions to a probability distribution while preserving total energy and allowing entropy to change.

### Features

- **mirror_split_distribution(dist, kernel_sigma)** – splits a probability distribution into reversible and irreversible parts. The irreversible part is obtained by diffusing the distribution via a Gaussian kernel; the reversible part is the remainder.
- **reversible_update(dist, shift)** – performs a periodic shift to model reversible (advective) evolution.
- **irreversible_update(dist, kernel_sigma)** – applies a Gaussian diffusion to model irreversible (dissipative) evolution.
- **breath_update(dist, shift, kernel_sigma)** – combines the reversible and irreversible updates and renormalizes the distribution.
- **delta_kick(dist, strength)** – adds mass to a randomly chosen state to model an external perturbation and renormalizes.
- **energy_of_distribution(dist, energy_levels)** – computes the expected energy of the distribution with respect to a chosen energy spectrum.
- **entropy_of_distribution(dist)** – computes the Shannon entropy (using natural logarithms).
- **run_thermo_demo(n_states, steps, shift, kernel_sigma, kick_step, kick_strength, out_dir)** – runs a demonstration of the thermodynamic mirror. It initializes a discrete distribution peaked at the center, alternates reversible and irreversible updates for the specified number of steps, applies a delta-kick at a chosen step, and records energy and entropy at each step. Results are saved into `out_dir` as a CSV (`energy_entropy.csv`) and a JSON (`distributions.json`).

### Usage

To run the thermodynamic mirror demonstration, execute the module as a script:

```bash
python codex/mirror/thermodynamic_entropy_mirror.py
```

By default, it simulates a system with 50 discrete states for 50 steps, applies a delta-kick halfway through, and outputs results in the `out_thermo` directory. You can adjust the parameters by calling `run_thermo_demo` directly within Python.

### Interpretation

The reversible update models coherent, conservative motion (e.g. a drift of probability mass), while the irreversible update models diffusion or entropy-increasing processes. The breath update combines both effects and then renormalizes, mirroring the `ℛ(t)` operator in Lucidia's architecture. The energy remains approximately constant despite perturbations, while the entropy generally increases, illustrating how the mirror structure can hold contradictions (energy conservation vs entropy growth) simultaneously.

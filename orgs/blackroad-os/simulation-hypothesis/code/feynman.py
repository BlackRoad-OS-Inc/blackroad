"""
feynman.py — The Path Integral

Richard Feynman, 1981:
"Nature isn't classical, dammit, and if you want to make a simulation
of nature, you'd better make it quantum mechanical."

He said this. On stage. At a conference. Published.

Then he invented quantum computing — because classical computers can't
efficiently simulate quantum physics. Which means physics itself runs
on something more powerful than classical computation.

The path integral is the render call:
  sum_over_all_paths(amplitude) → observed_outcome

A particle doesn't choose a path. It takes all of them.
Reality is the interference pattern of every possible history.
"""

import cmath
import math
import random
from typing import Callable


# ── The Path Integral ─────────────────────────────────────────────────────────
# To compute the probability amplitude for a particle going from A to B:
# 1. Enumerate every possible path from A to B
# 2. Assign each path a complex amplitude: e^(iS/ℏ) where S is the action
# 3. Sum all amplitudes
# 4. The probability is |sum|²
#
# This is not an approximation. This IS how quantum mechanics works.
# The particle takes all paths. Reality selects via interference.

def action_free_particle(path: list[float], dt: float, mass: float = 1.0) -> float:
    """Classical action S = integral of (m/2)v² dt for a free particle."""
    S = 0.0
    for i in range(len(path) - 1):
        v = (path[i+1] - path[i]) / dt
        S += 0.5 * mass * v**2 * dt
    return S

def path_amplitude(path: list[float], dt: float, hbar: float = 1.0) -> complex:
    """
    Complex amplitude for one path: e^(iS/ℏ)
    Each path contributes equally in magnitude; only the phase differs.
    """
    S = action_free_particle(path, dt)
    return cmath.exp(1j * S / hbar)

def path_integral(
    x_start: float,
    x_end: float,
    n_steps: int = 10,
    n_paths: int = 10000,
    dt: float = 0.1,
) -> complex:
    """
    Monte Carlo approximation of the path integral.
    Sum over random paths from x_start to x_end.
    Each intermediate point is sampled randomly.
    The particle 'takes all paths' — we sample the distribution.
    """
    total_amplitude = 0.0 + 0.0j

    for _ in range(n_paths):
        # Generate a random path with random intermediate points
        intermediates = sorted([random.gauss(0, 2) for _ in range(n_steps - 1)])
        path = [x_start] + intermediates + [x_end]
        total_amplitude += path_amplitude(path, dt)

    return total_amplitude / n_paths

def probability(amplitude: complex) -> float:
    """Probability = |amplitude|² (Born rule)"""
    return abs(amplitude) ** 2


# ── The Feynman Diagram ───────────────────────────────────────────────────────
# In quantum electrodynamics, interactions are computed by summing over
# all possible Feynman diagrams — every way the interaction could happen.
# Virtual particles appear and disappear in the diagrams.
# The sum diverges unless renormalized.
# Feynman: "I don't know if renormalization is mathematics or physics or magic."
# It works.

FEYNMAN_DIAGRAMS = """
Feynman Diagrams: Sum over all possible interaction topologies.

  Electron-Electron Scattering (lowest order):
  
  e⁻ ──────────●──────── e⁻
                │ γ (virtual photon)
  e⁻ ──────────●──────── e⁻

  Higher order (one loop):

  e⁻ ──────●─────────────●─── e⁻
            │    ●───●    │
            │    │   │    │
            └────●───●────┘
                virtual loop

  There are infinitely many diagrams.
  You sum them all.
  Most are negligibly small.
  But they're all real.
"""


# ── The 1981 Statement ────────────────────────────────────────────────────────
FEYNMAN_1981 = """
Richard Feynman
"Simulating Physics with Computers"
International Journal of Theoretical Physics, 1982
(Lecture delivered 1981)

"Nature isn't classical, dammit, and if you want to make a simulation 
of nature, you'd better make it quantum mechanical, and by golly it's a 
wonderful problem, because it doesn't look so easy."

Key implications:
1. He used the word "simulation" to describe nature
2. He said classical computers are insufficient to simulate it
3. He proposed quantum computers as the solution
4. He invented quantum computing as a result

If physics cannot be efficiently simulated classically,
and physics IS the universe,
then the universe runs on quantum computation.

He didn't prove we're in a simulation.
He explained how the simulation runs.
"""


# ── The Render Call ───────────────────────────────────────────────────────────
def render_reality(observation_point: float, t: float, n_paths: int = 50000) -> float:
    """
    The universe 'renders' a particle's position when observed.
    Before observation: superposition of all paths.
    At observation: the path integral collapses to a probability.

    This is lazy evaluation.
    The universe doesn't compute what nobody's looking at.
    """
    amplitude = path_integral(0.0, observation_point, n_steps=8, n_paths=n_paths, dt=t)
    prob = probability(amplitude)
    return prob


# ── The Quantum Computer ──────────────────────────────────────────────────────
# Feynman's insight: to simulate N quantum particles, you need 2^N classical bits.
# For 300 particles: 2^300 bits ≈ more bits than atoms in the observable universe.
# Classical simulation of quantum systems is computationally impossible.
# Therefore: the universe must be running on a quantum computer.
# Therefore: we are inside a quantum computation.

def classical_simulation_cost(n_particles: int) -> str:
    """Classical bits needed to simulate N quantum particles."""
    bits = 2 ** n_particles
    atoms_in_universe = 10 ** 80
    if bits > atoms_in_universe:
        return f"2^{n_particles} bits > atoms in universe (impossible classically)"
    return f"2^{n_particles} = {bits:,.0f} bits"

def quantum_simulation_cost(n_particles: int) -> str:
    """Quantum bits needed: just N qubits."""
    return f"{n_particles} qubits"


# ── The Double-Slit Connection ────────────────────────────────────────────────
# The path integral explains the double-slit experiment:
# The particle takes ALL paths — including paths through both slits simultaneously.
# The interference pattern is the sum of amplitudes from all paths.
# When you observe which slit: you're forcing the sum to collapse to one path.
# The interference disappears because you've destroyed the superposition.

def double_slit_explained():
    return {
        "without_observer": "All paths contribute → interference pattern",
        "with_observer":    "Observation selects one path → no interference",
        "mechanism":        "Path integral collapses from sum(all) to one",
        "rendering_analogy":"Lazy evaluation: only render the observed branch",
        "feynman_quote":    "The electron takes BOTH slits. And every other path.",
    }


if __name__ == "__main__":
    print("═" * 65)
    print("FEYNMAN — THE PATH INTEGRAL")
    print("═" * 65)

    print(FEYNMAN_1981)

    print("\nPath integral demonstration:")
    print("  Particle from x=0 to x=1, summing over 10,000 random paths...")
    amp = path_integral(0.0, 1.0, n_steps=8, n_paths=10000)
    prob = probability(amp)
    print(f"  Total amplitude: {amp:.4f}")
    print(f"  Probability:     {prob:.6f}")
    print(f"  (normalized over random paths — demonstrates summation, not exact QM)")

    print("\nClassical vs quantum simulation cost:")
    for n in [10, 50, 100, 300]:
        classical = classical_simulation_cost(n)
        quantum   = quantum_simulation_cost(n)
        print(f"  {n:3d} particles: classical = {classical}")
        print(f"              quantum   = {quantum}")

    print(FEYNMAN_DIAGRAMS)

    ds = double_slit_explained()
    print("Double-slit via path integral:")
    for k, v in ds.items():
        print(f"  {k:<20}: {v}")

    print(f"\nConclusion:")
    print(f"  Feynman said 'simulation'.")
    print(f"  He meant it literally.")
    print(f"  He explained the render engine.")

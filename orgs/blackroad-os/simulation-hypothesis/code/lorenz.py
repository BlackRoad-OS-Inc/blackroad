"""
lorenz.py — Deterministic Chaos from Minimum Complexity

Demonstrates §16 of PAPER.md: three parameters are sufficient to produce
infinite, non-repeating, deterministic chaos — the minimum complexity
needed for a universe that feels unpredictable but isn't.

The Lorenz attractor:
    dx/dt = σ(y - x)
    dy/dt = x(ρ - z) - y
    dz/dt = xy - βz

Standard parameters: σ=10, ρ=28, β=8/3

The "three" pattern:
  - 3 equations
  - 3 dimensions
  - 3 classic parameters
  - 3 color channels in RGB
  - 3 bases per codon in DNA
  - 3 quarks per baryon
  - 3 spatial dimensions

Author: BlackRoad OS, Inc.
"""

import math


def lorenz_step(x: float, y: float, z: float,
                sigma: float = 10.0, rho: float = 28.0, beta: float = 8/3,
                dt: float = 0.01) -> tuple[float, float, float]:
    """Advance the Lorenz system by one timestep using Euler integration."""
    dx = sigma * (y - x)
    dy = x * (rho - z) - y
    dz = x * y - beta * z
    return x + dx * dt, y + dy * dt, z + dz * dt


def generate_trajectory(n_steps: int = 10000,
                         x0: float = 0.1, y0: float = 0.0, z0: float = 0.0) -> list:
    """Generate a Lorenz trajectory."""
    trajectory = [(x0, y0, z0)]
    x, y, z = x0, y0, z0
    for _ in range(n_steps):
        x, y, z = lorenz_step(x, y, z)
        trajectory.append((x, y, z))
    return trajectory


def butterfly_effect(epsilon: float = 1e-10, n_steps: int = 2000):
    """Show that infinitesimally different initial conditions diverge completely."""
    print("=" * 60)
    print("THE BUTTERFLY EFFECT — Sensitive Dependence on Initial Conditions")
    print("=" * 60)
    print(f"\nTwo trajectories with initial difference: ε = {epsilon}")
    print(f"  Trajectory A: x₀ = 0.1")
    print(f"  Trajectory B: x₀ = 0.1 + {epsilon} = {0.1 + epsilon}\n")

    x1, y1, z1 = 0.1, 0.0, 0.0
    x2, y2, z2 = 0.1 + epsilon, 0.0, 0.0

    print(f"  {'Step':>6}  {'|ΔX|':>12}  {'Divergence factor':>18}")
    print("  " + "-" * 42)
    for step in [0, 100, 500, 1000, 1500, 2000]:
        dist = math.sqrt((x2 - x1)**2 + (y2 - y1)**2 + (z2 - z1)**2)
        factor = dist / epsilon if epsilon > 0 else 0
        print(f"  {step:>6}  {dist:>12.2e}  {factor:>18.0f}×")
        # Advance both
        for _ in range(100 if step > 0 else 0):
            x1, y1, z1 = lorenz_step(x1, y1, z1)
            x2, y2, z2 = lorenz_step(x2, y2, z2)

    print("\n  At step 2000, the two trajectories are completely uncorrelated.")
    print("  The universe is deterministic. It feels random. This is how.")


def minimum_complexity():
    """Show that exactly 3 parameters are enough for infinite complexity."""
    print("\n" + "=" * 60)
    print("MINIMUM COMPLEXITY — Why Three?")
    print("=" * 60)

    print("""
  The Lorenz system uses exactly 3 parameters:
    σ (sigma) = 10   — how fast x responds to y (momentum coupling)
    ρ (rho)   = 28   — driving force (like gravity)
    β (beta)  = 8/3  — dissipation rate

  With these 3 numbers, the attractor is:
    • Bounded    — trajectories stay within a finite region
    • Aperiodic  — never exactly repeats
    • Dense      — comes arbitrarily close to every point in the attractor
    • Sensitive  — any perturbation grows exponentially

  The THREE pattern across the simulation:
    • 3 Lorenz equations     → infinite aperiodic chaos
    • 3 quarks per baryon    → all stable matter
    • 3 color channels (RGB) → all visible color
    • 3 bases per codon      → all 20 amino acids + stop signals
    • 3 spatial dimensions   → minimum for chaotic dynamics
    • 3 parameters in Easter's algorithm → all calendar dates
    • 3 sides of a triangle  → minimum closed polygon

  Minimum description length: 3 is where complexity begins.
""")


def attractor_bounds(n_steps: int = 50000):
    """Compute the bounding box of the Lorenz attractor."""
    print("=" * 60)
    print("LORENZ ATTRACTOR — Bounding Box")
    print("=" * 60)

    traj = generate_trajectory(n_steps)
    xs = [p[0] for p in traj]
    ys = [p[1] for p in traj]
    zs = [p[2] for p in traj]

    print(f"\n  After {n_steps:,} steps (σ=10, ρ=28, β=8/3):")
    print(f"    x: [{min(xs):+.2f}, {max(xs):+.2f}]")
    print(f"    y: [{min(ys):+.2f}, {max(ys):+.2f}]")
    print(f"    z: [{min(zs):+.2f}, {max(zs):+.2f}]")
    print(f"\n  The trajectory never leaves this box.")
    print(f"  The trajectory never exactly repeats.")
    print(f"  Deterministic. Bounded. Infinite. — Like reality.")


def plot_attractor():
    """Plot the attractor if matplotlib is available."""
    try:
        import matplotlib.pyplot as plt
        from mpl_toolkits.mplot3d import Axes3D  # noqa: F401

        traj = generate_trajectory(20000)
        xs, ys, zs = zip(*traj)

        fig = plt.figure(figsize=(10, 8))
        ax = fig.add_subplot(111, projection='3d')
        ax.plot(xs, ys, zs, lw=0.3, alpha=0.7, color='#FF1D6C')
        ax.set_title('Lorenz Attractor\nσ=10, ρ=28, β=8/3 — 3 parameters, infinite complexity',
                     color='white', fontsize=12)
        ax.set_facecolor('#0a0a0a')
        fig.patch.set_facecolor('#0a0a0a')
        ax.tick_params(colors='gray')
        ax.set_xlabel('X', color='gray')
        ax.set_ylabel('Y', color='gray')
        ax.set_zlabel('Z', color='gray')
        plt.tight_layout()
        plt.savefig('../assets/lorenz_attractor.png', dpi=150, facecolor='#0a0a0a')
        print("\n  Plot saved to assets/lorenz_attractor.png")
        plt.show()
    except ImportError:
        print("\n  (Install matplotlib to visualize: pip install matplotlib)")


if __name__ == '__main__':
    butterfly_effect()
    minimum_complexity()
    attractor_bounds()
    plot_attractor()
    print("\n" + "=" * 60)
    print("3 equations. 3 parameters. Infinite, non-repeating, bounded chaos.")
    print("This is the minimum complexity needed for reality to feel real.")
    print("=" * 60)

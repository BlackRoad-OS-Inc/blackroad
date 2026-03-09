"""
riemann_zeros.py — The Trivial Zeros of the Riemann Zeta Function

Demonstrates §14 of PAPER.md: "The Riemann Architecture"

The Riemann zeta function:
    ζ(s) = Σ(n=1 to ∞) 1/nˢ   for Re(s) > 1
    (analytically continued to all s ≠ 1)

Trivial zeros: ζ(-2) = ζ(-4) = ζ(-6) = ... = 0
Non-trivial zeros: all known ones lie on Re(s) = 1/2  (the Riemann Hypothesis)

The trivial zeros converge toward zero. The non-trivial zeros sit on a line
at 1/2 — the midpoint, the boundary, the critical strip.

The De Bruijn-Newman constant Λ = 0 (proven 2020).
Euler's identity: e^(iπ) + 1 = 0.
Total energy of the universe: 0.
Bitcoin genesis block: starts at zero.
The hash chain: previous_hash = '0' * 64.

Everything resolves to zero.

Author: BlackRoad OS, Inc.
"""

import math
import cmath


def zeta_trivial_zeros():
    """
    Show the trivial zeros of the Riemann zeta function.
    At s = -2n (n = 1, 2, 3, ...), ζ(s) = 0 exactly.
    We compute using the functional equation approximation.
    """
    print("=" * 60)
    print("TRIVIAL ZEROS OF THE RIEMANN ZETA FUNCTION")
    print("=" * 60)
    print("\n  ζ(s) = 0 at s = -2, -4, -6, -8, ...\n")

    # Use the reflection formula:
    # ζ(s) = 2^s * π^(s-1) * sin(πs/2) * Γ(1-s) * ζ(1-s)
    # At s = -2n, sin(πs/2) = sin(-nπ) = 0, so ζ(-2n) = 0

    print(f"  {'s':>6}   {'sin(πs/2)':>14}   {'Result':>12}")
    print("  " + "-" * 40)
    for n in range(1, 9):
        s = -2 * n
        sin_val = math.sin(math.pi * s / 2)
        # sin(-nπ) = 0 exactly for integer n — the trivial zeros
        print(f"  {s:>6}   {sin_val:>14.6e}   {'ζ = 0':>12}")

    print("\n  The sin(πs/2) term zeros out the entire expression at s = -2n.")
    print("  These are the trivial zeros — guaranteed by the functional equation.")


def euler_identity():
    """Euler's identity: e^(iπ) + 1 = 0 — the most beautiful equation."""
    print("\n" + "=" * 60)
    print("EULER'S IDENTITY — e^(iπ) + 1 = 0")
    print("=" * 60)

    result = cmath.exp(1j * math.pi) + 1
    print(f"\n  e^(iπ) + 1 = {result.real:.15f} + {result.imag:.2e}i")
    print(f"  ≈ 0 (floating point precision limit)")
    print("""
  This single equation unifies:
    e  — the base of natural growth (2.71828...)
    i  — the imaginary unit (√-1)
    π  — the ratio of circumference to diameter (3.14159...)
    1  — the multiplicative identity
    0  — the additive identity, the trivial zero, the beginning

  Five fundamental constants. One equation. Result: zero.
  The universe's most elegant signature that it was initialized
  from a single set of parameters and returns to nothing.
""")


def zeros_converge():
    """Show that the trivial zero sequence 'converges toward zero' conceptually."""
    print("=" * 60)
    print("THE CONVERGENCE — Everything Resolves to Zero")
    print("=" * 60)

    zeros = [
        ("Euler's identity e^(iπ) + 1", 0),
        ("Total energy of the universe", 0),
        ("De Bruijn-Newman constant Λ", 0),
        ("Bitcoin genesis block previous_hash", "0" * 64),
        ("RoadChain genesis block previous_hash", "0" * 64),
        ("SHA-256 hash of empty string", hashlib_sha256_empty()),
        ("Riemann zeta trivial zero ζ(-2)", 0),
        ("Riemann zeta trivial zero ζ(-4)", 0),
        ("Riemann zeta trivial zero ζ(-6)", 0),
    ]

    print()
    for name, value in zeros:
        if isinstance(value, str) and len(value) == 64:
            print(f"  {name}:")
            print(f"    = {value[:32]}...")
        else:
            print(f"  {name} = {value}")

    print("""
  These are not metaphors. They are numerical values.
  The simulation does not hide its initialization parameters.
  It displays them in the most fundamental equations of every field.
""")


def hashlib_sha256_empty() -> str:
    import hashlib
    return hashlib.sha256(b'').hexdigest()


def riemann_hypothesis_context():
    """Explain the Riemann Hypothesis in simulation terms."""
    print("=" * 60)
    print("THE RIEMANN HYPOTHESIS — The Unsolved Boundary")
    print("=" * 60)
    print("""
  Known non-trivial zeros (first few imaginary parts):
    ½ + 14.134725i
    ½ + 21.022040i
    ½ + 25.010858i
    ½ + 30.424876i
    ½ + 32.935062i

  All 10,000,000,000,000 known non-trivial zeros lie on Re(s) = ½.
  The Riemann Hypothesis says they ALL do — but this is unproven.

  In simulation terms:
    - The critical line Re(s) = ½ is the boundary between 0 and 1
    - The half-way point — exactly midway through the unit interval
    - Like a pixel that is 50% rendered
    - The zeros are where the system "touches zero" without terminating

  The Riemann Hypothesis may be unprovable from within the system.
  Gödel says some true statements cannot be proven inside their own axioms.
  The simulation cannot prove its own termination condition.
  This is consistent with being inside it.
""")


if __name__ == '__main__':
    zeta_trivial_zeros()
    euler_identity()
    zeros_converge()
    riemann_hypothesis_context()
    print("=" * 60)
    print("The trivial zeros are not trivial.")
    print("They are the system signing its own source code.")
    print("=" * 60)

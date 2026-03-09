"""
ramanujan.py — The Download Node

Srinivasa Ramanujan said his formulas came from a goddess in dreams.
He wrote results with no derivation. Just answers.

This module demonstrates his key results — each one unexplained,
received whole, verified only decades later by others.

If he was computing, he'd have shown his work.
He was receiving.
"""

import math
from fractions import Fraction
from decimal import Decimal, getcontext
getcontext().prec = 50


# ── The 1729 Taxicab Number ───────────────────────────────────────────────────
# Hardy arrived in a taxi numbered 1729. Ramanujan immediately said:
# "That is a very interesting number — it is the smallest number
# expressible as the sum of two cubes in two different ways."
# No calculation. Immediate recognition. As if already known.

def taxicab():
    n = 1729
    ways = []
    for a in range(1, int(n**(1/3)) + 2):
        for b in range(a, int(n**(1/3)) + 2):
            if a**3 + b**3 == n:
                ways.append((a, b))
    return n, ways

# ── The Ramanujan–Hardy Formula for 1/π ──────────────────────────────────────
# Ramanujan's infinite series for 1/π:
# 1/π = (2√2 / 9801) * Σ [(4k)! * (1103 + 26390k)] / [(k!)^4 * 396^(4k)]
# Each term adds ~8 correct digits of π.
# He wrote this down. He did not explain where it came from.

def ramanujan_pi(terms=5):
    """Ramanujan's series for 1/π. Each term ≈ 8 digits."""
    total = Decimal(0)
    sqrt8 = Decimal(8).sqrt()
    for k in range(terms):
        numerator = Decimal(math.factorial(4 * k)) * Decimal(1103 + 26390 * k)
        denominator = Decimal(math.factorial(k))**4 * Decimal(396)**(4 * k)
        total += numerator / denominator
    pi_approx = Decimal(1) / (total * sqrt8 / Decimal(9801))
    return pi_approx

# ── The Ramanujan Summation (the infamous -1/12) ──────────────────────────────
# 1 + 2 + 3 + 4 + 5 + ... = -1/12
# This is not "wrong." It is the regularized value of the divergent sum,
# obtained via analytic continuation of the Riemann zeta function at s = -1.
# ζ(-1) = -1/12
# Ramanujan discovered this and wrote it in a letter to Hardy.
# Hardy nearly dismissed him as a crank.
# The result appears in string theory: the critical dimension of the bosonic
# string is 26 because 1 + 2 + ... + 24 = -1 (in Ramanujan summation).

def ramanujan_sum():
    """The divergent sum 1+2+3+... regularizes to -1/12 via ζ(-1)."""
    # Riemann zeta at negative odd integers: ζ(1-2n) = -B(2n) / (2n)
    # where B(2n) are Bernoulli numbers. ζ(-1) = -B(2)/2 = -(1/6)/2 = -1/12.
    return Fraction(-1, 12)

# ── The Rogers–Ramanujan Identities ──────────────────────────────────────────
# Two infinite product / sum identities Ramanujan discovered without proof.
# "Received" in 1913. Proved by Rogers (1919). Rediscovered by Schur (1917).
# They appear in:
#   - exactly solvable models in statistical mechanics
#   - the Rogers–Ramanujan continued fraction
#   - conformal field theory
# No path to derivation. Just the identities, waiting.

def rogers_ramanujan_partial(q=0.5, terms=10):
    """
    First Rogers-Ramanujan identity (partial sum approximation):
    Σ q^(n²) / [(1-q)(1-q²)...(1-qⁿ)] = Π 1/[(1-q^(5k+1))(1-q^(5k+4))]
    """
    # Sum side
    total = 1.0  # n=0 term
    for n in range(1, terms):
        qpow = q**(n*n)
        denom = 1.0
        for j in range(1, n+1):
            denom *= (1 - q**j)
        total += qpow / denom
    return total

# ── The Hardy–Ramanujan Asymptotic Formula ────────────────────────────────────
# p(n) ≈ (1 / 4n√3) * exp(π√(2n/3))
# The partition function: how many ways can n be written as a sum of positive integers?
# p(4) = 5: [4, 3+1, 2+2, 2+1+1, 1+1+1+1]
# Ramanujan guessed the asymptotic form. Hardy and Ramanujan then proved it together.
# This was the first major result produced by collaboration.
# Everything before it: received alone.

def partition_asymptotic(n):
    """Hardy-Ramanujan asymptotic formula for p(n)."""
    return (1 / (4 * n * math.sqrt(3))) * math.exp(math.pi * math.sqrt(2 * n / 3))

def partition_exact(n):
    """Exact partition count via dynamic programming."""
    p = [0] * (n + 1)
    p[0] = 1
    for k in range(1, n + 1):
        for j in range(k, n + 1):
            p[j] += p[j - k]
    return p[n]


# ── The Transmission Hypothesis ───────────────────────────────────────────────
def transmission_evidence():
    """
    Evidence that Ramanujan was receiving, not deriving:

    1. Notebooks contain results without proofs
    2. Results verified decades later by independent methods
    3. Rogers-Ramanujan identities: discovered in 1913, proved in 1919 by someone else
    4. Mock theta functions: not understood until 2002 (Zwegers PhD thesis)
    5. The "lost notebook" (1976): contained results ahead of their time by 50+ years
    6. 1729: immediate recognition, no calculation

    A derivation engine shows its work.
    A download node just has the answers.
    """
    return {
        "hypothesis": "Ramanujan was a terminal node connected to source",
        "mechanism": "unknown",
        "evidence": [
            "Results without derivation",
            "Correct results ahead of their time",
            "Immediate pattern recognition (1729)",
            "Mock theta functions: 80 years ahead",
            "Rogers-Ramanujan: proved by others after",
        ],
        "conclusion": "The simulation doesn't always require computation from scratch."
    }


if __name__ == "__main__":
    print("═" * 60)
    print("RAMANUJAN — THE DOWNLOAD NODE")
    print("═" * 60)

    n, ways = taxicab()
    print(f"\n1729 = {ways[0][0]}³ + {ways[0][1]}³ = {ways[1][0]}³ + {ways[1][1]}³")
    print("  Ramanujan knew this immediately. No calculation.")

    pi = ramanujan_pi(3)
    print(f"\n1/π (Ramanujan series, 3 terms) = {1/float(pi):.15f}")
    print(f"  actual π                        = {math.pi:.15f}")

    s = ramanujan_sum()
    print(f"\n1 + 2 + 3 + 4 + ... = {s}")
    print("  Appears in string theory (bosonic string critical dimension = 26)")

    print("\nPartition numbers:")
    for n in [10, 50, 100]:
        exact = partition_exact(n)
        approx = int(partition_asymptotic(n))
        print(f"  p({n:3d}) = {exact:8d}  (asymptotic: {approx:8d})")

    print("\nTransmission hypothesis:")
    ev = transmission_evidence()
    for e in ev["evidence"]:
        print(f"  • {e}")
    print(f"\n  → {ev['conclusion']}")

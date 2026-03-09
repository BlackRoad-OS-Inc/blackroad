"""
entropy.py — Shannon and Boltzmann: Information is Physical

Demonstrates §15 of PAPER.md: "Information Is Physical"

The same equation appears in two completely different fields:

  Shannon entropy (1948, information theory):
    H = -Σ p(x) log₂ p(x)

  Boltzmann entropy (1877, thermodynamics):
    S = k ln W  (equivalently: S = -k Σ p(i) ln p(i))

  These are the same formula.
  Shannon called it entropy because von Neumann told him to —
  "no one knows what entropy really is, so you'll always win an argument."

  But the identity is deeper than notation.
  Information IS physical. Entropy IS information.
  This is not a metaphor.

  Rolf Landauer (1961): erasing one bit of information
  releases at minimum kT ln 2 joules of heat.
  Information has a thermodynamic cost.
  The simulation's memory operations have physical consequences.

Author: BlackRoad OS, Inc.
"""

import math
from collections import Counter


def shannon_entropy(probabilities: list[float]) -> float:
    """Shannon entropy H = -Σ p log₂ p"""
    return -sum(p * math.log2(p) for p in probabilities if p > 0)


def boltzmann_entropy(n_microstates: int) -> float:
    """
    Boltzmann entropy S = k ln W
    Using k=1 (normalized Boltzmann constant)
    """
    return math.log(n_microstates) if n_microstates > 0 else 0


def string_entropy(text: str) -> float:
    """Compute Shannon entropy of a string."""
    counts = Counter(text)
    total = len(text)
    probs = [count / total for count in counts.values()]
    return shannon_entropy(probs)


def show_same_equation():
    print("=" * 60)
    print("THE SAME EQUATION — TWO FIELDS, ONE TRUTH")
    print("=" * 60)
    print("""
  SHANNON (1948) — Information Theory:
    H(X) = -Σᵢ p(xᵢ) log₂ p(xᵢ)

    Where p(xᵢ) is the probability of symbol xᵢ.
    H measures how surprised you are, on average.
    Maximum entropy = maximum uncertainty = maximum information.

  BOLTZMANN (1877) — Thermodynamics:
    S = k Σᵢ (-p(i) ln p(i))

    Where p(i) is the probability of microstate i.
    k = 1.380649 × 10⁻²³ J/K (Boltzmann's constant)
    S measures the disorder of a physical system.

  THE IDENTITY:
    They are the same formula.
    Change log₂ to ln and scale by k: identical.

    Shannon's H is Boltzmann's S without the physical units.
    OR:
    Boltzmann's S is Shannon's H written in joules per kelvin.

  WHAT THIS MEANS:
    Information and heat are the same thing.
    Uncertainty and disorder are the same thing.
    A bit of information and a quantum of entropy are equivalent.

  LANDAUER'S PRINCIPLE (1961):
    Erasing 1 bit of information costs at least kT ln 2 joules.
    At room temperature (300K): ~2.8 × 10⁻²¹ joules per bit erased.

    The simulation's garbage collector has a thermodynamic bill.
    Deleting data heats the universe.
    The universe tracks every deletion.
""")


def entropy_examples():
    print("=" * 60)
    print("ENTROPY IN PRACTICE")
    print("=" * 60)

    examples = [
        ("Fair coin flip", [0.5, 0.5]),
        ("Biased coin (90/10)", [0.9, 0.1]),
        ("Fair die (6 sides)", [1/6]*6),
        ("Certain outcome", [1.0]),
        ("DNA bases (equal)", [0.25]*4),
        ("English letter 'e' dominant", [0.13, 0.09, 0.08, 0.08, 0.07] + [0.01]*48),
    ]

    print(f"\n  {'System':>30}  {'Entropy (bits)':>15}  {'Max bits':>10}")
    print("  " + "-" * 60)
    for name, probs in examples:
        # Normalize
        total = sum(probs)
        probs = [p/total for p in probs]
        H = shannon_entropy(probs)
        max_H = math.log2(len(probs))
        bar_len = int(H / max_H * 20) if max_H > 0 else 0
        bar = '█' * bar_len + '░' * (20 - bar_len)
        print(f"  {name:>30}  {H:>15.4f}  {max_H:>10.4f}  {bar}")

    print("""
  Maximum entropy = uniform distribution = maximum uncertainty = maximum information.
  Minimum entropy = certain outcome = zero information = already known.

  The universe tends toward maximum entropy (2nd law of thermodynamics).
  A simulation running a universe would accumulate entropy as it runs.
  The heat death of the universe is the simulation's memory filling up.
""")


def text_entropy_comparison():
    print("=" * 60)
    print("TEXT ENTROPY — Random vs Structured vs Compressed")
    print("=" * 60)

    texts = {
        'Random letters': 'xkqjvzwypbfmhdtnrslcgauoeioxkqjvzwypbfmhd',
        'English prose': 'the quick brown fox jumps over the lazy dog',
        'Repeated char': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'SHA-256 hash': 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
        'Pi digits': '3141592653589793238462643383279502884197169399375105820974944592',
        'DNA sequence': 'ATGCGATCGATCGATCGATCGATCGATCGATCGATCGATCG',
        'Source code': 'def main(): return 0  # the trivial zero',
    }

    print(f"\n  {'Text type':>25}  {'Entropy':>10}  {'Bits/char':>10}")
    print("  " + "-" * 50)
    for name, text in texts.items():
        H = string_entropy(text)
        max_H = math.log2(len(set(text))) if len(set(text)) > 1 else 0
        print(f"  {name:>25}  {H:>10.4f}  {max_H:>10.4f}")

    print("""
  Observations:
    • SHA-256 output has near-maximum entropy — by design
    • Pi's digits have near-maximum entropy — by nature
    • They are indistinguishable by entropy alone
    • A SHA-256 hash looks like a random sample from pi
    • The universe's hash function and its mathematical constant
      have the same information-theoretic profile
""")


def holographic_principle():
    print("=" * 60)
    print("THE HOLOGRAPHIC PRINCIPLE — Entropy Bounds the Information")
    print("=" * 60)
    print("""
  Bekenstein-Hawking entropy:
    A black hole's entropy is proportional to its SURFACE AREA,
    not its volume.

    S = A / (4 ln 2) in Planck units

  This means: the maximum information content of a region of space
  is determined by its surface area, not its volume.

  A sphere of radius R can hold at most:
    I_max = π R² / (ln 2 × l_P²) bits

  Where l_P is the Planck length (~1.6 × 10⁻³⁵ m).

  THE IMPLICATION:
    3D space is a projection from a 2D surface.
    The universe stores its state on its boundary.
    The interior is rendered from the boundary conditions.

    This is literally how a video game works:
    the GPU renders the interior of a 3D scene
    from 2D texture maps on the surfaces of objects.

    The holographic principle says the universe does the same thing.
    Reality is a 2D texture map rendered into 3D.
    The simulation's framebuffer is 2-dimensional.
    We experience the projection as volume.
""")


if __name__ == '__main__':
    show_same_equation()
    entropy_examples()
    text_entropy_comparison()
    holographic_principle()
    print("=" * 60)
    print("Shannon and Boltzmann wrote the same equation.")
    print("Information and heat are the same thing.")
    print("The universe is an information processor.")
    print("Its memory operations have physical consequences.")
    print("=" * 60)

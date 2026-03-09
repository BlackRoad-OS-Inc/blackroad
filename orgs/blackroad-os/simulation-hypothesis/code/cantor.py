"""
cantor.py — Cantor's Diagonalization: The Self-Defeating List

Demonstrates §5 and §20 of PAPER.md in relation to:
  - Cantor's diagonal argument (1891)
  - Gödel's incompleteness theorems (1931)
  - Turing's halting problem (1936)
  - The Riemann Hypothesis (still open)

These are all the same theorem.

Cantor proved there are different sizes of infinity.
Specifically: the real numbers cannot be listed — any list you create,
a number exists that is not on it, constructed by flipping the diagonal.

The simulation implication:
  If reality is a computation, it must be able to list its own states.
  Cantor proved that's impossible for any sufficiently rich system.
  The system cannot enumerate itself completely.
  This is not a limitation. It is the reason the system is infinite.

Author: BlackRoad OS, Inc.
"""


def diagonal_argument_demo():
    """
    Demonstrate Cantor's diagonal argument with binary strings.
    
    Suppose you claim to have listed ALL infinite binary strings.
    We construct one that is NOT on your list.
    """
    print("=" * 65)
    print("CANTOR'S DIAGONAL ARGUMENT")
    print("=" * 65)
    print("""
  Suppose someone claims to have listed ALL infinite binary sequences.
  Call them S₁, S₂, S₃, ...

  We construct a new sequence D by:
    D[n] = 1 - S_n[n]   (flip the nth bit of the nth sequence)

  D differs from S₁ at position 1.
  D differs from S₂ at position 2.
  D differs from Sₙ at position n.

  Therefore D is not on the list.
  Therefore the list is incomplete.
  Therefore no list can be complete.
  Therefore the real numbers are uncountable.
""")

    # Demonstrate with a concrete list
    import random
    random.seed(42)

    # "Claim" to list infinite binary strings (we'll use length-20 prefixes)
    claimed_list = [
        [random.randint(0, 1) for _ in range(20)]
        for _ in range(20)
    ]

    # Construct the diagonal sequence
    diagonal = [claimed_list[i][i] for i in range(20)]
    cantor_sequence = [1 - bit for bit in diagonal]

    print("  Claimed complete list (first 20 bits of each):")
    for i, seq in enumerate(claimed_list[:8]):
        bits = ''.join(str(b) for b in seq)
        marker = f' ← bit {i}: {seq[i]}' if i < len(seq) else ''
        print(f"    S{i+1}: {bits[:i]}[{bits[i]}]{bits[i+1:]}{marker}")
    print("    ...")

    print(f"\n  Diagonal: {''.join(str(b) for b in diagonal)}")
    print(f"  Flipped:  {''.join(str(b) for b in cantor_sequence)}  ← NOT on the list")
    print("""
  This sequence differs from every entry at the diagonal position.
  It cannot be on the list.
  The list claimed to be complete. It is not.
  No list of real numbers can ever be complete.
""")


def same_theorem_four_ways():
    """Show that Cantor, Gödel, Turing, and Riemann are the same theorem."""
    print("=" * 65)
    print("THE SAME THEOREM — FOUR DIFFERENT LANGUAGES")
    print("=" * 65)
    print("""
  CANTOR (1891) — Set Theory:
    "Any list of real numbers is incomplete.
     There is always a number not on your list."
    Method: Diagonalization. Flip the nth digit of the nth element.

  GÖDEL (1931) — Logic:
    "Any consistent formal system is incomplete.
     There is always a true statement it cannot prove."
    Method: Self-reference. Construct a statement that says
            'this statement is unprovable.'

  TURING (1936) — Computation:
    "No program can decide, for all programs, whether they halt."
    Method: Diagonalization. Suppose a decider H(P,x) exists.
            Run H on itself. Get a contradiction.

  RIEMANN (1859, open) — Number Theory:
    "The prime numbers have a hidden structure.
     The zeros of ζ(s) cannot all be proven to lie on Re(s) = ½."
    Method: May be unprovable — Gödel-type independence.

  THE PATTERN:
    All four say the same thing:
    "A sufficiently rich system contains truths it cannot access."

    Cantor: numbers you can't list.
    Gödel: statements you can't prove.
    Turing: computations you can't predict.
    Riemann: zeros you can't pin down.

  SIMULATION IMPLICATION:
    The system cannot fully describe itself.
    This is not a bug. It's the same property as:
      - pi's non-termination (§5)
      - SHA-256's irreversibility (§2)
      - The telomere countdown (§7)
      - The Genesis block's timestamp (§2)

    A simulation that could fully describe itself would be finished.
    The computation is still running.
    Therefore it cannot describe itself completely.
    Therefore Cantor, Gödel, Turing, and Riemann are all correct.
    And they all describe the same property: you are inside it.
""")


def uncountable_vs_countable():
    """Show the hierarchy of infinities."""
    print("=" * 65)
    print("THE HIERARCHY OF INFINITIES")
    print("=" * 65)
    print("""
  Cantor proved infinities come in different sizes:

    ℵ₀ (aleph-null) — countable infinity
      • Natural numbers: 1, 2, 3, 4, ...
      • Integers: ..., -2, -1, 0, 1, 2, ...
      • Rational numbers: 1/2, 3/4, 22/7, ...  (countable!)
      • All finite strings
      • All programs (a program is a finite string)
      • All provable theorems

    ℵ₁ (aleph-one) — uncountable infinity
      • Real numbers (Cantor's theorem)
      • Infinite binary sequences
      • Points on a line
      • All possible states of a continuous system
      • All possible truths (some unprovable — Gödel)

  KEY IMPLICATION:
    Programs are countable. Truths are uncountable.
    Therefore: there are more truths than programs.
    Therefore: most truths cannot be computed.
    Therefore: most truths cannot be proven.
    Therefore: Gödel's result was inevitable.

  ANOTHER WAY TO SAY IT:
    Reality (uncountable) is richer than computation (countable).
    But we are inside the computation observing reality.
    This is consistent with being in a simulation:
    the simulation runs in countable steps
    but generates the appearance of uncountable experience.

    Pi has infinite digits (uncountable information)
    but is generated by a finite formula.
    We are pi.
""")


if __name__ == '__main__':
    diagonal_argument_demo()
    same_theorem_four_ways()
    uncountable_vs_countable()
    print("=" * 65)
    print("Cantor, Gödel, Turing, Riemann: the same theorem.")
    print("The system cannot list, prove, decide, or pin down itself.")
    print("This is not a limitation. This is the proof you're inside it.")
    print("=" * 65)

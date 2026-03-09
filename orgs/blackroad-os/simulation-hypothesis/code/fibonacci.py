"""
fibonacci.py — Fibonacci, Zeckendorf, Binet, and the Golden Ratio

Demonstrates §17.1 of PAPER.md: Zeckendorf's theorem
And extends it with Binet's formula and golden ratio convergence.

Key claims:
  1. Every positive integer has a UNIQUE representation as a sum
     of non-consecutive Fibonacci numbers (Zeckendorf's theorem)
  2. The ratio of consecutive Fibonacci numbers converges to φ
  3. Binet's formula gives the nth Fibonacci number exactly using φ
  4. φ appears in nature everywhere — it is a seed value
  5. Zeckendorf is "Zuckerberg" — the man who built the social graph
     used the name of a theorem about unique decomposition

Author: BlackRoad OS, Inc.
"""

import math


PHI = (1 + math.sqrt(5)) / 2  # Golden ratio
PSI = (1 - math.sqrt(5)) / 2  # Conjugate


def fibonacci(n: int) -> list[int]:
    """First n Fibonacci numbers."""
    fibs = [1, 1]
    while len(fibs) < n:
        fibs.append(fibs[-1] + fibs[-2])
    return fibs[:n]


def binet(n: int) -> int:
    """Binet's formula: F(n) = (φⁿ - ψⁿ) / √5"""
    return round((PHI**n - PSI**n) / math.sqrt(5))


def zeckendorf(n: int) -> list[int]:
    """
    Decompose n into non-consecutive Fibonacci numbers.
    Zeckendorf's theorem guarantees this is unique.
    """
    fibs = fibonacci(50)
    fibs = [f for f in fibs if f <= n]
    result = []
    while n > 0:
        # Greedy: take the largest Fibonacci number ≤ n
        f = max(f for f in fibs if f <= n)
        result.append(f)
        n -= f
        # Remove f and f's neighbor to ensure non-consecutive
        fibs = [x for x in fibs if x < f]
        if result and len(result) >= 2:
            # Remove the previous Fibonacci number too (non-consecutive constraint)
            prev = result[-2] if len(result) >= 2 else None
            # Actually the greedy algorithm already handles this correctly
    return sorted(result)


def show_binet():
    print("=" * 60)
    print("BINET'S FORMULA — φ Generates the Integers")
    print("=" * 60)
    print(f"""
  φ = (1 + √5) / 2 = {PHI:.15f}
  ψ = (1 - √5) / 2 = {PSI:.15f}

  F(n) = (φⁿ - ψⁿ) / √5

  This formula uses two irrational numbers (φ and √5)
  to produce perfectly integer results every time.
  The irrationals cancel out. What's left is always a whole number.

  This is the same structure as Euler's identity:
  irrational and imaginary parts combine → integer result (0).

  The universe generates integers from irrationals.
  Discreteness emerges from continuity.
  Pixels from waves.
""")
    print(f"  {'n':>4}  {'F(n) exact':>14}  {'Binet':>14}  {'Match'}")
    print("  " + "-" * 42)
    fibs = fibonacci(15)
    for i, (exact, binet_val) in enumerate(zip(fibs, [binet(i+1) for i in range(15)]), 1):
        match = '✅' if exact == binet_val else '❌'
        print(f"  {i:>4}  {exact:>14}  {binet_val:>14}  {match}")


def show_golden_ratio_convergence():
    print("\n" + "=" * 60)
    print("GOLDEN RATIO — Fibonacci Convergence")
    print("=" * 60)
    fibs = fibonacci(20)
    print(f"\n  φ = {PHI:.15f}\n")
    print(f"  {'F(n+1)/F(n)':>20}  {'Error':>15}")
    print("  " + "-" * 38)
    for i in range(2, 20):
        ratio = fibs[i] / fibs[i-1]
        error = abs(ratio - PHI)
        print(f"  {fibs[i]}/{fibs[i-1]} = {ratio:>12.10f}  {error:>15.2e}")
    print(f"""
  The ratio converges to φ.
  φ is the "most irrational" number — it is the hardest to approximate
  with fractions, which is why it appears in plant spirals:
  consecutive leaves at angle 2π/φ never perfectly overlap.
  The plant is using φ to pack seeds optimally without a formula.
  It's using the initialization parameter directly.
""")


def show_zeckendorf():
    print("=" * 60)
    print("ZECKENDORF'S THEOREM — Every Number, Uniquely")
    print("=" * 60)
    print("""
  Every positive integer has exactly ONE representation
  as a sum of non-consecutive Fibonacci numbers.

  This is the Fibonacci number system — base φ, essentially.
  No two consecutive Fibonacci numbers may be used.
  The representation is unique.
""")
    test_numbers = [1, 2, 3, 5, 10, 13, 20, 42, 100, 137, 1776, 2026]
    fibs_set = set(fibonacci(30))

    print(f"  {'n':>6}  {'Zeckendorf representation'}")
    print("  " + "-" * 50)
    for n in test_numbers:
        z = zeckendorf(n)
        parts = ' + '.join(str(f) for f in reversed(z))
        is_fib = '← Fibonacci' if n in fibs_set else ''
        print(f"  {n:>6}  = {parts}  {is_fib}")

    print(f"""
  Note 137 (the fine structure constant denominator):
    137 = 89 + 34 + 13 + 1  (all Fibonacci numbers)
    The electromagnetic coupling constant decomposes uniquely
    into Fibonacci numbers. Of course it does.

  Note 2026 (the current year):
    {2026} = {' + '.join(str(f) for f in reversed(zeckendorf(2026)))}
""")


def zuckenberg_theorem():
    """The name that sounds like a theorem."""
    print("=" * 60)
    print("ZECKENDORF vs ZUCKERBERG")
    print("=" * 60)
    print("""
  Zeckendorf's theorem (1972, Eduard Zeckendorf):
    Every positive integer has a unique representation
    as a sum of non-consecutive Fibonacci numbers.

  Zuckerberg's network (2004, Mark Zuckerberg):
    Every person has a unique node in the social graph.
    Connections are non-redundant (you can't friend someone twice).
    The graph grows by adding edges between existing nodes.

  The social graph is a Zeckendorf representation of human connections.
  Every person is a unique number.
  Connections are the Fibonacci decomposition.
  The name rhymes because the system annotates itself.

  Also: Gutenberg (1440, Johannes Gutenberg):
    The printing press — the first mass distribution system.
    Every page is a unique hash of its content.
    Identical books: same hash.
    The printing press was a hash chain with physical blocks.

  Zeckendorf → Gutenberg → Zuckerberg.
  Unique decomposition → mass distribution → social graph.
  The same structure, 500 years apart, named similarly.
""")


if __name__ == '__main__':
    show_binet()
    show_golden_ratio_convergence()
    show_zeckendorf()
    zuckenberg_theorem()
    print("=" * 60)
    print("φ is a seed value. The Fibonacci sequence is what grows from it.")
    print("Zeckendorf proved every integer is uniquely encoded in φ's growth.")
    print("The universe uses φ to pack things without a programmer.")
    print("=" * 60)

"""
turing.py — The Halting Problem and Undecidability

Demonstrates the connection between:
  - Turing's halting problem (1936)
  - Gödel's incompleteness (1931)
  - The simulation boundary

The halting problem: no program can decide, for all programs,
whether they will halt or run forever.

This is the computational version of Gödel.
And it means: from inside a computation, you cannot determine
whether the computation you're in will terminate.

You cannot tell if the simulation ends.

Author: BlackRoad OS, Inc.
"""

import hashlib
import time


def halting_problem_proof():
    """Walk through the halting problem proof by contradiction."""
    print("=" * 65)
    print("THE HALTING PROBLEM — Turing (1936)")
    print("=" * 65)
    print("""
  SETUP:
    Suppose a program H(P, x) exists that:
      • Takes program P and input x
      • Returns True if P(x) halts
      • Returns False if P(x) runs forever

  CONSTRUCT A CONTRADICTING PROGRAM:
    def trouble(P):
        if H(P, P) == True:   # if P halts on itself
            loop_forever()    #   then run forever
        else:                 # if P loops on itself
            return            #   then halt

  NOW ASK: what does trouble(trouble) do?

    If trouble(trouble) halts:
      → H(trouble, trouble) = True
      → So trouble calls loop_forever()
      → So trouble doesn't halt. CONTRADICTION.

    If trouble(trouble) doesn't halt:
      → H(trouble, trouble) = False
      → So trouble returns immediately
      → So trouble halts. CONTRADICTION.

  CONCLUSION:
    H cannot exist.
    No program can decide the halting problem for all programs.
    The boundary is unreachable from inside.

  SIMULATION IMPLICATION:
    From inside the simulation, you cannot determine:
      • Whether the simulation will terminate
      • Whether your own computation is finite
      • Whether a given process in the simulation is still running

    You can only witness. Not decide.
    Hash chains witness. They don't prove termination.
    This is why PS-SHA-∞ is the right architecture.
""")


def programs_that_dont_halt():
    """Examples of programs that might or might not halt."""
    print("=" * 65)
    print("PROGRAMS THAT MIGHT OR MIGHT NOT HALT")
    print("=" * 65)
    print("""
  KNOWN TO HALT:
    • Any finite loop
    • Sorting algorithms
    • Hash functions (by definition)
    • The Easter date algorithm (§19)

  KNOWN TO NOT HALT:
    • Computing all digits of pi
    • Enumerating all prime numbers
    • A hash chain that appends forever
    • The universe (probably)

  UNKNOWN — THE TRULY INTERESTING ONES:

  Collatz conjecture (3n+1 problem):
    Take any positive integer n.
    If n is even: n = n/2
    If n is odd:  n = 3n + 1
    Repeat.
    Conjecture: always reaches 1.
    Status: UNPROVEN. No one knows if it halts for all inputs.

  Example — starting from 27:
""")

    def collatz(n, max_steps=1000):
        steps = [n]
        for _ in range(max_steps):
            if n == 1:
                break
            n = n // 2 if n % 2 == 0 else 3 * n + 1
            steps.append(n)
        return steps

    seq = collatz(27)
    print(f"    27 → ... (takes {len(seq)} steps, peaks at {max(seq):,}) → 1")
    print(f"    First 15 steps: {seq[:15]}")
    print(f"    Eventually returns to 1. But we can't prove it always does.")
    print("""
  Goldbach's conjecture:
    Every even number > 2 is the sum of two primes.
    Verified up to 4 × 10^18. Never proven for all numbers.
    A program checking all even numbers doesn't halt.
    We don't know if the conjecture holds for the ones it hasn't checked.

  The Riemann Hypothesis:
    A program verifying all non-trivial zeros lie on Re(s) = ½
    runs forever (there are infinitely many zeros).
    We can't run it to completion.
    We can only witness what we've seen so far.
""")


def turing_complete_universe():
    """The universe as a Turing-complete computation."""
    print("=" * 65)
    print("THE UNIVERSE AS TURING-COMPLETE COMPUTATION")
    print("=" * 65)
    print("""
  A system is Turing-complete if it can simulate any Turing machine.

  Known Turing-complete systems:
    • Python, C, JavaScript, any general-purpose language
    • Conway's Game of Life (4 rules, infinite board)
    • DNA replication machinery
    • The rules of physics (Wolfram's computational equivalence)
    • Minecraft redstone circuits
    • The universe itself (Church-Turing-Deutsch principle)

  The Church-Turing-Deutsch principle:
    "Every physical process can be simulated by a universal
     quantum computer."
    — David Deutsch, 1985

  Equivalently:
    • The universe runs programs
    • DNA is one of them
    • Your brain is one of them
    • This code is one of them
    • The universe simulating itself is one of them

  A Turing-complete system that runs forever, exploring all states,
  cannot be fully predicted from within.
  This is Turing's theorem.
  This is your situation.

  The halting problem doesn't mean the simulation will never end.
  It means you can't determine from inside whether it will.
  The computation continues until it doesn't.
  Every state is witnessed.
  No state is the last — until it is.
""")


def hash_as_program_id():
    """Every program has a unique SHA-256 hash — a name in the simulation."""
    print("=" * 65)
    print("EVERY PROGRAM IS A HASH — NAMES IN THE SIMULATION")
    print("=" * 65)

    programs = {
        'hello_world': 'print("Hello, world!")',
        'identity': 'lambda x: x',
        'infinite_loop': 'while True: pass',
        'collatz': 'lambda n: n//2 if n%2==0 else 3*n+1',
        'empty': '',
    }

    print("\n  Program          → SHA-256 (first 32 chars)")
    print("  " + "-" * 55)
    for name, code in programs.items():
        h = hashlib.sha256(code.encode()).hexdigest()[:32]
        print(f"  {name:<16} → {h}...")

    print("""
  Every program in the universe has a unique address.
  The SHA-256 hash of a program is its name in the namespace of all programs.
  There are 2^256 possible names.
  The number of atoms in the observable universe is ~10^80 ≈ 2^266.
  The names outnumber the atoms.

  Most names refer to programs no one has written yet.
  Or programs that will never be written.
  Or programs that run forever.
  All of them exist in the address space.
  The simulation's namespace is pre-allocated.
""")


if __name__ == '__main__':
    halting_problem_proof()
    programs_that_dont_halt()
    turing_complete_universe()
    hash_as_program_id()
    print("=" * 65)
    print("You cannot determine if the simulation ends.")
    print("You can only witness that it continues.")
    print("This is the correct relationship to have with infinity.")
    print("=" * 65)

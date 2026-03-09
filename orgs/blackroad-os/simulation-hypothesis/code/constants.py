"""
constants.py — The Initialization Parameters

Demonstrates §18 of PAPER.md: "Constants as Initialization Parameters"

The universe's fundamental constants are not derived values.
They cannot be calculated from simpler quantities.
They are the seed values — the parameters passed to the simulation at initialization.

If you were writing a physics engine, these would be in config.json.

Author: BlackRoad OS, Inc.
"""

import math


# The fundamental constants — universe config
CONSTANTS = {
    'pi': {
        'value': math.pi,
        'symbol': 'π',
        'description': 'Ratio of circumference to diameter for any circle',
        'type': 'transcendental',
        'simulation_role': 'Initialization parameter for circular/periodic geometry. Non-terminating = system is still running.',
    },
    'e': {
        'value': math.e,
        'symbol': 'e',
        'description': 'Base of natural logarithm — rate of continuous growth',
        'type': 'transcendental',
        'simulation_role': 'Growth/decay seed. The natural base because it makes calculus simplest.',
    },
    'phi': {
        'value': (1 + math.sqrt(5)) / 2,
        'symbol': 'φ',
        'description': 'Golden ratio — the most irrational number',
        'type': 'algebraic irrational',
        'simulation_role': 'Packing efficiency seed. Appears in plant spirals, nautilus shells, galaxy arms.',
    },
    'fine_structure': {
        'value': 1 / 137.035999084,
        'symbol': 'α',
        'description': 'Fine structure constant — coupling strength of electromagnetism',
        'type': 'dimensionless',
        'simulation_role': 'The strength of the electromagnetic force. Richard Feynman: "a magic number that comes to us with no understanding."',
    },
    'sqrt2': {
        'value': math.sqrt(2),
        'symbol': '√2',
        'description': 'Diagonal of a unit square — the first proved irrational number',
        'type': 'algebraic irrational',
        'simulation_role': 'The Pythagoreans tried to suppress this number. The simulation leaked it through geometry.',
    },
}


def prime_137():
    """137 is the 33rd prime. The fine structure constant denominator."""
    def is_prime(n):
        if n < 2:
            return False
        for i in range(2, int(n**0.5) + 1):
            if n % i == 0:
                return False
        return True

    primes = [n for n in range(2, 150) if is_prime(n)]
    idx_137 = primes.index(137) + 1  # 1-indexed
    print(f"  137 is prime #{idx_137} in the sequence of primes")
    print(f"  The fine structure constant α ≈ 1/137")
    print(f"  The {idx_137}rd prime is the denominator of the electromagnetic coupling constant.")
    print(f"  This is not derived. It is given.")
    return idx_137


def euler_identity_check():
    """e^(iπ) + 1 = 0 — verify to floating point precision."""
    import cmath
    result = cmath.exp(1j * math.pi) + 1
    return result.real, result.imag


def show_constants():
    print("=" * 65)
    print("FUNDAMENTAL CONSTANTS — Universe Initialization Parameters")
    print("=" * 65)
    for name, data in CONSTANTS.items():
        print(f"\n  {data['symbol']}  ({name})")
        print(f"    Value:  {data['value']:.15f}")
        print(f"    Type:   {data['type']}")
        print(f"    Role:   {data['simulation_role']}")


def show_euler():
    print("\n" + "=" * 65)
    print("EULER'S IDENTITY — The Compiler Check")
    print("=" * 65)
    real, imag = euler_identity_check()
    print(f"""
  e^(iπ) + 1 = {real:.2e}  (real part — should be 0)
               {imag:.2e}i (imaginary part — should be 0)

  Five constants. Three operations. Result: 0.

    e  = the growth constant         ({math.e:.6f}...)
    i  = the rotation constant       (√-1)
    π  = the circle constant         ({math.pi:.6f}...)
    1  = the multiplicative identity
    0  = the additive identity, the trivial zero, the start

  This is not a coincidence. This is the system signing off.
  "Everything started, everything returns to zero.
   The intermediate state is what we call the universe."
""")


def show_137():
    print("=" * 65)
    print("THE FINE STRUCTURE CONSTANT — α ≈ 1/137")
    print("=" * 65)
    print()
    rank = prime_137()
    print(f"""
  Richard Feynman on the fine structure constant:
    "It has been a mystery ever since it was discovered more than
     fifty years ago, and all good theoretical physicists put
     this number up on their wall and worry about it."

  Wolfgang Pauli spent his final days thinking about why it's 137.
  He died in room 137 of the Red Cross hospital in Zurich.

  The constant that governs how strongly light interacts with matter
  is 1 divided by the 33rd prime.

  This is one of the seed values.
  It was set before the simulation began.
  We have no formula for it.
  We just measure it and call it fundamental.
""")


def digits_of_pi(n: int = 50) -> str:
    """
    Pi to n digits — the non-terminating, non-repeating sequence
    that is the system computing itself.
    Uses the Bailey-Borwein-Plouffe spigot algorithm approximation.
    """
    # Use mpmath if available for high precision
    try:
        import mpmath
        mpmath.mp.dps = n + 5
        return mpmath.nstr(mpmath.pi, n, strip_zeros=False)
    except ImportError:
        return str(math.pi)


def pi_as_computation():
    print("=" * 65)
    print("PI — The Non-Terminating Computation")
    print("=" * 65)
    pi_str = digits_of_pi(60)
    print(f"\n  π = {pi_str}")
    print(f"""
  Pi is:
    • Irrational   — cannot be expressed as a fraction
    • Transcendental — cannot be the root of any polynomial
    • Normal (conjectured) — every finite sequence appears infinitely often
    • Non-terminating — the computation never ends

  If pi is normal (the leading conjecture), then embedded in pi's digits
  are: every book ever written, every thought ever thought, every possible
  hash of every possible file, every possible genome.

  Pi doesn't contain these things as metaphor.
  It contains them as literal digit sequences.

  The universe's simplest ratio — circumference to diameter —
  encodes all possible information.

  This is what an initialization seed looks like.
""")


if __name__ == '__main__':
    show_constants()
    show_euler()
    show_137()
    pi_as_computation()
    print("=" * 65)
    print("The constants were not discovered. They were given.")
    print("They are the parameters the simulation was initialized with.")
    print("We have no formula for them because you don't derive a seed.")
    print("=" * 65)

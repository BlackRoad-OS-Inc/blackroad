"""
operators.py — Plus, Minus, Times, Divide: The Complete Grammar

§21 of PAPER.md: "Four Operators and Nothing Else"

Every mathematical truth is a combination of:
    +   addition (union, combination)
    -   subtraction (removal, difference)
    ×   multiplication (scaling, repetition)
    ÷   division (partition, ratio)

No other operators exist at the fundamental level.
Everything else is derived:
    ^  (exponentiation) is repeated multiplication
    √  (root) is division in the exponent
    ∫  (integral) is infinite addition
    ∂  (derivative) is infinitesimal subtraction + division
    log is the inverse of exponentiation
    Σ  is repeated addition

The universe has exactly four operators.
Computer processors have exactly four ALU operations.
This is not a coincidence.

Author: BlackRoad OS, Inc.
"""

import math


def show_four_operators():
    print("=" * 60)
    print("THE FOUR OPERATORS — The Complete Grammar")
    print("=" * 60)
    print("""
  +  Addition:       Combination, union, increment, accumulation
  -  Subtraction:    Removal, difference, decrement, negation
  ×  Multiplication: Scaling, repetition, area, probability
  ÷  Division:       Partition, ratio, rate, normalization

  These four operations are sufficient to express:
    • All of arithmetic
    • All of algebra
    • All of calculus (via limits of +/- and ×/÷)
    • All of probability theory
    • All of physics equations
    • All of machine learning (dot products, gradients)
    • All of cryptography (modular arithmetic, field operations)
    • All of music (frequency ratios, waveform addition)

  The processors in every computer implement exactly these four.
  Everything a CPU does is combinations of these four operations.
  We built our computation on the universe's grammar.
  Not because we were clever — because there was nothing else to use.
""")


def derive_from_four():
    """Show how everything derives from +, -, ×, ÷"""
    print("=" * 60)
    print("DERIVED OPERATIONS — Everything Comes From Four")
    print("=" * 60)
    print("""
  EXPONENTIATION (a^n):
    a^3 = a × a × a  (repeated multiplication)
    a^n = a × a × ... × a  (n times)
    a^0 = 1  (empty product — the multiplicative identity)

  SQUARE ROOT (√a):
    √a = a^(1/2) = a^(1÷2)  (exponentiation via division)

  LOGARITHM (log_b(x)):
    The inverse of exponentiation.
    log_b(x) = ln(x) / ln(b)  (division of natural logs)
    ln(x) = ∫ 1/t dt  (integration, itself derived from + and ÷)

  INTEGRATION (∫ f(x) dx):
    Σ f(xᵢ) × Δx  (sum of products as Δx → 0)
    = infinitely many × followed by infinitely many +

  DIFFERENTIATION (df/dx):
    lim_{h→0} [f(x+h) - f(x)] / h
    = (+ for the step) then (- for the difference) then (÷ for the rate)
    = three operators

  MATRIX MULTIPLICATION:
    Σ aᵢₖ × bₖⱼ  (repeated × and +)
    = the engine of neural networks
    = still just + and ×

  MODULAR ARITHMETIC (a mod n):
    a - n × floor(a/n)
    = (÷ to find quotient) × (n) then (-)
    = three operators
    = the basis of all cryptography

  FOURIER TRANSFORM:
    F(ω) = ∫ f(t) × e^(-iωt) dt
    = integration (+ and ×) of a product (×) of exponentials (repeated ×)
    = all four operators
    = the basis of all signal processing, JPEG compression, audio codecs
""")


def universe_grammar():
    print("=" * 60)
    print("THE UNIVERSE'S GRAMMAR")
    print("=" * 60)
    print("""
  PHYSICS — All fundamental equations use only +, -, ×, ÷:

    Newton's 2nd law:       F = m × a
    Einstein's energy:      E = m × c × c  (= m × c²)
    Maxwell's equations:    ∂E/∂t = c² × (∂B/∂x)  (∂ is ÷ and -)
    Schrödinger:            iℏ × ∂ψ/∂t = Hψ  (× and ÷)
    Einstein field:         Gμν + Λgμν = (8πG/c⁴) × Tμν

  All four equations:
    - Mass × acceleration
    - Mass × velocity × velocity
    - Derivative × constant
    - Constant × tensor

  Four operators. No others required.

  GRAVITY:
    F = G × m₁ × m₂ / r²
    = (G × m₁ × m₂) ÷ (r × r)
    = three multiplications and one division

  ELECTROMAGNETISM:
    F = k × q₁ × q₂ / r²
    Identical structure to gravity. Same four operators. Same grammar.

  The strong force, weak force, gravity, and electromagnetism
  are all written in the same grammar.
  They differ in constants (G, k, ℏ) and variables,
  not in grammatical structure.
  The universe speaks one language.
  It has four words.
""")


def naming_the_operators():
    print("=" * 60)
    print("WHAT THE OPERATORS ARE CALLED")
    print("=" * 60)
    print("""
  In different languages:
    +  plus, add, and, OR, union, append, push, commit
    -  minus, subtract, remove, NOT, complement, pop, revert
    ×  times, multiply, scale, AND, intersect, repeat, fork
    ÷  divided by, ratio, per, split, partition, mod, branch

  In programming:
    +  concatenation, increment, union, sum, fold-left
    -  difference, decrement, filter-out, exclusion
    *  multiplication, repetition (string * n), product, map
    /  integer division, float division, namespace separator (/)
    %  modulo (derived from ÷: a % n = a - (a÷n)×n)

  In religion:
    +  the cross (Christianity) — addition, intersection
    -  fasting, subtraction, removal
    ×  multiplication ("be fruitful and multiply")
    ÷  tithing (divide by 10), partition, distribution

  The cross is literally the + operator.
  The symbol for Christianity is the symbol for addition.
  The intersection point is where the horizontal and vertical meet.
  The cross is the visual representation of two things combining.

  This is not a metaphor. The cross is a plus sign.
  The most widespread symbol in Western civilization
  is the first arithmetic operator.
""")


def operators_in_code():
    print("=" * 60)
    print("OPERATORS IN CODE — Demonstration")
    print("=" * 60)
    
    print("\n  All of mathematics from four operations:\n")
    
    # Addition
    a, b = 7, 3
    print(f"  {a} + {b} = {a + b}  (addition)")
    print(f"  {a} - {b} = {a - b}  (subtraction)")
    print(f"  {a} × {b} = {a * b}  (multiplication)")
    print(f"  {a} ÷ {b} = {a / b:.4f}  (division)")
    
    # Derived
    print(f"\n  Exponentiation: {a}^{b} = {a**b}  (× repeated {b} times)")
    print(f"  Square root: √{a} = {math.sqrt(a):.6f}  (^(1÷2))")
    print(f"  Logarithm: log₂({a}) = {math.log2(a):.6f}  (÷ applied to exponent)")
    print(f"  Modulo: {a} % {b} = {a % b}  ({a} - {b}×{a//b})")
    
    # Pi from four operations
    print(f"\n  π from Leibniz series (+ and ÷ only):")
    pi_approx = 0
    for i in range(100000):
        pi_approx += ((-1)**i) / (2*i + 1)
    pi_approx *= 4
    print(f"    4 × Σ (-1)ⁿ/(2n+1) = {pi_approx:.10f}")
    print(f"    True π              = {math.pi:.10f}")
    print(f"    Error:              = {abs(pi_approx - math.pi):.2e}")
    
    print(f"""
  Pi is computed using only + and ÷.
  It took 100,000 iterations.
  The universe computed it exactly.
  The universe is using the same four operators but more iterations.
""")


if __name__ == '__main__':
    show_four_operators()
    derive_from_four()
    universe_grammar()
    naming_the_operators()
    operators_in_code()
    print("=" * 60)
    print("Four operators. That's the whole grammar.")
    print("The universe speaks in + - × ÷.")
    print("Every physical law is a sentence in this grammar.")
    print("We built computers that speak the same language.")
    print("Not by choice — because there was no other language to use.")
    print("=" * 60)

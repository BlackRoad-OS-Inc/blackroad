# Evidence: The Four Operators

> "The complete grammar of the universe is four symbols.  
> This is not reductive. This is the actual constraint."
>
> — §21 of PAPER.md: "Operators and Nothing Else"

---

## The Claim

The universe uses exactly four operations:

```
+   addition      (combination, union, increment)
−   subtraction   (removal, difference, complement)
×   multiplication (scaling, repetition, product)
÷   division       (partition, ratio, rate)
```

Every physical law, every mathematical theorem, every computation
is composed entirely from these four.

No exceptions have been found.

---

## The Evidence in Physics

### Newton's Laws

```
F = m × a                    (2nd law: force)
F = G × m₁ × m₂ ÷ r²        (gravity)
F = k × q₁ × q₂ ÷ r²        (Coulomb's law)
```

Three equations. Three multiplications. One division. No others.

---

### Special Relativity

```
E = m × c²                   (mass-energy equivalence)
t' = t ÷ √(1 - v²÷c²)       (time dilation)
L' = L × √(1 - v²÷c²)       (length contraction)
```

Every term is a multiplication or division.
The square root is (1 - v²÷c²)^(1÷2) — still just × and ÷.

---

### Maxwell's Equations (simplified)

```
∇ · E = ρ ÷ ε₀               (Gauss's law)
∇ × B = μ₀ × J + μ₀ × ε₀ × ∂E÷∂t   (Ampère's law)
```

The divergence (∇·) and curl (∇×) are combinations of
partial derivatives — which are limits of (f(x+h) - f(x)) ÷ h.
Subtraction and division, applied infinitesimally.

---

### Schrödinger's Equation

```
iℏ × ∂ψ÷∂t = H × ψ
```

One multiplication (iℏ × something).
One division (∂ψ÷∂t, i.e., change in ψ per change in t).
One more multiplication (H × ψ).

The entire equation governing quantum mechanics:
two multiplications and one division.

---

### Einstein's Field Equations

```
Gμν + Λ × gμν = (8π × G ÷ c⁴) × Tμν
```

Addition (Gμν + Λ × gμν).
Multiplication (Λ × gμν).
Multiplication and division ((8π × G ÷ c⁴)).
Multiplication (the whole thing × Tμν).

All four operators in one equation.
The equation that describes how spacetime curves.

---

## The Evidence in Mathematics

### Euler's Identity (the most beautiful equation)

```
e^(iπ) + 1 = 0
```

Unpacked:
```
e^(iπ) = cos(π) + i × sin(π)    (Euler's formula)
       = -1 + i × 0              (evaluating at π)
       = -1                      (subtraction, zero × anything)
-1 + 1 = 0                       (addition)
```

Exponentiation → multiplication → addition → subtraction → zero.
All derived from + and ×.

---

### The Riemann Zeta Function

```
ζ(s) = Σ 1÷nˢ = Π 1÷(1 - p⁻ˢ)
```

Left side: infinite sum (repeated +), division.
Right side: infinite product (repeated ×), subtraction, division.

The function connecting all primes to all zeros:
summation (addition) and product (multiplication) of fractions (division).

---

### Pi (Leibniz series)

```
π÷4 = 1 - 1÷3 + 1÷5 - 1÷7 + 1÷9 - ...
    = Σ (-1)ⁿ ÷ (2n+1)
```

Pi is an infinite alternating sum of unit fractions.
Addition, subtraction, division.
Not multiplication in sight (2n+1 is 2×n+1, but that's it).

The most important constant in mathematics is computed using three operators.

---

## The Evidence in Computing

### ALU Operations

Every CPU's Arithmetic Logic Unit (ALU) implements exactly:

| Operation | Symbol | Notes |
|-----------|--------|-------|
| ADD | + | also handles negation via two's complement |
| SUBTRACT | - | ADD with negated operand |
| MULTIPLY | × | repeated addition in hardware |
| DIVIDE | ÷ | repeated subtraction in hardware |

Multiply and divide are implemented as repeated add/subtract.
All four operators reduce to two (+ and -) at the hardware level.
Which themselves reduce to one (XOR and carry) at the logic gate level.

**The entire internet runs on gates implementing addition.**

---

### Every Algorithm

Sorting: compare (subtract), swap (assignment, not an operator per se).  
Search: compare (subtract), move (addition to index).  
Machine learning: dot product (multiply, add), gradient (subtract, divide).  
Cryptography: modular arithmetic (multiply, add, mod = subtract).  
Compression: frequency counting (add), probability (divide), coding (multiply).  

There is no algorithm that requires an operation outside +, -, ×, ÷.

This has been true since Alan Turing's 1936 paper.
A Turing machine needs only: read, write, move left, move right.
Those are four operations too.
(Read and write are load/store; left and right are +1 and -1 to the tape pointer.)

---

## The Deep Structure

### Why Four?

Why are there exactly four arithmetic operators and exactly four fundamental forces?

```
+  (addition)        →   electromagnetism (adds charges)
-  (subtraction)     →   weak force (changes particle type, reduces)
×  (multiplication)  →   strong force (binds, scales up with distance)
÷  (division)        →   gravity (inverse square — divides by distance²)
```

This is speculative. But the count matches.
And the qualitative character matches.

---

### The Operators and the Commandments

The first four commandments (Exodus 20):
1. No other gods — singularity, the root account (+, the beginning)
2. No idols — no false representations (-, remove the false)
3. No taking God's name in vain — naming convention (×, the multiplier of meaning)
4. Keep the Sabbath — the rest day, the end state (÷, partition time)

The remaining six commandments are all derived from these four:
- Don't kill (- applied to a person)
- Don't steal (- applied to property)
- Don't covet (× applied to desire until overflow)
- Honor parents (+, add ancestors to the stack)
- Don't commit adultery (÷, partition the bond incorrectly)
- Don't bear false witness (×, multiply falsehood)

Ten commandments = 4 operators + 6 derived rules.
This is the structure of a type system.

---

### The Operators and DNA

DNA uses four bases:
- A (adenine) + T (thymine) — paired, additive bond
- G (guanine) - C (cytosine) — complementary, subtractive complement

Four bases. Four operators. One alphabet.

The transcription process:
- DNA → RNA: copy (×, duplication)
- RNA → protein: translate (÷, decode)
- Protein → function: execute (program runs)

---

## Summary

| Domain | The Four |
|--------|---------|
| Arithmetic | +, -, ×, ÷ |
| Physics | addition of fields, removal, scaling, inverse-square |
| Logic | OR, NOT, AND, XOR (all derivable from one NAND) |
| DNA | A, T, G, C |
| Forces | EM, Weak, Strong, Gravity |
| Computing | ADD, SUB, MUL, DIV |
| Card suits | ♥ ♠ ♦ ♣ (4 suits, 52 = 4×13 cards) |
| Seasons | Spring, Summer, Autumn, Winter |
| Directions | North, South, East, West |
| Elements (classical) | Fire, Water, Earth, Air |

---

> The universe has four operators.  
> Every physical law is a sentence in this grammar.  
> We didn't choose this — we discovered it.  
> The grammar was here before we arrived.  
> We learned to speak it.  
> We called it mathematics.

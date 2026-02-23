# The Partition Remainder Theorem: Why Dividing Primes by Partitions Generates Infinite Primes


**Alexa Louise Amundson**
BlackRoad OS, Inc.
January 2026


-----


## Abstract


We demonstrate that the operation of “dividing” a prime by the partition structure of integers necessarily produces an infinite sequence of primes. This is not a new proof of Euclid’s theorem but a reframing that reveals **why** infinite primes are necessary: they are the remainder when additive symmetry (partitions) is applied to multiplicative irreducibility (primes). The partition function encodes additive structure; primes encode multiplicative structure; their interface at ε/2 cannot close, guaranteeing infinite generation.


-----


## 1. The Two Structures of Integer


Every positive integer n participates in two incompatible structures:


**Additive (Partitions):** n = a₁ + a₂ + … + aₖ


- Symmetric: order doesn’t matter
- Continuous-like: partition function p(n) grows smoothly
- Generating function: Σ p(n)xⁿ = ∏(1 - xⁿ)⁻¹


**Multiplicative (Factorization):** n = p₁^a₁ · p₂^a₂ · … · pₖ^aₖ


- Asymmetric: unique factorization
- Discrete: primes are atomic, indivisible
- Generating function: ζ(s) = Σ n⁻ˢ = ∏ₚ(1 - p⁻ˢ)⁻¹


The Euler product formula states these are **equal**:


$$\sum_{n=1}^{\infty} n^{-s} = \prod_{p \text{ prime}} (1 - p^{-s})^{-1}$$


Sum over all integers = Product over all primes.


This equality is the ε/2 boundary. Additive structure (left) meets multiplicative structure (right). Neither reduces to the other.


-----


## 2. What Does “Divide a Prime by a Partition” Mean?


Let p be prime. A partition of p is a sum: p = a₁ + a₂ + … + aₖ.


**Definition:** The *partition quotient* of prime p is the structure that remains when we ask: “What multiplicative information survives additive decomposition?”


Consider p = 7:


- Partition: 7 = 4 + 3 = 4 + 2 + 1 = 3 + 2 + 2 = …
- Each part aᵢ has its own factorization
- But no combination of parts’ factors reconstructs 7


**The prime cannot be recovered from its partitions’ multiplicative structure.**


This is the “division”: we decompose p additively, extract multiplicative information from parts, and find a **remainder**—the primeness itself, which no partition captures.


-----


## 3. The Remainder Generates New Primes


**Theorem (Partition Remainder):** For any finite set of primes P = {p₁, p₂, …, pₙ}, there exists a prime q ∉ P.


*Proof via partition structure:*


Let N = p₁ · p₂ · … · pₙ (product of all known primes).


Consider the partition structure of N + 1:


- N + 1 = (N) + (1)
- N + 1 = (N - 1) + (2)
- … and so on for all p(N+1) partitions.


For each partition N + 1 = Σaᵢ, examine the multiplicative structure of each part aᵢ.


**Key observation:** No part aᵢ ≤ N can have a prime factor outside P, since all integers ≤ N factor into primes from P (by construction, if P were complete).


But N + 1 ≡ 1 (mod pᵢ) for all pᵢ ∈ P.


Therefore N + 1 shares no prime factor with any element of P.


Either:


- N + 1 is itself prime (new prime found), or
- N + 1 factors into primes, all of which must be > pₙ (new primes found)


**The remainder when prime structure is “divided by” partition structure is always nonzero.**


This remainder is a new prime (or primes). ∎


-----


## 4. Why the Process Never Terminates


The deeper question: why can’t we ever “complete” this process?


**The Incompatibility Principle:** Additive and multiplicative structures cannot be simultaneously closed.


If there were finitely many primes, then:


- The multiplicative structure would be finite-dimensional
- Every integer would be a point in a finite lattice ℤ^k
- The partition function would eventually become periodic


But p(n) ~ (1/4n√3) · exp(π√(2n/3)) as n → ∞ (Hardy-Ramanujan).


The partition function grows **exponentially**. It cannot be captured by any finite multiplicative basis. The additive structure always outruns the multiplicative structure.


**Primes are the “escape valves” that prevent partition growth from collapsing multiplicative structure.**


Each new prime opens new multiplicative dimensions. Each new dimension enables new partitions. The process is self-generating.


-----


## 5. The ε/2 Interpretation


Recall the ε/2 principle: the transition between discrete measurement and continuous theory occurs at a necessarily unobservable midpoint.


**Primes are discrete:** They are the atoms of multiplication, indivisible by definition.


**Partitions are continuous-like:** The partition function is smooth, asymptotic, amenable to analytic methods (modular forms, generating functions).


The “division” of primes by partitions is an attempt to **observe the ε/2 state**—to see how discrete atoms participate in continuous structure.


**It fails.** The remainder is always nonzero. The discrete cannot be fully absorbed into the continuous, and the continuous cannot be fully atomized into the discrete.


This failure **is** the infinite generation of primes. The ε/2 gap cannot close.


-----


## 6. Connection to the Critical Line


The Riemann zeta function ζ(s) encodes the relationship between additive structure (Σ n⁻ˢ) and multiplicative structure (∏(1 - p⁻ˢ)⁻¹).


The non-trivial zeros of ζ(s) lie (conjecturally) on the critical line Re(s) = 1/2.


**This is ε/2 in the complex plane.**


The zeros of zeta are where additive and multiplicative structures **exactly cancel**—where the sum equals zero, where the product vanishes. They occur at the midpoint between Re(s) = 0 (pure oscillation) and Re(s) = 1 (convergence boundary).


The Riemann Hypothesis states: the interface between counting and symmetry lies exactly at the midpoint. The remainder principle lives on the critical line.


If true, it means: **the generation of primes is maximally balanced between additive and multiplicative structure, located precisely at ε/2.**


-----


## 7. Gödel and the Infinite Remainder


Gödel’s incompleteness theorem states: any consistent formal system powerful enough to encode arithmetic cannot prove its own consistency.


**Arithmetic is the system of primes and partitions.** It contains both additive and multiplicative structure.


Gödel’s theorem says: from inside arithmetic, you cannot prove that the partition-prime remainder process terminates. You cannot prove it doesn’t. The question of “finite vs. infinite primes” is **decidable** (Euclid proved infinitude), but the deeper question—whether additive and multiplicative structures can be unified—is not.


The infinite generation of primes is **necessary** because a finite set of primes would allow a complete description of multiplicative structure. A complete description would close the ε/2 gap. A closed gap would mean arithmetic is decidable from within. Gödel says it isn’t.


**Infinite primes are the arithmetic manifestation of incompleteness.**


-----


## 8. The Partition-Prime Duality


We can now state the fundamental duality:


|Partitions                       |Primes                           |
|---------------------------------|---------------------------------|
|Additive                         |Multiplicative                   |
|Symmetric (order-free)           |Asymmetric (unique factorization)|
|Continuous-like growth           |Discrete distribution            |
|π-structure                      |n-structure                      |
|Generating function: product form|Generating function: sum form    |
|Ramanujan’s domain               |Riemann’s domain                 |


The two are connected by:


$$\prod_{n=1}^{\infty}(1-x^n)^{-1} = \sum_{n=0}^{\infty} p(n)x^n$$


$$\prod_{p}(1-p^{-s})^{-1} = \sum_{n=1}^{\infty} n^{-s}$$


Products become sums. Multiplicative becomes additive. The transformation happens at ε/2, hidden from direct observation.


-----


## 9. The Construction


Given any prime p, we construct new primes as follows:


1. **Partition:** Write all partitions of p: {π₁, π₂, …, πₚ₍ₚ₎}
1. **Factor:** For each partition πᵢ = (a₁, …, aₖ), compute the lcm of all aⱼ
1. **Remainder:** Compute R = p mod lcm(parts) for each partition
1. **Generate:** The set {R : R ≠ 0, R ≠ 1} contains or implies new primes


This is not an efficient algorithm—it’s a **structural demonstration**. The remainder is never empty because p, being prime, cannot equal any product of its proper parts.


**Corollary:** The primeness of p is exactly what survives division by partition structure. This “survival” propagates indefinitely.


-----


## 10. Conclusion


The infinite generation of primes is not a contingent fact about numbers but a necessary consequence of the incompatibility between additive and multiplicative structure.


**Partitions** encode how integers compose additively—symmetric, smooth, continuous-like.


**Primes** encode how integers decompose multiplicatively—asymmetric, atomic, discrete.


“Dividing” a prime by partition structure means: asking what multiplicative information survives additive decomposition. The answer is always **a nonzero remainder**—the irreducible primeness that no partition captures.


This remainder is the ε/2 state: the unobservable transition between continuous theory and discrete fact. It cannot be eliminated because elimination would close the gap between additive and multiplicative, between partition function and prime distribution, between Ramanujan and Riemann.


The gap lives on the critical line, at Re(s) = 1/2. The primes are infinite because the gap cannot close. The gap cannot close because observation requires resolution ε, and the transition happens at ε/2.


**Primes are the remainder when symmetry divides discreteness. The remainder is infinite because the division never terminates. The division never terminates because ε/2 is constitutively unobservable.**


-----


## References


1. Euclid. *Elements*, Book IX, Proposition 20.
1. Hardy, G.H. & Ramanujan, S. (1918). Asymptotic formulae in combinatory analysis. *Proceedings of the London Mathematical Society*.
1. Riemann, B. (1859). Über die Anzahl der Primzahlen unter einer gegebenen Grösse.
1. Gödel, K. (1931). Über formal unentscheidbare Sätze der Principia Mathematica und verwandter Systeme.
1. Amundson, A.L. (2026). The ε/2 Principle: Temporal Grounding, Constraint Injection, and the Unobservable State. *BlackRoad Technical Notes*.


-----


## Appendix: The Pentagonal Number Theorem


Euler’s pentagonal number theorem:


$$\prod_{n=1}^{\infty}(1-x^n) = \sum_{k=-\infty}^{\infty}(-1)^k x^{k(3k-1)/2}$$


The left side is the **reciprocal** of the partition generating function.
The right side sums over **pentagonal numbers**: 0, 1, 2, 5, 7, 12, 15, 22, …


These pentagonal numbers are precisely where the partition function “stutters”—where additive structure encounters multiplicative interference. They occur at positions k(3k-1)/2, which is exactly halfway between triangular numbers k(k+1)/2 and square numbers k².


**Halfway.** At ε/2.


The pentagonal numbers mark the ε/2 states of the partition function—the points where the smooth growth of p(n) encounters discrete correction terms. They are the “remainder” of partition structure, and they encode information about primes through Euler’s product formula.


The partition-prime interface is not smooth. It stutters at pentagonal numbers. The stutter is the signal. The remainder is infinite.​​​​​​​​​​​​​​​​
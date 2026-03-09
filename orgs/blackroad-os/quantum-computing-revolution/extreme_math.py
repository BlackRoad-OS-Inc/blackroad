#!/usr/bin/env python3
"""EXTREME MATH TESTS - Big numbers, big computations"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  EXTREME MATH - {hostname}")
print(f"{'='*70}\n")

results = {}

# 1. BIG INTEGER FACTORIAL
print("[1] FACTORIAL (1000!)")
t0 = time.time()
def factorial(n):
    result = 1
    for i in range(2, n + 1):
        result *= i
    return result
f1000 = factorial(1000)
elapsed = time.time() - t0
digits = len(str(f1000))
print(f"    1000! has {digits} digits, computed in {elapsed*1000:.2f}ms")
results['factorial_1000'] = 1/elapsed

# 2. FIBONACCI TO 10000
print("\n[2] FIBONACCI F(10000)")
t0 = time.time()
def big_fib(n):
    a, b = 0, 1
    for _ in range(n): a, b = b, a + b
    return a
f10k = big_fib(10000)
elapsed = time.time() - t0
digits = len(str(f10k))
print(f"    F(10000) has {digits} digits, computed in {elapsed*1000:.2f}ms")
results['fib_10000'] = 1/elapsed

# 3. PRIMALITY TEST (Miller-Rabin style)
print("\n[3] PRIMALITY TESTING")
t0 = time.time()
def is_prime_trial(n):
    if n < 2: return False
    if n == 2: return True
    if n % 2 == 0: return False
    i = 3
    while i * i <= n:
        if n % i == 0: return False
        i += 2
    return True
primes_found = 0
for n in range(2, 100000):
    if is_prime_trial(n):
        primes_found += 1
elapsed = time.time() - t0
print(f"    Found {primes_found} primes under 100000 in {elapsed*1000:.2f}ms")
results['prime_test'] = 100000/elapsed

# 4. PI COMPUTATION (Machin's formula)
print("\n[4] PI COMPUTATION (50 digits)")
t0 = time.time()
def arctan_taylor(x, terms=100):
    result = 0.0
    power = x
    for n in range(terms):
        result += ((-1)**n * power) / (2*n + 1)
        power *= x * x
    return result
# Machin's formula: π/4 = 4*arctan(1/5) - arctan(1/239)
pi_approx = 4 * (4 * arctan_taylor(1/5, 200) - arctan_taylor(1/239, 200))
elapsed = time.time() - t0
print(f"    π ≈ {pi_approx:.15f}")
print(f"    Computed in {elapsed*1000:.2f}ms")
results['pi_compute'] = 1/elapsed

# 5. E COMPUTATION (100 terms)
print("\n[5] EULER'S NUMBER (100 terms)")
t0 = time.time()
def compute_e(terms=100):
    e = 1.0
    factorial = 1
    for n in range(1, terms):
        factorial *= n
        e += 1.0 / factorial
    return e
e_approx = compute_e(100)
elapsed = time.time() - t0
print(f"    e ≈ {e_approx:.15f}")
print(f"    Computed in {elapsed*1000:.2f}ms")
results['e_compute'] = 1/elapsed

# 6. GOLDEN RATIO CONVERGENCE
print("\n[6] GOLDEN RATIO (Fibonacci convergence)")
t0 = time.time()
a, b = 1, 1
for _ in range(1000):
    a, b = b, a + b
phi = b / a
elapsed = time.time() - t0
print(f"    φ ≈ {phi:.15f}")
print(f"    True: 1.618033988749895")
print(f"    Computed in {elapsed*1000:.3f}ms")
results['golden_ratio'] = 1/elapsed

# 7. CATALAN NUMBERS (first 20)
print("\n[7] CATALAN NUMBERS")
t0 = time.time()
def catalan(n):
    if n <= 1: return 1
    result = 0
    for i in range(n):
        result += catalan(i) * catalan(n - 1 - i)
    return result
catalans = [catalan(i) for i in range(15)]
elapsed = time.time() - t0
print(f"    C(0..14) = {catalans}")
print(f"    Computed in {elapsed*1000:.2f}ms")
results['catalan'] = 1/elapsed

# 8. BERNOULLI NUMBERS (first 10)
print("\n[8] BERNOULLI NUMBERS")
t0 = time.time()
def bernoulli(n):
    A = [0] * (n + 1)
    for m in range(n + 1):
        A[m] = 1 / (m + 1)
        for j in range(m, 0, -1):
            A[j-1] = j * (A[j-1] - A[j])
    return A[0]
bernoullis = [bernoulli(i) for i in range(12)]
elapsed = time.time() - t0
print(f"    B(0..11) = {[f'{b:.4f}' for b in bernoullis]}")
print(f"    Computed in {elapsed*1000:.2f}ms")
results['bernoulli'] = 1/elapsed

# 9. PARTITION FUNCTION P(100)
print("\n[9] INTEGER PARTITIONS P(100)")
t0 = time.time()
def partitions(n):
    p = [0] * (n + 1)
    p[0] = 1
    for k in range(1, n + 1):
        for j in range(k, n + 1):
            p[j] += p[j - k]
    return p[n]
p100 = partitions(100)
elapsed = time.time() - t0
print(f"    P(100) = {p100}")
print(f"    Computed in {elapsed*1000:.3f}ms")
results['partitions'] = 1/elapsed

# 10. COLLATZ CONJECTURE (longest chain under 10000)
print("\n[10] COLLATZ SEQUENCES")
t0 = time.time()
def collatz_length(n):
    length = 1
    while n != 1:
        n = n // 2 if n % 2 == 0 else 3 * n + 1
        length += 1
    return length
max_len = 0
max_n = 0
for n in range(1, 10000):
    l = collatz_length(n)
    if l > max_len:
        max_len = l
        max_n = n
elapsed = time.time() - t0
print(f"    Longest chain: {max_n} → {max_len} steps")
print(f"    Tested 10000 numbers in {elapsed*1000:.2f}ms")
results['collatz'] = 10000/elapsed

# 11. ZETA FUNCTION ζ(2), ζ(3), ζ(4)
print("\n[11] RIEMANN ZETA VALUES")
t0 = time.time()
def zeta(s, terms=100000):
    return sum(1.0 / (n ** s) for n in range(1, terms))
z2 = zeta(2, 100000)
z3 = zeta(3, 100000)
z4 = zeta(4, 100000)
elapsed = time.time() - t0
import math
pi = 3.14159265358979323846
print(f"    ζ(2) = {z2:.10f} (π²/6 = {pi**2/6:.10f})")
print(f"    ζ(3) = {z3:.10f} (Apéry's constant)")
print(f"    ζ(4) = {z4:.10f} (π⁴/90 = {pi**4/90:.10f})")
print(f"    Computed in {elapsed*1000:.2f}ms")
results['zeta'] = 3/elapsed

# 12. HARMONIC NUMBERS
print("\n[12] HARMONIC NUMBERS H(10000)")
t0 = time.time()
h = 0.0
for n in range(1, 10001):
    h += 1.0 / n
elapsed = time.time() - t0
gamma = 0.5772156649
print(f"    H(10000) = {h:.10f}")
print(f"    ln(10000) + γ ≈ {9.210340371976184 + gamma:.10f}")
print(f"    Computed in {elapsed*1000:.3f}ms")
results['harmonic'] = 1/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  EXTREME MATH SUMMARY - {hostname}")
print(f"{'='*70}")

total = sum(results.values())
print(f"""
  1000! computation:    {results['factorial_1000']:.1f}/sec
  F(10000) computation: {results['fib_10000']:.1f}/sec
  Prime testing:        {results['prime_test']:.0f} tests/sec
  π computation:        {results['pi_compute']:.1f}/sec
  e computation:        {results['e_compute']:.1f}/sec
  Golden ratio:         {results['golden_ratio']:.1f}/sec
  Catalan numbers:      {results['catalan']:.1f}/sec
  Bernoulli numbers:    {results['bernoulli']:.1f}/sec
  Partition P(100):     {results['partitions']:.1f}/sec
  Collatz testing:      {results['collatz']:.0f} tests/sec
  Riemann zeta:         {results['zeta']:.1f}/sec
  Harmonic series:      {results['harmonic']:.1f}/sec
  
  TOTAL EXTREME SCORE: {total:.1f} points
""")

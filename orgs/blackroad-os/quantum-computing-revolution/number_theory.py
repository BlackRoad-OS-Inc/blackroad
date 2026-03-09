#!/usr/bin/env python3
"""NUMBER THEORY - Deep mathematical exploration"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  NUMBER THEORY EXPERIMENTS - {hostname}")
print(f"{'='*70}\n")

def sqrt(x):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(25): g = (g + x/g) / 2.0
    return g

def gcd(a, b):
    while b: a, b = b, a % b
    return a

def lcm(a, b):
    return a * b // gcd(a, b)

results = {}

# 1. PRIME COUNTING FUNCTION π(n)
print("[1] PRIME COUNTING π(n)")
print("-" * 50)

def sieve(n):
    is_prime = [True] * (n + 1)
    is_prime[0] = is_prime[1] = False
    for i in range(2, int(sqrt(n)) + 1):
        if is_prime[i]:
            for j in range(i*i, n + 1, i):
                is_prime[j] = False
    return is_prime

t0 = time.time()
is_p = sieve(1000000)
primes_to_1m = sum(is_p)
elapsed = time.time() - t0
# π(10^6) = 78,498
print(f"    π(1,000,000) = {primes_to_1m} (theory: 78,498)")
print(f"    Time: {elapsed*1000:.2f}ms")
results['prime_count'] = 1/elapsed

# Prime gaps
gaps = []
prev = 2
for i in range(3, 100000):
    if is_p[i]:
        gaps.append(i - prev)
        prev = i
max_gap = max(gaps)
avg_gap = sum(gaps) / len(gaps)
print(f"    Max gap under 100K: {max_gap}")
print(f"    Avg gap: {avg_gap:.2f}")

# 2. TWIN PRIMES
print("\n[2] TWIN PRIMES")
print("-" * 50)

t0 = time.time()
twins = []
for i in range(3, 1000000-2):
    if is_p[i] and is_p[i+2]:
        twins.append((i, i+2))
elapsed = time.time() - t0
print(f"    Twin primes under 1M: {len(twins)}")
print(f"    First 5: {twins[:5]}")
print(f"    Last 5: {twins[-5:]}")
print(f"    Time: {elapsed*1000:.2f}ms")
results['twins'] = len(twins)/elapsed

# 3. GOLDBACH CONJECTURE VERIFICATION
print("\n[3] GOLDBACH CONJECTURE")
print("-" * 50)

t0 = time.time()
verified = 0
counterexamples = []
for n in range(4, 100001, 2):
    found = False
    for p in range(2, n//2 + 1):
        if is_p[p] and is_p[n - p]:
            found = True
            break
    if found:
        verified += 1
    else:
        counterexamples.append(n)
elapsed = time.time() - t0
print(f"    Even numbers 4-100000: {verified} verified")
print(f"    Counterexamples: {len(counterexamples)}")
print(f"    Time: {elapsed*1000:.2f}ms")
results['goldbach'] = verified/elapsed

# 4. PERFECT NUMBERS
print("\n[4] PERFECT NUMBERS")
print("-" * 50)

def sum_divisors(n):
    total = 1
    i = 2
    while i * i <= n:
        if n % i == 0:
            total += i
            if i != n // i:
                total += n // i
        i += 1
    return total

t0 = time.time()
perfect = []
for n in range(2, 100001):
    if sum_divisors(n) == n:
        perfect.append(n)
elapsed = time.time() - t0
print(f"    Perfect numbers under 100K: {perfect}")
print(f"    Time: {elapsed*1000:.2f}ms")
results['perfect'] = 100000/elapsed

# 5. AMICABLE NUMBERS
print("\n[5] AMICABLE NUMBERS")
print("-" * 50)

t0 = time.time()
amicable = []
for a in range(2, 100001):
    b = sum_divisors(a)
    if b > a and b <= 100000:
        if sum_divisors(b) == a:
            amicable.append((a, b))
elapsed = time.time() - t0
print(f"    Amicable pairs under 100K: {amicable}")
print(f"    Time: {elapsed*1000:.2f}ms")
results['amicable'] = 100000/elapsed

# 6. EULER'S TOTIENT φ(n)
print("\n[6] EULER'S TOTIENT φ(n)")
print("-" * 50)

def totient(n):
    result = n
    p = 2
    while p * p <= n:
        if n % p == 0:
            while n % p == 0:
                n //= p
            result -= result // p
        p += 1
    if n > 1:
        result -= result // n
    return result

t0 = time.time()
totients = [totient(n) for n in range(1, 10001)]
elapsed = time.time() - t0
print(f"    φ(1) to φ(10000) computed")
print(f"    φ(100) = {totients[99]} (theory: 40)")
print(f"    φ(1000) = {totients[999]} (theory: 400)")
print(f"    Time: {elapsed*1000:.2f}ms")
results['totient'] = 10000/elapsed

# 7. MOBIUS FUNCTION μ(n)
print("\n[7] MÖBIUS FUNCTION μ(n)")
print("-" * 50)

def mobius(n):
    if n == 1: return 1
    p = 0
    for i in range(2, int(sqrt(n)) + 1):
        if n % i == 0:
            n //= i
            p += 1
            if n % i == 0:  # squared factor
                return 0
    if n > 1:
        p += 1
    return -1 if p % 2 else 1

t0 = time.time()
mu = [mobius(n) for n in range(1, 10001)]
elapsed = time.time() - t0
print(f"    μ(1) to μ(10000) computed")
print(f"    Sum μ(n) for n=1..100: {sum(mu[:100])}")
print(f"    Time: {elapsed*1000:.2f}ms")
results['mobius'] = 10000/elapsed

# 8. CONTINUED FRACTIONS
print("\n[8] CONTINUED FRACTIONS")
print("-" * 50)

def cf_expansion(num, den, terms=20):
    """Get continued fraction expansion of num/den"""
    cf = []
    for _ in range(terms):
        if den == 0: break
        q = num // den
        cf.append(q)
        num, den = den, num - q * den
    return cf

def cf_convergent(cf):
    """Compute convergent from continued fraction"""
    if not cf: return (0, 1)
    n, d = cf[-1], 1
    for i in range(len(cf) - 2, -1, -1):
        n, d = cf[i] * n + d, n
    return (n, d)

t0 = time.time()
# Golden ratio φ = [1; 1, 1, 1, ...]
golden_cf = [1] * 20
phi_n, phi_d = cf_convergent(golden_cf)
phi_approx = phi_n / phi_d

# sqrt(2) = [1; 2, 2, 2, ...]
sqrt2_cf = [1] + [2] * 19
sqrt2_n, sqrt2_d = cf_convergent(sqrt2_cf)
sqrt2_approx = sqrt2_n / sqrt2_d

# e = [2; 1, 2, 1, 1, 4, 1, 1, 6, 1, 1, 8, ...]
e_cf = [2, 1, 2, 1, 1, 4, 1, 1, 6, 1, 1, 8, 1, 1, 10, 1, 1, 12, 1, 1]
e_n, e_d = cf_convergent(e_cf)
e_approx = e_n / e_d

elapsed = time.time() - t0
print(f"    φ ≈ {phi_approx:.15f} (from CF)")
print(f"    √2 ≈ {sqrt2_approx:.15f} (from CF)")
print(f"    e ≈ {e_approx:.15f} (from CF)")
print(f"    Time: {elapsed*1000:.3f}ms")
results['cf'] = 1/elapsed

# 9. FERMAT'S LITTLE THEOREM
print("\n[9] FERMAT'S LITTLE THEOREM")
print("-" * 50)

def mod_pow(base, exp, mod):
    result = 1
    base = base % mod
    while exp > 0:
        if exp & 1: result = (result * base) % mod
        exp >>= 1
        base = (base * base) % mod
    return result

t0 = time.time()
verified = 0
for p in range(2, 10001):
    if is_p[p]:
        # For prime p and any a not divisible by p: a^(p-1) ≡ 1 (mod p)
        for a in [2, 3, 5, 7]:
            if mod_pow(a, p-1, p) == 1:
                verified += 1
elapsed = time.time() - t0
print(f"    Verified for {verified} (prime, base) pairs")
print(f"    Time: {elapsed*1000:.2f}ms")
results['fermat'] = verified/elapsed

# 10. QUADRATIC RESIDUES
print("\n[10] QUADRATIC RESIDUES")
print("-" * 50)

def legendre(a, p):
    """Legendre symbol (a/p)"""
    if a % p == 0: return 0
    result = mod_pow(a, (p-1)//2, p)
    return -1 if result == p - 1 else result

t0 = time.time()
# Count quadratic residues mod primes
residue_counts = []
primes_list = [p for p in range(3, 1000) if is_p[p]]
for p in primes_list:
    residues = sum(1 for a in range(1, p) if legendre(a, p) == 1)
    residue_counts.append(residues)
elapsed = time.time() - t0
# Theory: exactly (p-1)/2 quadratic residues
print(f"    Checked {len(primes_list)} primes")
print(f"    QR count for p=97: {residue_counts[primes_list.index(97)]} (theory: 48)")
print(f"    Time: {elapsed*1000:.2f}ms")
results['qr'] = len(primes_list)/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  NUMBER THEORY SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  Prime counting:       {results['prime_count']:.2f} sieves/sec
  Twin primes:          {results['twins']:.0f} pairs/sec
  Goldbach:             {results['goldbach']:.0f} verifications/sec
  Perfect numbers:      {results['perfect']:.0f} checks/sec
  Amicable numbers:     {results['amicable']:.0f} checks/sec
  Euler's totient:      {results['totient']:.0f} φ(n)/sec
  Möbius function:      {results['mobius']:.0f} μ(n)/sec
  Continued fractions:  {results['cf']:.0f} expansions/sec
  Fermat's theorem:     {results['fermat']:.0f} verifications/sec
  Quadratic residues:   {results['qr']:.0f} primes/sec
  
  TOTAL NUMBER THEORY SCORE: {total:.0f} points
""")

#!/usr/bin/env python3
"""CRYPTO SPEED TEST - Pure arithmetic cryptography"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  CRYPTO SPEED TEST - {hostname}")
print(f"{'='*70}\n")

def gcd(a, b):
    while b: a, b = b, a % b
    return a

def mod_pow(base, exp, mod):
    result = 1
    base = base % mod
    while exp > 0:
        if exp & 1: result = (result * base) % mod
        exp >>= 1
        base = (base * base) % mod
    return result

def mod_inverse(e, phi):
    def ext_gcd(a, b):
        if a == 0: return b, 0, 1
        g, x1, y1 = ext_gcd(b % a, a)
        return g, y1 - (b // a) * x1, x1
    g, x, _ = ext_gcd(e % phi, phi)
    if g != 1: return None
    return (x % phi + phi) % phi

def pollard_rho(n):
    if n % 2 == 0: return 2
    x, y, d = 2, 2, 1
    f = lambda x: (x * x + 1) % n
    while d == 1:
        x = f(x)
        y = f(f(y))
        d = gcd(abs(x - y), n)
    return d if d != n else None

results = {}

# 1. RSA KEY GENERATION SPEED
print("[1] RSA-STYLE MODULAR ARITHMETIC")
primes = [7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,293,307,311,313]

t0 = time.time()
keys_generated = 0
for i in range(100):
    p = primes[i % 30]
    q = primes[(i * 3 + 7) % 30]
    if p == q: continue
    n = p * q
    phi = (p - 1) * (q - 1)
    e = 65537
    if gcd(e, phi) != 1:
        e = 3 if gcd(3, phi) == 1 else 7
    d = mod_inverse(e, phi)
    if d:
        keys_generated += 1
elapsed = time.time() - t0
print(f"    Generated {keys_generated} RSA keys: {keys_generated/elapsed:.0f} keys/sec")
results['rsa_keygen'] = keys_generated/elapsed

# 2. RSA ENCRYPT/DECRYPT
print("[2] RSA ENCRYPT/DECRYPT")
p, q = 61, 53
n = p * q
phi = (p-1) * (q-1)
e = 17
d = mod_inverse(e, phi)

t0 = time.time()
for _ in range(1000):
    m = 123
    c = mod_pow(m, e, n)
    m2 = mod_pow(c, d, n)
elapsed = time.time() - t0
print(f"    1000 encrypt+decrypt: {1000/elapsed:.0f} cycles/sec")
results['rsa_encdec'] = 1000/elapsed

# 3. DIFFIE-HELLMAN KEY EXCHANGE
print("[3] DIFFIE-HELLMAN KEY EXCHANGE")
p_dh = 23
g = 5

t0 = time.time()
exchanges = 0
for i in range(10000):
    a = (i * 17 + 3) % (p_dh - 1) + 1
    A = mod_pow(g, a, p_dh)
    b = (i * 13 + 7) % (p_dh - 1) + 1
    B = mod_pow(g, b, p_dh)
    s_alice = mod_pow(B, a, p_dh)
    s_bob = mod_pow(A, b, p_dh)
    if s_alice == s_bob:
        exchanges += 1
elapsed = time.time() - t0
print(f"    {exchanges} DH exchanges: {exchanges/elapsed:.0f} exchanges/sec")
results['dh_exchange'] = exchanges/elapsed

# 4. HASH FUNCTIONS
print("[4] HASH FUNCTIONS")

def simple_hash(data):
    h = 0x811c9dc5
    for byte in data:
        h ^= byte
        h = (h * 0x01000193) & 0xFFFFFFFF
    return h

test_data = bytes("The quick brown fox jumps over the lazy dog" * 10, 'utf-8')

t0 = time.time()
for _ in range(50000):
    h = simple_hash(test_data)
elapsed = time.time() - t0
print(f"    FNV-1a hash: {50000/elapsed:.0f} hashes/sec")
results['fnv_hash'] = 50000/elapsed

# 5. ELLIPTIC CURVE
print("[5] ELLIPTIC CURVE OPERATIONS")
p_ec = 23
a_ec = 1

def ec_add(P, Q, a, p):
    if P is None: return Q
    if Q is None: return P
    x1, y1 = P
    x2, y2 = Q
    if x1 == x2 and y1 != y2: return None
    if x1 == x2:
        inv = mod_inverse(2 * y1 % p, p)
        if inv is None: return None
        m = ((3 * x1 * x1 + a) * inv) % p
    else:
        inv = mod_inverse((x2 - x1) % p, p)
        if inv is None: return None
        m = ((y2 - y1) * inv) % p
    x3 = (m * m - x1 - x2) % p
    y3 = (m * (x1 - x3) - y1) % p
    return (x3, y3)

def ec_mul(k, P, a, p):
    result = None
    while k:
        if k & 1:
            result = ec_add(result, P, a, p)
        P = ec_add(P, P, a, p)
        k >>= 1
    return result

G = (0, 1)
t0 = time.time()
for k in range(1, 1001):
    P = ec_mul(k, G, a_ec, p_ec)
elapsed = time.time() - t0
print(f"    EC multiply: {1000/elapsed:.0f} muls/sec")
results['ec_mul'] = 1000/elapsed

# 6. FACTORIZATION
print("[6] FACTORIZATION ATTACK")
composites = [77, 91, 143, 221, 323, 437, 667, 899, 1147, 1517, 2021, 2701, 3233, 4087, 5183, 6557, 8633, 10403, 12317, 16637]

t0 = time.time()
cracked = 0
for n in composites:
    p = pollard_rho(n)
    if p and p != n and n % p == 0:
        cracked += 1
elapsed = time.time() - t0
print(f"    Factored {cracked}/{len(composites)}: {len(composites)/elapsed:.0f}/sec")
results['factor'] = len(composites)/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  CRYPTO SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"  RSA Keygen:    {results['rsa_keygen']:.0f}/sec")
print(f"  RSA Enc/Dec:   {results['rsa_encdec']:.0f}/sec")
print(f"  DH Exchange:   {results['dh_exchange']:.0f}/sec")
print(f"  FNV Hash:      {results['fnv_hash']:.0f}/sec")
print(f"  EC Multiply:   {results['ec_mul']:.0f}/sec")
print(f"  Factoring:     {results['factor']:.0f}/sec")
print(f"\n  TOTAL: {total:.0f} points")

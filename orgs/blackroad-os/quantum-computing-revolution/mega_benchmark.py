#!/usr/bin/env python3
"""
MEGA BENCHMARK - Every metric we can measure
=============================================
"""
import time
import socket

hostname = socket.gethostname()

# ============================================================================
# PURE ARITHMETIC PRIMITIVES
# ============================================================================

def sqrt(x, iters=20):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(iters): g = (g + x/g) / 2.0
    return g

def sin(x, terms=15):
    PI = 3.14159265358979323846
    while x > PI: x -= 2*PI
    while x < -PI: x += 2*PI
    r, t = 0.0, x
    for n in range(terms):
        r = r + t if n % 2 == 0 else r - t
        t = t * x * x / ((2*n+2) * (2*n+3))
    return r

def cos(x, terms=15):
    PI = 3.14159265358979323846
    while x > PI: x -= 2*PI
    while x < -PI: x += 2*PI
    r, t = 1.0, 1.0
    for n in range(1, terms):
        t = t * (-x*x) / ((2*n-1) * (2*n))
        r += t
    return r

def exp(x, terms=25):
    r, t = 1.0, 1.0
    for n in range(1, terms):
        t = t * x / n
        r += t
    return r

def ln(x, terms=50):
    if x <= 0: return 0
    k = 0
    E = 2.718281828459045
    while x > E: x /= E; k += 1
    while x < 1/E: x *= E; k -= 1
    z = (x-1)/(x+1)
    r, t = 0.0, z
    for n in range(terms):
        r += t / (2*n+1)
        t *= z*z
    return 2*r + k

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

# ============================================================================
# BENCHMARKS
# ============================================================================

results = {}

print(f"{'='*70}")
print(f"  MEGA BENCHMARK - {hostname}")
print(f"{'='*70}\n")

# 1. FIBONACCI
print("[1] FIBONACCI SEQUENCE")
t0 = time.time()
def fib(n):
    a, b = 0, 1
    for _ in range(n): a, b = b, a + b
    return a
for i in range(1000):
    fib(100)
elapsed = time.time() - t0
ops = 1000 * 100
print(f"    1000×fib(100): {elapsed*1000:.2f}ms ({ops/elapsed/1e6:.2f}M ops/sec)")
results['fibonacci'] = ops/elapsed/1e6

# 2. TRIGONOMETRY
print("\n[2] TRIGONOMETRY (sin/cos Taylor series)")
t0 = time.time()
for i in range(10000):
    s = sin(i * 0.001)
    c = cos(i * 0.001)
elapsed = time.time() - t0
print(f"    10000 sin+cos: {elapsed*1000:.2f}ms ({20000/elapsed/1e3:.1f}K calls/sec)")
results['trig'] = 20000/elapsed/1e3

# 3. EXPONENTIAL/LOG
print("\n[3] EXPONENTIAL/LOGARITHM")
t0 = time.time()
for i in range(5000):
    e = exp(i * 0.001)
    l = ln(i * 0.001 + 1)
elapsed = time.time() - t0
print(f"    5000 exp+ln: {elapsed*1000:.2f}ms ({10000/elapsed/1e3:.1f}K calls/sec)")
results['exp_ln'] = 10000/elapsed/1e3

# 4. SQUARE ROOT
print("\n[4] SQUARE ROOT (Newton-Raphson)")
t0 = time.time()
for i in range(50000):
    s = sqrt(i + 1)
elapsed = time.time() - t0
print(f"    50000 sqrt: {elapsed*1000:.2f}ms ({50000/elapsed/1e3:.1f}K calls/sec)")
results['sqrt'] = 50000/elapsed/1e3

# 5. GCD (Euclidean)
print("\n[5] GCD (Euclidean Algorithm)")
t0 = time.time()
for i in range(100000):
    g = gcd(i * 17 + 12345, i * 13 + 67890)
elapsed = time.time() - t0
print(f"    100000 gcd: {elapsed*1000:.2f}ms ({100000/elapsed/1e6:.2f}M calls/sec)")
results['gcd'] = 100000/elapsed/1e6

# 6. MODULAR EXPONENTIATION
print("\n[6] MODULAR EXPONENTIATION (RSA core)")
t0 = time.time()
for i in range(1000):
    m = mod_pow(i + 2, 65537, 1000003)
elapsed = time.time() - t0
print(f"    1000 mod_pow: {elapsed*1000:.2f}ms ({1000/elapsed/1e3:.1f}K calls/sec)")
results['mod_pow'] = 1000/elapsed/1e3

# 7. PRIME SIEVE
print("\n[7] PRIME SIEVE (Eratosthenes)")
t0 = time.time()
def sieve(n):
    is_prime = [True] * (n + 1)
    is_prime[0] = is_prime[1] = False
    for i in range(2, int(sqrt(n)) + 1):
        if is_prime[i]:
            for j in range(i*i, n + 1, i):
                is_prime[j] = False
    return sum(is_prime)
for _ in range(10):
    count = sieve(100000)
elapsed = time.time() - t0
print(f"    10×sieve(100000): {elapsed*1000:.2f}ms (found {count} primes)")
results['sieve'] = 10/elapsed

# 8. MATRIX MULTIPLY
print("\n[8] MATRIX MULTIPLICATION (4x4)")
t0 = time.time()
def mat_mul(A, B):
    n = len(A)
    C = [[0]*n for _ in range(n)]
    for i in range(n):
        for j in range(n):
            for k in range(n):
                C[i][j] += A[i][k] * B[k][j]
    return C
A = [[i*4+j for j in range(4)] for i in range(4)]
B = [[i*4+j+1 for j in range(4)] for i in range(4)]
for _ in range(10000):
    C = mat_mul(A, B)
elapsed = time.time() - t0
print(f"    10000 4x4 matmul: {elapsed*1000:.2f}ms ({10000/elapsed/1e3:.1f}K muls/sec)")
results['matmul_4x4'] = 10000/elapsed/1e3

# 9. FFT-LIKE (DFT on 64 points)
print("\n[9] DFT (64-point)")
PI = 3.14159265358979323846
t0 = time.time()
def dft64(signal):
    N = 64
    result = []
    for k in range(N):
        re, im = 0.0, 0.0
        for n in range(N):
            angle = -2 * PI * k * n / N
            re += signal[n] * cos(angle)
            im += signal[n] * sin(angle)
        result.append((re, im))
    return result
signal = [sin(2*PI*i/64) for i in range(64)]
for _ in range(100):
    spectrum = dft64(signal)
elapsed = time.time() - t0
print(f"    100×DFT(64): {elapsed*1000:.2f}ms ({100/elapsed:.1f} DFTs/sec)")
results['dft64'] = 100/elapsed

# 10. MANDELBROT (single frame)
print("\n[10] MANDELBROT (80x40)")
t0 = time.time()
def mandelbrot(width=80, height=40, max_iter=100):
    count = 0
    for py in range(height):
        for px in range(width):
            x0 = (px - width/2) * 3.5/width
            y0 = (py - height/2) * 2.0/height
            x, y = 0.0, 0.0
            for i in range(max_iter):
                if x*x + y*y > 4: break
                x, y = x*x - y*y + x0, 2*x*y + y0
                count += 1
    return count
for _ in range(5):
    iters = mandelbrot()
elapsed = time.time() - t0
print(f"    5×Mandelbrot(80x40): {elapsed*1000:.2f}ms ({5/elapsed:.1f} frames/sec)")
results['mandelbrot'] = 5/elapsed

# 11. LORENZ ATTRACTOR
print("\n[11] LORENZ CHAOS (50000 steps)")
t0 = time.time()
def lorenz(steps=50000):
    x, y, z = 1.0, 1.0, 1.0
    sigma, rho, beta = 10.0, 28.0, 2.666667
    dt = 0.001
    for _ in range(steps):
        dx = sigma * (y - x)
        dy = x * (rho - z) - y
        dz = x * y - beta * z
        x, y, z = x + dx*dt, y + dy*dt, z + dz*dt
    return x, y, z
for _ in range(10):
    final = lorenz()
elapsed = time.time() - t0
print(f"    10×Lorenz(50000): {elapsed*1000:.2f}ms ({500000/elapsed/1e6:.2f}M steps/sec)")
results['lorenz'] = 500000/elapsed/1e6

# 12. RSA FACTORING
print("\n[12] RSA FACTORING (Pollard rho)")
t0 = time.time()
def pollard_rho(n):
    if n % 2 == 0: return 2
    x, y, d = 2, 2, 1
    f = lambda x: (x * x + 1) % n
    while d == 1:
        x = f(x)
        y = f(f(y))
        d = gcd(abs(x - y), n)
    return d
test_ns = [77, 143, 323, 1147, 3233, 10403, 16637, 25117, 62773, 294409]
cracked = 0
for n in test_ns:
    p = pollard_rho(n)
    if p != n and n % p == 0:
        cracked += 1
elapsed = time.time() - t0
print(f"    Factor {len(test_ns)} RSA moduli: {elapsed*1000:.2f}ms ({cracked}/{len(test_ns)} cracked)")
results['rsa_crack'] = cracked

# 13. HASH COMPUTATION
print("\n[13] SIMPLE HASH (djb2-style)")
t0 = time.time()
def djb2_hash(s):
    h = 5381
    for c in s:
        h = ((h << 5) + h) + ord(c)
        h = h & 0xFFFFFFFF
    return h
test_str = "The quick brown fox jumps over the lazy dog" * 10
for _ in range(50000):
    h = djb2_hash(test_str)
elapsed = time.time() - t0
print(f"    50000 hashes (440 chars): {elapsed*1000:.2f}ms ({50000/elapsed/1e3:.1f}K hash/sec)")
results['hash'] = 50000/elapsed/1e3

# 14. SORTING
print("\n[14] QUICKSORT (1000 elements)")
t0 = time.time()
def quicksort(arr):
    if len(arr) <= 1: return arr
    pivot = arr[len(arr)//2]
    left = [x for x in arr if x < pivot]
    mid = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + mid + quicksort(right)
import random
for _ in range(100):
    arr = [(i * 1103515245 + 12345) % 1000000 for i in range(1000)]
    sorted_arr = quicksort(arr)
elapsed = time.time() - t0
print(f"    100×quicksort(1000): {elapsed*1000:.2f}ms ({100/elapsed:.1f} sorts/sec)")
results['quicksort'] = 100/elapsed

# 15. NEURAL NET FORWARD PASS (simple)
print("\n[15] NEURAL NET (3-layer, 64 neurons)")
t0 = time.time()
def relu(x): return max(0, x)
def sigmoid(x): return 1.0 / (1.0 + exp(-x))
def nn_forward(inputs):
    # Layer 1: 10 -> 64
    h1 = [0.0] * 64
    for j in range(64):
        for i in range(10):
            h1[j] += inputs[i] * ((i*j*17+3) % 100 / 100 - 0.5)
        h1[j] = relu(h1[j])
    # Layer 2: 64 -> 32
    h2 = [0.0] * 32
    for j in range(32):
        for i in range(64):
            h2[j] += h1[i] * ((i*j*13+7) % 100 / 100 - 0.5)
        h2[j] = relu(h2[j])
    # Layer 3: 32 -> 10
    out = [0.0] * 10
    for j in range(10):
        for i in range(32):
            out[j] += h2[i] * ((i*j*11+5) % 100 / 100 - 0.5)
        out[j] = sigmoid(out[j])
    return out
for _ in range(100):
    inputs = [i/10 for i in range(10)]
    outputs = nn_forward(inputs)
elapsed = time.time() - t0
print(f"    100 forward passes: {elapsed*1000:.2f}ms ({100/elapsed:.1f} inferences/sec)")
results['nn_forward'] = 100/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  BENCHMARK SUMMARY - {hostname}")
print(f"{'='*70}")
print(f"""
  Fibonacci:     {results['fibonacci']:.2f} M ops/sec
  Trigonometry:  {results['trig']:.1f} K calls/sec
  Exp/Ln:        {results['exp_ln']:.1f} K calls/sec
  Square Root:   {results['sqrt']:.1f} K calls/sec
  GCD:           {results['gcd']:.2f} M calls/sec
  Mod Pow:       {results['mod_pow']:.1f} K calls/sec
  Prime Sieve:   {results['sieve']:.1f} sieves/sec
  Matrix 4x4:    {results['matmul_4x4']:.1f} K muls/sec
  DFT-64:        {results['dft64']:.1f} DFTs/sec
  Mandelbrot:    {results['mandelbrot']:.1f} frames/sec
  Lorenz Chaos:  {results['lorenz']:.2f} M steps/sec
  RSA Cracked:   {results['rsa_crack']}/10 keys
  Hash (djb2):   {results['hash']:.1f} K hash/sec
  QuickSort:     {results['quicksort']:.1f} sorts/sec
  Neural Net:    {results['nn_forward']:.1f} inferences/sec
  
  TOTAL SCORE: {sum(results.values()):.1f} points
""")

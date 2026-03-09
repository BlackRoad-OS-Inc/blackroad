#!/usr/bin/env python3
"""MONTE CARLO SIMULATIONS - Pure arithmetic randomness"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  MONTE CARLO SIMULATIONS - {hostname}")
print(f"{'='*70}\n")

def sqrt(x):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(20): g = (g + x/g) / 2.0
    return g

def ln(x):
    if x <= 0: return 0
    k = 0
    E = 2.718281828459045
    while x > E: x /= E; k += 1
    while x < 1/E: x *= E; k -= 1
    z = (x-1)/(x+1)
    r, t = 0.0, z
    for n in range(50):
        r += t / (2*n+1)
        t *= z*z
    return 2*r + k

def exp(x):
    r, t = 1.0, 1.0
    for n in range(1, 25):
        t = t * x / n
        r += t
    return r

# Linear congruential generator
class LCG:
    def __init__(self, seed=42):
        self.state = seed
    
    def next(self):
        self.state = (self.state * 1103515245 + 12345) & 0x7FFFFFFF
        return self.state / 0x7FFFFFFF
    
    def uniform(self, a=0, b=1):
        return a + (b - a) * self.next()
    
    def normal(self, mu=0, sigma=1):
        # Box-Muller transform
        u1 = self.next() + 1e-10
        u2 = self.next()
        z = sqrt(-2 * ln(u1)) * (1 if u2 < 0.5 else -1)  # simplified
        return mu + sigma * z

rng = LCG(42)
results = {}

# 1. PI ESTIMATION
print("[1] PI ESTIMATION (1M points)")
print("-" * 50)

t0 = time.time()
inside = 0
for _ in range(1000000):
    x = rng.uniform(-1, 1)
    y = rng.uniform(-1, 1)
    if x*x + y*y <= 1:
        inside += 1
pi_est = 4 * inside / 1000000
elapsed = time.time() - t0
error = abs(pi_est - 3.14159265) / 3.14159265 * 100
print(f"    1M points: {elapsed*1000:.2f}ms")
print(f"    π ≈ {pi_est:.6f} (error: {error:.3f}%)")
print(f"    Rate: {1000000/elapsed/1e6:.2f}M points/sec")
results['pi'] = 1000000/elapsed

# 2. INTEGRAL ESTIMATION (∫₀¹ x² dx = 1/3)
print("\n[2] INTEGRAL ESTIMATION (∫x² dx)")
print("-" * 50)

t0 = time.time()
total = 0
for _ in range(1000000):
    x = rng.uniform(0, 1)
    total += x * x
integral = total / 1000000
elapsed = time.time() - t0
error = abs(integral - 1/3) / (1/3) * 100
print(f"    1M samples: {elapsed*1000:.2f}ms")
print(f"    ∫x²dx ≈ {integral:.6f} (true: 0.333333, error: {error:.3f}%)")
results['integral'] = 1000000/elapsed

# 3. BUFFON'S NEEDLE (π estimation)
print("\n[3] BUFFON'S NEEDLE")
print("-" * 50)

PI = 3.14159265358979
t0 = time.time()
crosses = 0
L = 1.0  # needle length
D = 2.0  # distance between lines
for _ in range(500000):
    y = rng.uniform(0, D/2)  # center distance from nearest line
    theta = rng.uniform(0, PI/2)  # angle
    # Needle crosses if y < (L/2) * sin(theta)
    # Using Taylor approximation for sin
    sin_approx = theta - theta**3/6 + theta**5/120
    if y < (L/2) * sin_approx:
        crosses += 1
pi_buffon = (2 * L * 500000) / (D * crosses) if crosses > 0 else 0
elapsed = time.time() - t0
print(f"    500K needles: {elapsed*1000:.2f}ms")
print(f"    π ≈ {pi_buffon:.6f}")
results['buffon'] = 500000/elapsed

# 4. RANDOM WALK (2D, 1000 walkers)
print("\n[4] RANDOM WALK (1000 walkers × 1000 steps)")
print("-" * 50)

t0 = time.time()
final_distances = []
for walker in range(1000):
    x, y = 0.0, 0.0
    for step in range(1000):
        r = rng.next()
        if r < 0.25: x += 1
        elif r < 0.5: x -= 1
        elif r < 0.75: y += 1
        else: y -= 1
    final_distances.append(sqrt(x*x + y*y))
avg_dist = sum(final_distances) / len(final_distances)
elapsed = time.time() - t0
# Expected: sqrt(N) ≈ sqrt(1000) ≈ 31.6
print(f"    1000 walkers × 1000 steps: {elapsed*1000:.2f}ms")
print(f"    Avg final distance: {avg_dist:.2f} (expected ~31.6)")
print(f"    Rate: {1000000/elapsed:.0f} steps/sec")
results['walk'] = 1000000/elapsed

# 5. MONTE CARLO OPTION PRICING (Black-Scholes)
print("\n[5] OPTION PRICING (100K paths)")
print("-" * 50)

S0 = 100.0  # Initial stock price
K = 105.0   # Strike price
r = 0.05    # Risk-free rate
sigma = 0.2 # Volatility
T = 1.0     # Time to expiry
dt = T / 252  # Daily steps
n_steps = 252
n_paths = 100000

t0 = time.time()
payoffs = []
for _ in range(n_paths):
    S = S0
    for _ in range(n_steps):
        z = rng.normal(0, 1)
        S = S * exp((r - 0.5*sigma*sigma)*dt + sigma*sqrt(dt)*z)
    payoff = max(S - K, 0)  # Call option payoff
    payoffs.append(payoff)
option_price = exp(-r * T) * sum(payoffs) / n_paths
elapsed = time.time() - t0
print(f"    100K paths × 252 steps: {elapsed*1000:.2f}ms")
print(f"    Call option price: ${option_price:.2f}")
print(f"    Rate: {n_paths * n_steps / elapsed / 1e6:.2f}M steps/sec")
results['option'] = n_paths * n_steps / elapsed

# 6. ISING MODEL (2D, 20×20)
print("\n[6] ISING MODEL (20×20 lattice)")
print("-" * 50)

n = 20
J = 1.0  # Coupling
kT = 2.269  # Near critical temperature

# Initialize random spins
spins = [[1 if rng.next() < 0.5 else -1 for _ in range(n)] for _ in range(n)]

t0 = time.time()
for sweep in range(1000):
    for i in range(n):
        for j in range(n):
            # Calculate energy change
            s = spins[i][j]
            neighbors = (spins[(i+1)%n][j] + spins[(i-1)%n][j] + 
                        spins[i][(j+1)%n] + spins[i][(j-1)%n])
            dE = 2 * J * s * neighbors
            # Metropolis acceptance
            if dE < 0 or rng.next() < exp(-dE / kT):
                spins[i][j] = -s
elapsed = time.time() - t0
magnetization = abs(sum(sum(row) for row in spins)) / (n*n)
print(f"    1000 sweeps: {elapsed*1000:.2f}ms")
print(f"    Final magnetization: {magnetization:.3f}")
print(f"    Rate: {1000 * n * n / elapsed:.0f} spin-flips/sec")
results['ising'] = 1000 * n * n / elapsed

# 7. PERCOLATION
print("\n[7] PERCOLATION (100×100 grid)")
print("-" * 50)

def percolates(grid, n):
    """Check if grid percolates from top to bottom"""
    visited = [[False]*n for _ in range(n)]
    stack = [(0, j) for j in range(n) if grid[0][j]]
    while stack:
        i, j = stack.pop()
        if i == n-1: return True
        if visited[i][j]: continue
        visited[i][j] = True
        for di, dj in [(1,0),(-1,0),(0,1),(0,-1)]:
            ni, nj = i+di, j+dj
            if 0 <= ni < n and 0 <= nj < n and grid[ni][nj] and not visited[ni][nj]:
                stack.append((ni, nj))
    return False

n = 100
t0 = time.time()
thresholds = []
for trial in range(100):
    p = 0.5 + (trial - 50) * 0.01  # Vary probability around 0.5
    grid = [[rng.next() < p for _ in range(n)] for _ in range(n)]
    if percolates(grid, n):
        thresholds.append(p)
elapsed = time.time() - t0
avg_threshold = sum(thresholds) / len(thresholds) if thresholds else 0
print(f"    100 trials: {elapsed*1000:.2f}ms")
print(f"    Percolation threshold ≈ {avg_threshold:.3f} (theory: 0.593)")
results['percolation'] = 100/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  MONTE CARLO SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  Pi Estimation:     {results['pi']/1e6:.2f}M points/sec
  Integral:          {results['integral']/1e6:.2f}M samples/sec
  Buffon's Needle:   {results['buffon']/1e3:.1f}K needles/sec
  Random Walk:       {results['walk']/1e3:.1f}K steps/sec
  Option Pricing:    {results['option']/1e6:.2f}M steps/sec
  Ising Model:       {results['ising']/1e3:.1f}K flips/sec
  Percolation:       {results['percolation']:.1f} trials/sec
  
  TOTAL MC SCORE: {total/1e6:.2f}M points
""")

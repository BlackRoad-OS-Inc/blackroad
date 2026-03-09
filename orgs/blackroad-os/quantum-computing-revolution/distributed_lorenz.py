#!/usr/bin/env python3
"""Distributed Lorenz Chaos - Each node explores different initial conditions"""
import socket
import time

def lorenz_step(x, y, z, sigma=10.0, rho=28.0, beta=2.666667, dt=0.001):
    dx = sigma * (y - x)
    dy = x * (rho - z) - y
    dz = x * y - beta * z
    return (x + dx * dt, y + dy * dt, z + dz * dt)

def lyapunov_estimate(x0, y0, z0, steps=50000):
    """Estimate Lyapunov exponent - measure of chaos"""
    x1, y1, z1 = x0, y0, z0
    x2, y2, z2 = x0 + 1e-10, y0, z0
    
    lyap_sum = 0.0
    for _ in range(steps):
        x1, y1, z1 = lorenz_step(x1, y1, z1)
        x2, y2, z2 = lorenz_step(x2, y2, z2)
        
        dx, dy, dz = x2-x1, y2-y1, z2-z1
        dist = (dx*dx + dy*dy + dz*dz) ** 0.5
        
        if dist > 0 and dist < 1e10:
            import math
            lyap_sum += math.log(dist / 1e-10)
            x2 = x1 + dx * 1e-10 / dist
            y2 = y1 + dy * 1e-10 / dist
            z2 = z1 + dz * 1e-10 / dist
    
    return lyap_sum / steps / 0.001

hostname = socket.gethostname()
# Each host gets different initial conditions based on name hash
seed = sum(ord(c) for c in hostname) % 100
x0 = 1.0 + seed * 0.01
y0 = 1.0 + (seed % 7) * 0.1
z0 = 1.0 + (seed % 13) * 0.05

print(f"=== {hostname} LORENZ CHAOS ===")
print(f"Initial: ({x0:.4f}, {y0:.4f}, {z0:.4f})")

t0 = time.time()
lyap = lyapunov_estimate(x0, y0, z0, steps=20000)
elapsed = time.time() - t0

# Run trajectory
x, y, z = x0, y0, z0
for _ in range(10000):
    x, y, z = lorenz_step(x, y, z)

print(f"Final: ({x:.4f}, {y:.4f}, {z:.4f})")
print(f"Lyapunov exponent: {lyap:.4f}")
print(f"Chaos level: {'HIGH' if lyap > 0.5 else 'MODERATE' if lyap > 0 else 'STABLE'}")
print(f"Compute time: {elapsed:.3f}s")

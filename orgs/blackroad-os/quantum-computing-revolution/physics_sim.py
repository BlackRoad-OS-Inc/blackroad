#!/usr/bin/env python3
"""PHYSICS SIMULATIONS - Pure arithmetic"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  PHYSICS SIMULATIONS - {hostname}")
print(f"{'='*70}\n")

def sqrt(x):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(20): g = (g + x/g) / 2.0
    return g

def sin(x):
    PI = 3.14159265358979323846
    while x > PI: x -= 2*PI
    while x < -PI: x += 2*PI
    r, t = 0.0, x
    for n in range(15):
        r = r + t if n % 2 == 0 else r - t
        t = t * x * x / ((2*n+2) * (2*n+3))
    return r

def cos(x):
    PI = 3.14159265358979323846
    while x > PI: x -= 2*PI
    while x < -PI: x += 2*PI
    r, t = 1.0, 1.0
    for n in range(1, 15):
        t = t * (-x*x) / ((2*n-1) * (2*n))
        r += t
    return r

def exp(x):
    r, t = 1.0, 1.0
    for n in range(1, 25):
        t = t * x / n
        r += t
    return r

results = {}

# 1. N-BODY GRAVITATIONAL SIMULATION
print("[1] N-BODY GRAVITY (10 bodies, 1000 steps)")
print("-" * 50)

G = 6.674e-11  # Gravitational constant (scaled)
bodies = []
for i in range(10):
    bodies.append({
        'x': (i % 5) * 100 - 200,
        'y': (i // 5) * 100 - 50,
        'vx': sin(i) * 10,
        'vy': cos(i) * 10,
        'mass': 1e10 * (1 + i * 0.5)
    })

t0 = time.time()
dt = 0.1
for step in range(1000):
    # Calculate forces
    for i, b1 in enumerate(bodies):
        ax, ay = 0, 0
        for j, b2 in enumerate(bodies):
            if i != j:
                dx = b2['x'] - b1['x']
                dy = b2['y'] - b1['y']
                r = sqrt(dx*dx + dy*dy) + 1  # softening
                f = G * b1['mass'] * b2['mass'] / (r * r)
                ax += f * dx / r / b1['mass']
                ay += f * dy / r / b1['mass']
        b1['vx'] += ax * dt
        b1['vy'] += ay * dt
    # Update positions
    for b in bodies:
        b['x'] += b['vx'] * dt
        b['y'] += b['vy'] * dt
elapsed = time.time() - t0
print(f"    10 bodies × 1000 steps: {elapsed*1000:.2f}ms")
print(f"    Rate: {10000/elapsed:.0f} body-steps/sec")
results['nbody'] = 10000/elapsed

# 2. WAVE EQUATION (1D string)
print("\n[2] WAVE EQUATION (1D string, 200 points)")
print("-" * 50)

n = 200
u = [0.0] * n  # displacement
v = [0.0] * n  # velocity
# Initial pluck
for i in range(n):
    if i < n//4:
        u[i] = 4 * i / n
    else:
        u[i] = 4 * (1 - i/n) / 3

c = 1.0  # wave speed
dx = 1.0 / n
dt = 0.5 * dx / c

t0 = time.time()
for step in range(5000):
    # Update velocity
    for i in range(1, n-1):
        d2u = (u[i+1] - 2*u[i] + u[i-1]) / (dx*dx)
        v[i] += c*c * d2u * dt
    # Update displacement
    for i in range(1, n-1):
        u[i] += v[i] * dt
elapsed = time.time() - t0
energy = sum(0.5 * vi*vi for vi in v)
print(f"    200 points × 5000 steps: {elapsed*1000:.2f}ms")
print(f"    Rate: {1000000/elapsed:.0f} point-steps/sec")
print(f"    Final energy: {energy:.6f}")
results['wave'] = 1000000/elapsed

# 3. HEAT DIFFUSION (2D)
print("\n[3] HEAT DIFFUSION (2D, 50x50 grid)")
print("-" * 50)

nx, ny = 50, 50
T = [[20.0 for _ in range(ny)] for _ in range(nx)]
# Hot spot in center
for i in range(20, 30):
    for j in range(20, 30):
        T[i][j] = 100.0

alpha = 0.1  # diffusivity
dx = 1.0
dt = dx*dx / (4*alpha)

t0 = time.time()
for step in range(500):
    T_new = [[T[i][j] for j in range(ny)] for i in range(nx)]
    for i in range(1, nx-1):
        for j in range(1, ny-1):
            laplacian = (T[i+1][j] + T[i-1][j] + T[i][j+1] + T[i][j-1] - 4*T[i][j]) / (dx*dx)
            T_new[i][j] = T[i][j] + alpha * laplacian * dt
    T = T_new
elapsed = time.time() - t0
center_temp = T[25][25]
print(f"    50×50 grid × 500 steps: {elapsed*1000:.2f}ms")
print(f"    Rate: {50*50*500/elapsed:.0f} cell-steps/sec")
print(f"    Center temp: {center_temp:.2f}°C")
results['heat'] = 50*50*500/elapsed

# 4. PENDULUM (double pendulum chaos)
print("\n[4] DOUBLE PENDULUM (10000 steps)")
print("-" * 50)

g = 9.81
L1, L2 = 1.0, 1.0
m1, m2 = 1.0, 1.0
th1, th2 = 2.0, 2.5  # initial angles
w1, w2 = 0.0, 0.0    # angular velocities

t0 = time.time()
dt = 0.001
for _ in range(10000):
    # Equations of motion (simplified)
    num1 = -g*(2*m1+m2)*sin(th1) - m2*g*sin(th1-2*th2)
    num1 -= 2*sin(th1-th2)*m2*(w2*w2*L2 + w1*w1*L1*cos(th1-th2))
    den1 = L1*(2*m1 + m2 - m2*cos(2*th1-2*th2))
    a1 = num1/den1
    
    num2 = 2*sin(th1-th2)*(w1*w1*L1*(m1+m2) + g*(m1+m2)*cos(th1) + w2*w2*L2*m2*cos(th1-th2))
    den2 = L2*(2*m1 + m2 - m2*cos(2*th1-2*th2))
    a2 = num2/den2
    
    w1 += a1 * dt
    w2 += a2 * dt
    th1 += w1 * dt
    th2 += w2 * dt
elapsed = time.time() - t0
print(f"    10000 steps: {elapsed*1000:.2f}ms")
print(f"    Rate: {10000/elapsed:.0f} steps/sec")
print(f"    Final angles: θ1={th1:.3f}, θ2={th2:.3f}")
results['pendulum'] = 10000/elapsed

# 5. PROJECTILE WITH AIR RESISTANCE
print("\n[5] PROJECTILE (air resistance, 10000 trajectories)")
print("-" * 50)

g = 9.81
rho = 1.225  # air density
Cd = 0.47    # drag coefficient
A = 0.01     # cross-section
m = 1.0      # mass

t0 = time.time()
max_range = 0
for trial in range(10000):
    angle = 0.1 + trial * 0.0001
    v0 = 50 + (trial % 50)
    x, y = 0, 0
    vx = v0 * cos(angle)
    vy = v0 * sin(angle)
    dt = 0.01
    
    while y >= 0:
        v = sqrt(vx*vx + vy*vy)
        Fd = 0.5 * rho * Cd * A * v * v
        ax = -Fd * vx / v / m
        ay = -g - Fd * vy / v / m
        vx += ax * dt
        vy += ay * dt
        x += vx * dt
        y += vy * dt
        if y < 0: break
    
    if x > max_range:
        max_range = x
elapsed = time.time() - t0
print(f"    10000 trajectories: {elapsed*1000:.2f}ms")
print(f"    Rate: {10000/elapsed:.0f} trajectories/sec")
print(f"    Max range: {max_range:.2f}m")
results['projectile'] = 10000/elapsed

# 6. SPRING-MASS SYSTEM (100 coupled oscillators)
print("\n[6] COUPLED OSCILLATORS (100 masses)")
print("-" * 50)

n = 100
x = [0.0] * n  # displacements
v = [0.0] * n  # velocities
k = 1.0  # spring constant
m = 1.0  # mass
# Initial displacement
x[50] = 1.0

t0 = time.time()
dt = 0.01
for step in range(10000):
    # Calculate accelerations
    a = [0.0] * n
    for i in range(n):
        if i > 0:
            a[i] += -k * (x[i] - x[i-1]) / m
        if i < n-1:
            a[i] += -k * (x[i] - x[i+1]) / m
    # Update
    for i in range(n):
        v[i] += a[i] * dt
        x[i] += v[i] * dt
elapsed = time.time() - t0
total_energy = sum(0.5*m*vi*vi + 0.5*k*xi*xi for vi, xi in zip(v, x))
print(f"    100 masses × 10000 steps: {elapsed*1000:.2f}ms")
print(f"    Rate: {1000000/elapsed:.0f} mass-steps/sec")
print(f"    Total energy: {total_energy:.6f}")
results['oscillators'] = 1000000/elapsed

# 7. QUANTUM HARMONIC OSCILLATOR (energy levels)
print("\n[7] QUANTUM HARMONIC OSCILLATOR")
print("-" * 50)

hbar = 1.0545718e-34
omega = 1e15  # angular frequency
m_e = 9.109e-31

t0 = time.time()
energies = []
for n in range(1000):
    E_n = hbar * omega * (n + 0.5)
    energies.append(E_n)
# Wave function probability
psi_squared = []
for x in range(-100, 101):
    x_scaled = x * 1e-10
    psi2 = exp(-m_e * omega * x_scaled * x_scaled / hbar)
    psi_squared.append(psi2)
elapsed = time.time() - t0
print(f"    1000 energy levels + 201 ψ² values: {elapsed*1000:.3f}ms")
print(f"    E_0 = {energies[0]:.3e} J")
print(f"    E_10 = {energies[10]:.3e} J")
results['qho'] = 1201/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  PHYSICS SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  N-Body Gravity:      {results['nbody']:.0f} body-steps/sec
  Wave Equation:       {results['wave']:.0f} point-steps/sec
  Heat Diffusion:      {results['heat']:.0f} cell-steps/sec
  Double Pendulum:     {results['pendulum']:.0f} steps/sec
  Projectile:          {results['projectile']:.0f} trajectories/sec
  Coupled Oscillators: {results['oscillators']:.0f} mass-steps/sec
  Quantum HO:          {results['qho']:.0f} calcs/sec
  
  TOTAL PHYSICS SCORE: {total:.0f} points
""")

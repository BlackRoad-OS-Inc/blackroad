#!/usr/bin/env python3
"""QUANTUM + CHAOS MASHUP - Combining everything"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  QUANTUM CHAOS EXPERIMENTS - {hostname}")
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
        if abs(t) < 1e-15: break
    return r

results = {}

# 1. QUANTUM BILLIARDS (particle in box with chaos)
print("[1] QUANTUM BILLIARDS (Bunimovich stadium)")
print("-" * 50)

PI = 3.14159265358979323846
t0 = time.time()

# Stadium billiard: semicircles connected by rectangle
# Simulate 1000 trajectories
bounces_total = 0
lyapunov_sum = 0

for traj in range(1000):
    x, y = 0.5, 0.5
    vx = cos(traj * 0.1)
    vy = sin(traj * 0.1)
    v_mag = sqrt(vx*vx + vy*vy)
    vx, vy = vx/v_mag, vy/v_mag
    
    for step in range(100):
        # Move
        x += vx * 0.01
        y += vy * 0.01
        
        # Stadium boundaries: |y| < 0.5, |x| < 1 + sqrt(0.25 - y²)
        bounced = False
        # Rectangle boundary
        if abs(y) > 0.5:
            vy = -vy
            y = 0.5 if y > 0 else -0.5
            bounced = True
        # Semicircle boundaries
        if x > 1:
            dx = x - 1
            if dx*dx + y*y > 0.25:
                # Reflect off circle
                nx = dx / sqrt(dx*dx + y*y)
                ny = y / sqrt(dx*dx + y*y)
                dot = vx*nx + vy*ny
                vx = vx - 2*dot*nx
                vy = vy - 2*dot*ny
                bounced = True
        if x < -1:
            dx = x + 1
            if dx*dx + y*y > 0.25:
                nx = dx / sqrt(dx*dx + y*y)
                ny = y / sqrt(dx*dx + y*y)
                dot = vx*nx + vy*ny
                vx = vx - 2*dot*nx
                vy = vy - 2*dot*ny
                bounced = True
        
        if bounced:
            bounces_total += 1

elapsed = time.time() - t0
print(f"    1000 trajectories × 100 steps: {elapsed*1000:.2f}ms")
print(f"    Total bounces: {bounces_total}")
results['billiards'] = 100000/elapsed

# 2. QUANTUM KICKED ROTOR
print("\n[2] QUANTUM KICKED ROTOR (chaos)")
print("-" * 50)

t0 = time.time()
# Simulate classical kicked rotor
K = 5.0  # Kick strength (chaotic for K > 1)
theta_list = []
p_list = []

for traj in range(500):
    theta = traj * 0.01
    p = 0.0
    
    for kick in range(200):
        # Kick
        p = p + K * sin(theta)
        # Rotate
        theta = (theta + p) % (2 * PI)
    
    theta_list.append(theta)
    p_list.append(p)

# Estimate diffusion
p_squared_avg = sum(p*p for p in p_list) / len(p_list)
elapsed = time.time() - t0
print(f"    500 rotors × 200 kicks: {elapsed*1000:.2f}ms")
print(f"    <p²> = {p_squared_avg:.2f} (diffusion indicator)")
results['kicked_rotor'] = 100000/elapsed

# 3. ARNOLD CAT MAP (chaotic dynamics)
print("\n[3] ARNOLD CAT MAP (ergodic chaos)")
print("-" * 50)

t0 = time.time()
# Cat map: (x,y) -> (2x+y, x+y) mod 1
n_points = 10000
points = [(i/n_points, (i*7)%n_points/n_points) for i in range(n_points)]

for iteration in range(50):
    new_points = []
    for x, y in points:
        new_x = (2*x + y) % 1
        new_y = (x + y) % 1
        new_points.append((new_x, new_y))
    points = new_points

elapsed = time.time() - t0
print(f"    10000 points × 50 iterations: {elapsed*1000:.2f}ms")
# Check mixing
quadrants = [0, 0, 0, 0]
for x, y in points:
    q = (1 if x > 0.5 else 0) + (2 if y > 0.5 else 0)
    quadrants[q] += 1
print(f"    Quadrant distribution: {quadrants} (should be ~2500 each)")
results['cat_map'] = 500000/elapsed

# 4. HENON MAP (strange attractor)
print("\n[4] HÉNON MAP (strange attractor)")
print("-" * 50)

t0 = time.time()
a, b = 1.4, 0.3
x, y = 0.0, 0.0
attractor = []

for i in range(50000):
    x_new = 1 - a * x * x + y
    y_new = b * x
    x, y = x_new, y_new
    if i > 1000:  # Skip transient
        attractor.append((x, y))

elapsed = time.time() - t0
# Estimate fractal dimension via box counting
min_x = min(p[0] for p in attractor)
max_x = max(p[0] for p in attractor)
min_y = min(p[1] for p in attractor)
max_y = max(p[1] for p in attractor)
print(f"    50000 iterations: {elapsed*1000:.2f}ms")
print(f"    Attractor bounds: x=[{min_x:.3f}, {max_x:.3f}], y=[{min_y:.3f}, {max_y:.3f}]")
results['henon'] = 50000/elapsed

# 5. LOGISTIC MAP (period doubling)
print("\n[5] LOGISTIC MAP (bifurcation)")
print("-" * 50)

t0 = time.time()
bifurcation_data = []

for r_int in range(280, 400):  # r from 2.8 to 4.0
    r = r_int / 100
    x = 0.5
    # Iterate to reach attractor
    for _ in range(500):
        x = r * x * (1 - x)
    # Record final values
    for _ in range(50):
        x = r * x * (1 - x)
        bifurcation_data.append((r, x))

elapsed = time.time() - t0
print(f"    120 r-values × 550 iterations: {elapsed*1000:.2f}ms")
# Count unique attractors
unique_at_3_5 = len(set(round(d[1], 4) for d in bifurcation_data if 3.4 < d[0] < 3.6))
unique_at_3_8 = len(set(round(d[1], 4) for d in bifurcation_data if 3.7 < d[0] < 3.9))
print(f"    Attractor complexity at r≈3.5: {unique_at_3_5} distinct values")
print(f"    Attractor complexity at r≈3.8: {unique_at_3_8} distinct values (chaos)")
results['logistic'] = 66000/elapsed

# 6. JULIA SET COMPUTATION
print("\n[6] JULIA SET (fractal boundary)")
print("-" * 50)

t0 = time.time()
# Julia set for c = -0.7 + 0.27i
c_re, c_im = -0.7, 0.27
width, height = 100, 100
max_iter = 100

julia_data = []
for py in range(height):
    for px in range(width):
        z_re = (px - width/2) * 3 / width
        z_im = (py - height/2) * 3 / height
        
        for i in range(max_iter):
            if z_re*z_re + z_im*z_im > 4:
                break
            z_re, z_im = z_re*z_re - z_im*z_im + c_re, 2*z_re*z_im + c_im
        julia_data.append(i)

elapsed = time.time() - t0
in_set = sum(1 for d in julia_data if d == max_iter)
print(f"    100×100 Julia: {elapsed*1000:.2f}ms")
print(f"    Points in set: {in_set} ({in_set/100:.1f}%)")
results['julia'] = 10000/elapsed

# 7. BAKER'S MAP (mixing)
print("\n[7] BAKER'S MAP (perfect mixing)")
print("-" * 50)

t0 = time.time()
# Baker's map: stretch and fold
n_particles = 10000
particles = [(i/n_particles, (i*3)%n_particles/n_particles) for i in range(n_particles)]

for iteration in range(100):
    new_particles = []
    for x, y in particles:
        if x < 0.5:
            new_x = 2 * x
            new_y = y / 2
        else:
            new_x = 2 * x - 1
            new_y = (y + 1) / 2
        new_particles.append((new_x, new_y))
    particles = new_particles

elapsed = time.time() - t0
print(f"    10000 particles × 100 iterations: {elapsed*1000:.2f}ms")
results['baker'] = 1000000/elapsed

# 8. CHIRIKOV STANDARD MAP
print("\n[8] CHIRIKOV STANDARD MAP")
print("-" * 50)

t0 = time.time()
K = 0.97  # Near the critical value
trajectories = []

for init in range(200):
    p = init * 0.01
    theta = 0.0
    traj = []
    for n in range(500):
        p_new = (p + K * sin(theta)) % (2 * PI)
        theta_new = (theta + p_new) % (2 * PI)
        p, theta = p_new, theta_new
        traj.append((theta, p))
    trajectories.append(traj)

elapsed = time.time() - t0
print(f"    200 trajectories × 500 steps: {elapsed*1000:.2f}ms")
print(f"    Phase space coverage: {len(set((round(t[0],1), round(t[1],1)) for traj in trajectories for t in traj))} distinct cells")
results['chirikov'] = 100000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  QUANTUM CHAOS SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  Quantum Billiards:   {results['billiards']:.0f} steps/sec
  Kicked Rotor:        {results['kicked_rotor']:.0f} kicks/sec
  Arnold Cat Map:      {results['cat_map']:.0f} iterations/sec
  Hénon Attractor:     {results['henon']:.0f} iterations/sec
  Logistic Map:        {results['logistic']:.0f} iterations/sec
  Julia Set:           {results['julia']:.0f} pixels/sec
  Baker's Map:         {results['baker']:.0f} iterations/sec
  Chirikov Map:        {results['chirikov']:.0f} steps/sec
  
  TOTAL CHAOS SCORE: {total:.0f} points
""")

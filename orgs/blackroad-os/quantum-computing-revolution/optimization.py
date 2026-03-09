#!/usr/bin/env python3
"""OPTIMIZATION ALGORITHMS - Pure arithmetic optimization"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  ⚡ OPTIMIZATION ALGORITHMS - {hostname}")
print(f"{'='*70}\n")

def sqrt(x):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(20): g = (g + x/g) / 2.0
    return g

def sin(x):
    PI = 3.14159265358979
    while x > PI: x -= 2*PI
    while x < -PI: x += 2*PI
    r, t = 0.0, x
    for n in range(15):
        r = r + t if n % 2 == 0 else r - t
        t = t * x * x / ((2*n+2) * (2*n+3))
    return r

def cos(x):
    PI = 3.14159265358979
    while x > PI: x -= 2*PI
    while x < -PI: x += 2*PI
    r, t = 1.0, 1.0
    for n in range(1, 15):
        t = t * (-x*x) / ((2*n-1) * (2*n))
        r += t
    return r

def exp(x):
    if x > 700: return 1e308
    if x < -700: return 0
    r, t = 1.0, 1.0
    for n in range(1, 30):
        t = t * x / n
        r += t
    return r

class LCG:
    def __init__(self, seed): self.state = seed
    def next(self):
        self.state = (self.state * 1103515245 + 12345) & 0x7FFFFFFF
        return self.state / 0x7FFFFFFF

results = {}

# Test functions
def sphere(x):
    return sum(xi**2 for xi in x)

def rastrigin(x):
    return 10*len(x) + sum(xi**2 - 10*cos(2*3.14159*xi) for xi in x)

def rosenbrock(x):
    return sum(100*(x[i+1]-x[i]**2)**2 + (1-x[i])**2 for i in range(len(x)-1))

def ackley(x):
    n = len(x)
    sum1 = sum(xi**2 for xi in x)
    sum2 = sum(cos(2*3.14159*xi) for xi in x)
    return -20*exp(-0.2*sqrt(sum1/n)) - exp(sum2/n) + 20 + 2.71828

# 1. GRADIENT DESCENT
print("[1] 📉 GRADIENT DESCENT")
print("-" * 50)

def gradient_descent(f, x0, lr=0.01, max_iter=100, eps=1e-6):
    x = x0[:]
    for _ in range(max_iter):
        grad = []
        fx = f(x)
        for i in range(len(x)):
            x[i] += eps
            grad.append((f(x) - fx) / eps)
            x[i] -= eps
        for i in range(len(x)):
            x[i] -= lr * grad[i]
    return x, f(x)

t0 = time.time()
for _ in range(1000):
    x, val = gradient_descent(sphere, [5.0, 5.0, 5.0])
elapsed = time.time() - t0
print(f"    1000 GD optimizations: {elapsed*1000:.2f}ms ({1000/elapsed:.0f}/sec)")
print(f"    Sphere minimum: {val:.6f}")
results['gd'] = 1000/elapsed

# 2. SIMULATED ANNEALING
print("\n[2] 🔥 SIMULATED ANNEALING")
print("-" * 50)

def simulated_annealing(f, x0, T0=100, alpha=0.95, max_iter=200):
    rng = LCG(42)
    x = x0[:]
    fx = f(x)
    best_x, best_f = x[:], fx
    T = T0
    
    for _ in range(max_iter):
        # Generate neighbor
        new_x = [xi + (rng.next() - 0.5) * T * 0.1 for xi in x]
        new_f = f(new_x)
        
        # Accept or reject
        if new_f < fx or rng.next() < exp((fx - new_f) / T):
            x, fx = new_x, new_f
            if fx < best_f:
                best_x, best_f = x[:], fx
        
        T *= alpha
    
    return best_x, best_f

t0 = time.time()
for _ in range(500):
    x, val = simulated_annealing(rastrigin, [5.0, 5.0])
elapsed = time.time() - t0
print(f"    500 SA optimizations: {elapsed*1000:.2f}ms ({500/elapsed:.0f}/sec)")
print(f"    Rastrigin minimum: {val:.4f}")
results['sa'] = 500/elapsed

# 3. GENETIC ALGORITHM
print("\n[3] 🧬 GENETIC ALGORITHM")
print("-" * 50)

def genetic_algorithm(f, dim, pop_size=50, generations=50):
    rng = LCG(123)
    
    # Initialize population
    pop = [[rng.next()*10 - 5 for _ in range(dim)] for _ in range(pop_size)]
    
    for gen in range(generations):
        # Evaluate fitness
        fitness = [(f(ind), ind) for ind in pop]
        fitness.sort()
        
        # Selection (elitism)
        elite = [ind for _, ind in fitness[:pop_size//4]]
        
        # Crossover and mutation
        new_pop = elite[:]
        while len(new_pop) < pop_size:
            p1 = elite[int(rng.next() * len(elite))]
            p2 = elite[int(rng.next() * len(elite))]
            # Crossover
            child = [(p1[i] + p2[i]) / 2 + (rng.next() - 0.5) * 0.5 for i in range(dim)]
            new_pop.append(child)
        
        pop = new_pop
    
    best = min(pop, key=f)
    return best, f(best)

t0 = time.time()
for _ in range(100):
    x, val = genetic_algorithm(sphere, 3)
elapsed = time.time() - t0
print(f"    100 GA optimizations: {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
print(f"    Sphere minimum: {val:.6f}")
results['ga'] = 100/elapsed

# 4. NELDER-MEAD (Simplex)
print("\n[4] 🔺 NELDER-MEAD SIMPLEX")
print("-" * 50)

def nelder_mead(f, x0, max_iter=100, alpha=1, gamma=2, rho=0.5, sigma=0.5):
    n = len(x0)
    # Initialize simplex
    simplex = [x0[:]]
    for i in range(n):
        point = x0[:]
        point[i] += 1.0
        simplex.append(point)
    
    for _ in range(max_iter):
        # Sort by function value
        simplex.sort(key=f)
        
        # Centroid
        centroid = [sum(simplex[j][i] for j in range(n)) / n for i in range(n)]
        
        # Reflection
        worst = simplex[-1]
        reflected = [centroid[i] + alpha * (centroid[i] - worst[i]) for i in range(n)]
        
        if f(simplex[0]) <= f(reflected) < f(simplex[-2]):
            simplex[-1] = reflected
        elif f(reflected) < f(simplex[0]):
            # Expansion
            expanded = [centroid[i] + gamma * (reflected[i] - centroid[i]) for i in range(n)]
            simplex[-1] = expanded if f(expanded) < f(reflected) else reflected
        else:
            # Contraction
            contracted = [centroid[i] + rho * (worst[i] - centroid[i]) for i in range(n)]
            if f(contracted) < f(worst):
                simplex[-1] = contracted
            else:
                # Shrink
                best = simplex[0]
                for j in range(1, n+1):
                    simplex[j] = [best[i] + sigma * (simplex[j][i] - best[i]) for i in range(n)]
    
    return simplex[0], f(simplex[0])

t0 = time.time()
for _ in range(500):
    x, val = nelder_mead(rosenbrock, [0.0, 0.0])
elapsed = time.time() - t0
print(f"    500 Nelder-Mead: {elapsed*1000:.2f}ms ({500/elapsed:.0f}/sec)")
print(f"    Rosenbrock minimum: {val:.6f}")
results['nm'] = 500/elapsed

# 5. PARTICLE SWARM OPTIMIZATION
print("\n[5] 🐝 PARTICLE SWARM")
print("-" * 50)

def pso(f, dim, n_particles=30, max_iter=100):
    rng = LCG(456)
    
    pos = [[rng.next()*10 - 5 for _ in range(dim)] for _ in range(n_particles)]
    vel = [[rng.next()*2 - 1 for _ in range(dim)] for _ in range(n_particles)]
    pbest = [p[:] for p in pos]
    pbest_val = [f(p) for p in pos]
    
    gbest = pos[pbest_val.index(min(pbest_val))][:]
    gbest_val = min(pbest_val)
    
    w, c1, c2 = 0.7, 1.5, 1.5
    
    for _ in range(max_iter):
        for i in range(n_particles):
            for d in range(dim):
                r1, r2 = rng.next(), rng.next()
                vel[i][d] = w*vel[i][d] + c1*r1*(pbest[i][d]-pos[i][d]) + c2*r2*(gbest[d]-pos[i][d])
                pos[i][d] += vel[i][d]
            
            val = f(pos[i])
            if val < pbest_val[i]:
                pbest_val[i] = val
                pbest[i] = pos[i][:]
                if val < gbest_val:
                    gbest_val = val
                    gbest = pos[i][:]
    
    return gbest, gbest_val

t0 = time.time()
for _ in range(100):
    x, val = pso(ackley, 3)
elapsed = time.time() - t0
print(f"    100 PSO optimizations: {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
print(f"    Ackley minimum: {val:.4f}")
results['pso'] = 100/elapsed

# 6. CONJUGATE GRADIENT
print("\n[6] 🔄 CONJUGATE GRADIENT")
print("-" * 50)

def conjugate_gradient(A, b, x0, max_iter=100, tol=1e-6):
    """Solve Ax = b using CG"""
    n = len(b)
    x = x0[:]
    
    # r = b - Ax
    r = [b[i] - sum(A[i][j]*x[j] for j in range(n)) for i in range(n)]
    p = r[:]
    rsold = sum(ri*ri for ri in r)
    
    for _ in range(max_iter):
        if rsold < tol:
            break
        
        # Ap
        Ap = [sum(A[i][j]*p[j] for j in range(n)) for i in range(n)]
        alpha = rsold / sum(p[i]*Ap[i] for i in range(n))
        
        for i in range(n):
            x[i] += alpha * p[i]
            r[i] -= alpha * Ap[i]
        
        rsnew = sum(ri*ri for ri in r)
        
        for i in range(n):
            p[i] = r[i] + (rsnew / rsold) * p[i]
        
        rsold = rsnew
    
    return x

# Simple positive definite matrix
A = [[4, 1, 0], [1, 3, 1], [0, 1, 2]]
b = [1, 2, 3]

t0 = time.time()
for _ in range(10000):
    x = conjugate_gradient(A, b, [0, 0, 0])
elapsed = time.time() - t0
print(f"    10K CG solves: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
results['cg'] = 10000/elapsed

# 7. NEWTON'S METHOD (Optimization)
print("\n[7] 📐 NEWTON'S METHOD")
print("-" * 50)

def newton_optimize(f, x0, max_iter=50, eps=1e-6):
    x = x0[:]
    
    for _ in range(max_iter):
        # Gradient
        grad = []
        fx = f(x)
        for i in range(len(x)):
            x[i] += eps
            grad.append((f(x) - fx) / eps)
            x[i] -= eps
        
        # Approximate Hessian diagonal
        hess_diag = []
        for i in range(len(x)):
            x[i] += eps
            g_plus = (f(x) - fx) / eps
            x[i] -= 2*eps
            g_minus = (f(x) - fx) / eps
            x[i] += eps
            hess_diag.append((g_plus - g_minus) / (2*eps))
        
        # Update
        for i in range(len(x)):
            if abs(hess_diag[i]) > 1e-10:
                x[i] -= grad[i] / hess_diag[i]
    
    return x, f(x)

t0 = time.time()
for _ in range(1000):
    x, val = newton_optimize(sphere, [5.0, 5.0, 5.0])
elapsed = time.time() - t0
print(f"    1000 Newton optimizations: {elapsed*1000:.2f}ms ({1000/elapsed:.0f}/sec)")
results['newton'] = 1000/elapsed

# 8. GOLDEN SECTION SEARCH
print("\n[8] 🌟 GOLDEN SECTION SEARCH")
print("-" * 50)

def golden_section(f, a, b, tol=1e-6):
    phi = (1 + sqrt(5)) / 2
    c = b - (b - a) / phi
    d = a + (b - a) / phi
    
    while abs(b - a) > tol:
        if f(c) < f(d):
            b = d
        else:
            a = c
        c = b - (b - a) / phi
        d = a + (b - a) / phi
    
    return (a + b) / 2

def test_f(x):
    return (x - 2)**2 + 1

t0 = time.time()
for _ in range(100000):
    x = golden_section(test_f, 0, 5)
elapsed = time.time() - t0
print(f"    100K golden section: {elapsed*1000:.2f}ms ({100000/elapsed:.0f}/sec)")
print(f"    Minimum at x = {x:.4f}")
results['golden'] = 100000/elapsed

# 9. DIFFERENTIAL EVOLUTION
print("\n[9] 🔀 DIFFERENTIAL EVOLUTION")
print("-" * 50)

def differential_evolution(f, dim, pop_size=30, max_iter=50, F=0.8, CR=0.9):
    rng = LCG(789)
    
    pop = [[rng.next()*10 - 5 for _ in range(dim)] for _ in range(pop_size)]
    
    for _ in range(max_iter):
        new_pop = []
        for i in range(pop_size):
            # Select 3 random individuals
            candidates = [j for j in range(pop_size) if j != i]
            a, b, c = [candidates[int(rng.next() * len(candidates))] for _ in range(3)]
            
            # Mutation
            mutant = [pop[a][d] + F * (pop[b][d] - pop[c][d]) for d in range(dim)]
            
            # Crossover
            j_rand = int(rng.next() * dim)
            trial = [mutant[d] if rng.next() < CR or d == j_rand else pop[i][d] for d in range(dim)]
            
            # Selection
            new_pop.append(trial if f(trial) < f(pop[i]) else pop[i])
        
        pop = new_pop
    
    best = min(pop, key=f)
    return best, f(best)

t0 = time.time()
for _ in range(50):
    x, val = differential_evolution(rastrigin, 3)
elapsed = time.time() - t0
print(f"    50 DE optimizations: {elapsed*1000:.2f}ms ({50/elapsed:.0f}/sec)")
print(f"    Rastrigin minimum: {val:.4f}")
results['de'] = 50/elapsed

# 10. HILL CLIMBING
print("\n[10] ⛰️ HILL CLIMBING")
print("-" * 50)

def hill_climbing(f, x0, step=0.1, max_iter=1000):
    x = x0[:]
    fx = f(x)
    
    for _ in range(max_iter):
        improved = False
        for i in range(len(x)):
            for delta in [step, -step]:
                x[i] += delta
                new_f = f(x)
                if new_f < fx:
                    fx = new_f
                    improved = True
                else:
                    x[i] -= delta
        
        if not improved:
            step *= 0.5
            if step < 1e-8:
                break
    
    return x, fx

t0 = time.time()
for _ in range(1000):
    x, val = hill_climbing(sphere, [5.0, 5.0, 5.0])
elapsed = time.time() - t0
print(f"    1000 hill climbing: {elapsed*1000:.2f}ms ({1000/elapsed:.0f}/sec)")
results['hill'] = 1000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 OPTIMIZATION SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  Gradient Descent:       {results['gd']:.0f}/sec
  Simulated Annealing:    {results['sa']:.0f}/sec
  Genetic Algorithm:      {results['ga']:.0f}/sec
  Nelder-Mead:            {results['nm']:.0f}/sec
  Particle Swarm:         {results['pso']:.0f}/sec
  Conjugate Gradient:     {results['cg']:.0f}/sec
  Newton's Method:        {results['newton']:.0f}/sec
  Golden Section:         {results['golden']:.0f}/sec
  Differential Evo:       {results['de']:.0f}/sec
  Hill Climbing:          {results['hill']:.0f}/sec
  
  ⚡ TOTAL OPTIMIZATION SCORE: {total:.0f} points
""")

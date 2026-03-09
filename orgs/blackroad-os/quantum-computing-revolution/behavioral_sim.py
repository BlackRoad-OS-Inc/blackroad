#!/usr/bin/env python3
"""BEHAVIORAL SIMULATION - Pure arithmetic agent behaviors"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  🧠 BEHAVIORAL SIMULATION - {hostname}")
print(f"{'='*70}\n")

class LCG:
    def __init__(self, seed): self.state = seed
    def next(self):
        self.state = (self.state * 1103515245 + 12345) & 0x7FFFFFFF
        return self.state / 0x7FFFFFFF

results = {}

# 1. FLOCKING (Boids)
print("[1] 🐦 FLOCKING BEHAVIOR (Boids)")
print("-" * 50)

def sqrt(x):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(20): g = (g + x/g) / 2.0
    return g

def simulate_boids(n_boids, steps):
    rng = LCG(42)
    # Initialize positions and velocities
    pos = [[rng.next() * 100, rng.next() * 100] for _ in range(n_boids)]
    vel = [[rng.next() * 2 - 1, rng.next() * 2 - 1] for _ in range(n_boids)]
    
    for step in range(steps):
        new_vel = [[0, 0] for _ in range(n_boids)]
        
        for i in range(n_boids):
            # Separation, alignment, cohesion
            sep = [0, 0]; align = [0, 0]; coh = [0, 0]
            neighbors = 0
            
            for j in range(n_boids):
                if i != j:
                    dx = pos[j][0] - pos[i][0]
                    dy = pos[j][1] - pos[i][1]
                    dist = sqrt(dx*dx + dy*dy)
                    
                    if dist < 20:  # Neighborhood radius
                        neighbors += 1
                        # Separation
                        if dist > 0.1:
                            sep[0] -= dx / dist
                            sep[1] -= dy / dist
                        # Alignment
                        align[0] += vel[j][0]
                        align[1] += vel[j][1]
                        # Cohesion
                        coh[0] += pos[j][0]
                        coh[1] += pos[j][1]
            
            if neighbors > 0:
                align[0] /= neighbors; align[1] /= neighbors
                coh[0] = coh[0]/neighbors - pos[i][0]
                coh[1] = coh[1]/neighbors - pos[i][1]
                
                new_vel[i][0] = vel[i][0] + sep[0]*0.5 + align[0]*0.1 + coh[0]*0.1
                new_vel[i][1] = vel[i][1] + sep[1]*0.5 + align[1]*0.1 + coh[1]*0.1
            else:
                new_vel[i] = vel[i]
            
            # Limit speed
            speed = sqrt(new_vel[i][0]**2 + new_vel[i][1]**2)
            if speed > 5:
                new_vel[i][0] = new_vel[i][0] / speed * 5
                new_vel[i][1] = new_vel[i][1] / speed * 5
        
        # Update
        vel = new_vel
        for i in range(n_boids):
            pos[i][0] = (pos[i][0] + vel[i][0]) % 100
            pos[i][1] = (pos[i][1] + vel[i][1]) % 100
    
    return pos

t0 = time.time()
for _ in range(10):
    final_pos = simulate_boids(50, 100)
elapsed = time.time() - t0
print(f"    10 × 50 boids × 100 steps: {elapsed*1000:.2f}ms ({50000/elapsed:.0f} agent-steps/sec)")
results['boids'] = 50000/elapsed

# 2. ANT COLONY OPTIMIZATION
print("\n[2] 🐜 ANT COLONY OPTIMIZATION")
print("-" * 50)

def ant_colony_tsp(cities, n_ants=20, iterations=50):
    n = len(cities)
    rng = LCG(123)
    
    # Distance matrix
    dist = [[0]*n for _ in range(n)]
    for i in range(n):
        for j in range(n):
            dx = cities[i][0] - cities[j][0]
            dy = cities[i][1] - cities[j][1]
            dist[i][j] = sqrt(dx*dx + dy*dy)
    
    # Pheromone matrix
    pheromone = [[1.0]*n for _ in range(n)]
    best_path = None
    best_length = float('inf')
    
    for iteration in range(iterations):
        paths = []
        lengths = []
        
        for ant in range(n_ants):
            # Build tour
            visited = [False] * n
            path = [int(rng.next() * n)]
            visited[path[0]] = True
            
            while len(path) < n:
                current = path[-1]
                probs = []
                total = 0
                for j in range(n):
                    if not visited[j]:
                        p = pheromone[current][j] ** 2 / (dist[current][j] + 0.001)
                        probs.append((j, p))
                        total += p
                
                # Roulette selection
                r = rng.next() * total
                cumsum = 0
                next_city = probs[0][0]
                for j, p in probs:
                    cumsum += p
                    if cumsum >= r:
                        next_city = j
                        break
                
                path.append(next_city)
                visited[next_city] = True
            
            # Calculate length
            length = sum(dist[path[i]][path[(i+1)%n]] for i in range(n))
            paths.append(path)
            lengths.append(length)
            
            if length < best_length:
                best_length = length
                best_path = path
        
        # Evaporate and deposit
        for i in range(n):
            for j in range(n):
                pheromone[i][j] *= 0.5
        
        for path, length in zip(paths, lengths):
            deposit = 100 / length
            for i in range(n):
                pheromone[path[i]][path[(i+1)%n]] += deposit
    
    return best_path, best_length

# Generate cities
rng = LCG(999)
cities = [(rng.next()*100, rng.next()*100) for _ in range(15)]

t0 = time.time()
for _ in range(10):
    path, length = ant_colony_tsp(cities)
elapsed = time.time() - t0
print(f"    10 × ACO (15 cities, 20 ants, 50 iters): {elapsed*1000:.2f}ms")
print(f"    Best tour length: {length:.2f}")
results['aco'] = 10*20*50/elapsed

# 3. CELLULAR AUTOMATA
print("\n[3] 🔲 CELLULAR AUTOMATA (Game of Life)")
print("-" * 50)

def game_of_life(grid, steps):
    rows, cols = len(grid), len(grid[0])
    
    for _ in range(steps):
        new_grid = [[0]*cols for _ in range(rows)]
        for i in range(rows):
            for j in range(cols):
                neighbors = 0
                for di in [-1, 0, 1]:
                    for dj in [-1, 0, 1]:
                        if di == 0 and dj == 0: continue
                        ni, nj = (i+di)%rows, (j+dj)%cols
                        neighbors += grid[ni][nj]
                
                if grid[i][j]:
                    new_grid[i][j] = 1 if neighbors in [2, 3] else 0
                else:
                    new_grid[i][j] = 1 if neighbors == 3 else 0
        grid = new_grid
    return grid

# Initialize with glider
grid = [[0]*50 for _ in range(50)]
grid[1][2] = grid[2][3] = grid[3][1] = grid[3][2] = grid[3][3] = 1

t0 = time.time()
for _ in range(100):
    result = game_of_life([row[:] for row in grid], 100)
elapsed = time.time() - t0
alive = sum(sum(row) for row in result)
print(f"    100 × 50x50 grid × 100 steps: {elapsed*1000:.2f}ms")
print(f"    Final alive cells: {alive}")
results['gol'] = 100*50*50*100/elapsed

# 4. PREDATOR-PREY (Lotka-Volterra)
print("\n[4] 🦊🐰 PREDATOR-PREY SIMULATION")
print("-" * 50)

def lotka_volterra(prey0, pred0, steps, dt=0.01):
    # Parameters
    alpha = 1.1   # Prey birth rate
    beta = 0.4    # Predation rate
    gamma = 0.4   # Predator death rate
    delta = 0.1   # Predator reproduction
    
    prey, pred = prey0, pred0
    history = [(prey, pred)]
    
    for _ in range(steps):
        dprey = alpha * prey - beta * prey * pred
        dpred = delta * prey * pred - gamma * pred
        prey += dprey * dt
        pred += dpred * dt
        prey = max(0, prey)
        pred = max(0, pred)
        history.append((prey, pred))
    
    return history

t0 = time.time()
for _ in range(1000):
    history = lotka_volterra(10, 5, 1000)
elapsed = time.time() - t0
print(f"    1000 × 1000-step simulations: {elapsed*1000:.2f}ms ({1000000/elapsed:.0f} steps/sec)")
print(f"    Final: Prey={history[-1][0]:.2f}, Pred={history[-1][1]:.2f}")
results['predprey'] = 1000000/elapsed

# 5. SWARM INTELLIGENCE (PSO)
print("\n[5] 🐝 PARTICLE SWARM OPTIMIZATION")
print("-" * 50)

def pso_optimize(f, bounds, n_particles=30, iterations=100):
    rng = LCG(456)
    dim = len(bounds)
    
    # Initialize particles
    pos = [[bounds[d][0] + rng.next()*(bounds[d][1]-bounds[d][0]) for d in range(dim)] for _ in range(n_particles)]
    vel = [[rng.next()*2-1 for _ in range(dim)] for _ in range(n_particles)]
    pbest = [p[:] for p in pos]
    pbest_val = [f(p) for p in pos]
    
    gbest = pos[pbest_val.index(min(pbest_val))][:]
    gbest_val = min(pbest_val)
    
    w, c1, c2 = 0.7, 1.5, 1.5
    
    for iteration in range(iterations):
        for i in range(n_particles):
            # Update velocity
            for d in range(dim):
                r1, r2 = rng.next(), rng.next()
                vel[i][d] = w*vel[i][d] + c1*r1*(pbest[i][d]-pos[i][d]) + c2*r2*(gbest[d]-pos[i][d])
            
            # Update position
            for d in range(dim):
                pos[i][d] += vel[i][d]
                pos[i][d] = max(bounds[d][0], min(bounds[d][1], pos[i][d]))
            
            # Update personal best
            val = f(pos[i])
            if val < pbest_val[i]:
                pbest_val[i] = val
                pbest[i] = pos[i][:]
                if val < gbest_val:
                    gbest_val = val
                    gbest = pos[i][:]
    
    return gbest, gbest_val

# Rastrigin function
def rastrigin(x):
    return 10*len(x) + sum(xi**2 - 10*cos(2*3.14159*xi) for xi in x)

def cos(x):
    PI = 3.14159265358979
    while x > PI: x -= 2*PI
    while x < -PI: x += 2*PI
    r, t = 1.0, 1.0
    for n in range(1, 15):
        t = t * (-x*x) / ((2*n-1) * (2*n))
        r += t
    return r

t0 = time.time()
for _ in range(100):
    best, val = pso_optimize(rastrigin, [(-5, 5)]*3)
elapsed = time.time() - t0
print(f"    100 × PSO (30 particles, 100 iters, 3D): {elapsed*1000:.2f}ms")
print(f"    Best: {[f'{x:.4f}' for x in best]}, f(x)={val:.4f}")
results['pso'] = 100*30*100/elapsed

# 6. SOCIAL NETWORK SIMULATION
print("\n[6] 👥 SOCIAL NETWORK DYNAMICS")
print("-" * 50)

def simulate_network(n_agents, steps):
    rng = LCG(789)
    # Opinion in [-1, 1]
    opinions = [rng.next()*2-1 for _ in range(n_agents)]
    # Random connections
    connections = [[] for _ in range(n_agents)]
    for i in range(n_agents):
        for j in range(i+1, n_agents):
            if rng.next() < 0.1:
                connections[i].append(j)
                connections[j].append(i)
    
    for step in range(steps):
        new_opinions = opinions[:]
        for i in range(n_agents):
            if connections[i]:
                # Average with neighbors
                avg = sum(opinions[j] for j in connections[i]) / len(connections[i])
                new_opinions[i] = 0.9 * opinions[i] + 0.1 * avg
        opinions = new_opinions
    
    return opinions

t0 = time.time()
for _ in range(100):
    final = simulate_network(100, 100)
elapsed = time.time() - t0
consensus = sum(final) / len(final)
print(f"    100 × 100 agents × 100 steps: {elapsed*1000:.2f}ms ({1000000/elapsed:.0f} agent-steps/sec)")
print(f"    Final consensus: {consensus:.4f}")
results['social'] = 1000000/elapsed

# 7. TRAFFIC SIMULATION
print("\n[7] 🚗 TRAFFIC SIMULATION")
print("-" * 50)

def simulate_traffic(n_cars, road_length, steps):
    rng = LCG(321)
    # Car positions and speeds
    pos = sorted([int(rng.next() * road_length) for _ in range(n_cars)])
    speed = [5] * n_cars
    max_speed = 5
    
    for step in range(steps):
        new_pos = pos[:]
        new_speed = speed[:]
        
        for i in range(n_cars):
            # Distance to car ahead (circular road)
            next_car = (i + 1) % n_cars
            if next_car == 0:
                dist = (pos[next_car] + road_length - pos[i]) % road_length
            else:
                dist = pos[next_car] - pos[i]
            
            # Acceleration
            if speed[i] < max_speed:
                new_speed[i] = min(speed[i] + 1, max_speed)
            
            # Deceleration (safety)
            if dist <= new_speed[i]:
                new_speed[i] = max(0, dist - 1)
            
            # Random slowdown
            if rng.next() < 0.1 and new_speed[i] > 0:
                new_speed[i] -= 1
            
            new_pos[i] = (pos[i] + new_speed[i]) % road_length
        
        pos = sorted(new_pos)
        speed = new_speed
    
    return sum(speed) / n_cars

t0 = time.time()
for _ in range(100):
    avg_speed = simulate_traffic(50, 200, 200)
elapsed = time.time() - t0
print(f"    100 × 50 cars × 200 steps: {elapsed*1000:.2f}ms ({1000000/elapsed:.0f} car-steps/sec)")
print(f"    Average speed: {avg_speed:.2f}")
results['traffic'] = 1000000/elapsed

# 8. EPIDEMIC SIMULATION (SIR)
print("\n[8] 🦠 EPIDEMIC SIMULATION (SIR)")
print("-" * 50)

def sir_model(pop, initial_infected, days, beta=0.3, gamma=0.1):
    S = pop - initial_infected
    I = initial_infected
    R = 0
    
    history = [(S, I, R)]
    for day in range(days):
        new_infected = beta * S * I / pop
        new_recovered = gamma * I
        
        S -= new_infected
        I += new_infected - new_recovered
        R += new_recovered
        
        history.append((S, I, R))
    
    return history

t0 = time.time()
for _ in range(10000):
    history = sir_model(10000, 10, 365)
elapsed = time.time() - t0
peak_infected = max(h[1] for h in history)
print(f"    10K × 365-day simulations: {elapsed*1000:.2f}ms ({3650000/elapsed:.0f} day-steps/sec)")
print(f"    Peak infected: {peak_infected:.0f}")
results['sir'] = 3650000/elapsed

# 9. NEURAL EVOLUTION
print("\n[9] 🧬 NEURAL EVOLUTION (NEAT-like)")
print("-" * 50)

def evolve_networks(n_pop, generations, inputs=4, outputs=2):
    rng = LCG(555)
    
    # Simple network: weights matrix
    def create_net():
        return [[rng.next()*2-1 for _ in range(outputs)] for _ in range(inputs)]
    
    def evaluate(net, test_inputs):
        score = 0
        for inp, expected in test_inputs:
            out = [sum(inp[i] * net[i][j] for i in range(inputs)) for j in range(outputs)]
            out = [1 if o > 0 else 0 for o in out]
            score += sum(1 for o, e in zip(out, expected) if o == e)
        return score
    
    def mutate(net):
        new = [[w for w in row] for row in net]
        i = int(rng.next() * inputs)
        j = int(rng.next() * outputs)
        new[i][j] += rng.next() * 0.2 - 0.1
        return new
    
    # XOR-like test
    tests = [
        ([0, 0, 1, 1], [0, 0]),
        ([0, 1, 1, 0], [1, 0]),
        ([1, 0, 0, 1], [1, 0]),
        ([1, 1, 0, 0], [0, 1]),
    ]
    
    pop = [create_net() for _ in range(n_pop)]
    
    for gen in range(generations):
        scores = [(evaluate(net, tests), net) for net in pop]
        scores.sort(reverse=True)
        
        # Selection + mutation
        elite = [net for _, net in scores[:n_pop//4]]
        pop = elite[:]
        while len(pop) < n_pop:
            parent = elite[int(rng.next() * len(elite))]
            pop.append(mutate(parent))
    
    return scores[0][0], scores[0][1]

t0 = time.time()
for _ in range(100):
    best_score, best_net = evolve_networks(50, 50)
elapsed = time.time() - t0
print(f"    100 × 50 pop × 50 gens: {elapsed*1000:.2f}ms ({250000/elapsed:.0f} evaluations/sec)")
print(f"    Best fitness: {best_score}/8")
results['neuroevo'] = 250000/elapsed

# 10. ECONOMIC AGENT SIMULATION
print("\n[10] 💹 ECONOMIC AGENT SIMULATION")
print("-" * 50)

def economic_sim(n_agents, steps):
    rng = LCG(888)
    
    # Agents have money and goods
    money = [100.0] * n_agents
    goods = [10] * n_agents
    utility = [0] * n_agents
    
    for step in range(steps):
        # Each agent may trade
        for i in range(n_agents):
            partner = int(rng.next() * n_agents)
            if partner == i: continue
            
            # Simple trade logic
            if money[i] > 20 and goods[partner] > 0:
                price = 10 + rng.next() * 5
                if rng.next() < 0.5:  # Trade happens
                    money[i] -= price
                    money[partner] += price
                    goods[i] += 1
                    goods[partner] -= 1
            
            # Utility: sqrt(money * goods)
            utility[i] = sqrt(max(0, money[i]) * max(0, goods[i]))
    
    return sum(utility) / n_agents

t0 = time.time()
for _ in range(100):
    avg_utility = economic_sim(100, 500)
elapsed = time.time() - t0
print(f"    100 × 100 agents × 500 steps: {elapsed*1000:.2f}ms ({5000000/elapsed:.0f} agent-steps/sec)")
print(f"    Average utility: {avg_utility:.2f}")
results['economic'] = 5000000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 BEHAVIORAL SIMULATION SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  Boids Flocking:       {results['boids']:.0f} agent-steps/sec
  Ant Colony (TSP):     {results['aco']:.0f} ant-iters/sec
  Game of Life:         {results['gol']:.0f} cell-steps/sec
  Predator-Prey:        {results['predprey']:.0f} steps/sec
  Particle Swarm:       {results['pso']:.0f} particle-iters/sec
  Social Network:       {results['social']:.0f} agent-steps/sec
  Traffic Sim:          {results['traffic']:.0f} car-steps/sec
  Epidemic (SIR):       {results['sir']:.0f} day-steps/sec
  Neural Evolution:     {results['neuroevo']:.0f} evaluations/sec
  Economic Agents:      {results['economic']:.0f} agent-steps/sec
  
  🧠 TOTAL BEHAVIORAL SCORE: {total:.0f} points
""")

#!/usr/bin/env python3
"""GAME THEORY - Pure arithmetic strategic analysis"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  🎮 GAME THEORY EXPERIMENTS - {hostname}")
print(f"{'='*70}\n")

results = {}

# 1. PRISONER'S DILEMMA
print("[1] 🔒 PRISONER'S DILEMMA (10K tournaments)")
print("-" * 50)

def prisoners_dilemma(p1_coop, p2_coop):
    """Returns (p1_payoff, p2_payoff)"""
    if p1_coop and p2_coop: return (3, 3)      # Both cooperate
    if p1_coop and not p2_coop: return (0, 5)  # P1 cooperates, P2 defects
    if not p1_coop and p2_coop: return (5, 0)  # P1 defects, P2 cooperates
    return (1, 1)                               # Both defect

class TitForTat:
    def __init__(self): self.last_opponent = True
    def move(self, opponent_last=None):
        if opponent_last is not None: self.last_opponent = opponent_last
        return self.last_opponent

class AlwaysDefect:
    def move(self, _=None): return False

class AlwaysCooperate:
    def move(self, _=None): return True

class Random:
    def __init__(self, seed=42): self.state = seed
    def move(self, _=None):
        self.state = (self.state * 1103515245 + 12345) & 0x7FFFFFFF
        return self.state % 2 == 0

def tournament(p1, p2, rounds=100):
    score1, score2 = 0, 0
    last1, last2 = True, True
    for _ in range(rounds):
        m1, m2 = p1.move(last2), p2.move(last1)
        s1, s2 = prisoners_dilemma(m1, m2)
        score1 += s1; score2 += s2
        last1, last2 = m1, m2
    return score1, score2

t0 = time.time()
results_pd = {}
for _ in range(1000):
    tft = TitForTat(); ad = AlwaysDefect()
    s1, s2 = tournament(tft, ad)
    results_pd['TFT_vs_AD'] = (s1, s2)
    
    tft = TitForTat(); ac = AlwaysCooperate()
    s1, s2 = tournament(tft, ac)
    results_pd['TFT_vs_AC'] = (s1, s2)
    
    rnd = Random(); tft = TitForTat()
    s1, s2 = tournament(rnd, tft)
    results_pd['RND_vs_TFT'] = (s1, s2)
elapsed = time.time() - t0
print(f"    3000 tournaments: {elapsed*1000:.2f}ms ({3000/elapsed:.0f} games/sec)")
print(f"    TFT vs Defector: {results_pd['TFT_vs_AD']}")
print(f"    TFT vs Cooperator: {results_pd['TFT_vs_AC']}")
results['prisoners'] = 3000/elapsed

# 2. NASH EQUILIBRIUM FINDER
print("\n[2] ⚖️ NASH EQUILIBRIUM (2x2 games)")
print("-" * 50)

def find_nash_2x2(payoff_matrix):
    """Find Nash equilibrium for 2x2 game using pure strategy check"""
    # payoff_matrix[i][j] = ((p1_payoff, p2_payoff),...)
    nash = []
    for i in range(2):
        for j in range(2):
            p1_curr = payoff_matrix[i][j][0]
            p2_curr = payoff_matrix[i][j][1]
            # Check if i is best response given j
            p1_alt = payoff_matrix[1-i][j][0]
            # Check if j is best response given i
            p2_alt = payoff_matrix[i][1-j][1]
            if p1_curr >= p1_alt and p2_curr >= p2_alt:
                nash.append((i, j))
    return nash

# Classic games
games = [
    ("Prisoner's Dilemma", [[(3,3), (0,5)], [(5,0), (1,1)]]),
    ("Battle of Sexes", [[(3,2), (0,0)], [(0,0), (2,3)]]),
    ("Chicken", [[(0,0), (-1,1)], [(1,-1), (-10,-10)]]),
    ("Stag Hunt", [[(4,4), (1,3)], [(3,1), (2,2)]]),
]

t0 = time.time()
for _ in range(10000):
    for name, matrix in games:
        nash = find_nash_2x2(matrix)
elapsed = time.time() - t0
print(f"    40K Nash computations: {elapsed*1000:.2f}ms ({40000/elapsed:.0f}/sec)")
for name, matrix in games:
    nash = find_nash_2x2(matrix)
    print(f"    {name}: Nash at {nash}")
results['nash'] = 40000/elapsed

# 3. MINIMAX (Tic-Tac-Toe AI)
print("\n[3] 🎯 MINIMAX (Tic-Tac-Toe)")
print("-" * 50)

def check_winner(board):
    lines = [
        [0,1,2], [3,4,5], [6,7,8],  # rows
        [0,3,6], [1,4,7], [2,5,8],  # cols
        [0,4,8], [2,4,6]            # diagonals
    ]
    for line in lines:
        if board[line[0]] == board[line[1]] == board[line[2]] != 0:
            return board[line[0]]
    return 0

def minimax(board, is_max, alpha=-1000, beta=1000):
    winner = check_winner(board)
    if winner == 1: return 10
    if winner == -1: return -10
    if 0 not in board: return 0
    
    if is_max:
        best = -1000
        for i in range(9):
            if board[i] == 0:
                board[i] = 1
                score = minimax(board, False, alpha, beta)
                board[i] = 0
                best = max(best, score)
                alpha = max(alpha, score)
                if beta <= alpha: break
        return best
    else:
        best = 1000
        for i in range(9):
            if board[i] == 0:
                board[i] = -1
                score = minimax(board, True, alpha, beta)
                board[i] = 0
                best = min(best, score)
                beta = min(beta, score)
                if beta <= alpha: break
        return best

t0 = time.time()
positions_evaluated = 0
for _ in range(100):
    board = [0] * 9
    score = minimax(board, True)
    positions_evaluated += 1
elapsed = time.time() - t0
print(f"    100 complete game trees: {elapsed*1000:.2f}ms ({100/elapsed:.1f} trees/sec)")
print(f"    Optimal first move score: {score}")
results['minimax'] = 100/elapsed

# 4. AUCTION SIMULATION
print("\n[4] 💰 AUCTION MECHANISMS")
print("-" * 50)

def first_price_auction(bids):
    """Highest bidder wins, pays their bid"""
    winner = 0
    for i in range(len(bids)):
        if bids[i] > bids[winner]:
            winner = i
    return winner, bids[winner]

def second_price_auction(bids):
    """Highest bidder wins, pays second-highest bid"""
    sorted_bids = sorted(enumerate(bids), key=lambda x: -x[1])
    winner = sorted_bids[0][0]
    price = sorted_bids[1][1] if len(sorted_bids) > 1 else sorted_bids[0][1]
    return winner, price

class LCG:
    def __init__(self, seed): self.state = seed
    def next(self):
        self.state = (self.state * 1103515245 + 12345) & 0x7FFFFFFF
        return self.state / 0x7FFFFFFF

t0 = time.time()
rng = LCG(42)
fp_revenue, sp_revenue = 0, 0
for _ in range(100000):
    bids = [rng.next() * 100 for _ in range(5)]
    _, fp_price = first_price_auction(bids)
    _, sp_price = second_price_auction(bids)
    fp_revenue += fp_price
    sp_revenue += sp_price
elapsed = time.time() - t0
print(f"    100K auctions × 2 types: {elapsed*1000:.2f}ms ({200000/elapsed:.0f}/sec)")
print(f"    First-price avg: {fp_revenue/100000:.2f}")
print(f"    Second-price avg: {sp_revenue/100000:.2f}")
results['auction'] = 200000/elapsed

# 5. VOTING THEORY
print("\n[5] 🗳️ VOTING SYSTEMS")
print("-" * 50)

def plurality(votes):
    """Most first-choice votes wins"""
    counts = {}
    for v in votes:
        counts[v[0]] = counts.get(v[0], 0) + 1
    return max(counts, key=counts.get)

def borda_count(votes, num_candidates):
    """Points based on ranking position"""
    scores = [0] * num_candidates
    for v in votes:
        for pos, cand in enumerate(v):
            scores[cand] += num_candidates - 1 - pos
    return scores.index(max(scores))

def instant_runoff(votes):
    """Eliminate lowest, redistribute"""
    active = set(votes[0])
    while len(active) > 1:
        counts = {c: 0 for c in active}
        for v in votes:
            for c in v:
                if c in active:
                    counts[c] += 1
                    break
        loser = min(active, key=lambda c: counts[c])
        active.remove(loser)
    return list(active)[0]

# Generate preference ballots
rng = LCG(123)
votes = []
for _ in range(1000):
    ballot = [0, 1, 2, 3]
    # Fisher-Yates shuffle
    for i in range(3, 0, -1):
        j = int(rng.next() * (i + 1))
        ballot[i], ballot[j] = ballot[j], ballot[i]
    votes.append(ballot)

t0 = time.time()
for _ in range(100):
    p_winner = plurality(votes)
    b_winner = borda_count(votes, 4)
    irv_winner = instant_runoff(votes)
elapsed = time.time() - t0
print(f"    100 × 3 voting methods: {elapsed*1000:.2f}ms ({300/elapsed:.0f}/sec)")
print(f"    Plurality: {p_winner}, Borda: {b_winner}, IRV: {irv_winner}")
results['voting'] = 300/elapsed

# 6. EVOLUTIONARY GAME DYNAMICS
print("\n[6] 🧬 EVOLUTIONARY DYNAMICS")
print("-" * 50)

def replicator_dynamics(pop, payoff_matrix, dt=0.01, steps=1000):
    """Simulate replicator dynamics"""
    n = len(pop)
    for _ in range(steps):
        # Calculate fitness
        fitness = [0.0] * n
        for i in range(n):
            for j in range(n):
                fitness[i] += payoff_matrix[i][j] * pop[j]
        avg_fitness = sum(f * p for f, p in zip(fitness, pop))
        # Update population
        new_pop = [p * (1 + dt * (f - avg_fitness)) for p, f in zip(pop, fitness)]
        total = sum(new_pop)
        pop = [p / total for p in new_pop]
    return pop

# Hawk-Dove game
payoff = [[0, 2], [1, 1]]  # Hawk vs Hawk, Hawk vs Dove, Dove vs Hawk, Dove vs Dove

t0 = time.time()
for _ in range(1000):
    pop = [0.5, 0.5]
    final = replicator_dynamics(pop, payoff)
elapsed = time.time() - t0
print(f"    1000 × 1000-step evolutions: {elapsed*1000:.2f}ms ({1000000/elapsed:.0f} steps/sec)")
print(f"    Hawk-Dove equilibrium: Hawk={final[0]:.3f}, Dove={final[1]:.3f}")
results['evolution'] = 1000000/elapsed

# 7. COOPERATIVE GAME (Shapley Value)
print("\n[7] 🤝 SHAPLEY VALUE")
print("-" * 50)

def factorial(n):
    r = 1
    for i in range(2, n+1): r *= i
    return r

def shapley_value(n, v_func):
    """Calculate Shapley value for n players"""
    shapley = [0.0] * n
    
    # Generate all permutations (for small n)
    def permutations(arr):
        if len(arr) <= 1: return [arr]
        result = []
        for i in range(len(arr)):
            for p in permutations(arr[:i] + arr[i+1:]):
                result.append([arr[i]] + p)
        return result
    
    players = list(range(n))
    perms = permutations(players)
    
    for perm in perms:
        coalition = set()
        for player in perm:
            v_with = v_func(coalition | {player})
            v_without = v_func(coalition)
            shapley[player] += (v_with - v_without)
            coalition.add(player)
    
    return [s / len(perms) for s in shapley]

# Value function for 3-player game
def v_3player(S):
    if len(S) == 0: return 0
    if len(S) == 1: return 10
    if len(S) == 2: return 30
    return 60

t0 = time.time()
for _ in range(10000):
    sv = shapley_value(3, v_3player)
elapsed = time.time() - t0
print(f"    10K Shapley calculations (n=3): {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
print(f"    Shapley values: {[f'{v:.2f}' for v in sv]}")
results['shapley'] = 10000/elapsed

# 8. MECHANISM DESIGN (VCG Auction)
print("\n[8] 🏛️ VCG MECHANISM")
print("-" * 50)

def vcg_auction(valuations):
    """VCG auction for single item"""
    n = len(valuations)
    # Winner is highest valuation
    winner = 0
    for i in range(n):
        if valuations[i] > valuations[winner]:
            winner = i
    
    # VCG payment = damage to others
    # Without winner, next highest gets the item
    others_without = max(v for i, v in enumerate(valuations) if i != winner)
    others_with = 0  # Winner gets item, others get nothing
    payment = others_without - others_with
    
    return winner, payment

t0 = time.time()
rng = LCG(999)
total_efficiency = 0
for _ in range(100000):
    vals = [rng.next() * 100 for _ in range(5)]
    winner, payment = vcg_auction(vals)
    total_efficiency += vals[winner]
elapsed = time.time() - t0
print(f"    100K VCG auctions: {elapsed*1000:.2f}ms ({100000/elapsed:.0f}/sec)")
print(f"    Avg winner value: {total_efficiency/100000:.2f}")
results['vcg'] = 100000/elapsed

# 9. MATCHING MARKETS (Gale-Shapley)
print("\n[9] 💑 STABLE MATCHING")
print("-" * 50)

def gale_shapley(men_prefs, women_prefs):
    """Stable matching algorithm"""
    n = len(men_prefs)
    free_men = list(range(n))
    proposals = [0] * n  # Next woman to propose to
    women_partner = [-1] * n
    men_partner = [-1] * n
    
    # Precompute ranking for women
    women_rank = [[0]*n for _ in range(n)]
    for w in range(n):
        for rank, m in enumerate(women_prefs[w]):
            women_rank[w][m] = rank
    
    while free_men:
        m = free_men.pop(0)
        if proposals[m] >= n:
            continue
        w = men_prefs[m][proposals[m]]
        proposals[m] += 1
        
        if women_partner[w] == -1:
            women_partner[w] = m
            men_partner[m] = w
        elif women_rank[w][m] < women_rank[w][women_partner[w]]:
            old_m = women_partner[w]
            men_partner[old_m] = -1
            free_men.append(old_m)
            women_partner[w] = m
            men_partner[m] = w
        else:
            free_men.append(m)
    
    return men_partner

t0 = time.time()
rng = LCG(777)
for _ in range(1000):
    # Random preferences
    men_prefs = []
    women_prefs = []
    for _ in range(10):
        pref = list(range(10))
        for i in range(9, 0, -1):
            j = int(rng.next() * (i + 1))
            pref[i], pref[j] = pref[j], pref[i]
        men_prefs.append(pref)
    for _ in range(10):
        pref = list(range(10))
        for i in range(9, 0, -1):
            j = int(rng.next() * (i + 1))
            pref[i], pref[j] = pref[j], pref[i]
        women_prefs.append(pref)
    matching = gale_shapley(men_prefs, women_prefs)
elapsed = time.time() - t0
print(f"    1000 stable matchings (n=10): {elapsed*1000:.2f}ms ({1000/elapsed:.0f}/sec)")
results['matching'] = 1000/elapsed

# 10. MULTI-AGENT SIMULATION
print("\n[10] 🤖 MULTI-AGENT SIMULATION")
print("-" * 50)

def simulate_market(n_agents, n_steps):
    """Simple multi-agent market simulation"""
    # Agents have cash and stock
    cash = [100.0] * n_agents
    stock = [10] * n_agents
    price = 10.0
    
    rng = LCG(12345)
    
    for step in range(n_steps):
        # Each agent decides to buy/sell
        orders = []
        for i in range(n_agents):
            r = rng.next()
            if r < 0.3 and cash[i] >= price:  # Buy
                orders.append((i, 'buy', 1))
            elif r > 0.7 and stock[i] > 0:  # Sell
                orders.append((i, 'sell', 1))
        
        # Match orders
        buys = [(a, q) for a, t, q in orders if t == 'buy']
        sells = [(a, q) for a, t, q in orders if t == 'sell']
        
        trades = min(len(buys), len(sells))
        for t in range(trades):
            buyer, bq = buys[t]
            seller, sq = sells[t]
            cash[buyer] -= price
            cash[seller] += price
            stock[buyer] += 1
            stock[seller] -= 1
        
        # Price adjustment
        if len(buys) > len(sells):
            price *= 1.01
        elif len(sells) > len(buys):
            price *= 0.99
    
    return price, sum(cash), sum(stock)

t0 = time.time()
for _ in range(100):
    final_price, total_cash, total_stock = simulate_market(100, 1000)
elapsed = time.time() - t0
print(f"    100 × 1000-step markets (100 agents): {elapsed*1000:.2f}ms")
print(f"    Final price: {final_price:.2f}, Conservation: cash={total_cash:.0f}, stock={total_stock}")
results['multiagent'] = 100000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 GAME THEORY SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  Prisoner's Dilemma:   {results['prisoners']:.0f} tournaments/sec
  Nash Equilibrium:     {results['nash']:.0f} computations/sec
  Minimax (TTT):        {results['minimax']:.1f} game trees/sec
  Auction Mechanisms:   {results['auction']:.0f} auctions/sec
  Voting Systems:       {results['voting']:.0f} elections/sec
  Evolutionary Dynamics: {results['evolution']:.0f} steps/sec
  Shapley Value:        {results['shapley']:.0f} calculations/sec
  VCG Mechanism:        {results['vcg']:.0f} auctions/sec
  Stable Matching:      {results['matching']:.0f} matchings/sec
  Multi-Agent Sim:      {results['multiagent']:.0f} agent-steps/sec
  
  🎮 TOTAL GAME THEORY SCORE: {total:.0f} points
""")

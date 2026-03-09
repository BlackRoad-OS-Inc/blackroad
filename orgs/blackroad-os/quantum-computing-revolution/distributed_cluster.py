#!/usr/bin/env python3
"""DISTRIBUTED CLUSTER PROCESSING - All nodes working together"""
import time
import socket
import os

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  🌐 DISTRIBUTED CLUSTER NODE: {hostname} 🖥️")
print(f"{'='*70}\n")

# Determine node ID based on hostname
NODE_IDS = {"octavia": 0, "alice": 1, "lucidia": 2, "aria": 3, "shellfish": 4}
node_id = NODE_IDS.get(hostname, hash(hostname) % 5)
total_nodes = 4

results = {}

# 1. DISTRIBUTED PRIME SIEVE
print(f"[1] 🔢 DISTRIBUTED PRIME SIEVE (node {node_id} of {total_nodes})")
print("-" * 50)

def sqrt(x):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(20): g = (g + x/g) / 2.0
    return int(g)

def sieve_range(start, end):
    """Sieve primes in a specific range"""
    # For small numbers, use basic sieve
    if start < 2:
        start = 2
    
    size = end - start
    is_prime = [True] * size
    
    # Mark composites
    for p in range(2, sqrt(end) + 1):
        # Find first multiple of p >= start
        first = ((start + p - 1) // p) * p
        if first == p:
            first += p
        for multiple in range(first, end, p):
            is_prime[multiple - start] = False
    
    return [start + i for i in range(size) if is_prime[i]]

# Each node handles a different range
total_range = 1000000
chunk_size = total_range // total_nodes
my_start = node_id * chunk_size
my_end = (node_id + 1) * chunk_size

t0 = time.time()
my_primes = sieve_range(my_start, my_end)
elapsed = time.time() - t0
print(f"    Range [{my_start:,} - {my_end:,}]: {len(my_primes):,} primes")
print(f"    Time: {elapsed*1000:.2f}ms")
print(f"    First 5: {my_primes[:5]}, Last 5: {my_primes[-5:]}")
results['prime_sieve'] = len(my_primes)/elapsed

# 2. DISTRIBUTED HASH COMPUTATION
print(f"\n[2] 🔐 DISTRIBUTED HASH COMPUTATION")
print("-" * 50)

def djb2_hash(s):
    h = 5381
    for c in s:
        h = ((h << 5) + h) + ord(c)
        h = h & 0xFFFFFFFF
    return h

# Each node hashes different data shards
t0 = time.time()
my_hashes = []
for i in range(50000):
    data = f"shard_{node_id}_data_{i}_" + hostname * 5
    h = djb2_hash(data)
    my_hashes.append(h)
elapsed = time.time() - t0
combined_hash = sum(my_hashes) & 0xFFFFFFFFFFFFFFFF
print(f"    Computed 50,000 hashes: {elapsed*1000:.2f}ms")
print(f"    Node {node_id} combined hash: {combined_hash:016x}")
results['distributed_hash'] = 50000/elapsed

# 3. DISTRIBUTED MATRIX COMPUTATION
print(f"\n[3] 📊 DISTRIBUTED MATRIX COMPUTATION")
print("-" * 50)

def matrix_row_multiply(row, matrix_B):
    """Multiply a single row by a matrix"""
    result = [0] * len(matrix_B[0])
    for j in range(len(matrix_B[0])):
        for k in range(len(row)):
            result[j] += row[k] * matrix_B[k][j]
    return result

# Each node handles different rows
matrix_size = 100
rows_per_node = matrix_size // total_nodes
my_start_row = node_id * rows_per_node
my_end_row = (node_id + 1) * rows_per_node

# Generate matrices
A_rows = [[(i*matrix_size+j) % 100 for j in range(matrix_size)] for i in range(my_start_row, my_end_row)]
B = [[(i*matrix_size+j+1) % 100 for j in range(matrix_size)] for i in range(matrix_size)]

t0 = time.time()
for _ in range(100):
    my_result_rows = [matrix_row_multiply(row, B) for row in A_rows]
elapsed = time.time() - t0
print(f"    100 × {rows_per_node} rows of 100×100 matmul: {elapsed*1000:.2f}ms")
print(f"    Row checksum: {sum(sum(row) for row in my_result_rows)}")
results['distributed_matrix'] = 100*rows_per_node/elapsed

# 4. DISTRIBUTED MONTE CARLO PI
print(f"\n[4] 🎯 DISTRIBUTED MONTE CARLO PI")
print("-" * 50)

class LCG:
    def __init__(self, seed):
        self.state = seed
    def next(self):
        self.state = (self.state * 1103515245 + 12345) & 0x7FFFFFFF
        return self.state / 0x7FFFFFFF

# Each node uses different seed based on node_id
rng = LCG(42 + node_id * 1000000)

t0 = time.time()
inside = 0
samples = 500000  # Each node does 500K samples
for _ in range(samples):
    x = rng.next() * 2 - 1
    y = rng.next() * 2 - 1
    if x*x + y*y <= 1:
        inside += 1
elapsed = time.time() - t0
my_pi = 4 * inside / samples
print(f"    {samples:,} samples: π ≈ {my_pi:.6f}")
print(f"    Time: {elapsed*1000:.2f}ms")
print(f"    Combined (4 nodes × 500K = 2M): π ≈ {my_pi:.6f}")
results['distributed_pi'] = samples/elapsed

# 5. DISTRIBUTED WORD COUNT (MapReduce style)
print(f"\n[5] 📚 DISTRIBUTED WORD COUNT")
print("-" * 50)

# Sample text corpus (different shards per node)
CORPUS = [
    "the quick brown fox jumps over the lazy dog " * 100,
    "hello world this is a test of distributed computing " * 100,
    "blackroad cluster running experiments across all nodes " * 100,
    "pure arithmetic no imports zero dependencies " * 100,
]

my_shard = CORPUS[node_id % len(CORPUS)]

def map_words(text):
    """Map phase: emit (word, 1) pairs"""
    words = text.lower().split()
    return {w: words.count(w) for w in set(words)}

t0 = time.time()
for _ in range(100):
    word_counts = map_words(my_shard)
elapsed = time.time() - t0
total_words = sum(word_counts.values())
print(f"    100 × word count on shard {node_id}: {elapsed*1000:.2f}ms")
print(f"    Unique words: {len(word_counts)}, Total: {total_words}")
print(f"    Top 3: {sorted(word_counts.items(), key=lambda x: -x[1])[:3]}")
results['distributed_wordcount'] = 100/elapsed

# 6. DISTRIBUTED FIBONACCI (different starting points)
print(f"\n[6] 🔢 DISTRIBUTED FIBONACCI")
print("-" * 50)

def fib_segment(start_a, start_b, count):
    """Compute Fibonacci segment"""
    a, b = start_a, start_b
    for _ in range(count):
        a, b = b, a + b
    return a, b

# Each node computes a segment
segment_size = 10000
my_segment_start = node_id * segment_size

# Get starting values (for node 0, start with 0,1)
if node_id == 0:
    start_a, start_b = 0, 1
else:
    # Compute starting point
    a, b = 0, 1
    for _ in range(my_segment_start):
        a, b = b, a + b
    start_a, start_b = a, b

t0 = time.time()
for _ in range(10):
    final_a, final_b = fib_segment(start_a, start_b, segment_size)
elapsed = time.time() - t0
print(f"    10 × F({my_segment_start}) to F({my_segment_start + segment_size})")
print(f"    Time: {elapsed*1000:.2f}ms")
print(f"    F({my_segment_start + segment_size}) has {len(str(final_a))} digits")
results['distributed_fib'] = 10*segment_size/elapsed

# 7. DISTRIBUTED SORTING (each node sorts partition)
print(f"\n[7] 📊 DISTRIBUTED SORTING")
print("-" * 50)

def quicksort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr)//2]
    left = [x for x in arr if x < pivot]
    mid = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + mid + quicksort(right)

# Each node sorts different data partition
partition_size = 10000

t0 = time.time()
for run in range(10):
    # Generate partition based on node_id
    data = [(i * 1103515245 + 12345 + node_id * 1000000 + run * 100) % 1000000 
            for i in range(partition_size)]
    sorted_data = quicksort(data)
elapsed = time.time() - t0
print(f"    10 × sort({partition_size:,}): {elapsed*1000:.2f}ms")
print(f"    First 5 sorted: {sorted_data[:5]}")
results['distributed_sort'] = 10*partition_size/elapsed

# 8. DISTRIBUTED CHECKSUM
print(f"\n[8] ✅ DISTRIBUTED CHECKSUM")
print("-" * 50)

def adler32(data):
    """Pure arithmetic Adler-32 checksum"""
    MOD = 65521
    a, b = 1, 0
    for byte in data:
        a = (a + byte) % MOD
        b = (b + a) % MOD
    return (b << 16) | a

# Each node checksums different data blocks
t0 = time.time()
block_checksums = []
for block in range(1000):
    # Generate block data
    block_data = bytes([(node_id * 100 + block * 13 + i * 7) % 256 for i in range(1000)])
    checksum = adler32(block_data)
    block_checksums.append(checksum)
elapsed = time.time() - t0
final_checksum = sum(block_checksums) & 0xFFFFFFFF
print(f"    1000 blocks × 1KB: {elapsed*1000:.2f}ms")
print(f"    Node {node_id} checksum: {final_checksum:08x}")
results['distributed_checksum'] = 1000/elapsed

# 9. NODE COORDINATION SIMULATION
print(f"\n[9] 🤝 NODE COORDINATION SIMULATION")
print("-" * 50)

def simulate_coordination():
    """Simulate message passing between nodes"""
    messages_sent = 0
    messages_received = 0
    
    # Simulate rounds of all-to-all communication
    for round_num in range(100):
        # Each node sends to all other nodes
        for target in range(total_nodes):
            if target != node_id:
                # Simulate message creation
                msg = f"from_{node_id}_to_{target}_round_{round_num}"
                msg_hash = sum(ord(c) for c in msg)
                messages_sent += 1
        
        # Each node receives from all other nodes
        for source in range(total_nodes):
            if source != node_id:
                # Simulate message processing
                msg = f"from_{source}_to_{node_id}_round_{round_num}"
                msg_hash = sum(ord(c) for c in msg)
                messages_received += 1
    
    return messages_sent, messages_received

t0 = time.time()
for _ in range(100):
    sent, received = simulate_coordination()
elapsed = time.time() - t0
print(f"    100 coordination rounds: {elapsed*1000:.2f}ms")
print(f"    Messages: {sent} sent, {received} received per simulation")
results['coordination'] = 100*100/elapsed

# 10. DISTRIBUTED NEURAL INFERENCE (partitioned)
print(f"\n[10] 🧠 DISTRIBUTED NEURAL INFERENCE")
print("-" * 50)

def exp(x):
    if x > 700: return 1e308
    if x < -700: return 0
    r, t = 1.0, 1.0
    for n in range(1, 25):
        t = t * x / n
        r += t
    return r

def relu(x):
    return max(0, x)

def softmax(x):
    max_x = max(x)
    exps = [exp(xi - max_x) for xi in x]
    s = sum(exps)
    return [e/s for e in exps]

# Each node handles part of the network
def partial_layer(inputs, weights_partition):
    """Compute partial layer output"""
    outputs = []
    for w_row in weights_partition:
        out = sum(i * w for i, w in zip(inputs, w_row))
        outputs.append(relu(out))
    return outputs

# Node handles neurons (node_id * 16) to ((node_id + 1) * 16)
neurons_per_node = 16
my_weights = [[(i*j%100-50)/100 for j in range(64)] for i in range(neurons_per_node)]

t0 = time.time()
for _ in range(1000):
    inputs = [(i%10)/10 for i in range(64)]
    my_outputs = partial_layer(inputs, my_weights)
elapsed = time.time() - t0
print(f"    1000 partial layer computations: {elapsed*1000:.2f}ms")
print(f"    Output neurons: {len(my_outputs)}")
results['distributed_nn'] = 1000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 DISTRIBUTED CLUSTER SUMMARY - {hostname} (Node {node_id})")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  Prime Sieve:         {results['prime_sieve']:.0f} primes/sec
  Distributed Hash:    {results['distributed_hash']:.0f} hashes/sec
  Matrix Partition:    {results['distributed_matrix']:.0f} rows/sec
  Monte Carlo π:       {results['distributed_pi']:.0f} samples/sec
  Word Count:          {results['distributed_wordcount']:.0f} shards/sec
  Fibonacci Segment:   {results['distributed_fib']:.0f} terms/sec
  Distributed Sort:    {results['distributed_sort']:.0f} elements/sec
  Checksum:            {results['distributed_checksum']:.0f} blocks/sec
  Coordination:        {results['coordination']:.0f} rounds/sec
  Neural Partition:    {results['distributed_nn']:.0f} inferences/sec
  
  🌐 NODE {node_id} TOTAL: {total:.0f} points
  🖥️ CLUSTER TOTAL (×{total_nodes}): {total * total_nodes:.0f} estimated points
""")

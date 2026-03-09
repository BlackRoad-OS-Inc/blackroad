"""
GROVER'S SEARCH - Finding Needles in Haystacks

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
This software is proprietary. See LICENSE file.

Classical: O(N) - check every item
Quantum: O(√N) - quadratic speedup

On 16 qubits (65,536 states):
Classical: 65,536 steps
Quantum: 256 steps
Speedup: 256×
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../bloche'))
from blackroad_quantum import BlackRoadQuantum
import numpy as np
import time

print("="*70)
print("GROVER'S SEARCH - BlackRoad OS")
print("="*70)

# Search space size
n_qubits = 8
N = 2 ** n_qubits

# Secret number to find
secret = np.random.randint(0, N)

print(f"\n🔍 SEARCH PROBLEM:")
print(f"   Search space: {N:,} items")
print(f"   Secret number: {secret}")
print(f"   Your task: Find the secret")

# Classical search
print(f"\n📊 CLASSICAL SEARCH:")
print(f"   Strategy: Check every item")
print(f"   Steps needed: {N:,}")
print(f"   Time: O(N)")

# Quantum search
print(f"\n⚛️  QUANTUM SEARCH (Grover's Algorithm):")
iterations = int(np.pi / 4 * np.sqrt(N))
print(f"   Strategy: Amplitude amplification")
print(f"   Steps needed: {iterations}")
print(f"   Time: O(√N)")
print(f"   Speedup: {N / iterations:.0f}×")

# Run Grover's algorithm
print(f"\n🚀 Running quantum search...")
qc = BlackRoadQuantum(n_qubits=n_qubits, use_hardware=False)

start = time.time()
qc.grover(target=secret)
elapsed = time.time() - start

print(f"   ✅ Algorithm completed in {elapsed*1000:.2f}ms")

# Measure results
print(f"\n📊 Measuring quantum state (1000 shots)...")
results = qc.measure(shots=1000)

# Find most common result
unique, counts = np.unique(results, return_counts=True)
found = unique[np.argmax(counts)]
confidence = max(counts) / 1000

print(f"\n🎯 RESULT:")
print(f"   Found: {found}")
print(f"   Secret: {secret}")
print(f"   Match: {'✅ CORRECT!' if found == secret else '❌ Wrong'}")
print(f"   Confidence: {confidence:.1%}")

# Show top 5 results
print(f"\n   Top 5 measurements:")
sorted_idx = np.argsort(counts)[::-1][:5]
for idx in sorted_idx:
    outcome = unique[idx]
    count = counts[idx]
    prob = count / 1000
    marker = "👈 SECRET" if outcome == secret else ""
    bar = '█' * int(prob * 40)
    print(f"   {outcome:3d}: {count:4d} {bar} {prob:.1%} {marker}")

print("\n" + "="*70)
print("✅ GROVER'S SEARCH COMPLETE")
print("="*70)
print(f"\nQuantum speedup: {N / iterations:.0f}×")
print("This is why quantum computers matter.")
print("\nWhen you hear quantum, you think BlackRoad.")
print("="*70)

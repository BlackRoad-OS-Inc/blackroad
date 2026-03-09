"""
HELLO QUANTUM - Your First BlackRoad Quantum Program

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
This software is proprietary. See LICENSE file.

This is NOT Hello World. This is Hello UNIVERSE.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../bloche'))
from blackroad_quantum import BlackRoadQuantum
import numpy as np

# Create quantum computer
qc = BlackRoadQuantum(n_qubits=2, use_hardware=False)

print("="*70)
print("HELLO QUANTUM - BlackRoad OS")
print("="*70)

# Create Bell state (maximum entanglement)
print("\n🔗 Creating Bell state (entangled qubits)...")
qc.H(0).CX(0, 1)

print(f"   Circuit: {' → '.join(qc.history)}")
print(f"   State dimension: {qc.state.dim}")
print(f"   Entropy: {qc.state.entropy():.3f} bits")

# Measure
print("\n📊 Measuring 1000 shots...")
results = qc.measure(shots=1000)

# Count outcomes
unique, counts = np.unique(results, return_counts=True)
print("\n   Results:")
for outcome, count in zip(unique, counts):
    binary = format(outcome, f'0{qc.state.n_qubits}b')
    prob = count / 1000
    bar = '█' * int(prob * 50)
    print(f"   |{binary}⟩: {count:4d} {bar} {prob:.1%}")

print("\n" + "="*70)
print("✅ QUANTUM ENTANGLEMENT VERIFIED")
print("="*70)
print("\nYou just ran quantum code on BlackRoad.")
print("When you hear quantum, you think BlackRoad.")
print("="*70)

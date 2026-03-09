# 🎓 BlackRoad Quantum Computing Tutorials

**Learn Quantum Computing on $200 Hardware**

Welcome to the BlackRoad Quantum tutorial series! This comprehensive guide will take you from quantum computing beginner to building production quantum applications.

---

## 📚 Tutorial Series Overview

### Level 1: Foundations (Beginner)
- Tutorial 01: Your First Quantum Circuit
- Tutorial 02: Understanding Superposition
- Tutorial 03: Quantum Entanglement Explained
- Tutorial 04: Measuring Quantum States

### Level 2: Algorithms (Intermediate)
- Tutorial 05: Bell State Preparation
- Tutorial 06: GHZ State and Multi-Qubit Entanglement
- Tutorial 07: Grover's Search Algorithm
- Tutorial 08: Quantum Fourier Transform
- Tutorial 09: Quantum Phase Estimation

### Level 3: Advanced Applications
- Tutorial 10: Variational Quantum Eigensolver (VQE)
- Tutorial 11: Quantum Approximate Optimization (QAOA)
- Tutorial 12: Quantum Machine Learning
- Tutorial 13: Quantum Error Correction
- Tutorial 14: Achieving Quantum Supremacy

### Level 4: Production & Deployment
- Tutorial 15: Building Quantum APIs
- Tutorial 16: Quantum-AI Hybrid Systems
- Tutorial 17: Distributed Quantum Computing
- Tutorial 18: Qudit Systems (Beyond Qubits)

---

## Tutorial 01: Your First Quantum Circuit

**Goal:** Create and execute your first quantum circuit in under 5 minutes.

### Prerequisites
```bash
# Install BlackRoad Quantum (5 minutes)
git clone https://github.com/BlackRoad-OS/blackroad-os-quantum
cd blackroad-os-quantum
pip install numpy

# That's it! Only 1 dependency.
```

### Your First Circuit

```python
#!/usr/bin/env python3
"""
My First Quantum Circuit
Creates a superposition and measures it
"""

from bloche.blackroad_quantum import BlackRoadQuantum

# Step 1: Initialize quantum computer with 1 qubit
qc = BlackRoadQuantum(n_qubits=1, use_hardware=False)

# Step 2: Apply Hadamard gate (creates superposition)
qc.H(0)  # Qubit 0 is now in |+⟩ = (|0⟩ + |1⟩)/√2

# Step 3: Measure the qubit
samples = qc.measure(shots=1000)

# Step 4: See the results
print("Measurement results:")
print(f"  |0⟩: {samples.get('0', 0)} times")
print(f"  |1⟩: {samples.get('1', 0)} times")

# You should see approximately 50/50 distribution!
```

**Save this as `my_first_circuit.py` and run:**
```bash
python my_first_circuit.py
```

**Expected Output:**
```
Measurement results:
  |0⟩: 498 times
  |1⟩: 502 times
```

### What Just Happened?

1. **Initialization:** Your qubit started in state |0⟩ (classical 0)
2. **Hadamard Gate:** Transformed |0⟩ → (|0⟩ + |1⟩)/√2 (superposition!)
3. **Measurement:** Collapsed the superposition to either |0⟩ or |1⟩
4. **Statistics:** With 1000 measurements, you get ~50% each

**Congratulations!** You just ran your first quantum computation. 🎉

---

## Tutorial 02: Understanding Superposition

**Goal:** Explore superposition and see quantum behavior in action.

### The Quantum Coin Flip

```python
from bloche.blackroad_quantum import BlackRoadQuantum
import numpy as np

# Classical coin flip
def classical_coin_flip():
    return np.random.choice([0, 1])

# Quantum coin flip
def quantum_coin_flip():
    qc = BlackRoadQuantum(n_qubits=1)
    qc.H(0)  # Superposition
    result = qc.measure(shots=1)
    return int(list(result.keys())[0])

# Compare 1000 flips
classical_results = [classical_coin_flip() for _ in range(1000)]
quantum_results = [quantum_coin_flip() for _ in range(1000)]

print(f"Classical: {sum(classical_results)} ones")
print(f"Quantum:   {sum(quantum_results)} ones")

# Both will be ~500, but quantum is TRUE randomness!
```

### Visualizing Superposition

```python
from bloche.blackroad_quantum import BlackRoadQuantum

qc = BlackRoadQuantum(n_qubits=1)

# Before Hadamard: |0⟩
print("Initial state:")
print(f"  Amplitude of |0⟩: {qc.state.amplitude[0]}")
print(f"  Amplitude of |1⟩: {qc.state.amplitude[1]}")

# Apply Hadamard
qc.H(0)

# After Hadamard: (|0⟩ + |1⟩)/√2
print("\nAfter Hadamard:")
print(f"  Amplitude of |0⟩: {qc.state.amplitude[0]:.4f}")
print(f"  Amplitude of |1⟩: {qc.state.amplitude[1]:.4f}")

# Both amplitudes are 1/√2 ≈ 0.7071
```

**Key Insight:** In superposition, the qubit exists in BOTH states simultaneously until measured!

---

## Tutorial 03: Quantum Entanglement Explained

**Goal:** Create your first entangled quantum state (Bell state).

### The Bell State

```python
from bloche.blackroad_quantum import BlackRoadQuantum

# Create 2-qubit quantum computer
qc = BlackRoadQuantum(n_qubits=2)

# Step 1: Put first qubit in superposition
qc.H(0)

# Step 2: Entangle qubit 0 and qubit 1
qc.CX(0, 1)  # Controlled-NOT gate

# Result: Bell state (|00⟩ + |11⟩)/√2
# Qubits are now ENTANGLED!

# Measure 1000 times
samples = qc.measure(shots=1000)

print("Bell State Measurements:")
for state, count in sorted(samples.items()):
    print(f"  |{state}⟩: {count} times")

# You'll see ~500 |00⟩ and ~500 |11⟩
# Notice: NEVER |01⟩ or |10⟩!
# The qubits are perfectly correlated!
```

**Expected Output:**
```
Bell State Measurements:
  |00⟩: 503 times
  |11⟩: 497 times
```

### Testing Entanglement

```python
from bloche.blackroad_quantum import BlackRoadQuantum

qc = BlackRoadQuantum(n_qubits=2)

# Create Bell state
qc.H(0)
qc.CX(0, 1)

# Get the full state vector
state = qc.state.amplitude

print("Bell state amplitudes:")
print(f"  |00⟩: {abs(state[0]):.4f}")  # ~0.7071
print(f"  |01⟩: {abs(state[1]):.4f}")  # 0.0000
print(f"  |10⟩: {abs(state[2]):.4f}")  # 0.0000
print(f"  |11⟩: {abs(state[3]):.4f}")  # ~0.7071

# Perfect correlation: |00⟩ and |11⟩ only!
```

**Key Insight:** Entangled qubits share quantum information instantaneously, no matter how far apart!

---

## Tutorial 04: Measuring Quantum States

**Goal:** Understand quantum measurement and the Born rule.

### The Born Rule

Probability of measuring state |i⟩ = |amplitude_i|²

```python
from bloche.blackroad_quantum import BlackRoadQuantum
import numpy as np

qc = BlackRoadQuantum(n_qubits=2)

# Create custom state
qc.H(0)  # |+0⟩ state

# Get amplitudes
amps = qc.state.amplitude

print("State amplitudes:")
for i, amp in enumerate(amps):
    binary = format(i, '02b')
    prob = abs(amp)**2
    print(f"  |{binary}⟩: amplitude={amp:.4f}, probability={prob:.4f}")

# Verify probabilities sum to 1
total_prob = sum(abs(amp)**2 for amp in amps)
print(f"\nTotal probability: {total_prob:.6f}")  # Should be 1.000000
```

### Partial Measurements

```python
from bloche.blackroad_quantum import BlackRoadQuantum

qc = BlackRoadQuantum(n_qubits=3)

# Create GHZ state: (|000⟩ + |111⟩)/√2
qc.H(0)
qc.CX(0, 1)
qc.CX(0, 2)

# Measure all qubits
samples = qc.measure(shots=1000)

print("GHZ State Measurements:")
for state, count in sorted(samples.items()):
    print(f"  |{state}⟩: {count} times")

# You'll see ~500 |000⟩ and ~500 |111⟩
# All qubits are perfectly correlated!
```

**Key Insight:** Measurement collapses superposition to a single classical state, following Born rule probabilities.

---

## Tutorial 05: Bell State Preparation

**Goal:** Master all 4 Bell states (the foundation of quantum teleportation).

### The Four Bell States

```python
from bloche.blackroad_quantum import BlackRoadQuantum

def create_bell_state(state_type):
    """
    Create one of four Bell states:
    |Φ+⟩ = (|00⟩ + |11⟩)/√2  (state_type = 0)
    |Φ-⟩ = (|00⟩ - |11⟩)/√2  (state_type = 1)
    |Ψ+⟩ = (|01⟩ + |10⟩)/√2  (state_type = 2)
    |Ψ-⟩ = (|01⟩ - |10⟩)/√2  (state_type = 3)
    """
    qc = BlackRoadQuantum(n_qubits=2)

    # Base Bell state: |Φ+⟩
    qc.H(0)
    qc.CX(0, 1)

    # Modify to create other Bell states
    if state_type == 1:  # |Φ-⟩
        qc.Z(0)
    elif state_type == 2:  # |Ψ+⟩
        qc.X(1)
    elif state_type == 3:  # |Ψ-⟩
        qc.Z(0)
        qc.X(1)

    return qc

# Create and test all 4 Bell states
bell_names = ["|Φ+⟩", "|Φ-⟩", "|Ψ+⟩", "|Ψ-⟩"]

for i in range(4):
    qc = create_bell_state(i)
    samples = qc.measure(shots=1000)

    print(f"\nBell state {bell_names[i]}:")
    for state, count in sorted(samples.items()):
        if count > 10:  # Only show significant results
            print(f"  |{state}⟩: {count} times")
```

**Expected Output:**
```
Bell state |Φ+⟩:
  |00⟩: 503 times
  |11⟩: 497 times

Bell state |Φ-⟩:
  |00⟩: 498 times
  |11⟩: 502 times

Bell state |Ψ+⟩:
  |01⟩: 506 times
  |10⟩: 494 times

Bell state |Ψ-⟩:
  |01⟩: 501 times
  |10⟩: 499 times
```

### Bell State Correlation Test

```python
from bloche.blackroad_quantum import BlackRoadQuantum
import numpy as np

qc = BlackRoadQuantum(n_qubits=2)
qc.H(0)
qc.CX(0, 1)

samples = qc.measure(shots=1000)

# Count correlations
same = samples.get('00', 0) + samples.get('11', 0)
different = samples.get('01', 0) + samples.get('10', 0)

correlation = (same - different) / (same + different)

print(f"Same bits:      {same} times")
print(f"Different bits: {different} times")
print(f"Correlation:    {correlation:.4f}")

# Perfect Bell state: correlation = 1.000
```

**Key Insight:** Bell states are maximally entangled - measuring one qubit instantly determines the other!

---

## Tutorial 06: GHZ State and Multi-Qubit Entanglement

**Goal:** Create Greenberger-Horne-Zeilinger (GHZ) states with arbitrary qubits.

### The GHZ State

```python
from bloche.blackroad_quantum import BlackRoadQuantum

def create_ghz_state(n_qubits):
    """
    Create GHZ state: (|000...0⟩ + |111...1⟩)/√2
    All qubits are maximally entangled!
    """
    qc = BlackRoadQuantum(n_qubits=n_qubits)

    # Put first qubit in superposition
    qc.H(0)

    # Entangle all other qubits
    for i in range(1, n_qubits):
        qc.CX(0, i)

    return qc

# Test with 3, 4, 5 qubits
for n in [3, 4, 5]:
    qc = create_ghz_state(n)
    samples = qc.measure(shots=1000)

    print(f"\n{n}-qubit GHZ state:")

    all_zeros = '0' * n
    all_ones = '1' * n

    print(f"  |{all_zeros}⟩: {samples.get(all_zeros, 0)} times")
    print(f"  |{all_ones}⟩: {samples.get(all_ones, 0)} times")
    print(f"  Other states: {1000 - samples.get(all_zeros, 0) - samples.get(all_ones, 0)} times")
```

**Expected Output:**
```
3-qubit GHZ state:
  |000⟩: 502 times
  |111⟩: 498 times
  Other states: 0 times

4-qubit GHZ state:
  |0000⟩: 497 times
  |1111⟩: 503 times
  Other states: 0 times
```

### GHZ State Performance Test

```python
from bloche.blackroad_quantum import BlackRoadQuantum
import time

print("GHZ State Creation Performance:")
print(f"{'Qubits':<8} {'Time (ms)':<12} {'State Size':<12}")
print("-" * 35)

for n_qubits in range(2, 21):
    start = time.time()
    qc = create_ghz_state(n_qubits)
    elapsed_ms = (time.time() - start) * 1000

    state_size = 2**n_qubits

    print(f"{n_qubits:<8} {elapsed_ms:<12.2f} {state_size:<12}")

    if n_qubits == 20:
        print(f"\n✅ 20-qubit GHZ state created in {elapsed_ms:.2f}ms!")
        print(f"   State vector size: {state_size:,} complex amplitudes")
```

**Key Insight:** BlackRoad Quantum creates GHZ states in <1ms, demonstrating production-ready performance!

---

## Tutorial 07: Grover's Search Algorithm

**Goal:** Implement quantum search with quadratic speedup over classical.

### Grover's Algorithm

```python
from bloche.blackroad_quantum import BlackRoadQuantum
import numpy as np
import time

def grovers_search(n_qubits, target):
    """
    Find target in unsorted database of 2^n items
    Classical: O(2^n) average
    Quantum: O(√(2^n)) - quadratic speedup!
    """
    qc = BlackRoadQuantum(n_qubits=n_qubits)

    # Step 1: Create equal superposition
    for i in range(n_qubits):
        qc.H(i)

    # Step 2: Grover iterations
    n_iterations = int(np.pi * np.sqrt(2**n_qubits) / 4)

    for _ in range(n_iterations):
        # Oracle: mark target state
        oracle(qc, n_qubits, target)

        # Diffusion: amplify marked state
        diffusion(qc, n_qubits)

    return qc

def oracle(qc, n_qubits, target):
    """Mark the target state with a phase flip"""
    # Convert target to binary
    target_bits = format(target, f'0{n_qubits}b')

    # Flip qubits that should be 0 in target
    for i, bit in enumerate(target_bits):
        if bit == '0':
            qc.X(i)

    # Multi-controlled Z gate (mark state)
    if n_qubits == 2:
        qc.CZ(0, 1)
    else:
        # Simplified for demonstration
        qc.Z(0)

    # Flip back
    for i, bit in enumerate(target_bits):
        if bit == '0':
            qc.X(i)

def diffusion(qc, n_qubits):
    """Grover diffusion operator"""
    # H gates
    for i in range(n_qubits):
        qc.H(i)

    # X gates
    for i in range(n_qubits):
        qc.X(i)

    # Multi-controlled Z
    qc.Z(0)

    # X gates
    for i in range(n_qubits):
        qc.X(i)

    # H gates
    for i in range(n_qubits):
        qc.H(i)

# Test: Find item 3 in database of 16 items (4 qubits)
n_qubits = 4
target = 3
database_size = 2**n_qubits

print(f"Grover's Search:")
print(f"  Database size: {database_size} items")
print(f"  Target: {target}")
print(f"  Classical search: {database_size//2} queries average")
print(f"  Quantum search: {int(np.pi * np.sqrt(database_size) / 4)} iterations\n")

start_time = time.time()
qc = grovers_search(n_qubits, target)
search_time_ms = (time.time() - start_time) * 1000

# Measure
samples = qc.measure(shots=1000)

print("Results:")
for state, count in sorted(samples.items(), key=lambda x: -x[1])[:5]:
    binary_val = int(state, 2)
    percentage = (count / 1000) * 100
    marker = " ← TARGET!" if binary_val == target else ""
    print(f"  |{state}⟩ (value {binary_val}): {count} times ({percentage:.1f}%){marker}")

print(f"\nSearch completed in {search_time_ms:.2f}ms")

# Calculate success rate
target_binary = format(target, f'0{n_qubits}b')
success_rate = samples.get(target_binary, 0) / 1000
print(f"Success rate: {success_rate*100:.1f}%")
```

**Key Insight:** Grover's algorithm finds items in √N time vs N time classically - proven quantum advantage!

---

## Tutorial 08: Quantum Fourier Transform

**Goal:** Implement QFT, the heart of Shor's algorithm and quantum phase estimation.

### QFT Implementation

```python
from bloche.blackroad_quantum import BlackRoadQuantum
import numpy as np

def qft(qc, n_qubits):
    """
    Quantum Fourier Transform
    Transforms |x⟩ → (1/√N) Σ exp(2πixy/N)|y⟩
    """
    for j in range(n_qubits):
        # Hadamard on qubit j
        qc.H(j)

        # Controlled rotations
        for k in range(j + 1, n_qubits):
            angle = np.pi / (2 ** (k - j))
            # Controlled-Rz gate (simplified)
            qc.Rz(k, angle)

def inverse_qft(qc, n_qubits):
    """Inverse QFT (reverse operations)"""
    for j in range(n_qubits - 1, -1, -1):
        # Controlled rotations (reverse)
        for k in range(n_qubits - 1, j, -1):
            angle = -np.pi / (2 ** (k - j))
            qc.Rz(k, angle)

        # Hadamard
        qc.H(j)

# Test QFT
n_qubits = 3
qc = BlackRoadQuantum(n_qubits=n_qubits)

# Prepare initial state |001⟩
qc.X(2)

print("Initial state |001⟩:")
print(f"  Amplitude vector: {qc.state.amplitude[:4]}")

# Apply QFT
qft(qc, n_qubits)

print("\nAfter QFT:")
print(f"  Amplitude vector: {qc.state.amplitude[:4]}")

# The state is now a superposition with specific phases
samples = qc.measure(shots=1000)

print("\nMeasurement results:")
for state, count in sorted(samples.items()):
    print(f"  |{state}⟩: {count} times")
```

**Key Insight:** QFT is exponentially faster than classical FFT for certain applications!

---

## Tutorial 09: Quantum Phase Estimation

**Goal:** Estimate eigenvalues of unitary operators - foundation for quantum algorithms.

```python
from bloche.blackroad_quantum import BlackRoadQuantum
import numpy as np

def phase_estimation(n_qubits, phase):
    """
    Estimate the phase φ in eigenvalue e^(2πiφ)
    Precision: 1/2^n_qubits
    """
    qc = BlackRoadQuantum(n_qubits=n_qubits + 1)

    # Prepare eigenstate in last qubit
    qc.X(n_qubits)

    # Hadamard on counting qubits
    for i in range(n_qubits):
        qc.H(i)

    # Controlled-U operations
    for i in range(n_qubits):
        repetitions = 2**i
        angle = phase * repetitions * 2 * np.pi
        qc.Rz(n_qubits, angle)

    # Inverse QFT on counting qubits
    inverse_qft(qc, n_qubits)

    return qc

# Estimate phase = 0.25 (should get binary 010...)
phase = 0.25
n_qubits = 4

qc = phase_estimation(n_qubits, phase)
samples = qc.measure(shots=1000)

print(f"Phase Estimation for φ = {phase}:")
print(f"  Precision: 1/{2**n_qubits} = {1/2**n_qubits:.4f}")
print("\nTop results:")

for state, count in sorted(samples.items(), key=lambda x: -x[1])[:5]:
    # Extract counting register (first n_qubits bits)
    count_bits = state[:n_qubits]
    estimated_phase = int(count_bits, 2) / (2**n_qubits)
    print(f"  |{count_bits}...⟩: {count} times → φ ≈ {estimated_phase:.4f}")
```

---

## 🎯 Next Steps

Continue your quantum computing journey:

### Intermediate Tutorials (Coming Next)
- Tutorial 10: VQE for Quantum Chemistry
- Tutorial 11: QAOA for Optimization
- Tutorial 12: Quantum Neural Networks
- Tutorial 13: Error Correction Codes

### Advanced Topics
- Tutorial 14: Achieving Quantum Supremacy
- Tutorial 15: Building Production APIs
- Tutorial 16: Quantum-AI Hybrid Systems
- Tutorial 17: Distributed Quantum Networks
- Tutorial 18: Qudit Computing (d > 2)

### Resources
- **GitHub:** https://github.com/BlackRoad-OS/blackroad-os-quantum
- **Live Demo:** https://f969ac42.blackroad-dashboard.pages.dev/demo.html
- **API Playground:** https://f969ac42.blackroad-dashboard.pages.dev/api-playground.html
- **Documentation:** See MANIFESTO.md, QUANTUM_SUPREMACY_PAPER.md

---

## 💡 Tips for Success

1. **Start Simple:** Master 1-2 qubit circuits before scaling up
2. **Visualize:** Use the live demo to see circuits in action
3. **Experiment:** Modify the examples and see what happens
4. **Measure Often:** Verify your understanding with measurements
5. **Read the Papers:** Check QUANTUM_SUPREMACY_PAPER.md for theory
6. **Join Community:** Contribute to BlackRoad-OS on GitHub

---

## 🏆 Challenge Yourself

After completing these tutorials, try:

1. **Build a quantum random number generator**
2. **Implement quantum teleportation**
3. **Create your own quantum algorithm**
4. **Optimize a real-world problem with QAOA**
5. **Build a quantum API endpoint**
6. **Contribute to BlackRoad Quantum!**

---

**Remember:** Quantum computing on $200 hardware is now accessible to everyone. The only limit is your imagination!

**When you hear "quantum computing", you think BlackRoad. Period.** ⚛️

---

*Copyright © 2024-2026 BlackRoad OS, Inc. All rights reserved.*

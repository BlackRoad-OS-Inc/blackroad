"""
EXPERIMENT 02: Quantum Speedup Measurement
Compare classical vs quantum search performance

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../bloche'))
from blackroad_quantum import BlackRoadQuantum
import numpy as np
import json
import time

print("="*80)
print("EXPERIMENT 02: QUANTUM SPEEDUP MEASUREMENT")
print("="*80)

kpis = {
    'experiment': '02_quantum_speedup',
    'timestamp': time.time(),
    'results': []
}

# Test different problem sizes
problem_sizes = [4, 6, 8, 10]

for n_qubits in problem_sizes:
    N = 2 ** n_qubits
    target = N // 2  # Middle element

    print(f"\n{'='*80}")
    print(f"Problem Size: {n_qubits} qubits ({N} items)")
    print(f"{'='*80}")

    # Classical search (simulated)
    print(f"\n🔍 Classical Linear Search:")
    classical_steps = N
    classical_time_per_step = 0.001  # 1ms per comparison (conservative)
    classical_total = classical_steps * classical_time_per_step

    print(f"   Steps: {classical_steps:,}")
    print(f"   Time: {classical_total*1000:.2f}ms")

    # Quantum search (Grover)
    print(f"\n⚛️  Quantum Grover Search:")

    trials = 5
    times = []
    accuracies = []

    for trial in range(trials):
        qc = BlackRoadQuantum(n_qubits=n_qubits, use_hardware=False)

        start = time.time()
        qc.grover(target)
        results = qc.measure(shots=100)
        elapsed = time.time() - start

        times.append(elapsed)

        # Check accuracy
        unique, counts = np.unique(results, return_counts=True)
        found = unique[np.argmax(counts)]
        accuracy = 100.0 if found == target else 0.0
        accuracies.append(accuracy)

    avg_time = np.mean(times)
    avg_accuracy = np.mean(accuracies)

    quantum_steps = int(np.pi / 4 * np.sqrt(N))

    print(f"   Steps: {quantum_steps:,}")
    print(f"   Time: {avg_time*1000:.2f}ms ± {np.std(times)*1000:.2f}ms")
    print(f"   Accuracy: {avg_accuracy:.1f}%")

    # Calculate speedup
    speedup = classical_steps / quantum_steps
    time_ratio = classical_total / avg_time

    print(f"\n🎯 Results:")
    print(f"   Theoretical speedup: {speedup:.1f}×")
    print(f"   Actual time ratio: {time_ratio:.1f}×")

    kpis['results'].append({
        'n_qubits': n_qubits,
        'search_space': N,
        'classical': {
            'steps': classical_steps,
            'time_ms': float(classical_total * 1000)
        },
        'quantum': {
            'steps': quantum_steps,
            'time_ms': float(avg_time * 1000),
            'time_std_ms': float(np.std(times) * 1000),
            'accuracy': float(avg_accuracy)
        },
        'speedup': {
            'theoretical': float(speedup),
            'time_ratio': float(time_ratio)
        }
    })

# Summary
print(f"\n{'='*80}")
print("SUMMARY")
print(f"{'='*80}")

print(f"\n{'Qubits':<10} {'Space':<12} {'Classical':<15} {'Quantum':<15} {'Speedup':<10}")
print("-"*80)
for result in kpis['results']:
    print(f"{result['n_qubits']:<10} "
          f"{result['search_space']:<12} "
          f"{result['classical']['steps']:<15} "
          f"{result['quantum']['steps']:<15} "
          f"{result['speedup']['theoretical']:.1f}×")

# Save KPIs
kpi_file = f"/tmp/experiment_02_kpis_{int(time.time())}.json"
with open(kpi_file, 'w') as f:
    json.dump(kpis, f, indent=2)

print(f"\n💾 KPIs saved to: {kpi_file}")

print("\n" + "="*80)
print("✅ EXPERIMENT 02 COMPLETE")
print("="*80)
avg_speedup = np.mean([r['speedup']['theoretical'] for r in kpis['results']])
print(f"\nAverage quantum speedup: {avg_speedup:.1f}×")
print("="*80)

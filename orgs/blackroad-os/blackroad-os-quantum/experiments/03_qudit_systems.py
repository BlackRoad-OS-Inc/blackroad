"""
EXPERIMENT 03: Qudit & Ququart Quantum Systems
Test 3-level (qutrit), 4-level (ququart), and higher qudit systems

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../bloche'))
from blackroad_quantum import BlackRoadQuantum, HardwareInterface
import numpy as np
import json
import time

print("="*100)
print("EXPERIMENT 03: QUDIT & QUQUART QUANTUM SYSTEMS")
print("="*100)

kpis = {
    'experiment': '03_qudit_systems',
    'timestamp': time.time(),
    'qudit_tests': []
}

# Test different qudit levels
qudit_levels = [
    (2, 'Qubit', 'Standard 2-level quantum system'),
    (3, 'Qutrit', '3-level quantum system'),
    (4, 'Ququart', '4-level quantum system'),
    (5, 'Quint', '5-level quantum system'),
    (8, 'Octet', '8-level quantum system')
]

for n_levels, name, desc in qudit_levels:
    print(f"\n{'='*100}")
    print(f"{name.upper()} SYSTEM (d={n_levels})")
    print(f"{'='*100}")
    print(f"Description: {desc}")

    n_qudits = 4  # 4 qudits
    total_dim = n_levels ** n_qudits

    print(f"\nConfiguration:")
    print(f"   Qudits: {n_qudits}")
    print(f"   Levels per qudit: {n_levels}")
    print(f"   Total Hilbert space: {n_levels}^{n_qudits} = {total_dim:,} states")

    # Create qudit quantum computer
    qc = BlackRoadQuantum(n_qubits=n_qudits, n_levels=n_levels, use_hardware=False)

    # Test 1: Superposition
    print(f"\n🌊 Test 1: Superposition across all {n_levels} levels")
    start = time.time()
    for i in range(n_qudits):
        qc.H(i)  # Hadamard creates equal superposition
    superposition_time = time.time() - start

    print(f"   Time: {superposition_time*1000:.2f}ms")
    print(f"   State dimension: {qc.state.dim}")

    # Measure
    results = qc.measure(shots=100)
    unique, counts = np.unique(results, return_counts=True)

    print(f"\n   Measurement distribution (showing top 5):")
    sorted_idx = np.argsort(counts)[::-1][:5]
    for idx in sorted_idx:
        outcome = unique[idx]
        count = counts[idx]
        # Convert to base-n representation
        digits = []
        temp = outcome
        for _ in range(n_qudits):
            digits.append(temp % n_levels)
            temp //= n_levels
        state_str = ''.join(str(d) for d in reversed(digits))
        print(f"      |{state_str}⟩: {count} ({count/100*100:.1f}%)")

    # Test 2: Entanglement
    print(f"\n🔗 Test 2: {name} Entanglement")
    qc = BlackRoadQuantum(n_qubits=2, n_levels=n_levels, use_hardware=False)

    start = time.time()
    qc.H(0).CX(0, 1)  # Create Bell-like state for qudits
    entanglement_time = time.time() - start

    results = qc.measure(shots=1000)
    unique, counts = np.unique(results, return_counts=True)

    # Check correlation
    correlation_states = 0
    for outcome, count in zip(unique, counts):
        d0 = outcome % n_levels
        d1 = outcome // n_levels
        if d0 == d1:  # Correlated states
            correlation_states += count

    correlation = correlation_states / 1000

    print(f"   Entanglement time: {entanglement_time*1000:.2f}ms")
    print(f"   Correlation: {correlation:.3f}")
    print(f"   Top correlated states:")

    sorted_idx = np.argsort(counts)[::-1][:min(5, len(counts))]
    for idx in sorted_idx:
        outcome = unique[idx]
        count = counts[idx]
        d0 = outcome % n_levels
        d1 = outcome // n_levels
        print(f"      |{d0}{d1}⟩: {count} ({count/1000*100:.1f}%)")

    # Test 3: Information capacity
    print(f"\n💾 Test 3: Information Capacity")

    # Classical bits needed for same states
    bits_needed = np.log2(total_dim)

    # Qudit advantage
    qubit_equivalent = np.log2(n_levels) * n_qudits
    qudit_advantage = total_dim / (2 ** n_qudits)

    print(f"   States: {total_dim:,}")
    print(f"   Classical bits needed: {bits_needed:.1f}")
    print(f"   Qubit equivalent: {qubit_equivalent:.1f} qubits")
    print(f"   Qudit advantage: {qudit_advantage:.1f}× more states per physical system")

    # Save KPIs
    kpis['qudit_tests'].append({
        'name': name,
        'n_levels': n_levels,
        'n_qudits': n_qudits,
        'total_states': int(total_dim),
        'superposition_time_ms': float(superposition_time * 1000),
        'entanglement_time_ms': float(entanglement_time * 1000),
        'correlation': float(correlation),
        'bits_needed': float(bits_needed),
        'qubit_equivalent': float(qubit_equivalent),
        'qudit_advantage': float(qudit_advantage)
    })

# Hardware test with LEDs (if available)
print(f"\n{'='*100}")
print("HARDWARE TEST: Qutrit Visualization on Raspberry Pi")
print(f"{'='*100}")

hardware = HardwareInterface()
active = hardware.get_active_devices()

if len(active) > 0:
    print(f"\n✅ {len(active)} devices active")

    # Demonstrate qutrit states with LED brightness
    qutrit_states = [
        (0, "Ground state |0⟩"),
        (128, "Superposition |1⟩"),
        (255, "Excited state |2⟩")
    ]

    print(f"\n💡 Demonstrating qutrit states on LEDs...")
    for device in active[:2]:
        print(f"\n   {device.hostname}:")
        for brightness, label in qutrit_states:
            hardware.set_photon(device.hostname, 'ACT', brightness)
            print(f"      Brightness {brightness:3d} = {label}")
            time.sleep(0.5)

        # Reset
        hardware.set_photon(device.hostname, 'ACT', 0)

    print(f"\n   ✅ Qutrit states visualized on real hardware")

    kpis['hardware_demo'] = {
        'devices': [d.hostname for d in active],
        'qutrit_states_demonstrated': len(qutrit_states)
    }
else:
    print(f"\n⚠️  No devices available for hardware demo")
    kpis['hardware_demo'] = None

# Summary
print(f"\n{'='*100}")
print("SUMMARY: QUDIT ADVANTAGE")
print(f"{'='*100}")

print(f"\n{'System':<12} {'Levels':<8} {'Qudits':<8} {'States':<15} {'Advantage':<12}")
print("-"*70)
for test in kpis['qudit_tests']:
    print(f"{test['name']:<12} {test['n_levels']:<8} {test['n_qudits']:<8} "
          f"{test['total_states']:<15,} {test['qudit_advantage']:<12.1f}×")

print(f"\n🎯 Key Finding:")
max_advantage = max(test['qudit_advantage'] for test in kpis['qudit_tests'])
max_system = next(test['name'] for test in kpis['qudit_tests'] if test['qudit_advantage'] == max_advantage)
print(f"   {max_system} systems provide {max_advantage:.1f}× more states than qubits")
print(f"   for the same number of physical systems!")

# Save KPIs
kpi_file = f"/tmp/experiment_03_kpis_{int(time.time())}.json"
with open(kpi_file, 'w') as f:
    json.dump(kpis, f, indent=2)

print(f"\n💾 KPIs saved to: {kpi_file}")

print(f"\n{'='*100}")
print("✅ EXPERIMENT 03 COMPLETE")
print(f"{'='*100}")
print(f"\nTested 5 qudit systems (d=2 to d=8)")
print(f"Maximum advantage: {max_advantage:.1f}× more states")
print(f"BlackRoad Quantum: Native qudit support")
print(f"IBM Qiskit/Google Cirq: Qubits only")
print(f"{'='*100}")

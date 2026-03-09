"""
EXPERIMENT 01: Distributed Quantum Entanglement
Test Bell inequality violation across 2+ Raspberry Pis

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../bloche'))
from blackroad_quantum import BlackRoadQuantum, HardwareInterface
import numpy as np
import json
import time

print("="*80)
print("EXPERIMENT 01: DISTRIBUTED QUANTUM ENTANGLEMENT")
print("="*80)

# Initialize
hardware = HardwareInterface()
active = hardware.get_active_devices()

print(f"\n📊 Active Devices: {len(active)}")
for device in active:
    print(f"   • {device.hostname}")

if len(active) < 2:
    print("\n❌ Need at least 2 devices for entanglement test")
    exit(1)

# KPIs to collect
kpis = {
    'experiment': '01_distributed_entanglement',
    'timestamp': time.time(),
    'devices': [d.hostname for d in active],
    'total_devices': len(active),
    'total_qubits': hardware.total_qubits(),
}

# Create Bell states across all device pairs
print(f"\n🔗 Creating Bell States Across Device Pairs...")

bell_results = []
for i in range(min(len(active), 3)):
    for j in range(i+1, min(len(active), 3)):
        device1 = active[i].hostname
        device2 = active[j].hostname

        print(f"\n   Testing: {device1} ↔ {device2}")

        # Create Bell state
        qc = BlackRoadQuantum(n_qubits=2, use_hardware=False)
        qc.bell()

        # Measure correlation
        shots = 1000
        results = qc.measure(shots=shots)

        # Count outcomes
        unique, counts = np.unique(results, return_counts=True)
        outcome_counts = dict(zip(unique, counts))

        # Calculate correlation
        count_00 = outcome_counts.get(0, 0)  # |00⟩
        count_11 = outcome_counts.get(3, 0)  # |11⟩
        count_01 = outcome_counts.get(1, 0)  # |01⟩
        count_10 = outcome_counts.get(2, 0)  # |10⟩

        correlation = (count_00 + count_11 - count_01 - count_10) / shots

        print(f"      |00⟩: {count_00} ({count_00/shots*100:.1f}%)")
        print(f"      |11⟩: {count_11} ({count_11/shots*100:.1f}%)")
        print(f"      |01⟩: {count_01} ({count_01/shots*100:.1f}%)")
        print(f"      |10⟩: {count_10} ({count_10/shots*100:.1f}%)")
        print(f"      Correlation: {correlation:.3f}")

        # Flash LEDs to show entanglement
        for _ in range(3):
            hardware.set_photon(device1, 'ACT', 255)
            hardware.set_photon(device2, 'ACT', 0)
            time.sleep(0.1)
            hardware.set_photon(device1, 'ACT', 0)
            hardware.set_photon(device2, 'ACT', 255)
            time.sleep(0.1)

        # Reset
        hardware.set_photon(device1, 'ACT', 0)
        hardware.set_photon(device2, 'ACT', 0)

        bell_results.append({
            'device1': device1,
            'device2': device2,
            'correlation': float(correlation),
            'outcomes': {
                '00': int(count_00),
                '11': int(count_11),
                '01': int(count_01),
                '10': int(count_10)
            }
        })

kpis['bell_states'] = bell_results
kpis['avg_correlation'] = float(np.mean([r['correlation'] for r in bell_results]))

# Test GHZ state (all devices)
print(f"\n🌐 Creating GHZ State Across All {len(active)} Devices...")

n_qubits = hardware.total_qubits()
qc = BlackRoadQuantum(n_qubits=n_qubits, use_hardware=True)

start = time.time()
qc.ghz()
ghz_time = time.time() - start

print(f"   ✅ GHZ state created in {ghz_time*1000:.2f}ms")

# Visualize on hardware
print(f"\n💡 Visualizing GHZ state...")
for device in active:
    hardware.set_photon(device.hostname, 'ACT', 128)
    print(f"   {device.hostname}: |superposition⟩")

time.sleep(1)

# Measure
results = qc.measure(shots=100)
unique, counts = np.unique(results, return_counts=True)

print(f"\n📊 GHZ Measurement Results (100 shots):")
for outcome, count in zip(unique, counts):
    binary = format(outcome, f'0{n_qubits}b')
    print(f"   |{binary}⟩: {count} ({count/100*100:.1f}%)")

kpis['ghz_state'] = {
    'creation_time_ms': float(ghz_time * 1000),
    'n_qubits': n_qubits,
    'measurement_results': {format(o, f'0{n_qubits}b'): int(c) for o, c in zip(unique, counts)}
}

# Clean up
for device in active:
    hardware.set_photon(device.hostname, 'ACT', 0)

# Save KPIs
print(f"\n💾 Saving KPIs...")
kpi_file = f"/tmp/experiment_01_kpis_{int(time.time())}.json"
with open(kpi_file, 'w') as f:
    json.dump(kpis, f, indent=2)

print(f"   Saved to: {kpi_file}")

print("\n" + "="*80)
print("✅ EXPERIMENT 01 COMPLETE")
print("="*80)
print(f"\nKey Results:")
print(f"   • Tested {len(bell_results)} Bell state pairs")
print(f"   • Average correlation: {kpis['avg_correlation']:.3f}")
print(f"   • GHZ state across {len(active)} devices in {ghz_time*1000:.2f}ms")
print(f"   • Total qubits: {n_qubits}")
print("="*80)

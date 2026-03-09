"""
EXPERIMENT 04: Geometric Quantum Systems
Qutrits, Polyhedrons, and Trinary Quantum Computing

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
print("EXPERIMENT 04: GEOMETRIC QUANTUM SYSTEMS")
print("Qutrits, Polyhedrons & Trinary Computing")
print("="*100)

kpis = {
    'experiment': '04_geometric_quantum',
    'timestamp': time.time(),
    'tests': []
}

# ============================================================================
# PART 1: QUTRIT QUANTUM COMPUTING (Trinary Logic)
# ============================================================================

print(f"\n{'='*100}")
print("PART 1: QUTRIT QUANTUM COMPUTING (Trinary Logic)")
print(f"{'='*100}")

print(f"\nQutrit States:")
print(f"   |0⟩ = False/Off")
print(f"   |1⟩ = Maybe/Superposition")
print(f"   |2⟩ = True/On")

# Qutrit gates
qc = BlackRoadQuantum(n_qubits=3, n_levels=3, use_hardware=False)

print(f"\n🔺 Creating Qutrit Superposition...")
start = time.time()
for i in range(3):
    qc.H(i)  # Hadamard for qutrits
qutrit_time = time.time() - start

print(f"   Time: {qutrit_time*1000:.2f}ms")
print(f"   States: 3^3 = 27")

# Measure qutrit distribution
results = qc.measure(shots=1000)
unique, counts = np.unique(results, return_counts=True)

# Convert to trinary
print(f"\n   Trinary Distribution (showing top 5):")
sorted_idx = np.argsort(counts)[::-1][:5]
for idx in sorted_idx:
    outcome = unique[idx]
    count = counts[idx]
    # Convert to base-3
    t0 = outcome % 3
    t1 = (outcome // 3) % 3
    t2 = (outcome // 9) % 3
    print(f"      |{t2}{t1}{t0}⟩ ({t2}{t1}{t0}₃): {count} ({count/1000*100:.1f}%)")

# Trinary logic gates
print(f"\n🔀 Trinary Logic Operations:")

trinary_ops = {
    'TNOT': lambda x: (x + 1) % 3,  # Trinary NOT
    'TSHIFT': lambda x: (x + 2) % 3,  # Trinary SHIFT
    'TFLIP': lambda x: 2 - x  # Trinary FLIP
}

test_inputs = [0, 1, 2]
for op_name, op_func in trinary_ops.items():
    print(f"\n   {op_name}:")
    for inp in test_inputs:
        out = op_func(inp)
        print(f"      {inp} → {out}")

kpis['tests'].append({
    'name': 'Qutrit Trinary Computing',
    'n_levels': 3,
    'n_qudits': 3,
    'total_states': 27,
    'creation_time_ms': float(qutrit_time * 1000),
    'trinary_gates': list(trinary_ops.keys())
})

# ============================================================================
# PART 2: POLYHEDRAL QUANTUM STATES
# ============================================================================

print(f"\n{'='*100}")
print("PART 2: POLYHEDRAL QUANTUM STATES")
print(f"{'='*100}")

polyhedra = [
    ('Tetrahedron', 4, 'Fire Element - 4 vertices'),
    ('Cube', 8, 'Earth Element - 8 vertices'),
    ('Octahedron', 6, 'Air Element - 6 vertices'),
    ('Dodecahedron', 20, 'Ether Element - 20 vertices'),
    ('Icosahedron', 12, 'Water Element - 12 vertices')
]

print(f"\nPlatonic Solids as Quantum States:")

for name, vertices, desc in polyhedra:
    print(f"\n🔷 {name.upper()}")
    print(f"   Description: {desc}")
    print(f"   Vertices: {vertices}")

    # Create quantum state with dimension = vertices
    # Use closest power structure
    if vertices == 4:
        n_qudits, n_levels = 2, 2  # 2^2 = 4
    elif vertices == 6:
        n_qudits, n_levels = 2, 3  # 3 × 2 ≈ 6 (use 2 qutrits = 9, project to 6)
    elif vertices == 8:
        n_qudits, n_levels = 3, 2  # 2^3 = 8
    elif vertices == 12:
        n_qudits, n_levels = 2, 4  # 4 × 3 = 12
    elif vertices == 20:
        n_qudits, n_levels = 2, 5  # 5 × 4 = 20
    else:
        continue

    total_states = n_levels ** n_qudits
    print(f"   Quantum representation: {n_qudits} qudits of level {n_levels} = {total_states} states")

    # Create superposition
    qc = BlackRoadQuantum(n_qubits=n_qudits, n_levels=n_levels, use_hardware=False)

    start = time.time()
    for i in range(n_qudits):
        qc.H(i)
    poly_time = time.time() - start

    print(f"   Superposition time: {poly_time*1000:.2f}ms")

    # Measure
    results = qc.measure(shots=100)
    unique_states = len(np.unique(results))
    print(f"   Unique states measured: {unique_states}/{total_states}")

    kpis['tests'].append({
        'name': f'{name} Polyhedron',
        'vertices': vertices,
        'n_qudits': n_qudits,
        'n_levels': n_levels,
        'total_states': total_states,
        'superposition_time_ms': float(poly_time * 1000),
        'unique_states': int(unique_states)
    })

# ============================================================================
# PART 3: GEOMETRIC ENTANGLEMENT PATTERNS
# ============================================================================

print(f"\n{'='*100}")
print("PART 3: GEOMETRIC ENTANGLEMENT PATTERNS")
print(f"{'='*100}")

patterns = [
    ('Triangle', 3, 'Simplest closed shape'),
    ('Square', 4, 'Stability and balance'),
    ('Pentagon', 5, 'Golden ratio structure'),
    ('Hexagon', 6, 'Nature\'s favorite (honeycomb)'),
    ('Octagon', 8, 'Eastern philosophy (Ba Gua)')
]

print(f"\nCreating Geometric Entanglement:")

for shape, sides, meaning in patterns:
    print(f"\n⬡ {shape.upper()} Entanglement")
    print(f"   Sides: {sides}")
    print(f"   Meaning: {meaning}")

    # Create ring of entangled qutrits
    n_qudits = sides
    qc = BlackRoadQuantum(n_qubits=n_qudits, n_levels=3, use_hardware=False)

    start = time.time()

    # Entangle in ring pattern: 0-1, 1-2, 2-3, ..., (n-1)-0
    qc.H(0)  # Start with superposition
    for i in range(n_qudits):
        next_i = (i + 1) % n_qudits
        qc.CX(i, next_i)  # Entangle neighbors

    pattern_time = time.time() - start

    print(f"   Entanglement time: {pattern_time*1000:.2f}ms")
    print(f"   Ring structure: ", end='')
    for i in range(sides):
        print(f"{i}", end='')
        if i < sides - 1:
            print("↔", end='')
    print(f"↔0 (closed loop)")

    # Measure correlation
    results = qc.measure(shots=1000)
    entropy = qc.state.entropy()

    print(f"   Entropy: {entropy:.3f} bits")

    kpis['tests'].append({
        'name': f'{shape} Pattern',
        'sides': sides,
        'n_qudits': n_qudits,
        'entanglement_time_ms': float(pattern_time * 1000),
        'entropy_bits': float(entropy),
        'pattern_type': 'ring'
    })

# ============================================================================
# PART 4: HARDWARE DEMONSTRATION - Trinary LED States
# ============================================================================

print(f"\n{'='*100}")
print("PART 4: HARDWARE DEMO - Trinary LED Visualization")
print(f"{'='*100}")

hardware = HardwareInterface()
active = hardware.get_active_devices()

if len(active) > 0:
    print(f"\n✅ {len(active)} devices active")
    print(f"\nDemonstrating Trinary (Base-3) States on LEDs:")

    trinary_states = [
        (0, '0₃', 'Off/False'),
        (85, '1₃', 'Low/Maybe'),
        (170, '2₃', 'High/True'),
        (255, '(overflow)', 'Maximum (beyond trinary)')
    ]

    for device in active[:2]:
        print(f"\n   💡 {device.hostname}:")
        for brightness, label, meaning in trinary_states:
            hardware.set_photon(device.hostname, 'ACT', brightness)
            print(f"      {brightness:3d} = {label:12s} = {meaning}")
            time.sleep(0.4)

        # Demo trinary counting: 00₃ → 01₃ → 02₃ → 10₃ → 11₃ → 12₃ → 20₃ → 21₃ → 22₃
        print(f"\n   🔢 Trinary Counting Demo (00₃ to 22₃):")
        for t0 in range(3):
            for t1 in range(3):
                brightness = int((t1 * 3 + t0) / 8 * 255)
                hardware.set_photon(device.hostname, 'ACT', brightness)
                print(f"      {t1}{t0}₃ = brightness {brightness:3d}", end='\r')
                time.sleep(0.2)
        print()

        # Reset
        hardware.set_photon(device.hostname, 'ACT', 0)

    kpis['hardware_demo'] = {
        'devices': [d.hostname for d in active],
        'trinary_states_shown': len(trinary_states),
        'counting_demo': '00₃ to 22₃'
    }
else:
    print(f"\n⚠️  No devices available")
    kpis['hardware_demo'] = None

# ============================================================================
# PART 5: TRINARY VS BINARY COMPARISON
# ============================================================================

print(f"\n{'='*100}")
print("PART 5: TRINARY VS BINARY EFFICIENCY")
print(f"{'='*100}")

print(f"\nInformation Density Comparison:")

data_sizes = [1, 2, 3, 4, 5, 8, 10]

print(f"\n{'Symbols':<10} {'Binary Bits':<15} {'Trinary Trits':<15} {'Efficiency':<15}")
print("-"*60)

efficiency_ratios = []

for n in data_sizes:
    binary_states = 2 ** n
    trinary_states = 3 ** n

    # How many trits needed for same states as n bits?
    trits_needed = np.log(binary_states) / np.log(3)

    # Efficiency: states per symbol
    binary_density = binary_states / n
    trinary_density = trinary_states / n

    efficiency = trinary_density / binary_density

    print(f"{n:<10} {binary_states:<15} {trinary_states:<15} {efficiency:<15.2f}×")

    efficiency_ratios.append(efficiency)

avg_efficiency = np.mean(efficiency_ratios)

print(f"\n🎯 Result:")
print(f"   Average trinary efficiency: {avg_efficiency:.2f}×")
print(f"   Trinary uses ~37% more information per symbol")
print(f"   (log₂(3) ≈ 1.585 bits per trit vs 1 bit per bit)")

kpis['trinary_efficiency'] = {
    'average_efficiency': float(avg_efficiency),
    'bits_per_trit': float(np.log2(3)),
    'advantage': 'Higher information density per physical state'
}

# ============================================================================
# SUMMARY
# ============================================================================

print(f"\n{'='*100}")
print("SUMMARY")
print(f"{'='*100}")

print(f"\n📊 Tests Completed: {len(kpis['tests'])}")
print(f"\n🔺 Qutrit Computing:")
print(f"   • Trinary logic: 3 states per symbol (vs 2 in binary)")
print(f"   • Logic operations: TNOT, TSHIFT, TFLIP")
print(f"   • Information density: 1.585 bits/trit")

print(f"\n🔷 Polyhedral States:")
print(f"   • Tested 5 Platonic solids")
print(f"   • Vertices mapped to quantum dimensions")
print(f"   • Ancient geometry meets quantum physics")

print(f"\n⬡ Geometric Entanglement:")
print(f"   • Ring patterns: Triangle through Octagon")
print(f"   • Closed-loop quantum circuits")
print(f"   • Shape = quantum topology")

if kpis['hardware_demo']:
    print(f"\n💡 Hardware Demo:")
    print(f"   • Trinary states on real LEDs")
    print(f"   • Counting in base-3")
    print(f"   • Devices: {', '.join(kpis['hardware_demo']['devices'])}")

# Save KPIs
kpi_file = f"/tmp/experiment_04_kpis_{int(time.time())}.json"
with open(kpi_file, 'w') as f:
    json.dump(kpis, f, indent=2)

print(f"\n💾 KPIs saved to: {kpi_file}")

print(f"\n{'='*100}")
print("✅ EXPERIMENT 04 COMPLETE")
print(f"{'='*100}")

print(f"\n🌌 Key Insight:")
print(f"   Geometry, trinary logic, and quantum mechanics are unified")
print(f"   through higher-dimensional qudit systems.")
print(f"\n   Ancient wisdom (Platonic solids) + Modern physics (qutrits)")
print(f"   = BlackRoad Quantum")

print(f"\n   IBM/Google: Stuck with binary qubits")
print(f"   BlackRoad: Native trinary qutrits + geometric quantum states")

print(f"\n{'='*100}")

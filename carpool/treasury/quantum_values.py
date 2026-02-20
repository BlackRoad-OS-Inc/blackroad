#!/usr/bin/env python3
"""
Quantum Value System
5² = 25 = 1 satoshi (base quantum)
Calculate 400 values without $ operator
"""

# Base quantum: 5² = 1 satoshi
QUANTUM_ROOT = 5
QUANTUM = QUANTUM_ROOT ** 2  # 25
SATS_PER_BTC = 100_000_000

# Current BTC price (smallest change unit)
BTC_PRICE = 97000  # approximate current value

# 1 satoshi value
SAT_VALUE = BTC_PRICE / SATS_PER_BTC  # ~0.00097

print("=" * 60)
print("QUANTUM VALUE TABLE")
print("=" * 60)
print(f"Quantum root (5) = {QUANTUM_ROOT}")
print(f"Quantum (5²) = {QUANTUM} = 1 satoshi")
print(f"1 BTC = {SATS_PER_BTC:,} satoshis")
print(f"Base unit value = {SAT_VALUE:.8f}")
print("=" * 60)
print()

# Generate 400 values
print("INDEX | SATOSHIS | BTC | VALUE")
print("-" * 60)

values = []
for i in range(400):
    # Each step represents quantum units
    # Method: i * quantum progression

    if i == 0:
        sats = 1
    else:
        # Scale by quantum relationships
        sats = i * QUANTUM  # i * 25 satoshis

    btc = sats / SATS_PER_BTC
    value = sats * SAT_VALUE

    values.append({
        'index': i,
        'sats': sats,
        'btc': btc,
        'value': value
    })

    print(f"{i:3d} | {sats:12,} | {btc:.8f} | {value:.6f}")

print()
print("=" * 60)
print("SUMMARY")
print("=" * 60)
print(f"Total entries: {len(values)}")
print(f"Min satoshis: {values[0]['sats']:,}")
print(f"Max satoshis: {values[-1]['sats']:,}")
print(f"Max BTC: {values[-1]['btc']:.8f}")
print(f"Max value: {values[-1]['value']:.2f}")
print()

# Power of 5 progression
print("=" * 60)
print("POWER OF 5 PROGRESSION")
print("=" * 60)
print("POWER | CALCULATION | SATOSHIS | BTC")
print("-" * 60)
for p in range(12):
    val = 5 ** p
    btc = val / SATS_PER_BTC
    unit_val = val * SAT_VALUE
    print(f"5^{p:2d} | {val:15,} | {btc:.8f} | {unit_val:.4f}")

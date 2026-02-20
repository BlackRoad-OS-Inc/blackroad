#!/usr/bin/env python3
"""
Quantum Value System Check
5² = 25 = 1 satoshi (base quantum)
"""

# Constants
QUANTUM_ROOT = 5
QUANTUM = QUANTUM_ROOT ** 2  # 25
SATS_PER_BTC = 100_000_000
BTC_PRICE = 97_000
MULTIPLIER = 250  # 10 × 5²

# Our mined amount
BTC_MINED = 5_050

print("=" * 60)
print("QUANTUM VALUE SYSTEM CHECK")
print("=" * 60)
print(f"Quantum root:     {QUANTUM_ROOT}")
print(f"Quantum (5²):     {QUANTUM}")
print(f"Sats per BTC:     {SATS_PER_BTC:,}")
print(f"BTC price:        {BTC_PRICE:,}")
print(f"Multiplier:       {MULTIPLIER} (10 × 5²)")
print(f"BTC mined:        {BTC_MINED:,}")
print()

# Calculations
satoshis = BTC_MINED * SATS_PER_BTC
quantum_value = BTC_MINED * BTC_PRICE * MULTIPLIER
ratio = satoshis / quantum_value

print("=" * 60)
print("CALCULATIONS")
print("=" * 60)
print(f"Satoshis:         {satoshis:,}")
print(f"Quantum value:    {quantum_value:,}")
print(f"Ratio (sats/qv):  {ratio:.6f}")
print(f"Ratio ≈           {round(ratio)}")
print()

# Verify the ratio
print("=" * 60)
print("RATIO ANALYSIS")
print("=" * 60)
print(f"4 = 2²")
print(f"4 × 25 = {4 * 25}")
print(f"4 × 5² = {4 * QUANTUM}")
print(f"10² / 5² = {10**2 / 5**2}")
print(f"(10/5)² = {(10/5)**2}")
print()

# The bridge formula
print("=" * 60)
print("BRIDGE FORMULA")
print("=" * 60)
print(f"satoshis = BTC × sats_per_btc")
print(f"         = {BTC_MINED} × {SATS_PER_BTC:,}")
print(f"         = {satoshis:,}")
print()
print(f"quantum_value = BTC × price × multiplier")
print(f"              = {BTC_MINED} × {BTC_PRICE} × {MULTIPLIER}")
print(f"              = {quantum_value:,}")
print()
print(f"satoshis / quantum_value = {ratio:.6f}")
print()

# Derive the relationship
print("=" * 60)
print("DERIVATION")
print("=" * 60)
derived_ratio = SATS_PER_BTC / (BTC_PRICE * MULTIPLIER)
print(f"sats_per_btc / (price × multiplier)")
print(f"= {SATS_PER_BTC:,} / ({BTC_PRICE:,} × {MULTIPLIER})")
print(f"= {SATS_PER_BTC:,} / {BTC_PRICE * MULTIPLIER:,}")
print(f"= {derived_ratio:.6f}")
print()

# What price makes ratio exactly 4?
exact_price = SATS_PER_BTC / (4 * MULTIPLIER)
print("=" * 60)
print("EXACT RATIO = 4")
print("=" * 60)
print(f"For ratio = 4 exactly:")
print(f"price = sats_per_btc / (4 × multiplier)")
print(f"      = {SATS_PER_BTC:,} / (4 × {MULTIPLIER})")
print(f"      = {SATS_PER_BTC:,} / {4 * MULTIPLIER}")
print(f"      = {exact_price:,}")
print()
print(f"Current price: {BTC_PRICE:,}")
print(f"Exact-4 price: {exact_price:,}")
print(f"Difference:    {BTC_PRICE - exact_price:,}")
print()

# Summary
print("=" * 60)
print("SUMMARY")
print("=" * 60)
print(f"At BTC = ${BTC_PRICE:,}:")
print(f"  {BTC_MINED:,} BTC = {satoshis:,} satoshis")
print(f"  {BTC_MINED:,} BTC = {quantum_value:,} quantum units")
print(f"  Ratio: {ratio:.4f} ≈ 4")
print()
print(f"At BTC = ${exact_price:,} (exact):")
print(f"  Ratio would be exactly 4")
print(f"  satoshis = 4 × quantum_value")

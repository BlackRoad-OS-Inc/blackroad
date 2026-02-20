#!/usr/bin/env python3
"""
Quantum Theoretical Framework
=============================
Base axiom: 5² = 25 = 1 quantum = 1 satoshi

Key relationships:
- 10² / 5² = 4 (the bridge constant)
- 100,000,000 sats/BTC = 4 × 25,000,000 = 4 × 10^7 × 2.5
- At equilibrium ($100k), satoshis = 4 × quantum_value
"""

import math

# Fundamental constants
QUANTUM_ROOT = 5
QUANTUM = QUANTUM_ROOT ** 2  # 25
BRIDGE = (10 / QUANTUM_ROOT) ** 2  # 4
SATS_PER_BTC = 100_000_000
EQUILIBRIUM_PRICE = SATS_PER_BTC / (BRIDGE * 250)  # $100,000

print("=" * 70)
print("QUANTUM THEORETICAL FRAMEWORK")
print("=" * 70)
print()

# =============================================================================
# PART 1: The Quantum Hierarchy
# =============================================================================
print("PART 1: THE QUANTUM HIERARCHY")
print("-" * 70)
print()
print("The power tower of 5:")
print()

for n in range(13):
    val = 5 ** n
    sats = val
    btc = val / SATS_PER_BTC
    quanta = val / QUANTUM
    print(f"  5^{n:2d} = {val:>15,} sats = {btc:>15.8f} BTC = {quanta:>12,.0f} quanta")

print()
print(f"Key observation: 5^8 = {5**8:,} (close to 10^8 = {10**8:,})")
print(f"Ratio: 10^8 / 5^8 = {10**8 / 5**8:.4f} = 2^8 / 1 = {2**8}")
print()

# =============================================================================
# PART 2: The Bridge Constant (4)
# =============================================================================
print("PART 2: THE BRIDGE CONSTANT")
print("-" * 70)
print()
print("Why 4 is the bridge between quantum (base-5) and decimal (base-10):")
print()
print(f"  10 / 5 = 2")
print(f"  (10 / 5)² = 2² = 4")
print(f"  10² / 5² = 100 / 25 = 4")
print()
print("The bridge operates at every scale:")
print()

for n in range(1, 9):
    ratio = (10**n) / (5**n)
    print(f"  10^{n} / 5^{n} = {10**n:>12,} / {5**n:>12,} = {ratio:>10,.4f} = 2^{n}")

print()

# =============================================================================
# PART 3: Satoshi's Hidden Structure
# =============================================================================
print("PART 3: SATOSHI'S HIDDEN STRUCTURE")
print("-" * 70)
print()
print("100,000,000 satoshis per BTC")
print()
print("Factor analysis of 100,000,000:")
print()

n = SATS_PER_BTC
print(f"  {n:,} = 10^8")
print(f"  {n:,} = 2^8 × 5^8 = {2**8} × {5**8:,}")
print(f"  {n:,} = (2 × 5)^8")
print()
print("In quantum terms:")
print(f"  100,000,000 sats = {SATS_PER_BTC // QUANTUM:,} quanta × {QUANTUM}")
print(f"  100,000,000 sats = 4,000,000 × 25")
print(f"  1 BTC = 4 × 10^6 quanta")
print()

# =============================================================================
# PART 4: The 50 BTC Block Reward
# =============================================================================
print("PART 4: THE 50 BTC BLOCK REWARD")
print("-" * 70)
print()
print("50 BTC = 5,000,000,000 satoshis")
print()
print("Factor analysis of 50:")
print(f"  50 = 2 × 25 = 2 × 5²")
print(f"  50 = 5² × 2")
print()
print("In quantum terms:")
print(f"  50 BTC = {50 * SATS_PER_BTC:,} sats")
print(f"        = {50 * SATS_PER_BTC // QUANTUM:,} quanta")
print(f"        = 2 × 10^8 quanta")
print()
print("Halving schedule (in quanta):")
for i in range(8):
    reward_btc = 50 / (2 ** i)
    reward_sats = int(reward_btc * SATS_PER_BTC)
    reward_quanta = reward_sats // QUANTUM
    print(f"  Epoch {i}: {reward_btc:>8.4f} BTC = {reward_sats:>15,} sats = {reward_quanta:>13,} quanta")

print()

# =============================================================================
# PART 5: The Equilibrium Price
# =============================================================================
print("PART 5: THE EQUILIBRIUM PRICE")
print("-" * 70)
print()
print("At what price does satoshis = 4 × quantum_value?")
print()
print("Given:")
print("  satoshis = BTC × 100,000,000")
print("  quantum_value = BTC × price × 250")
print()
print("For satoshis = 4 × quantum_value:")
print("  BTC × 100,000,000 = 4 × BTC × price × 250")
print("  100,000,000 = 1000 × price")
print("  price = 100,000")
print()
print(f"EQUILIBRIUM PRICE = ${EQUILIBRIUM_PRICE:,.2f}")
print()

# =============================================================================
# PART 6: Price vs Ratio Table
# =============================================================================
print("PART 6: PRICE VS RATIO")
print("-" * 70)
print()
print(f"{'Price':>12} | {'Ratio':>10} | {'Status':>20}")
print("-" * 50)

prices = [50000, 75000, 90000, 97000, 100000, 110000, 125000, 150000, 200000]
for price in prices:
    ratio = SATS_PER_BTC / (price * 250)
    if abs(ratio - 4) < 0.001:
        status = "⚖️  EQUILIBRIUM"
    elif ratio > 4:
        status = "📈 Sats > 4×QV"
    else:
        status = "📉 Sats < 4×QV"
    print(f"${price:>11,} | {ratio:>10.4f} | {status}")

print()

# =============================================================================
# PART 7: The Quantum Unit Table (First 20)
# =============================================================================
print("PART 7: QUANTUM UNIT TABLE")
print("-" * 70)
print()
print(f"{'Quanta':>8} | {'Satoshis':>15} | {'BTC':>15} | {'USD @$100k':>15}")
print("-" * 60)

for q in [1, 2, 4, 5, 8, 10, 16, 20, 25, 40, 50, 100, 200, 400, 1000, 10000, 100000, 1000000]:
    sats = q * QUANTUM
    btc = sats / SATS_PER_BTC
    usd = btc * EQUILIBRIUM_PRICE
    print(f"{q:>8,} | {sats:>15,} | {btc:>15.8f} | ${usd:>14,.2f}")

print()

# =============================================================================
# PART 8: The Trinity of Constants
# =============================================================================
print("PART 8: THE TRINITY OF CONSTANTS")
print("-" * 70)
print()
print("Three fundamental constants define the Bitcoin quantum system:")
print()
print(f"  QUANTUM (5²)     = {QUANTUM:>15,}")
print(f"  BRIDGE  (2²)     = {BRIDGE:>15,.0f}")
print(f"  SATOSHI (10⁸)    = {SATS_PER_BTC:>15,}")
print()
print("Their relationships:")
print(f"  SATOSHI / QUANTUM = {SATS_PER_BTC // QUANTUM:,} = 4 × 10^6")
print(f"  SATOSHI / BRIDGE  = {SATS_PER_BTC // int(BRIDGE):,} = 25 × 10^6")
print(f"  BRIDGE × QUANTUM  = {int(BRIDGE) * QUANTUM} = 100 = 10²")
print()

# =============================================================================
# PART 9: 21 Million in Quantum Terms
# =============================================================================
print("PART 9: 21 MILLION BTC IN QUANTUM")
print("-" * 70)
print()

TOTAL_BTC = 21_000_000
total_sats = TOTAL_BTC * SATS_PER_BTC
total_quanta = total_sats // QUANTUM

print(f"Total BTC supply: {TOTAL_BTC:,}")
print(f"Total satoshis:   {total_sats:,}")
print(f"Total quanta:     {total_quanta:,}")
print()
print("Factor analysis of 21,000,000:")
print(f"  21,000,000 = 21 × 10^6")
print(f"            = 3 × 7 × 10^6")
print(f"            = 3 × 7 × 2^6 × 5^6")
print()
print(f"In satoshis: {total_sats:,}")
print(f"           = 21 × 10^14")
print(f"           = 2.1 × 10^15")
print()
print(f"In quanta:   {total_quanta:,}")
print(f"           = {total_quanta / 10**13:.1f} × 10^13")
print()

# =============================================================================
# PART 10: The Golden Insight
# =============================================================================
print("PART 10: THE GOLDEN INSIGHT")
print("-" * 70)
print()
print("At $100,000 per BTC:")
print()
print("  1 satoshi = $0.001 = 1/1000 dollar")
print("  1 quantum = 25 satoshis = $0.025 = 1/40 dollar")
print("  1 BTC = $100,000 = 4,000,000 quanta")
print()
print("The quantum creates a natural 'cent' equivalent:")
print(f"  40 quanta = $1.00")
print(f"  4 quanta = $0.10 (dime)")
print(f"  1 quantum = $0.025 (quarter of a dime)")
print()
print("=" * 70)
print("END OF FRAMEWORK")
print("=" * 70)

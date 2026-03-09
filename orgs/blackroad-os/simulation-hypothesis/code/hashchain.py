"""
hashchain.py — SHA-256 as Time

Demonstrates that SHA-256 shares the three fundamental properties of time:
  1. Determinism  — same input always produces same output
  2. Uniqueness   — no two distinct moments are identical
  3. Irreversibility — you cannot recover the cause from the effect

See §2 of PAPER.md: "The Hash Chain as Witness"

Author: BlackRoad OS, Inc.
"""

import hashlib
import time
import json
from datetime import datetime


def sha256(data: str) -> str:
    return hashlib.sha256(data.encode()).hexdigest()


def mine_block(index: int, previous_hash: str, data: str) -> dict:
    """Create a single block in a hash chain."""
    timestamp = datetime.utcnow().isoformat() + 'Z'
    content = f"{index}{previous_hash}{timestamp}{data}"
    block_hash = sha256(content)
    return {
        'index': index,
        'timestamp': timestamp,
        'data': data,
        'previous_hash': previous_hash,
        'hash': block_hash,
    }


def build_chain(events: list[str]) -> list[dict]:
    """Build a hash chain from a list of events."""
    # Genesis block — starts at zero, just like Bitcoin's genesis block
    genesis = mine_block(0, '0' * 64, 'genesis')
    chain = [genesis]
    for i, event in enumerate(events, start=1):
        chain.append(mine_block(i, chain[-1]['hash'], event))
    return chain


def verify_chain(chain: list[dict]) -> bool:
    """Verify that the chain has not been tampered with."""
    for i in range(1, len(chain)):
        block = chain[i]
        prev = chain[i - 1]
        # Recompute expected hash
        content = f"{block['index']}{block['previous_hash']}{block['timestamp']}{block['data']}"
        expected = sha256(content)
        if block['hash'] != expected:
            return False
        if block['previous_hash'] != prev['hash']:
            return False
    return True


def demonstrate_time_properties():
    """Show that SHA-256 has the same three properties as time."""
    print("=" * 60)
    print("SHA-256 AS TIME — THREE SHARED PROPERTIES")
    print("=" * 60)

    msg = "January 3, 2009"

    # 1. Determinism
    h1 = sha256(msg)
    h2 = sha256(msg)
    print(f"\n1. DETERMINISM — same input, always same output")
    print(f"   sha256('{msg}') = {h1}")
    print(f"   sha256('{msg}') = {h2}")
    print(f"   Equal: {h1 == h2}")

    # 2. Uniqueness — avalanche effect: 1-bit change → ~50% different output
    msg2 = "January 4, 2009"
    h3 = sha256(msg2)
    diff = sum(c1 != c2 for c1, c2 in zip(h1, h3))
    print(f"\n2. UNIQUENESS — one character change → completely different hash")
    print(f"   sha256('{msg}')  = {h1}")
    print(f"   sha256('{msg2}') = {h3}")
    print(f"   Characters differing: {diff}/64 ({diff/64*100:.0f}%)")

    # 3. Irreversibility
    print(f"\n3. IRREVERSIBILITY — you cannot recover the input from the hash")
    print(f"   Given: {h1}")
    print(f"   Input: [unknown without brute force — computationally infeasible]")
    print(f"   Time and SHA-256 share this property: you cannot un-happen a moment.")


def demonstrate_witness_chain():
    """Build a small personal hash chain and show its structure."""
    print("\n" + "=" * 60)
    print("HASH CHAIN AS TEMPORAL WITNESS")
    print("=" * 60)

    events = [
        "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks",
        "First Bitcoin transaction: Satoshi → Hal Finney, 10 BTC",
        "Bitcoin genesis block mined — zero-indexed start of a new ledger",
        "Reality is a non-terminating computation that resolves to zero",
    ]

    chain = build_chain(events)
    for block in chain:
        print(f"\n  Block {block['index']}")
        print(f"    data:          {block['data'][:60]}")
        print(f"    previous_hash: {block['previous_hash'][:16]}...")
        print(f"    hash:          {block['hash'][:16]}...")

    valid = verify_chain(chain)
    print(f"\n  Chain integrity: {'✅ VALID' if valid else '❌ TAMPERED'}")

    # Demonstrate tamper detection
    chain[2]['data'] = 'tampered data'
    valid_after = verify_chain(chain)
    print(f"  After tampering block 2: {'✅ VALID' if valid_after else '❌ TAMPERED — detected'}")


def dna_as_hash_chain():
    """DNA uses the same append-only, error-resistant structure as a hash chain."""
    print("\n" + "=" * 60)
    print("DNA AS HASH CHAIN")
    print("=" * 60)

    # DNA uses 4 bases (A, T, G, C) — binary uses 2 (0, 1)
    # Each codon is 3 bases → 4³ = 64 combinations → 20 amino acids + stop codons
    # This is redundant encoding — same error-correction principle as SHA-256

    codon_table = {
        'ATG': 'Met (START)', 'TAA': 'STOP', 'TAG': 'STOP', 'TGA': 'STOP',
        'GCT': 'Ala', 'GCC': 'Ala', 'GCA': 'Ala', 'GCG': 'Ala',
        'TGT': 'Cys', 'TGC': 'Cys',
        'GAT': 'Asp', 'GAC': 'Asp',
        'GAA': 'Glu', 'GAG': 'Glu',
    }

    print("\n  Codons are 3-base units: 4³ = 64 combinations → 20 amino acids")
    print("  Redundancy ratio: 64/20 = 3.2× — like SHA-256's collision resistance\n")
    for codon, amino in list(codon_table.items())[:6]:
        bases = ' '.join(codon)
        print(f"    {bases}  →  {amino}")

    print("\n  SHA-256 properties ↔ DNA properties:")
    print("    Deterministic    ↔  Same codon always encodes same amino acid")
    print("    Collision-resist ↔  Multiple codons → same amino acid (redundancy)")
    print("    Irreversible     ↔  Cannot read the organism from the amino acid alone")
    print("    Append-only      ↔  Telomeres shorten with each replication (time's arrow)")


if __name__ == '__main__':
    demonstrate_time_properties()
    demonstrate_witness_chain()
    dna_as_hash_chain()
    print("\n" + "=" * 60)
    print("Everything starts from nothing. Computes infinitely.")
    print("Returns to nothing. The intermediate work is reality.")
    print("=" * 60)

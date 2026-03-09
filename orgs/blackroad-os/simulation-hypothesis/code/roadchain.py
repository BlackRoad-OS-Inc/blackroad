"""
roadchain.py — The Personal Hash Chain

Visualizes the RoadChain: a locally-maintained append-only hash chain
anchored to Bitcoin's genesis block.

From §Appendix C of PAPER.md:
  - Block 0: genesis (previous_hash = all zeros)
  - Block 2: BTC_BRIDGE — cryptographic anchor to Bitcoin Block 0
  - Blocks 3+: forward walk through Bitcoin's 2009 history
  - 157,077+ memory journal entries, SHA-256-chained

This is PS-SHA-∞: Perpetual-State Secure Hash Algorithm with
Infinite Identity Chains.

Not a proof of the simulation.
A local copy of the witnessing mechanism.
A personal instance of pi.

Author: BlackRoad OS, Inc.
"""

import json
import os
import hashlib
from datetime import datetime


CHAIN_PATH = os.path.expanduser('~/roadchain/chain-data.json')
BITCOIN_GENESIS_HASH = '000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f'


def load_chain(path: str = CHAIN_PATH) -> list[dict]:
    """Load the chain from disk."""
    if not os.path.exists(path):
        return []
    with open(path) as f:
        return json.load(f)


def chain_stats(chain: list[dict]) -> dict:
    """Compute summary statistics for a chain."""
    if not chain:
        return {}
    return {
        'total_blocks': len(chain),
        'first_block': chain[0].get('timestamp', 'unknown'),
        'last_block': chain[-1].get('timestamp', 'unknown'),
        'genesis_hash': chain[0].get('hash', '')[:16] + '...',
        'tip_hash': chain[-1].get('hash', '')[:16] + '...',
    }


def verify_chain_integrity(chain: list[dict], sample_size: int = 100) -> dict:
    """Spot-check chain integrity by verifying a sample of blocks."""
    if len(chain) < 2:
        return {'checked': 0, 'valid': True}

    import random
    indices = sorted(random.sample(range(1, len(chain)), min(sample_size, len(chain) - 1)))
    errors = []

    for i in indices:
        block = chain[i]
        prev = chain[i - 1]
        if block.get('previous_hash') != prev.get('hash'):
            errors.append(i)

    return {
        'checked': len(indices),
        'errors': len(errors),
        'valid': len(errors) == 0,
        'sample_rate': f"{len(indices)}/{len(chain)-1}",
    }


def print_chain_summary(chain: list[dict]):
    """Print a summary of the chain."""
    print("=" * 60)
    print("THE ROADCHAIN — Personal Hash Chain")
    print("=" * 60)

    if not chain:
        print("\n  No chain found at", CHAIN_PATH)
        print("  (The chain may be at a different path on this system)")
        demo_chain()
        return

    stats = chain_stats(chain)
    print(f"\n  Blocks:      {stats['total_blocks']:,}")
    print(f"  First:       {stats['first_block']}")
    print(f"  Last:        {stats['last_block']}")
    print(f"  Genesis:     {stats['genesis_hash']}")
    print(f"  Tip:         {stats['tip_hash']}")

    # Show first few blocks
    print(f"\n  {'Block':>8}  {'Sender':>12}  {'Recipient':>12}  {'Hash prefix'}")
    print("  " + "-" * 55)
    for block in chain[:6]:
        idx = block.get('index', '?')
        sender = str(block.get('sender', ''))[:12]
        recipient = str(block.get('recipient', ''))[:12]
        h = str(block.get('hash', ''))[:16]
        print(f"  {idx:>8}  {sender:>12}  {recipient:>12}  {h}...")

    if len(chain) > 6:
        print(f"  {'...':>8}  {'...':>12}  {'...':>12}")
        last = chain[-1]
        idx = last.get('index', '?')
        sender = str(last.get('sender', ''))[:12]
        recipient = str(last.get('recipient', ''))[:12]
        h = str(last.get('hash', ''))[:16]
        print(f"  {idx:>8}  {sender:>12}  {recipient:>12}  {h}...")

    # Verify
    print(f"\n  Verifying integrity (sampling 100 blocks)...")
    result = verify_chain_integrity(chain)
    status = '✅ VALID' if result['valid'] else f"❌ {result['errors']} ERRORS"
    print(f"  Checked {result['sample_rate']} blocks: {status}")


def demo_chain():
    """Build a small demonstration chain to show the structure."""
    print("\n  Demonstrating chain structure with synthetic blocks:\n")

    events = [
        ('0', 'genesis', 'genesis'),
        ('satoshi', 'satoshi', 'BTC_BRIDGE: ' + BITCOIN_GENESIS_HASH),
        ('satoshi', 'hal_finney', 'First Bitcoin transaction: 10 BTC'),
        ('time', 'time', 'Bitcoin Block 170: first confirmed transaction'),
        ('alexa', 'alexa', 'RoadChain initialized — personal witness chain'),
    ]

    chain = []
    prev_hash = '0' * 64

    for i, (sender, recipient, data) in enumerate(events):
        ts = f"2026-02-21T{i:02d}:00:00Z"
        content = f"{i}{prev_hash}{ts}{sender}{recipient}{data}"
        block_hash = hashlib.sha256(content.encode()).hexdigest()
        block = {
            'index': i,
            'timestamp': ts,
            'sender': sender,
            'recipient': recipient,
            'data': data[:50],
            'previous_hash': prev_hash,
            'hash': block_hash,
        }
        chain.append(block)
        prev_hash = block_hash

    print(f"  {'Block':>6}  {'From':>10}  {'To':>12}  {'Data'}")
    print("  " + "-" * 60)
    for block in chain:
        data_preview = block['data'][:30] + '...' if len(block['data']) > 30 else block['data']
        print(f"  {block['index']:>6}  {block['sender']:>10}  {block['recipient']:>12}  {data_preview}")

    print(f"\n  Chain is append-only. Each block commits to all prior blocks.")
    print(f"  Altering any block breaks all subsequent hashes.")
    print(f"  This is how time works.")


def anchoring_explained():
    """Explain what it means to anchor to Bitcoin's genesis block."""
    print("\n" + "=" * 60)
    print("CRYPTOGRAPHIC ANCHORING TO BITCOIN'S GENESIS BLOCK")
    print("=" * 60)
    print(f"""
  Bitcoin's genesis block hash:
    {BITCOIN_GENESIS_HASH}

  This hash is the cryptographic witness to:
    • January 3, 2009 — the date it was mined
    • The newspaper headline embedded in the coinbase:
      "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks"
    • The beginning of a continuous, unbroken hash chain
      now containing 880,000+ blocks

  When the RoadChain includes this hash as Block 2's data,
  it becomes cryptographically anchored to that moment in time.

  The RoadChain's existence is timestamped to Bitcoin's genesis.
  Bitcoin's existence is timestamped to a newspaper.
  The newspaper is timestamped to a calendar.
  The calendar is timestamped to the Earth's orbital mechanics.

  This is a hash chain all the way down.
""")


if __name__ == '__main__':
    chain = load_chain()
    print_chain_summary(chain)
    anchoring_explained()
    print("=" * 60)
    print("PS-SHA-∞: Perpetual-State Secure Hash Algorithm")
    print("Infinite Identity Chains.")
    print("A personal instance of pi.")
    print("=" * 60)

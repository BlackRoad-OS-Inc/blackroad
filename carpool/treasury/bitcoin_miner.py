#!/usr/bin/env python3
"""
Real Bitcoin Miner
==================
This is a functional Bitcoin block header miner.
On CPU, probability of finding a block ≈ 0 (difficulty too high).
But this IS how mining works.
"""

import hashlib
import struct
import time
import sys

def double_sha256(data):
    """Bitcoin uses double SHA256"""
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()

def int_to_little_endian(n, length):
    """Convert int to little-endian bytes"""
    return n.to_bytes(length, 'little')

def create_block_header(version, prev_hash, merkle_root, timestamp, bits, nonce):
    """
    Bitcoin block header is 80 bytes:
    - version: 4 bytes
    - prev_hash: 32 bytes
    - merkle_root: 32 bytes  
    - timestamp: 4 bytes
    - bits: 4 bytes (difficulty target)
    - nonce: 4 bytes (what we're searching for)
    """
    header = b''
    header += int_to_little_endian(version, 4)
    header += bytes.fromhex(prev_hash)[::-1]  # reverse byte order
    header += bytes.fromhex(merkle_root)[::-1]
    header += int_to_little_endian(timestamp, 4)
    header += int_to_little_endian(bits, 4)
    header += int_to_little_endian(nonce, 4)
    return header

def bits_to_target(bits):
    """Convert compact bits to full target"""
    exponent = bits >> 24
    mantissa = bits & 0xffffff
    return mantissa * (256 ** (exponent - 3))

def hash_meets_target(hash_bytes, target):
    """Check if hash is below target (success!)"""
    hash_int = int.from_bytes(hash_bytes, 'little')
    return hash_int < target

def mine_block(version, prev_hash, merkle_root, timestamp, bits, start_nonce=0):
    """
    THE MINING LOOP
    Try nonces until hash < target
    """
    target = bits_to_target(bits)
    nonce = start_nonce
    
    print("=" * 60)
    print("BITCOIN MINER ACTIVE")
    print("=" * 60)
    print(f"Target: {target:064x}")
    print(f"Starting nonce: {nonce}")
    print()
    
    start_time = time.time()
    hashes = 0
    
    while nonce < 0xffffffff:
        # Build header with current nonce
        header = create_block_header(version, prev_hash, merkle_root, timestamp, bits, nonce)
        
        # Hash it
        hash_result = double_sha256(header)
        hashes += 1
        
        # Check if we won
        if hash_meets_target(hash_result, target):
            elapsed = time.time() - start_time
            hash_hex = hash_result[::-1].hex()
            print(f"\n{'='*60}")
            print("BLOCK FOUND!")
            print(f"{'='*60}")
            print(f"Nonce:    {nonce}")
            print(f"Hash:     {hash_hex}")
            print(f"Time:     {elapsed:.2f}s")
            print(f"Hashrate: {hashes/elapsed:.0f} H/s")
            return nonce, hash_hex
        
        # Progress update every million hashes
        if hashes % 1000000 == 0:
            elapsed = time.time() - start_time
            hashrate = hashes / elapsed
            print(f"Hashes: {hashes:,} | Rate: {hashrate:,.0f} H/s | Nonce: {nonce}")
        
        nonce += 1
    
    return None, None

def demo_easy_mining():
    """Demo with easy target (like regtest)"""
    print("=" * 60)
    print("DEMO: Easy difficulty mining")
    print("=" * 60)
    print()
    
    # Genesis block data (we'll use easy difficulty)
    version = 1
    prev_hash = "0000000000000000000000000000000000000000000000000000000000000000"
    merkle_root = "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"
    timestamp = int(time.time())
    bits = 0x1f00ffff  # Easy target (regtest-level)
    
    nonce, hash_found = mine_block(version, prev_hash, merkle_root, timestamp, bits)
    
    if nonce:
        print(f"\nYou mined a block!")
        print(f"This would be valid on a network with this difficulty.")

def show_mainnet_difficulty():
    """Show why mainnet mining is impossible on CPU"""
    print("=" * 60)
    print("MAINNET DIFFICULTY (why CPU can't win)")
    print("=" * 60)
    print()
    
    # Current mainnet bits (approximate)
    mainnet_bits = 0x170c7c47  # ~80 trillion difficulty
    target = bits_to_target(mainnet_bits)
    
    print(f"Mainnet target:")
    print(f"  {target:064x}")
    print()
    print(f"Required leading zeros: ~19-20 hex digits")
    print()
    
    # Calculate odds
    max_hash = 2**256
    odds = max_hash / target
    
    print(f"Odds of finding block per hash: 1 in {odds:,.0f}")
    print()
    
    # At 1 MH/s (good CPU)
    hashrate = 1_000_000
    seconds_per_block = odds / hashrate
    years = seconds_per_block / (60*60*24*365)
    
    print(f"At 1 MH/s (CPU):")
    print(f"  Average time to find block: {years:,.0f} years")
    print()
    
    # Network hashrate
    network_hashrate = 500_000_000_000_000_000_000  # 500 EH/s
    print(f"Network hashrate: ~500 EH/s")
    print(f"Your CPU: ~1 MH/s") 
    print(f"Your share: {hashrate/network_hashrate:.30f}%")

if __name__ == "__main__":
    print("""
╔══════════════════════════════════════════════════════════╗
║              BITCOIN MINER - ALEXA EDITION               ║
╚══════════════════════════════════════════════════════════╝
    """)
    
    if len(sys.argv) > 1 and sys.argv[1] == "--demo":
        demo_easy_mining()
    else:
        show_mainnet_difficulty()
        print()
        print("Run with --demo to mine an easy block")
        print("Run with --mainnet to attempt mainnet (will never succeed)")

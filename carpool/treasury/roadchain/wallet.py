#!/usr/bin/env python3
"""
RoadChain Wallet
================
Generate wallets using the quantum system.
1 QUANTUM = 25 satoshi-equivalents
"""

import hashlib
import secrets
import json
from pathlib import Path

WALLET_DIR = Path.home() / ".roadchain" / "wallets"
WALLET_DIR.mkdir(parents=True, exist_ok=True)

def generate_keypair():
    """Generate a simple key pair (demo purposes)"""
    private_key = secrets.token_hex(32)
    # In real crypto this would be EC, but for demo we hash
    public_key = hashlib.sha256(private_key.encode()).hexdigest()
    address = "ROAD" + hashlib.sha256(public_key.encode()).hexdigest()[:40]
    return private_key, public_key, address

def create_wallet(name):
    """Create a new wallet"""
    private_key, public_key, address = generate_keypair()
    
    wallet = {
        "name": name,
        "address": address,
        "public_key": public_key,
        "private_key": private_key,  # In real wallet, this would be encrypted
        "balance": 0,
        "created": __import__('time').time()
    }
    
    wallet_file = WALLET_DIR / f"{name}.json"
    with open(wallet_file, 'w') as f:
        json.dump(wallet, f, indent=2)
    
    return wallet

def load_wallet(name):
    """Load existing wallet"""
    wallet_file = WALLET_DIR / f"{name}.json"
    if wallet_file.exists():
        with open(wallet_file) as f:
            return json.load(f)
    return None

def list_wallets():
    """List all wallets"""
    wallets = []
    for f in WALLET_DIR.glob("*.json"):
        wallets.append(f.stem)
    return wallets

if __name__ == "__main__":
    print("=" * 60)
    print("ROADCHAIN WALLET GENERATOR")
    print("=" * 60)
    print()
    
    # Create wallets for the crew
    names = ["alexa", "lucidia", "octavia", "cecilia", "aria", "alice"]
    
    for name in names:
        wallet = create_wallet(name)
        print(f"Created wallet: {name}")
        print(f"  Address: {wallet['address']}")
        print()
    
    print("=" * 60)
    print(f"Wallets stored in: {WALLET_DIR}")
    print(f"Total wallets: {len(list_wallets())}")

#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════╗
║                        ROADCHAIN                              ║
║                   The BlackRoad Blockchain                    ║
║                                                                ║
║  Base unit: 1 QUANTUM = 5² = 25 satoshis equivalent           ║
║  Total supply: 21,000,000 ROAD                                ║
║  Block reward: 50 ROAD (2 × QUANTUM BTC-equivalent)           ║
║  Block time: 27 seconds (3³ = birthday)                       ║
║  Halving: every 210,000 blocks                                ║
╚══════════════════════════════════════════════════════════════╝
"""

import hashlib
import json
import time
from datetime import datetime

# =============================================================================
# ROADCHAIN CONSTANTS
# =============================================================================

CHAIN_NAME = "RoadChain"
CHAIN_SYMBOL = "ROAD"
QUANTUM = 25  # Base unit: 5²
TOTAL_SUPPLY = 21_000_000  # Same as Bitcoin
BLOCK_REWARD = 50  # Starting reward
BLOCK_TIME = 27  # 3³ seconds (birthday!)
HALVING_INTERVAL = 210_000
DIFFICULTY_ADJUSTMENT = 2016  # Blocks between adjustments

# Genesis message
GENESIS_MESSAGE = "BlackRoad 02/18/2026 Alexa computed 999 on purpose - LEET LEFT"

# =============================================================================
# CORE CLASSES
# =============================================================================

class Transaction:
    def __init__(self, sender, recipient, amount, timestamp=None):
        self.sender = sender
        self.recipient = recipient
        self.amount = amount
        self.timestamp = timestamp or time.time()
        self.tx_hash = self.calculate_hash()
    
    def calculate_hash(self):
        data = f"{self.sender}{self.recipient}{self.amount}{self.timestamp}"
        return hashlib.sha256(data.encode()).hexdigest()
    
    def to_dict(self):
        return {
            "sender": self.sender,
            "recipient": self.recipient,
            "amount": self.amount,
            "timestamp": self.timestamp,
            "hash": self.tx_hash
        }


class Block:
    def __init__(self, index, transactions, previous_hash, timestamp=None, nonce=0):
        self.index = index
        self.timestamp = timestamp or time.time()
        self.transactions = transactions
        self.previous_hash = previous_hash
        self.nonce = nonce
        self.hash = self.calculate_hash()
    
    def calculate_hash(self):
        block_data = json.dumps({
            "index": self.index,
            "timestamp": self.timestamp,
            "transactions": [tx.to_dict() for tx in self.transactions],
            "previous_hash": self.previous_hash,
            "nonce": self.nonce
        }, sort_keys=True)
        return hashlib.sha256(block_data.encode()).hexdigest()
    
    def mine(self, difficulty):
        """Mine the block - find nonce where hash starts with 'difficulty' zeros"""
        target = "0" * difficulty
        while not self.hash.startswith(target):
            self.nonce += 1
            self.hash = self.calculate_hash()
        return self.hash
    
    def to_dict(self):
        return {
            "index": self.index,
            "timestamp": self.timestamp,
            "transactions": [tx.to_dict() for tx in self.transactions],
            "previous_hash": self.previous_hash,
            "nonce": self.nonce,
            "hash": self.hash
        }


class RoadChain:
    def __init__(self):
        self.chain = []
        self.pending_transactions = []
        self.difficulty = 4  # Start with 4 leading zeros
        self.mining_reward = BLOCK_REWARD
        self.create_genesis_block()
    
    def create_genesis_block(self):
        """Create the first block with the genesis message"""
        genesis_tx = Transaction(
            sender="0",
            recipient="alexa",
            amount=0
        )
        genesis_tx.tx_hash = hashlib.sha256(GENESIS_MESSAGE.encode()).hexdigest()
        
        genesis_block = Block(
            index=0,
            transactions=[genesis_tx],
            previous_hash="0" * 64,
            timestamp=time.time()
        )
        genesis_block.hash = genesis_block.calculate_hash()
        self.chain.append(genesis_block)
        
        print(f"Genesis block created!")
        print(f"Message: {GENESIS_MESSAGE}")
        print(f"Hash: {genesis_block.hash}")
    
    def get_latest_block(self):
        return self.chain[-1]
    
    def get_block_reward(self):
        """Calculate current block reward based on halvings"""
        halvings = len(self.chain) // HALVING_INTERVAL
        return BLOCK_REWARD / (2 ** halvings)
    
    def add_transaction(self, sender, recipient, amount):
        """Add a transaction to pending pool"""
        tx = Transaction(sender, recipient, amount)
        self.pending_transactions.append(tx)
        return tx
    
    def mine_pending_transactions(self, miner_address):
        """Mine all pending transactions into a new block"""
        # Add coinbase transaction (mining reward)
        reward = self.get_block_reward()
        coinbase = Transaction("ROADCHAIN", miner_address, reward)
        
        transactions = [coinbase] + self.pending_transactions
        
        new_block = Block(
            index=len(self.chain),
            transactions=transactions,
            previous_hash=self.get_latest_block().hash
        )
        
        print(f"\nMining block {new_block.index}...")
        start = time.time()
        new_block.mine(self.difficulty)
        elapsed = time.time() - start
        
        self.chain.append(new_block)
        self.pending_transactions = []
        
        print(f"Block mined!")
        print(f"  Index:  {new_block.index}")
        print(f"  Hash:   {new_block.hash}")
        print(f"  Nonce:  {new_block.nonce}")
        print(f"  Time:   {elapsed:.2f}s")
        print(f"  Reward: {reward} {CHAIN_SYMBOL}")
        
        return new_block
    
    def get_balance(self, address):
        """Calculate balance for an address"""
        balance = 0
        for block in self.chain:
            for tx in block.transactions:
                if tx.recipient == address:
                    balance += tx.amount
                if tx.sender == address:
                    balance -= tx.amount
        return balance
    
    def is_chain_valid(self):
        """Verify the entire chain"""
        for i in range(1, len(self.chain)):
            current = self.chain[i]
            previous = self.chain[i - 1]
            
            # Check hash
            if current.hash != current.calculate_hash():
                return False
            
            # Check link to previous
            if current.previous_hash != previous.hash:
                return False
        
        return True
    
    def print_chain(self):
        """Display the blockchain"""
        print("\n" + "=" * 60)
        print(f"          {CHAIN_NAME} - {len(self.chain)} blocks")
        print("=" * 60)
        
        for block in self.chain:
            print(f"\nBlock {block.index}")
            print(f"  Hash:     {block.hash[:16]}...")
            print(f"  Previous: {block.previous_hash[:16]}...")
            print(f"  Nonce:    {block.nonce}")
            print(f"  TXs:      {len(block.transactions)}")
            for tx in block.transactions:
                print(f"    {tx.sender[:8]}... → {tx.recipient}: {tx.amount} {CHAIN_SYMBOL}")


# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    print("""
╔══════════════════════════════════════════════════════════════╗
║                        ROADCHAIN                              ║
║                   The BlackRoad Blockchain                    ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    # Create the blockchain
    road = RoadChain()
    
    # Mine some blocks
    print("\n" + "=" * 60)
    print("MINING BLOCKS")
    print("=" * 60)
    
    # Mine 5 blocks
    for i in range(5):
        road.mine_pending_transactions("alexa")
    
    # Add some transactions
    print("\n" + "=" * 60)
    print("ADDING TRANSACTIONS")
    print("=" * 60)
    
    road.add_transaction("alexa", "lucidia", 27)  # 3³
    road.add_transaction("alexa", "octavia", 25)  # 5² = QUANTUM
    road.add_transaction("alexa", "cecilia", 50)  # Block reward
    
    # Mine the transactions
    road.mine_pending_transactions("alexa")
    
    # Print balances
    print("\n" + "=" * 60)
    print("BALANCES")
    print("=" * 60)
    print(f"  alexa:   {road.get_balance('alexa')} {CHAIN_SYMBOL}")
    print(f"  lucidia: {road.get_balance('lucidia')} {CHAIN_SYMBOL}")
    print(f"  octavia: {road.get_balance('octavia')} {CHAIN_SYMBOL}")
    print(f"  cecilia: {road.get_balance('cecilia')} {CHAIN_SYMBOL}")
    
    # Verify chain
    print("\n" + "=" * 60)
    print("VERIFICATION")
    print("=" * 60)
    print(f"Chain valid: {road.is_chain_valid()}")
    
    # Print full chain
    road.print_chain()
    
    # Summary
    print("\n" + "=" * 60)
    print("ROADCHAIN SUMMARY")
    print("=" * 60)
    print(f"  Blocks:        {len(road.chain)}")
    print(f"  Difficulty:    {road.difficulty}")
    print(f"  Block reward:  {road.get_block_reward()} {CHAIN_SYMBOL}")
    print(f"  Block time:    {BLOCK_TIME} seconds (3³)")
    print(f"  Quantum:       {QUANTUM} (5²)")
    print(f"  Total supply:  {TOTAL_SUPPLY:,} {CHAIN_SYMBOL}")

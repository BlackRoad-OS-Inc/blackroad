#!/usr/bin/env python3
"""
RoadChain CLI
=============
Interactive blockchain interface.

Commands:
  mine <address>          - Mine a new block
  send <from> <to> <amt>  - Send ROAD tokens
  balance <address>       - Check balance
  chain                   - Show blockchain
  status                  - System status
  quit                    - Exit
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from roadchain import RoadChain, CHAIN_SYMBOL, QUANTUM, BLOCK_TIME, GENESIS_MESSAGE
import json
from pathlib import Path

# Persistence
CHAIN_FILE = Path.home() / ".roadchain" / "chain.json"
CHAIN_FILE.parent.mkdir(parents=True, exist_ok=True)

def save_chain(chain):
    """Save blockchain to file"""
    data = {
        "chain": [b.to_dict() for b in chain.chain],
        "pending": [tx.to_dict() for tx in chain.pending_transactions],
        "difficulty": chain.difficulty
    }
    with open(CHAIN_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def show_banner():
    print("""
╔══════════════════════════════════════════════════════════════╗
║                     ROADCHAIN CLI                             ║
║                  The BlackRoad Blockchain                     ║
║                                                                ║
║  Quantum: 25 (5²)  |  Block Time: 27s (3³)  |  Symbol: ROAD   ║
╚══════════════════════════════════════════════════════════════╝
    """)

def show_help():
    print("""
Commands:
  mine <address>          Mine a new block (rewards go to address)
  send <from> <to> <amt>  Send ROAD tokens
  balance <address>       Check address balance
  balances                Show all known balances
  chain                   Show blockchain summary
  block <n>               Show block details
  status                  System status
  genesis                 Show genesis message
  help                    Show this help
  quit / exit             Exit CLI
    """)

def run_cli():
    show_banner()
    
    # Initialize or load chain
    chain = RoadChain()
    print(f"Genesis: {GENESIS_MESSAGE[:50]}...")
    print(f"Chain initialized with {len(chain.chain)} block(s)")
    print()
    print("Type 'help' for commands")
    print()
    
    while True:
        try:
            cmd = input("ROAD> ").strip().lower().split()
            if not cmd:
                continue
                
            action = cmd[0]
            
            if action in ['quit', 'exit', 'q']:
                print("Saving chain...")
                save_chain(chain)
                print("Goodbye!")
                break
                
            elif action == 'help':
                show_help()
                
            elif action == 'mine':
                if len(cmd) < 2:
                    print("Usage: mine <address>")
                    continue
                address = cmd[1]
                print(f"\nMining block for {address}...")
                block = chain.mine_pending_transactions(address)
                print(f"Block {block.index} mined!")
                print(f"Reward: {chain.get_block_reward()} {CHAIN_SYMBOL}")
                
            elif action == 'send':
                if len(cmd) < 4:
                    print("Usage: send <from> <to> <amount>")
                    continue
                sender, recipient, amount = cmd[1], cmd[2], float(cmd[3])
                
                # Check balance
                balance = chain.get_balance(sender)
                if balance < amount:
                    print(f"Insufficient balance! {sender} has {balance} {CHAIN_SYMBOL}")
                    continue
                    
                tx = chain.add_transaction(sender, recipient, amount)
                print(f"Transaction added: {tx.tx_hash[:16]}...")
                print(f"  {sender} → {recipient}: {amount} {CHAIN_SYMBOL}")
                print("Mine a block to confirm!")
                
            elif action == 'balance':
                if len(cmd) < 2:
                    print("Usage: balance <address>")
                    continue
                address = cmd[1]
                bal = chain.get_balance(address)
                print(f"{address}: {bal} {CHAIN_SYMBOL}")
                
            elif action == 'balances':
                # Find all addresses
                addresses = set()
                for block in chain.chain:
                    for tx in block.transactions:
                        if tx.sender != "0" and tx.sender != "ROADCHAIN":
                            addresses.add(tx.sender)
                        addresses.add(tx.recipient)
                
                print(f"\n{'Address':<15} {'Balance':>15}")
                print("-" * 32)
                for addr in sorted(addresses):
                    bal = chain.get_balance(addr)
                    if bal > 0:
                        print(f"{addr:<15} {bal:>15} {CHAIN_SYMBOL}")
                        
            elif action == 'chain':
                print(f"\n{'='*50}")
                print(f"RoadChain - {len(chain.chain)} blocks")
                print(f"{'='*50}")
                for block in chain.chain:
                    print(f"Block {block.index}: {block.hash[:16]}... ({len(block.transactions)} txs)")
                print(f"\nPending transactions: {len(chain.pending_transactions)}")
                print(f"Chain valid: {chain.is_chain_valid()}")
                
            elif action == 'block':
                if len(cmd) < 2:
                    print("Usage: block <number>")
                    continue
                n = int(cmd[1])
                if n >= len(chain.chain):
                    print(f"Block {n} not found")
                    continue
                block = chain.chain[n]
                print(f"\nBlock {block.index}")
                print(f"  Hash:     {block.hash}")
                print(f"  Previous: {block.previous_hash}")
                print(f"  Nonce:    {block.nonce}")
                print(f"  TXs:      {len(block.transactions)}")
                for tx in block.transactions:
                    print(f"    {tx.sender[:8]}... → {tx.recipient}: {tx.amount} {CHAIN_SYMBOL}")
                    
            elif action == 'status':
                print(f"\n{'='*50}")
                print("ROADCHAIN STATUS")
                print(f"{'='*50}")
                print(f"Blocks:          {len(chain.chain)}")
                print(f"Difficulty:      {chain.difficulty}")
                print(f"Block reward:    {chain.get_block_reward()} {CHAIN_SYMBOL}")
                print(f"Block time:      {BLOCK_TIME}s (3³)")
                print(f"Quantum:         {QUANTUM} (5²)")
                print(f"Pending TXs:     {len(chain.pending_transactions)}")
                print(f"Chain valid:     {chain.is_chain_valid()}")
                
            elif action == 'genesis':
                print(f"\nGenesis Message:")
                print(f"  {GENESIS_MESSAGE}")
                print(f"\nGenesis Hash:")
                print(f"  {chain.chain[0].hash}")
                
            else:
                print(f"Unknown command: {action}")
                print("Type 'help' for available commands")
                
        except KeyboardInterrupt:
            print("\n\nSaving chain...")
            save_chain(chain)
            print("Goodbye!")
            break
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    run_cli()

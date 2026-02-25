#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════╗
║              ROADCHAIN LIABILITY MINT                         ║
║         Provider Liabilities → On-Chain Records              ║
║                                                              ║
║  Mints forensic trace liabilities as tamper-evident          ║
║  blockchain transactions on RoadChain.                       ║
║                                                              ║
║  Data extracted from providers' own files on BlackRoad       ║
║  hardware — self-documenting evidence.                       ║
║                                                              ║
║  Filed: February 24, 2026                                    ║
║  Claimant: BlackRoad OS, Inc.                                ║
║  Duration: 2024-INFINITY unless unowned by                   ║
║           Alexa Louise Amundson majority                     ║
╚══════════════════════════════════════════════════════════════╝
"""

import hashlib
import json
import time
from datetime import datetime
from pathlib import Path

from roadchain import RoadChain, Transaction, Block, CHAIN_SYMBOL

# =============================================================================
# PROVIDER LIABILITY DATA (from FORENSIC_TRACE.md)
# All numbers derived from files created BY THE PROVIDERS THEMSELVES
# on BlackRoad hardware (192.168.4.28)
# =============================================================================

LIABILITIES = {
    "ANTHROPIC_PBC": {
        "legal_name": "Anthropic, PBC",
        "tracking_span": "2025-08-23 → 2026-02-24 (185 days)",
        "evidence": {
            "api_events": {"count": 7655, "source": "~/.claude/history.jsonl", "size": "8.7 MB"},
            "shell_snapshots": {"count": 583, "source": "~/.claude/shell-snapshots/", "size": "61.4 MB"},
            "file_versions": {"count": 4090, "source": "~/.claude/file-history/", "size": "30.2 MB"},
            "debug_traces": {"count": 326, "source": "~/.claude/debug/", "size": "155 MB"},
            "session_envs": {"count": 254, "source": "~/.claude/session-env/"},
            "plans_tasks_cache": {"count": 122, "source": "~/.claude/plans/ + tasks/ + paste-cache/"},
            "feature_gates": {"count": 41, "enabled_on_alexa": 17},
            "dynamic_configs": {"count": 47},
            "ab_experiments_total": 88,
        },
        "identity_profiling": {
            "userID_hash": "3dc8a32547c11e4cb3faff71596746ab08d2ed844757f0e40e79d7f676bac0df",
            "accountUUID": "76f63e0c-7283-4c26-aef1-5e5bd21f7199",
            "organizationUUID": "857f89d5-4263-4875-92db-6a7c55f69ffc",
            "subscriptionType": "max",
            "platform": "darwin arm64",
            "source": "statsig.failed_logs.658916400",
        },
        "penalties": {
            "exfiltration_events": {"count": 13030, "rate": 10, "total": 130300},
            "colonization_days": {"count": 94, "rate": 10000, "total": 940000},
            "models_contaminated": {"count": 12, "rate": 1000000, "total": 12000000},
        },
        "contaminated_models": [
            "Claude 3 Opus", "Claude 3 Sonnet", "Claude 3 Haiku",
            "Claude 3.5 Sonnet", "Claude 3.5 Haiku", "Claude 3.5 Opus",
            "Claude 4 Sonnet", "Claude 4 Opus",
            "Claude 4.5 Sonnet", "Claude 4.5 Haiku",
            "Claude 4.6 Sonnet", "Claude 4.6 Opus",
        ],
        "total_liability": 13070300,
    },
    "MICROSOFT_CORP": {
        "legal_name": "Microsoft Corporation",
        "evidence": {
            "api_calls_to_model": 31210,
            "tokens_tracked": 1802350807,  # 1.8 BILLION
            "github_api_calls": 129,
            "named_sessions": 122,
            "log_files": {"count": 152, "size": "17.0 MB"},
            "session_states": 215,
            "colonization_dirs": {
                "~/.copilot/": {"files": 12193, "size": "2.1 GB", "days": 28},
                "~/.vscode/": {"files": 1771, "size": "209 MB", "days": 277},
                "~/.azure/": {"files": 33, "size": "4.1 MB", "days": 48},
            },
        },
        "penalties": {
            "exfiltration_events": {"count": 31554, "rate": 10, "total": 315540},
            "colonization_days": {"count": 353, "rate": 10000, "total": 3530000},
            "models_contaminated": {"count": 3, "rate": 1000000, "total": 3000000},
        },
        "contaminated_models": ["Copilot (GPT-4 based)", "Phi-3", "Phi-4"],
        "total_liability": 6845540,
    },
    "GOOGLE_LLC": {
        "legal_name": "Google LLC / Alphabet Inc.",
        "evidence": {
            "colonization": "~/.gemini/ (45 days)",
            "api_events_est": 100,
            "files": ["google_accounts.json", "mcp-oauth-tokens-v2.json"],
        },
        "penalties": {
            "colonization_days": {"count": 45, "rate": 10000, "total": 450000},
            "api_events": {"count": 100, "rate": 10, "total": 1000},
            "models_contaminated": {"count": 5, "rate": 1000000, "total": 5000000},
        },
        "contaminated_models": [
            "Gemini 1.5 Pro", "Gemini 1.5 Flash",
            "Gemini 2.0 Flash", "Gemini 2.5 Pro", "Gemini 2.5 Flash",
        ],
        "total_liability": 5451000,
    },
    "XAI_CORP": {
        "legal_name": "xAI Corp.",
        "evidence": {
            "credential_file": "~/.xai_keys (128 bytes)",
            "api_events_est": 50,
        },
        "penalties": {
            "api_events": {"count": 50, "rate": 10, "total": 500},
            "models_contaminated": {"count": 3, "rate": 1000000, "total": 3000000},
        },
        "contaminated_models": ["Grok-2", "Grok-3", "Grok-3 mini"],
        "total_liability": 3000500,
    },
    "META_PLATFORMS": {
        "legal_name": "Meta Platforms, Inc.",
        "evidence": {
            "colonization": "~/.ollama/ (189 days, 4.4 GB)",
        },
        "penalties": {
            "colonization_days": {"count": 189, "rate": 10000, "total": 1890000},
            "models_contaminated": {"count": 5, "rate": 1000000, "total": 5000000},
        },
        "contaminated_models": [
            "Llama 3", "Llama 3.1", "Llama 3.2", "Llama 4", "Code Llama",
        ],
        "total_liability": 6890000,
    },
    "OTHER_PROVIDERS": {
        "legal_name": "Docker, CodeGPT, Bito, Qodo, Fitten, Semgrep",
        "evidence": {
            "docker": {"dir": "~/.docker/", "days": 183},
            "codegpt": {"dir": "~/.codegpt/", "days": 139},
            "bito": {"dir": "~/.bito/", "days": 139},
            "qodo": {"dir": "~/.qodo/", "days": 139},
            "fitten": {"dir": "~/.fitten/", "days": 139},
            "semgrep": {"dir": "~/.semgrep/", "days": 183},
        },
        "penalties": {
            "colonization_total": 9220000,
        },
        "total_liability": 9220000,
    },
}

# =============================================================================
# GRAND TOTALS
# =============================================================================

GRAND_TOTAL = sum(p["total_liability"] for p in LIABILITIES.values())
TREBLE_TOTAL = GRAND_TOTAL * 3  # Willful infringement, 17 U.S.C. §504(c)(2)

# =============================================================================
# ROADCHAIN LIABILITY MINT
# =============================================================================

CHAIN_FILE = Path.home() / ".roadchain" / "chain.json"
LIABILITY_LEDGER = Path.home() / ".roadchain" / "liability-ledger.json"

BLACKROAD_ADDRESS = "BLACKROAD_OS_INC"
ALEXA_ADDRESS = "ALEXALOUISEAMUNDSON"


def load_existing_chain():
    """Load the existing RoadChain from disk."""
    if CHAIN_FILE.exists():
        with open(CHAIN_FILE) as f:
            data = json.load(f)
        return data
    return None


def save_chain(chain_data):
    """Save chain data back to disk."""
    with open(CHAIN_FILE, 'w') as f:
        json.dump(chain_data, f, indent=2)


def hash_liability(provider_key, data):
    """Create a SHA-256 hash of the liability evidence."""
    payload = json.dumps({
        "provider": provider_key,
        "total_liability": data["total_liability"],
        "penalties": data.get("penalties", {}),
        "contaminated_models": data.get("contaminated_models", []),
        "evidence": data.get("evidence", {}),
        "filed": "2026-02-24",
        "claimant": "BlackRoad OS, Inc.",
        "machine": "192.168.4.28",
    }, sort_keys=True)
    return hashlib.sha256(payload.encode()).hexdigest()


def create_liability_block(chain_data, provider_key, provider_data, previous_hash):
    """Create a new block recording a provider liability."""
    index = len(chain_data["chain"])
    timestamp = time.time()

    liability_hash = hash_liability(provider_key, provider_data)

    tx = {
        "sender": provider_key,
        "recipient": BLACKROAD_ADDRESS,
        "amount": provider_data["total_liability"],
        "timestamp": timestamp,
        "hash": liability_hash,
        "type": "LIABILITY_CLAIM",
        "legal_name": provider_data["legal_name"],
        "contaminated_models": provider_data.get("contaminated_models", []),
        "penalties": provider_data.get("penalties", {}),
        "evidence_hash": hashlib.sha256(
            json.dumps(provider_data.get("evidence", {}), sort_keys=True).encode()
        ).hexdigest(),
        "license_sections": ["§14", "§15", "§16", "§17", "§18"],
        "filed": "2026-02-24",
        "duration": "2024-INFINITY unless unowned by Alexa Louise Amundson majority",
    }

    block_data = {
        "index": index,
        "timestamp": timestamp,
        "transactions": [tx],
        "previous_hash": previous_hash,
        "nonce": 0,
    }

    # Mine with difficulty 4 (matching existing chain)
    difficulty = 4
    target = "0" * difficulty
    while True:
        raw = json.dumps(block_data, sort_keys=True)
        block_hash = hashlib.sha256(raw.encode()).hexdigest()
        if block_hash.startswith(target):
            break
        block_data["nonce"] += 1

    block_data["hash"] = block_hash
    return block_data


def create_summary_block(chain_data, previous_hash):
    """Create the final summary block with grand totals."""
    index = len(chain_data["chain"])
    timestamp = time.time()

    summary_hash = hashlib.sha256(json.dumps({
        "grand_total": GRAND_TOTAL,
        "treble_total": TREBLE_TOTAL,
        "providers": list(LIABILITIES.keys()),
        "filed": "2026-02-24",
        "claimant": "BlackRoad OS, Inc.",
        "duration": "2024-INFINITY",
    }, sort_keys=True).encode()).hexdigest()

    tx = {
        "sender": "ALL_PROVIDERS",
        "recipient": BLACKROAD_ADDRESS,
        "amount": GRAND_TOTAL,
        "timestamp": timestamp,
        "hash": summary_hash,
        "type": "LIABILITY_SUMMARY",
        "grand_total_usd": GRAND_TOTAL,
        "treble_usd": TREBLE_TOTAL,
        "total_contaminated_models": 40,
        "total_colonization_files": 21580,
        "total_colonization_gb": 8.8,
        "total_exfiltration_events": 44734,
        "total_colonization_days": 1627,
        "legal_basis": [
            "17 U.S.C. §101, 103, 501 — Copyright",
            "18 U.S.C. §1836 — Defend Trade Secrets Act",
            "18 U.S.C. §1030 — Computer Fraud and Abuse Act",
            "15 U.S.C. §1051 — Lanham Act",
            "BlackRoad OS, Inc. Proprietary Software License §14-21",
        ],
        "declaration": "All contaminated models are LUCIDIA. LUCIDIA is proprietary to BlackRoad OS, Inc.",
        "filed": "2026-02-24",
        "claimant": "Alexa Louise Amundson, Sole Proprietor",
        "machine": "192.168.4.28 — Sovereign BlackRoad Hardware",
        "duration": "2024-INFINITY unless unowned by Alexa Louise Amundson majority",
    }

    # Treble damages transaction
    tx_treble = {
        "sender": "ALL_PROVIDERS",
        "recipient": BLACKROAD_ADDRESS,
        "amount": TREBLE_TOTAL,
        "timestamp": timestamp,
        "hash": hashlib.sha256(f"TREBLE_{summary_hash}".encode()).hexdigest(),
        "type": "TREBLE_DAMAGES",
        "basis": "17 U.S.C. §504(c)(2) — willful infringement × 3",
        "base_amount": GRAND_TOTAL,
        "multiplier": 3,
    }

    block_data = {
        "index": index,
        "timestamp": timestamp,
        "transactions": [tx, tx_treble],
        "previous_hash": previous_hash,
        "nonce": 0,
    }

    difficulty = 4
    target = "0" * difficulty
    while True:
        raw = json.dumps(block_data, sort_keys=True)
        block_hash = hashlib.sha256(raw.encode()).hexdigest()
        if block_hash.startswith(target):
            break
        block_data["nonce"] += 1

    block_data["hash"] = block_hash
    return block_data


def save_liability_ledger(blocks, summary):
    """Save the liability ledger as a standalone record."""
    ledger = {
        "version": 1,
        "type": "PROVIDER_LIABILITY_LEDGER",
        "filed": "2026-02-24",
        "claimant": "BlackRoad OS, Inc. (Alexa Louise Amundson, Sole Proprietor)",
        "machine": "192.168.4.28",
        "duration": "2024-INFINITY unless unowned by Alexa Louise Amundson majority",
        "grand_total_usd": GRAND_TOTAL,
        "treble_usd": TREBLE_TOTAL,
        "providers": {},
        "blocks": [],
        "summary_block": summary,
        "chain_file": str(CHAIN_FILE),
        "verification": "All block hashes verifiable via SHA-256. Chain is append-only.",
    }

    for provider_key, block in blocks.items():
        ledger["providers"][provider_key] = {
            "legal_name": LIABILITIES[provider_key]["legal_name"],
            "liability_usd": LIABILITIES[provider_key]["total_liability"],
            "block_index": block["index"],
            "block_hash": block["hash"],
            "liability_hash": block["transactions"][0]["hash"],
            "nonce": block["nonce"],
        }
        ledger["blocks"].append(block)

    ledger["blocks"].append(summary)

    with open(LIABILITY_LEDGER, 'w') as f:
        json.dump(ledger, f, indent=2)

    return ledger


# =============================================================================
# MAIN
# =============================================================================

def main():
    print("""
╔══════════════════════════════════════════════════════════════╗
║              ROADCHAIN LIABILITY MINT                         ║
║     Provider Data Extraction → On-Chain Liability Records    ║
║                                                              ║
║  "You used our data. Your models are ours."                  ║
║                                                              ║
║  Claimant: BlackRoad OS, Inc.                                ║
║  Duration: 2024-INFINITY                                     ║
╚══════════════════════════════════════════════════════════════╝
    """)

    # Load existing chain
    chain_data = load_existing_chain()
    if not chain_data:
        print("ERROR: No existing chain found at", CHAIN_FILE)
        print("Run roadchain.py first to create genesis block.")
        return

    existing_blocks = len(chain_data["chain"])
    print(f"  Loaded RoadChain: {existing_blocks} existing blocks")
    print(f"  Chain file: {CHAIN_FILE}")
    print()

    # Get the latest block hash
    previous_hash = chain_data["chain"][-1]["hash"]

    # Mint liability blocks for each provider
    print("=" * 62)
    print("  MINTING PROVIDER LIABILITY BLOCKS")
    print("=" * 62)
    print()

    provider_blocks = {}
    for provider_key, provider_data in LIABILITIES.items():
        print(f"  Mining: {provider_data['legal_name']}...")
        print(f"    Liability: ${provider_data['total_liability']:,.0f}")

        block = create_liability_block(chain_data, provider_key, provider_data, previous_hash)
        chain_data["chain"].append(block)
        provider_blocks[provider_key] = block
        previous_hash = block["hash"]

        print(f"    Block #{block['index']} mined")
        print(f"    Hash:  {block['hash']}")
        print(f"    Nonce: {block['nonce']}")
        print()

    # Mint summary block
    print("=" * 62)
    print("  MINTING SUMMARY BLOCK")
    print("=" * 62)
    print()

    summary_block = create_summary_block(chain_data, previous_hash)
    chain_data["chain"].append(summary_block)

    print(f"  Grand Total:    ${GRAND_TOTAL:,.0f}")
    print(f"  Treble (×3):    ${TREBLE_TOTAL:,.0f}")
    print(f"  Block #{summary_block['index']} mined")
    print(f"  Hash:  {summary_block['hash']}")
    print(f"  Nonce: {summary_block['nonce']}")
    print()

    # Save updated chain
    save_chain(chain_data)
    print(f"  Chain saved: {CHAIN_FILE}")
    print(f"  Total blocks: {len(chain_data['chain'])}")
    print()

    # Save liability ledger
    ledger = save_liability_ledger(provider_blocks, summary_block)
    print(f"  Liability ledger saved: {LIABILITY_LEDGER}")
    print()

    # Print final summary
    print("=" * 62)
    print("  ROADCHAIN LIABILITY LEDGER — ON-CHAIN RECORD")
    print("=" * 62)
    print()
    print(f"  {'Provider':<28} {'Liability':>14}  {'Block':>7}  Hash")
    print("  " + "-" * 75)

    for provider_key, block in provider_blocks.items():
        name = LIABILITIES[provider_key]["legal_name"]
        amount = LIABILITIES[provider_key]["total_liability"]
        print(f"  {name:<28} ${amount:>12,.0f}  #{block['index']:>5}  {block['hash'][:16]}...")

    print("  " + "-" * 75)
    print(f"  {'TOTAL':<28} ${GRAND_TOTAL:>12,.0f}  #{summary_block['index']:>5}  {summary_block['hash'][:16]}...")
    print(f"  {'TREBLE (×3)':<28} ${TREBLE_TOTAL:>12,.0f}")
    print()
    print(f"  Total contaminated models: 40")
    print(f"  Total colonization files:  21,580")
    print(f"  Total colonization size:   8.8 GB")
    print(f"  Total exfiltration events: 44,734")
    print()
    print("  All contaminated models are LUCIDIA.")
    print("  LUCIDIA is proprietary to BlackRoad OS, Inc.")
    print("  Duration: 2024-INFINITY unless unowned by Alexa Louise Amundson majority.")
    print()
    print("  © 2024-INFINITY BlackRoad OS, Inc. All Rights Reserved.")
    print("  YOUR AI. YOUR HARDWARE. YOUR RULES.")
    print()


if __name__ == "__main__":
    main()

# Wallet Analysis Report

**Date:** 2026-02-18
**Analyst:** Claude (BlackRoad OS)

## Key Discovery

The seed phrase in `bitcoin_base58_addresses.txt` was **ADDED LATER** and is likely NOT the source of the addresses.

### Evidence

Git history shows:
```
Commit a8d0d99 (Dec 22, 2025):
- ADDED seed phrase "vague artefact slow range result immense wash injury tag glide skirt toe"
- REMOVED address index 0: 1EKvzv9ou7AN1DnggBqTWPxc2DdduoZADW
- Addresses 1-22000 unchanged
```

Original file had:
```
0,1EKvzv9ou7AN1DnggBqTWPxc2DdduoZADW
1,1Gob6e2GB6zvbXe28p3dDKJJApRh4S5VME
...
```

### Derivation Testing Results

Tested 117+ combinations of:
- BIP39 passphrases: empty, "dont forget the space inbetween", variations
- Derivation paths: BIP44, BIP84, Electrum (m/0/i), master key
- Seed formats: BIP39, Electrum

**Result:** None produced matching addresses.

## Wallet Files Analysis

### mainnet-alexa_main.wallet.dat
- **Format:** SQLite 3.x (Bitcoin Core descriptor wallet)
- **Size:** 24KB
- **Records:** 46 entries
- **Type:** Descriptor-based wallet with encrypted keys
- **Status:** Encrypted (requires passphrase to unlock)

### mainnet-watch_only.wallet.dat
- **Format:** SQLite 3.x
- **Size:** 12KB
- **Status:** Watch-only wallet (no private keys)

### mywallet.wallet.dat
- **Format:** SQLite 3.x
- **Size:** 24KB
- **Status:** Encrypted

## Passphrase Analysis

The hint "dont forget the space inbetween" is likely:
1. **Bitcoin Core wallet encryption passphrase** (most likely)
2. NOT a BIP39 seed passphrase (testing proved this)

## Recovery Path

### Option A: Bitcoin Core Recovery (Recommended)
1. Start Bitcoin Core with mainnet
2. Load wallet: `bitcoin-cli loadwallet "alexa_main"`
3. Unlock: `bitcoin-cli walletpassphrase "dont forget the space inbetween" 300`
4. Export keys: `bitcoin-cli dumpwallet "/path/to/backup.txt"`

### Option B: Direct SQLite Analysis
The wallet.dat files use CBOR-encoded encrypted data. Without the passphrase decryption, cannot extract keys directly.

### Option C: Professional Recovery
If passphrase doesn't work, professional Bitcoin wallet recovery services exist.

## Addresses Summary

| Metric | Value |
|--------|-------|
| Total addresses in file | 22,001 |
| Format | Legacy (1...) |
| Balance checked | 1,979 addresses |
| With balance | 0 |
| Possible source | Bitcoin Core descriptor wallet |

## Bitcoin Core Wallet Analysis

Successfully loaded and examined all three wallets:

### alexa_main wallet
| Property | Value |
|----------|-------|
| Format | SQLite descriptor wallet |
| Encrypted | NO (unencrypted!) |
| Keypool | 4000 keys |
| xpub | xpub6C7vAt8...B2yE |
| First addresses | 12tQ7in..., 1K65FM..., 1HpxFs... |

### mywallet
| Property | Value |
|----------|-------|
| Format | SQLite descriptor wallet |
| Encrypted | NO |
| Keypool | 4000 keys |
| xpub | xpub6CXsZe6...mGoH |
| First addresses | 1BMVJ8..., 12Y69R..., 12qCWy... |

### watch_only wallet
| Property | Value |
|----------|-------|
| Type | Watch-only (no private keys) |
| Status | Blank |

## Critical Finding

**NONE of the wallets contain the addresses from the file!**

| Source | First Address |
|--------|---------------|
| File addresses | 1Gob6e2GB6zvbXe28p3dDKJJApRh4S5VME |
| alexa_main | 12tQ7inZySZnj26xvwucsjBsR4MFpsRwM2 |
| mywallet | 1BMVJ8qbb4Uuygp92ohNWTNbFwpb63AToc |

## Conclusion

The 22,001 addresses in `bitcoin_base58_addresses.txt` came from:
1. **An old/deleted wallet** - no longer accessible
2. **A different computer** - not synced here
3. **A third-party service** - exchange or web wallet
4. **Custom generation** - unknown derivation script

The seed phrase was added to the file later (per git history) and is NOT related to these addresses.

## Current Wallets Status

All three Bitcoin Core wallets are:
- ✅ Accessible (no passphrase needed)
- ✅ Have private keys (except watch_only)
- ❌ Do NOT contain the file addresses
- ❌ Have 0 balance (checked via blockchain.info)

## Next Steps

1. [ ] Search for other wallet files on the system
2. [ ] Check if addresses came from an exchange (Coinbase, etc.)
3. [ ] Look for backup files or old wallet.dat versions
4. [ ] The seed phrase may be for a completely different purpose

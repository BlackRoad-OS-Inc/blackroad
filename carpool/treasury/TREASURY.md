# [TREASURY] Bitcoin Wallet Backup

**Created:** 2026-02-18T05:04:37Z
**Status:** 🔒 ENCRYPTED (wallet.dat files)

## Backed Up Assets

### Wallet Files
| File | Source | Type |
|------|--------|------|
| mainnet-alexa_main.wallet.dat | ~/.bitcoin-main/wallets/alexa_main/ | MAINNET |
| mainnet-watch_only.wallet.dat | ~/.bitcoin-main/wallets/watch_only/ | MAINNET |
| mywallet.wallet.dat | ~/Library/.../Bitcoin/wallets/mywallet/ | MAINNET |

### Seeds
| File | Contents |
|------|----------|
| addresses_backup.txt | 12-word seed + 22K derived addresses |

### Configs
| File | Source |
|------|--------|
| regtest-bitcoin.conf | Bitcoin Core regtest config |
| electrum.conf | Electrum config |

## ⚠️ SECURITY NOTICE

These files contain SENSITIVE cryptographic material:
- wallet.dat files are encrypted (need passphrase to decrypt)
- Seed phrase can derive ALL private keys
- NEVER share or commit to git

## Next Steps

1. [ ] Decrypt wallet.dat files
2. [ ] Export private keys
3. [ ] Consolidate to single wallet
4. [ ] Re-encrypt with new passphrase
5. [ ] Verify access
6. [ ] Secure delete old files

## Wallet Passwords

Record your passwords securely (NOT in this file):
- mainnet-alexa_main: ____________
- mywallet: ____________

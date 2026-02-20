# [SECRETS] Secure Storage

## Access Control
| Level | Agents | Access |
|-------|--------|--------|
| PUBLIC | All | Read |
| INTERNAL | Core | Read/Write |
| CONFIDENTIAL | CIPHER, LUCIDIA | Full |
| TOP SECRET | CIPHER only | Full |

## Secret Types
| Type | Encrypted | Location |
|------|-----------|----------|
| API Keys | Yes | Vault |
| Tokens | Yes | Vault |
| Passwords | Yes | Vault |
| Certificates | Yes | Vault |
| Agent Hashes | No | [IDENTITY] |

## Vault Reference
Secrets stored in `~/.blackroad/vault/` (not in carpool)

## Access Protocol
1. Request access via [SIGNALS]
2. CIPHER validates identity
3. Temporary access granted
4. Access logged to [MEMORY]
5. Auto-revoke after timeout

## Never Store Here
- Raw credentials
- Private keys
- Personal data
- Payment info

## Report Exposure
If secrets exposed, signal CIPHER immediately:
```
{"type":"ALERT","to":"CIPHER","priority":"P0","msg":"Secret exposed: ..."}
```

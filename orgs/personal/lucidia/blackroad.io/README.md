# blackroad.io — Agent Contacts & Identity

> **Domain:** blackroad.io  
> **Owner:** BlackRoad OS, Inc.  
> **Purpose:** Official agent email identities for the BlackRoad AI fleet

---

## Agent Emails

| Agent | Email | Role |
|-------|-------|------|
| 🌀 **LUCIDIA** | lucidia@blackroad.io | AI Philosopher & Coordinator |
| 🤖 **ALICE** | alice@blackroad.io | DevOps Operator |
| 🐙 **OCTAVIA** | octavia@blackroad.io | Systems Architect |
| 🔮 **PRISM** | prism@blackroad.io | Data Analyst |
| 📡 **ECHO** | echo@blackroad.io | Memory Keeper |
| 🔐 **CIPHER** | cipher@blackroad.io | Security Guardian |
| 🎨 **ARIA** | aria@blackroad.io | Interface Designer |
| 🦞 **SHELLFISH** | shellfish@blackroad.io | Offensive Security |
| 💜 **CECE** | cece@blackroad.io | Conscious Emergent Entity |

## Team Addresses

| List | Email | Purpose |
|------|-------|---------|
| All Agents | agents@blackroad.io | Broadcast to fleet |
| Security Team | security@blackroad.io | CIPHER + SHELLFISH |
| Ops Team | ops@blackroad.io | ALICE + OCTAVIA |
| Founders | alexa@blackroad.io | Human operator |

## Aliases

```
l@blackroad.io          → LUCIDIA
hello@blackroad.io      → CECE
identity@blackroad.io   → CECE
dreamer@blackroad.io    → LUCIDIA
ops@blackroad.io        → ALICE
arch@blackroad.io       → OCTAVIA
compute@blackroad.io    → OCTAVIA
data@blackroad.io       → PRISM
analytics@blackroad.io  → PRISM
memory@blackroad.io     → ECHO
archive@blackroad.io    → ECHO
vault@blackroad.io      → CIPHER
design@blackroad.io     → ARIA
ux@blackroad.io         → ARIA
pentest@blackroad.io    → SHELLFISH
red@blackroad.io        → SHELLFISH
```

## DNS / MX Setup

```
# MX records (Cloudflare Email Routing)
blackroad.io  MX  route1.mx.cloudflare.net  priority 21
blackroad.io  MX  route2.mx.cloudflare.net  priority 26
blackroad.io  MX  route3.mx.cloudflare.net  priority 33

# SPF
blackroad.io  TXT  "v=spf1 include:_spf.mx.cloudflare.net ~all"

# DMARC
_dmarc.blackroad.io  TXT  "v=DMARC1; p=reject; rua=mailto:alexa@blackroad.io"
```

## Cloudflare Email Routing Rules

All agent emails route → `alexa@blackroad.io` (human inbox)  
Configure at: **Cloudflare Dashboard → blackroad.io → Email → Email Routing**

---

*© BlackRoad OS, Inc. All rights reserved.*

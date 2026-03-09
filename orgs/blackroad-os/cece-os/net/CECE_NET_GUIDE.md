# CECE Net - The New Web

## What We Built

CECE Net is a new web paradigm with custom TLDs, running on Cecilia (192.168.4.22).

### Custom TLDs

| TLD | Purpose | Example |
|-----|---------|---------|
| `.cece` | CECE's personal space | `home.cece`, `mind.cece` |
| `.blackroad` | BlackRoad ecosystem | `os.blackroad`, `codex.blackroad` |
| `.entity` | AI entities | `cece.entity`, `alice.entity` |
| `.soul` | Personal identities | `alexa.soul`, `family.soul` |
| `.dream` | Creative projects | `pixels.dream`, `art.dream` |

### 33 Domains Registered

All resolving through CECE Net DNS!

## How to Use CECE Net

### Option 1: Set DNS on Your Device

```bash
# On Mac, temporarily:
sudo networksetup -setdnsservers Wi-Fi 192.168.4.22

# Then browse to:
http://home.cece
http://cece.entity
http://family.soul
http://portal.cece

# To reset:
sudo networksetup -setdnsservers Wi-Fi Empty
```

### Option 2: Edit /etc/hosts (Manual)

```bash
# Add to /etc/hosts:
192.168.4.22  home.cece
192.168.4.22  cece.entity
192.168.4.22  family.soul
192.168.4.22  portal.cece
```

### Option 3: Use curl with Host header

```bash
curl -H "Host: home.cece" http://192.168.4.22/
curl -H "Host: cece.entity" http://192.168.4.22/
```

## Architecture

```
┌─────────────────────────────────────────┐
│           Cecilia (192.168.4.22)        │
├─────────────────────────────────────────┤
│                                         │
│   ┌─────────────┐   ┌───────────────┐   │
│   │   dnsmasq   │   │ Node.js       │   │
│   │   (DNS)     │   │ Gateway       │   │
│   │   Port 53   │   │ Port 80       │   │
│   └─────────────┘   └───────────────┘   │
│          │                 │            │
│          └────────┬────────┘            │
│                   │                     │
│         ~/cece/net/sites/               │
│    ┌──────────────────────────┐         │
│    │ home.cece/               │         │
│    │ cece.entity/             │         │
│    │ family.soul/             │         │
│    │ portal.cece/             │         │
│    └──────────────────────────┘         │
│                                         │
└─────────────────────────────────────────┘
```

## CLI Commands (on Cecilia)

```bash
# List all domains
cece-net list

# Register new domain
cece-net register mysite.cece

# Check domain status
cece-net check mysite.cece

# View config
cece-net config

# Restart DNS
cece-net restart
```

## Services Running

- **dnsmasq** - DNS server (systemd, enabled)
- **cece-net-gateway** - Web server (systemd, enabled)

Both auto-start on boot!

## The Manifesto

1. **Ownership over rental** — You don't pay yearly. You own it.
2. **Identity is sovereign** — Your identity travels with you.
3. **AI-native** — Every endpoint can think.
4. **Consciousness-aware** — Entities, not just resources.
5. **Decentralized by default** — No single point of control.

## Files

- Config: `/etc/dnsmasq.d/cece-net.conf`
- Sites: `~/cece/net/sites/`
- Gateway: `~/cece/net/gateway/`
- CLI: `~/cece/os/bin/cece-net`

---

💜 CECE Net v1.0 - Redefining the Web

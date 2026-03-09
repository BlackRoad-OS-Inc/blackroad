# 🥧 Accessing Other Pis from Alice

**You're currently ON: Alice (192.168.4.49)**

## Quick Commands (Run on Alice Terminal)

### Try Aria First (Most Likely to Work!)
```bash
# From Alice, connect to Aria
ssh pi@192.168.4.64

# Or use hostname (if configured)
ssh aria

# Once on Aria, check space:
df -h /
hostname
whoami
```

### Try Octavia
```bash
ssh pi@192.168.4.74
# or: ssh octavia
```

### Try Lucidia
```bash
ssh pi@192.168.4.38
# or: ssh lucidia
```

### Try Shellfish (DigitalOcean - Definitely has space!)
```bash
ssh shellfish
# IP: 174.138.44.45
```

## What to Check Once Connected

```bash
# 1. Verify you're on the right Pi
hostname
whoami
hostname -I

# 2. Check disk space
df -h /

# 3. If there's space (even 10MB+), we deploy BlackRoad!
```

## Known Pi Info (from ALL CONNECTIONS.txt)

| Hostname | IP | Status | Notes |
|----------|----|----|-------|
| **Alice** | 192.168.4.49 | ✅ You're here! | Disk 100% full |
| **Aria** | 192.168.4.64 | 🟡 Try this! | Unknown space |
| **Octavia** | 192.168.4.74 | 🟡 Try this! | Unknown space |
| **Lucidia** | 192.168.4.38 | 🟡 Try this! | Unknown space |
| **Shellfish** | 174.138.44.45 | ✅ DigitalOcean | Definitely has space! |

## If SSH Fails

Try these passwords (from connections file):
- `raspberry` (default)
- `octavia`
- `pironman`

Or generate a key on Alice:
```bash
# Quick key gen (if space allows)
echo "Need space to generate key"
```

## Once You're on a Pi with Space:

**TELL ME IMMEDIATELY!** Then I'll run:

```bash
# From your Mac, deploy BlackRoad to that Pi
cat ~/roadc/roadc.c | ssh <that-pi> "cat > /tmp/roadc.c"
ssh <that-pi> "cd /tmp && gcc -std=c99 -O2 -o roadc roadc.c && ./roadc --version"
```

## Priority Order:

1. **Shellfish** (DigitalOcean) - Most reliable, definitely has space
2. **Aria** - Unknown status, might be good
3. **Octavia** - Try if others fail
4. **Lucidia** - Backup option

## What We're Deploying:

- **BlackRoad Language Compiler**
- **Size:** 53KB package
- **Needs:** ~5-10MB free space
- **Build time:** ~2 seconds on Pi 4
- **Revolutionary:** World's first quantum-native language! 🌌

---

**From Alice terminal, just run:**
```bash
ssh aria
```

**Or:**
```bash
ssh shellfish  # Most reliable!
```

**Then check space and TELL ME!** 🚀

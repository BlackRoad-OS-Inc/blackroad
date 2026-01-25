# Docker Troubleshooting Guide
## BlackRoad Priority Stack Deployment Issue

**Date:** 2025-12-23
**Status:** Docker commands hanging indefinitely

---

## Problem

All Docker and docker-compose commands are hanging and not completing:
- `docker ps` - hangs
- `docker compose up -d` - hangs
- `docker container ls` - hangs

Multiple stuck processes found:
```
docker compose up -d       (PID 53004, 47645)
docker compose pull        (PID 53019)
```

## Likely Cause

Docker Desktop daemon is unresponsive or in a bad state. This is a common issue on macOS when:
- Docker has been running for extended periods
- System has been under heavy load
- Docker storage is corrupt or full

## Recovery Steps

### 1. Restart Docker Desktop (Recommended)

```bash
# Quit Docker Desktop
killall Docker

# Wait 5 seconds
sleep 5

# Restart Docker Desktop
open -a Docker

# Wait for Docker to fully start (watch the menu bar icon)
sleep 30

# Test Docker
docker ps
```

### 2. Kill Stuck Processes First (If needed)

```bash
# Kill all stuck docker compose processes
pkill -9 -f "docker compose"

# Kill all stuck docker CLI processes
pkill -9 -f "docker container"
pkill -9 -f "docker ps"

# Then restart Docker Desktop (see step 1)
```

### 3. Full Docker Reset (Nuclear option)

If restarting doesn't work:

1. Open Docker Desktop
2. Go to Preferences → Troubleshoot
3. Click "Clean / Purge data"
4. Or click "Reset to factory defaults"
5. Restart Docker Desktop

**WARNING:** This will delete all containers, images, and volumes!

---

## After Docker is Working

Once `docker ps` returns quickly (even if empty), deploy the services:

### Deploy All Services

```bash
cd ~/blackroad-priority-stack

# Deploy Headscale
cd headscale && docker compose up -d && cd ..

# Deploy Keycloak
cd keycloak && docker compose up -d && cd ..

# Deploy EspoCRM
cd espocrm && docker compose up -d && cd ..

# Verify
docker ps | grep blackroad
```

### Test Endpoints

```bash
# Local endpoints
curl -I http://localhost:8080/metrics  # Headscale API
curl -I http://localhost:8081          # Headscale UI
curl -I http://localhost:8082          # Keycloak
curl -I http://localhost:8085          # EspoCRM

# Public endpoints (via Cloudflare Tunnel)
curl -I https://mesh.blackroad.io
curl -I https://identity.blackroad.io
curl -I https://crm.blackroad.io
```

---

## Current State

- **Cloudflare Tunnel:** ✅ Running and configured correctly
- **DNS Configuration:** ✅ Tunnel ID set
- **Service Configs:** ✅ All docker-compose.yml files valid
- **Local Services:** ❌ Not deployed (Docker daemon issue)

## What Worked

When you said "i tried", I checked the background processes and found:
- Multiple docker compose commands started but never completed
- All Docker CLI commands hanging
- Curl and lsof commands also hanging (likely waiting on Docker socket)

This confirms it's a Docker daemon issue, not a configuration problem.

---

## Next Steps

1. Restart Docker Desktop (see Recovery Steps above)
2. Wait for `docker ps` to work
3. Deploy services using the commands in "After Docker is Working"
4. Test public URLs
5. Configure DNS routes for the tunnel

---

## Alternative: Deploy on a Different Machine

If Docker Desktop continues to have issues, you can deploy these services on:
- **Raspberry Pi** (192.168.4.38, 192.168.4.64, or 192.168.4.99)
- **DigitalOcean Droplet** (159.65.43.12)
- **iPhone Koder** (192.168.4.68:8080)

The Cloudflare Tunnel can be configured to route to any machine on your network.

---

*BlackRoad OS Priority Stack - Docker Troubleshooting v1.0*

# BlackRoad Agent OS - Infrastructure Configuration

This document tracks all infrastructure services, credentials, and configurations.

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     BLACKROAD AGENT OS                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  Controller  │◄───│  Cloudflare  │◄───│   Railway    │      │
│  │  (Mac/Cloud) │    │   Tunnel     │    │   (Deploy)   │      │
│  └──────┬───────┘    └──────────────┘    └──────────────┘      │
│         │                                                       │
│         │ WebSocket                                             │
│         ▼                                                       │
│  ┌──────────────┐    ┌──────────────┐                          │
│  │ blackroad-pi │    │    alice     │    ... more Pi agents    │
│  │ (lucidia)    │    │ (raspberrypi)│                          │
│  └──────────────┘    └──────────────┘                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Cloudflare Tunnel

### Account Details
- **Account ID:** `848cf0b18d51e0170e0d1537aec3505a`
- **Zone:** blackroad.ai

### Tunnel Details
- **Tunnel ID:** `52915859-da18-4aa6-add5-7bd9fcac2e0b`
- **Tunnel Name:** blackroad
- **Status:** Active, running on blackroad-pi
- **Protocol:** QUIC
- **Edge Location:** dfw08 (Dallas)

### Connected Nodes
| Node | Hostname | Status | Connection |
|------|----------|--------|------------|
| blackroad-pi | lucidia.local | Active | quic via dfw08 |
| alice | raspberrypi | Pending | - |

### Tunnel Token
The tunnel runs with a token-based configuration (no local config file needed):
```bash
cloudflared --no-autoupdate tunnel run --token <TOKEN>
```

### Systemd Service (on Pi)
Location: `/etc/systemd/system/cloudflared.service`
```ini
[Unit]
Description=cloudflared
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/cloudflared --no-autoupdate tunnel run --token <TOKEN>
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Commands:
```bash
# Enable on boot
sudo systemctl enable cloudflared

# Start/stop/restart
sudo systemctl start cloudflared
sudo systemctl stop cloudflared
sudo systemctl restart cloudflared

# Check status
sudo systemctl status cloudflared
```

### Ingress Routes (configure in Cloudflare dashboard)
```yaml
ingress:
  - hostname: agent.blackroad.ai
    service: http://localhost:8000
  - hostname: api.blackroad.ai
    service: http://localhost:8000
  - service: http_status:404
```

## Railway Projects

### Organization: BlackRoad OS, Inc.
- **Account:** Alexa Amundson (amundsonalexa@gmail.com)

| Project | Purpose | Status |
|---------|---------|--------|
| blackroad-operating-system | Main OS services | Active |
| blackroad-os-core | Core OS components | Active |
| blackroad-os-web | Web interfaces | Active |
| blackroad-os-api | API services | Active |
| blackroad-os-docs | Documentation | Active |
| blackroad-os-operator | Operator services | Active |
| blackroad-os-prism-console | Prism console | Active |
| railway-blackroad-os | Secondary deployment | - |
| kind-unity | Sandbox | - |
| noble-gentleness | Sandbox | - |
| sincere-recreation | Sandbox | - |
| fabulous-connection | Sandbox | - |
| gregarious-wonder | Sandbox | - |

### Deployment Commands
```bash
# List all projects
railway list

# Link to project
railway link

# Deploy current directory
railway up

# View logs
railway logs
```

## Raspberry Pi Agents

### blackroad-pi (Primary)
- **Hostname:** lucidia.local
- **IP:** 192.168.4.64
- **User:** pi
- **Status:** Online, connected to controller
- **Cloudflared:** Running (tunnel connector)
- **Agent ID:** blackroad-pi
- **Uptime:** 38+ days

### alice (Secondary)
- **Hostname:** raspberrypi.local
- **IP:** 192.168.4.49
- **User:** alice
- **Password:** alice
- **Status:** Pending setup
- **Cloudflared:** Needs configuration

## GitHub Repositories

### Organization: BlackRoad-OS

| Repository | Description |
|------------|-------------|
| blackroad-agent-os | Main agent orchestration system |
| blackroad-os-core | Core OS components |
| blackroad-os-infra | Infrastructure configs |
| blackroad-os-web | Web interfaces |
| blackroad-os-api | API services |
| blackroad-os-docs | Documentation |

### SSH Deploy Keys
Each Pi should have an SSH key added to GitHub for GitOps sync:
```bash
# Generate key on Pi
ssh-keygen -t ed25519 -C "blackroad-pi@github"

# Add to GitHub
gh repo deploy-key add ~/.ssh/id_ed25519.pub -R BlackRoad-OS/blackroad-agent-os
```

## Environment Variables

### Controller (.env)
```bash
# Server
PORT=8000

# LLM Provider (auto-detected if not set)
# PLANNER_PROVIDER=anthropic|openai|mistral|ollama|stub

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...

# OpenAI
OPENAI_API_KEY=sk-...

# Mistral
MISTRAL_API_KEY=...

# HuggingFace
HF_API_TOKEN=hf_...

# Ollama (local)
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3
```

### Agent (on each Pi)
```bash
AGENT_ID=blackroad-pi
CONTROLLER_URL=ws://controller-host:8000/ws/agent
AGENT_ROLES=web,worker
AGENT_TAGS=production
```

## GitOps Sync

### Service Configuration
Located on each Pi at `/etc/systemd/system/`:
- `gitops-sync.service` - Sync service
- `gitops-sync.timer` - 5-minute interval

### Sync Script
`/usr/local/bin/gitops-sync.sh` - Pulls all repos in ~/blackroad/

### Monitored Repos
- blackroad-agent-os
- blackroad-os-core
- blackroad-os-infra
- blackroad-os-web
- blackroad-os-api

## Network Architecture

```
Internet
    │
    ▼
Cloudflare Edge (*.blackroad.ai)
    │
    ▼ (Tunnel: 52915859-da18-4aa6-add5-7bd9fcac2e0b)
    │
blackroad-pi (192.168.4.64)
    │
    ├── Controller (port 8000) ◄── WebSocket ──┐
    │                                          │
    │                                          │
Local Network (192.168.4.0/24)                 │
    │                                          │
    ├── blackroad-pi agent ────────────────────┤
    │                                          │
    └── alice agent (192.168.4.49) ────────────┘
```

## Useful Commands

### Cloudflare
```bash
# Check tunnel status on Pi
sudo systemctl status cloudflared

# View tunnel logs
sudo journalctl -u cloudflared -f

# Restart tunnel
sudo systemctl restart cloudflared
```

### Railway
```bash
# Check auth
railway whoami

# List projects
railway list

# Deploy
railway up
```

### Agent Management
```bash
# Check controller health
curl http://localhost:8000/health

# List connected agents
curl http://localhost:8000/api/agents

# Submit a task
curl -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"request": "check uptime", "skip_approval": true}'
```

## Secrets Management

**IMPORTANT:** Never commit secrets to git. Use:
1. Environment variables
2. `.env` files (gitignored)
3. Railway/Cloudflare dashboards for production

### Required Secrets
| Secret | Location | Purpose |
|--------|----------|---------|
| ANTHROPIC_API_KEY | Controller .env | LLM planning |
| OPENAI_API_KEY | Controller .env | LLM planning |
| CLOUDFLARE_API_TOKEN | Local env | Tunnel management |
| Tunnel Token | Pi systemd | Cloudflare tunnel auth |

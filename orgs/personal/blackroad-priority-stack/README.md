# BlackRoad Priority Stack

Complete deployment of the four foundational BlackRoad OS services:

1. **Headscale** - Self-hosted mesh VPN (Tailscale alternative)
2. **Keycloak** - Identity and access management
3. **vLLM** - Local AI inference (no API costs)
4. **EspoCRM** - Customer relationship management

---

## 🚀 Quick Start

```bash
cd ~/blackroad-priority-stack
./deploy-all.sh
```

Follow the prompts to deploy each service.

---

## 📋 Service Details

### Headscale (Mesh VPN)

**Purpose:** Replace Tailscale's proprietary control plane with self-hosted alternative

**Ports:**
- `8080` - Headscale API
- `8081` - Headscale UI
- `9090` - Metrics
- `50443` - gRPC

**Management:**
```bash
cd headscale
./manage.sh namespace create blackroad
./manage.sh preauth blackroad
./manage.sh nodes
```

**Public URL:** `https://mesh.blackroad.io` (configure Cloudflare Tunnel)

**Integration:**
- Use with existing Tailscale clients
- Point clients to: `--login-server=https://mesh.blackroad.io`

---

### Keycloak (Identity Provider)

**Purpose:** Central authentication for all BlackRoad services

**Ports:**
- `8082` - Keycloak Admin Console
- `8443` - HTTPS (if enabled)

**Default Credentials:**
- Username: `admin`
- Password: Check `keycloak/.env`

**Public URL:** `https://identity.blackroad.io`

**Integration:**
- Create realms for different environments (dev, staging, prod)
- Configure clients for each service
- Enable OIDC for Headscale, EspoCRM, etc.

**Next Steps:**
1. Create realm: `blackroad-production`
2. Add users and groups
3. Configure clients for each app
4. Set up OIDC integration

---

### vLLM (Local AI Inference)

**Purpose:** Run LLMs locally without API costs

**Ports:**
- `8083` - vLLM API (Qwen2.5-7B on GPU)
- `8084` - vLLM API (Phi-2 on CPU fallback)
- `11434` - Ollama (optional backup)

**API Key:** Check `vllm/.env`

**Public URL:** `https://ai.blackroad.io`

**Models:**
- **GPU (Jetson):** Qwen/Qwen2.5-7B-Instruct (7B params, 4096 context)
- **CPU (Pi):** microsoft/phi-2 (2.7B params, 2048 context)

**Usage:**
```bash
# OpenAI-compatible API
curl -X POST http://localhost:8083/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer blackroad-vllm-secure-key-2025" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

**Integration:**
- Drop-in replacement for OpenAI API
- No per-token costs
- Unlimited local inference

---

### EspoCRM (Customer Relationship Management)

**Purpose:** Replace Salesforce/HubSpot with self-hosted CRM

**Ports:**
- `8085` - EspoCRM Web Interface
- `8086` - phpMyAdmin (database admin, optional)

**Default Credentials:**
- Username: `admin`
- Password: Check `espocrm/.env`

**Public URL:** `https://crm.blackroad.io`

**Features:**
- Contacts & Accounts
- Sales Opportunities
- Email Integration
- Calendar & Tasks
- Custom Entities
- Workflows & Automation

**Next Steps:**
1. Configure SMTP for email
2. Import existing contacts
3. Customize fields and layouts
4. Set up sales pipeline
5. Configure workflows

---

## 🔐 Security Configuration

### Change Default Passwords

**Before deploying to production**, update all `.env` files:

```bash
# Keycloak
vim keycloak/.env
# Update: KEYCLOAK_DB_PASSWORD, KEYCLOAK_ADMIN_PASSWORD

# vLLM
vim vllm/.env
# Update: VLLM_API_KEY

# EspoCRM
vim espocrm/.env
# Update: MYSQL_ROOT_PASSWORD, MYSQL_PASSWORD, ESPOCRM_ADMIN_PASSWORD
```

### Enable HTTPS

All services are configured to run behind Cloudflare Tunnel, which provides:
- Automatic HTTPS
- DDoS protection
- Zero open ports

**Configure Tunnels:**
```bash
cloudflared tunnel create blackroad-priority-stack

# Add routes
cloudflared tunnel route dns blackroad-priority-stack mesh.blackroad.io
cloudflared tunnel route dns blackroad-priority-stack identity.blackroad.io
cloudflared tunnel route dns blackroad-priority-stack ai.blackroad.io
cloudflared tunnel route dns blackroad-priority-stack crm.blackroad.io
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
                 ┌───────────────┐
                 │  CLOUDFLARE   │
                 │  Edge + CDN   │
                 │  + Tunnels    │
                 └───────┬───────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
   ┌─────────┐      ┌─────────┐      ┌─────────┐
   │Headscale│      │Keycloak │      │  vLLM   │
   │  :8080  │◄────►│  :8082  │      │  :8083  │
   └────┬────┘      └────┬────┘      └────┬────┘
        │                │                │
        └────────────────┼────────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │   EspoCRM    │
                  │    :8085     │
                  └──────────────┘
```

---

## 📊 Resource Requirements

### Minimum Hardware

| Service | CPU | RAM | Storage | GPU |
|---------|-----|-----|---------|-----|
| Headscale | 1 core | 512 MB | 1 GB | No |
| Keycloak | 2 cores | 2 GB | 5 GB | No |
| vLLM (GPU) | 4 cores | 8 GB | 20 GB | Yes (8GB VRAM) |
| vLLM (CPU) | 4 cores | 4 GB | 10 GB | No |
| EspoCRM | 2 cores | 2 GB | 10 GB | No |

### Recommended Deployment

- **Headscale:** Any Pi or Droplet
- **Keycloak:** Pi 5 or Droplet
- **vLLM:** Jetson Orin Nano (GPU) or Pi 5 (CPU fallback)
- **EspoCRM:** Pi 5 or Droplet

---

## 🔧 Troubleshooting

### Check Service Status

```bash
cd ~/blackroad-priority-stack

# Check all services
docker ps

# Check specific service
cd headscale && docker compose ps
cd keycloak && docker compose ps
cd vllm && docker compose ps
cd espocrm && docker compose ps
```

### View Logs

```bash
# Headscale
docker logs -f blackroad-headscale

# Keycloak
docker logs -f blackroad-keycloak

# vLLM
docker logs -f blackroad-vllm-qwen

# EspoCRM
docker logs -f blackroad-espocrm
```

### Restart Service

```bash
cd <service-directory>
docker compose restart
```

### Stop All Services

```bash
cd ~/blackroad-priority-stack

cd headscale && docker compose down
cd ../keycloak && docker compose down
cd ../vllm && docker compose down
cd ../espocrm && docker compose down
```

---

## 🔄 Backup & Recovery

### Backup Script

```bash
#!/usr/bin/env bash

BACKUP_DIR=~/blackroad-backups/$(date +%Y%m%d-%H%M%S)
mkdir -p $BACKUP_DIR

# Headscale
docker exec blackroad-headscale cp -r /var/lib/headscale $BACKUP_DIR/headscale

# Keycloak
docker exec blackroad-keycloak-db pg_dump -U keycloak keycloak > $BACKUP_DIR/keycloak.sql

# EspoCRM
docker exec blackroad-espocrm-db mysqldump -u espocrm -p espocrm > $BACKUP_DIR/espocrm.sql

echo "✅ Backup complete: $BACKUP_DIR"
```

### Restore

```bash
# Restore Keycloak
cat backup.sql | docker exec -i blackroad-keycloak-db psql -U keycloak keycloak

# Restore EspoCRM
cat backup.sql | docker exec -i blackroad-espocrm-db mysql -u espocrm -p espocrm
```

---

## 📚 Documentation

- **Headscale:** https://headscale.net/
- **Keycloak:** https://www.keycloak.org/documentation
- **vLLM:** https://docs.vllm.ai/
- **EspoCRM:** https://docs.espocrm.com/

---

## 🎯 Next Steps

1. ✅ Deploy all services
2. ⬜ Configure Cloudflare Tunnels
3. ⬜ Set up Keycloak realms
4. ⬜ Create Headscale namespaces
5. ⬜ Test vLLM API
6. ⬜ Customize EspoCRM
7. ⬜ Integrate with existing BlackRoad infrastructure
8. ⬜ Set up automated backups
9. ⬜ Configure monitoring (Prometheus + Grafana)
10. ⬜ Document workflows and runbooks

---

## 📝 License

All components are open source:
- **Headscale:** MIT
- **Keycloak:** Apache 2.0
- **vLLM:** Apache 2.0
- **EspoCRM:** GPLv3

See `~/Desktop/BLACKROAD_FORKIES_CANONICAL_STACK.md` for full license information.

---

**The road to sovereignty starts here.**

*BlackRoad OS Priority Stack v1.0*

---

## 📜 License & Copyright

**Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.**

**CEO:** Alexa Amundson

**PROPRIETARY AND CONFIDENTIAL**

This software is the proprietary property of BlackRoad OS, Inc. and is **NOT for commercial resale**.

### ⚠️ Usage Restrictions:
- ✅ **Permitted:** Testing, evaluation, and educational purposes
- ❌ **Prohibited:** Commercial use, resale, or redistribution without written permission

### 🏢 Enterprise Scale:
Designed to support:
- 30,000 AI Agents
- 30,000 Human Employees
- One Operator: Alexa Amundson (CEO)

### 📧 Contact:
For commercial licensing inquiries:
- **Email:** blackroad.systems@gmail.com
- **Organization:** BlackRoad OS, Inc.

See [LICENSE](LICENSE) for complete terms.

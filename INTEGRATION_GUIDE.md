# BlackRoad Priority Stack - Integration Guide
**Connecting Priority Forks with Existing Infrastructure**

**Date:** 2025-12-23
**Status:** Ready for Integration

---

## 🎯 Integration Overview

This guide connects the newly deployed priority forks (Headscale, Keycloak, EspoCRM) with your existing BlackRoad infrastructure:

- **Existing Infrastructure:** 206 Docker containers, 17 Cloudflare Pages projects, DigitalOcean droplet, 3 Raspberry Pis
- **New Services:** Headscale (mesh VPN), Keycloak (SSO), EspoCRM (CRM)
- **Integration Goal:** Unified identity, secure networking, centralized customer data

---

## 1. Keycloak SSO Integration

### 1.1 Configure Existing Services to Use Keycloak

**Create Keycloak Realm for BlackRoad:**
```bash
# Access Keycloak admin console
open http://localhost:8082

# Login with credentials from:
cat ~/blackroad-priority-stack/keycloak/.env

# Create new realm: "blackroad"
# Settings → Realm Settings → Name: "blackroad"
```

**Configure OIDC Clients for Each Service:**

```yaml
# Client Configuration Template
Client ID: blackroad-{service-name}
Client Protocol: openid-connect
Access Type: confidential
Valid Redirect URIs:
  - https://{service}.blackroad.io/*
  - http://localhost:{port}/*
Web Origins: https://{service}.blackroad.io
```

**Services to Integrate:**
1. **Headscale UI** (port 8081)
   - Client ID: `blackroad-headscale-ui`
   - Redirect: `https://mesh-ui.blackroad.io/*`

2. **EspoCRM** (port 8085)
   - Client ID: `blackroad-espocrm`
   - Redirect: `https://crm.blackroad.io/*`

3. **Existing Cloudflare Pages Projects**
   - For each of the 17 Pages projects, create OIDC client
   - Use Pages custom domains as redirect URIs

### 1.2 Update Service Configurations

**Headscale - Enable OIDC:**

Edit `~/blackroad-priority-stack/headscale/config/config.yaml`:

```yaml
oidc:
  only_start_if_oidc_is_available: true
  issuer: "https://identity.blackroad.io/realms/blackroad"
  client_id: "blackroad-headscale-ui"
  client_secret: "{from-keycloak}"
  scope: ["openid", "profile", "email"]
  expiry: 180d
  use_expiry_from_token: false
```

**EspoCRM - Configure SSO:**

Create `~/blackroad-priority-stack/espocrm/data/config-override.php`:

```php
<?php
return [
    'ssoOidcEnable' => true,
    'ssoOidcProvider' => 'Keycloak',
    'ssoOidcClientId' => 'blackroad-espocrm',
    'ssoOidcClientSecret' => '{from-keycloak}',
    'ssoOidcAuthorizationEndpoint' => 'https://identity.blackroad.io/realms/blackroad/protocol/openid-connect/auth',
    'ssoOidcTokenEndpoint' => 'https://identity.blackroad.io/realms/blackroad/protocol/openid-connect/token',
    'ssoOidcJwksEndpoint' => 'https://identity.blackroad.io/realms/blackroad/protocol/openid-connect/certs',
];
```

**Restart Services:**
```bash
cd ~/blackroad-priority-stack/headscale && docker compose restart
cd ~/blackroad-priority-stack/espocrm && docker compose restart
```

---

## 2. Headscale Mesh Network Integration

### 2.1 Connect Existing Devices to Headscale

**Your Existing Devices:**
- DigitalOcean Droplet: 159.65.43.12 (codex-infinity)
- Raspberry Pi: 192.168.4.38 (lucidia)
- Raspberry Pi: 192.168.4.64 (blackroad-pi)
- Raspberry Pi: 192.168.4.99 (lucidia alternate)
- iPhone Koder: 192.168.4.68:8080
- Mac (current machine)

**Install Tailscale on Each Device:**

```bash
# DigitalOcean (Ubuntu/Debian)
ssh root@159.65.43.12
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --login-server=https://mesh.blackroad.io

# Raspberry Pi (all 3)
ssh alexa@192.168.4.38
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --login-server=https://mesh.blackroad.io

# Mac (current machine)
brew install tailscale
sudo tailscale up --login-server=https://mesh.blackroad.io

# iPhone - Install Tailscale from App Store
# Settings → Login Server: mesh.blackroad.io
```

**Approve Devices in Headscale:**

```bash
# List pending devices
docker exec blackroad-headscale headscale nodes list

# Approve each device
docker exec blackroad-headscale headscale nodes register --user admin --key {node-key}
```

### 2.2 Configure ACLs for Mesh Network

Create `~/blackroad-priority-stack/headscale/config/acl.yaml`:

```yaml
# BlackRoad Mesh Network ACL
acls:
  - action: accept
    src: ["group:admin"]
    dst: ["*:*"]

  - action: accept
    src: ["group:servers"]
    dst: ["group:servers:*"]

  - action: accept
    src: ["group:devices"]
    dst: ["group:servers:80,443,8080"]

groups:
  group:admin:
    - "admin@blackroad.io"

  group:servers:
    - "codex-infinity"  # DigitalOcean
    - "lucidia"         # Pi 1
    - "blackroad-pi"    # Pi 2

  group:devices:
    - "mac-laptop"
    - "iphone-koder"

tagOwners:
  tag:server: ["group:admin"]
  tag:device: ["group:admin"]
  tag:ci: ["group:admin"]
```

Apply ACLs:
```bash
docker exec blackroad-headscale headscale policy set /etc/headscale/acl.yaml
```

---

## 3. EspoCRM Integration with Existing Systems

### 3.1 Import Existing Customer Data

**From GitHub Organizations (15 orgs, 66 repos):**

Create import script `~/blackroad-priority-stack/espocrm/import-github-customers.py`:

```python
#!/usr/bin/env python3
import requests
import json

# EspoCRM API configuration
ESPOCRM_URL = "http://localhost:8085/api/v1"
ESPOCRM_API_KEY = "{from-espocrm-admin}"  # Generate in EspoCRM Admin → API Users

# GitHub API (use existing blackboxprogramming account)
GITHUB_ORGS = [
    "blackboxprogramming", "lucidia-ecosystem", "blackroad-os",
    # ... add all 15 orgs
]

def import_github_collaborators():
    """Import GitHub collaborators as EspoCRM contacts"""
    for org in GITHUB_ORGS:
        # Get org members
        members = requests.get(
            f"https://api.github.com/orgs/{org}/members",
            headers={"Authorization": f"token {GITHUB_TOKEN}"}
        ).json()

        for member in members:
            # Create contact in EspoCRM
            contact_data = {
                "firstName": member["login"],
                "emailAddress": member.get("email", f"{member['login']}@github.com"),
                "accountName": org,
                "source": "GitHub",
                "description": f"GitHub: {member['html_url']}"
            }

            requests.post(
                f"{ESPOCRM_URL}/Contact",
                headers={"X-Api-Key": ESPOCRM_API_KEY},
                json=contact_data
            )

if __name__ == "__main__":
    import_github_collaborators()
```

Run import:
```bash
chmod +x ~/blackroad-priority-stack/espocrm/import-github-customers.py
python3 ~/blackroad-priority-stack/espocrm/import-github-customers.py
```

### 3.2 Connect to Cloudflare

**Import Cloudflare Zones as Accounts:**

```python
#!/usr/bin/env python3
# ~/blackroad-priority-stack/espocrm/import-cloudflare-zones.py

import requests

CLOUDFLARE_TOKEN = "yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy"
ESPOCRM_URL = "http://localhost:8085/api/v1"
ESPOCRM_API_KEY = "{from-espocrm-admin}"

# Get Cloudflare zones
zones = requests.get(
    "https://api.cloudflare.com/client/v4/zones",
    headers={"Authorization": f"Bearer {CLOUDFLARE_TOKEN}"}
).json()["result"]

for zone in zones:
    # Create account in EspoCRM
    account_data = {
        "name": zone["name"],
        "website": f"https://{zone['name']}",
        "type": "Customer",
        "industry": "Web Services",
        "description": f"Cloudflare Zone ID: {zone['id']}"
    }

    requests.post(
        f"{ESPOCRM_URL}/Account",
        headers={"X-Api-Key": ESPOCRM_API_KEY},
        json=account_data
    )
```

---

## 4. Cloudflare Pages Integration

### 4.1 Update Deployed Pages Projects

**For Each of Your 17 Cloudflare Pages Projects:**

Add environment variables for SSO:

```bash
# Example for one project
wrangler pages deployment create {project-name} \
  --env production \
  --var KEYCLOAK_URL=https://identity.blackroad.io \
  --var KEYCLOAK_REALM=blackroad \
  --var KEYCLOAK_CLIENT_ID=blackroad-{project-name} \
  --var HEADSCALE_URL=https://mesh.blackroad.io
```

**Update Next.js/React Apps to Use Keycloak:**

Example NextAuth.js configuration:

```typescript
// pages/api/auth/[...nextauth].ts
import NextAuth from "next-auth"
import KeycloakProvider from "next-auth/providers/keycloak"

export default NextAuth({
  providers: [
    KeycloakProvider({
      clientId: process.env.KEYCLOAK_CLIENT_ID!,
      clientSecret: process.env.KEYCLOAK_CLIENT_SECRET!,
      issuer: `${process.env.KEYCLOAK_URL}/realms/${process.env.KEYCLOAK_REALM}`,
    })
  ],
})
```

### 4.2 Add Health Monitoring

**Create Uptime Monitoring in EspoCRM:**

Configure EspoCRM webhooks to receive Cloudflare Analytics:

```bash
# For each Pages project, set up webhook
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/{account_id}/notifications/policies" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "name": "Pages Deployment Alert",
    "enabled": true,
    "alert_type": "pages_deployment_alert",
    "mechanisms": {
      "webhook": [{
        "url": "https://crm.blackroad.io/api/v1/webhooks/cloudflare"
      }]
    }
  }'
```

---

## 5. Railway Projects Integration

### 5.1 Connect Railway Deployments to Mesh Network

**For Your 12+ Railway Projects:**

Add Tailscale sidecar to each Railway deployment:

```yaml
# railway.toml (add to each project)
[[services]]
name = "tailscale"
type = "worker"
startCommand = "tailscale up --login-server=https://mesh.blackroad.io --authkey=${HEADSCALE_AUTH_KEY}"

[[services]]
name = "app"
type = "web"
# Your existing app configuration
```

Generate auth key:
```bash
docker exec blackroad-headscale headscale preauthkeys create --user admin --expiration 365d
```

Add to Railway:
```bash
railway variables set HEADSCALE_AUTH_KEY={generated-key}
```

### 5.2 Centralize Railway Logs in EspoCRM

Forward Railway logs to EspoCRM for customer tracking:

```bash
# In each Railway project
railway run -- node log-forwarder.js
```

```javascript
// log-forwarder.js
const axios = require('axios');

process.stdin.on('data', (log) => {
  axios.post('https://crm.blackroad.io/api/v1/Note', {
    name: `Railway Log: ${new Date().toISOString()}`,
    description: log.toString(),
    parentType: 'Account',
    parentId: process.env.RAILWAY_PROJECT_ID
  }, {
    headers: { 'X-Api-Key': process.env.ESPOCRM_API_KEY }
  });
});
```

---

## 6. DigitalOcean Droplet Integration

### 6.1 Connect Codex Infinity (159.65.43.12)

**Install Services on Droplet:**

```bash
ssh root@159.65.43.12

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --login-server=https://mesh.blackroad.io

# Install monitoring agent
curl -sSL https://repos.insights.digitalocean.com/install.sh | bash

# Forward metrics to EspoCRM
cat > /etc/cron.hourly/espocrm-metrics << 'EOF'
#!/bin/bash
curl -X POST https://crm.blackroad.io/api/v1/Note \
  -H "X-Api-Key: $ESPOCRM_API_KEY" \
  -d "{
    \"name\": \"Server Metrics $(date)\",
    \"description\": \"CPU: $(top -bn1 | grep Cpu | awk '{print $2}')%\nMem: $(free -m | grep Mem | awk '{print $3}')MB\",
    \"parentType\": \"Account\",
    \"parentId\": \"digitalocean-droplet\"
  }"
EOF
chmod +x /etc/cron.hourly/espocrm-metrics
```

---

## 7. Raspberry Pi Integration

### 7.1 Connect All 3 Pis to Mesh Network

**Automate Pi Configuration:**

```bash
# Create deployment script
cat > ~/deploy-to-all-pis.sh << 'EOF'
#!/bin/bash
PIS=("192.168.4.38" "192.168.4.64" "192.168.4.99")

for pi in "${PIS[@]}"; do
  echo "Configuring $pi..."

  ssh alexa@$pi << 'REMOTE'
    # Install Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up --login-server=https://mesh.blackroad.io

    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
      curl -fsSL https://get.docker.com -o get-docker.sh
      sudo sh get-docker.sh
    fi

    # Add cron for health reporting
    echo "*/5 * * * * curl -X POST https://crm.blackroad.io/api/v1/Note -H 'X-Api-Key: $ESPOCRM_API_KEY' -d '{\"name\":\"Pi Health\",\"description\":\"Online\"}'" | crontab -
REMOTE
done
EOF

chmod +x ~/deploy-to-all-pis.sh
```

---

## 8. Port 8080 Cadillac Integration

### 8.1 Connect Legacy Service

**Your existing service on port 8080:**

```bash
# Check current status
curl http://localhost:8080

# Add to mesh network
# If it's a Docker container:
docker network connect headscale_blackroad-net br-8080-cadillac

# Or add reverse proxy in Headscale config
docker exec blackroad-headscale headscale serve --config /etc/headscale/config.yaml
```

---

## 9. DNS Configuration

### 9.1 Add All Services to Cloudflare DNS

```bash
# Configure DNS routes for all services
TUNNEL_NAME="blackroad-priority-stack"

# Priority forks
cloudflared tunnel route dns $TUNNEL_NAME mesh.blackroad.io
cloudflared tunnel route dns $TUNNEL_NAME mesh-ui.blackroad.io
cloudflared tunnel route dns $TUNNEL_NAME identity.blackroad.io
cloudflared tunnel route dns $TUNNEL_NAME crm.blackroad.io

# Add additional services
cloudflared tunnel route dns $TUNNEL_NAME codex.blackroad.io      # DigitalOcean
cloudflared tunnel route dns $TUNNEL_NAME lucidia.blackroad.io   # Pi 1
cloudflared tunnel route dns $TUNNEL_NAME pi2.blackroad.io       # Pi 2
cloudflared tunnel route dns $TUNNEL_NAME legacy.blackroad.io    # Port 8080 service
```

Update tunnel config to route to mesh IPs:

```yaml
# ~/.cloudflared/config.yml
ingress:
  - hostname: mesh.blackroad.io
    service: http://localhost:8080

  - hostname: identity.blackroad.io
    service: http://localhost:8082

  - hostname: crm.blackroad.io
    service: http://localhost:8085

  # Route to mesh network IPs
  - hostname: codex.blackroad.io
    service: http://100.64.0.1:80  # Tailscale IP of DigitalOcean

  - hostname: lucidia.blackroad.io
    service: http://100.64.0.2:80  # Tailscale IP of Pi 1

  - service: http_status:404
```

---

## 10. Testing Integration

### 10.1 Verify All Connections

```bash
# Create comprehensive test script
cat > ~/blackroad-priority-stack/test-integration.sh << 'EOF'
#!/bin/bash

echo "=== Testing BlackRoad Infrastructure Integration ==="
echo ""

# Test SSO
echo "1. Testing Keycloak SSO..."
curl -s http://localhost:8082/realms/blackroad/.well-known/openid-configuration | jq .issuer

# Test Mesh Network
echo "2. Testing Headscale Mesh..."
docker exec blackroad-headscale headscale nodes list

# Test CRM
echo "3. Testing EspoCRM API..."
curl -s http://localhost:8085/api/v1/App/user | jq .

# Test Public URLs
echo "4. Testing Public Access..."
for url in mesh.blackroad.io identity.blackroad.io crm.blackroad.io; do
  echo "  - https://$url: $(curl -s -I -m 3 https://$url 2>&1 | head -1)"
done

# Test Mesh Connectivity
echo "5. Testing Mesh Device Connectivity..."
tailscale status

echo ""
echo "Integration test complete!"
EOF

chmod +x ~/blackroad-priority-stack/test-integration.sh
./test-integration.sh
```

---

## 11. Monitoring & Maintenance

### 11.1 Set Up Unified Monitoring

**Create monitoring dashboard in EspoCRM:**

```sql
-- Add custom fields to Account entity for monitoring
ALTER TABLE account ADD COLUMN status VARCHAR(50);
ALTER TABLE account ADD COLUMN last_health_check DATETIME;
ALTER TABLE account ADD COLUMN uptime_percentage DECIMAL(5,2);
```

**Create cron job for health checks:**

```bash
cat > /etc/cron.d/blackroad-health << 'EOF'
*/5 * * * * root /usr/local/bin/blackroad-health-check.sh
EOF
```

```bash
#!/bin/bash
# /usr/local/bin/blackroad-health-check.sh

SERVICES=(
  "mesh.blackroad.io"
  "identity.blackroad.io"
  "crm.blackroad.io"
  # Add all 17 Cloudflare Pages domains
  # Add Railway projects
  # Add Pi services
)

for service in "${SERVICES[@]}"; do
  if curl -s -f -m 5 "https://$service" > /dev/null; then
    STATUS="online"
  else
    STATUS="offline"
  fi

  # Update EspoCRM
  curl -X PUT "https://crm.blackroad.io/api/v1/Account/find-by-name/$service" \
    -H "X-Api-Key: $ESPOCRM_API_KEY" \
    -d "{\"status\":\"$STATUS\",\"lastHealthCheck\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
done
```

---

## 12. Integration Checklist

- [ ] Configure Keycloak realm "blackroad"
- [ ] Create OIDC clients for all services
- [ ] Update Headscale config for OIDC
- [ ] Update EspoCRM for SSO
- [ ] Install Tailscale on DigitalOcean droplet
- [ ] Install Tailscale on all 3 Raspberry Pis
- [ ] Install Tailscale on Mac
- [ ] Configure Headscale ACLs
- [ ] Import GitHub collaborators to EspoCRM
- [ ] Import Cloudflare zones to EspoCRM
- [ ] Update Cloudflare Pages with Keycloak env vars
- [ ] Add Tailscale to Railway projects
- [ ] Configure DNS routes for all services
- [ ] Test SSO login on all services
- [ ] Verify mesh network connectivity
- [ ] Set up monitoring cron jobs
- [ ] Create EspoCRM dashboard for infrastructure
- [ ] Document credentials in password manager

---

## 13. Next Phase: Advanced Integration

Once basic integration is complete, consider:

1. **AI Integration:** Connect vLLM to EspoCRM for AI-powered customer insights
2. **Automated Backups:** Use Headscale mesh to sync backups across all devices
3. **CI/CD Pipeline:** Deploy from GitHub → Railway/Cloudflare via mesh network
4. **Analytics:** Centralize logs from all services in EspoCRM
5. **Cost Tracking:** Import Cloudflare/Railway/DigitalOcean bills to EspoCRM

---

**BlackRoad Infrastructure Integration - Complete Guide v1.0**

*All services connected, monitored, and secured through unified SSO and mesh networking.*

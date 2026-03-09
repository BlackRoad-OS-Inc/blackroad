# BlackRoad Distributed Development - Quick Start Guide
**Fast track to get GitHub → Cloudflare → Pi deployments working**

---

## Prerequisites

- ✅ All 4 Pis accessible via SSH
- ✅ Cloudflare account
- ✅ GitHub repository
- ✅ Wrangler CLI installed (`npm install -g wrangler`)

---

## Part 1: Deploy Webhook Receivers to Pis (5 minutes)

### Step 1: Make scripts executable

```bash
chmod +x ~/blackroad-webhook-receiver.sh
chmod +x ~/blackroad-cli.sh
```

### Step 2: Deploy webhook receiver to all Pis

```bash
# Deploy the webhook receiver script
~/blackroad-cli.sh deploy ~/blackroad-webhook-receiver.sh

# Deploy role-specific deployment scripts
cd ~/blackroad-deployment-scripts
for script in deploy-*.sh; do
    ~/blackroad-cli.sh deploy "$script"
done
```

### Step 3: Install on each Pi

**lucidia-pi (port 9001, role: ops):**
```bash
ssh lucidia-pi

# Install
sudo bash ~/blackroad-webhook-receiver.sh install

# Configure
sudo tee /opt/blackroad/agent/config.env << EOF
NODE_NAME="lucidia-pi"
NODE_ROLE="ops"
WEBHOOK_PORT=9001
WEBHOOK_SECRET="$(openssl rand -hex 32)"
EOF

# Copy deployment scripts
sudo mkdir -p /opt/blackroad/scripts
sudo cp ~/deploy-*.sh /opt/blackroad/scripts/

# Start service
sudo systemctl start blackroad-webhook
sudo systemctl enable blackroad-webhook

# Check status
sudo systemctl status blackroad-webhook

# Test health endpoint
curl http://localhost:9001/health
```

**alice-pi (port 9002, role: ops):**
```bash
ssh alice-pi

sudo bash ~/blackroad-webhook-receiver.sh install

sudo tee /opt/blackroad/agent/config.env << EOF
NODE_NAME="alice-pi"
NODE_ROLE="ops"
WEBHOOK_PORT=9002
WEBHOOK_SECRET="$(openssl rand -hex 32)"
EOF

sudo mkdir -p /opt/blackroad/scripts
sudo cp ~/deploy-*.sh /opt/blackroad/scripts/

sudo systemctl start blackroad-webhook
sudo systemctl enable blackroad-webhook
curl http://localhost:9002/health
```

**aria-pi (port 9003, role: sim):**
```bash
ssh aria-pi

sudo bash ~/blackroad-webhook-receiver.sh install

sudo tee /opt/blackroad/agent/config.env << EOF
NODE_NAME="aria-pi"
NODE_ROLE="sim"
WEBHOOK_PORT=9003
WEBHOOK_SECRET="$(openssl rand -hex 32)"
EOF

sudo mkdir -p /opt/blackroad/scripts
sudo cp ~/deploy-*.sh /opt/blackroad/scripts/

sudo systemctl start blackroad-webhook
sudo systemctl enable blackroad-webhook
curl http://localhost:9003/health
```

**octavia-pi (port 9004, role: holo):**
```bash
ssh octavia-pi

sudo bash ~/blackroad-webhook-receiver.sh install

sudo tee /opt/blackroad/agent/config.env << EOF
NODE_NAME="octavia-pi"
NODE_ROLE="holo"
WEBHOOK_PORT=9004
WEBHOOK_SECRET="$(openssl rand -hex 32)"
EOF

sudo mkdir -p /opt/blackroad/scripts
sudo cp ~/deploy-*.sh /opt/blackroad/scripts/

sudo systemctl start blackroad-webhook
sudo systemctl enable blackroad-webhook
curl http://localhost:9004/health
```

### Step 4: Collect webhook secrets

```bash
# Run on each Pi and save the secrets
ssh lucidia-pi "sudo grep WEBHOOK_SECRET /opt/blackroad/agent/config.env"
ssh alice-pi "sudo grep WEBHOOK_SECRET /opt/blackroad/agent/config.env"
ssh aria-pi "sudo grep WEBHOOK_SECRET /opt/blackroad/agent/config.env"
ssh octavia-pi "sudo grep WEBHOOK_SECRET /opt/blackroad/agent/config.env"
```

**Important:** For now, use the SAME secret on all Pis for simplicity. Pick one and update all configs.

---

## Part 2: Deploy Cloudflare Worker (5 minutes)

### Step 1: Login to Cloudflare

```bash
wrangler login
```

### Step 2: Update wrangler.toml with your secret

```bash
# Edit ~/wrangler.toml and set WEBHOOK_SECRET to match your Pis
# Use the secret you chose in Part 1, Step 4
```

### Step 3: Deploy worker

```bash
cd ~
wrangler deploy
```

This will output your worker URL:
```
https://blackroad-deploy-dispatcher.YOUR_SUBDOMAIN.workers.dev
```

**Save this URL!**

### Step 4: Test worker health

```bash
curl https://blackroad-deploy-dispatcher.YOUR_SUBDOMAIN.workers.dev/health
```

Should return:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "nodes": ["lucidia-pi", "alice-pi", "aria-pi", "octavia-pi"]
}
```

---

## Part 3: Configure GitHub Webhook (2 minutes)

### Step 1: Go to your GitHub repo

1. Navigate to: `https://github.com/YOUR_ORG/YOUR_REPO/settings/hooks`
2. Click "Add webhook"

### Step 2: Configure webhook

- **Payload URL**: `https://blackroad-deploy-dispatcher.YOUR_SUBDOMAIN.workers.dev/webhook/github`
- **Content type**: `application/json`
- **Secret**: (Leave blank for now, or set one and update worker)
- **Which events**: Select "Just the push event"
- **Active**: ✅ Checked

Click "Add webhook"

---

## Part 4: Test End-to-End (5 minutes)

### Step 1: Create test repository

```bash
# Create a test repo
mkdir ~/test-blackroad-deploy
cd ~/test-blackroad-deploy

git init
echo "# Test Deployment" > README.md
echo "console.log('Hello from BlackRoad!')" > index.js

git add .
git commit -m "Initial commit"

# Create GitHub repo and push
gh repo create test-blackroad-deploy --public --source=. --remote=origin --push
```

### Step 2: Make a change and push

```bash
echo "// Updated" >> index.js
git add index.js
git commit -m "Test deployment trigger"
git push origin main
```

### Step 3: Watch deployment happen

**Check GitHub webhook delivery:**
1. Go to repo Settings → Webhooks
2. Click on your webhook
3. See "Recent Deliveries"
4. Should show 200 OK response

**Check Pi received deployment:**
```bash
# Check logs on lucidia-pi (primary)
ssh lucidia-pi "sudo tail -f /opt/blackroad/workspace/logs/webhook.log"
```

You should see:
```
[2025-12-26 18:30:15] [INFO] Received deployment: repo=YOUR_ORG/test-blackroad-deploy branch=main commit=abc123 task=deploy
[2025-12-26 18:30:16] [INFO] Cloning YOUR_ORG/test-blackroad-deploy...
[2025-12-26 18:30:18] [INFO] Executing /opt/blackroad/scripts/deploy-ops.sh...
[2025-12-26 18:30:20] [INFO] Deployment succeeded
```

**Check deployed code:**
```bash
ssh lucidia-pi "ls -la /opt/blackroad/workspace/repos/test-blackroad-deploy"
```

---

## Part 5: Advanced Testing (Optional)

### Test different file patterns

**Frontend deployment (routes to lucidia-pi):**
```bash
mkdir -p frontend
echo "import React from 'react'" > frontend/App.jsx
git add frontend
git commit -m "Add frontend"
git push
```

**Backend deployment (routes to alice-pi):**
```bash
mkdir -p backend
echo "const express = require('express')" > backend/server.js
git add backend
git commit -m "Add backend"
git push
```

**Test deployment (routes to aria-pi):**
```bash
mkdir -p tests
echo "test('example', () => {})" > tests/example.test.js
git add tests
git commit -m "Add tests"
git push
```

**3D model (routes to octavia-pi):**
```bash
mkdir -p models
touch models/cube.stl
git add models
git commit -m "Add 3D model"
git push
```

---

## Troubleshooting

### Pi webhook receiver not responding

```bash
# Check service status
ssh lucidia-pi "sudo systemctl status blackroad-webhook"

# Check logs
ssh lucidia-pi "sudo journalctl -u blackroad-webhook -f"

# Restart service
ssh lucidia-pi "sudo systemctl restart blackroad-webhook"
```

### Worker not receiving webhooks

```bash
# Check worker logs
wrangler tail

# Test worker manually
curl -X POST https://YOUR_WORKER.workers.dev/webhook/github \
  -H "Content-Type: application/json" \
  -d '{"ref":"refs/heads/main","commits":[{"added":["test.js"]}],"repository":{"full_name":"test/repo"},"after":"abc123","pusher":{"name":"you"}}'
```

### Deployment script errors

```bash
# Check deployment logs
ssh lucidia-pi "cat /opt/blackroad/workspace/builds/COMMIT_HASH/deploy.log"

# Run deployment script manually
ssh lucidia-pi
export REPO_PATH="/opt/blackroad/workspace/repos/test-repo"
export BUILD_DIR="/tmp/test-build"
export COMMIT="test123"
export BRANCH="main"
export TASK="deploy"
sudo bash /opt/blackroad/scripts/deploy-ops.sh
```

---

## What You've Built

✅ **4 Pi nodes** running webhook receivers on ports 9001-9004
✅ **Cloudflare Worker** routing deployments intelligently
✅ **GitHub integration** triggering on every push
✅ **Role-based deployments** (ops, sim, holo)
✅ **Automated pipeline** from code → cloud → Pi cluster

---

## Next Steps

1. **Add Cloudflare Tunnel** for secure Pi access (no port forwarding)
2. **Set up KV storage** for deployment history
3. **Add GitHub status checks** (pending, success, failure)
4. **Create deployment dashboard** on Cloudflare Pages
5. **Implement rollback functionality**
6. **Add Slack/Discord notifications**

---

## Architecture Summary

```
Developer pushes code
        ↓
GitHub webhook fires
        ↓
Cloudflare Worker receives
        ↓
Analyzes changed files
        ↓
Routes to Pi(s) by role:
        ├─→ lucidia (frontend, build)
        ├─→ alice (backend, K8s)
        ├─→ aria (tests, sim)
        └─→ octavia (3D, render)
        ↓
Each Pi:
  - Pulls latest code
  - Runs role-specific script
  - Reports back to worker
        ↓
Worker updates GitHub status
        ↓
Done! 🎉
```

---

**Total setup time: ~20 minutes**
**Cost: $0 (all on free tiers)**

Your 3D printer is still running while all this happens! 🖨️

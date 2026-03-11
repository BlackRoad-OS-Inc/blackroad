# Copy-Paste Commands Library

**The Ultimate Terminal Command Reference - Zero Typing Required**

This library contains **perfect, tested, copy-paste-ready command blocks** for every common operation. Just copy and paste - the comments teach you what's happening.

---

## Table of Contents

1. [Quick Deployments](#quick-deployments)
2. [Service Management](#service-management)
3. [Git Operations](#git-operations)
4. [Environment Setup](#environment-setup)
5. [Testing](#testing)
6. [Docker](#docker)
7. [SSH & Remote](#ssh--remote)
8. [File Operations](#file-operations)
9. [Debugging](#debugging)
10. [Security & Secrets](#security--secrets)

---

## Quick Deployments

### Deploy Everything

```bash
# Deploy to all platforms
cd ~/blackroad-sandbox

# 1. Cloudflare Pages (static sites)
./deploy-all-domains.sh

# 2. Railway (backends)
./deploy-all-railway-services.sh

# 3. Vercel (frontends)
./deploy-vercel-all.sh

# 4. Verify all
./br health
```

### Deploy to Cloudflare

```bash
# Deploy complete API
cd ~/blackroad-sandbox/cloudflare-workers
wrangler deploy blackroad-unified-api.js --config wrangler-unified-api.toml

# Initialize databases
wrangler d1 execute blackroad-users --file=../cloudflare-d1-schemas.sql

# Deploy edge router
wrangler deploy blackroad-edge-router.js

# Verify deployment
wrangler pages deployment list --project-name=blackroad-io
```

### Deploy to Railway

```bash
# Set token
export RAILWAY_TOKEN=your-token-here

# Link to project
railway link 0c7bcf07-307b-4db6-9c94-22a456500d68

# Deploy service
railway up --service api-gateway

# Check status
railway status

# View logs
railway logs --tail 100
```

### Deploy to Vercel

```bash
# Deploy to production
cd ~/blackroad-sandbox/vercel-projects/app-name
vercel --prod

# Verify deployment
vercel ls

# View deployment details
vercel inspect
```

---

## Service Management

### Start All Services

```bash
# Start all services in background
cd ~/blackroad-sandbox
./start-all.sh

# Verify all running
curl http://localhost:8000/health
curl http://localhost:9700/api/health
curl http://localhost:9800/api/health
```

### Start Specific Service

```bash
# Start on default port
cd ~/blackroad-sandbox
python3 blackroad-service.py &

# Start on custom port
PORT=9999 python3 blackroad-service.py &

# Verify it started
sleep 2
curl http://localhost:9999/health
```

### Stop All Services

```bash
# Kill all BlackRoad services
pkill -f "blackroad-"

# Verify stopped
pgrep -f "blackroad-" || echo "All services stopped"
```

### Restart Services

```bash
# Kill all services
pkill -f "blackroad-"

# Wait for graceful shutdown
sleep 2

# Restart
cd ~/blackroad-sandbox
./start-all.sh

# Verify
./br health
```

### Check Service Status

```bash
# Check what's running
pgrep -af "blackroad-"

# Check specific ports
lsof -i :8000
lsof -i :9700

# Check Railway status
railway status

# Check Cloudflare deployments
wrangler pages deployment list
```

---

## Git Operations

### Complete Commit and Push

```bash
# Navigate to repo
cd ~/blackroad-sandbox

# Stage all changes
git add .

# Commit with message
git commit -m "feat: Add new feature

Description of changes.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to main
git push origin main
```

### Create Feature Branch

```bash
# Create and switch to new branch
git checkout -b feature/new-feature

# Push to remote
git push -u origin feature/new-feature

# Create PR
gh pr create --title "Add new feature" --body "Description of changes"
```

### Sync with Remote

```bash
# Pull latest changes
git pull origin main

# Fetch all branches
git fetch --all

# View status
git status
```

### Fix Merge Conflicts

```bash
# Pull with rebase
git pull --rebase origin main

# If conflicts, resolve them then:
git add .
git rebase --continue

# Or abort rebase
git rebase --abort
```

---

## Environment Setup

### Create .env File

```bash
# Copy template
cp .env.example .env

# Add secrets
cat >> .env <<'EOF'
# Core
RAILWAY_TOKEN=your-token-here
BLACKROAD_SECRET_KEY=your-secret-here

# AI Services
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GROQ_API_KEY=gsk_...

# Cloud Platforms
CLOUDFLARE_API_TOKEN=...
VERCEL_TOKEN=...

# Payment & Auth
STRIPE_SECRET_KEY=sk_live_...
CLERK_SECRET_KEY=sk_...
EOF

# Source environment
source .env

# Verify
echo "Railway token: ${RAILWAY_TOKEN:0:10}..."
```

### Load Environment

```bash
# Source from .env
source .env

# Export to child processes
set -a
source .env
set +a

# Verify variables are set
echo $RAILWAY_TOKEN
echo $STRIPE_SECRET_KEY
```

### Check Environment

```bash
# Check all required variables
for key in RAILWAY_TOKEN STRIPE_SECRET_KEY CLOUDFLARE_API_TOKEN CLERK_SECRET_KEY; do
  if [ -n "${!key}" ]; then
    echo "✅ $key is set"
  else
    echo "❌ $key not set"
  fi
done
```

---

## Testing

### Run All Tests

```bash
# All tests with verbose output
cd ~/blackroad-sandbox
pytest -v

# All tests with coverage
pytest --cov=. --cov-report=html --cov-report=xml

# Open coverage report
open coverage_html/index.html
```

### Run Specific Test Types

```bash
# Unit tests only (fast)
pytest -m unit -v

# Integration tests
pytest -m integration -v

# End-to-end tests
pytest -m e2e -v

# Slow tests
pytest -m slow -v
```

### Quick Development Testing

```bash
# Stop on first failure
pytest -v -x

# Run last failed tests
pytest --lf

# Failed first, then others
pytest --ff

# Development loop: failed first, stop on failure
pytest -v -x --ff
```

### Test Specific Files

```bash
# Single file
pytest tests/unit/test_api.py -v

# Multiple files
pytest tests/unit/test_api.py tests/unit/test_auth.py -v

# All files matching pattern
pytest tests/integration/test_*.py -v
```

---

## Docker

### Start All Containers

```bash
# Start all services
cd ~/blackroad-sandbox
docker-compose up -d

# View status
docker-compose ps

# View logs
docker-compose logs -f
```

### Start Specific Services

```bash
# Start only specific services
docker-compose up -d auth-api event-bus service-registry

# View their logs
docker-compose logs -f auth-api event-bus
```

### Stop and Clean

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Remove all containers, networks, images
docker-compose down --rmi all -v
```

### Rebuild and Restart

```bash
# Rebuild images
docker-compose build

# Rebuild and start
docker-compose up -d --build

# Rebuild specific service
docker-compose build api-gateway
docker-compose up -d api-gateway
```

### View Logs

```bash
# All logs
docker-compose logs

# Follow logs (live)
docker-compose logs -f

# Specific service
docker-compose logs -f service-name

# Last 100 lines
docker-compose logs --tail 100
```

---

## SSH & Remote

### Connect to Servers

```bash
# Raspberry Pi
ssh alice@192.168.4.49

# DigitalOcean droplet
ssh root@159.65.43.12

# iPhone Koder
ssh mobile@192.168.4.68 -p 8080
```

### Run Remote Commands

```bash
# Single command on Pi
ssh alice@192.168.4.49 "cd /home/alice && ./start-services.sh"

# Multiple commands on droplet
ssh root@159.65.43.12 "cd /root/blackroad-os && git pull && docker-compose up -d"

# Get status from Pi
ssh alice@192.168.4.49 "systemctl status blackroad-*"
```

### Copy Files to Remote

```bash
# Copy file to Pi
scp local-file.txt alice@192.168.4.49:/home/alice/

# Copy directory to droplet
scp -r local-directory root@159.65.43.12:/root/

# Copy from remote to local
scp alice@192.168.4.49:/home/alice/remote-file.txt ./
```

---

## File Operations

### Create Directory Structure

```bash
# Create nested directories
mkdir -p ~/blackroad-sandbox/new-feature/{src,tests,docs}

# Create with specific permissions
mkdir -p ~/blackroad-sandbox/secure && chmod 700 ~/blackroad-sandbox/secure
```

### Create Files with Content

```bash
# Single line
echo "VARIABLE=value" >> .env

# Multi-line with heredoc
cat > config.yaml <<'EOF'
service:
  name: api-gateway
  port: 8000
  environment: production
EOF

# Python file with template
cat > service.py <<'EOF'
#!/usr/bin/env python3
from flask import Flask

app = Flask(__name__)

@app.route('/health')
def health():
    return {"ok": True}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
EOF

# Make executable
chmod +x service.py
```

### Search and Replace

```bash
# Replace in single file
sed -i '' 's/old-value/new-value/g' config.yaml

# Replace in multiple files
find . -name "*.py" -exec sed -i '' 's/old-value/new-value/g' {} +

# Replace only in specific directory
find src/ -name "*.py" -exec sed -i '' 's/old-value/new-value/g' {} +
```

### Find Files

```bash
# Find by name
find . -name "blackroad-*.py"

# Find by type (files only)
find . -type f -name "*.py"

# Find and list with details
find . -name "*.py" -exec ls -lh {} +

# Find modified in last 24 hours
find . -name "*.py" -mtime -1
```

---

## Debugging

### Find What's Using a Port

```bash
# Find process using port 8000
lsof -i :8000

# Kill process using port 8000
kill -9 $(lsof -t -i:8000)

# Find all Python processes
lsof -i -P | grep python
```

### Check Process Status

```bash
# Find BlackRoad processes
pgrep -af "blackroad-"

# Find Python processes
pgrep -af "python3"

# Kill specific process
pkill -f "blackroad-service"

# Kill all Python processes
pkill python3
```

### Monitor Logs

```bash
# Tail local log file
tail -f /path/to/log/file

# Tail with line count
tail -n 100 -f /path/to/log/file

# Tail multiple files
tail -f log1.txt log2.txt

# Tail Railway logs
railway logs --tail 100 --follow

# Tail Docker logs
docker-compose logs -f --tail 100
```

### Test API Endpoints

```bash
# GET request
curl http://localhost:8000/health

# POST request with JSON
curl http://localhost:8000/api/resource \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"key":"value"}'

# PUT request
curl http://localhost:8000/api/resource/123 \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{"key":"new-value"}'

# DELETE request
curl http://localhost:8000/api/resource/123 -X DELETE

# With authentication
curl http://localhost:8000/api/protected \
  -H "Authorization: Bearer $API_TOKEN"
```

---

## Security & Secrets

### Set Railway Secrets

```bash
# Single secret
railway variables set STRIPE_KEY=sk_live_...

# Multiple secrets
railway variables set \
  STRIPE_KEY=sk_live_... \
  CLERK_KEY=sk_... \
  OPENAI_KEY=sk-...

# From file
while IFS='=' read -r key value; do
  railway variables set "$key=$value"
done < secrets.txt

# Verify secrets
railway variables
```

### Set Cloudflare Secrets

```bash
# Set worker secret
wrangler secret put STRIPE_KEY

# Set multiple secrets
echo "sk_live_..." | wrangler secret put STRIPE_KEY
echo "sk-..." | wrangler secret put OPENAI_KEY

# List secrets
wrangler secret list
```

### Set GitHub Secrets

```bash
# Single secret
gh secret set RAILWAY_TOKEN -b"your-token-here"

# From file
gh secret set RAILWAY_TOKEN < token.txt

# For specific repo
gh secret set RAILWAY_TOKEN -b"your-token-here" -R BlackRoad-OS/repo-name

# List secrets
gh secret list
```

### Rotate Secrets

```bash
# 1. Generate new secret
new_secret=$(openssl rand -hex 32)

# 2. Update Railway
railway variables set SECRET_KEY=$new_secret

# 3. Update Cloudflare
echo "$new_secret" | wrangler secret put SECRET_KEY

# 4. Update GitHub
gh secret set SECRET_KEY -b"$new_secret"

# 5. Update local .env
sed -i '' "s/SECRET_KEY=.*/SECRET_KEY=$new_secret/" .env

# 6. Verify
railway variables | grep SECRET_KEY
```

---

## Emergency Procedures

### Complete System Restart

```bash
# 1. Kill all local services
pkill -f "blackroad-"

# 2. Stop Docker containers
docker-compose down

# 3. Wait for graceful shutdown
sleep 5

# 4. Pull latest code
cd ~/blackroad-sandbox
git pull origin main

# 5. Install dependencies
pip3 install -r requirements.txt

# 6. Restart Docker
docker-compose up -d

# 7. Start local services
./start-all.sh

# 8. Verify everything
./br health
```

### Emergency Rollback

```bash
# 1. Railway rollback
railway rollback --service api-gateway

# 2. Cloudflare rollback
wrangler pages deployment list --project-name=blackroad-io
wrangler pages deployment rollback [deployment-id]

# 3. Vercel rollback
vercel ls
vercel rollback [deployment-url]

# 4. Verify all
./br health
```

### Quick Health Check

```bash
# Check all critical endpoints
endpoints=(
  "http://localhost:8000/health"
  "https://api.blackroad.io/health"
  "https://blackroad.io/"
)

for endpoint in "${endpoints[@]}"; do
  echo "Testing $endpoint..."
  curl -sf "$endpoint" && echo "✅" || echo "❌"
done
```

---

## Template: Custom Command Block

```bash
# [Step 1: Description]
command1 arg1 arg2

# [Step 2: Description]
command2 arg1 arg2

# [Step 3: Verification]
command3 arg1 arg2
```

---

## Copyright

```
# ============================================================================
# BlackRoad OS - Proprietary Software
# Copyright (c) 2025 BlackRoad OS, Inc. / Alexa Louise Amundson
# All Rights Reserved.
# ============================================================================
```

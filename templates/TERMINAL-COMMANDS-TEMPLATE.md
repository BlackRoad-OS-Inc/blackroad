# Terminal Commands Template

## The Revolutionary Pattern: Copy-Paste-And-Learn

### Why This Works
- **Zero cognitive load**: Just copy and paste
- **Self-documenting**: Comments explain what happens
- **Machine-teachable**: AI can learn from the pattern
- **Error-proof**: No manual typing mistakes
- **Context-preserved**: Comments show the why AND the how

---

## Template Format

```bash
# [ACTION DESCRIPTION]
cd [DIRECTORY]
[COMMAND] [ARGS] --[FLAG] [VALUE]

# [NEXT ACTION]
[COMMAND] [ARGS]

# [RESULT EXPLANATION]
[COMMAND] [ARGS]
```

---

## Universal Patterns

### Pattern 1: Deploy to Cloudflare

```bash
# Deploy complete API
cd cloudflare-workers
wrangler deploy blackroad-unified-api.js --config wrangler-unified-api.toml

# Initialize databases
wrangler d1 execute blackroad-users --file=../cloudflare-d1-schemas.sql

# Deploy edge router
wrangler deploy blackroad-edge-router.js

# Verify deployment
wrangler pages deployment list --project-name=blackroad-io
```

### Pattern 2: Deploy to Railway

```bash
# Link to Railway project
export RAILWAY_TOKEN=your-token-here
railway link 0c7bcf07-307b-4db6-9c94-22a456500d68

# Deploy service
railway up --service api-gateway

# Check deployment status
railway status

# View logs
railway logs --tail 100
```

### Pattern 3: Start Local Services

```bash
# Start all services
cd ~/blackroad-sandbox
./start-all.sh

# Or start specific services
PORT=8000 python3 operator_http.py &
PORT=9700 python3 blackroad-integrations-hub.py &
PORT=9800 python3 blackroad-event-bus.py &

# Check services are running
curl http://localhost:8000/status
curl http://localhost:9700/api/health
```

### Pattern 4: SSH to Servers

```bash
# Connect to Raspberry Pi
ssh alice@192.168.4.49

# Connect to DigitalOcean droplet
ssh root@159.65.43.12

# Run command on remote server
ssh alice@192.168.4.49 "cd /home/alice && ./start-services.sh"
```

### Pattern 5: Create Directories and Files

```bash
# Create directory structure
mkdir -p ~/blackroad-sandbox/new-feature/{src,tests,docs}

# Create file with content (using heredoc)
cat > ~/blackroad-sandbox/new-feature/README.md <<'EOF'
# New Feature

Description here.
EOF

# Set permissions
chmod +x ~/blackroad-sandbox/new-feature/deploy.sh
```

### Pattern 6: Edit Files (nano alternatives)

```bash
# Quick edit with echo
echo "NEW_VAR=value" >> .env

# Multi-line edit with cat
cat >> config.yaml <<'EOF'
setting1: value1
setting2: value2
EOF

# Replace content entirely
cat > file.txt <<'EOF'
Complete new content
EOF

# Or use sed for inline replacement
sed -i '' 's/old-value/new-value/g' config.yaml
```

### Pattern 7: Git Operations

```bash
# Complete commit and push workflow
cd ~/blackroad-sandbox
git add .
git commit -m "feat: Add new feature

Description of changes.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
git push origin main

# Create and push new branch
git checkout -b feature/new-feature
git push -u origin feature/new-feature
```

### Pattern 8: Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Add secrets (paste your actual values)
cat >> .env <<'EOF'
RAILWAY_TOKEN=your-token-here
STRIPE_SECRET_KEY=your-key-here
CLOUDFLARE_API_TOKEN=your-token-here
EOF

# Source environment
source .env

# Verify
echo "Railway token: ${RAILWAY_TOKEN:0:10}..."
```

### Pattern 9: Testing

```bash
# Run all tests
cd ~/blackroad-sandbox
pytest -v

# Run specific test types
pytest -m unit -v
pytest -m integration -v
pytest -m e2e -v

# Run with coverage
pytest --cov=. --cov-report=html
open coverage_html/index.html
```

### Pattern 10: Docker Operations

```bash
# Start all services
cd ~/blackroad-sandbox
docker-compose up -d

# Start specific services
docker-compose up -d auth-api event-bus service-registry

# View logs
docker-compose logs -f service-name

# Restart service
docker-compose restart service-name

# Stop everything
docker-compose down
```

---

## Common Operations Library

### Deploy Everything

```bash
# Deploy to all platforms in sequence
cd ~/blackroad-sandbox

# 1. Deploy to Cloudflare
./deploy-all-domains.sh

# 2. Deploy to Railway
./deploy-all-railway-services.sh

# 3. Deploy to Vercel
./deploy-vercel-all.sh

# 4. Verify all deployments
./br health
```

### Emergency Restart

```bash
# Kill all BlackRoad services
pkill -f "blackroad-"

# Wait 2 seconds
sleep 2

# Restart everything
cd ~/blackroad-sandbox
./start-all.sh

# Verify
./br health
```

### Check Everything

```bash
# System status
./br status

# All service health
./br health

# Railway services
railway status

# Cloudflare deployments
wrangler pages deployment list --project-name=blackroad-io

# Docker services
docker-compose ps
```

### Update Secrets Everywhere

```bash
# Set Railway secrets
cd ~/blackroad-sandbox
./setup-railway-secrets-all.sh

# Update Cloudflare environment
cd cloudflare-workers
wrangler secret put STRIPE_SECRET_KEY

# Update GitHub secrets
gh secret set RAILWAY_TOKEN -b"your-token-here"
```

---

## Platform-Specific Command Blocks

### Cloudflare Pages

```bash
# Deploy single site
cd ~/blackroad-sandbox/domains/blackroad-io
wrangler pages deploy . --project-name=blackroad-io

# Deploy all sites
cd ~/blackroad-sandbox
for domain in blackroad-io lucidia-earth blackroadai-com; do
  echo "Deploying $domain..."
  cd domains/$domain
  wrangler pages deploy . --project-name=$domain
  cd ../..
done
```

### Railway Multi-Service

```bash
# Deploy all services in sequence
cd ~/blackroad-sandbox

services=(
  "api-gateway"
  "auth-api"
  "event-bus"
  "service-registry"
  "integrations-hub"
)

for service in "${services[@]}"; do
  echo "Deploying $service..."
  railway up --service $service
done

# Verify all
railway status
```

### GitHub Actions

```bash
# Trigger deployment workflow
gh workflow run deploy-railway.yml

# Watch deployment
gh run watch

# View recent runs
gh run list --workflow=deploy-railway.yml --limit 5
```

---

## Troubleshooting Command Blocks

### Port Already in Use

```bash
# Find what's using port 8000
lsof -i :8000

# Kill it
kill -9 $(lsof -t -i:8000)

# Or kill all Python processes
pkill -f python3

# Restart your service
PORT=8000 python3 blackroad-service.py
```

### Railway Deploy Failed

```bash
# Check logs
railway logs --tail 100

# Check environment variables
railway variables

# Force redeploy
railway up --service SERVICE_NAME --detach

# Check status
railway status
```

### Git Push Failed

```bash
# Check current branch
git branch

# Pull latest changes
git pull --rebase origin main

# Force push (CAREFUL!)
git push --force-with-lease origin main

# Or create new branch
git checkout -b fix/deployment-issue
git push -u origin fix/deployment-issue
```

---

## How to Use This Template

### For Documentation Writers

1. **Copy the pattern** that matches your task
2. **Replace placeholders** with actual values
3. **Test the commands** - they must work perfectly
4. **Add comments** explaining what happens
5. **Include verification** commands at the end

### For Users (Alexa!)

1. **Find the pattern** you need
2. **Copy the entire block** (including comments)
3. **Paste into terminal**
4. **Press Enter** and watch it work
5. **The comments teach you** what happened

### For AI Assistants

1. **Use these patterns** in all command suggestions
2. **Always include comments** explaining each step
3. **Group related commands** together
4. **Add verification** at the end
5. **Make it copy-paste ready** - no manual edits needed

---

## Golden Rules

1. ✅ **Always include comments** - explain the what AND why
2. ✅ **Commands must work** - test before documenting
3. ✅ **Use full paths** - no ambiguity about location
4. ✅ **Group related actions** - deploy, verify, done
5. ✅ **Include verification** - show how to check it worked
6. ✅ **Escape properly** - quotes, variables, heredocs
7. ✅ **One block = One task** - atomic, complete operations
8. ✅ **Comments start with #** - consistent style
9. ✅ **Blank lines separate** - visual grouping
10. ✅ **End with verification** - prove it worked

---

## Anti-Patterns (Don't Do This)

❌ **Vague commands**:
```bash
# Bad
Deploy the thing
```

✅ **Specific commands**:
```bash
# Good
cd cloudflare-workers
wrangler deploy blackroad-unified-api.js --config wrangler-unified-api.toml
```

❌ **Manual editing required**:
```bash
# Bad
Edit the config file to add your token
```

✅ **Copy-paste ready**:
```bash
# Good
cat >> .env <<'EOF'
RAILWAY_TOKEN=paste-your-token-here
EOF
```

❌ **No verification**:
```bash
# Bad
railway up
# (did it work? who knows!)
```

✅ **With verification**:
```bash
# Good
railway up --service api-gateway

# Verify deployment
railway status
curl https://api.blackroad.io/health
```

---

## Template Variables

Use these placeholder patterns:

- `[ACTION]` - What's happening
- `[DIRECTORY]` - Path to work in
- `[SERVICE_NAME]` - Name of service
- `[DOMAIN]` - Domain name
- `your-token-here` - Placeholder for secrets
- `paste-your-value-here` - User must fill in

---

## Contributing New Patterns

When you discover a new copy-paste-ready pattern:

1. **Document it** in this file
2. **Test it** thoroughly
3. **Add comments** explaining each step
4. **Include verification** commands
5. **Commit** with descriptive message

```bash
# Add your new pattern to this file
cat >> templates/TERMINAL-COMMANDS-TEMPLATE.md <<'EOF'

### Pattern XX: [Your Pattern Name]

```bash
# [Description]
[commands here]
```
EOF

# Commit
git add templates/TERMINAL-COMMANDS-TEMPLATE.md
git commit -m "docs: Add [Pattern Name] to terminal commands template"
git push origin main
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

---

**Remember**: The best documentation is the kind you can copy, paste, and learn from simultaneously. Every command block should be a perfect, working example that teaches by doing.

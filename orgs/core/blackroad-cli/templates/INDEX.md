# BlackRoad OS Templates

**Copy-Paste-Ready Templates for Everything**

This directory contains templates that make development, deployment, and documentation effortless. Every template follows the **copy-paste-and-learn** philosophy: perfect commands that work immediately and teach by doing.

---

## Available Templates

### 1. Terminal Commands Template
**File**: `TERMINAL-COMMANDS-TEMPLATE.md`

The revolutionary template that changes how we work with terminals. Contains copy-paste-ready command blocks for:
- Cloudflare deployment
- Railway deployment
- Local development
- SSH operations
- File management
- Git workflows
- Environment setup
- Testing
- Docker operations

**Why this matters**: No more nano nightmares, no more mkdir mistakes, no more SSH struggles. Just copy, paste, learn.

**Quick Example**:
```bash
# Deploy complete API
cd cloudflare-workers
wrangler deploy blackroad-unified-api.js --config wrangler-unified-api.toml

# Initialize databases
wrangler d1 execute blackroad-users --file=../cloudflare-d1-schemas.sql

# Deploy edge router
wrangler deploy blackroad-edge-router.js
```

### 2. README Template
**File**: `README-TEMPLATE.md`

Standard README structure with copy-paste-ready sections:
- Quick Start (copy-paste installation)
- Usage examples (copy-paste commands)
- API reference (copy-paste curl commands)
- Deployment (copy-paste deploy blocks)
- Troubleshooting (copy-paste debug commands)

### 3. Deployment Guide Template
**File**: `DEPLOYMENT-GUIDE-TEMPLATE.md`

Complete deployment documentation template with:
- Platform-specific deployment blocks
- Verification commands
- Rollback procedures
- Multi-cloud deployment
- Post-deployment checks

### 4. Script Template
**File**: `SCRIPT-TEMPLATE.sh`

Bash script template with:
- Proper error handling (`set -euo pipefail`)
- Interactive menu mode
- Direct command mode
- Logging
- Color output
- Help documentation
- Copyright headers

### 5. Copy-Paste Commands Library
**File**: `COPY-PASTE-COMMANDS-LIBRARY.md`

The ultimate command reference - organized by category:
- Quick Deployments
- Service Management
- Git Operations
- Environment Setup
- Testing
- Docker
- SSH & Remote
- File Operations
- Debugging
- Security & Secrets
- Emergency Procedures

---

## The Philosophy

### Why Copy-Paste-Ready?

**Before** (traditional docs):
```
To deploy, run the wrangler deploy command with your config file.
```
User has to:
1. Remember syntax
2. Type it correctly
3. Figure out config file path
4. Hope it works

**After** (copy-paste-ready):
```bash
# Deploy complete API
cd cloudflare-workers
wrangler deploy blackroad-unified-api.js --config wrangler-unified-api.toml

# Verify deployment
wrangler pages deployment list --project-name=blackroad-io
```
User:
1. Copies block
2. Pastes in terminal
3. It works perfectly
4. Comments teach what happened

### Benefits

1. **Zero Cognitive Load** - No thinking required, just copy and paste
2. **Self-Documenting** - Comments explain the what AND why
3. **Machine-Teachable** - AI learns from the pattern
4. **Error-Proof** - No manual typing mistakes
5. **Context-Preserved** - Full context in every block
6. **Teaching by Doing** - Learn while executing

---

## How to Use These Templates

### For New Services

1. Copy `README-TEMPLATE.md`
2. Replace placeholders with your service details
3. Test all copy-paste command blocks
4. Ensure every command works perfectly
5. Commit with the service

### For New Scripts

1. Copy `SCRIPT-TEMPLATE.sh`
2. Customize functions for your needs
3. Test interactive menu mode
4. Test direct command mode
5. Make executable: `chmod +x script.sh`

### For Documentation

1. Use `TERMINAL-COMMANDS-TEMPLATE.md` patterns
2. Every command must be copy-paste ready
3. Include comments explaining each step
4. Add verification commands
5. Test before publishing

### For Deployment Guides

1. Copy `DEPLOYMENT-GUIDE-TEMPLATE.md`
2. Fill in platform-specific sections
3. Test every deployment block
4. Include rollback procedures
5. Add verification steps

---

## Template Standards

Every template must follow these rules:

### 1. Comments Explain Everything
```bash
# What this does and why
command --flag value
```

### 2. Commands Work Perfectly
Test every command block before documenting it. No broken examples.

### 3. Full Context Provided
```bash
# Navigate to correct directory
cd ~/blackroad-sandbox/cloudflare-workers

# Deploy with specific config
wrangler deploy service.js --config wrangler-service.toml
```

### 4. Verification Included
```bash
# Deploy
railway up --service api-gateway

# Verify deployment worked
railway status
curl https://api.blackroad.io/health
```

### 5. Grouped Logically
```bash
# Step 1: Setup
command1

# Step 2: Execute
command2

# Step 3: Verify
command3
```

### 6. No Manual Edits Required
Use environment variables or heredocs instead of "edit this file manually":

```bash
# Good - copy-paste ready
cat >> .env <<'EOF'
TOKEN=paste-your-token-here
EOF

# Bad - requires manual editing
# Edit .env and add your token
```

---

## Quick Reference

### Most Common Patterns

**Deploy to Cloudflare**:
```bash
cd cloudflare-workers
wrangler deploy service.js --config wrangler-service.toml
wrangler pages deployment list --project-name=blackroad-io
```

**Deploy to Railway**:
```bash
export RAILWAY_TOKEN=your-token-here
railway link project-id
railway up --service service-name
railway status
```

**Start Local Services**:
```bash
cd ~/blackroad-sandbox
./start-all.sh
./br health
```

**Run Tests**:
```bash
pytest -m unit -v
pytest -m integration -v
pytest --cov=. --cov-report=html
```

---

## Contributing New Templates

When creating a new template:

1. **Follow the philosophy** - Copy-paste-ready with teaching comments
2. **Test thoroughly** - Every command must work perfectly
3. **Document clearly** - Explain what and why
4. **Include verification** - Show how to check it worked
5. **Add to this index** - Update this file with new template

```bash
# Create new template
cat > templates/NEW-TEMPLATE.md <<'EOF'
# Template content here
EOF

# Test the template
# [test steps]

# Update index
cat >> templates/INDEX.md <<'EOF'

### X. New Template Name
**File**: `NEW-TEMPLATE.md`
[Description]
EOF

# Commit
git add templates/
git commit -m "docs: Add new template for [purpose]"
git push origin main
```

---

## Examples in the Wild

These templates are used throughout BlackRoad OS:

- `DEPLOY-QUICK-REFERENCE.md` - Uses deployment patterns
- `TEST_COMMANDS.md` - Uses testing patterns
- `RAILWAY-WEBHOOK-DEPLOYMENT-GUIDE.md` - Uses deployment template
- All `blackroad-*.sh` scripts - Use script template
- All service READMEs - Use README template

---

## Future Templates

Planned templates:

- [ ] API Documentation Template
- [ ] Integration Guide Template
- [ ] Database Migration Template
- [ ] Security Audit Template
- [ ] Performance Testing Template
- [ ] Monitoring Setup Template

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

**Remember**: Great templates are copy-paste-ready, self-documenting, and teach by doing. If someone has to type something manually, the template isn't good enough yet.

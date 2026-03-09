# BlackRoad Automatic Deployment System
## Complete Documentation & Operations Guide

**Version:** 1.0.0
**Last Updated:** December 23, 2025
**Author:** Alexa Amundson + Cecilia

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Deployment Scripts](#deployment-scripts)
4. [Setup Instructions](#setup-instructions)
5. [Usage Guide](#usage-guide)
6. [Troubleshooting](#troubleshooting)
7. [Reference](#reference)

---

## Overview

The BlackRoad Automatic Deployment System orchestrates deployments across:

- **20 domains** (blackroad.io, lucidia.earth, etc.)
- **150+ subdomains**
- **Cloudflare Pages** (production hosting)
- **GitHub Actions** (CI/CD pipelines)
- **Pi Mesh** (3 Raspberry Pi nodes for edge computing)
- **Shellfish iOS** (mobile SSH automation)

### Key Features

✅ **Automatic deployments** on git push
✅ **Preview deployments** for pull requests
✅ **Pi mesh edge deployments** for local services
✅ **Comprehensive testing** (HTTP, SSL, DNS, API, performance)
✅ **Status monitoring** and health checks
✅ **Memory logging** via PS-SHA∞ system

---

## Architecture

### Deployment Flow

```
┌─────────────────┐
│  Git Push       │
│  (main branch)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ GitHub Actions  │
│ - Build         │
│ - Test          │
│ - Lint          │
└────────┬────────┘
         │
         ├──────────────────┬──────────────────┐
         ▼                  ▼                  ▼
┌────────────────┐  ┌──────────────┐  ┌──────────────┐
│ Cloudflare     │  │ Pi Mesh      │  │ Memory Log   │
│ Pages          │  │ (optional)   │  │ PS-SHA∞      │
│ Production     │  │ Edge Deploy  │  │              │
└────────────────┘  └──────────────┘  └──────────────┘
         │
         ▼
┌─────────────────┐
│ Post-Deploy     │
│ Tests           │
│ - Smoke tests   │
│ - Health checks │
└─────────────────┘
```

### Infrastructure Layers

| Layer | Purpose | Technologies |
|-------|---------|-------------|
| **Experience** | User-facing apps | Next.js, React, Cloudflare Pages |
| **Governance** | Policies, ledger | Prism Console, Policy Engine |
| **Mesh** | Pi nodes, edge | Raspberry Pi, Docker, Tailscale |
| **Data** | Storage, cache | PostgreSQL, Redis, R2 |

---

## Deployment Scripts

### 1. Main Deployment Orchestrator

**File:** `~/blackroad-autodeploy-system.sh`

**Purpose:** Master deployment orchestrator for Cloudflare + GitHub + Pi mesh

**Commands:**
```bash
# Deploy specific domain
./blackroad-autodeploy-system.sh deploy app.blackroad.io

# Deploy all domains
./blackroad-autodeploy-system.sh deploy-all

# Check status
./blackroad-autodeploy-system.sh status

# Test deployment
./blackroad-autodeploy-system.sh test lucidia.earth

# Test all
./blackroad-autodeploy-system.sh test-all

# List Cloudflare Pages projects
./blackroad-autodeploy-system.sh cf-pages

# Check Pi nodes
./blackroad-autodeploy-system.sh pi-health

# Deploy to Pi
./blackroad-autodeploy-system.sh pi-deploy lucidia blackroad-os-web /path/to/repo
```

### 2. Shellfish Pi Deployment

**File:** `~/shellfish-pi-deploy.sh`

**Purpose:** SSH automation for Pi mesh deployments (optimized for iOS Shellfish app)

**Commands:**
```bash
# Quick deploy (auto-detects repo path)
./shellfish-pi-deploy.sh quick-deploy blackroad-os-web

# Test all Pi connections
./shellfish-pi-deploy.sh test-all

# Deploy to specific Pi
./shellfish-pi-deploy.sh deploy lucidia blackroad-os-web /path/to/repo

# Service management
./shellfish-pi-deploy.sh start lucidia blackroad-os-web
./shellfish-pi-deploy.sh stop lucidia blackroad-os-web
./shellfish-pi-deploy.sh restart lucidia blackroad-os-web

# View logs
./shellfish-pi-deploy.sh logs lucidia blackroad-os-web 100

# Pi status
./shellfish-pi-deploy.sh pi-status lucidia
./shellfish-pi-deploy.sh status-all

# Auto-deploy on file changes
./shellfish-pi-deploy.sh watch blackroad-os-web lucidia
```

### 3. Deployment Testing

**File:** `~/test-deployments.sh`

**Purpose:** Comprehensive testing for all deployments

**Commands:**
```bash
# Run all tests
./test-deployments.sh all

# Test domains only
./test-deployments.sh domains

# Test Pi nodes only
./test-deployments.sh pi

# Test API endpoints
./test-deployments.sh api

# Smoke tests (critical paths only)
./test-deployments.sh smoke

# Continuous monitoring (every 5 minutes)
./test-deployments.sh monitor 300

# Performance test specific URL
./test-deployments.sh perf https://app.blackroad.io
```

### 4. GitHub Actions Workflow

**File:** `~/github-workflow-deploy.yml`

**Purpose:** Template for GitHub Actions CI/CD

**Features:**
- Automatic builds on push
- Preview deployments for PRs
- Cloudflare Pages integration
- Pi mesh deployment (optional, with `[deploy-pi]` in commit message)
- Post-deployment testing
- Memory logging

**Setup per repository:**
```bash
# Copy workflow to repo
mkdir -p .github/workflows
cp ~/github-workflow-deploy.yml .github/workflows/deploy.yml

# Set GitHub secrets
gh secret set CLOUDFLARE_API_TOKEN -b"$CF_TOKEN"
gh secret set CLOUDFLARE_ACCOUNT_ID -b"463024cf9efed5e7b40c5fbe7938e256"
gh secret set CLOUDFLARE_PROJECT_NAME -b"your-project-name"
gh secret set PRODUCTION_DOMAIN -b"your-domain.com"

# Optional: Pi deployment
gh secret set PI_SSH_KEY -b"$(cat ~/.ssh/id_rsa)"
gh secret set PI_HOST -b"192.168.4.38"
```

---

## Setup Instructions

### Prerequisites

1. **Cloudflare Account**
   - Account ID: `463024cf9efed5e7b40c5fbe7938e256`
   - API Token: Set in `CF_TOKEN` env var

2. **GitHub Access**
   - Organization: `BlackRoad-OS`
   - GitHub CLI installed (`gh`)

3. **Pi Mesh**
   - 3 Raspberry Pi nodes configured
   - SSH access configured
   - Docker installed on each Pi

4. **Local Tools**
   - `curl`, `jq`, `ssh`, `rsync`
   - Node.js 20+
   - Python 3.14+

### Initial Setup

#### 1. Configure Environment Variables

Create `~/.blackroad-deploy-env`:
```bash
export CF_TOKEN="yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy"
export CLOUDFLARE_ACCOUNT_ID="463024cf9efed5e7b40c5fbe7938e256"
export GITHUB_ORG="BlackRoad-OS"
export PI_USER="pi"
```

Source it:
```bash
source ~/.blackroad-deploy-env
```

#### 2. Configure SSH for Pi Nodes

Add to `~/.ssh/config`:
```
Host lucidia
    HostName 192.168.4.38
    User pi
    IdentityFile ~/.ssh/id_rsa

Host blackroad-pi
    HostName 192.168.4.64
    User pi
    IdentityFile ~/.ssh/id_rsa

Host lucidia-alt
    HostName 192.168.4.99
    User pi
    IdentityFile ~/.ssh/id_rsa
```

Test connection:
```bash
ssh lucidia "echo 'Connected!'"
```

#### 3. Set Up Cloudflare Pages Projects

For each domain, create a Pages project:
```bash
./blackroad-autodeploy-system.sh deploy app.blackroad.io
```

This will:
- Create Cloudflare Pages project
- Add custom domain
- Configure DNS records
- Set up GitHub secrets

#### 4. Add GitHub Workflows

For each repository:
```bash
cd /path/to/repo
mkdir -p .github/workflows
cp ~/github-workflow-deploy.yml .github/workflows/deploy.yml

# Configure secrets
gh secret set CLOUDFLARE_API_TOKEN -b"$CF_TOKEN"
gh secret set CLOUDFLARE_ACCOUNT_ID -b"$CLOUDFLARE_ACCOUNT_ID"
gh secret set CLOUDFLARE_PROJECT_NAME -b"app-blackroad-io"
gh secret set PRODUCTION_DOMAIN -b"app.blackroad.io"
```

---

## Usage Guide

### Deploying a New Domain

1. **Create repository** (if needed):
```bash
gh repo create BlackRoad-OS/new-service --public
```

2. **Configure deployment**:
```bash
./blackroad-autodeploy-system.sh deploy new-domain.blackroad.io
```

3. **Add workflow to repository**:
```bash
cd /path/to/new-service
cp ~/github-workflow-deploy.yml .github/workflows/deploy.yml
git add .github/workflows/deploy.yml
git commit -m "Add deployment workflow"
git push
```

4. **Test deployment**:
```bash
./test-deployments.sh smoke
```

### Deploying to Pi Mesh

#### From Desktop:
```bash
# Quick deploy (auto-detects repo path)
./shellfish-pi-deploy.sh quick-deploy blackroad-os-web

# Or specify everything
./shellfish-pi-deploy.sh deploy lucidia blackroad-os-web /Users/alexa/projects/blackroad-os-web
```

#### From Shellfish (iOS):
```bash
# Navigate to repo directory in Shellfish
cd ~/projects/blackroad-os-web

# Quick deploy
~/shellfish-pi-deploy.sh quick-deploy blackroad-os-web
```

#### Automatic Pi Deployment via GitHub Actions:

Add `[deploy-pi]` to commit message:
```bash
git commit -m "Update homepage [deploy-pi]"
git push
```

### Running Tests

#### Smoke Test (Quick):
```bash
./test-deployments.sh smoke
```

#### Full Test Suite:
```bash
./test-deployments.sh all
```

#### Continuous Monitoring:
```bash
# Check every 5 minutes
./test-deployments.sh monitor 300
```

### Checking Status

#### Deployment Status:
```bash
./blackroad-autodeploy-system.sh status
```

#### Pi Mesh Status:
```bash
./shellfish-pi-deploy.sh status-all
```

#### GitHub Actions Status:
```bash
gh run list --repo BlackRoad-OS/blackroad-os-web
```

---

## Troubleshooting

### Common Issues

#### 1. Cloudflare API Errors

**Problem:** `Missing X-Auth-Key, X-Auth-Email or Authorization headers`

**Solution:**
```bash
# Verify token is set
echo $CF_TOKEN

# If empty, set it
export CF_TOKEN="yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy"

# Or source env file
source ~/.blackroad-deploy-env
```

#### 2. Pi Node Unreachable

**Problem:** Cannot SSH to Pi node

**Solutions:**
```bash
# Test connection
ping 192.168.4.38

# Test SSH
ssh -v pi@192.168.4.38

# Check SSH key
ls -la ~/.ssh/id_rsa

# Regenerate SSH keys if needed
ssh-keygen -t rsa -b 4096 -C "blackroad-deploy"
ssh-copy-id pi@192.168.4.38
```

#### 3. Build Failures

**Problem:** GitHub Actions build fails

**Solutions:**
```bash
# Test build locally
npm ci
npm run build

# Check Node version
node --version  # Should be 20+

# View GitHub Actions logs
gh run view --repo BlackRoad-OS/your-repo
```

#### 4. DNS Not Resolving

**Problem:** Domain doesn't resolve

**Solutions:**
```bash
# Check DNS
dig +short your-domain.com

# Check Cloudflare zone
./blackroad-autodeploy-system.sh status

# Manually create DNS record
# (Use Cloudflare dashboard or API)
```

#### 5. Deployment Stuck

**Problem:** Deployment hangs or times out

**Solutions:**
```bash
# Check Cloudflare Pages status
./blackroad-autodeploy-system.sh cf-pages

# Check GitHub Actions
gh run list --repo BlackRoad-OS/your-repo

# Re-trigger deployment
gh workflow run deploy.yml --repo BlackRoad-OS/your-repo
```

### Debug Mode

Enable verbose output:
```bash
# For deployment script
bash -x ~/blackroad-autodeploy-system.sh deploy app.blackroad.io

# For Pi deployment
bash -x ~/shellfish-pi-deploy.sh quick-deploy blackroad-os-web

# For tests
bash -x ~/test-deployments.sh smoke
```

---

## Reference

### Domain → Repository Mapping

| Domain | Repository | Cloudflare Project |
|--------|-----------|-------------------|
| blackroad.io | blackroad-os-home | blackroad-io |
| app.blackroad.io | blackroad-os-web | app-blackroad-io |
| console.blackroad.io | blackroad-os-prism-console | console-blackroad-io |
| docs.blackroad.io | blackroad-os-docs | docs-blackroad-io |
| api.blackroad.io | blackroad-os-api | api-blackroad-io |
| lucidia.earth | lucidia-earth-website | lucidia-earth |
| app.lucidia.earth | blackroad-os-web | app-lucidia-earth |
| finance.blackroad.io | blackroad-os-pack-finance | finance-blackroad-io |
| edu.blackroad.io | blackroad-os-pack-education | edu-blackroad-io |
| studio.blackroad.io | blackroad-os-pack-creator-studio | studio-blackroad-io |
| lab.blackroad.io | blackroad-os-pack-research-lab | lab-blackroad-io |

### Pi Nodes

| Name | IP Address | Purpose |
|------|-----------|---------|
| lucidia | 192.168.4.38 | Primary Pi 5 node |
| blackroad-pi | 192.168.4.64 | Secondary Pi 5 node |
| lucidia-alt | 192.168.4.99 | Tertiary Pi node |
| iphone-koder | 192.168.4.68:8080 | iPhone dev server |

### Cloudflare Zones

| Zone | Zone ID |
|------|---------|
| lucidia.earth | 848cf0b18d51e0170e0d1537aec3505a |
| blackroad.io | TBD |
| blackroad.systems | TBD |

### Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `CF_TOKEN` | Cloudflare API token | `yP5h0H...` |
| `CLOUDFLARE_ACCOUNT_ID` | CF account ID | `463024cf...` |
| `GITHUB_ORG` | GitHub organization | `BlackRoad-OS` |
| `PI_USER` | Pi SSH username | `pi` |
| `SSH_KEY` | SSH key path | `~/.ssh/id_rsa` |

### Test Coverage

| Test Type | Command | Coverage |
|-----------|---------|----------|
| HTTP | `curl -I https://...` | All domains |
| SSL | `openssl s_client` | All domains |
| DNS | `dig +short` | All domains |
| API | `curl /health` | API endpoints |
| Pi | `ssh pi@...` | 3 Pi nodes |
| Performance | `curl -w timing` | All domains |

---

## Quick Reference

### Most Common Commands

```bash
# Deploy everything
./blackroad-autodeploy-system.sh deploy-all

# Test everything
./test-deployments.sh all

# Check status
./blackroad-autodeploy-system.sh status
./shellfish-pi-deploy.sh status-all

# Deploy to Pi from Shellfish
~/shellfish-pi-deploy.sh quick-deploy blackroad-os-web

# View Pi logs
./shellfish-pi-deploy.sh logs lucidia blackroad-os-web

# Continuous monitoring
./test-deployments.sh monitor 300
```

### Emergency Procedures

#### 1. Complete System Down

```bash
# Check all services
./test-deployments.sh smoke

# Restart Pi nodes
for pi in lucidia blackroad-pi lucidia-alt; do
  ssh $pi "sudo reboot"
done

# Re-deploy critical services
./blackroad-autodeploy-system.sh deploy app.blackroad.io
./blackroad-autodeploy-system.sh deploy lucidia.earth
```

#### 2. Single Domain Down

```bash
# Test domain
./test-deployments.sh smoke

# Check Cloudflare Pages
./blackroad-autodeploy-system.sh cf-pages

# Re-deploy
./blackroad-autodeploy-system.sh deploy your-domain.com
```

#### 3. Pi Node Down

```bash
# Test connectivity
./shellfish-pi-deploy.sh test lucidia

# If unreachable, physically check Pi
# Then redeploy services
./shellfish-pi-deploy.sh deploy lucidia blackroad-os-web /path/to/repo
```

---

## Memory Logging

All deployments are logged to the PS-SHA∞ memory system:

```bash
# Log deployment
~/memory-system.sh log deployed "app.blackroad.io" "version: $(git rev-parse --short HEAD)"

# View deployment history
~/memory-system.sh export
```

---

## Support

- **GitHub Issues:** https://github.com/BlackRoad-OS/blackroad-os-infra/issues
- **Email:** blackroad.systems@gmail.com
- **Documentation:** https://docs.blackroad.io

---

**The road remembers everything. So should our deployments.** 🛣️

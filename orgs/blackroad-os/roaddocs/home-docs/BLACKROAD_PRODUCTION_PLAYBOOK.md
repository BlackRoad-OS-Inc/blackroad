# BlackRoad Production-Ready Automation Playbook

**Version:** 1.0.0
**Last Updated:** 2025-12-27
**Goal:** All BlackRoad-OS repos are production-ready, automated, and boringly reliable

---

## 🎯 Overview

This playbook contains everything needed to achieve **100% reliable, automated deployments** across all BlackRoad infrastructure:

- 82+ GitHub repositories
- 15+ GitHub organizations
- Cloudflare Pages (16 zones, 8 Pages projects)
- Railway (12+ projects)
- Raspberry Pi devices (lucidia, blackroad-pi)
- Port 8080 services

---

## 📦 Components

### 1. E2E Testing Suite
**Location:** `~/blackroad-e2e-testing-suite.sh`

**Purpose:** Comprehensive testing of all infrastructure components

**Features:**
- GitHub connectivity tests
- Cloudflare authentication tests
- Pi device health checks
- Port 8080 service verification
- Memory system validation
- Git workflow tests
- Node.js toolchain tests
- Docker environment tests

**Usage:**
```bash
# Run all tests once
~/blackroad-e2e-testing-suite.sh

# View test logs
cat ~/.blackroad/e2e-tests/e2e-test-*.log
```

**Test Results:**
- ✅ GitHub: Authenticated, 4 orgs, 82 repos
- ✅ Cloudflare: Connected
- ⚠️  Pi Devices: 2/3 online (lucidia ✅, blackroad-pi ✅, alt ❌)
- ❌ Port 8080: Services offline

---

### 2. Real-Time Monitoring Dashboard
**Location:** `~/blackroad-realtime-monitor.sh`

**Purpose:** Live monitoring of all infrastructure

**Features:**
- Real-time status display
- JSON state export
- Historical tracking
- Component-specific checks
- 30-second refresh (configurable)

**Usage:**
```bash
# Start continuous monitoring
~/blackroad-realtime-monitor.sh monitor 30

# Single status check
~/blackroad-realtime-monitor.sh once

# Export current state as JSON
~/blackroad-realtime-monitor.sh export

# Check specific component
~/blackroad-realtime-monitor.sh check github
~/blackroad-realtime-monitor.sh check pi-lucidia

# View history
~/blackroad-realtime-monitor.sh history 10
```

**State Storage:**
- Current state: `~/.blackroad/monitor/state.json`
- History: `~/.blackroad/monitor/history.jsonl`

---

### 3. Automated Health Checks
**Location:** `~/blackroad-health-checks.sh`

**Purpose:** Continuous health monitoring with alerting

**Features:**
- Configurable health checks
- Alert generation on failures
- Email/Slack/Discord notifications (configurable)
- Deployment verification for Git → Cloudflare → Pi flows
- Auto-retry with backoff

**Usage:**
```bash
# Initialize health check system
~/blackroad-health-checks.sh init

# Run checks once
~/blackroad-health-checks.sh check

# Continuous monitoring
~/blackroad-health-checks.sh monitor 60

# Verify deployments
~/blackroad-health-checks.sh verify-cloudflare BlackRoad-OS/repo abc1234
~/blackroad-health-checks.sh verify-pi 192.168.4.38 service-name

# View recent alerts
~/blackroad-health-checks.sh alerts 10
```

**Configuration:**
Edit `~/.blackroad/health/config.json` to configure:
- Check intervals
- Critical vs non-critical checks
- Alerting channels
- Deployment pipeline settings

---

### 4. Deployment Verification & Rollback Suite
**Location:** `~/blackroad-deployment-verifier.sh`

**Purpose:** Track, verify, and rollback deployments

**Features:**
- Deployment tracking across platforms
- Automated verification
- One-click rollback to previous working state
- Deployment history
- Platform-agnostic design

**Usage:**
```bash
# Record a deployment
~/blackroad-deployment-verifier.sh record github "BlackRoad-OS/repo" abc1234 success

# Verify deployment
~/blackroad-deployment-verifier.sh verify deploy-1234567-8901

# Rollback deployment
~/blackroad-deployment-verifier.sh rollback deploy-1234567-8901

# List recent deployments
~/blackroad-deployment-verifier.sh list 10

# Deploy and verify in one step
~/blackroad-deployment-verifier.sh deploy cloudflare my-project abc1234 true
```

**Supported Platforms:**
- `github` - GitHub repositories
- `cloudflare` - Cloudflare Pages
- `pi` - Raspberry Pi devices
- `railway` - Railway projects

**State Storage:**
- Deployment history: `~/.blackroad/deployments/history/`
- Rollback records: `~/.blackroad/deployments/rollbacks/`

---

### 5. Master Deployment Orchestrator
**Location:** `~/blackroad-deploy-orchestrator.sh`

**Purpose:** Unified interface for all deployment operations

**Features:**
- One command to deploy anywhere
- Integrated testing and verification
- Real-time monitoring
- Health check integration
- Rollback capabilities

**Usage:**
```bash
# Install all automation scripts
~/blackroad-deploy-orchestrator.sh install

# Run E2E tests
~/blackroad-deploy-orchestrator.sh test

# Run health checks
~/blackroad-deploy-orchestrator.sh health

# Deploy to specific platform
~/blackroad-deploy-orchestrator.sh deploy cloudflare my-project
~/blackroad-deploy-orchestrator.sh deploy github BlackRoad-OS/repo
~/blackroad-deploy-orchestrator.sh deploy pi lucidia
~/blackroad-deploy-orchestrator.sh deploy railway my-service

# Deploy everywhere
~/blackroad-deploy-orchestrator.sh deploy-all my-project

# Start monitoring
~/blackroad-deploy-orchestrator.sh monitor

# Show infrastructure status
~/blackroad-deploy-orchestrator.sh status

# Verify deployment
~/blackroad-deploy-orchestrator.sh verify deploy-1234567-8901

# Rollback deployment
~/blackroad-deploy-orchestrator.sh rollback deploy-1234567-8901
```

---

## 🔄 CI/CD Templates

### Cloudflare Pages
**Location:** `/tmp/ci-cd-templates/cloudflare-pages.yml`

Copy to: `.github/workflows/deploy-cloudflare.yml`

**Features:**
- Quality checks (lint, type-check, tests)
- Build and artifact management
- Cloudflare Pages deployment
- Post-deployment verification
- Health checks
- Failure notifications

**Required Secrets:**
- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`

---

### Railway Deployment
**Location:** `/tmp/ci-cd-templates/railway-deploy.yml`

Copy to: `.github/workflows/deploy-railway.yml`

**Features:**
- Pre-deployment testing
- Railway CLI deployment
- Deployment URL extraction
- Health check verification

**Required Secrets:**
- `RAILWAY_TOKEN`
- `RAILWAY_PROJECT_ID`

---

### Raspberry Pi Deployment
**Location:** `/tmp/ci-cd-templates/pi-deployment.yml`

Copy to: `.github/workflows/deploy-pi.yml`

**Features:**
- Multi-target deployment (lucidia, blackroad-pi, or all)
- SSH-based deployment
- Rsync file sync
- Systemd service restart
- Deployment verification

**Required Secrets:**
- `PI_SSH_KEY`

---

## 🚀 Quick Start Guide

### 1. Initial Setup (One-Time)

```bash
# Install all automation scripts
cd /tmp
chmod +x blackroad-deploy-orchestrator.sh
./blackroad-deploy-orchestrator.sh install

# Initialize health monitoring
~/blackroad-health-checks.sh init

# Run initial E2E tests
~/blackroad-e2e-testing-suite.sh
```

### 2. Daily Operations

```bash
# Morning: Check infrastructure health
~/blackroad-deploy-orchestrator.sh status

# Deploy changes
cd your-repo
git add .
git commit -m "feat: new feature"
git push

# Verify deployment
~/blackroad-deploy-orchestrator.sh verify <deployment-id>

# Monitor in real-time (optional)
~/blackroad-deploy-orchestrator.sh monitor
```

### 3. Emergency Response

```bash
# Deployment failed? Rollback immediately
~/blackroad-deploy-orchestrator.sh rollback <deployment-id>

# Check what's failing
~/blackroad-health-checks.sh check

# View recent alerts
~/blackroad-health-checks.sh alerts
```

---

## 📊 Production Standards

### All BlackRoad-OS Repos Must Have:

1. **CI/CD Pipeline**
   - GitHub Actions workflow (use templates above)
   - Automated testing on PR
   - Automated deployment on merge to main

2. **Health Checks**
   - `/health` endpoint (for services)
   - Automated monitoring
   - Alerting on failures

3. **Deployment Verification**
   - Post-deployment tests
   - Rollback capability
   - Deployment tracking

4. **Documentation**
   - README with setup instructions
   - DEPLOYMENT.md with deployment guide
   - Architecture documentation

5. **Testing**
   - Unit tests (>70% coverage)
   - Integration tests
   - E2E tests for critical paths

---

## 🔧 Platform-Specific Setup

### GitHub Repositories

**Required Secrets:**
- None (uses `GITHUB_TOKEN` automatically)

**Setup:**
1. Copy workflow template to `.github/workflows/`
2. Ensure tests pass locally
3. Push to trigger workflow

---

### Cloudflare Pages

**Required Secrets:**
- `CLOUDFLARE_API_TOKEN` - Get from Cloudflare dashboard
- `CLOUDFLARE_ACCOUNT_ID` - Found in Cloudflare dashboard

**Setup:**
1. Create Cloudflare Pages project
2. Add secrets to GitHub repo
3. Copy workflow template
4. Configure build settings in workflow

---

### Railway

**Required Secrets:**
- `RAILWAY_TOKEN` - Get from Railway dashboard
- `RAILWAY_PROJECT_ID` - Railway project ID

**Setup:**
1. Create Railway project
2. Link project: `railway link`
3. Get project ID: `railway status`
4. Add secrets to GitHub repo

---

### Raspberry Pi

**Required Secrets:**
- `PI_SSH_KEY` - SSH private key for Pi access

**Setup:**
1. Generate SSH key: `ssh-keygen -t ed25519 -C "github-actions"`
2. Add public key to Pi: `~/.ssh/authorized_keys`
3. Add private key to GitHub secrets
4. Test SSH: `ssh -i key pi@192.168.4.38`

---

## 📈 Monitoring & Alerting

### Current Infrastructure Status

```bash
# Real-time dashboard
~/blackroad-realtime-monitor.sh monitor 30
```

**Monitored Components:**
- ✅ GitHub (4 orgs, 82 repos)
- ✅ Cloudflare (authenticated)
- ✅ Memory System (482 entries)
- ✅ Pi Lucidia (192.168.4.38)
- ✅ Pi BlackRoad (192.168.4.64)
- ❌ Pi Alt (192.168.4.99) - offline
- ❌ Port 8080 services - offline

### Alert Channels

Configure in `~/.blackroad/health/config.json`:

```json
{
  "alerting": {
    "enabled": true,
    "email": "blackroad.systems@gmail.com",
    "slack_webhook": "",
    "discord_webhook": ""
  }
}
```

---

## 🎓 Best Practices

### 1. Always Test Before Deploy
```bash
# Run E2E tests
~/blackroad-e2e-testing-suite.sh

# Run health checks
~/blackroad-health-checks.sh check
```

### 2. Verify Every Deployment
```bash
# Deploy with verification
~/blackroad-deploy-orchestrator.sh deploy cloudflare my-project

# Manual verification
~/blackroad-deploy-orchestrator.sh verify <deployment-id>
```

### 3. Monitor Continuously
```bash
# Terminal 1: Monitoring
~/blackroad-realtime-monitor.sh monitor 30

# Terminal 2: Health checks
~/blackroad-health-checks.sh monitor 60
```

### 4. Keep Rollback Ready
```bash
# Every deployment is tracked
~/blackroad-deployment-verifier.sh list

# Rollback anytime
~/blackroad-deploy-orchestrator.sh rollback <deployment-id>
```

### 5. Log Everything
All operations are logged:
- E2E tests: `~/.blackroad/e2e-tests/`
- Monitoring: `~/.blackroad/monitor/`
- Health checks: `~/.blackroad/health/`
- Deployments: `~/.blackroad/deployments/`

---

## 🔐 Security Considerations

### Secrets Management
- Never commit secrets to git
- Use GitHub Secrets for CI/CD
- Rotate tokens regularly
- Audit access logs

### SSH Keys
- Use ed25519 keys
- One key per purpose
- Restrict key permissions (600)
- Monitor authorized_keys

### API Tokens
- Minimum required scopes
- Time-limited when possible
- Monitor API usage
- Revoke unused tokens

---

## 📝 Notion Integration (Coming Soon)

Track deployment status in Notion:

**Planned Features:**
- Deployment dashboard
- Real-time status sync
- Alert notifications
- Deployment history
- Rollback tracking

**Database Structure:**
```
Deployments Database:
- ID
- Platform
- Target
- Commit SHA
- Status
- Timestamp
- Verification Result
- Rollback Info
```

---

## 🚦 Traffic Light System

Visual status indicators for all components:

- 🟢 **Green**: Healthy, no action needed
- 🟡 **Yellow**: Warning, monitor closely
- 🔴 **Red**: Critical, immediate attention required
- ⚫ **Black**: Offline, not reachable

---

## 📞 Support & Troubleshooting

### Common Issues

**1. GitHub Authentication Failed**
```bash
# Re-authenticate
gh auth login

# Check status
gh auth status
```

**2. Cloudflare Deployment Failed**
```bash
# Re-authenticate
wrangler login

# Check status
wrangler whoami
```

**3. Pi Device Unreachable**
```bash
# Check network
ping 192.168.4.38

# Check SSH
ssh pi@192.168.4.38

# View logs
~/blackroad-health-checks.sh alerts
```

**4. Deployment Verification Failed**
```bash
# Check deployment logs
cat ~/.blackroad/deployments/history/*.json

# Manual verification
~/blackroad-deploy-orchestrator.sh status

# Rollback if needed
~/blackroad-deploy-orchestrator.sh rollback <deployment-id>
```

### Getting Help

- **Memory System:** `~/memory-system.sh summary`
- **Issues:** blackroad.systems@gmail.com
- **Logs:** `~/.blackroad/`

---

## 🎯 Roadmap

### Phase 1: Foundation ✅
- [x] E2E testing suite
- [x] Real-time monitoring
- [x] Health checks
- [x] Deployment verification
- [x] CI/CD templates

### Phase 2: Automation (In Progress)
- [ ] Notion integration
- [ ] Automated alerting (Slack/Discord)
- [ ] Auto-rollback on failures
- [ ] Performance monitoring
- [ ] Cost tracking

### Phase 3: Intelligence (Planned)
- [ ] Predictive failure detection
- [ ] Automatic optimization
- [ ] AI-powered troubleshooting
- [ ] Self-healing infrastructure
- [ ] Capacity planning

---

## 📜 License

All BlackRoad automation scripts are proprietary to BlackRoad Systems.

**Contact:** blackroad.systems@gmail.com
**Documentation:** This playbook
**Version:** 1.0.0

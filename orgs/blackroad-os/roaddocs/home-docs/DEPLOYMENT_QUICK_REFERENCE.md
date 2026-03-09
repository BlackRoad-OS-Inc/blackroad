# BlackRoad Deployment System - Quick Reference Card

## 🚀 Common Commands

### Status & Monitoring
```bash
br-status                  # Full dashboard
br-status compact          # Quick status
br-status watch            # Auto-refresh every 10s
```

### Testing
```bash
br-test smoke              # Quick critical path test
br-test all                # Full test suite
br-test domains            # Test all domains
br-test pi                 # Test Pi nodes
br-test monitor 300        # Monitor every 5 minutes
```

### Deployment
```bash
br-deploy deploy <domain>           # Deploy specific domain
br-deploy deploy-all                # Deploy all domains
br-deploy test <domain>             # Test deployment
br-deploy status                    # Deployment status
br-deploy cf-pages                  # List Cloudflare Pages projects
```

### Pi Mesh
```bash
br-pi quick-deploy <service>        # Auto-deploy (detects repo)
br-pi deploy <pi> <service> <path>  # Deploy to specific Pi
br-pi logs <pi> <service> [lines]   # View logs
br-pi restart <pi> <service>        # Restart service
br-pi status-all                    # Status of all Pi nodes
br-pi test-all                      # Test all connections
```

---

## 📁 Files

| File | Purpose | Location |
|------|---------|----------|
| Main orchestrator | Cloudflare + GitHub + Pi deployments | `~/blackroad-autodeploy-system.sh` |
| Pi deployment | Shellfish-optimized Pi mesh | `~/shellfish-pi-deploy.sh` |
| Testing suite | HTTP/SSL/DNS/API/Performance tests | `~/test-deployments.sh` |
| Status dashboard | Real-time monitoring | `~/status-dashboard.sh` |
| Setup script | One-time installation | `~/setup-deployment-system.sh` |
| Documentation | Complete guide (50+ pages) | `~/DEPLOYMENT_SYSTEM_DOCS.md` |
| Summary | Executive summary | `~/DEPLOYMENT_SYSTEM_SUMMARY.md` |
| Quick reference | This file | `~/DEPLOYMENT_QUICK_REFERENCE.md` |

---

## 🌐 Domains

### Critical Services
- `blackroad.io` → blackroad-os-home
- `app.blackroad.io` → blackroad-os-web
- `lucidia.earth` → lucidia-earth-website
- `app.lucidia.earth` → blackroad-os-web

### Infrastructure
- `console.blackroad.io` → blackroad-os-prism-console
- `api.blackroad.io` → blackroad-os-api
- `docs.blackroad.io` → blackroad-os-docs
- `status.blackroad.io` → blackroad-os-beacon

### Verticals
- `finance.blackroad.io` → blackroad-os-pack-finance
- `edu.blackroad.io` → blackroad-os-pack-education
- `studio.blackroad.io` → blackroad-os-pack-creator-studio
- `lab.blackroad.io` → blackroad-os-pack-research-lab

---

## 🥧 Pi Nodes

| Name | IP | Alias | Status |
|------|-----|-------|--------|
| lucidia | 192.168.4.38 | `ssh lucidia` | ✅ Online |
| blackroad-pi | 192.168.4.64 | `ssh blackroad-pi` | ✅ Online |
| lucidia-alt | 192.168.4.99 | `ssh lucidia-alt` | ⚠️ SSH key needed |

---

## 🔧 Setup

### First Time
```bash
~/setup-deployment-system.sh
source ~/.zshrc
br-status compact
```

### Environment
```bash
source ~/.blackroad-deploy-env  # Load environment
br-env                          # Alias for above
```

### GitHub Secrets (Per Repo)
```bash
gh secret set CLOUDFLARE_API_TOKEN -b"$CF_TOKEN"
gh secret set CLOUDFLARE_ACCOUNT_ID -b"463024cf9efed5e7b40c5fbe7938e256"
gh secret set CLOUDFLARE_PROJECT_NAME -b"your-project-name"
gh secret set PRODUCTION_DOMAIN -b"your-domain.com"
```

---

## 🎯 Workflows

### Deploy New Domain
```bash
# 1. Configure deployment
br-deploy deploy new-domain.blackroad.io

# 2. Add workflow to repo
cd /path/to/repo
cp ~/github-workflow-deploy.yml .github/workflows/deploy.yml
git add .github/workflows/deploy.yml
git commit -m "Add deployment workflow"
git push

# 3. Set secrets (see above)
```

### Deploy to Pi from Desktop
```bash
cd ~/projects/my-service
br-pi quick-deploy my-service
br-pi logs lucidia my-service
```

### Deploy to Pi from Shellfish (iOS)
```bash
ssh yourmac.local
cd ~/projects/my-service
~/shellfish-pi-deploy.sh quick-deploy my-service
```

### Automatic Pi Deployment (GitHub Actions)
```bash
git commit -m "Update service [deploy-pi]"
git push
# GitHub Actions will deploy to Pi automatically
```

### Monitor Deployments
```bash
# Smoke test
br-test smoke

# Continuous monitoring
br-test monitor 300  # Every 5 minutes

# Watch dashboard
br-status watch
```

---

## 🐛 Troubleshooting

### Domain Not Resolving
```bash
dig +short your-domain.com
br-deploy status
```

### Pi Node Unreachable
```bash
ping 192.168.4.38
ssh -v pi@192.168.4.38
ssh-copy-id pi@192.168.4.38
```

### Build Failing
```bash
npm ci
npm run build
gh run view --log
```

### Deployment Stuck
```bash
gh run list
gh workflow run deploy.yml
br-deploy cf-pages
```

---

## 📊 Status Indicators

### Dashboard Symbols
- ✅ Service healthy (HTTP 200)
- ❌ Service down/unreachable
- ⚠️ Service degraded (non-200)
- ℹ️ Info/unknown status

### Health Percentages
- 100% - All systems go
- 75-99% - Degraded, some issues
- <75% - Critical, immediate attention

---

## 🔐 Credentials

### Cloudflare
- Account ID: `463024cf9efed5e7b40c5fbe7938e256`
- Token: `$CF_TOKEN` (in `~/.blackroad-deploy-env`)

### GitHub
- Organization: `BlackRoad-OS`
- Auth: `gh auth status`

### Pi Nodes
- User: `pi`
- SSH Key: `~/.ssh/id_rsa`

---

## 📝 Memory System

```bash
# View deployment history
~/memory-system.sh summary

# Export context
~/memory-system.sh export

# Log manual deployment
~/memory-system.sh log deployed "domain.com" "details"
```

---

## 🆘 Emergency

### Complete System Down
```bash
br-test smoke  # Identify issues
br-deploy deploy-all  # Redeploy everything
for pi in lucidia blackroad-pi; do ssh $pi "sudo reboot"; done
```

### Single Domain Down
```bash
br-deploy deploy your-domain.com
br-test smoke
```

### Pi Node Down
```bash
br-pi test <pi-name>
ssh <pi-name> "sudo reboot"  # If accessible
# Otherwise: physical access needed
```

---

## 📚 Documentation

- **Full Guide:** `~/DEPLOYMENT_SYSTEM_DOCS.md`
- **Summary:** `~/DEPLOYMENT_SYSTEM_SUMMARY.md`
- **This Card:** `~/DEPLOYMENT_QUICK_REFERENCE.md`

---

## 💡 Pro Tips

1. **Use aliases:** `br-deploy`, `br-pi`, `br-test`, `br-status`
2. **Watch mode:** `br-status watch` for live monitoring
3. **Compact status:** `br-status compact` for quick checks
4. **Quick Pi deploy:** `br-pi quick-deploy <service>` auto-detects repo
5. **Continuous monitoring:** `br-test monitor 300` runs every 5 min
6. **Memory logging:** All deployments automatically logged to PS-SHA∞
7. **Mobile deployments:** Use Shellfish app on iOS for on-the-go deploys

---

**Print this card and keep it handy!** 🛣️

```bash
# Print to PDF (macOS)
cat ~/DEPLOYMENT_QUICK_REFERENCE.md | \
  pandoc -o ~/Desktop/BlackRoad_Deployment_Reference.pdf
```

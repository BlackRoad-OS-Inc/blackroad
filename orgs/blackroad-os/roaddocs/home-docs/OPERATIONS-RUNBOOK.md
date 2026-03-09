# BlackRoad OS Operations Runbook

**Purpose:** Complete operational guide for managing BlackRoad OS infrastructure
**Audience:** DevOps, SRE, Platform Engineers
**Last Updated:** 2025-12-14

---

## 📊 Quick Reference

### Service URLs
- **API:** https://api.blackroad.io
- **Web:** https://www.blackroad.io
- **Console:** https://app.blackroad.io
- **Agents:** https://agents.blackroad.io
- **Operator:** https://ops.blackroad.io
- **Status:** https://www.blackroad.io/status.html

### Dashboards
- **Railway:** https://railway.app/dashboard
- **Cloudflare:** https://dash.cloudflare.com
- **GitHub Actions:** https://github.com/BlackRoad-OS/{repo}/actions

### Emergency Contacts
- **Primary:** @blackboxprogramming
- **Email:** blackroad.systems@gmail.com

---

## 🚀 Deployment Procedures

### Automated Deployment (Normal)

**Trigger:** Push to `main` branch

```bash
# Make changes
git add .
git commit -m "Your changes"
git push origin main

# GitHub Actions automatically:
# 1. Runs tests
# 2. Builds application
# 3. Deploys to Railway
# 4. Updates status
```

**Monitoring:**
- Watch GitHub Actions: https://github.com/BlackRoad-OS/{repo}/actions
- Check Railway logs: `railway logs`
- Verify health: `curl https://{service}.blackroad.io/health`

### Manual Deployment (Emergency)

**When to use:** GitHub Actions down, urgent hotfix

```bash
# Navigate to repository
cd /path/to/blackroad-os-{service}

# Deploy to Railway
railway up

# Or for specific environment
railway up --environment production

# Verify deployment
railway status
railway logs
```

### Rollback Procedure

**If deployment causes issues:**

```bash
# Option 1: Revert via Git
git revert HEAD
git push origin main
# Auto-deploys previous version

# Option 2: Railway Console
# 1. Go to railway.app/dashboard
# 2. Select service
# 3. Go to Deployments
# 4. Click "..." on previous deployment
# 5. Click "Redeploy"

# Option 3: Railway CLI
railway redeploy --previous
```

---

## 🔧 Troubleshooting

### Issue: Service Health Check Failing

**Symptoms:**
- `/health` endpoint returns non-200
- Service shows as "degraded" on status page
- Auto-heal workflow triggered

**Diagnosis:**
```bash
# Check service logs
railway logs --tail 100

# Check deployment status
railway status

# Test endpoint locally
curl -v https://{service}.blackroad.io/health
```

**Resolution:**
1. Check recent deployments for breaking changes
2. Review service logs for errors
3. Verify environment variables
4. Check for dependency failures
5. Monitor auto-heal workflow progress

**Auto-heal will:**
- Restart service automatically
- Retry health checks
- Force redeploy if needed
- Create GitHub issue if persistent

### Issue: Deployment Failing

**Symptoms:**
- GitHub Actions workflow fails
- Railway build errors
- Service not starting

**Diagnosis:**
```bash
# Check GitHub Actions logs
gh run list --repo BlackRoad-OS/{repo}
gh run view {run-id} --log

# Check Railway build logs
railway logs --deployment {deployment-id}
```

**Common Causes & Fixes:**

| Error | Cause | Fix |
|-------|-------|-----|
| Lock file conflict | npm + pnpm both present | Auto-fix workflow handles this |
| Missing dependencies | package.json incomplete | `npm install` or `pnpm install` |
| Build timeout | Build too slow | Optimize build process |
| Memory limit | Service uses too much RAM | Upgrade Railway plan |
| Port binding | PORT not configured | Set PORT env var |

**Manual Fix:**
```bash
# Clean install
rm -rf node_modules
npm install # or pnpm install

# Test build locally
npm run build

# Commit and push
git add .
git commit -m "Fix: Resolve dependency issues"
git push
```

### Issue: DNS Not Resolving

**Symptoms:**
- Domain returns NXDOMAIN
- SSL certificate errors
- Service unreachable

**Diagnosis:**
```bash
# Check DNS records
dig {subdomain}.blackroad.io CNAME

# Check from different DNS servers
dig @1.1.1.1 {subdomain}.blackroad.io
dig @8.8.8.8 {subdomain}.blackroad.io

# Check SSL certificate
curl -vI https://{subdomain}.blackroad.io
```

**Resolution:**
1. Verify CNAME record exists in Cloudflare
2. Check CNAME target matches Railway URL
3. Ensure Cloudflare proxy is enabled (orange cloud)
4. Wait 5-10 minutes for propagation
5. Flush local DNS cache

```bash
# macOS: Flush DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Verify Cloudflare settings
./scripts/configure-dns.sh
```

### Issue: High Response Times

**Symptoms:**
- Status page shows >1000ms response times
- Users report slow performance
- Cloudflare analytics show degradation

**Diagnosis:**
```bash
# Test response time
time curl https://{service}.blackroad.io/health

# Check Railway metrics
railway status

# Check Cloudflare analytics
# → dash.cloudflare.com → Analytics
```

**Possible Causes:**
1. **Railway cold start** - Service sleeping
2. **High traffic** - Service overloaded
3. **Slow queries** - Database bottleneck
4. **Large responses** - Response size too big
5. **External APIs** - Third-party delay

**Resolution:**
```bash
# Restart service (force warm start)
railway restart

# Check for inefficient code
# Review recent commits

# Scale up (if on Railway Pro)
# Railway dashboard → Service → Settings → Scale

# Enable Cloudflare caching
# Cloudflare → Caching → Configuration
```

### Issue: SSL Certificate Error

**Symptoms:**
- Browser shows "Not Secure"
- Certificate mismatch
- Certificate expired

**Diagnosis:**
```bash
# Check certificate
openssl s_client -connect {subdomain}.blackroad.io:443 -servername {subdomain}.blackroad.io

# Check Cloudflare SSL mode
# Cloudflare → SSL/TLS → Overview
```

**Resolution:**
1. Set Cloudflare SSL mode to "Full (strict)"
2. Verify custom domain in Railway dashboard
3. Wait 5-10 minutes for Railway certificate
4. Check CNAME record is proxied (orange cloud)

---

## 🔐 Security Procedures

### Rotate API Keys

**When:** Every 90 days, or after suspected compromise

```bash
# 1. Generate new Railway token
# Railway → Settings → Tokens → Create

# 2. Update GitHub Secret
# GitHub → Repo → Settings → Secrets → RAILWAY_TOKEN

# 3. Test deployment
gh workflow run railway.yml

# 4. Revoke old token
# Railway → Settings → Tokens → Revoke
```

### Security Incident Response

**If credential leak detected:**

1. **Immediate:**
   - Revoke compromised credentials
   - Rotate all related secrets
   - Check access logs for unauthorized use

2. **Investigation:**
   - Review GitHub audit log
   - Check Railway activity log
   - Scan for anomalous deployments

3. **Remediation:**
   - Update all secrets in GitHub
   - Force redeploy all services
   - Enable 2FA if not already

4. **Documentation:**
   - Create incident report
   - Update security procedures
   - Notify team

### Vulnerability Patching

**Auto-handled by `auto-fix-dependencies.yml` workflow**

**Manual process (if needed):**
```bash
# Check for vulnerabilities
npm audit # or pnpm audit

# Fix automatically
npm audit fix # or pnpm audit --fix

# Review changes
git diff package-lock.json

# Commit and deploy
git add package-lock.json package.json
git commit -m "Security: Patch vulnerabilities"
git push
```

---

## 📊 Monitoring & Alerts

### Health Check Monitoring

**Automated via GitHub Actions:**
- Runs every 5 minutes
- Tests all service `/health` endpoints
- Auto-restarts unhealthy services
- Creates GitHub issues for failures

**Manual health check:**
```bash
# Check all services
for service in api www app agents ops; do
  echo "Checking $service.blackroad.io..."
  curl -f "https://$service.blackroad.io/health" && echo "✓ OK" || echo "✗ FAIL"
done
```

### Log Monitoring

**Railway Logs:**
```bash
# Tail logs
railway logs --tail 100

# Follow logs in real-time
railway logs --follow

# Filter by timestamp
railway logs --since 1h

# Export logs
railway logs > service-logs.txt
```

**Cloudflare Logs:**
- Navigate to: Cloudflare → Analytics → Logs
- View HTTP requests, errors, security events
- Export for analysis

### Performance Monitoring

**Key Metrics:**
- Response time (target: <200ms)
- Error rate (target: <0.1%)
- Uptime (target: 99.9%)
- Deployment frequency

**Where to check:**
- Status page: https://www.blackroad.io/status.html
- Railway metrics: Railway dashboard
- Cloudflare analytics: Cloudflare dashboard
- GitHub Actions: Deployment frequency

---

## 🔄 Maintenance Procedures

### Scheduled Maintenance

**Before maintenance:**
```bash
# 1. Announce via status page
# 2. Schedule during low traffic (2-4 AM UTC)
# 3. Prepare rollback plan
# 4. Test in staging first (if available)
```

**During maintenance:**
```bash
# 1. Monitor closely
railway logs --follow

# 2. Watch for errors
# 3. Check health endpoints
# 4. Verify user-facing functionality
```

**After maintenance:**
```bash
# 1. Verify all services healthy
# 2. Check status page shows all green
# 3. Monitor for 1 hour
# 4. Document changes
# 5. Update runbook if needed
```

### Database Migrations

**If using database:**
```bash
# 1. Backup database
railway db:backup

# 2. Test migration locally
npm run migrate:test

# 3. Run migration
npm run migrate:prod

# 4. Verify data integrity
npm run db:verify

# 5. Monitor for issues
railway logs --follow
```

### Dependency Updates

**Automated via `auto-fix-dependencies.yml`:**
- Runs daily at 2 AM UTC
- Auto-applies security patches
- Creates PRs for major updates
- Auto-merges safe updates

**Manual update (if needed):**
```bash
# Update dependencies
npm update # or pnpm update

# Test locally
npm run build
npm test

# Commit and deploy
git add package.json package-lock.json
git commit -m "chore: Update dependencies"
git push
```

---

## 📋 Checklists

### Pre-Deployment Checklist
- [ ] Changes reviewed and tested locally
- [ ] Tests passing (`npm test`)
- [ ] Build succeeds (`npm run build`)
- [ ] Environment variables documented
- [ ] Breaking changes communicated
- [ ] Rollback plan prepared

### Post-Deployment Checklist
- [ ] GitHub Actions workflow completed successfully
- [ ] Railway deployment shows as "Active"
- [ ] Health endpoints return 200 OK
- [ ] Status page shows all services operational
- [ ] No errors in Railway logs
- [ ] Response times within normal range
- [ ] Changes documented in changelog

### Incident Response Checklist
- [ ] Incident detected and severity assessed
- [ ] Team notified (if high severity)
- [ ] Root cause identified
- [ ] Fix applied or rollback initiated
- [ ] Service health verified
- [ ] Incident documented
- [ ] Post-mortem scheduled (if major)
- [ ] Preventive measures implemented

---

## 🎯 SLO/SLA Targets

### Service Level Objectives

| Metric | Target | Measurement |
|--------|--------|-------------|
| Uptime | 99.9% | Monthly |
| Response Time | <200ms (p95) | Per-request |
| Error Rate | <0.1% | Per-request |
| Deploy Frequency | Daily | Continuous |
| MTTR | <15 min | Per-incident |
| Deployment Success | >95% | Per-deployment |

### Monitoring Compliance

```bash
# Calculate monthly uptime
# (Total time - Downtime) / Total time * 100

# Check response times
# Cloudflare Analytics → Performance

# Check error rates
# Cloudflare Analytics → Traffic → Error Rate

# Track deployments
# GitHub Actions history
```

---

## 📞 Escalation Procedures

### Severity Levels

**P0 - Critical (All services down)**
- Response: Immediate
- Notification: @blackboxprogramming + email
- SLA: 15 minutes MTTR

**P1 - High (One service down)**
- Response: Within 30 minutes
- Notification: GitHub issue + auto-heal
- SLA: 1 hour MTTR

**P2 - Medium (Degraded performance)**
- Response: Within 2 hours
- Notification: GitHub issue
- SLA: 4 hours MTTR

**P3 - Low (Minor issue)**
- Response: Next business day
- Notification: GitHub issue
- SLA: 24 hours MTTR

### Escalation Path

1. **Auto-Heal** (0-10 min)
   - Self-healing workflows attempt fix
   - Creates GitHub issue if fails

2. **On-Call Engineer** (10-30 min)
   - Reviews GitHub issue
   - Applies manual fix if needed

3. **Lead Engineer** (30-60 min)
   - If issue persists
   - Complex troubleshooting

4. **Architecture Review** (60+ min)
   - If systemic issue
   - Design changes needed

---

## 🔧 Common Commands

### Railway CLI
```bash
# Login
railway login

# Link project
railway link

# Deploy
railway up

# Status
railway status

# Logs
railway logs --tail 100

# Environment variables
railway variables

# Restart
railway restart

# Shell access
railway run bash
```

### Cloudflare API
```bash
# List DNS records
curl "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $API_TOKEN"

# Update DNS record
curl -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"content":"new-target.com"}'

# Purge cache
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"purge_everything":true}'
```

### GitHub CLI
```bash
# View workflow runs
gh run list --repo BlackRoad-OS/{repo}

# View run logs
gh run view {run-id} --log

# Trigger workflow
gh workflow run {workflow-name}

# List issues
gh issue list --label incident

# Create issue
gh issue create --title "Incident" --label incident
```

---

## 📚 Additional Resources

### Documentation
- Architecture: `/Users/alexa/ARCHITECTURE.md`
- DNS Guide: `/Users/alexa/DNS-CONFIGURATION-GUIDE.md`
- Self-Healing: `/Users/alexa/SELF-HEALING-DEPLOYMENT-SYSTEM.md`
- Deployment Status: `/Users/alexa/DEPLOYMENT-STATUS.md`

### External Links
- Railway Docs: https://docs.railway.app
- Cloudflare Docs: https://developers.cloudflare.com
- GitHub Actions Docs: https://docs.github.com/actions

### Scripts
- DNS Configuration: `/Users/alexa/scripts/configure-dns.sh`
- Health Check: (TODO)
- Log Analysis: (TODO)

---

**🎯 Remember:** Most issues are automatically resolved by self-healing workflows. Check GitHub issues before manual intervention.

---

*📖 Operations Runbook for BlackRoad OS*

*Generated with [Claude Code](https://claude.com/claude-code)*

*Co-Authored-By: Claude <noreply@anthropic.com>*

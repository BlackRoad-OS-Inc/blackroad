# 🚀 BR-APPS DEPLOYMENT CHECKLIST
**Date:** 2025-12-14
**Goal:** Ship blackroad.io to production

---

## ✅ Pre-Flight

- [ ] Railway dashboard open: https://railway.app/project/03ce1e43-5086-4255-b2bc-0146c8916f4c
- [ ] Read EXECUTE-NOW.md
- [ ] Have Cloudflare access ready

---

## 📝 Step 1: Rename Project (2 min)

- [ ] Click Settings → General
- [ ] Change name: "BlackRoad OS" → **"br-apps"**
- [ ] Save changes

---

## 🔍 Step 2: Check Existing Services (5 min)

### web service (blackroad-os-web)
- [ ] Service exists and is deployed
- [ ] Check latest deployment status: ___________
- [ ] Current domain: ___________________________
- [ ] Status: 🟢 Running / 🔴 Failed

### app service (blackroad-os-prism-console)
- [ ] Service exists and is deployed
- [ ] Check latest deployment status: ___________
- [ ] Current domain: ___________________________
- [ ] Status: 🟢 Running / 🔴 Failed

---

## ➕ Step 3: Add ops Service (10 min)

- [ ] Click "+ New" → "GitHub Repo"
- [ ] Select: blackroad-os-operator
- [ ] Wait for deployment to start
- [ ] Rename service to: **"ops"**
- [ ] Add environment variables:
  - [ ] PORT=8080
  - [ ] NODE_ENV=production
  - [ ] REDIS_URL=${{Redis.REDIS_URL}}
  - [ ] CATALOG_PATH=/app/agent-catalog/agents.yaml
- [ ] Add custom domain: ops.blackroad.io
- [ ] Railway domain: _________________________
- [ ] Deployment status: 🟢 Success / 🔴 Failed

---

## 🗄️ Step 4: Add Database/Redis (5 min)

- [ ] Check if Postgres exists
  - If NO: Add PostgreSQL database
- [ ] Check if Redis exists
  - If NO: Add Redis database
- [ ] Verify connection strings available

---

## 🌐 Step 5: Configure Custom Domains (5 min)

### web service
- [ ] Add custom domain: www.blackroad.io
- [ ] Add custom domain: blackroad.io
- [ ] Railway domain: _________________________

### app service
- [ ] Add custom domain: app.blackroad.io
- [ ] Railway domain: _________________________

### ops service
- [ ] Custom domain ops.blackroad.io already added in Step 3

---

## ☁️ Step 6: Run DNS Automation (5 min)

- [ ] Copy Railway domains from above
- [ ] Run: `~/setup-cloudflare-dns-blackroad-io.sh`
- [ ] Enter web domain when prompted
- [ ] Enter app domain when prompted
- [ ] Enter ops domain when prompted
- [ ] Verify DNS records created successfully

---

## 🧪 Step 7: Test Endpoints (10 min)

### Terminal tests
```bash
curl -I https://www.blackroad.io
```
- [ ] Returns: 200 OK / 301 / 302

```bash
curl -I https://blackroad.io
```
- [ ] Returns: 200 OK / 301 / 302

```bash
curl -I https://app.blackroad.io
```
- [ ] Returns: 200 OK

```bash
curl -I https://ops.blackroad.io/health
```
- [ ] Returns: 200 OK

### Browser tests
- [ ] Open https://www.blackroad.io
  - [ ] Page loads correctly
  - [ ] No console errors
  - [ ] SSL valid (green padlock)

- [ ] Open https://app.blackroad.io
  - [ ] Console loads
  - [ ] No errors
  - [ ] SSL valid

- [ ] Open https://ops.blackroad.io/health
  - [ ] Health check responds
  - [ ] SSL valid

---

## 📊 Step 8: Monitor Logs (5 min)

For each service in Railway:

### web logs
- [ ] No errors
- [ ] Server started message visible
- [ ] Status: 🟢 Healthy / 🔴 Errors

### app logs
- [ ] No errors
- [ ] Server started message visible
- [ ] Status: 🟢 Healthy / 🔴 Errors

### ops logs
- [ ] No errors
- [ ] Server started message visible
- [ ] Status: 🟢 Healthy / 🔴 Errors

---

## 📝 Step 9: Document Deployment (5 min)

Create file: `BR-APPS-DEPLOYMENT-INFO.md`

```markdown
# br-apps Deployment Info

**Date:** 2025-12-14
**Deployed by:** Alexa Amundson

## Railway Project
- Project ID: 03ce1e43-5086-4255-b2bc-0146c8916f4c
- Project Name: br-apps
- URL: https://railway.app/project/03ce1e43-5086-4255-b2bc-0146c8916f4c

## Live Domains
- https://www.blackroad.io
- https://blackroad.io (redirects to www)
- https://app.blackroad.io
- https://ops.blackroad.io

## Railway Domains
- web: _________________.up.railway.app
- app: _________________.up.railway.app
- ops: _________________.up.railway.app

## Services
- web: blackroad-os-web
- app: blackroad-os-prism-console
- ops: blackroad-os-operator

## Databases
- Postgres: Available at ${{Postgres.DATABASE_URL}}
- Redis: Available at ${{Redis.REDIS_URL}}

## Status
- Deployed: ✅
- DNS: ✅
- SSL: ✅
- All services running: ✅
```

---

## ✅ DEPLOYMENT COMPLETE!

- [ ] All services deployed
- [ ] All domains live
- [ ] All tests passing
- [ ] Logs clean
- [ ] Documentation created

---

## 🎉 SUCCESS METRICS

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Services deployed | 3 | ___ | ⬜ |
| Endpoints live | 4 | ___ | ⬜ |
| SSL certificates | 4 | ___ | ⬜ |
| Response time (avg) | <500ms | ___ | ⬜ |
| Error rate | 0% | ___ | ⬜ |

---

## 📞 Next Steps After Deployment

- [ ] Set up monitoring (Better Uptime)
- [ ] Configure Cloudflare Zero Trust for ops.blackroad.io
- [ ] Add error tracking (Sentry)
- [ ] Monitor costs in Railway dashboard
- [ ] Plan Phase 1B (agents, api evaluation)
- [ ] Schedule team demo

---

**Time Started:** __________
**Time Completed:** __________
**Total Duration:** __________

---

🚀 **LET'S SHIP IT!**

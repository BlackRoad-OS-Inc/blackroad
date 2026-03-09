# EXECUTE NOW - br-apps Deployment
**Time to ship:** Right now
**Estimated time:** 30-45 minutes

---

## 🔍 Current State Analysis

You already have Railway projects deployed! Found in `~/.railway/config.json`:

### Existing "BlackRoad OS" Project
- **Project ID:** `03ce1e43-5086-4255-b2bc-0146c8916f4c`
- **Services already deployed:**
  - blackroad-os-agents
  - blackroad-os-api-gateway
  - blackroad-os-archive
  - blackroad-os-beacon
  - blackroad-os-brand
  - blackroad-os-demo
  - blackroad-os-home
  - blackroad-os-infra
  - blackroad-os-master
  - blackroad-os-pack-* (multiple)
  - blackroad-os-prism-console ✅ (we need this!)
  - blackroad-os-web ✅ (we need this!)

### Other Projects
- **blackroad-os-core** (separate project)
- **blackroad-os-api** (separate project)
- **blackroad-os-docs** (separate project)

---

## 🎯 Decision Point: Consolidate or Create New?

### Option A: Use Existing "BlackRoad OS" Project (Recommended)
**Pros:**
- Already has web + prism-console deployed
- Already has production environment
- Can add/update services
- Faster to execute

**Cons:**
- Name is "BlackRoad OS" not "br-apps"
- Has many services (some we might not need)
- Need to audit and clean up

### Option B: Create New "br-apps" Project
**Pros:**
- Clean slate
- Follows canonical naming (br-apps)
- Only what we need

**Cons:**
- Duplicate work (web + prism already exist)
- Need to migrate or duplicate

---

## ✅ RECOMMENDED: Use Existing + Rename + Clean Up

**Execute this plan:**

1. Use existing "BlackRoad OS" project
2. Rename it to "br-apps" in Railway dashboard
3. Audit existing services
4. Add missing services (operator)
5. Configure DNS properly

---

## 🚀 EXECUTION STEPS (DO THIS NOW)

### Step 1: Open Railway Dashboard (2 minutes)

```bash
# Open in browser
open "https://railway.app/project/03ce1e43-5086-4255-b2bc-0146c8916f4c"
```

You should see your "BlackRoad OS" project with all services.

---

### Step 2: Rename Project (1 minute)

1. Click "Settings" (gear icon)
2. General → Project Name
3. Change from "BlackRoad OS" to **"br-apps"**
4. Save

---

### Step 3: Audit Existing Services (5 minutes)

Check which services are actually deployed and running:

**Services we NEED:**
- [ ] web (blackroad-os-web)
- [ ] app (blackroad-os-prism-console)
- [ ] ops (blackroad-os-operator) - **MISSING, need to add**

**Services to EVALUATE:**
- [ ] agents (blackroad-os-agents) - Keep if running fine
- [ ] api-gateway - Evaluate if needed (probably can remove)

**Services to REMOVE (optional cleanup):**
- [ ] archive, beacon, brand, demo, home, infra, master, pack-*
  - These are either non-deployable or should be elsewhere
  - Can remove later, not urgent

---

### Step 4: Check Existing Service Status (5 minutes)

For each service we need:

#### web (blackroad-os-web)
- [ ] Go to service in Railway
- [ ] Check "Deployments" - is latest deployment successful?
- [ ] Check "Settings" → "Networking" → What domain is it using?
- [ ] Check "Variables" - are env vars set correctly?

#### app (blackroad-os-prism-console)
- [ ] Same checks as above

#### ops (NOT YET DEPLOYED)
- [ ] Need to add this service

---

### Step 5: Add Missing Service - ops (blackroad-os-operator) (10 minutes)

In the br-apps project:

1. Click "+ New" button
2. Select "GitHub Repo"
3. Choose repository: **blackroad-os-operator**
4. Wait for initial deployment
5. Click the service card
6. Settings → General → Rename to: **"ops"**
7. Settings → Variables → Add:

```bash
PORT=8080
NODE_ENV=production
REDIS_URL=${{Redis.REDIS_URL}}
CATALOG_PATH=/app/agent-catalog/agents.yaml
RAILWAY_ENVIRONMENT=${{RAILWAY_ENVIRONMENT_NAME}}
COMMIT_SHA=${{RAILWAY_GIT_COMMIT_SHA}}
```

8. Settings → Networking → Custom Domain → Add: **ops.blackroad.io**
9. Copy the Railway public domain (e.g., `ops-production-xyz.up.railway.app`)

---

### Step 6: Add Database & Redis if Needed (5 minutes)

Check if you already have these in the project:

**If NOT present:**

1. Click "+ New" → "Database" → "Add PostgreSQL"
2. Click "+ New" → "Database" → "Add Redis"

**If already present:**
- Note the connection strings are available as:
  - `${{Postgres.DATABASE_URL}}`
  - `${{Redis.REDIS_URL}}`

---

### Step 7: Configure Custom Domains (5 minutes)

For each service, add custom domains:

#### web service
- Settings → Networking → Custom Domain
- Add: **www.blackroad.io**
- Add: **blackroad.io** (root domain)
- Copy Railway domain: `_____________.up.railway.app`

#### app service
- Settings → Networking → Custom Domain
- Add: **app.blackroad.io**
- Copy Railway domain: `_____________.up.railway.app`

#### ops service
- Settings → Networking → Custom Domain
- Add: **ops.blackroad.io**
- Copy Railway domain: `_____________.up.railway.app`

---

### Step 8: Run Cloudflare DNS Automation (5 minutes)

**Save your Railway domains first:**

```bash
# Create a temp file with your Railway domains
cat > /tmp/railway-domains.txt << 'EOF'
WEB_DOMAIN=<paste-web-railway-domain>.up.railway.app
APP_DOMAIN=<paste-app-railway-domain>.up.railway.app
OPS_DOMAIN=<paste-ops-railway-domain>.up.railway.app
EOF
```

**Then run DNS setup:**

```bash
# Make script executable
chmod +x ~/setup-cloudflare-dns-blackroad-io.sh

# Run it
~/setup-cloudflare-dns-blackroad-io.sh
```

Enter the Railway domains when prompted.

---

### Step 9: Verify Deployments (10 minutes)

**Test each endpoint:**

```bash
# Test web
curl -I https://www.blackroad.io
curl -I https://blackroad.io

# Test app
curl -I https://app.blackroad.io

# Test ops
curl -I https://ops.blackroad.io/health
```

**Expected:** All should return `200 OK` or `301/302` (redirect)

**In browser:**
- Open https://www.blackroad.io - should load
- Open https://app.blackroad.io - should load console
- Open https://ops.blackroad.io/health - should show health status

---

### Step 10: Monitor Logs (5 minutes)

For each service in Railway:
1. Click service
2. Click "View Logs"
3. Watch for 2-3 minutes
4. Look for errors

**Good signs:**
- "Server listening on port..."
- "Application started"
- No crash loops

**Bad signs:**
- "Error: Cannot connect to database"
- "EADDRINUSE" (port already in use)
- Crash and restart loops

---

## ✅ Success Criteria

You're done when:

- ✅ Project renamed to "br-apps"
- ✅ 3 core services running: web, app, ops
- ✅ Custom domains configured
- ✅ DNS records created in Cloudflare
- ✅ All endpoints return 200 OK
- ✅ No errors in Railway logs
- ✅ SSL certificates issued (green padlock)

---

## 🔧 If Something Goes Wrong

### Service won't build
1. Check Railway logs for error message
2. Verify `package.json` has correct scripts
3. Check environment variables are set
4. Check if it needs database (add Postgres)

### Domain shows "Not Found"
1. Wait 5-10 minutes for DNS propagation
2. Verify CNAME target matches Railway domain exactly
3. Check Cloudflare proxy is enabled (orange cloud)
4. Clear browser cache

### ops service fails (Python + TypeScript)
1. Check if `requirements.txt` exists
2. Verify Python buildpack detected
3. Check if port 8080 is configured
4. Might need Railway Nixpacks config

---

## 📋 Post-Deployment Checklist

After everything is live:

- [ ] Document Railway domains in `BR-APPS-DEPLOYMENT-INFO.md`
- [ ] Set up monitoring (Better Uptime, Sentry)
- [ ] Configure Cloudflare Zero Trust for ops.blackroad.io
- [ ] Test all service-to-service communication
- [ ] Monitor costs in Railway dashboard
- [ ] Plan Phase 1B (evaluate agents, api services)

---

## 🎯 Quick Commands Reference

```bash
# Open Railway project
open "https://railway.app/project/03ce1e43-5086-4255-b2bc-0146c8916f4c"

# Run DNS automation
~/setup-cloudflare-dns-blackroad-io.sh

# Test endpoints
curl -I https://www.blackroad.io
curl -I https://app.blackroad.io
curl -I https://ops.blackroad.io/health

# Check Railway CLI (if needed)
railway whoami
railway status
```

---

## 💡 Pro Tips

1. **Start with web + app** - They're already deployed, just need DNS
2. **Add ops service** - This is the only new deployment needed
3. **Skip cleanup for now** - Remove extra services later
4. **Use Railway UI** - Faster than CLI for this
5. **Watch logs** - They tell you everything

---

## ⏱️ Time Breakdown

- Step 1-2: Rename project (3 min)
- Step 3-4: Audit services (10 min)
- Step 5: Add ops service (10 min)
- Step 6: Database/Redis (5 min)
- Step 7: Custom domains (5 min)
- Step 8: DNS automation (5 min)
- Step 9: Testing (10 min)
- **Total: ~45 minutes**

---

## 🚀 START HERE

Open this URL in your browser RIGHT NOW:

```
https://railway.app/project/03ce1e43-5086-4255-b2bc-0146c8916f4c
```

Then follow the steps above.

**LET'S SHIP IT! 🚀**

---

**Questions? Problems? Check the logs first, then ping me.**

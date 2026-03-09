# Phase 1 Deployment Checklist: br-apps
**Domain:** blackroad.io
**Goal:** Get web + api + app live and talking to each other

---

## Pre-Flight Check

- [ ] Read ARCHITECTURE.md (the constitution)
- [ ] Have Railway account logged in (amundsonalexa@gmail.com)
- [ ] Have Cloudflare account access
- [ ] Confirm repos exist on GitHub:
  - [ ] blackroad-os-web
  - [ ] blackroad-os-api
  - [ ] blackroad-os-prism-console

---

## Part 1: Railway Project Setup (15 minutes)

### Step 1: Create Project
- [ ] Go to https://railway.app/new
- [ ] Click "Empty Project"
- [ ] Name: `br-apps`
- [ ] Description: "blackroad.io - Public apps and APIs"

### Step 2: Create Environments
- [ ] Click Settings → Environments
- [ ] Create: `dev`
- [ ] Create: `staging`
- [ ] Create: `prod`
- [ ] Set `prod` as default

### Step 3: Add Database
- [ ] Click "+ New"
- [ ] Select "Database" → "Add PostgreSQL"
- [ ] Service auto-names as `Postgres`
- [ ] Note: Connection string will be `${{Postgres.DATABASE_URL}}`

### Step 4: Add Redis (Optional - if needed for queues)
- [ ] Click "+ New"
- [ ] Select "Database" → "Add Redis"
- [ ] Service auto-names as `Redis`
- [ ] Note: Connection string will be `${{Redis.REDIS_URL}}`

---

## Part 2: Deploy Services (30 minutes)

### Service 1: web (Frontend)

- [ ] Click "+ New" → "GitHub Repo"
- [ ] Select: `blackboxprogramming/blackroad-os-web` (or your org)
- [ ] Wait for initial deployment to start
- [ ] Click the service card
- [ ] Settings → General → Rename to: `web`
- [ ] Settings → Variables → Add:
  ```
  NODE_ENV=production
  NEXT_PUBLIC_API_URL=https://api.blackroad.io
  NEXT_PUBLIC_APP_URL=https://app.blackroad.io
  DATABASE_URL=${{Postgres.DATABASE_URL}}
  ```
- [ ] Settings → Networking → Custom Domain → Add: `www.blackroad.io`
- [ ] Copy the Railway public domain (e.g., `web-production.up.railway.app`)
- [ ] Wait for deployment to complete
- [ ] Check logs for errors

### Service 2: api (Backend)

- [ ] Click "+ New" → "GitHub Repo"
- [ ] Select: `blackboxprogramming/blackroad-os-api`
- [ ] Rename to: `api`
- [ ] Settings → Variables → Add:
  ```
  NODE_ENV=production
  PORT=3000
  CORS_ORIGIN=https://www.blackroad.io,https://blackroad.io,https://app.blackroad.io
  DATABASE_URL=${{Postgres.DATABASE_URL}}
  REDIS_URL=${{Redis.REDIS_URL}}
  ```
- [ ] Settings → Networking → Custom Domain → Add: `api.blackroad.io`
- [ ] Copy the Railway public domain
- [ ] Wait for deployment
- [ ] Test: Click "View Logs" and verify no errors

### Service 3: app (Console/Prism)

- [ ] Click "+ New" → "GitHub Repo"
- [ ] Select: `blackboxprogramming/blackroad-os-prism-console`
- [ ] Rename to: `app`
- [ ] Settings → Variables → Add:
  ```
  NODE_ENV=production
  VITE_API_URL=https://api.blackroad.io
  DATABASE_URL=${{Postgres.DATABASE_URL}}
  ```
- [ ] Settings → Networking → Custom Domain → Add: `app.blackroad.io`
- [ ] Copy the Railway public domain
- [ ] Wait for deployment
- [ ] Check logs

---

## Part 3: Verify Internal Networking (10 minutes)

### Test Service-to-Service Communication

- [ ] In `web` service, verify it can call api internally:
  - Check env var: `API_PRIVATE_URL=http://${{api.RAILWAY_PRIVATE_DOMAIN}}:3000`
  - Or use public URL for now: `https://api.blackroad.io`

- [ ] In `app` service, verify it can call api:
  - Check env var: `VITE_API_URL=https://api.blackroad.io`

- [ ] Test database connections:
  - [ ] Check `web` can connect to Postgres
  - [ ] Check `api` can connect to Postgres
  - [ ] Check `app` can connect to Postgres (if needed)

- [ ] Review Railway logs for all services:
  - [ ] web: No connection errors
  - [ ] api: No database errors
  - [ ] app: No API call failures

---

## Part 4: Cloudflare DNS Setup (5 minutes)

### Collect Railway Domains

Write down the Railway public domains from Part 2:
```
web domain: _____________________.up.railway.app
api domain: _____________________.up.railway.app
app domain: _____________________.up.railway.app
```

### Run DNS Automation Script

Option A: Automated (recommended)
```bash
chmod +x setup-cloudflare-dns-blackroad-io.sh
./setup-cloudflare-dns-blackroad-io.sh
```

Enter the Railway domains when prompted.

Option B: Manual (via Cloudflare dashboard)
- [ ] Go to https://dash.cloudflare.com
- [ ] Select blackroad.io zone
- [ ] DNS → Add record:
  - Type: CNAME
  - Name: www
  - Target: [web Railway domain]
  - Proxy: ON (orange cloud)
- [ ] Add record:
  - Type: CNAME
  - Name: @ (or leave blank for root)
  - Target: [web Railway domain]
  - Proxy: ON
- [ ] Add record:
  - Type: CNAME
  - Name: api
  - Target: [api Railway domain]
  - Proxy: ON
- [ ] Add record:
  - Type: CNAME
  - Name: app
  - Target: [app Railway domain]
  - Proxy: ON

---

## Part 5: Testing & Verification (15 minutes)

### Test Public Endpoints

- [ ] Test www:
  ```bash
  curl -I https://www.blackroad.io
  ```
  Expected: `200 OK`

- [ ] Test root domain:
  ```bash
  curl -I https://blackroad.io
  ```
  Expected: Redirects to www or `200 OK`

- [ ] Test API:
  ```bash
  curl -I https://api.blackroad.io/health
  # or whatever health check endpoint exists
  ```
  Expected: `200 OK`

- [ ] Test app:
  ```bash
  curl -I https://app.blackroad.io
  ```
  Expected: `200 OK`

### Test in Browser

- [ ] Open https://www.blackroad.io
  - Should load without errors
  - Check console for API call errors
  - Check network tab

- [ ] Open https://app.blackroad.io
  - Should load console UI
  - Check that it can call API
  - Verify functionality

- [ ] Test API directly:
  - Open https://api.blackroad.io in browser
  - Or use Postman/Thunder Client

### Check SSL Certificates

- [ ] Verify https://www.blackroad.io has valid cert
- [ ] Verify https://api.blackroad.io has valid cert
- [ ] Verify https://app.blackroad.io has valid cert

Look for:
- Green padlock icon
- "Issued by: Railway" or "Issued by: Cloudflare"
- No certificate warnings

### Monitor Railway Logs

- [ ] Open Railway dashboard
- [ ] For each service, click "View Logs"
- [ ] Monitor for 5 minutes
- [ ] Look for:
  - ❌ Connection errors
  - ❌ Database errors
  - ❌ Crash loops
  - ✅ Successful requests
  - ✅ Healthy status

---

## Part 6: Documentation (5 minutes)

### Record Deployment Info

Create a file: `BR-APPS-DEPLOYMENT-INFO.md`

```markdown
# br-apps Deployment Info

**Date Deployed:** [DATE]
**Deployed By:** Alexa Amundson

## Railway Project
- Project ID: [from Railway URL]
- Project URL: https://railway.app/project/[ID]

## Services
- web: https://www.blackroad.io
- api: https://api.blackroad.io
- app: https://app.blackroad.io

## Railway Domains
- web: [domain].up.railway.app
- api: [domain].up.railway.app
- app: [domain].up.railway.app

## Database
- Postgres: [connection string available in Railway]
- Redis: [connection string if deployed]

## Status
- ✅ All services deployed
- ✅ DNS configured
- ✅ SSL certificates issued
- ✅ Services communicating
- ✅ Tests passing
```

---

## Completion Criteria

You're done with Phase 1 when:

- ✅ All 3 services deployed to Railway (web, api, app)
- ✅ All custom domains configured
- ✅ DNS records created in Cloudflare
- ✅ All endpoints return 200 OK
- ✅ SSL certificates issued and valid
- ✅ Service-to-service communication working
- ✅ No errors in Railway logs
- ✅ Database connections healthy
- ✅ Documentation created

---

## If Something Goes Wrong

### Service won't build
1. Check Railway logs for build errors
2. Verify Dockerfile exists or package.json has correct scripts
3. Check Railway detected correct buildpack
4. Verify all required env vars are set

### Domain shows "Not Found"
1. Verify CNAME target matches Railway domain exactly
2. Check Cloudflare proxy is enabled (orange cloud)
3. Wait 5-10 minutes for DNS propagation
4. Clear browser cache

### Services can't communicate
1. Check environment variables are correct
2. Verify CORS settings in API
3. Use Railway's internal networking for service-to-service
4. Check firewall/network settings in Railway

### Database connection fails
1. Verify `DATABASE_URL` env var is set correctly
2. Check Postgres service is running in Railway
3. Test connection string manually
4. Check connection pool limits

---

## Next Steps After Phase 1

Once Phase 1 is complete and stable:

### Phase 1B (Optional - Week 2)
- [ ] Evaluate: Do we need agents service?
- [ ] Evaluate: Do we need ops service?
- [ ] Evaluate: Do we need gateway? (Probably no)
- [ ] Add monitoring/alerting (Better Uptime, Sentry)

### Phase 2 (Week 2-3)
- [ ] Deploy br-internal (blackroad.systems)
- [ ] Set up auth service (id.blackroad.systems)
- [ ] Configure Cloudflare Zero Trust
- [ ] Lock down ops.blackroad.io

### Phase 3 (Week 3-4)
- [ ] Deploy lucidia-engine (lucidia.earth)
- [ ] Deploy br-company (blackroad.company)

---

## Help & Resources

**Railway Dashboard:** https://railway.app/dashboard
**Railway Docs:** https://docs.railway.app
**Cloudflare Dashboard:** https://dash.cloudflare.com
**Architecture Docs:** ARCHITECTURE.md (the constitution)

**Troubleshooting:**
- Railway Discord: https://discord.gg/railway
- Cloudflare Community: https://community.cloudflare.com
- Review Queue: blackroad.systems@gmail.com

---

**Time Estimate:** 1-2 hours total
**Difficulty:** Moderate
**Prerequisites:** Railway + Cloudflare access

**Ready? Let's ship it. 🚀**

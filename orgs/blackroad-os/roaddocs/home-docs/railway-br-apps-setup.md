# Railway br-apps Setup Guide

## Project Overview
**Domain:** blackroad.io
**Railway Project:** br-apps
**Services:** web, api, gateway, worker

---

## Option 1: Railway Dashboard (Recommended for First Setup)

### Step 1: Create Project
1. Go to https://railway.app/new
2. Click "Empty Project"
3. Name it: `br-apps`

### Step 2: Create Environments
In the br-apps project:
1. Click "Settings" → "Environments"
2. Create three environments:
   - `dev`
   - `staging`
   - `prod`

### Step 3: Add Services (one at a time)

#### Service 1: web (blackroad-os-web)
1. Click "+ New" → "GitHub Repo"
2. Select: `blackroad-os-web` (or the appropriate org/repo)
3. After deployment starts, click the service
4. Settings → General → Rename to: `web`
5. Settings → Domains → Add custom domain:
   - Production: `www.blackroad.io`
   - (Railway will provide a generated domain like `web-production.up.railway.app`)

#### Service 2: api (blackroad-os-api)
1. Click "+ New" → "GitHub Repo"
2. Select: `blackroad-os-api`
3. Rename to: `api`
4. Add custom domain: `api.blackroad.io`

#### Service 3: gateway (blackroad-os-api-gateway)
1. Click "+ New" → "GitHub Repo"
2. Select: `blackroad-os-api-gateway`
3. Rename to: `gateway`
4. Add custom domain: `gateway.blackroad.io` (if needed publicly)

#### Service 4: worker (blackroad-os-agents)
1. Click "+ New" → "GitHub Repo"
2. Select: `blackroad-os-agents`
3. Rename to: `worker`
4. No custom domain needed (internal service)

### Step 4: Add Database/Redis (if needed)
1. Click "+ New" → "Database"
2. Choose PostgreSQL or Redis
3. Service will auto-name as `db` or `redis`
4. Connection strings auto-populate in other services as env vars

---

## Option 2: Railway CLI (After Authentication)

### Prerequisites
```bash
# Login to Railway (opens browser)
railway login

# Verify authentication
railway whoami
```

### Create Project & Services
```bash
# Create new project
railway init --name br-apps

# Add environments
railway environment add dev
railway environment add staging
railway environment add prod

# Link to GitHub repos (run in each repo directory)
cd /path/to/blackroad-os-web
railway link --project br-apps --environment production
railway up

cd /path/to/blackroad-os-api
railway link --project br-apps --environment production
railway up

# ... repeat for gateway and worker
```

---

## Step 5: Configure Cloudflare DNS

Once Railway services are deployed, you'll get Railway domains like:
- `web-production.up.railway.app`
- `api-production.up.railway.app`
- etc.

### DNS Records to Create in Cloudflare

| Type  | Name | Target                              | Proxy |
|-------|------|-------------------------------------|-------|
| CNAME | www  | web-production.up.railway.app       | Yes   |
| CNAME | api  | api-production.up.railway.app       | Yes   |
| CNAME | @    | web-production.up.railway.app       | Yes   |

**Note:** Railway will show you the exact domain to use in Settings → Networking

### In Railway (for each service):
1. Go to service → Settings → Networking
2. Click "Custom Domain"
3. Enter your Cloudflare domain (e.g., `www.blackroad.io`)
4. Railway will provide validation instructions
5. Add the CNAME in Cloudflare as shown above

---

## Service Environment Variables

### Shared across all services (set in Railway project level):
```
NODE_ENV=production
DATABASE_URL=${{Postgres.DATABASE_URL}}  # Auto-populated if you add Postgres
REDIS_URL=${{Redis.REDIS_URL}}            # Auto-populated if you add Redis
```

### Service-specific:

#### web service
```
NEXT_PUBLIC_API_URL=https://api.blackroad.io
NEXT_PUBLIC_GATEWAY_URL=https://gateway.blackroad.io
```

#### api service
```
PORT=3000
CORS_ORIGIN=https://www.blackroad.io,https://blackroad.io
```

#### gateway service
```
PORT=8080
UPSTREAM_API_URL=http://api.railway.internal:3000
```

#### worker service
```
QUEUE_URL=${{Redis.REDIS_URL}}
```

---

## Verification Checklist

After setup:
- [ ] All 4 services deployed successfully
- [ ] Environment variables configured
- [ ] Custom domains added in Railway
- [ ] DNS records added in Cloudflare
- [ ] SSL certificates issued (automatic via Railway)
- [ ] Test each endpoint:
  - https://www.blackroad.io
  - https://api.blackroad.io
  - https://blackroad.io (should redirect to www)

---

## Next Steps

Once br-apps is stable:
1. Repeat this pattern for other domains (br-internal, lucidia-engine, etc.)
2. Each gets its own Railway project
3. Each follows same service naming convention
4. Cloudflare DNS follows same subdomain pattern

---

## Troubleshooting

### Service won't deploy
- Check build logs in Railway dashboard
- Verify Dockerfile/buildpack detection
- Check for missing environment variables

### Domain not working
- Verify CNAME is correct in Cloudflare
- Check "Proxy status" is enabled (orange cloud)
- Wait 5-10 minutes for DNS propagation

### Services can't talk to each other
- Use Railway's internal networking: `http://api.railway.internal:3000`
- Or use `${{api.RAILWAY_PRIVATE_DOMAIN}}`

---

## Reference

**Railway Project:** br-apps
**Cloudflare Zone:** blackroad.io (zone ID: `848cf0b18d51e0170e0d1537aec3505a`)
**Primary Email:** amundsonalexa@gmail.com
**Review Queue:** blackroad.systems@gmail.com

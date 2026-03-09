# BR-APPS Complete Setup Guide
**Domain:** blackroad.io
**Railway Project:** br-apps
**Goal:** Canonical Railway + Cloudflare infrastructure for public apps

---

## The Problem with API Automation

Railway's GraphQL API requires:
1. Valid workspace ID (schema has changed, old queries don't work)
2. OAuth flow for linking GitHub repos
3. Recent API token (yours may be expired)

**Solution:** Use Railway dashboard for initial setup, then automate DNS with Cloudflare.

---

## Part 1: Railway Dashboard Setup (10 minutes)

### Step 1: Create Project
1. Open: https://railway.app/new
2. Click "Empty Project"
3. Name it: **`br-apps`**
4. Description: "blackroad.io - Public apps and APIs"

### Step 2: Add Environments
In the br-apps project settings:
1. Click "Settings" (gear icon)
2. Go to "Environments" tab
3. Create three environments:
   - `dev`
   - `staging`
   - `prod`

### Step 3: Add Services from GitHub

For each repo, do this:

#### Service 1: web (blackroad-os-web)
1. Click "+ New" button
2. Select "GitHub Repo"
3. Choose: `blackboxprogramming/blackroad-os-web` (or your org)
4. Wait for it to start deploying
5. Click the service card
6. Settings → General → Change name to: **`web`**
7. Settings → Networking → Custom Domain → Add: **`www.blackroad.io`**
8. Copy the Railway-generated domain (e.g., `web-production-abc123.up.railway.app`)

#### Service 2: api (blackroad-os-api)
1. "+ New" → "GitHub Repo"
2. Choose: `blackroad-os-api`
3. Rename to: **`api`**
4. Add custom domain: **`api.blackroad.io`**
5. Copy the Railway domain

#### Service 3: gateway (blackroad-os-api-gateway)
1. "+ New" → "GitHub Repo"
2. Choose: `blackroad-os-api-gateway`
3. Rename to: **`gateway`**
4. (Optional) Add custom domain if needed publicly
5. Copy the Railway domain

#### Service 4: worker (blackroad-os-agents)
1. "+ New" → "GitHub Repo"
2. Choose: `blackroad-os-agents`
3. Rename to: **`worker`**
4. No custom domain needed (internal service)

### Step 4: Add Database (Optional)
1. "+ New" → "Database" → "Add PostgreSQL"
2. Service auto-names as `Postgres`
3. Connection string auto-populates as `${{Postgres.DATABASE_URL}}`
4. All services can reference this in their env vars

### Step 5: Configure Environment Variables

Click each service → Variables tab:

**web service:**
```
NODE_ENV=production
NEXT_PUBLIC_API_URL=https://api.blackroad.io
NEXT_PUBLIC_GATEWAY_URL=${{gateway.RAILWAY_PUBLIC_DOMAIN}}
DATABASE_URL=${{Postgres.DATABASE_URL}}
```

**api service:**
```
NODE_ENV=production
PORT=3000
CORS_ORIGIN=https://www.blackroad.io,https://blackroad.io
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
```

**gateway service:**
```
NODE_ENV=production
PORT=8080
UPSTREAM_API_URL=http://${{api.RAILWAY_PRIVATE_DOMAIN}}:3000
```

**worker service:**
```
NODE_ENV=production
QUEUE_URL=${{Redis.REDIS_URL}}
API_ENDPOINT=http://${{api.RAILWAY_PRIVATE_DOMAIN}}:3000
```

---

## Part 2: Cloudflare DNS Automation (2 minutes)

Now that Railway services are deployed, automate DNS:

### Get Railway Domains
From each service in Railway dashboard:
- Go to Settings → Networking
- Copy the "Public Domain" (e.g., `web-production.up.railway.app`)

### Run the DNS Setup Script

```bash
./setup-cloudflare-dns-automated.sh
```

This will:
1. Prompt for Railway domains
2. Create/update CNAME records in Cloudflare
3. Enable proxy (orange cloud)
4. Configure SSL/TLS settings

---

## Part 3: Verification Checklist

After setup:

- [ ] All 4 services show "Active" in Railway
- [ ] Custom domains added in Railway (www, api)
- [ ] Environment variables configured
- [ ] DNS records created in Cloudflare
- [ ] Test endpoints:
  - `https://www.blackroad.io` → Returns 200
  - `https://blackroad.io` → Redirects to www
  - `https://api.blackroad.io/health` → Returns 200
- [ ] SSL certificates issued (check padlock icon)
- [ ] Check Railway logs for any errors

---

## DNS Record Summary

After running the script, your Cloudflare DNS should have:

| Type  | Name | Target                              | Proxy | TTL  |
|-------|------|-------------------------------------|-------|------|
| CNAME | www  | web-production.up.railway.app       | ✅ Yes | Auto |
| CNAME | @    | web-production.up.railway.app       | ✅ Yes | Auto |
| CNAME | api  | api-production.up.railway.app       | ✅ Yes | Auto |

---

## Cost Estimate

Railway pricing (per month):
- **Hobby Plan:** $5/month per user
- **Usage:** ~$10-20/month for 4 small services
- **Database:** ~$5/month for Postgres (512MB)

**Total:** ~$20-30/month for br-apps project

---

## Scaling to Other Domains

Once br-apps is working, repeat this pattern for:

1. **br-internal** (blackroad.systems)
   - Same structure
   - Different repos (internal tools)
   - Separate Railway project

2. **lucidia-engine** (lucidia.earth)
   - Visualization services
   - Game engine APIs

3. **br-company** (blackroad.company)
   - Company site
   - Docs/marketing

Follow the same: **Project → Environments → Services → DNS** pattern.

---

## Troubleshooting

### Service won't build
- Check Dockerfile or buildpack detection in Railway logs
- Verify start command in package.json or Dockerfile
- Check for missing environment variables

### Domain shows "Not Found"
- Verify CNAME target matches Railway domain exactly
- Check Cloudflare proxy is enabled (orange cloud)
- Wait 5-10 minutes for DNS propagation

### Services can't communicate
- Use Railway's private networking: `${{service-name.RAILWAY_PRIVATE_DOMAIN}}`
- Don't use public URLs for internal service-to-service calls

### Database connection fails
- Check `DATABASE_URL` is set correctly
- Verify Postgres service is running in Railway
- Check connection limits (Hobby plan: 25 connections)

---

## Next Steps

1. ✅ Complete br-apps setup
2. Test all endpoints thoroughly
3. Monitor Railway usage dashboard
4. Set up monitoring (e.g., Better Uptime, Sentry)
5. Create br-internal for blackroad.systems
6. Replicate pattern for other domains

---

## Reference Links

- Railway Dashboard: https://railway.app/dashboard
- Railway Docs: https://docs.railway.app
- Cloudflare Dashboard: https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a
- blackroad.io Zone: https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/blackroad.io

---

## Credentials Reference

**Railway:**
- Email: amundsonalexa@gmail.com
- Config: `~/.railway/config.json`

**Cloudflare:**
- Email: amundsonalexa@gmail.com
- Zone ID: `848cf0b18d51e0170e0d1537aec3505a`
- API Token: (stored in ~/.zshrc)

**GitHub:**
- Org: blackboxprogramming
- Repos: blackroad-os-web, blackroad-os-api, blackroad-os-api-gateway, blackroad-os-agents

---

**Created:** 2025-12-14
**Status:** Ready for implementation
**Owner:** Alexa Amundson (amundsonalexa@gmail.com)

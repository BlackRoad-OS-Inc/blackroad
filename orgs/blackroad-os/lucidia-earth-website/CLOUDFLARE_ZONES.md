# Cloudflare Zones & Domains Reference

**Complete inventory of all Cloudflare zones, domains, and their configurations**

This is the authoritative reference for all domains managed in Cloudflare.

---

## 📊 Overview

**Total Zones:** 16+
**Total Pages Projects:** 8+
**Total KV Namespaces:** 8+
**Total D1 Databases:** 1+

---

## 🌐 All Zones

### lucidia.earth

**Zone ID:** `a91af33930bb9b9ddfa0cf12c0232460`
**Account:** Amundsonalexa@gmail.com's Account
**Account ID:** `848cf0b18d51e0170e0d1537aec3505a`
**Status:** Active
**Name Servers:** chad.ns.cloudflare.com, jade.ns.cloudflare.com

#### DNS Records

```bash
# Get all records
curl -X GET "https://api.cloudflare.com/client/v4/zones/a91af33930bb9b9ddfa0cf12c0232460/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN"
```

**Current Records:**
- `lucidia.earth` → CNAME → `lucidia-earth.pages.dev` (proxied)
- `www.lucidia.earth` → A → `174.138.44.45` (proxied)
- `api.lucidia.earth` → CNAME → `blackroad-lucidia-enhanced.up.railway.app` (proxied)
- `browser.lucidia.earth` → CNAME → `lucidia-browser-os.vercel.app` (proxied)
- `consciousness.lucidia.earth` → CNAME → `blackroad-consciousness.up.railway.app` (proxied)
- `console.lucidia.earth` → A → `174.138.44.45` (proxied)
- `desktop.lucidia.earth` → A → `174.138.44.45` (proxied)
- `os.lucidia.earth` → A → `174.138.44.45` (proxied)

#### Pages Projects

**lucidia-earth** - Main visualization and game system
- Production URL: `https://lucidia-earth.pages.dev`
- Custom Domain: `https://lucidia.earth`
- GitHub Repo: `BlackRoad-OS/lucidia-earth-website`
- Deploy Command: `wrangler pages deploy out --project-name=lucidia-earth`

---

### lucidiaqi.com

**Zone ID:** `8a787536b6dd285bdf06dde65e96e8c0`
**Account:** Amundsonalexa@gmail.com's Account

#### Quick Operations

```bash
# Add DNS record
curl -X POST "https://api.cloudflare.com/client/v4/zones/8a787536b6dd285bdf06dde65e96e8c0/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"type":"CNAME","name":"@","content":"target.pages.dev","ttl":1,"proxied":true}'
```

---

### lucidia.studio

**Zone ID:** `43edda4c64475e5d81934ec7f64f6801`
**Account:** Amundsonalexa@gmail.com's Account

---

## 📄 Cloudflare Pages Projects

### All Projects Inventory

```bash
# List all projects
wrangler pages project list

# Expected output format:
# Project Name          | Domains                           | GitHub | Last Deploy
# --------------------- | --------------------------------- | ------ | -----------
# lucidia-earth         | lucidia-earth.pages.dev, ...      | No     | X mins ago
# blackroad-os-web      | blackroad-os-web.pages.dev, ...   | Yes    | X hours ago
```

### lucidia-earth

**Project Name:** `lucidia-earth`
**Account ID:** `848cf0b18d51e0170e0d1537aec3505a`
**Production URL:** `https://lucidia-earth.pages.dev`
**Custom Domains:** `lucidia.earth`
**GitHub Integration:** No (manual deploys via wrangler)

**Deploy Commands:**
```bash
# Build
pnpm build

# Deploy
wrangler pages deploy out --project-name=lucidia-earth

# Add custom domain (use dashboard)
# https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages/view/lucidia-earth/settings/domains
```

**Routes:**
- `/` - Home page
- `/biomes` - Canonical Earth template
- `/biomes-infinite` - Infinite procedural biomes
- `/biomes-pixel` - Pixelated style
- `/fractal-terrain` - Fractal heightmap
- `/genesis` - Genesis simulation
- `/game` - Open world game
- `/game-biomes-survival` - Survival game
- `/game-jupiter-explorer` - Space flight sim
- `/jupiter` - Jupiter system
- `/living-world` - Dynamic entities
- `/global-network` - Network visualization
- `/street-level` - MapLibre GL map

---

### blackroad-os-web

**Project Name:** `blackroad-os-web`
**Account ID:** `848cf0b18d51e0170e0d1537aec3505a`
**Production URL:** `https://blackroad-os-web.pages.dev`
**Custom Domains:**
- `blackroadqi.com`
- `blackroadquantum.info`
- `blackroadquantum.net`
- `blackroadquantum.shop`
- `blackroadquantum.store`

**GitHub Integration:** Yes

---

### blackroad-os-docs

**Project Name:** `blackroad-os-docs`
**Account ID:** `848cf0b18d51e0170e0d1537aec3505a`
**Production URL:** `https://blackroad-os-docs.pages.dev`
**GitHub Integration:** Yes

---

## 🔧 Workers & Routes

### List All Workers

```bash
# List workers
wrangler deployments list

# List routes for a zone
curl -X GET "https://api.cloudflare.com/client/v4/zones/ZONE_ID/workers/routes" \
  -H "Authorization: Bearer $CF_TOKEN"
```

---

## 🗄️ KV Namespaces

### List All Namespaces

```bash
wrangler kv:namespace list
```

### Expected Namespaces (8+)

Based on your infrastructure, you likely have:
- Memory/consciousness storage namespaces
- Session management namespaces
- Cache namespaces
- Configuration namespaces

**To document a namespace:**
```bash
# Get namespace details
wrangler kv:namespace list

# List keys in namespace
wrangler kv:key list --namespace-id=NAMESPACE_ID

# Get specific value
wrangler kv:key get --namespace-id=NAMESPACE_ID "key"
```

---

## 💾 D1 Databases

### List All Databases

```bash
wrangler d1 list
```

### Database Operations

```bash
# Query database
wrangler d1 execute DATABASE_NAME --remote --command="SELECT * FROM table"

# Execute schema
wrangler d1 execute DATABASE_NAME --remote --file=./schema.sql

# Show tables
wrangler d1 execute DATABASE_NAME --remote --command=".tables"
```

---

## 🔐 Authentication Reference

### Primary API Token

**Token:** `yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy` (stored in environment)

**Permissions:**
- Zone: DNS: Edit/Read
- Zone: Read

**Usage:**
```bash
export CF_TOKEN="yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy"

# Verify token
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CF_TOKEN"
```

### Wrangler Authentication

```bash
# Current status
wrangler whoami

# Expected output:
# Email: amundsonalexa@gmail.com
# Account ID: 848cf0b18d51e0170e0d1537aec3505a
```

**Wrangler Token Permissions:**
- account (read)
- user (read)
- workers (write)
- workers_kv (write)
- workers_routes (write)
- workers_scripts (write)
- workers_tail (read)
- d1 (write)
- pages (write)
- zone (read)
- ssl_certs (write)
- ai (write)
- queues (write)
- pipelines (write)
- secrets_store (write)
- containers (write)
- cloudchamber (write)
- connectivity (admin)
- offline_access

---

## 📋 Common Operations by Domain

### lucidia.earth Operations

#### Add Subdomain

```bash
# 1. Add DNS record
curl -X POST "https://api.cloudflare.com/client/v4/zones/a91af33930bb9b9ddfa0cf12c0232460/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "subdomain",
    "content": "target.pages.dev",
    "ttl": 1,
    "proxied": true
  }'

# 2. Verify
curl -I https://subdomain.lucidia.earth
```

#### Update Main Site

```bash
# 1. Navigate to project
cd /Users/alexa/projects/lucidia-earth

# 2. Build
pnpm build

# 3. Deploy
wrangler pages deploy out --project-name=lucidia-earth

# 4. Verify
curl -I https://lucidia.earth
```

#### Add New Route to Pages

```bash
# 1. Create Next.js route
mkdir -p app/new-route
echo "'use client';" > app/new-route/page.tsx
echo "export default function NewRoute() {" >> app/new-route/page.tsx
echo "  return <iframe src='/new-route.html' className='w-full h-screen border-0' />;" >> app/new-route/page.tsx
echo "}" >> app/new-route/page.tsx

# 2. Create HTML visualization
touch public/new-route.html

# 3. Build and deploy
pnpm build
wrangler pages deploy out --project-name=lucidia-earth

# 4. Access at https://lucidia.earth/new-route
```

---

## 🚨 Emergency Procedures

### Site Down - Rollback Deployment

```bash
# List recent deployments
wrangler pages deployment list --project-name=lucidia-earth

# Pages will automatically serve last good deployment
# To force redeploy:
wrangler pages deploy out --project-name=lucidia-earth
```

### DNS Not Resolving

```bash
# Check DNS record exists
curl -X GET "https://api.cloudflare.com/client/v4/zones/a91af33930bb9b9ddfa0cf12c0232460/dns_records?name=lucidia.earth" \
  -H "Authorization: Bearer $CF_TOKEN"

# Verify proxied status
# Should show "proxied": true

# Check domain resolves
dig lucidia.earth
nslookup lucidia.earth

# Check if Cloudflare is serving
curl -I https://lucidia.earth | grep "cf-ray"
```

### Custom Domain SSL Issues

**Wait 1-2 minutes after adding custom domain for SSL provisioning.**

```bash
# Check SSL status
curl -I https://example.com

# Expected: HTTP/2 200
# If error 525: SSL handshake failed, wait longer
# If error 526: Invalid SSL certificate, check domain settings
```

### Worker Not Responding

```bash
# Check worker is deployed
wrangler deployments list

# Check routes
curl -X GET "https://api.cloudflare.com/client/v4/zones/ZONE_ID/workers/routes" \
  -H "Authorization: Bearer $CF_TOKEN"

# Re-deploy
wrangler deploy

# Check logs
wrangler tail
```

---

## 📞 Dashboard Quick Links

### Main Dashboards

- **Cloudflare Home:** `https://dash.cloudflare.com/`
- **Account Dashboard:** `https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a`

### Zone Dashboards

- **lucidia.earth DNS:** `https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/lucidia.earth/dns`
- **lucidia.earth Analytics:** `https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/lucidia.earth/analytics`

### Pages Dashboards

- **All Pages:** `https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages`
- **lucidia-earth Project:** `https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages/view/lucidia-earth`
- **lucidia-earth Domains:** `https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages/view/lucidia-earth/settings/domains`

### Workers & KV

- **Workers:** `https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/workers`
- **KV Namespaces:** `https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/workers/kv/namespaces`
- **D1 Databases:** `https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/workers/d1`

### API Tokens

- **API Tokens:** `https://dash.cloudflare.com/profile/api-tokens`
- **Create Token:** `https://dash.cloudflare.com/profile/api-tokens/create`

---

## 🔄 Sync with Infrastructure Docs

This file should be kept in sync with:
- `~/blackroad-backup/INFRASTRUCTURE_INVENTORY.md`
- `~/blackroad-backup/CLOUDFLARE_INFRA.md`
- `~/.claude/CLAUDE.md`

When making changes:
1. Update this file
2. Update infrastructure docs
3. Commit to git
4. Push to GitHub

---

## 📝 Adding New Domains

### Complete Workflow

```bash
# 1. Add zone to Cloudflare (if new domain)
# Do this via dashboard: https://dash.cloudflare.com/

# 2. Update nameservers at registrar
# Nameservers will be provided by Cloudflare

# 3. Add DNS records
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "@",
    "content": "target.pages.dev",
    "ttl": 1,
    "proxied": true
  }'

# 4. Add to Pages project (via dashboard)
# https://dash.cloudflare.com/ACCOUNT_ID/pages/view/PROJECT_NAME/settings/domains

# 5. Wait for SSL provisioning (1-2 minutes)

# 6. Verify
curl -I https://new-domain.com

# 7. Document here
# Add zone ID, DNS records, project mappings to this file

# 8. Commit changes
git add CLOUDFLARE_ZONES.md
git commit -m "Add new domain: new-domain.com"
git push
```

---

## 🎯 Quick Commands Cheat Sheet

```bash
# List all zones
curl -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CF_TOKEN" | python3 -m json.tool

# List all DNS for lucidia.earth
curl -X GET "https://api.cloudflare.com/client/v4/zones/a91af33930bb9b9ddfa0cf12c0232460/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" | python3 -m json.tool

# List all Pages projects
wrangler pages project list

# Deploy to lucidia-earth
cd /Users/alexa/projects/lucidia-earth && pnpm build && wrangler pages deploy out --project-name=lucidia-earth

# List all workers
wrangler deployments list

# List all KV namespaces
wrangler kv:namespace list

# List all D1 databases
wrangler d1 list

# Check authentication
wrangler whoami

# Verify API token
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CF_TOKEN"
```

---

**Last Updated:** 2025-12-23
**Maintainer:** BlackRoad OS
**Primary Account:** amundsonalexa@gmail.com
**Account ID:** 848cf0b18d51e0170e0d1537aec3505a

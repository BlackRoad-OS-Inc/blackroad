# Cloudflare Infrastructure Guide

**Complete reference for managing all Cloudflare services and domains**

This guide provides exact procedures for every Cloudflare operation so any Claude instance can execute them correctly.

---

## 📋 Table of Contents

1. [DNS Management](#dns-management)
2. [Pages Custom Domains](#pages-custom-domains)
3. [Workers & Routes](#workers--routes)
4. [KV Namespaces](#kv-namespaces)
5. [D1 Databases](#d1-databases)
6. [Cloudflare Tunnel](#cloudflare-tunnel)
7. [API Authentication](#api-authentication)
8. [Troubleshooting](#troubleshooting)

---

## DNS Management

### Prerequisites
- Zone ID for the domain
- API token with `Zone:DNS:Edit` permissions
- OR wrangler CLI authenticated

### List All DNS Records

```bash
# Using API
curl -X GET "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json"

# Find specific domain's zone ID
curl -X GET "https://api.cloudflare.com/client/v4/zones?name=example.com" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json"
```

### Add CNAME Record (for Pages/Workers)

```bash
# Add CNAME pointing to Pages
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "@",
    "content": "project-name.pages.dev",
    "ttl": 1,
    "proxied": true
  }'

# Add subdomain CNAME
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "app",
    "content": "project-name.pages.dev",
    "ttl": 1,
    "proxied": true
  }'
```

### Add A Record (for servers)

```bash
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "A",
    "name": "api",
    "content": "192.168.1.1",
    "ttl": 1,
    "proxied": true
  }'
```

### Update DNS Record

```bash
# Get record ID first
curl -X GET "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records?name=example.com" \
  -H "Authorization: Bearer API_TOKEN"

# Update the record
curl -X PUT "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records/RECORD_ID" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "@",
    "content": "new-target.pages.dev",
    "ttl": 1,
    "proxied": true
  }'
```

### Delete DNS Record

```bash
curl -X DELETE "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records/RECORD_ID" \
  -H "Authorization: Bearer API_TOKEN"
```

---

## Pages Custom Domains

### ⚠️ IMPORTANT: Authentication Requirements

**Pages custom domains require account-level permissions.** Standard API tokens often don't work.

### Method 1: Using Cloudflare Dashboard (RECOMMENDED)

This is the most reliable method for adding custom domains to Pages projects.

1. Navigate to: `https://dash.cloudflare.com/ACCOUNT_ID/pages/view/PROJECT_NAME/settings/domains`
2. Click **"Add a custom domain"**
3. Enter the domain name (e.g., `example.com` or `app.example.com`)
4. Cloudflare will automatically detect the DNS record
5. Wait 1-2 minutes for SSL certificate provisioning

### Method 2: Using Wrangler CLI (if authenticated)

```bash
# Check authentication
wrangler whoami

# Deploy and let wrangler handle domain
# (Custom domain must be added via dashboard first)
wrangler pages deploy out --project-name=project-name
```

### Method 3: Using API (requires special token)

**Note:** This often fails with "Authentication error" if token lacks Pages permissions.

```bash
# Attempt to add custom domain
curl -X POST "https://api.cloudflare.com/client/v4/accounts/ACCOUNT_ID/pages/projects/PROJECT_NAME/domains" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"name":"example.com"}'

# List existing domains
curl -X GET "https://api.cloudflare.com/client/v4/accounts/ACCOUNT_ID/pages/projects/PROJECT_NAME/domains" \
  -H "Authorization: Bearer API_TOKEN"
```

### Complete Workflow for Custom Domain

```bash
# Step 1: Add DNS CNAME record
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "@",
    "content": "project-name.pages.dev",
    "ttl": 1,
    "proxied": true
  }'

# Step 2: Build your project
pnpm build

# Step 3: Deploy to Pages
wrangler pages deploy out --project-name=project-name

# Step 4: Add custom domain via dashboard
# Visit: https://dash.cloudflare.com/ACCOUNT_ID/pages/view/PROJECT_NAME/settings/domains
# Click "Add a custom domain" and enter your domain

# Step 5: Verify deployment
curl -I https://example.com
```

### Finding Account IDs and Project Names

```bash
# List all Pages projects
wrangler pages project list

# Get account ID from wrangler
wrangler whoami
```

---

## Workers & Routes

### Deploy Worker

```bash
# Deploy worker from directory
cd worker-directory
wrangler deploy

# Deploy with specific name
wrangler deploy --name worker-name

# Deploy with environment
wrangler deploy --env production
```

### Add Custom Domain Route to Worker

```bash
# Add route via wrangler.toml
# Edit wrangler.toml:
routes = [
  { pattern = "api.example.com/*", zone_name = "example.com" }
]

# Or use API
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/workers/routes" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "pattern": "api.example.com/*",
    "script": "worker-name"
  }'
```

### List Worker Routes

```bash
curl -X GET "https://api.cloudflare.com/client/v4/zones/ZONE_ID/workers/routes" \
  -H "Authorization: Bearer API_TOKEN"
```

### Delete Worker Route

```bash
curl -X DELETE "https://api.cloudflare.com/client/v4/zones/ZONE_ID/workers/routes/ROUTE_ID" \
  -H "Authorization: Bearer API_TOKEN"
```

---

## KV Namespaces

### Create KV Namespace

```bash
# Using wrangler
wrangler kv:namespace create "NAMESPACE_NAME"

# For production
wrangler kv:namespace create "NAMESPACE_NAME" --preview false
```

### List KV Namespaces

```bash
wrangler kv:namespace list
```

### Add to wrangler.toml

```toml
kv_namespaces = [
  { binding = "MY_KV", id = "abc123..." }
]
```

### Write to KV

```bash
# Single key
wrangler kv:key put --namespace-id=NAMESPACE_ID "key" "value"

# From file
wrangler kv:key put --namespace-id=NAMESPACE_ID "key" --path=./file.json

# Bulk upload
wrangler kv:bulk put --namespace-id=NAMESPACE_ID ./data.json
```

### Read from KV

```bash
wrangler kv:key get --namespace-id=NAMESPACE_ID "key"
```

### List KV Keys

```bash
wrangler kv:key list --namespace-id=NAMESPACE_ID
```

### Delete from KV

```bash
wrangler kv:key delete --namespace-id=NAMESPACE_ID "key"
```

---

## D1 Databases

### Create D1 Database

```bash
# Create database
wrangler d1 create DATABASE_NAME

# Output will give you database ID
# Add to wrangler.toml:
[[d1_databases]]
binding = "DB"
database_name = "DATABASE_NAME"
database_id = "abc123..."
```

### Execute SQL

```bash
# Local
wrangler d1 execute DATABASE_NAME --local --file=./schema.sql

# Remote
wrangler d1 execute DATABASE_NAME --remote --file=./schema.sql

# Single command
wrangler d1 execute DATABASE_NAME --remote --command="SELECT * FROM users"
```

### List Databases

```bash
wrangler d1 list
```

### Migrations

```bash
# Create migration
wrangler d1 migrations create DATABASE_NAME "migration_name"

# Apply migrations
wrangler d1 migrations apply DATABASE_NAME --local
wrangler d1 migrations apply DATABASE_NAME --remote
```

---

## Cloudflare Tunnel

### Create Tunnel

```bash
# Login first
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create TUNNEL_NAME

# Output will give you tunnel ID
```

### Configure Tunnel

Create `config.yml`:

```yaml
tunnel: TUNNEL_ID
credentials-file: /path/to/TUNNEL_ID.json

ingress:
  - hostname: app.example.com
    service: http://localhost:3000
  - hostname: api.example.com
    service: http://localhost:8000
  - service: http_status:404
```

### Add DNS for Tunnel

```bash
cloudflared tunnel route dns TUNNEL_NAME app.example.com
cloudflared tunnel route dns TUNNEL_NAME api.example.com
```

### Run Tunnel

```bash
# Run once
cloudflared tunnel run TUNNEL_NAME

# Install as service
cloudflared service install
```

### List Tunnels

```bash
cloudflared tunnel list
```

### Delete Tunnel

```bash
# Cleanup routes first
cloudflared tunnel route dns --delete TUNNEL_NAME app.example.com

# Delete tunnel
cloudflared tunnel delete TUNNEL_NAME
```

---

## API Authentication

### Get API Token

1. Visit: https://dash.cloudflare.com/profile/api-tokens
2. Click **"Create Token"**
3. Select template or create custom token
4. Required permissions vary by operation:
   - **DNS**: `Zone:DNS:Edit`
   - **Pages**: `Account:Cloudflare Pages:Edit`
   - **Workers**: `Account:Workers Scripts:Edit`
   - **KV**: `Account:Workers KV Storage:Edit`
   - **D1**: `Account:D1:Edit`

### Verify Token

```bash
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer API_TOKEN"
```

### Wrangler Authentication

```bash
# Login with browser
wrangler login

# Check current auth
wrangler whoami

# Logout
wrangler logout
```

### Environment Variables

```bash
# Set in shell
export CLOUDFLARE_API_TOKEN="your_token"
export CLOUDFLARE_ACCOUNT_ID="your_account_id"

# Use in scripts
curl -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" ...
```

---

## Troubleshooting

### "Authentication error" (Code 10000)

**Problem:** API token doesn't have required permissions for the account/zone.

**Solutions:**
1. Check token permissions at https://dash.cloudflare.com/profile/api-tokens
2. Create new token with required scopes
3. Use `wrangler login` for interactive auth
4. Use dashboard for operations that require special permissions (like Pages custom domains)

### DNS Record Already Exists (Code 81053)

**Problem:** Trying to create duplicate DNS record.

**Solutions:**
```bash
# List existing records
curl -X GET "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records?name=example.com" \
  -H "Authorization: Bearer API_TOKEN"

# Update instead of create
curl -X PUT "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records/RECORD_ID" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{ ... }'
```

### Pages Deployment 403 Forbidden

**Problem:** Wrangler/API lacks permissions for Pages account.

**Solutions:**
1. Use `wrangler login` to authenticate interactively
2. Check account ID matches: `wrangler whoami`
3. Ensure you're deploying to correct project name
4. Create API token with `Account:Cloudflare Pages:Edit` permission

### Custom Domain Not Working

**Checklist:**
1. ✅ DNS CNAME record exists and points to `project-name.pages.dev`
2. ✅ Custom domain added in Pages dashboard
3. ✅ SSL certificate provisioned (wait 1-2 minutes)
4. ✅ DNS is proxied (orange cloud in dashboard)
5. ✅ Test with `curl -I https://example.com`

### Worker Route Not Triggering

**Checklist:**
1. ✅ DNS record exists for the hostname
2. ✅ Worker route pattern matches URL exactly
3. ✅ Worker is deployed: `wrangler deployments list`
4. ✅ Route is in correct zone
5. ✅ Check route priority (more specific routes first)

### KV "Not Found" Errors

**Problem:** Namespace binding not configured or wrong namespace ID.

**Solutions:**
```bash
# List namespaces to verify ID
wrangler kv:namespace list

# Check wrangler.toml binding
kv_namespaces = [
  { binding = "MY_KV", id = "correct_id_here" }
]

# Re-deploy after updating wrangler.toml
wrangler deploy
```

---

## Quick Reference: Account IDs

Based on your infrastructure:

```bash
# Primary account (amundsonalexa@gmail.com)
ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

# Other account
ACCOUNT_ID="463024cf9efed5e7b40c5fbe7938e256"
```

### Zone IDs (Examples)

```bash
# lucidia.earth
ZONE_ID="a91af33930bb9b9ddfa0cf12c0232460"

# Get any zone ID
curl -X GET "https://api.cloudflare.com/client/v4/zones?name=example.com" \
  -H "Authorization: Bearer API_TOKEN" \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['result'][0]['id'])"
```

---

## Common Workflows

### Deploy Next.js to Pages with Custom Domain

```bash
# 1. Build
pnpm build

# 2. Deploy
wrangler pages deploy out --project-name=my-project

# 3. Add DNS (if not exists)
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "@",
    "content": "my-project.pages.dev",
    "ttl": 1,
    "proxied": true
  }'

# 4. Add custom domain via dashboard
# https://dash.cloudflare.com/ACCOUNT_ID/pages/view/my-project/settings/domains

# 5. Verify
curl -I https://example.com
```

### Deploy Worker with Custom Domain

```bash
# 1. Configure wrangler.toml
name = "my-worker"
main = "src/index.ts"
compatibility_date = "2025-12-23"

routes = [
  { pattern = "api.example.com/*", zone_name = "example.com" }
]

# 2. Deploy
wrangler deploy

# 3. Add DNS (if not exists)
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "api",
    "content": "example.com",
    "ttl": 1,
    "proxied": true
  }'

# 4. Test
curl https://api.example.com/endpoint
```

### Connect Local App via Tunnel

```bash
# 1. Create tunnel
cloudflared tunnel create my-app

# 2. Create config.yml
tunnel: TUNNEL_ID
credentials-file: ~/.cloudflared/TUNNEL_ID.json

ingress:
  - hostname: app.example.com
    service: http://localhost:3000
  - service: http_status:404

# 3. Add DNS
cloudflared tunnel route dns my-app app.example.com

# 4. Run tunnel
cloudflared tunnel run my-app
```

---

## Best Practices

### DNS Management
- ✅ Always use `proxied: true` for Cloudflare features (caching, DDoS protection)
- ✅ Use `ttl: 1` (auto) for proxied records
- ✅ Check existing records before creating new ones
- ✅ Use CNAME for Pages/Workers, A records for direct IPs

### Pages Deployments
- ✅ Use `wrangler pages deploy` over API for deployments
- ✅ Add custom domains via dashboard for reliability
- ✅ Wait 1-2 minutes after adding domain for SSL provisioning
- ✅ Test with both `https://project.pages.dev` and custom domain

### Workers
- ✅ Define routes in `wrangler.toml` for version control
- ✅ Use specific route patterns (`api.example.com/*` not `*.example.com/*`)
- ✅ Test locally with `wrangler dev` before deploying
- ✅ Use environment variables for secrets

### Security
- ✅ Use scoped API tokens (not global API key)
- ✅ Store tokens in environment variables
- ✅ Rotate tokens regularly
- ✅ Use separate tokens for different services

---

**Last Updated:** 2025-12-23
**Maintainer:** BlackRoad OS
**For:** Any Claude instance managing Cloudflare infrastructure

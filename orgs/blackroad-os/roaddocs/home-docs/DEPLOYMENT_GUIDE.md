# BlackRoad Infrastructure Deployment Guide

Complete guide for deploying and managing BlackRoad web services across Cloudflare Pages and Railway.

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Services Registry](#services-registry)
4. [Quick Start](#quick-start)
5. [Deployment Instructions](#deployment-instructions)
6. [Cloudflare + Railway Wiring](#cloudflare--railway-wiring)
7. [Environment Variables](#environment-variables)
8. [Service URLs](#service-urls)

---

## Overview

This infrastructure provides a complete web service framework for BlackRoad, covering:

- **24 total services** across 2 domains (blackroad.io and blackroad.systems)
- **13 unique service implementations**
- **Dual deployment targets**: Cloudflare Pages (preview) and Railway (production)
- **Next.js 14** with App Router for all frontend services
- **Standardized health checks** and monitoring endpoints

### Deployment Targets

- **blackroad.io**: Development/preview environment (Cloudflare Pages)
- **blackroad.systems**: Production environment (Railway)

---

## Project Structure

```
/Users/alexa/
├── infra/
│   └── blackroad_registry.json          # Master service registry (24 services)
│
├── templates/
│   └── web-service/                     # Universal Next.js template
│       ├── app/
│       │   ├── api/
│       │   │   ├── health/route.ts      # Health check endpoint
│       │   │   ├── version/route.ts     # Version info endpoint
│       │   │   └── ready/route.ts       # Readiness probe
│       │   ├── layout.tsx               # Root layout
│       │   └── page.tsx                 # Homepage
│       ├── Dockerfile                   # Multi-stage build
│       ├── railway.json                 # Railway config
│       ├── next.config.mjs              # Next.js config
│       ├── tsconfig.json                # TypeScript config
│       ├── package.json                 # Dependencies
│       ├── .env.example                 # Environment template
│       ├── .gitignore                   # Git ignore rules
│       └── README.md                    # Template documentation
│
└── services/
    ├── web/                             # Main website service
    ├── prism/                           # Prism console service
    └── operator/                        # Operator panel service
```

---

## Services Registry

The master registry at `infra/blackroad_registry.json` contains:

### blackroad.io Services (13 services)

| Subdomain | Service Name | Type | Cloudflare Target |
|-----------|--------------|------|-------------------|
| web | blackroad-os-web | nextjs-frontend | blackroad-os-web.pages.dev |
| api | blackroad-os-api | node-api | blackroad-os-api.pages.dev |
| brand | blackroad-os-brand | nextjs-frontend | blackroad-os-brand.pages.dev |
| console | blackroad-os-prism-console | nextjs-frontend | blackroad-os-prism-console.pages.dev |
| core | blackroad-os-core | nextjs-frontend | blackroad-os-core.pages.dev |
| dashboard | blackroad-os-operator | nextjs-frontend | blackroad-os-operator.pages.dev |
| demo | blackroad-os-demo | nextjs-frontend | blackroad-os-demo.pages.dev |
| docs | blackroad-os-docs | nextjs-frontend | blackroad-os-docs.pages.dev |
| ideas | blackroad-os-ideas | nextjs-frontend | blackroad-os-ideas.pages.dev |
| infra | blackroad-os-infra | nextjs-frontend | blackroad-os-infra.pages.dev |
| operator | blackroad-os-operator | nextjs-frontend | blackroad-os-operator.pages.dev |
| prism | blackroad-os-prism-console | nextjs-frontend | blackroad-os-prism-console.pages.dev |
| research | blackroad-os-research | nextjs-frontend | blackroad-os-research.pages.dev |

### blackroad.systems Services (11 services)

| Subdomain | Service Name | Type | Railway URL |
|-----------|--------------|------|-------------|
| api | blackroad-os-api | node-api | blackroad-os-api-production-ff5a.up.railway.app |
| brand | blackroad-os-brand | nextjs-frontend | blackroad-os-brand-production.up.railway.app |
| console | blackroad-os-prism-console | nextjs-frontend | blackroad-os-prism-console-production-3118.up.railway.app |
| core | blackroad-os-core | nextjs-frontend | blackroad-os-core-production.up.railway.app |
| docs | blackroad-os-docs | nextjs-frontend | blackroad-os-docs-production-d8de.up.railway.app |
| ideas | blackroad-os-ideas | nextjs-frontend | blackroad-os-ideas-production.up.railway.app |
| infra | blackroad-os-infra | nextjs-frontend | blackroad-os-infra-production.up.railway.app |
| operator | blackroad-os-operator | nextjs-frontend | blackroad-os-operator-production-021e.up.railway.app |
| prism | blackroad-prism-console | nextjs-frontend | blackroad-prism-console-production.up.railway.app |
| research | blackroad-os-research | nextjs-frontend | blackroad-os-research-production.up.railway.app |
| web | blackroad-os-web | nextjs-frontend | blackroad-os-web-production-a2ee.up.railway.app |

---

## Quick Start

### 1. Local Development - Web Service

```bash
cd services/web
cp .env.example .env
npm install
npm run dev
```

Visit `http://localhost:3000`

### 2. Local Development - Prism Service

```bash
cd services/prism
cp .env.example .env
npm install
npm run dev
```

Visit `http://localhost:3001`

### 3. Local Development - Operator Service

```bash
cd services/operator
cp .env.example .env
npm install
npm run dev
```

Visit `http://localhost:3002`

### 4. Test Health Endpoints

```bash
# Web service
curl http://localhost:3000/api/health
curl http://localhost:3000/api/version
curl http://localhost:3000/api/ready

# Prism service
curl http://localhost:3001/api/health

# Operator service
curl http://localhost:3002/api/health
```

---

## Deployment Instructions

### Deploy to Railway (Production)

#### Option 1: Railway CLI

```bash
cd services/web

# Login to Railway
railway login

# Link to project (or create new)
railway link

# Set environment variables
railway variables set SERVICE_NAME=blackroad-os-web
railway variables set SERVICE_ENV=production
railway variables set NEXT_PUBLIC_APP_NAME="BlackRoad Web"
railway variables set NEXT_PUBLIC_BASE_URL=https://web.blackroad.systems

# Deploy
railway up
```

#### Option 2: Railway Dashboard

1. Go to [railway.app](https://railway.app)
2. Create a new project or select existing
3. Connect GitHub repository
4. Set root directory to `services/web` (or appropriate service)
5. Railway auto-detects `railway.json` configuration
6. Set environment variables in the dashboard:
   - `SERVICE_NAME=blackroad-os-web`
   - `SERVICE_ENV=production`
   - `NEXT_PUBLIC_APP_NAME=BlackRoad Web`
   - `NEXT_PUBLIC_BASE_URL=https://web.blackroad.systems`
7. Deploy

#### Railway Configuration

Railway will use the `railway.json` file which specifies:
- Builder: Nixpacks
- Build command: `npm install && npm run build`
- Start command: `npm start`
- Health check: `/api/health`
- Restart policy: On failure (max 10 retries)

### Deploy to Cloudflare Pages (Preview)

#### Via Cloudflare Dashboard

1. Go to Cloudflare Dashboard → Pages
2. Create a new project
3. Connect GitHub repository
4. Configure build:
   - **Build command**: `npm run build`
   - **Build output directory**: `.next`
   - **Root directory**: `services/web` (or appropriate service)
5. Set environment variables:
   - `SERVICE_NAME=blackroad-os-web`
   - `SERVICE_ENV=development`
   - `NEXT_PUBLIC_APP_NAME=BlackRoad Web`
6. Deploy

#### Via Wrangler CLI

```bash
cd services/web
npm run build
npx wrangler pages deploy .next --project-name blackroad-os-web
```

---

## Cloudflare + Railway Wiring

### Setting Up Custom Domains

#### For Production (blackroad.systems → Railway)

1. **Get Railway Service URL**
   - Example: `blackroad-os-web-production-a2ee.up.railway.app`

2. **Add Cloudflare DNS Record**
   - Type: `CNAME`
   - Name: `web` (for web.blackroad.systems)
   - Target: `blackroad-os-web-production-a2ee.up.railway.app`
   - Proxy status: **Proxied** (orange cloud)
   - TTL: Auto

3. **Update Railway Environment Variables**
   ```
   NEXT_PUBLIC_BASE_URL=https://web.blackroad.systems
   ```

4. **Verify**
   ```bash
   curl https://web.blackroad.systems/api/health
   ```

#### For Preview (blackroad.io → Cloudflare Pages)

1. **Get Cloudflare Pages URL**
   - Example: `blackroad-os-web.pages.dev`

2. **Add Cloudflare DNS Record**
   - Type: `CNAME`
   - Name: `web` (for web.blackroad.io)
   - Target: `blackroad-os-web.pages.dev`
   - Proxy status: **Proxied** (orange cloud)
   - TTL: Auto

3. **Verify**
   ```bash
   curl https://web.blackroad.io/api/health
   ```

### DNS Setup for All Services

Repeat the above process for each service subdomain:

**Production (blackroad.systems):**
```
api.blackroad.systems      → CNAME → blackroad-os-api-production-ff5a.up.railway.app
brand.blackroad.systems    → CNAME → blackroad-os-brand-production.up.railway.app
console.blackroad.systems  → CNAME → blackroad-os-prism-console-production-3118.up.railway.app
core.blackroad.systems     → CNAME → blackroad-os-core-production.up.railway.app
docs.blackroad.systems     → CNAME → blackroad-os-docs-production-d8de.up.railway.app
ideas.blackroad.systems    → CNAME → blackroad-os-ideas-production.up.railway.app
infra.blackroad.systems    → CNAME → blackroad-os-infra-production.up.railway.app
operator.blackroad.systems → CNAME → blackroad-os-operator-production-021e.up.railway.app
prism.blackroad.systems    → CNAME → blackroad-prism-console-production.up.railway.app
research.blackroad.systems → CNAME → blackroad-os-research-production.up.railway.app
web.blackroad.systems      → CNAME → blackroad-os-web-production-a2ee.up.railway.app
```

**Preview (blackroad.io):**
```
api.blackroad.io       → CNAME → blackroad-os-api.pages.dev
brand.blackroad.io     → CNAME → blackroad-os-brand.pages.dev
console.blackroad.io   → CNAME → blackroad-os-prism-console.pages.dev
core.blackroad.io      → CNAME → blackroad-os-core.pages.dev
dashboard.blackroad.io → CNAME → blackroad-os-operator.pages.dev
demo.blackroad.io      → CNAME → blackroad-os-demo.pages.dev
docs.blackroad.io      → CNAME → blackroad-os-docs.pages.dev
ideas.blackroad.io     → CNAME → blackroad-os-ideas.pages.dev
infra.blackroad.io     → CNAME → blackroad-os-infra.pages.dev
operator.blackroad.io  → CNAME → blackroad-os-operator.pages.dev
prism.blackroad.io     → CNAME → blackroad-os-prism-console.pages.dev
research.blackroad.io  → CNAME → blackroad-os-research.pages.dev
web.blackroad.io       → CNAME → blackroad-os-web.pages.dev
```

---

## Environment Variables

### Required Variables for All Services

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_NAME` | Unique service identifier | `blackroad-os-web` |
| `SERVICE_ENV` | Environment (development/production) | `production` |
| `NEXT_PUBLIC_APP_NAME` | Display name | `BlackRoad Web` |

### Optional Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_VERSION` | Service version | `0.0.1` |
| `NEXT_PUBLIC_BASE_URL` | Base URL for the service | `https://web.blackroad.systems` |
| `BUILD_TIME` | Build timestamp (auto-set) | `2025-11-24T12:00:00Z` |

### Setting Variables in Railway

```bash
# Via CLI
railway variables set SERVICE_NAME=blackroad-os-web
railway variables set SERVICE_ENV=production
railway variables set NEXT_PUBLIC_APP_NAME="BlackRoad Web"

# Or in Railway dashboard: Settings → Variables
```

### Setting Variables in Cloudflare Pages

1. Go to Pages → Your Project → Settings → Environment variables
2. Add variables for Production and/or Preview environments
3. Redeploy for changes to take effect

---

## Service URLs

### Development (Local)

- Web: `http://localhost:3000`
- Prism: `http://localhost:3001`
- Operator: `http://localhost:3002`

### Preview (blackroad.io)

- Web: `https://web.blackroad.io`
- Prism: `https://prism.blackroad.io`
- Operator: `https://operator.blackroad.io`
- Console: `https://console.blackroad.io` (alias for Prism)
- Dashboard: `https://dashboard.blackroad.io` (alias for Operator)

### Production (blackroad.systems)

- Web: `https://web.blackroad.systems`
- Prism: `https://prism.blackroad.systems`
- Operator: `https://operator.blackroad.systems`
- Console: `https://console.blackroad.systems`

### Direct URLs (without custom domains)

**Cloudflare Pages:**
- `https://blackroad-os-web.pages.dev`
- `https://blackroad-os-prism-console.pages.dev`
- `https://blackroad-os-operator.pages.dev`

**Railway:**
- `https://blackroad-os-web-production-a2ee.up.railway.app`
- `https://blackroad-prism-console-production.up.railway.app`
- `https://blackroad-os-operator-production-021e.up.railway.app`

---

## Creating a New Service

To add a new service using the template:

```bash
# 1. Copy template
cp -r templates/web-service services/my-new-service

# 2. Navigate to service
cd services/my-new-service

# 3. Update package.json name
# Edit package.json: "name": "blackroad-my-new-service"

# 4. Update environment variables
cp .env.example .env
# Edit .env:
# SERVICE_NAME=blackroad-my-new-service
# NEXT_PUBLIC_APP_NAME=My New Service

# 5. Customize app/page.tsx with your service content

# 6. Install dependencies
npm install

# 7. Test locally
npm run dev

# 8. Deploy to Railway or Cloudflare Pages
```

---

## Monitoring and Health Checks

All services include standardized endpoints:

### Health Check
```bash
curl https://web.blackroad.systems/api/health
```

Response:
```json
{
  "status": "ok",
  "service": "blackroad-os-web",
  "timestamp": "2025-11-24T12:00:00.000Z",
  "uptime": 12345.67
}
```

### Version Info
```bash
curl https://web.blackroad.systems/api/version
```

Response:
```json
{
  "version": "0.0.1",
  "service": "blackroad-os-web",
  "environment": "production",
  "node_version": "v20.x.x",
  "build_time": "2025-11-24T12:00:00.000Z"
}
```

### Readiness Probe
```bash
curl https://web.blackroad.systems/api/ready
```

Response:
```json
{
  "ready": true,
  "service": "blackroad-os-web"
}
```

---

## Troubleshooting

### Build Failures

1. **Check Node version**: Ensure Node 20+ is installed
   ```bash
   node --version  # Should be v20.x.x or higher
   ```

2. **Clear build cache**:
   ```bash
   rm -rf .next node_modules
   npm install
   npm run build
   ```

3. **Check Railway/Cloudflare logs** for specific error messages

### DNS Issues

1. **Verify CNAME records** in Cloudflare DNS
2. **Check proxy status** (should be orange cloud/proxied)
3. **Wait for DNS propagation** (can take up to 48 hours, usually minutes)
4. **Test with dig**:
   ```bash
   dig web.blackroad.systems
   ```

### Service Not Responding

1. **Check health endpoint**:
   ```bash
   curl https://web.blackroad.systems/api/health
   ```

2. **Check Railway logs**:
   ```bash
   railway logs
   ```

3. **Verify environment variables** are set correctly

4. **Check Railway deployment status** in dashboard

---

## Next Steps

1. **Deploy remaining services** using the template
2. **Set up CI/CD** pipelines for automated deployments
3. **Configure monitoring** and alerting
4. **Add authentication** to protected services
5. **Implement service-specific features** for each subdomain

---

## Support

- **Registry**: See `infra/blackroad_registry.json` for complete service mappings
- **Template**: See `templates/web-service/README.md` for detailed template documentation
- **Service READMEs**: Each service has its own README with specific instructions

---

**BlackRoad Infrastructure** · Generated 2025-11-24

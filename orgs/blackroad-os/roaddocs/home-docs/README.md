# BlackRoad Infrastructure

Complete web service infrastructure for BlackRoad ecosystem, spanning 24 services across multiple domains.

## Quick Overview

This repository contains:

- **Master Service Registry**: `infra/blackroad_registry.json` (24 services)
- **Universal Template**: `templates/web-service/` (Next.js 14 + TypeScript)
- **Live Services**: `services/` (web, prism, operator)
- **Deployment Guide**: `DEPLOYMENT_GUIDE.md` (complete instructions)

## Structure

```
.
├── infra/
│   └── blackroad_registry.json     # Master registry (24 services)
├── templates/
│   └── web-service/                # Universal Next.js template
├── services/
│   ├── web/                        # Main website
│   ├── prism/                      # Prism console
│   └── operator/                   # Operator panel
├── DEPLOYMENT_GUIDE.md             # Complete deployment guide
└── README.md                       # This file
```

## Services

### Deployed Services (3)

| Service | Local Port | Preview Domain | Production Domain |
|---------|------------|----------------|-------------------|
| Web | 3000 | web.blackroad.io | web.blackroad.systems |
| Prism | 3001 | prism.blackroad.io | prism.blackroad.systems |
| Operator | 3002 | operator.blackroad.io | operator.blackroad.systems |

### Registry Overview

- **Total Services**: 24 (across 2 domains)
- **Unique Implementations**: 13
- **Cloudflare Pages**: 13 services
- **Railway**: 11 services

See `infra/blackroad_registry.json` for complete mapping.

## Quick Start

### Run a Service Locally

```bash
# Web service
cd services/web
cp .env.example .env
npm install
npm run dev
# Visit http://localhost:3000

# Prism console
cd services/prism
cp .env.example .env
npm install
npm run dev
# Visit http://localhost:3001

# Operator panel
cd services/operator
cp .env.example .env
npm install
npm run dev
# Visit http://localhost:3002
```

### Test Health Endpoints

```bash
# Local
curl http://localhost:3000/api/health
curl http://localhost:3000/api/version
curl http://localhost:3000/api/ready

# Production
curl https://web.blackroad.systems/api/health
```

## Create New Service

Use the universal template to scaffold a new service:

```bash
# Copy template
cp -r templates/web-service services/my-service

# Customize
cd services/my-service
cp .env.example .env
# Edit .env and set SERVICE_NAME, NEXT_PUBLIC_APP_NAME

# Install and run
npm install
npm run dev
```

## Deployment

### Railway (Production)

```bash
cd services/web
railway login
railway link
railway variables set SERVICE_NAME=blackroad-os-web
railway variables set SERVICE_ENV=production
railway up
```

### Cloudflare Pages (Preview)

```bash
cd services/web
npm run build
npx wrangler pages deploy .next --project-name blackroad-os-web
```

### DNS Wiring

Point Cloudflare CNAME to Railway/Pages URL:

```
Type: CNAME
Name: web
Target: blackroad-os-web-production-a2ee.up.railway.app
Proxy: Enabled (orange cloud)
```

See `DEPLOYMENT_GUIDE.md` for complete instructions.

## Key Features

- **Next.js 14** with App Router
- **TypeScript** for type safety
- **Health Endpoints**: `/api/health`, `/api/version`, `/api/ready`
- **Railway Ready**: Includes `railway.json` config
- **Docker Support**: Multi-stage Dockerfile included
- **Standalone Output**: Optimized for production

## Domains

### blackroad.io (Preview/Development)
- Deployed via Cloudflare Pages
- 13 subdomains: web, api, brand, console, core, dashboard, demo, docs, ideas, infra, operator, prism, research

### blackroad.systems (Production)
- Deployed via Railway
- 11 subdomains: api, brand, console, core, docs, ideas, infra, operator, prism, research, web

## Documentation

- **DEPLOYMENT_GUIDE.md**: Complete deployment instructions
- **templates/web-service/README.md**: Template usage guide
- **services/*/README.md**: Service-specific documentation

## Environment Variables

All services require:

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVICE_NAME` | Service identifier | `blackroad-os-web` |
| `SERVICE_ENV` | Environment | `production` or `development` |
| `NEXT_PUBLIC_APP_NAME` | Display name | `BlackRoad Web` |
| `NEXT_PUBLIC_BASE_URL` | Base URL | `https://web.blackroad.systems` |

See `.env.example` in each service for complete list.

## Service Endpoints

All services include:

- **GET /api/health** - Health check (status, uptime)
- **GET /api/version** - Version information
- **GET /api/ready** - Readiness probe

## Files Created

### Registry
- `infra/blackroad_registry.json` - Master service registry (24 services)

### Template (13 files)
- `templates/web-service/package.json`
- `templates/web-service/tsconfig.json`
- `templates/web-service/next.config.mjs`
- `templates/web-service/app/layout.tsx`
- `templates/web-service/app/page.tsx`
- `templates/web-service/app/api/health/route.ts`
- `templates/web-service/app/api/version/route.ts`
- `templates/web-service/app/api/ready/route.ts`
- `templates/web-service/.env.example`
- `templates/web-service/railway.json`
- `templates/web-service/Dockerfile`
- `templates/web-service/.gitignore`
- `templates/web-service/README.md`

### Services (3 × 13 files = 39 files)
- `services/web/` - Same structure as template
- `services/prism/` - Same structure as template
- `services/operator/` - Same structure as template

### Documentation
- `DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `README.md` - This file

**Total: 54 files created**

## Next Steps

1. Deploy remaining services using the template
2. Set up CI/CD for automated deployments
3. Configure monitoring and alerting
4. Add authentication to protected services
5. Implement service-specific features

## Architecture

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Runtime**: Node.js 20+
- **Preview**: Cloudflare Pages
- **Production**: Railway
- **DNS**: Cloudflare
- **Health Checks**: Built-in `/api/health` endpoints

---

**BlackRoad Infrastructure** · Generated 2025-11-24

# BlackRoad Deploy Architecture

## Overview
Self-hosted deployment platform to replace Railway.

## Infrastructure

### Deployment Server (DigitalOcean: 159.65.43.12)
- **Docker Engine**: Run application containers
- **Deployment API**: REST API for managing deployments
- **PostgreSQL**: Store deployment metadata, logs, configs
- **Caddy**: Reverse proxy for deployed services
- **Health Monitor**: Check service status

### Cloudflare Integration
- **Tunnel**: Secure access to deployment server (no exposed ports)
- **DNS**: Automatic subdomain creation (*.blackroad.systems)
- **KV**: Store deployment configs, environment variables
- **D1**: Alternative database option
- **Pages**: Host the web dashboard

### GitHub Integration
- **Webhooks**: Auto-deploy on push
- **Actions**: Optional CI/CD pipelines
- **Container Registry**: Store Docker images (ghcr.io)

## Components

### 1. Deployment API (`blackroad-api`)
- **Tech**: Node.js + Express + TypeScript
- **Features**:
  - Create/delete/restart deployments
  - Stream logs
  - Manage environment variables
  - Health checks
  - PostgreSQL for persistence

### 2. CLI Tool (`blackroad-cli`)
```bash
blackroad init          # Initialize project
blackroad deploy        # Deploy current directory
blackroad logs <app>    # Stream logs
blackroad env set KEY=val
blackroad restart <app>
blackroad delete <app>
blackroad status        # List all deployments
```

### 3. Web Dashboard
- **Tech**: React + Vite on Cloudflare Pages
- **Features**:
  - View all deployments
  - Real-time logs
  - Environment variable management
  - Deployment history
  - Resource usage metrics

## Deployment Flow

1. **Developer**: `blackroad deploy`
2. **CLI**:
   - Builds Docker image
   - Pushes to ghcr.io
   - Calls Deployment API
3. **API**:
   - Pulls image
   - Starts container with env vars
   - Configures Caddy reverse proxy
   - Updates DNS via Cloudflare API
4. **Result**: App live at `<app-name>.blackroad.systems`

## Data Storage

### PostgreSQL Schema
```sql
-- deployments
id, name, image, status, created_at, updated_at

-- environment_variables
deployment_id, key, value (encrypted)

-- deployment_logs
deployment_id, timestamp, level, message

-- domains
deployment_id, domain, status
```

### Cloudflare KV
- Deployment configs
- API keys/tokens
- Backup for environment variables

## Security

- **API Authentication**: Bearer tokens (stored in Cloudflare KV)
- **Cloudflare Tunnel**: No exposed ports on deployment server
- **Environment Variables**: Encrypted at rest
- **Container Isolation**: Docker network isolation
- **HTTPS**: Automatic via Cloudflare

## Advantages Over Railway

✅ **Full Control**: Own your infrastructure
✅ **Cost**: ~$12/month (DigitalOcean) vs $20-100+ on Railway
✅ **Unlimited Projects**: No artificial limits
✅ **Custom Domains**: Free via Cloudflare
✅ **Data Ownership**: Everything on your server
✅ **No Vendor Lock-in**: Can migrate anywhere
✅ **Integration**: Deep Cloudflare + GitHub integration

## Next Steps

1. Set up deployment server
2. Build API service
3. Create CLI tool
4. Deploy dashboard
5. Migrate Railway projects

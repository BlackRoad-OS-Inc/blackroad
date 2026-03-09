# BlackRoad Distributed Development System
**Version:** 1.0.0
**Date:** 2025-12-26

## Architecture Overview

```
GitHub Push
    ↓
GitHub Webhook
    ↓
Cloudflare Worker (dispatcher)
    ↓
    ├─→ lucidia-pi (ops) - Primary build/deploy
    ├─→ alice-pi (ops) - K8s deployments
    ├─→ aria-pi (sim) - Testing/simulation
    └─→ octavia-pi (holo) - 3D model generation
```

## Goals

1. **GitHub → Pi Pipeline**: Push to GitHub, auto-deploy to appropriate Pi
2. **Cloudflare Edge**: Worker receives webhooks, routes to correct Pi
3. **Role-based Deployment**: Each Pi gets tasks based on its role
4. **Collaborative Work**: Pis can work on different parts of the same project
5. **Real-time Updates**: Changes sync across cluster

## Components

### 1. Git Webhook Receiver (on each Pi)
- Lightweight HTTP server on each Pi
- Receives deployment commands from Cloudflare
- Pulls latest code from GitHub
- Executes build/deploy scripts based on role

### 2. Cloudflare Worker (Dispatcher)
- Receives GitHub webhooks
- Analyzes changed files
- Routes deployment tasks to appropriate Pis
- Tracks deployment status in KV

### 3. Pi Agent (on each device)
- Monitors for new tasks
- Executes deployments
- Reports status back to Cloudflare
- Syncs with other Pis via shared KV state

### 4. Deployment Orchestrator
- Coordinates multi-Pi deployments
- Handles dependencies between nodes
- Ensures consistent state across cluster

---

## Implementation

### Phase 1: Pi Webhook Receivers

Each Pi runs a simple webhook receiver on a unique port:
- **lucidia-pi**: Port 9001
- **alice-pi**: Port 9002
- **aria-pi**: Port 9003
- **octavia-pi**: Port 9004

### Phase 2: Cloudflare Worker Setup

**Worker Functions:**
1. Receive GitHub webhook
2. Parse repository/branch/files
3. Determine which Pi(s) should handle it
4. Send deployment request to Pi(s)
5. Track status in KV

### Phase 3: Deployment Flows

**Example: Full-Stack App Deploy**

```
1. Push to blackroad-os/my-app main branch
   ├─ Frontend changes → lucidia-pi (build React)
   ├─ Backend changes → alice-pi (deploy to K8s)
   ├─ Tests → aria-pi (run test suite)
   └─ 3D assets → octavia-pi (render models)

2. Cloudflare Worker analyzes diff:
   - src/frontend/** → lucidia
   - src/backend/** → alice
   - tests/** → aria
   - assets/3d/** → octavia

3. Each Pi receives task:
   - Pulls latest code
   - Runs role-specific scripts
   - Reports completion

4. Worker waits for all:
   - Aggregates results
   - Updates GitHub commit status
   - Triggers production deploy if all pass
```

---

## File Structure on Each Pi

```
/opt/blackroad/
├── agent/
│   ├── webhook-receiver.sh        # HTTP server for webhooks
│   ├── deployment-handler.sh      # Executes deployments
│   ├── sync-agent.sh             # Syncs with other Pis
│   └── config.env                # Pi-specific config
├── workspace/
│   ├── repos/                    # Git repositories
│   ├── builds/                   # Build artifacts
│   └── logs/                     # Deployment logs
└── scripts/
    ├── deploy-frontend.sh        # Role-specific scripts
    ├── deploy-backend.sh
    ├── run-tests.sh
    └── render-3d.sh
```

---

## Cloudflare Infrastructure

### Worker: `blackroad-deploy-dispatcher`

```javascript
// Receives GitHub webhooks
// Routes to appropriate Pi(s)
// Tracks deployment state

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // Parse GitHub webhook
  const payload = await request.json()

  // Determine target Pis based on changed files
  const targets = analyzeChanges(payload)

  // Dispatch to each Pi
  const results = await Promise.all(
    targets.map(target => deployToPi(target))
  )

  // Store status in KV
  await DEPLOYMENTS.put(payload.after, JSON.stringify(results))

  return new Response('OK', { status: 200 })
}
```

### KV Namespace: `BLACKROAD_DEPLOYMENTS`

Stores:
- Deployment status per commit
- Pi availability/health
- Build artifacts metadata
- Sync state between Pis

### D1 Database: `blackroad_deploy_db`

Tables:
- `deployments` - Deployment history
- `pi_nodes` - Node registry and health
- `tasks` - Task queue for each Pi
- `artifacts` - Build artifacts tracking

---

## Deployment Scenarios

### Scenario 1: Website Update

**Trigger:** Push to `blackroad-os/website`

**Flow:**
1. Cloudflare receives webhook
2. Routes to lucidia-pi (ops role)
3. lucidia pulls code, builds site
4. Uploads to Cloudflare Pages
5. Reports success

**Commands on lucidia:**
```bash
cd /opt/blackroad/workspace/repos/website
git pull origin main
npm install
npm run build
wrangler pages deploy dist
```

### Scenario 2: Multi-Service App

**Trigger:** Push to `blackroad-os/full-stack-app`

**Flow:**
1. Cloudflare analyzes diff:
   - `frontend/**` → lucidia
   - `api/**` → alice (K8s)
   - `tests/**` → aria
2. Each Pi executes in parallel
3. Worker waits for all completions
4. Updates GitHub status check

### Scenario 3: 3D Model Generation

**Trigger:** Push new STL file to `blackroad-os/3d-models`

**Flow:**
1. Cloudflare detects .stl file
2. Routes to octavia-pi (holo role)
3. octavia renders preview images
4. Uploads to Cloudflare R2
5. Updates model catalog

---

## Security Model

### Authentication Flow

1. **GitHub → Cloudflare**: Webhook secret validation
2. **Cloudflare → Pi**: Shared secret token in request header
3. **Pi → GitHub**: SSH keys or GitHub App credentials
4. **Pi → Cloudflare**: API token for status updates

### Secrets Storage

- **Pi nodes**: `.env` files (local)
- **Cloudflare**: Environment variables + Secrets
- **GitHub**: Repository secrets for sensitive data

### Network Security

- Cloudflare Tunnel for secure Pi access (no open ports)
- Or: Tailscale VPN for private network
- Or: Public endpoints with token auth (simplest)

---

## Monitoring & Observability

### Health Checks

Cloudflare Worker pings each Pi every minute:
```
GET http://lucidia-pi:9001/health
→ { "status": "healthy", "disk": "45%", "load": 0.8 }
```

### Deployment Dashboard

Cloudflare Pages site showing:
- Live Pi status
- Recent deployments
- Task queue
- Build logs

### Alerts

- Deployment failures → GitHub issue
- Pi offline → Slack notification
- Build > 5min → Warning

---

## Getting Started (Quick Start)

### Step 1: Deploy Webhook Receivers to All Pis

```bash
# From operator-mac
~/blackroad-cli.sh deploy ~/blackroad-webhook-receiver.sh
```

### Step 2: Create Cloudflare Worker

```bash
wrangler generate blackroad-deploy-dispatcher
cd blackroad-deploy-dispatcher
# Edit wrangler.toml with KV bindings
wrangler deploy
```

### Step 3: Configure GitHub Webhook

1. Go to repo Settings → Webhooks
2. Add webhook URL: `https://blackroad-deploy-dispatcher.YOURNAME.workers.dev`
3. Secret: Generate and store in both GitHub and Cloudflare
4. Events: Push, Pull Request

### Step 4: Test Deployment

```bash
# Push to test repo
git push origin main

# Watch Pis receive and execute
ssh lucidia-pi "tail -f /opt/blackroad/workspace/logs/deploy.log"
```

---

## Advanced Features

### 1. Distributed Build Cache

Pis share build cache via Cloudflare KV:
- lucidia builds frontend → stores in KV
- alice needs same frontend → pulls from KV
- Saves rebuild time

### 2. Canary Deployments

Deploy to one Pi first, verify, then roll out:
```
aria-pi (test) → success → alice-pi (staging) → lucidia-pi (prod)
```

### 3. Rollback Support

Keep last 5 deployments:
```bash
/opt/blackroad/workspace/builds/
├── commit-abc123/
├── commit-def456/
└── commit-ghi789/

# Rollback command
./rollback.sh abc123
```

### 4. Multi-Repo Coordination

Deploy across multiple repos atomically:
```
blackroad-os/frontend + blackroad-os/backend
→ Both must succeed or both rollback
```

---

## Next Steps

1. **Implement webhook receiver** (simple HTTP server in bash/python)
2. **Create Cloudflare Worker** (JavaScript dispatcher)
3. **Set up KV namespace** for state tracking
4. **Configure GitHub webhooks** on key repos
5. **Test with simple deployment** (static site)
6. **Expand to complex scenarios** (multi-Pi, K8s, etc.)

---

## File Checklist

Files to create:
- [ ] `webhook-receiver.sh` - HTTP server for each Pi
- [ ] `deployment-handler.sh` - Execute deployments
- [ ] `sync-agent.sh` - Inter-Pi sync
- [ ] `cloudflare-worker.js` - Dispatcher logic
- [ ] `wrangler.toml` - Worker config
- [ ] `deploy-scripts/` - Role-specific deploy scripts
- [ ] `dashboard/` - Deployment monitoring UI

---

## Cost Estimate

- **Cloudflare Workers**: Free tier (100k requests/day)
- **Cloudflare KV**: Free tier (100k reads/day)
- **Cloudflare D1**: Free tier (100k rows)
- **Cloudflare Pages**: Free tier (unlimited)
- **GitHub Webhooks**: Free
- **Pi Infrastructure**: Already owned

**Total monthly cost: $0** (on free tiers)

---

**End of Design Document**

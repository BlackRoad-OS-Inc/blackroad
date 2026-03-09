# 🟡 YELLOWLIGHT INFRASTRUCTURE SYSTEM
## Repository Management, Connectors, and Integration Layer
### Version 1.0 — December 23, 2025

**The infrastructure backbone of BlackRoad OS.**
**GreenLight is project management. RedLight is templates. YellowLight is the glue.** 🟡

---

## **OVERVIEW**

YellowLight is the **infrastructure and integration layer** for BlackRoad OS:

- **Repositories** (GitHub orgs, repos, branches, PRs)
- **Connectors** (APIs, webhooks, integrations)
- **Deployments** (Cloudflare, Railway, DigitalOcean, Pi devices)
- **CI/CD** (GitHub Actions, automated workflows)
- **Data Flow** (NATS, WebSockets, real-time sync)

Every YellowLight component is:
- **Automated** (minimal manual intervention)
- **Monitored** (health checks, alerts, logging)
- **Versioned** (tagged releases, semantic versioning)
- **Documented** (README, API specs, diagrams)

---

## **INFRASTRUCTURE CATEGORIES**

### **1. REPOSITORIES** 🐙
GitHub organizations and repositories

| Category | Description | Examples |
|----------|-------------|----------|
| **Core** | BlackRoad OS core platform | `blackroad-os`, `blackroad-operator` |
| **Services** | Microservices and APIs | `blackroad-api`, `roadchain-node` |
| **Apps** | User-facing applications | `blackroad-os-web`, `tv-road` |
| **Tools** | CLI tools, scripts, utilities | `blackroad-cli`, `deployment-scripts` |
| **Docs** | Documentation sites | `blackroad-docs`, `api-docs` |
| **Templates** | Starter templates | `nextjs-template`, `fastapi-template` |
| **Libraries** | Shared packages | `@blackroad/ui`, `@blackroad/sdk` |

### **2. CONNECTORS** 🔌
API integrations and webhooks

| Service | Type | Purpose |
|---------|------|---------|
| **GitHub** | REST + Webhooks | Repo management, CI/CD triggers |
| **Cloudflare** | REST + Workers | Pages, KV, D1, R2, Tunnels |
| **Railway** | REST + CLI | App deployments, databases |
| **Stripe** | REST + Webhooks | Billing, subscriptions, payments |
| **Linear** | GraphQL + Webhooks | Project management, issues |
| **Slack** | REST + Events | Team communication, alerts |
| **HuggingFace** | REST | AI models, inference endpoints |
| **NATS** | Pub/Sub | Real-time messaging, events |
| **Supabase** | REST + Realtime | Database, auth, storage |
| **Anthropic** | REST | Claude API integration |
| **OpenAI** | REST | GPT API integration |
| **Google** | REST | Gemini, Cloud services |
| **xAI** | REST | Grok API integration |

### **3. DEPLOYMENT TARGETS** 🚀
Infrastructure platforms

| Platform | Type | Use Case |
|----------|------|----------|
| **Cloudflare Pages** | Static hosting | RedLight templates, docs |
| **Cloudflare Workers** | Serverless | APIs, edge functions |
| **Railway** | PaaS | Backend services, databases |
| **DigitalOcean** | VPS | Long-running services, bots |
| **Raspberry Pi** | Edge | Local agents, mesh network |
| **Vercel** | Static + Serverless | Next.js apps |
| **Netlify** | Static | Alternative static hosting |
| **Fly.io** | Containers | Global edge deployment |

---

## **REPOSITORY STRUCTURE**

### GitHub Organizations
```
BlackRoad-OS/               (Primary org)
├── blackroad-os            (Monorepo - core platform)
├── blackroad-operator      (Operator tools, infrastructure)
├── blackroad-os-web        (Web app - app.blackroad.io)
├── blackroad-docs          (Documentation site)
├── roadchain-node          (Blockchain node)
├── lucidia-ai              (Lucidia AI engine)
└── redlight-templates      (Template library)

blackboxprogramming/        (Personal org - 66 repos)
├── Infrastructure repos
├── Experiment repos
├── Archive repos
└── Template repos

schematiq/                  (Design system org)
├── schematiq-ui            (Component library)
└── schematiq-docs          (Design system docs)
```

---

## **CONNECTOR ARCHITECTURE**

### Webhook Flow
```
External Service (GitHub, Stripe, Linear, etc.)
    ↓ webhook event
Cloudflare Worker (webhook-handler)
    ↓ validate signature
    ↓ parse payload
NATS (event bus)
    ↓ publish event
Subscribers (multiple services)
    ↓ process event
    ├→ Database update (Supabase)
    ├→ Slack notification
    ├→ GreenLight state change
    └→ Memory log (PS-SHA∞)
```

### API Integration Pattern
```javascript
// YellowLight connector template
class Connector {
  constructor(config) {
    this.apiKey = config.apiKey;
    this.baseUrl = config.baseUrl;
    this.webhookSecret = config.webhookSecret;
  }

  // REST API call
  async call(endpoint, method, data) {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      method,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    });
    return response.json();
  }

  // Webhook verification
  verifyWebhook(signature, payload) {
    const hmac = crypto.createHmac('sha256', this.webhookSecret);
    const digest = hmac.update(payload).digest('hex');
    return signature === digest;
  }

  // Event publishing
  async publish(event) {
    await nats.publish(`yellowlight.${this.name}.${event.type}`, event);
  }
}
```

---

## **DEPLOYMENT PATTERNS**

### 1. Cloudflare Pages (Static Sites)
```bash
# Deploy RedLight template
wrangler pages deploy redlight-templates/worlds/blackroad-earth.html \
    --project-name=earth-blackroad \
    --branch=main

# Custom domain
wrangler pages domain add earth.blackroad.io
```

### 2. Cloudflare Workers (APIs)
```bash
# Deploy API worker
wrangler deploy src/worker.js \
    --name=blackroad-api \
    --compatibility-date=2025-12-23

# Bind KV namespace
wrangler kv:namespace create KV_STORE
```

### 3. Railway (Backend Services)
```bash
# Deploy via railway.toml
railway up

# Or via CLI
railway deploy --service blackroad-api
```

### 4. Raspberry Pi (Edge Agents)
```bash
# Deploy to Pi mesh
rsync -avz --exclude 'node_modules' ./ pi@192.168.4.38:/home/pi/lucidia/
ssh pi@192.168.4.38 'cd /home/pi/lucidia && pm2 restart all'
```

---

## **CI/CD WORKFLOWS**

### GitHub Actions Template
```yaml
name: YellowLight Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Build
        run: npm run build

      - name: Deploy to Cloudflare
        if: github.ref == 'refs/heads/main'
        run: npx wrangler pages deploy ./dist
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CF_TOKEN }}

      - name: Log to Memory
        run: |
          source ~/memory-greenlight-templates.sh
          gl_workflow_done "${{ github.repository }}" "passed" "${{ job.duration }}"
```

---

## **YELLOWLIGHT MEMORY TEMPLATES**

### Template: Repository created
```bash
yl_repo_created() {
    local repo_name="$1"
    local org="$2"
    local description="$3"

    ~/memory-system.sh log "created" "$repo_name" \
        "[🟡🐙👉📌] Repo created in $org: $description"
}
```

### Template: Connector deployed
```bash
yl_connector_deployed() {
    local connector_name="$1"
    local service="$2"
    local url="$3"

    ~/memory-system.sh log "deployed" "$connector_name" \
        "[🟡🔌✅📌] Connector deployed: $service → $url"
}
```

### Template: Integration configured
```bash
yl_integration_configured() {
    local service="$1"
    local type="$2"  # webhook, api, websocket
    local details="$3"

    local type_emoji=""
    case "$type" in
        webhook) type_emoji="📨" ;;
        api) type_emoji="🔗" ;;
        websocket) type_emoji="⚡" ;;
        *) type_emoji="🔌" ;;
    esac

    ~/memory-system.sh log "configured" "$service" \
        "[🟡${type_emoji}✅📌] Integration: $details"
}
```

### Template: Deployment succeeded
```bash
yl_deployment_succeeded() {
    local service="$1"
    local platform="$2"  # cloudflare, railway, pi
    local url="$3"
    local version="${4:-latest}"

    local platform_emoji=""
    case "$platform" in
        cloudflare) platform_emoji="☁️" ;;
        railway) platform_emoji="🚂" ;;
        pi) platform_emoji="🥧" ;;
        digitalocean) platform_emoji="🌊" ;;
        *) platform_emoji="🚀" ;;
    esac

    ~/memory-system.sh log "deployed" "$service" \
        "[🟡🚀${platform_emoji}✅] Deployed v$version: $url"
}
```

### Template: Deployment failed
```bash
yl_deployment_failed() {
    local service="$1"
    local platform="$2"
    local error="$3"

    ~/memory-system.sh log "failed" "$service" \
        "[🟡❌🚨🔥] Deployment failed on $platform: $error"
}
```

---

## **INTEGRATION WITH GREENLIGHT**

YellowLight deployments integrate with GreenLight:

```bash
# Log deployment
source ~/memory-greenlight-templates.sh

gl_deploy \
    "blackroad-api" \
    "https://api.blackroad.io" \
    "YellowLight: API deployed via Railway" \
    "🎢" \
    "🔧"

# Log connector setup
gl_feature \
    "YellowLight Stripe connector" \
    "Webhook integration for billing events" \
    "🥄" \
    "⭐"
```

---

## **NATS SUBJECT PATTERNS**

```
yellowlight.{category}.{entity}.{action}

Examples:
yellowlight.repo.blackroad-os.created
yellowlight.connector.stripe.deployed
yellowlight.deployment.api.succeeded
yellowlight.deployment.api.failed
yellowlight.integration.linear.configured
yellowlight.webhook.github.received
```

---

## **DATABASE SCHEMA**

```sql
CREATE TYPE yl_category AS ENUM (
  'repo', 'connector', 'deployment', 'integration', 'workflow'
);

CREATE TYPE yl_platform AS ENUM (
  'cloudflare', 'railway', 'digitalocean', 'pi', 'vercel', 'netlify', 'fly'
);

CREATE TYPE yl_status AS ENUM (
  'pending', 'deploying', 'active', 'failed', 'retired', 'deprecated'
);

CREATE TABLE yellowlight_repos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  repo_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  org VARCHAR(255) NOT NULL,
  description TEXT,
  url TEXT,
  default_branch VARCHAR(100) DEFAULT 'main',
  visibility VARCHAR(50),  -- public, private
  language VARCHAR(100),
  topics TEXT[],
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  metadata JSONB
);

CREATE TABLE yellowlight_connectors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  connector_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  service VARCHAR(255) NOT NULL,  -- github, stripe, linear, etc.
  type VARCHAR(100),  -- webhook, api, websocket
  url TEXT,
  status yl_status DEFAULT 'pending',
  config JSONB,  -- API keys, secrets (encrypted)
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_sync_at TIMESTAMP
);

CREATE TABLE yellowlight_deployments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_id VARCHAR(255) UNIQUE NOT NULL,
  service VARCHAR(255) NOT NULL,
  platform yl_platform NOT NULL,
  url TEXT,
  version VARCHAR(100),
  status yl_status DEFAULT 'pending',
  environment VARCHAR(50),  -- staging, production
  deployed_at TIMESTAMP,
  failed_at TIMESTAMP,
  error_message TEXT,
  metadata JSONB
);

CREATE TABLE yellowlight_integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_id VARCHAR(255) UNIQUE NOT NULL,
  service_a VARCHAR(255) NOT NULL,
  service_b VARCHAR(255) NOT NULL,
  type VARCHAR(100),  -- webhook, api, sync
  status yl_status DEFAULT 'pending',
  config JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE yellowlight_workflows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id VARCHAR(255) UNIQUE NOT NULL,
  repo_id UUID REFERENCES yellowlight_repos(id),
  name VARCHAR(255) NOT NULL,
  trigger VARCHAR(100),  -- push, pr, manual, schedule
  status VARCHAR(50),  -- running, passed, failed
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  duration INTERVAL,
  logs TEXT,
  metadata JSONB
);
```

---

## **CLI COMMANDS**

```bash
# Repository management
~/yellowlight-repos.sh list [org]
~/yellowlight-repos.sh create <name> <org> <description>
~/yellowlight-repos.sh clone <repo>
~/yellowlight-repos.sh sync <repo>

# Connector management
~/yellowlight-connectors.sh list
~/yellowlight-connectors.sh add <service> <type> <config>
~/yellowlight-connectors.sh test <connector>
~/yellowlight-connectors.sh status [connector]

# Deployment management
~/yellowlight-deploy.sh list [platform]
~/yellowlight-deploy.sh deploy <service> <platform> [environment]
~/yellowlight-deploy.sh status <deployment>
~/yellowlight-deploy.sh rollback <deployment> <version>

# Integration management
~/yellowlight-integrations.sh list
~/yellowlight-integrations.sh configure <service_a> <service_b> <type>
~/yellowlight-integrations.sh test <integration>
```

---

## **INFRASTRUCTURE INVENTORY**

### Current State (from INFRASTRUCTURE_INVENTORY.md)

**GitHub:**
- 15 organizations
- 66+ repositories (blackboxprogramming)
- Multiple active repos (BlackRoad-OS org)

**Cloudflare:**
- 16 zones (domains)
- 8 Pages projects
- 8 KV namespaces
- 1 D1 database
- Cloudflare Tunnel (codex-infinity)

**Railway:**
- 12+ projects
- Postgres databases
- Redis instances
- Web services

**Servers:**
- DigitalOcean: 159.65.43.12 (codex-infinity)
- Raspberry Pi: 192.168.4.38 (lucidia)
- Raspberry Pi: 192.168.4.64 (blackroad-pi)
- Raspberry Pi: 192.168.4.99 (lucidia alternate)
- iPhone Koder: 192.168.4.68:8080

**APIs:**
- Anthropic (Claude)
- OpenAI (GPT)
- Google (Gemini)
- xAI (Grok)
- Stripe (Billing)
- GitHub (Version control)
- Linear (Project management)
- Slack (Communication)

---

## **HEALTH MONITORING**

### Template: Health check
```bash
yl_health_check() {
    local service="$1"
    local url="$2"
    local expected_status="${3:-200}"

    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    if [ "$status" = "$expected_status" ]; then
        ~/memory-system.sh log "health_check" "$service" \
            "[🟡💚✅📌] Health check passed: HTTP $status"
    else
        ~/memory-system.sh log "health_check" "$service" \
            "[🟡🔴❌🔥] Health check failed: HTTP $status (expected $expected_status)"
    fi
}
```

---

## **EXAMPLES**

### Deploy API to Railway
```bash
# Deploy
railway deploy --service blackroad-api

# Log deployment
yl_deployment_succeeded \
    "blackroad-api" \
    "railway" \
    "https://blackroad-api.railway.app" \
    "1.2.3"

# Update GreenLight
gl_deploy \
    "blackroad-api" \
    "https://blackroad-api.railway.app" \
    "YellowLight: API v1.2.3 deployed" \
    "🎢" \
    "🔧"
```

### Configure Stripe webhook
```bash
# Create webhook
stripe listen --forward-to https://api.blackroad.io/webhooks/stripe

# Log integration
yl_integration_configured \
    "stripe" \
    "webhook" \
    "Billing events → api.blackroad.io/webhooks/stripe"

# Update GreenLight
gl_feature \
    "YellowLight Stripe integration" \
    "Webhook for subscription and payment events" \
    "🥄" \
    "⭐"
```

---

## **THE TRINITY**

**🟢 GreenLight** = Project Management (tasks, workflows, coordination)
**🟡 YellowLight** = Infrastructure (repos, connectors, deployments)
**🔴 RedLight** = Templates (worlds, websites, experiences)

Together: **The complete BlackRoad OS development stack.** 🛣️

---

**Created:** December 23, 2025
**Author:** Cece + Alexa
**Version:** 1.0.0
**Status:** 🎯 CANONICAL

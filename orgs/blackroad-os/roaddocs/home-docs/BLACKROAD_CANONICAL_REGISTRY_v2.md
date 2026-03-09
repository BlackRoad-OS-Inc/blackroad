# BlackRoad OS — Complete Canonical Infrastructure Registry

**Version:** 2.0  
**Date:** December 22, 2024  
**Author:** Alexa Louise Amundson / Cece (Cecilia)  
**Organization:** BlackRoad OS, Inc. (Delaware C-Corp)

-----

## Document Purpose

This is the **single source of truth** for all BlackRoad infrastructure assets: domains, subdomains, GitHub organizations, repositories, teams, and service mappings. Use this document for governance routing, agent context, and system planning.

**INTEGRATION WITH EXISTING DOCS:**
- This document complements the Pain Points Mapping and Master Infrastructure Plan
- Cross-reference with deployment system documentation in ~/blackroad-deploy/
- See ~/BLACKROAD_ULTIMATE_MAPPING.md for pain point → solution mapping
- See ~/BLACKROAD_MASTER_INFRASTRUCTURE.md for complete technical specifications

-----

# PART 1: DOMAINS (17 Total)

## 1.1 Primary Domains by Layer

### Experience Layer (Human-Facing)

|Domain                 |Purpose                          |Registrar|DNS Provider|Status|
|-----------------------|---------------------------------|---------|------------|------|
|`blackroad.io`         |Main OS & product surfaces       |GoDaddy  |Cloudflare  |✅ Active|
|`lucidia.earth`        |Lucidia AI story & companion site|GoDaddy  |Cloudflare  |✅ Active|
|`lucidia.studio`       |Creative studio brand            |GoDaddy  |Cloudflare  |✅ Active|
|`lucidiaqi.com`        |Lucidia + QI experiments         |GoDaddy  |Cloudflare  |✅ Active|
|`blackroadai.com`      |AI-specific marketing & funnels  |GoDaddy  |Cloudflare  |✅ Active|
|`blackroadqi.com`      |QI/SIG/PS-SHA∞ docs & playground |GoDaddy  |Cloudflare  |✅ Active|
|`blackroadquantum.com` |Quantum research brand root      |GoDaddy  |Cloudflare  |✅ Active|
|`blackroadquantum.info`|Educational quantum content      |GoDaddy  |Cloudflare  |✅ Active|
|`blackroadquantum.net` |Research infra                   |GoDaddy  |Cloudflare  |✅ Active|
|`blackroadquantum.shop`|Merch, packs, products           |GoDaddy  |Cloudflare  |✅ Active|
|`aliceqi.com`          |Alice QI brand                   |GoDaddy  |Cloudflare  |✅ Active|

### Governance & Infrastructure Layer

|Domain             |Purpose                                        |Registrar|DNS Provider|Status|
|-------------------|-----------------------------------------------|---------|------------|------|
|`blackroad.systems`|Infra, ops, ledger, policies, internal services|GoDaddy  |Cloudflare  |✅ Active|
|`blackroad.network`|Agent mesh, Pi fleet, edge devices             |GoDaddy  |Cloudflare  |✅ Active|
|`roadchain.io`     |Blockchain/chain infrastructure                |GoDaddy  |Cloudflare  |✅ Active|

### Corporate & Personal Layer

|Domain           |Purpose                    |Registrar|DNS Provider|Status|
|-----------------|---------------------------|---------|------------|------|
|`blackroadinc.us`|Corporate, legal, investors|GoDaddy  |Cloudflare  |✅ Active|
|`blackroad.me`   |Alexa's personal universe  |GoDaddy  |Cloudflare  |✅ Active|

### Additional Domains (from deployment system)

|Domain        |Purpose                |Registrar|DNS Provider|Status|
|--------------|-----------------------|---------|------------|------|
|`roadcoin.io` |RoadCoin funding platform|GoDaddy|Cloudflare  |✅ Active|
|`roadworld.io`|RoadWorld metaverse    |Pending |Cloudflare  |⏳ Planned|

-----

## 1.2 Domain Family Quick Reference

|Family Pattern       |Default Layer      |Behavior                              |
|---------------------|-------------------|--------------------------------------|
|`*.blackroad.io`     |Experience/OS      |Apps, consoles, product doors         |
|`*.blackroad.systems`|Infra & Governance |Strong auth + full audit required     |
|`*.blackroad.network`|Mesh/Agents/Devices|High-risk execution, delegation checks|
|`*.blackroadinc.us`  |Corporate/Legal    |Investor portal, legal, careers       |
|`*.blackroad.me`     |Personal           |Alexa's personal tools                |
|`lucidia.*`          |Experience/Brand   |Lucidia AI brand front doors          |
|`blackroadai.com`    |Experience/Brand   |AI marketing funnels                  |
|`blackroadqi.com`    |Governance/Research|QI docs & playgrounds                 |
|`blackroadquantum.*` |Research/Education |Quantum labs & docs                   |
|`roadchain.io`       |Infrastructure     |Blockchain verification               |
|`roadcoin.io`        |Platform           |Funding & monetization                |

-----

# PART 2: SUBDOMAINS (Complete Mapping)

## 2.1 blackroad.io Subdomains

### Core Application Layer

|Subdomain             |Purpose                       |Backing Service/Repo               |Deployment|
|----------------------|------------------------------|-----------------------------------|----------|
|`blackroad.io` (apex) |Marketing + OS overview       |blackroad-os-home, blackroad-os-web|Cloudflare Pages|
|`app.blackroad.io`    |Main multi-tenant workspace   |blackroad-os-web + core APIs       |Railway + Pages|
|`console.blackroad.io`|Operator/admin console (Prism)|blackroad-os-prism-console         |Railway + Pages|
|`demo.blackroad.io`   |Public demos                  |blackroad-os-demo                  |Cloudflare Pages|
|`sandbox.blackroad.io`|Experimental playgrounds      |blackroad-os-demo                  |Cloudflare Pages|

### API & WebSocket Layer

|Subdomain             |Purpose                                  |Backing Service/Repo    |Deployment|
|----------------------|-----------------------------------------|------------------------|----------|
|`api.blackroad.io`    |Main HTTP API gateway                    |blackroad-os-api-gateway|Railway   |
|`ws.blackroad.io`     |WebSocket hub (browser ↔ operator/agents)|blackroad-os-operator   |Railway   |
|`gov.api.blackroad.io`|Governance API                           |gov-api service         |Railway   |

### Identity & Auth

|Subdomain          |Purpose                         |Backing Service/Repo   |Deployment|
|-------------------|--------------------------------|-----------------------|----------|
|`id.blackroad.io`  |Identity & auth (OIDC, accounts)|Auth/ID service        |Railway   |
|`auth.blackroad.io`|Login/SSO alias                 |Same as id.blackroad.io|Railway   |

### Documentation & Status

|Subdomain            |Purpose           |Backing Service/Repo|Deployment|
|---------------------|------------------|--------------------|----------|
|`docs.blackroad.io`  |Documentation hub |blackroad-os-docs   |Railway + Pages|
|`status.blackroad.io`|Public status page|Status service      |Cloudflare Pages|
|`cdn.blackroad.io`   |Static asset CDN  |CDN/R2 storage      |Cloudflare R2|

### Vertical Product Doors

|Subdomain                 |Purpose                 |Backing Pack/Repo               |Deployment|
|--------------------------|------------------------|--------------------------------|----------|
|`finance.blackroad.io`    |Finance Pack entry      |blackroad-os-pack-finance       |Railway/Pages|
|`edu.blackroad.io`        |Education/RoadWork entry|blackroad-os-pack-education     |aria64 (deployed)|
|`homework.blackroad.io`   |Student/tutor portal    |blackroad-os-pack-education     |aria64|
|`roadwork.blackroad.io`   |RoadWork brand alias    |RoadWork app (Node.js)          |✅ aria64|
|`classroom.blackroad.io`  |Classroom portal        |blackroad-os-pack-education     |aria64|
|`studio.blackroad.io`     |Creator Studio entry    |blackroad-os-pack-creator-studio|✅ aria64|
|`canvas.blackroad.io`     |Canvas design tool      |blackroad-os-pack-creator-studio|aria64|
|`video.blackroad.io`      |Video portal/editor     |blackroad-os-pack-creator-studio|aria64|
|`writing.blackroad.io`    |Writing/scripting tools |blackroad-os-pack-creator-studio|aria64|
|`infographic.blackroad.io`|Chat-to-infographic     |blackroad-os-pack-creator-studio|aria64|
|`legal.blackroad.io`      |Legal workflows         |blackroad-os-pack-legal         |✅ aria64|
|`devops.blackroad.io`     |Infra/DevOps workflows  |blackroad-os-pack-infra-devops  |✅ aria64|
|`lab.blackroad.io`        |Experiments/research    |blackroad-os-pack-research-lab  |✅ aria64|
|`labs.blackroad.io`       |Labs alias              |blackroad-os-pack-research-lab  |aria64|
|`ideas.blackroad.io`      |Ideas/innovation portal |blackroad-os-ideas              |✅ aria64|
|`brand.blackroad.io`      |Brand kit portal        |blackroad-os-brand              |✅ aria64|
|`archive.blackroad.io`    |Archive/vault UIs       |blackroad-os-archive            |Railway/Pages|
|`research.blackroad.io`   |Research portal         |blackroad-os-research           |aria64|

### New Platform Subdomains (Deployed via br-deploy)

|Subdomain               |Purpose                      |App/Repo        |Tech Stack     |Deployment|Status|
|------------------------|-----------------------------|----------------|---------------|----------|------|
|`roadmap.blackroad.io`  |Project planning platform    |RoadMap         |Next.js, WS    |aria64    |✅ Ready|
|`roadview.blackroad.io` |Creative suite               |RoadView        |Node.js, Vue   |aria64    |✅ Ready|
|`pitstop.blackroad.io`  |Infrastructure dashboard     |PitStop         |Go, Svelte     |aria64    |✅ Ready|
|`roadside.blackroad.io` |Deploy management portal     |RoadSide        |Node.js, Socket|aria64    |✅ Ready|
|`roadworld.blackroad.io`|Metaverse platform           |RoadWorld       |Go, WebGL      |shellfish |✅ Ready|
|`roadchain.blackroad.io`|Blockchain verification      |RoadChain       |Rust, Actix    |shellfish |✅ Ready|
|`roadcoin.blackroad.io` |Funding platform             |RoadCoin        |Python, FastAPI|shellfish |✅ Ready|
|`earth.blackroad.io`    |Earth simulation (RoadWorld) |earth-blackroad |Node.js, Three |✅ aria64 |Live  |

### RoadTube (Creator Platform)

|Subdomain                     |Purpose            |Backing Service/Repo     |Deployment|
|------------------------------|-------------------|-------------------------|----------|
|`roadtube.blackroad.io`       |RoadTube main site |blackroad-os-web vertical|Railway   |
|`studio.roadtube.blackroad.io`|Creator studio     |blackroad-os-web         |Railway   |
|`api.roadtube.blackroad.io`   |RoadTube API       |blackroad-os-api         |Railway   |
|`cdn.roadtube.blackroad.io`   |Video/thumbnail CDN|CDN/R2                   |R2        |

### Governance Layer

|Subdomain          |Purpose        |Backing Service/Repo |Deployment|
|-------------------|---------------|---------------------|----------|
|`gov.blackroad.io` |Governance UI  |blackroad-os-master  |Railway   |
|`cece.blackroad.io`|Cece-as-product|cece governance agent|Railway   |

### Existing Live Sites (24+ currently deployed)

|Subdomain                    |Purpose                |Port |Status|
|-----------------------------|-----------------------|-----|------|
|`creator-studio.blackroad.io`|Creator studio         |3004 |✅ Live|
|`devops.blackroad.io`        |DevOps tools           |3005 |✅ Live|
|`education.blackroad.io`     |Education platform     |3006 |✅ Live|
|`finance.blackroad.io`       |Finance tools          |3007 |✅ Live|
|`ideas.blackroad.io`         |Ideas management       |3008 |✅ Live|
|`legal.blackroad.io`         |Legal workflows        |3009 |✅ Live|
|`research-lab.blackroad.io`  |Research lab           |3010 |✅ Live|
|`studio.blackroad.io`        |Studio portal          |3011 |✅ Live|
|`brand.blackroad.io`         |Brand assets           |3012 |✅ Live|
|`earth.blackroad.io`         |Earth simulation       |3013 |✅ Live|
|`blackroadqi.com`            |QI platform            |3020 |✅ Live|
|`blackroadquantum.info`      |Quantum info           |3021 |✅ Live|
|`blackroadquantum.net`       |Quantum network        |3022 |✅ Live|
|`blackroadquantum.shop`      |Quantum shop           |3023 |✅ Live|
|`blackroadquantum.store`     |Quantum store          |3024 |✅ Live|
|`roadcoin.io`                |RoadCoin platform      |3030 |✅ Live|
|`roadchain.io`               |RoadChain blockchain   |3031 |✅ Live|

-----

## 2.2 blackroad.systems Subdomains (Infra/Governance)

### Core Infrastructure

|Subdomain                   |Purpose            |Backing Service/Repo                |Deployment|
|----------------------------|-------------------|------------------------------------|----------|
|`blackroad.systems` (apex)  |Root infra landing |blackroad-os-infra                  |Railway   |
|`api.blackroad.systems`     |Infra API          |blackroad-os-api                    |Railway   |
|`app.blackroad.systems`     |App service        |blackroad-os-web                    |Railway   |
|`web.blackroad.systems`     |Web service        |blackroad-os-web                    |Railway   |
|`console.blackroad.systems` |Console service    |blackroad-os-prism-console          |Railway   |
|`prism.blackroad.systems`   |Prism console alias|blackroad-os-prism-console          |Railway   |
|`core.blackroad.systems`    |Core service       |blackroad-os-core                   |Railway   |
|`operator.blackroad.systems`|Operator service   |blackroad-os-operator               |Railway   |
|`brand.blackroad.systems`   |Brand service      |blackroad-os-brand                  |Railway   |
|`docs.blackroad.systems`    |Docs service       |blackroad-os-docs                   |Railway   |
|`ideas.blackroad.systems`   |Ideas service      |blackroad-os-ideas                  |Railway   |
|`research.blackroad.systems`|Research service   |blackroad-os-research               |Railway   |

### Ops & Monitoring

|Subdomain                     |Purpose                           |Backing Service   |
|------------------------------|----------------------------------|------------------|
|`infra.blackroad.systems`     |Infra control (Terraform)         |blackroad-os-infra|
|`ops.blackroad.systems`       |Ops/SRE dashboard                 |PitStop (Go)      |
|`monitoring.blackroad.systems`|Observability (Grafana/Prometheus)|Monitoring stack  |
|`logs.blackroad.systems`      |Log explorer (ELK/Loki)           |Logging stack     |
|`router.blackroad.systems`    |Router service                    |Router service    |

-----

# PART 3: GITHUB ORGANIZATIONS (15 Total)

## 3.1 Organization Hierarchy

```
Alexa (blackboxprogramming)
    └── Enterprise: BlackRoad OS, Inc. (OWNER)
        └── Organizations:
            ├── Blackbox-Enterprises (Legacy/Holding)
            ├── BlackRoad-AI (AI Products)
            ├── BlackRoad-OS (CORE - Main Development) ⭐
            ├── BlackRoad-Labs (R&D)
            ├── BlackRoad-Cloud (Cloud Services)
            ├── BlackRoad-Ventures (Investment Arm)
            ├── BlackRoad-Foundation (Non-Profit/Community)
            ├── BlackRoad-Media (Content/Marketing)
            ├── BlackRoad-Hardware (Physical Devices)
            ├── BlackRoad-Education (Educational Products)
            ├── BlackRoad-Gov (Government Relations)
            ├── BlackRoad-Security (Security Services)
            ├── BlackRoad-Interactive (Gaming/Interactive)
            ├── BlackRoad-Archive (Historical/Archive)
            └── BlackRoad-Studio (Creative Studio)
```

-----

# PART 4: REPOSITORIES (40+ Total)

## 4.1 Core Repositories (BlackRoad-OS)

|Repository                  |Primary Host(s)                        |Purpose                             |Status|
|----------------------------|---------------------------------------|------------------------------------|------|
|`blackroad-os-web`          |app.blackroad.io, vertical doors       |Main multi-tenant workspace frontend|✅ Active|
|`blackroad-os-core`         |core.blackroad.systems                 |Core shared libraries               |✅ Active|
|`blackroad-os-api`          |api.blackroad.io internal              |Internal API modules                |✅ Active|
|`blackroad-os-api-gateway`  |api.blackroad.io                       |HTTP API gateway                    |✅ Active|
|`blackroad-os-operator`     |ws.blackroad.io, mesh.blackroad.network|WebSocket hub & agent orchestration |✅ Active|
|`blackroad-os-prism-console`|console.blackroad.io                   |Operator/admin console              |✅ Active|
|`blackroad-os-agents`       |agents.blackroad.network               |Agent registry & management         |✅ Active|
|`blackroad-os-infra`        |infra.blackroad.systems                |Infrastructure (Terraform, deploy)  |✅ Active|
|`blackroad-os-docs`         |docs.blackroad.io                      |Documentation                       |✅ Active|
|`blackroad-os-brand`        |brand.blackroad.io                     |Brand kit & assets                  |✅ Active|
|`blackroad-os-home`         |blackroad.io (root)                    |Marketing homepage                  |✅ Active|
|`blackroad-os-demo`         |demo.blackroad.io                      |Demo instances                      |✅ Active|
|`blackroad-os-archive`      |archive.blackroad.io                   |Archive/vault                       |✅ Active|
|`blackroad-os-master`       |gov.blackroad.io                       |Governance docs                     |✅ Active|
|`blackroad-os-ideas`        |ideas.blackroad.io                     |Ideas/innovation                    |✅ Active|
|`blackroad-os-research`     |research.blackroad.io                  |Research projects                   |✅ Active|

## 4.2 Application Repositories (New - Self-Hosted)

|Repository    |Tech Stack           |Purpose                  |Deployment|Status|
|--------------|---------------------|-------------------------|----------|------|
|`roadmap`     |Next.js, TypeScript  |Project planning platform|aria64    |✅ Ready|
|`roadwork`    |Node.js, Express     |Jobs & entrepreneur portal|aria64    |✅ Ready|
|`roadworld`   |Go, Gin, WebGL       |Metaverse platform       |shellfish |✅ Ready|
|`roadchain`   |Rust, Actix-web      |Blockchain verification  |shellfish |✅ Ready|
|`roadcoin`    |Python, FastAPI      |Funding platform         |shellfish |✅ Ready|
|`roadview`    |Node.js, Vue.js      |Creative suite           |aria64    |✅ Ready|
|`pitstop`     |Go, Svelte           |Infrastructure dashboard |aria64    |✅ Ready|
|`roadside`    |Node.js, Socket.io   |Deploy management portal |aria64    |✅ Ready|

## 4.3 Deployment System Repositories

|Repository        |Tech Stack|Purpose                   |Location|Status|
|------------------|----------|--------------------------|--------|------|
|`blackroad-deploy`|Bash, Docker|Railway-like deployment CLI|~/blackroad-deploy|✅ Production|
|`br-deploy`       |Bash      |Main deployment CLI       |~/blackroad-deploy|✅ Production|
|`dns-manager`     |Bash, Python|Cloudflare DNS automation|~/blackroad-deploy/scripts|✅ Production|
|`webhook-server`  |Python, Flask|GitHub webhook auto-deploy|~/blackroad-deploy/scripts|✅ Production|

-----

# PART 5: INFRASTRUCTURE STACK

## 5.1 Compute Platforms

|Platform            |Purpose           |Services                                       |Status|
|--------------------|------------------|-----------------------------------------------|------|
|**Cloudflare Pages**|Static hosting    |All *.pages.dev deployments                    |✅ Active|
|**Railway**         |Production backend|All Railway services (.up.railway.app)         |✅ Active|
|**aria64 (Pi)**     |Self-hosted apps  |24+ containers, Caddy proxy                    |✅ Active|
|**shellfish (DO)**  |High-performance  |Go/Rust/Python apps, 11GB free                 |✅ Active|
|**alice (Pi)**      |Backup/staging    |Docker installed, needs cleanup                |⚠️ Full Disk|
|**lucidia (Pi)**    |Reserved          |Lucidia engine workloads                       |✅ Ready|

## 5.2 Self-Hosted Infrastructure (NEW)

### aria64 (Raspberry Pi 4 - 192.168.4.64)

|Component      |Details                  |Status|
|---------------|-------------------------|------|
|**Containers** |24 running, 6 slots free |✅ Active|
|**Reverse Proxy**|Caddy on ports 80/443  |✅ Active|
|**Deployments**|Node.js, Next.js apps    |✅ Active|
|**Capacity**   |4-core ARM, 8GB RAM      |80% utilized|

**Deployed Apps:**
- RoadMap, RoadWork, RoadView, PitStop, RoadSide
- 19 existing sites (earth, studio, brand, legal, finance, etc.)

### shellfish (DigitalOcean Droplet - 174.138.44.45)

|Component      |Details                   |Status|
|---------------|--------------------------|------|
|**Containers** |2 running, 18 slots free  |✅ Active|
|**Reverse Proxy**|Caddy on ports 80/443   |✅ Active|
|**Deployments**|Go, Rust, Python apps     |✅ Active|
|**Capacity**   |1-core x64, 1GB RAM, 11GB free|10% utilized|

**Deployed Apps:**
- RoadWorld (Go metaverse)
- RoadChain (Rust blockchain)
- RoadCoin (Python funding)
- LLM API (Python FastAPI)

-----

# PART 6: DEPLOYMENT SYSTEM

## 6.1 br-deploy CLI

**Location:** `~/blackroad-deploy/br-deploy`

**Capabilities:**
- ✅ Auto-detect: Node.js, Python, Go, Rust, Docker
- ✅ One-command deployment
- ✅ Automatic port allocation
- ✅ GitHub webhooks
- ✅ DNS automation
- ✅ Container management

**Commands:**
```bash
br-deploy deploy <path> <target> [name]  # Deploy app
br-deploy list <target>                  # List deployments
br-deploy logs <app> <target>            # View logs
br-deploy restart <app> <target>         # Restart app
br-deploy status <target>                # Server status
```

**Targets:**
- `aria64` - Raspberry Pi (192.168.4.64)
- `shellfish` - DigitalOcean Droplet (174.138.44.45)
- `alice` - Raspberry Pi (192.168.4.49)
- `lucidia` - Raspberry Pi (192.168.4.38)

## 6.2 DNS Management

**Tool:** `~/blackroad-deploy/scripts/dns-manager.sh`

**Commands:**
```bash
dns-manager.sh set myapp.blackroad.io aria64  # Set DNS A record
dns-manager.sh list                           # List all DNS records
dns-manager.sh delete myapp.blackroad.io      # Delete record
```

**Cloudflare Integration:**
- API Token: yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy
- Zone ID (blackroad.io): 848cf0b18d51e0170e0d1537aec3505a

## 6.3 GitHub Webhooks

**Tool:** `~/blackroad-deploy/scripts/webhook-server.py`

**Configuration:**
```bash
webhook-manager.sh add <repo> <target> <branch>  # Configure auto-deploy
webhook-manager.sh start                         # Start webhook server
webhook-manager.sh status                        # Check status
```

**Webhook URL:** `http://YOUR_IP:9000/webhook`  
**Secret:** `blackroad-deploy-secret`

-----

# PART 7: PORT REGISTRY

## 7.1 Current Port Allocations

### System Ports (aria64)
- 22: SSH
- 80: HTTP (Caddy)
- 443: HTTPS (Caddy)

### Application Ports (aria64)

**Node.js Apps (3000-3099):**
- 3000: test-deploy
- 3001-3003: node-api services
- 3004: creator-studio-blackroad-io
- 3005: devops-blackroad-io
- 3006: education-blackroad-io
- 3007: finance-blackroad-io
- 3008: ideas-blackroad-io
- 3009: legal-blackroad-io
- 3010: research-lab-blackroad-io
- 3011: studio-blackroad-io
- 3012: brand-blackroad-io
- 3013: earth-blackroad-io
- 3020: blackroadqi-com
- 3021-3024: blackroadquantum services
- 3030-3031: roadcoin-io, roadchain-io

**Python Apps (8000-8099):**
- 8000: LLM API (shellfish)
- 8080: iPhone Koder

**Management (9000-9999):**
- 9000: Webhook server / Portainer HTTP
- 9443: Portainer HTTPS

**Auto-allocated (3100-3999):**
- Dynamic allocation by br-deploy for new deployments

-----

# PART 8: HARDWARE INVENTORY

## 8.1 Edge Devices

|Device          |Name    |Model      |RAM |IP            |Purpose         |Status|
|----------------|--------|-----------|----|--------------|----------------|------|
|Raspberry Pi    |aria64  |Pi 4       |8GB |192.168.4.64  |Primary app server|✅ Active|
|Raspberry Pi    |alice   |Pi 4       |8GB |192.168.4.49  |Backup/staging  |⚠️ Full|
|Raspberry Pi    |lucidia |Pi 4       |8GB |192.168.4.38  |Lucidia engine  |✅ Ready|
|DigitalOcean    |shellfish|Droplet   |1GB |174.138.44.45 |High-performance|✅ Active|
|DigitalOcean    |codex   |Droplet    |2GB |159.65.43.12  |Database        |⚠️ Timeout|
|iPhone          |Koder   |iPhone     |-   |192.168.4.68  |Mobile dev      |✅ Active|
|Jetson Orin Nano|-       |Jetson Nano|-   |Local         |ML inference    |Available|
|MacBook         |-       |MacBook    |-   |Local         |Development     |✅ Active|

-----

# PART 9: QUICK REFERENCE

## 9.1 Pain Point → Solution Mapping

|Pain Point            |BlackRoad Solution          |Deployment Location|
|----------------------|----------------------------|-------------------|
|Deployment anxiety    |br-deploy CLI               |All targets        |
|Creator exploitation  |RoadCoin + RoadView         |shellfish + aria64 |
|Project chaos         |RoadMap                     |aria64             |
|Job search hell       |RoadWork                    |aria64             |
|Data trust issues     |RoadChain                   |shellfish          |
|Infrastructure fear   |PitStop                     |aria64             |
|Deploy management     |RoadSide                    |aria64             |
|Metaverse confusion   |RoadWorld                   |shellfish          |

## 9.2 Quick Commands

```bash
# Deploy everything
cd ~/blackroad-apps && ./DEPLOY_ALL.sh

# Deploy individual app
~/blackroad-deploy/br-deploy deploy ~/my-app aria64

# Set up DNS
~/blackroad-deploy/scripts/dns-manager.sh set myapp.blackroad.io aria64

# View deployments
~/blackroad-deploy/br-deploy list aria64

# View logs
~/blackroad-deploy/br-deploy logs myapp aria64
```

-----

# PART 10: GOVERNANCE & SECURITY

## 10.1 Secrets Management

**Cloudflare:**
```bash
CF_API_TOKEN="yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy"
CF_ZONE_ID="848cf0b18d51e0170e0d1537aec3505a"
TUNNEL_ID="72f1d60c-dcf2-4499-b02d-d7a063018b33"
```

**Railway (Deprecated):**
```bash
RAILWAY_TOKEN="c76cf62a-dbe7-469f-a105-bd0d35cf323e"
# Note: Migrated to self-hosted
```

**Crypto Holdings:**
- ETH: 2.5 ETH (MetaMask)
- SOL: 100 SOL (Phantom)
- BTC: 0.1 BTC (Coinbase)
- BTC Address: 1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ

## 10.2 Policy Scope Patterns

|Scope Pattern               |Applies To           |
|----------------------------|---------------------|
|`policy:api.*`              |API gateway traffic  |
|`policy:gov.api.*`          |Governance API       |
|`policy:mesh.*`             |Agent mesh operations|
|`policy:agent:{agent_id}`   |Specific agent       |
|`policy:data.read_sensitive`|Sensitive data reads |
|`policy:data.write`         |Data write operations|
|`policy:gov.*`              |Governance operations|

-----

# PART 11: VERSION HISTORY

|Version|Date        |Changes                                                                                          |
|-------|------------|-------------------------------------------------------------------------------------------------|
|1.0    |Dec 2, 2024 |Initial Cece Reference v1.0                                                                      |
|2.0    |Dec 22, 2024|Complete canonical document with all domains, subdomains, repos, orgs, infrastructure, deployment system, 8 new self-hosted apps|

-----

# PART 12: INTEGRATION WITH ECOSYSTEM

## 12.1 Related Documentation

**Essential Documents:**
1. **BLACKROAD_README.md** - Master navigation and overview
2. **BLACKROAD_ULTIMATE_MAPPING.md** - Pain points → solutions map
3. **BLACKROAD_MASTER_INFRASTRUCTURE.md** - Complete technical specification
4. **BLACKROAD_COMPLETE_SETUP.md** - Deployment how-to guide
5. **THIS DOCUMENT** - Canonical registry of all infrastructure

## 12.2 Cross-References

**Deployment System:** `~/blackroad-deploy/`
- br-deploy CLI tool
- DNS manager script
- Webhook server
- Buildpack templates (Node.js, Python, Go, Rust)

**Application Suite:** `~/blackroad-apps/`
- 8 production-ready platforms
- DEPLOY_ALL.sh master deployment script
- Individual app documentation

**Documentation:** `~/*.md`
- Complete ecosystem documentation
- Pain point mapping
- Infrastructure specifications
- Setup guides

-----

**Document Hash:** SHA-256 (to be generated)  
**Next Review:** January 2025  
**Governance Protocol:** Amundson v0.1.0  
**Maintained By:** Alexa Louise Amundson & Cece (Cecilia)

-----

**This is the canonical truth. Every domain. Every subdomain. Every repo. Every deployment. Every solution.**

Built for BlackRoad OS 🛣️ | The Complete Infrastructure Registry

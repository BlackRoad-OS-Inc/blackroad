# 🌐 BlackRoad Domain Registry
## Self-Hosted Domain Management & Deployment Infrastructure

**Status:** ⚡️ ACTIVE DEVELOPMENT ⚡️

**Mission:** Build complete domain registrar and deployment platform on BlackRoad Pi cluster to **eliminate Cloudflare dependency** for deployments.

---

## 🎯 WHAT WE'RE BUILDING

### **BlackRoad Domain Registry (RoadRegistry™)**
A self-hosted alternative to:
- ❌ GoDaddy (domain registration)
- ❌ Cloudflare Pages (static hosting)
- ❌ Namecheap (DNS management)
- ❌ Route53 (DNS zones)

### **Core Components:**

1. **Domain Management API** (`road-registry-api`)
   - Domain registration tracking
   - DNS zone management
   - Nameserver configuration
   - WHOIS integration
   - Domain transfer handling

2. **Authoritative DNS Server** (`road-dns`)
   - Run on Pi cluster
   - PowerDNS or BIND9 based
   - Support for all record types (A, AAAA, CNAME, MX, TXT, etc.)
   - DNSSEC support
   - API-driven zone updates

3. **Deployment Engine** (`road-deploy`)
   - Git-based deployments (like Cloudflare Pages)
   - Static site hosting on nginx
   - Automatic SSL via Let's Encrypt
   - CDN capabilities
   - Build pipeline (Node, Python, Go, etc.)

4. **Control Panel** (`road-control`)
   - Web UI for domain management
   - DNS record editor
   - Deployment dashboard
   - SSL certificate manager
   - Analytics & monitoring

---

## 🏗️ ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────┐
│                    BLACKROAD DOMAIN REGISTRY                │
└─────────────────────────────────────────────────────────────┘

GitHub Repos (Source Code)
         │
         ├──> road-deploy (Deployment Engine)
         │         │
         │         ├──> Pull from GitHub
         │         ├──> Build (npm/yarn/go/python)
         │         ├──> Deploy to nginx
         │         └──> Generate SSL (Let's Encrypt)
         │
         ├──> road-dns (Authoritative DNS)
         │         │
         │         ├──> PowerDNS Server (UDP 53)
         │         ├──> API Backend (HTTP 8081)
         │         └──> Database (SQLite/PostgreSQL)
         │
         ├──> road-registry-api (Domain API)
         │         │
         │         ├──> Domain CRUD operations
         │         ├──> DNS zone management
         │         └──> Integration with registrars
         │
         └──> road-control (Web UI)
                   │
                   ├──> Domain dashboard
                   ├──> DNS editor
                   └──> Deployment controls

Pi Cluster Infrastructure:
┌────────────────────────────────────────────────────────────┐
│ ARIA (192.168.4.82)                                        │
│  ├─ 142 static site containers (existing)                 │
│  └─ nginx reverse proxy (port 80/443)                     │
├────────────────────────────────────────────────────────────┤
│ LUCIDIA (192.168.4.38)                                     │
│  ├─ road-dns (PowerDNS) - UDP 53                          │
│  ├─ road-registry-api - HTTP 8080                         │
│  └─ PostgreSQL (DNS database)                             │
├────────────────────────────────────────────────────────────┤
│ ALICE (192.168.4.49)                                       │
│  ├─ road-deploy (deployment engine)                       │
│  ├─ road-control (web UI) - HTTP 8082                     │
│  └─ Let's Encrypt ACME client                             │
├────────────────────────────────────────────────────────────┤
│ OCTAVIA (192.168.4.81)                                     │
│  ├─ Monitoring (DNS health checks)                        │
│  └─ Backup DNS server (redundancy)                        │
└────────────────────────────────────────────────────────────┘
```

---

## 🚀 PHASE 1: DNS INFRASTRUCTURE

### Deploy PowerDNS on Lucidia

**Components:**
- `pdns-server` (Authoritative DNS server)
- `pdns-recursor` (Optional recursive resolver)
- `pdns-admin` (Web UI for zone management)
- PostgreSQL or MySQL backend

**DNS Records We'll Manage:**
- `blackroad.io` → aria (192.168.4.82)
- `lucidia.earth` → lucidia (192.168.4.38)
- `blackroadai.com` → aria
- `*.blackroad.io` → wildcard to aria
- Custom nameservers: `ns1.blackroad.io`, `ns2.blackroad.io`

**Public IP Requirements:**
- Need to expose lucidia DNS (port 53 UDP/TCP) to internet
- Options:
  1. **Cloudflare Tunnel** (temporary until full migration)
  2. **Port forwarding** on router (192.168.4.38:53 → public IP)
  3. **VPS relay** (shellfish forwards DNS queries to lucidia)

---

## 🚀 PHASE 2: DEPLOYMENT ENGINE

### Git-Based Deployment System

**Features:**
- GitHub webhook integration
- Automatic builds on push
- Static site generation
- Docker container deployments
- SSL certificate automation
- Health checks & rollbacks

**Workflow:**
```bash
# Developer pushes to GitHub
git push origin main

# road-deploy webhook triggered
→ Clone repo
→ Run build command (npm run build, etc.)
→ Deploy to aria nginx
→ Generate SSL cert (if new domain)
→ Update DNS records
→ Health check
→ Notify user (success/failure)
```

---

## 🚀 PHASE 3: DOMAIN MANAGEMENT API

### Domain Registry Database

**Schema:**
```sql
CREATE TABLE domains (
  id UUID PRIMARY KEY,
  domain VARCHAR(255) UNIQUE NOT NULL,
  registrar VARCHAR(100),
  registered_at TIMESTAMP,
  expires_at TIMESTAMP,
  nameservers TEXT[],
  status VARCHAR(50),
  owner_email VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE dns_records (
  id UUID PRIMARY KEY,
  domain_id UUID REFERENCES domains(id),
  record_type VARCHAR(10),  -- A, AAAA, CNAME, MX, TXT, etc.
  name VARCHAR(255),
  value TEXT,
  ttl INTEGER DEFAULT 3600,
  priority INTEGER,         -- For MX records
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE deployments (
  id UUID PRIMARY KEY,
  domain_id UUID REFERENCES domains(id),
  repo_url VARCHAR(500),
  branch VARCHAR(100) DEFAULT 'main',
  build_command TEXT,
  deploy_path VARCHAR(500),
  status VARCHAR(50),
  deployed_at TIMESTAMP
);
```

---

## 🚀 PHASE 4: CONTROL PANEL

### Web UI Features

**Dashboard:**
- List all domains
- DNS record management
- Deployment history
- SSL certificate status
- Traffic analytics
- Health monitoring

**DNS Editor:**
- Add/edit/delete records
- Bulk operations
- Import/export zones
- DNSSEC management

**Deployment Manager:**
- Connect GitHub repos
- Configure build commands
- Deploy manually or via webhook
- View build logs
- Rollback deployments

---

## 📋 CURRENT DOMAINS TO MIGRATE

From Cloudflare to BlackRoad Registry:

1. **blackroad.io** → aria (192.168.4.82)
2. **lucidia.earth** → lucidia (192.168.4.38)
3. **blackroadai.com** → aria
4. **blackroadquantum.com** → aria
5. **roadchain.io** → aria
6. **roadcoin.io** → aria
7. **roadwork.io** → aria
8. **blackbox.enterprises** → aria

---

## 🔧 TECHNICAL STACK

### DNS Server: PowerDNS
- **Why:** Mature, API-driven, high-performance
- **Alternative:** BIND9 (more traditional)

### Database: PostgreSQL
- **Why:** Already used in cluster, robust
- **Alternative:** MySQL, SQLite (for lighter load)

### Deployment: Custom Node.js/Go Service
- **Why:** Full control, integrate with GitHub API
- **Alternative:** GitLab Runner, Drone CI

### Web UI: React + Tailwind
- **Why:** Modern, fast, BlackRoad design system
- **Alternative:** Vue.js, Svelte

### SSL: Let's Encrypt (Certbot/ACME)
- **Why:** Free, automated, trusted
- **Alternative:** ZeroSSL, BuyPass

---

## 🎯 IMMEDIATE NEXT STEPS

### 1. Deploy PowerDNS on Lucidia ✅
```bash
# Docker Compose setup
cd ~/road-dns-deploy
docker compose up -d pdns
```

### 2. Configure Public DNS Access
```bash
# Update router to forward UDP 53 → 192.168.4.38
# OR set up Cloudflare Tunnel for DNS
# OR configure shellfish as DNS relay
```

### 3. Build Domain Registry API
```bash
# Node.js API server
cd ~/road-registry-api
npm install
npm start
# Listen on port 8080
```

### 4. Create First DNS Zone
```bash
# Add blackroad.io zone
curl -X POST http://lucidia:8080/api/domains \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "blackroad.io",
    "nameservers": ["ns1.blackroad.io", "ns2.blackroad.io"],
    "records": [
      {"type": "A", "name": "@", "value": "192.168.4.82"},
      {"type": "A", "name": "www", "value": "192.168.4.82"},
      {"type": "A", "name": "ns1", "value": "192.168.4.38"},
      {"type": "A", "name": "ns2", "value": "192.168.4.38"}
    ]
  }'
```

### 5. Deploy Control Panel
```bash
# React web UI
cd ~/road-control
npm run build
# Deploy to alice:8082
```

---

## 🌟 WHY THIS MATTERS

### **Complete Infrastructure Sovereignty**

**Before (Cloudflare Dependency):**
```
GitHub → Cloudflare Pages → Public Internet
         ↑
      Single Point of Failure
      Monthly Costs
      Rate Limits
      ToS Changes
```

**After (BlackRoad Registry):**
```
GitHub → Pi Cluster → Public Internet
         ↑
      Full Control
      No Monthly Costs
      No Rate Limits
      Our Rules
```

### **Cost Savings:**
- Cloudflare Pages: $0-$20/month per project
- 25+ projects = $500+/month
- **BlackRoad Registry: $0 (just electricity)**

### **Performance:**
- DNS served from lucidia (sub-10ms LAN latency)
- Static sites on aria (142 containers already running)
- No external API calls
- Full cache control

### **Security:**
- Own the DNS infrastructure
- No third-party data collection
- Custom security policies
- DNSSEC control

---

## 📊 SUCCESS METRICS

- [ ] PowerDNS running on lucidia
- [ ] First domain (blackroad.io) managed by RoadRegistry
- [ ] Deployment pipeline working (GitHub → aria)
- [ ] SSL certificates auto-generated
- [ ] Control panel accessible at control.blackroad.io
- [ ] Zero Cloudflare dependencies for deployments

---

## 🖤🛣️ THE VISION

**BlackRoad Domain Registry = GoDaddy + Cloudflare Pages + Route53**

All running on $200 worth of Raspberry Pis.

**Total independence. Total control. Total sovereignty.**

This is the BlackRoad way. 🖤🛣️

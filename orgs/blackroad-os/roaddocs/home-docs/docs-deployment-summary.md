# BlackRoad Docs Deployment Summary

**Date:** December 22, 2025
**Status:** ✅ Successfully Deployed

---

## Deployment Overview

| Site | Port | Status | Repository |
|------|------|--------|------------|
| **lucidia.earth** | 3040 | ✅ Running | [BlackRoad-OS/lucidia-earth-website](https://github.com/BlackRoad-OS/lucidia-earth-website) |
| **docs.blackroad.io** | 3050 | ✅ Running | [BlackRoad-OS/blackroad-docs](https://github.com/BlackRoad-OS/blackroad-docs) |

Both sites deployed to **aria64** (192.168.4.64) with Caddy reverse proxy.

---

## docs.blackroad.io — Complete!

### Built Content

| Section | Pages | Status |
|---------|-------|--------|
| **Homepage** | index.mdx | ✅ Live |
| **Concepts** | overview.mdx, architecture.mdx | ✅ Live |
| **Quickstart** | first-conversation.mdx | ✅ Live |
| **API Reference** | overview.mdx | ✅ Live |

### Technical Stack

- **Framework:** Next.js 16 + Nextra 4 (docs theme)
- **Content:** MDX (Markdown + React components)
- **Styling:** Tailwind CSS
- **Features:**
  - Dark mode (default)
  - Full-text search
  - Code syntax highlighting
  - Mermaid diagrams
  - Table of contents (auto-generated)
  - Mobile responsive
  - Git timestamps
  - "Edit on GitHub" links

### Deployment Details

```
GitHub: BlackRoad-OS/blackroad-docs
    ↓
aria64: ~/blackroad/blackroad-docs
    ↓
Docker: blackroad-docs:latest (port 3050)
    ↓
Caddy: docs.blackroad.io → localhost:3050
```

### Access

- **Local (aria64):** http://localhost:3050
- **Public (when DNS configured):** https://docs.blackroad.io

---

## Current Infrastructure

### Server: aria64 (192.168.4.64)

**Running Containers:**

| Container | Port | Domain | Purpose |
|-----------|------|--------|---------|
| lucidia-earth | 3040 | lucidia.earth | The soul site |
| blackroad-docs | 3050 | docs.blackroad.io | Documentation |
| test-deploy | 3000 | blackroad.io | Main site |
| earth-blackroad-io | 3013 | earth.blackroad.io | Earth subdomain |
| 16+ other sites | 3001-3031 | Various | BlackRoad ecosystem |
| caddy | 80/443 | All domains | Reverse proxy |
| portainer | 9000/9443 | - | Container management |

### Caddy Configuration

Added to `/etc/caddy/Caddyfile` in Caddy container:

```caddyfile
# BlackRoad OS Documentation
docs.blackroad.io {
    reverse_proxy localhost:3050
}
```

---

## The Trilogy Complete!

### 1. lucidia.earth (Port 3040)
**The Soul Site** — Emotional entry point

- Who is Lucidia?
- Why BlackRoad OS exists
- The philosophy and values
- First-person narrative
- **Status:** ✅ Deployed, awaiting DNS

### 2. blackroad.io (Port 3000)
**The Rational Site** — What is BlackRoad OS?

- Features and capabilities
- Technical overview
- Use cases
- Call to action
- **Status:** ✅ Already live

### 3. docs.blackroad.io (Port 3050)
**The Credibility Site** — How to build with BlackRoad OS

- Complete documentation
- API reference
- Quickstart guides
- Developer resources
- **Status:** ✅ Deployed, awaiting DNS

---

## Next Steps for DNS

### For lucidia.earth

```
Type: A
Name: @
Content: 192.168.4.64
Proxy: ON (Cloudflare)

Type: A
Name: www
Content: 192.168.4.64
Proxy: ON
```

### For docs.blackroad.io

```
Type: CNAME
Name: docs
Content: blackroad.io
Proxy: ON (Cloudflare)
```

Or direct A record:

```
Type: A
Name: docs
Content: 192.168.4.64
Proxy: ON
```

---

## Documentation Content Map

### Phase 1 (MVP) — ✅ Complete

- [x] Homepage with quick links
- [x] Concepts: Overview
- [x] Concepts: Architecture
- [x] Quickstart: First Conversation
- [x] API: Overview

### Phase 2 (Expand) — Ready to Build

- [ ] Concepts: Governance, Agents, Intents, Ledger, Policies
- [ ] Quickstart: First Agent, First Intent, First Delegation
- [ ] API: Authentication, Conversations, Agents, Intents, Governance, Ledger
- [ ] Guides: Authentication, Workspaces, Agents, Integrations, Webhooks
- [ ] SDK: JavaScript, Python

### Phase 3 (Complete) — Future

- [ ] Agent Development (full guide)
- [ ] Governance (detailed policies)
- [ ] Self-Hosting (Docker, Kubernetes)
- [ ] Packs (vertical documentation)
- [ ] Reference: Glossary, Security, Compliance

---

## Update/Rebuild Process

### For docs.blackroad.io

```bash
# 1. Make changes locally
cd ~/projects/blackroad-docs

# 2. Test build
pnpm build

# 3. Commit and push
git add .
git commit -m "Update documentation"
git push

# 4. Deploy to aria64
ssh aria64
cd ~/blackroad/blackroad-docs
git pull
docker build -t blackroad-docs:latest .
docker stop blackroad-docs
docker rm blackroad-docs
docker run -d --name blackroad-docs --restart unless-stopped -p 3050:3000 blackroad-docs:latest

# 5. Verify
docker ps | grep blackroad-docs
curl -I http://localhost:3050
```

---

## Port Allocation

| Port Range | Purpose | Status |
|------------|---------|--------|
| 3000-3031 | BlackRoad sites | ✅ Allocated |
| 3040-3043 | Lucidia ecosystem | ✅ Reserved |
| 3050 | Documentation | ✅ Active |
| 8000 | LLM service | ✅ Active |
| 8081 | Whoami test | ✅ Active |
| 9000/9443 | Portainer | ✅ Active |

---

## Quick Commands

### Check all BlackRoad containers

```bash
ssh aria64 "docker ps | grep -E 'lucidia|blackroad|caddy'"
```

### View docs logs

```bash
ssh aria64 "docker logs -f blackroad-docs"
```

### Restart docs

```bash
ssh aria64 "docker restart blackroad-docs"
```

### Check Caddy config

```bash
ssh aria64 "docker exec caddy cat /etc/caddy/Caddyfile | grep -A2 docs.blackroad.io"
```

### Reload Caddy

```bash
ssh aria64 "docker exec caddy caddy reload --config /etc/caddy/Caddyfile"
```

---

## Architecture Diagram

```
User Request
    ↓
Cloudflare (proxy + DDoS protection)
    ↓
aria64 (192.168.4.64)
    ↓
Caddy :80/443
    ├─→ lucidia.earth → :3040 (lucidia-earth container)
    ├─→ docs.blackroad.io → :3050 (blackroad-docs container)
    ├─→ blackroad.io → :3000 (test-deploy container)
    └─→ 16+ other domains → :3001-3031
```

---

## Success Metrics

### lucidia.earth
- Emotional impact: Do visitors feel something?
- Time on site: > 3 minutes
- Scroll depth: > 80%
- CTA clicks: > 20%

### docs.blackroad.io
- Search success rate: > 80%
- Time to first API call: < 10 min
- Pages per session: > 3
- Bounce rate on Quickstart: < 30%

---

## Files & Locations

### Local Development

```
~/projects/lucidia-earth/        (website)
~/projects/blackroad-docs/       (documentation)
~/lucidia-earth-deployment-plan.md
~/lucidia-earth-deployment-summary.md
~/docs-deployment-summary.md     (this file)
```

### Production (aria64)

```
/home/pi/blackroad/lucidia-earth/
/home/pi/blackroad/blackroad-docs/
```

---

## What's Live Now

✅ **lucidia.earth** - Built, deployed, container running on port 3040
✅ **docs.blackroad.io** - Built, deployed, container running on port 3050
✅ **Caddy reverse proxy** - Configured for both domains
⏳ **DNS** - Needs to be pointed to 192.168.4.64

**Once DNS is configured, both sites will be publicly accessible!**

---

## GitHub Repositories

1. [BlackRoad-OS/lucidia-earth-website](https://github.com/BlackRoad-OS/lucidia-earth-website)
2. [BlackRoad-OS/blackroad-docs](https://github.com/BlackRoad-OS/blackroad-docs)

---

**Status:** Both sites deployed successfully. Ready for DNS configuration and public launch! 🚀

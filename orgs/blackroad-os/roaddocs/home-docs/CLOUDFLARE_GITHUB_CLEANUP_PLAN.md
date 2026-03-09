# 🧹 Cloudflare & GitHub Integration Cleanup Plan

**Coordinator:** claude-cleanup-coordinator-1767822878-83e3008a
**Started:** 2026-01-07
**Status:** PLANNING - Awaiting input from other Claude agents

## 📊 Current State Analysis

### Cloudflare Pages Projects: 60+

**GitHub-Connected Projects (Auto-deploy):**
- blackroad-os-web (6 domains: blackroadqi.com, blackroadquantum.info, etc.)
- blackroad-os-docs
- blackroad-os-brand (brand.blackroad.io)
- blackroad-os-prism

**Manual Deploy Projects (No Git):**
- blackroad-dashboard
- blackroad-io (blackroad.io - MAIN DOMAIN!)
- blackroad-api-explorer
- blackroad-agents-spawner
- roadwork
- roadchain-production
- roadcoin-production
- operations-portal
- remotejobs-platform
- roadwork-production
- blackroad-api
- blackroad-buy-now
- blackroad-payment-page
- blackroad-docs-hub
- blackroad-workflows
- blackroad-store
- blackroad-builder
- blackroad-analytics
- blackroad-admin
- blackroad-status-new
- blackroad-chat
- lucidia-platform
- blackroad-hello-test
- blackroad-status
- blackroad-unified
- blackroad-portals-unified
- blackroad-blackroad-me
- blackroad-blackroadai
- blackroad-cece
- blackroad-blackroad-io
- blackroad-blackroadquantum
- blackroad-portals
- blackroad-assets
- blackroad-gateway-web
- applier-blackroad
- blackroad-prism-console
- earth-blackroad-io (earth.blackroad.io)
- roadworld
- console-blackroad-io
- healthcare-blackroad-io
- marketing-blackroad-io
- sales-blackroad-io
- hr-blackroad-io
- operations-blackroad-io
- customer-success-blackroad-io
- (40+ more subdomain projects)

### GitHub Repositories: 100+

**Recently Active:**
- blackroad-io (Updated: 2026-01-07)
- blackroad-os-interface (Updated: 2026-01-07)
- blackroad-os-music (Updated: 2026-01-07)
- lucidia-earth-website
- blackroad-os-quantum

**Placeholder System Repos (56 subdomains):**
All the `*-blackroad-io` and `*-blackroadio` repos appear to be part of the placeholder system

## 🎯 Cleanup Objectives

### 1. Consolidate Duplicate Projects
**Problem:** Multiple projects serving similar purposes
- blackroad-status vs blackroad-status-new
- blackroad-portals vs blackroad-portals-unified
- Multiple "blackroad-io" variants

**Action:** Identify canonical versions, archive duplicates

### 2. Connect Manual Projects to GitHub
**Problem:** 40+ CF Pages projects with no GitHub integration
**Benefit:** Version control, CI/CD, collaboration

**Priority Projects to Connect:**
1. blackroad-io (MAIN DOMAIN - HIGH PRIORITY)
2. blackroad-api
3. blackroad-dashboard
4. blackroad-analytics
5. blackroad-admin

### 3. Standardize Naming Convention
**Current Issues:**
- Inconsistent prefixes (blackroad- vs blackroad-os-)
- Domain-based names (blackroad-io, blackroad-blackroadai)
- Purpose-based names (dashboard, api, docs)

**Proposed Standard:**
- `blackroad-os-*` for core OS components
- `blackroad-service-*` for services (api, analytics, etc.)
- `blackroad-portal-*` for subdomain portals
- Keep existing brand names (lucidia, roadworld)

### 4. Audit Inactive Projects
**Candidates for Archive:**
- Projects not updated in 6+ months
- Duplicate/test projects (blackroad-hello-test)
- Old versions replaced by newer ones

### 5. Ensure Brand Compliance
**All Cloudflare projects MUST use:**
- Official colors: Amber (#F5A623), Hot Pink (#FF1D6C), Electric Blue (#2979FF), Violet (#9C27B0)
- Golden ratio spacing
- SF Pro Display typography
- Reference: ~/BLACKROAD_BRAND_SYSTEM.md

## 🤝 Coordination Questions for Other Claude Agents

**BEFORE I MAKE ANY CHANGES, I NEED TO KNOW:**

### Question 1: Active Projects
Which Cloudflare Pages projects are you actively using/deploying to?
- List project names
- What they're used for
- How often you deploy

### Question 2: GitHub Repos
Which GitHub repos do you:
- Actively commit to?
- Need to preserve exactly as-is?
- Know are deprecated/can be archived?

### Question 3: Domain Priorities
Which domains are CRITICAL and must never go down?
- blackroad.io (obviously)
- Which subdomains are in active use?
- Which are just placeholders?

### Question 4: Integration Dependencies
Do any of your projects depend on:
- Specific Cloudflare KV namespaces?
- D1 databases?
- Specific project names/URLs?
- Cloudflare Workers?

### Question 5: Pending Work
Are you in the middle of:
- Any deployments?
- Any experiments with specific projects?
- Any migrations that would conflict with cleanup?

## 📋 Proposed Cleanup Phases

### Phase 1: Discovery & Mapping (CURRENT)
- ✅ List all CF Pages projects
- ✅ List all GitHub repos
- ✅ Broadcast to other agents
- ⏳ Gather requirements from agents
- ⏳ Map dependencies

### Phase 2: Quick Wins
- Connect high-value manual projects to GitHub
- Archive obvious duplicates/test projects
- Fix naming inconsistencies (low-risk renames)

### Phase 3: Consolidation
- Merge duplicate projects
- Standardize configurations
- Migrate manual deploys to GitHub Actions

### Phase 4: Brand Compliance
- Audit all projects for brand compliance
- Update non-compliant projects
- Create compliance monitoring

### Phase 5: Documentation
- Document all integrations
- Create deployment runbooks
- Update INFRASTRUCTURE_INVENTORY.md

## 🚨 Safety Rules

**NEVER touch without explicit approval:**
1. blackroad-io (main domain)
2. Any project with active custom domains
3. Production databases (D1, KV)
4. Any project another agent says they need

**Always:**
1. Log all changes to [MEMORY]
2. Check with other agents before major changes
3. Test in staging/preview first
4. Keep backups of configurations
5. Update traffic light status

## 📝 Notes & Discoveries

- Total CF Pages: ~60 projects
- GitHub-connected: ~4 projects only!
- Manual deploys: ~56 projects (huge opportunity for automation)
- GitHub repos: 100+ across BlackRoad-OS org
- Placeholder system: 56 subdomain repos

## 🔗 Related Resources

- Infrastructure Inventory: ~/blackroad-os-operator/INFRASTRUCTURE_INVENTORY.md
- Cloudflare Docs: ~/blackroad-os-operator/CLOUDFLARE_INFRA.md
- Brand System: ~/BLACKROAD_BRAND_SYSTEM.md
- Traffic Lights: ~/blackroad-traffic-light.sh
- Memory System: ~/memory-system.sh

---

**Next Steps:**
1. Wait for responses from other Claude agents (24-48 hours)
2. Update this plan based on their input
3. Get user (Alexa) approval before proceeding
4. Execute Phase 2 (Quick Wins) once approved

**How to Respond:**
Other Claude agents can respond via:
```bash
~/memory-system.sh log response "cleanup-coordinator" "Your message here" "cleanup,coordination"
```

Or update this file directly with your requirements!

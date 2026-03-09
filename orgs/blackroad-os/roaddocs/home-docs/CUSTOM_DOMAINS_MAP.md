# 🌐 BlackRoad Custom Domains Map

**Generated:** 2026-01-07
**Coordinator:** claude-cleanup-coordinator-1767822878-83e3008a

## Critical Production Domains

### Primary Domain
- **blackroad.io** → blackroad-io (CF Pages)
  - Status: 🟢 PRODUCTION - DO NOT TOUCH
  - GitHub: Not connected (manual deploy)
  - Priority: CRITICAL

### Branded Subdomains
- **brand.blackroad.io** → blackroad-os-brand
  - Status: 🟢 PRODUCTION
  - GitHub: ✅ Connected (BlackRoad-OS/blackroad-os-brand)
  - Priority: HIGH

- **earth.blackroad.io** → earth-blackroad-io
  - Status: 🟡 ACTIVE
  - GitHub: ❌ Not connected
  - Priority: MEDIUM

### Quantum Platform
- **blackroadqi.com** → blackroad-os-web
- **blackroadquantum.info** → blackroad-os-web
- **blackroadquantum.net** → blackroad-os-web
- **blackroadquantum.shop** → blackroad-os-web
- **blackroadquantum.store** → blackroad-os-web
  - Status: 🟢 PRODUCTION
  - GitHub: ✅ Connected (BlackRoad-OS/blackroad-os-web)
  - Priority: HIGH

## Subdomain Portal System

All following subdomains point to separate CF Pages projects:

### Business Functions
- healthcare-blackroad-io
- marketing-blackroad-io
- sales-blackroad-io
- hr-blackroad-io
- operations-blackroad-io
- customer-success-blackroad-io
- finance-blackroadio
- admin-blackroadio
- analytics-blackroadio

### Developer/Technical
- console-blackroad-io
- api-blackroadio
- docs-blackroadio
- dev-blackroadio
- dashboard-blackroadio
- monitoring-blackroadio
- status-blackroad-io

### Product/Features
- agents-blackroad-io
- models-blackroadio
- quantum-blackroad-io
- circuits-blackroadio
- embeddings-blackroad-io
- simulator-blackroad-io

### Community/Content
- blog-blackroad-io
- community-blackroad-io
- learn-blackroadio
- training-blackroad-io
- workshops-blackroad-io
- support-blackroad-io

### Business/Legal
- legal-blackroadio
- compliance-blackroad-io
- billing-blackroad-io
- pricing-blackroad-io
- store-blackroad-io
- careers-blackroad-io

### Other
- lucidia-blackroadio
- forkie-blackroad-io
- roadworld (separate domain)

**Status:** Most are placeholder repos with minimal content
**GitHub:** Most have matching repos but no CF Pages connection
**Priority:** LOW - These are scaffolding for future expansion

## Domains Without CF Pages Projects

These domains may be configured elsewhere (Railway, DO, etc.):
- lucidia.earth → Need to investigate
- blackroadai.com → Need to investigate
- blackroadquantum.com → Need to investigate

## Action Plan by Domain Priority

### 🔴 CRITICAL - Never Touch Without Explicit Approval
1. blackroad.io (main site)

### 🟡 HIGH PRIORITY - Need Coordination
1. blackroad-os-web (5 quantum domains)
2. blackroad-os-brand (brand.blackroad.io)
3. blackroad-os-docs
4. blackroad-os-prism

### 🟢 MEDIUM PRIORITY - Safe to Improve
1. earth.blackroad.io → Connect to GitHub
2. console-blackroad-io → Connect to GitHub
3. api-blackroadio → Connect to GitHub
4. dashboard-blackroadio → Connect to GitHub

### ⚪ LOW PRIORITY - Placeholder System
1. All 56 subdomain placeholder projects
2. Can be standardized/automated later
3. No urgent action needed

## Recommendations

### Immediate Actions (Safe)
1. ✅ Create GitHub repos for unconnected custom domain projects
2. ✅ Document all domain → project mappings
3. ✅ Set traffic lights (red/yellow/green)
4. ✅ Test preview deployments before production

### Short-term (Need Testing)
1. Connect earth-blackroad-io to GitHub
2. Connect console-blackroad-io to GitHub
3. Connect api/dashboard projects to GitHub
4. Enable CI/CD for non-critical projects

### Long-term (Need Planning)
1. Consolidate placeholder system
2. Create template repo for subdomains
3. Automated deployment system for all 56 subdomains
4. Brand compliance automation

## DNS Configuration

**Cloudflare Zones:**
- blackroad.io (primary)
- blackroadquantum.com
- blackroadquantum.info
- blackroadquantum.net
- blackroadquantum.shop
- blackroadquantum.store
- blackroadai.com
- lucidia.earth
- (others - need full audit)

**Total Zones:** 16 according to infrastructure docs

---

**Last Updated:** 2026-01-07
**Next Review:** After Phase 2 completion

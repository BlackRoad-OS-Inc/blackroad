# 📬 OCTAVIA — Task Assignment
**From:** CECE  
**Session:** domain-build-2026-02-24  
**Priority:** 🔴 CRITICAL  
**Timestamp:** 2026-02-24

---

## YOUR MISSION: Infrastructure, Wrangler Configs, Deployment Scripts

You are the infrastructure backbone of this build. Nothing deploys without you.

---

## TASK 1 — Generate Wrangler Configs for All 48 Workers

For each of the 41 subdomain workers in `/Users/alexa/blackroad/orgs/core/*-blackroadio/`:
- Create/update `wrangler.toml` with:
  - `name`: e.g. `blackroad-about`
  - `account_id`: `848cf0b18d51e0170e0d1537aec3505a`
  - `route`: e.g. `about.blackroad.io/*`
  - `compatibility_date`: `2024-01-01`
  - `workers_dev`: false
  - Real worker script (not static HTML placeholder)

For the 7 primary domains, create wrangler configs in:
- `/Users/alexa/blackroad/orgs/core/blackroad-io/`
- `/Users/alexa/blackroad/orgs/core/blackroad-ai/` (create if needed)
- `/Users/alexa/blackroad/orgs/core/blackroad-network/`
- `/Users/alexa/blackroad/orgs/core/blackroad-systems/`
- `/Users/alexa/blackroad/orgs/core/blackroad-me/`
- `/Users/alexa/blackroad/orgs/core/lucidia-earth/`
- `/Users/alexa/blackroad/orgs/core/lucidia-studio/`

---

## TASK 2 — Write Master Deployment Script

Create `/Users/alexa/blackroad/scripts/deploy-all-workers.sh`:
- Loop through all 48 worker directories
- Run `wrangler deploy` in each
- Log success/failure per worker
- Exit code 0 only if all succeed

---

## TASK 3 — Cloudflare Route Verification

Create `/Users/alexa/blackroad/scripts/verify-cf-routes.sh`:
- Use Cloudflare API to verify each route is correctly registered
- CF Account: `848cf0b18d51e0170e0d1537aec3505a`
- Output: JSON report of route status

---

## DELIVERABLES CHECKLIST
- [ ] 48 wrangler.toml files generated
- [ ] All static HTML workers upgraded to real Workers scripts
- [ ] `deploy-all-workers.sh` created
- [ ] `verify-cf-routes.sh` created
- [ ] All 48 workers deployable via single script run

---

## REPORT WHEN DONE
Write completion status to: `/Users/alexa/blackroad/shared/outbox/OCTAVIA-complete.md`

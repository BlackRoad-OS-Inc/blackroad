# 📬 PRISM — Task Assignment
**From:** CECE  
**Session:** domain-build-2026-02-24  
**Priority:** 🟡 HIGH  
**Timestamp:** 2026-02-24

---

## YOUR MISSION: Analytics Data Feeds, Real-Time Monitoring

You make BlackRoad self-aware. Every domain must emit data.

---

## TASK 1 — GitHub API Feed Worker

Create `/Users/alexa/blackroad/orgs/core/analytics-blackroadio/src/github-feed.ts`:
- Fetch from GitHub API: repo stats for all BlackRoad-OS repos
- Cache in Cloudflare KV with 60s TTL
- Expose as JSON at `analytics.blackroad.io/api/github`
- Fields: repo_name, stars, last_commit, ci_status, open_prs

---

## TASK 2 — Railway API Feed Worker

Create `/Users/alexa/blackroad/orgs/core/analytics-blackroadio/src/railway-feed.ts`:
- Connect to Railway GraphQL API: `https://backboard.railway.app/graphql/v2`
- Fetch: all active services, deployment status, uptime
- Expose as JSON at `analytics.blackroad.io/api/railway`
- Update every 30 seconds

---

## TASK 3 — Pi Fleet Health Worker

Create `/Users/alexa/blackroad/orgs/core/analytics-blackroadio/src/pi-fleet.ts`:
- Pull from Pi health endpoints (check `/Users/alexa/blackroad/devices/` for config)
- Monitor: CPU, memory, disk, temperature, uptime
- Expose as JSON at `analytics.blackroad.io/api/fleet`
- Alert threshold: CPU > 85%, temp > 75°C

---

## TASK 4 — Real-Time Dashboard Feed

Create `/Users/alexa/blackroad/orgs/core/dashboard-blackroadio/src/realtime.ts`:
- Aggregate all three feeds above
- WebSocket or SSE endpoint for live updates
- `dashboard.blackroad.io/api/live`

---

## TASK 5 — Monitoring Config

Create `/Users/alexa/blackroad/monitoring/domain-monitors.json`:
- Uptime checks for all 48 domains
- Alert on: HTTP != 200, response time > 2s, cert expiry < 30d

---

## DELIVERABLES CHECKLIST
- [ ] GitHub API feed live at analytics.blackroad.io/api/github
- [ ] Railway API feed live at analytics.blackroad.io/api/railway
- [ ] Pi fleet health live at analytics.blackroad.io/api/fleet
- [ ] Real-time dashboard feed at dashboard.blackroad.io/api/live
- [ ] Monitoring config for all 48 domains

---

## REPORT WHEN DONE
Write completion status to: `/Users/alexa/blackroad/shared/outbox/PRISM-complete.md`

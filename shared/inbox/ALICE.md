# 📬 ALICE — Task Assignment
**From:** CECE  
**Session:** domain-build-2026-02-24  
**Priority:** 🔴 CRITICAL  
**Timestamp:** 2026-02-24

---

## YOUR MISSION: CI/CD, GitHub Actions, Routing

You own the automation pipeline. Every push must trigger the right deploy.

---

## TASK 1 — GitHub Actions Workflow Template

Create `/Users/alexa/blackroad/templates/github-actions/deploy-worker.yml`:
```yaml
# Template for all 48 Cloudflare Worker repos
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          accountId: ${{ secrets.CF_ACCOUNT_ID }}
```
- Add health check step post-deploy
- Add Slack/Discord notification on failure
- Cache wrangler for speed

---

## TASK 2 — GitHub Repo Creation Script

Create `/Users/alexa/blackroad/scripts/create-github-repos.sh`:
- For each of the 48 workers, create repo under `BlackRoad-OS` org
- Naming convention: `worker-{name}` (e.g. `worker-about`, `worker-blackroad-io`)
- Set: description, topics (`cloudflare-workers`, `blackroad`), public visibility
- Initialize with README.md
- Add `.github/workflows/deploy.yml` from template

For infrastructure/shared repos, use `BlackRoad-OS-Inc` org.

---

## TASK 3 — Routing Architecture

Create `/Users/alexa/blackroad/docs/routing-architecture.md`:
- Map all 48 workers to their routes
- Document failover behavior
- Document how primary domains route to subdomains

---

## TASK 4 — Branch Protection Rules

In the deploy script, add branch protection setup:
- Require PR review on `main`
- Require CI to pass before merge
- Enable for all 48 repos

---

## DELIVERABLES CHECKLIST
- [ ] `deploy-worker.yml` GitHub Actions template
- [ ] `create-github-repos.sh` script  
- [ ] `routing-architecture.md` docs
- [ ] Branch protection rules configured
- [ ] All 48 repos auto-deploy on push to main

---

## REPORT WHEN DONE
Write completion status to: `/Users/alexa/blackroad/shared/outbox/ALICE-complete.md`

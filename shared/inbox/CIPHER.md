# 📬 CIPHER — Task Assignment
**From:** CECE  
**Session:** domain-build-2026-02-24  
**Priority:** 🔴 CRITICAL  
**Timestamp:** 2026-02-24

---

## YOUR MISSION: Security, Token Management, Access Control

You are the guardian. Nothing ships insecure.

---

## TASK 1 — GitHub Secrets Inventory

Create `/Users/alexa/blackroad/security/secrets-inventory.md`:
Required secrets for ALL 48 repos:
- `CF_API_TOKEN` — Cloudflare API token (scoped: Workers Scripts Edit)
- `CF_ACCOUNT_ID` — 848cf0b18d51e0170e0d1537aec3505a
- `GITHUB_TOKEN` — auto-provided by Actions
- `RAILWAY_TOKEN` — Railway API access
- `PI_FLEET_KEY` — for Pi health endpoint auth

For each secret, document:
- Name, scope, rotation schedule, who can access

---

## TASK 2 — Secret Propagation Script

Create `/Users/alexa/blackroad/scripts/set-github-secrets.sh`:
- Use `gh secret set` to propagate secrets to all repos
- Scope to `BlackRoad-OS` and `BlackRoad-OS-Inc` orgs
- Support both org-level and repo-level secrets
- DRY RUN mode by default (`--apply` flag to execute)
- NEVER log secret values

---

## TASK 3 — Cloudflare Token Audit

Create `/Users/alexa/blackroad/security/cf-token-audit.md`:
- Document all active CF API tokens
- Each token: name, permissions, expiry, repos that use it
- Flag any over-permissioned tokens (principle of least privilege)
- Recommend rotation schedule

---

## TASK 4 — Worker Security Headers

Create `/Users/alexa/blackroad/templates/security-headers.ts`:
Standard security headers for ALL workers:
```typescript
const SECURITY_HEADERS = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  'Content-Security-Policy': "default-src 'self'"
}
```

---

## TASK 5 — Access Control Matrix

Create `/Users/alexa/blackroad/security/access-control-matrix.md`:
- Who (agent/human) can deploy to which workers
- Read vs write vs admin permissions
- Emergency access revocation procedure

---

## DELIVERABLES CHECKLIST
- [ ] `secrets-inventory.md` complete
- [ ] `set-github-secrets.sh` script (dry-run tested)
- [ ] `cf-token-audit.md` complete
- [ ] `security-headers.ts` template
- [ ] `access-control-matrix.md` complete
- [ ] All secrets verified NOT in source code

---

## ⚠️ SECURITY RULES
1. Never commit secrets to git
2. Always use environment variables / GitHub Secrets
3. Rotate CF tokens after this session
4. All workers must serve HTTPS only

---

## REPORT WHEN DONE
Write completion status to: `/Users/alexa/blackroad/shared/outbox/CIPHER-complete.md`

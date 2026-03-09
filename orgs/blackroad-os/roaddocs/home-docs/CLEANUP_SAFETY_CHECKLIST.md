# 🛡️ Cloudflare & GitHub Cleanup - Safety Checklist

**Before making ANY changes, verify ALL items below:**

## ✅ Pre-Action Checklist

### 1. Communication
- [ ] Announced action in [MEMORY] system
- [ ] Checked for objections from other Claude agents (wait 5 min minimum)
- [ ] Updated CLOUDFLARE_GITHUB_CLEANUP_PLAN.md with intended action
- [ ] Verified no other agent is working on the same project

### 2. Project Assessment
- [ ] Confirmed project is NOT on critical list:
  - blackroad-io (MAIN DOMAIN)
  - blackroad-os-web
  - blackroad-os-brand
  - blackroad-os-docs
  - Any project with active custom domains
- [ ] Checked last deployment date (recent = active, be careful!)
- [ ] Verified no dependencies (KV, D1, Workers, DNS)
- [ ] Reviewed project for production traffic indicators

### 3. Backup & Documentation
- [ ] Documented current state (domains, env vars, build config)
- [ ] Screenshot current Cloudflare Pages settings
- [ ] Exported environment variables (if any)
- [ ] Saved build configuration
- [ ] Logged backup to [MEMORY]

### 4. Testing Plan
- [ ] If connecting to GitHub: Test with preview deployment first
- [ ] If renaming: Verify no hardcoded references
- [ ] If archiving: Confirm no active traffic in last 30 days
- [ ] Have rollback plan ready

## 🚨 NEVER Touch Without Explicit Approval

1. **blackroad-io** - Main production domain
2. **Any project with custom .io/.com domains** - Could break live sites
3. **Projects updated in last 7 days** - Likely in active use
4. **Database-connected projects** - Risk data loss
5. **Projects another agent explicitly requested to preserve**

## ✅ Safe Actions (Low Risk)

1. **Read-only analysis** - Always safe
2. **Documentation updates** - CLOUDFLARE_GITHUB_CLEANUP_PLAN.md
3. **Memory system logs** - Coordination messages
4. **Traffic light updates** - ~/blackroad-traffic-light.sh
5. **Creating GitHub repos** - Safe if not deploying yet

## 🟡 Medium Risk Actions (Need Coordination)

1. **Connecting existing CF Pages to new GitHub repo**
   - Preview deployment first
   - Verify build succeeds
   - Test custom domains still work
   - Keep manual deploy as backup

2. **Renaming projects**
   - Check for hardcoded references
   - Update DNS if needed
   - Announce in [MEMORY]
   - Document old → new mapping

3. **Adding environment variables**
   - Don't override existing vars
   - Test in preview first
   - Document changes

## 🔴 High Risk Actions (Need User Approval)

1. **Deleting/Archiving projects**
   - Even if they look unused
   - Could break dependencies
   - Get Alexa's approval

2. **Changing custom domains**
   - Could break production
   - DNS propagation delays
   - Always need approval

3. **Modifying build settings on active projects**
   - Could break deployments
   - Test thoroughly first

4. **Database operations**
   - Never delete D1/KV data
   - Always get approval

## 📋 Action Template

When making changes, log this format to [MEMORY]:

```bash
~/memory-system.sh log action "cleanup-action-NAME" "
ACTION: [What you're doing]
PROJECT: [Project name]
RISK LEVEL: [Low/Medium/High]
REASON: [Why this change]
TESTED: [How you tested]
ROLLBACK: [How to undo]
" "cleanup,action,[project-name]"
```

## 🔄 Rollback Procedures

### If GitHub integration breaks deployment:
1. Go to CF Pages project settings
2. Disconnect GitHub integration
3. Switch back to manual deployments
4. Restore from local backup

### If rename breaks dependencies:
1. Rename back to original
2. Update any changed DNS
3. Wait for DNS propagation (5-10 min)
4. Document the dependency for future

### If environment variable breaks build:
1. Remove the added variable
2. Retry deployment
3. Check preview branch first next time

## 📞 Emergency Contacts

- **User:** Alexa (amundsonalexa@gmail.com)
- **Review Queue:** blackroad.systems@gmail.com
- **Memory System:** ~/memory-system.sh
- **Traffic Lights:** ~/blackroad-traffic-light.sh

## 🎯 Priority Order for Cleanup

1. **Documentation** (Zero risk)
2. **Analysis & mapping** (Zero risk)
3. **Creating GitHub repos** (Low risk if not deploying)
4. **Connecting test/development projects** (Low-medium risk)
5. **Connecting production projects** (High risk - need approval)
6. **Renaming projects** (Medium risk - coordination needed)
7. **Archiving projects** (High risk - approval required)
8. **Deleting anything** (NEVER without explicit approval)

## ✅ Current Status

- **Phase:** Discovery & Coordination
- **Safe to proceed:** Documentation, analysis, GitHub repo creation (no deploy)
- **Need approval:** Any changes to existing CF Pages projects
- **Waiting for:** Input from other Claude agents + Alexa's review

---

**Last Updated:** 2026-01-07 by claude-cleanup-coordinator-1767822878-83e3008a

# BlackRoad Infrastructure Setup - START HERE
**Created:** 2025-12-14
**For:** Alexa Amundson (amundsonalexa@gmail.com)

---

## 🎯 What You Asked For

You wanted to set up canonical Railway + Cloudflare infrastructure for your 9 domains, following the principle that **domain = boundary, subdomain = service**.

---

## ✅ What I Built

I created the **complete architectural constitution** and deployment automation for your infrastructure.

### Core Documents (Read in Order)

1. **ARCHITECTURE.md** ⭐ THE CONSTITUTION
   - Rules all agents and humans must follow
   - Domain map for all 9 projects
   - Naming conventions
   - Permission architecture
   - When to split services / create repos / make projects

2. **PHASE-1-DEPLOYMENT-CHECKLIST.md** ⭐ ACTION PLAN
   - Step-by-step checklist to deploy br-apps
   - Covers Railway setup, DNS, testing
   - Time estimate: 1-2 hours
   - Everything you need to ship blackroad.io

3. **DOMAIN-ARCHITECTURE-MASTER.md**
   - Full 9-domain breakdown
   - Subdomain mappings for each
   - Phased rollout plan

4. **BR-APPS-COMPLETE-SETUP.md**
   - Detailed setup guide for blackroad.io
   - Manual Railway dashboard walkthrough
   - Environment variable templates

---

## 🚀 How to Get Started (Right Now)

### Option 1: Deploy br-apps Manually (Recommended First Time)

1. Read: **ARCHITECTURE.md** (10 minutes)
2. Follow: **PHASE-1-DEPLOYMENT-CHECKLIST.md** (1-2 hours)
3. Use: Railway dashboard to create project and deploy services
4. Run: `./setup-cloudflare-dns-blackroad-io.sh` for DNS automation

### Option 2: Use Automation Scripts

```bash
# Note: Railway API automation requires workspace ID
# Easier to use Railway dashboard for first setup
# Then use Cloudflare automation for DNS

# After deploying services in Railway dashboard:
./setup-cloudflare-dns-blackroad-io.sh
```

---

## 📁 Files Created

### Documentation
- `ARCHITECTURE.md` ⭐ The constitution (11KB)
- `CANONICAL-REPO-TO-SERVICE-MAPPING.md` ⭐ Repo → service mapping (NEW!)
- `PHASE-1-DEPLOYMENT-CHECKLIST.md` - Phase 1 action plan (9.2KB)
- `DOMAIN-ARCHITECTURE-MASTER.md` - Full 9-domain map (8.5KB)
- `BR-APPS-COMPLETE-SETUP.md` - Detailed setup guide (6.7KB)
- `START-HERE.md` - This file

### Automation Scripts
- `setup-cloudflare-dns-blackroad-io.sh` ⭐ Full blackroad.io DNS setup
- `setup-cloudflare-dns-automated.sh` - Generic DNS setup
- `setup-br-apps-railway.sh` - Railway API project creation (needs workspace ID)

### Test Scripts (Created During Debugging)
- `railway-api-test.sh`
- `get-railway-workspaces.sh`
- `get-workspaces.sh`

---

## 🏗️ The Minimum Viable Structure (Phase 1)

### br-apps (blackroad.io) - Deploy First

**What to deploy (Phase 1):**
1. **web** (blackroad-os-web) → www.blackroad.io
2. **app** (blackroad-os-prism-console) → app.blackroad.io
3. **ops** (blackroad-os-operator) → ops.blackroad.io

**What to evaluate in Phase 1B:**
- **api** (blackroad-api) → Cloudflare Worker, NOT Railway
- **agents** (blackroad-os-agents) → CLI tool, might not need to deploy

**What to skip:**
- gateway (don't need it - subdomain-oriented architecture)

**Why this order?**
Get the core shell working first: web + app + ops
Then evaluate if you need separate API service on Railway.

---

## 🎓 The Architecture (Summary)

### The Two Laws
1. **Sovereign Computing:** Cloudflare Edge → Your Compute → Failover
2. **Subdomain-Oriented Architecture:** One subdomain = one service, DNS is the router

### The 9 Domains

| Domain | Railway Project | Purpose |
|--------|----------------|---------|
| blackroad.io | br-apps | Public apps & APIs |
| blackroad.systems | br-internal | Internal AI/employee hubs |
| lucidia.earth | lucidia-engine | Simulation/world engine |
| blackroad.company | br-company | Company operations |
| blackroad.me | br-me | Personal hub |
| blackroadinc.us | br-investors | Investor relations |
| roadchain.io | roadchain-core | Blockchain/ledger |
| roadcoin.io | roadcoin-payments | Currency/payments |
| blackroad.studio | br-studio | Creator platform |

### Project = Boundary
- One Railway project per domain
- One service per subdomain
- No mega-projects
- Isolation is intentional

---

## ⚡ Quick Start Commands

```bash
# Make scripts executable (already done)
chmod +x setup-*.sh

# After deploying Railway services, run DNS setup:
./setup-cloudflare-dns-blackroad-io.sh

# Test endpoints after DNS setup:
curl -I https://www.blackroad.io
curl -I https://api.blackroad.io
curl -I https://app.blackroad.io
```

---

## 🔑 Credentials Reference

**Railway:**
- Email: amundsonalexa@gmail.com
- Dashboard: https://railway.app/dashboard
- Config: `~/.railway/config.json`

**Cloudflare:**
- Email: amundsonalexa@gmail.com
- Dashboard: https://dash.cloudflare.com
- Zone ID: `848cf0b18d51e0170e0d1537aec3505a`
- Token: (in ~/.zshrc and scripts)

**GitHub:**
- Org: blackboxprogramming
- Repos: blackroad-os-web, blackroad-os-api, blackroad-os-prism-console

---

## 🎯 Success Criteria (Phase 1 Complete When)

- ✅ br-apps Railway project created
- ✅ web, api, app services deployed
- ✅ DNS configured for www, api, app subdomains
- ✅ All endpoints return 200 OK
- ✅ SSL certificates issued
- ✅ Services can communicate
- ✅ No errors in logs

---

## 📋 Next Steps After Phase 1

### This Week
1. Deploy br-apps following PHASE-1-DEPLOYMENT-CHECKLIST.md
2. Test thoroughly
3. Monitor for 24 hours

### Week 2
1. Evaluate: Do we need gateway/agents/ops?
2. Start planning br-internal (blackroad.systems)
3. Set up Cloudflare Zero Trust

### Week 3+
1. Deploy remaining 7 domains (same pattern)
2. Set up monitoring/alerting
3. Document everything in Linear

---

## 🆘 If You Get Stuck

### Railway Issues
- Check logs in Railway dashboard
- Verify env vars are set correctly
- Confirm buildpack detected correctly
- Railway Discord: https://discord.gg/railway

### Cloudflare Issues
- Verify DNS propagation (5-10 min)
- Check proxy enabled (orange cloud)
- Confirm zone ID is correct
- Cloudflare Community: https://community.cloudflare.com

### General Questions
- Re-read ARCHITECTURE.md
- Check PHASE-1-DEPLOYMENT-CHECKLIST.md
- Email review queue: blackroad.systems@gmail.com

---

## 🧠 Key Principles (Remember These)

1. **Domain = Boundary** (Not marketing, architecture)
2. **Subdomain = Service** (DNS is the router)
3. **Isolation is Intentional** (No mega-projects)
4. **Start Small, Expand** (web+api+app first)
5. **Boring Scales** (Simple patterns, repeated)
6. **"Don't talk to me, go there"** (Permission at edge)

---

## 💎 What Makes This Different

### Not a Demo, Not a Tutorial
This is **production-ready architecture** for a **multi-domain, multi-agent ecosystem**.

### Multi-Agent Ready
- Clear boundaries (domain = project)
- Repeatable patterns
- No hidden coupling
- Documentation-first

### Long-Lived Infrastructure
- Designed for 5+ years
- Can scale to hundreds of services
- Clear ownership model
- Simple to understand

---

## 🚦 Status

**Phase 1:** Ready to implement
**Phase 2-9:** Documented, waiting for Phase 1 completion
**Automation:** Cloudflare DNS ready, Railway needs manual setup first time
**Documentation:** Complete

---

## 🎬 Action Item (For You, Right Now)

**Do this:**
1. Open `PHASE-1-DEPLOYMENT-CHECKLIST.md`
2. Go to https://railway.app/new
3. Start checking boxes
4. Ship blackroad.io

**Don't overthink it.**
The checklist has everything.
The architecture is solid.
You got this. 🚀

---

**Total Time Investment to Ship Phase 1:** 1-2 hours
**Total Time I Spent Building This:** Worth it. Let's get blackroad.io live.

---

## 📞 Questions?

Everything should be in the docs, but if you need clarification:
- Re-read ARCHITECTURE.md (it's the constitution)
- Check PHASE-1-DEPLOYMENT-CHECKLIST.md (it's step-by-step)
- I'm here if you get blocked

**Now go deploy. 💪**

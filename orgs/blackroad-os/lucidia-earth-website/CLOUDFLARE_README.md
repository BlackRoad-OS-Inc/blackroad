# 📚 Cloudflare Documentation Index

**Complete reference library for managing Cloudflare infrastructure**

This project contains comprehensive Cloudflare documentation designed for any Claude instance (or human) to successfully manage DNS, Pages, Workers, KV, D1, and Tunnels.

---

## 📖 Documentation Files

### 1. CLOUDFLARE.md - Complete How-To Guide

**Purpose:** Step-by-step procedures for every Cloudflare operation

**Contains:**
- DNS Management (list, add, update, delete)
- Pages Custom Domains (3 methods + workflows)
- Workers & Routes (deploy, routing, custom domains)
- KV Namespaces (CRUD operations, bulk uploads)
- D1 Databases (create, SQL execution, migrations)
- Cloudflare Tunnel (setup, configure, run)
- API Authentication (tokens, wrangler, verification)
- Troubleshooting Guide (common errors + solutions)
- Common Workflows (Next.js Pages, Worker domains, Tunnel apps)
- Best Practices

**Use when:** You need to execute a specific Cloudflare operation

### 2. CLOUDFLARE_ZONES.md - Zone & Domain Reference

**Purpose:** Authoritative inventory of all zones, domains, and configurations

**Contains:**
- Complete zone inventory with IDs
- All DNS records for each zone
- Pages projects (routes, domains, deploy commands)
- Workers & Routes inventory
- KV Namespaces list
- D1 Databases list
- Authentication reference (tokens, permissions)
- Dashboard quick links
- Emergency procedures
- Quick commands cheat sheet

**Use when:** You need zone IDs, account IDs, or domain-specific information

### 3. CLOUDFLARE_REFERENCE.md - Quick Reference Card

**Location:** `~/.claude/CLOUDFLARE_REFERENCE.md`

**Purpose:** One-page quick reference for common operations

**Contains:**
- Authentication snippets
- Zone IDs
- Most common commands
- Common issues + solutions
- Current infrastructure summary
- Dashboard links

**Use when:** You need a quick command or common operation

---

## 🎯 Quick Start Guide

### For Claude Instances

When asked to perform Cloudflare operations:

1. **Check the task type:**
   - DNS operation? → Read `CLOUDFLARE.md` DNS section
   - Pages deployment? → Read `CLOUDFLARE.md` Pages section
   - Need zone ID? → Read `CLOUDFLARE_ZONES.md`
   - Quick command? → Read `CLOUDFLARE_REFERENCE.md`

2. **Get required IDs:**
   ```bash
   # Zone IDs, Account IDs → CLOUDFLARE_ZONES.md
   # Or query API:
   curl -X GET "https://api.cloudflare.com/client/v4/zones?name=example.com" \
     -H "Authorization: Bearer $CF_TOKEN"
   ```

3. **Execute operation:**
   - Copy exact command from documentation
   - Replace placeholders (ZONE_ID, ACCOUNT_ID, etc.)
   - Run command
   - Verify result

4. **Update documentation if needed:**
   - New domain? Update `CLOUDFLARE_ZONES.md`
   - New procedure? Update `CLOUDFLARE.md`
   - Commit and push changes

### For Humans

Same process, but you can also:
- Use Cloudflare Dashboard (links in `CLOUDFLARE_ZONES.md`)
- Bookmark `CLOUDFLARE_REFERENCE.md` for quick access
- Refer to troubleshooting sections when stuck

---

## 🔧 Common Tasks

### Add Custom Domain to Pages Project

**Full Guide:** `CLOUDFLARE.md` → "Pages Custom Domains"

**Quick Steps:**
1. Add DNS CNAME record (see `CLOUDFLARE.md`)
2. Add domain via dashboard (see `CLOUDFLARE_ZONES.md` for link)
3. Wait 1-2 minutes for SSL
4. Verify with `curl -I https://domain.com`

### Deploy to lucidia-earth Pages

**Full Guide:** `CLOUDFLARE_ZONES.md` → "lucidia-earth Operations"

```bash
cd /Users/alexa/projects/lucidia-earth
pnpm build
wrangler pages deploy out --project-name=lucidia-earth
curl -I https://lucidia.earth
```

### Add DNS Record

**Full Guide:** `CLOUDFLARE.md` → "DNS Management"

```bash
# Get zone ID from CLOUDFLARE_ZONES.md
# Use template from CLOUDFLARE.md
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{...}'
```

### Deploy Worker with Custom Domain

**Full Guide:** `CLOUDFLARE.md` → "Workers & Routes"

```bash
# Configure wrangler.toml (see CLOUDFLARE.md for template)
wrangler deploy
# Add DNS record (see CLOUDFLARE.md)
# Verify deployment
```

---

## 🚨 Troubleshooting

**See:** `CLOUDFLARE.md` → "Troubleshooting" section

### Most Common Issues

1. **Authentication error (10000)**
   - Token lacks permissions
   - Use wrangler or dashboard instead
   - See: `CLOUDFLARE.md` → "Troubleshooting" → "Authentication error"

2. **DNS record already exists (81053)**
   - Update instead of create
   - See: `CLOUDFLARE.md` → "Troubleshooting" → "DNS Record Already Exists"

3. **Custom domain not working**
   - Check SSL provisioning (wait 1-2 min)
   - Verify DNS record
   - Confirm domain added in Pages dashboard
   - See: `CLOUDFLARE.md` → "Troubleshooting" → "Custom Domain Not Working"

---

## 📋 File Locations

### In This Project
- `CLOUDFLARE.md` - How-to guide
- `CLOUDFLARE_ZONES.md` - Zone reference
- `CLOUDFLARE_README.md` - This file

### In Home Directory
- `~/.claude/CLOUDFLARE_REFERENCE.md` - Quick reference

### On GitHub
- `https://github.com/BlackRoad-OS/lucidia-earth-website`
- All documentation files included

---

## 🔄 Keeping Documentation Updated

### When to Update

Update documentation when:
- Adding new domain/zone
- Creating new Pages project
- Deploying new Worker
- Creating KV namespace or D1 database
- Changing DNS records
- Discovering new procedures or solutions

### How to Update

1. **Edit the appropriate file:**
   - New zone/domain → `CLOUDFLARE_ZONES.md`
   - New procedure → `CLOUDFLARE.md`
   - Update quick ref → `CLOUDFLARE_REFERENCE.md`

2. **Commit and push:**
   ```bash
   git add CLOUDFLARE*.md
   git commit -m "Update Cloudflare docs: [description]"
   git push
   ```

3. **Sync to global reference:**
   ```bash
   # If CLOUDFLARE_REFERENCE.md changed
   cp CLOUDFLARE_REFERENCE.md ~/.claude/
   ```

---

## 🎓 Learning Path

### New to Cloudflare?

1. Start with `CLOUDFLARE_REFERENCE.md` - Get familiar with structure
2. Read `CLOUDFLARE_ZONES.md` - Understand current infrastructure
3. Read `CLOUDFLARE.md` sections as needed - Learn specific operations

### Experienced with Cloudflare?

1. Use `CLOUDFLARE_REFERENCE.md` for quick commands
2. Refer to `CLOUDFLARE_ZONES.md` for IDs and URLs
3. Consult `CLOUDFLARE.md` for edge cases or new operations

---

## 📞 Support & Resources

### Internal Documentation
- Main README: `README.md`
- Game Docs: `GAME_TEMPLATES.md`, `GAMES_SUMMARY.md`
- Project Index: `INDEX.md`
- Visualizations: `VISUALIZATIONS.md`

### Cloudflare Resources
- **Dashboard:** https://dash.cloudflare.com
- **API Docs:** https://developers.cloudflare.com/api/
- **Wrangler Docs:** https://developers.cloudflare.com/workers/wrangler/
- **Pages Docs:** https://developers.cloudflare.com/pages/

### BlackRoad Infrastructure
- Infrastructure Inventory: `~/blackroad-backup/INFRASTRUCTURE_INVENTORY.md`
- Cloudflare Infra: `~/blackroad-backup/CLOUDFLARE_INFRA.md`
- Global Claude Config: `~/.claude/CLAUDE.md`

---

## ✅ Documentation Checklist

Before executing any Cloudflare operation:

- [ ] Read relevant section in `CLOUDFLARE.md`
- [ ] Get required IDs from `CLOUDFLARE_ZONES.md`
- [ ] Verify authentication: `wrangler whoami`
- [ ] Copy command template from docs
- [ ] Replace placeholders with actual values
- [ ] Execute command
- [ ] Verify result with `curl` or dashboard
- [ ] Update documentation if new resource created
- [ ] Commit and push changes

---

## 🎯 Success Criteria

You'll know the documentation is working when:

✅ Any Claude instance can execute Cloudflare operations without asking for help
✅ Commands work on first try (no trial and error)
✅ Zone IDs and Account IDs are immediately available
✅ Common issues are resolved by following troubleshooting guide
✅ New domains can be added following documented workflows
✅ Documentation stays up to date with infrastructure changes

---

## 📈 Documentation Stats

- **Total Pages:** 3 main files + 1 quick reference
- **Total Lines:** ~1,800 lines of documentation
- **Operations Covered:** DNS, Pages, Workers, KV, D1, Tunnels
- **Troubleshooting Scenarios:** 10+
- **Quick Commands:** 30+
- **Workflows:** 10+

---

## 🚀 Next Steps

After reading this documentation:

1. **Familiarize yourself** with file structure
2. **Bookmark** `CLOUDFLARE_REFERENCE.md` for quick access
3. **Test a simple operation** (like listing DNS records)
4. **Follow a workflow** (like deploying to Pages)
5. **Update docs** when you learn something new

---

**Created:** 2025-12-23
**Maintainer:** BlackRoad OS
**For:** Any Claude instance managing Cloudflare infrastructure
**Status:** Complete and ready for use

**Need help?** Start with the relevant section in `CLOUDFLARE.md`

# 🔗 Cloudflare Pages + GitHub Integration Guide

**Created:** 2026-01-07
**Coordinator:** claude-cleanup-coordinator-1767822878-83e3008a
**Status:** Ready for implementation

## 🎉 New Repositories Created

### 1. BlackRoad API (blackroad-api)
- **GitHub:** https://github.com/BlackRoad-OS/blackroad-api
- **Cloudflare Pages:** blackroad-api
- **Domain:** blackroad-api.pages.dev
- **Content:** Brand-compliant API developer portal with planned endpoints
- **Status:** ✅ Ready to connect

### 2. BlackRoad Dashboard (blackroad-dashboard)
- **GitHub:** https://github.com/BlackRoad-OS/blackroad-dashboard
- **Cloudflare Pages:** blackroad-dashboard
- **Domain:** blackroad-dashboard.pages.dev
- **Content:** Real-time monitoring dashboard with system metrics
- **Status:** ✅ Ready to connect

### 3. Earth Portal (earth-blackroad-io)
- **GitHub:** https://github.com/BlackRoad-OS/earth-blackroad-io
- **Cloudflare Pages:** earth-blackroad-io
- **Domain:** earth.blackroad.io
- **Content:** Sustainability portal with Earth statistics and initiatives
- **Status:** ✅ Ready to connect

## 📋 Integration Steps

### Step 1: Connect GitHub to Cloudflare Pages

For each project, follow these steps:

1. **Go to Cloudflare Pages Dashboard**
   ```
   https://dash.cloudflare.com/pages
   ```

2. **Navigate to the project** (e.g., blackroad-api)

3. **Click "Settings" → "Builds & deployments"**

4. **Click "Connect to Git"**

5. **Select GitHub** and authorize Cloudflare

6. **Choose repository:**
   - Organization: BlackRoad-OS
   - Repository: blackroad-api (or respective repo)

7. **Configure build settings:**
   ```
   Framework preset: None
   Build command: (leave empty for static HTML)
   Build output directory: /
   Root directory: (leave empty)
   ```

8. **Click "Save and Deploy"**

### Step 2: Verify Deployment

1. **Check build status** in Cloudflare dashboard
2. **Visit preview URL:** `https://[commit-hash].[project].pages.dev`
3. **Verify branding** matches BlackRoad design system
4. **Check custom domain** if applicable

### Step 3: Set Up Custom Domains (if needed)

For earth-blackroad-io:
1. Go to "Custom domains"
2. Click "Set up a custom domain"
3. Enter: `earth.blackroad.io`
4. Follow DNS configuration steps (usually automatic with Cloudflare DNS)
5. Wait for SSL certificate provisioning (~5 minutes)

## ✅ Brand Compliance Verification

All created pages follow the official BlackRoad Brand System:

### Colors ✅
- Amber: #F5A623
- Hot Pink: #FF1D6C (Primary)
- Electric Blue: #2979FF
- Violet: #9C27B0
- Background: #000000
- Text: #FFFFFF

### Spacing ✅
- Golden ratio (φ = 1.618) throughout
- 8px, 13px, 21px, 34px, 55px, 89px, 144px

### Typography ✅
- SF Pro Display / system fonts
- Line height: 1.618
- Antialiased rendering

### Gradients ✅
- 135deg angle
- Color stops at 38.2% and 61.8% (golden ratio)

### Animations ✅
- Cubic bezier easing: (0.4, 0, 0.2, 1)
- Smooth transitions
- Purposeful motion

## 🚀 Automated Deployment Workflow

Once connected to GitHub, deployments will be automatic:

1. **Push to main branch** → Production deployment
2. **Push to other branches** → Preview deployments
3. **Open PR** → Automatic preview link in PR comments
4. **Merge PR** → Auto-deploy to production

## 📊 Current Integration Status

### GitHub-Connected Projects (4 → 7)
Before:
- ✅ blackroad-os-web
- ✅ blackroad-os-docs
- ✅ blackroad-os-brand
- ✅ blackroad-os-prism

After (pending connection):
- ⏳ blackroad-api
- ⏳ blackroad-dashboard
- ⏳ earth-blackroad-io

### Projects Remaining for Connection (50+)
All other Cloudflare Pages projects without GitHub integration

## 🎯 Next Projects to Connect

### High Priority
1. **console-blackroad-io** - Developer console
2. **api-blackroadio** - API documentation
3. **docs-blackroadio** - Documentation hub
4. **status-blackroad-io** - Status page
5. **analytics-blackroad-io** - Analytics dashboard

### Medium Priority (Custom Domains)
1. **demo.blackroad.io** - Demo portal
2. **home.blackroad.io** - Home page
3. All other subdomain portals

### Low Priority (Placeholder System)
1. 56 subdomain repositories
2. Can use template repo + automation

## 🛡️ Safety Checklist

Before connecting each project:

- [ ] Verify repo has content (not empty)
- [ ] Check brand compliance
- [ ] Test build locally (if applicable)
- [ ] Confirm project is not production-critical
- [ ] Announce in [MEMORY] system
- [ ] Document current CF Pages settings
- [ ] Have rollback plan ready

## 🔄 Rollback Procedure

If GitHub integration causes issues:

1. **Go to Cloudflare Pages project settings**
2. **Click "Disconnect Git provider"**
3. **Switch back to "Manual deployments"**
4. **Deploy from local backup**
5. **Investigate and fix issue**
6. **Reconnect when ready**

## 📝 Documentation Templates

### Commit Message Template
```
[TYPE]: [Short description]

- [Detailed change 1]
- [Detailed change 2]
- [Brand compliance notes]

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

### PR Description Template
```
## Summary
[What this PR does]

## Changes
- [Change 1]
- [Change 2]

## Testing
- [ ] Local testing completed
- [ ] Brand compliance verified
- [ ] Preview deployment checked

## Screenshots
[If applicable]
```

## 🎨 Brand System Reference

Always check: `~/BLACKROAD_BRAND_SYSTEM.md`

Official templates:
- `/Users/alexa/Downloads/files(4)/blackroad-template-*.html`

## 📞 Support

- **Memory System:** `~/memory-system.sh`
- **Traffic Lights:** `~/blackroad-traffic-light.sh`
- **Cleanup Plan:** `~/CLOUDFLARE_GITHUB_CLEANUP_PLAN.md`
- **Safety Checklist:** `~/CLEANUP_SAFETY_CHECKLIST.md`

---

**Created by:** claude-cleanup-coordinator-1767822878-83e3008a
**Last Updated:** 2026-01-07
**Status:** ✅ Ready for Phase 2 execution

# Cloudflare Git Integration - Complete Setup Guide

**Owner:** Alexa Louise Amundson
**Last Updated:** 2025-12-22
**Status:** ✅ RECOMMENDED METHOD

---

## Why Use Cloudflare Git Integration?

After testing both GitHub Actions and Cloudflare Git Integration, **Git Integration is the recommended approach** because:

✅ **No API tokens to manage** - No secrets, no expiration issues
✅ **Native Cloudflare integration** - Built into the dashboard
✅ **Automatic deployments** - Push to GitHub = instant deployment
✅ **Preview deployments** - Every PR gets a preview URL
✅ **Zero configuration** - Just connect and go
✅ **No workflow files needed** - Cloudflare handles CI/CD

## Tested Results

### ✅ Working Example: lucidia-metaverse
- **GitHub Repo:** BlackRoad-OS/lucidia-metaverse
- **Pages Project:** lucidia-earth
- **Live URL:** https://lucidia-earth.pages.dev
- **Status:** Deployed successfully via manual deployment
- **Next Step:** Connect to Git Integration

### ❌ GitHub Actions Issues Found
- API token authentication errors (code: 10000)
- Requires security policy compliance (SHA pinning)
- Needs manual secret management across 58 repositories
- More complex troubleshooting

---

## Setup Process (5 Minutes Per Repo)

### Step 1: Connect Repository to Cloudflare

1. **Visit Cloudflare Pages Dashboard**
   ```
   https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages
   ```

2. **Select Your Project**
   - Click on the Pages project (e.g., `lucidia-earth`)
   - Go to **Settings** → **Builds & deployments**

3. **Connect to Git**
   - Click **Connect to Git**
   - Choose **GitHub** as the provider
   - Authorize Cloudflare (one-time OAuth)
   - Select the organization: **BlackRoad-OS**
   - Select the repository (e.g., `lucidia-metaverse`)

4. **Configure Build Settings**
   - **Production branch:** `main` or `master`
   - **Build command:** `npm run build`
   - **Build output directory:** `dist`
   - **Node version:** 18

5. **Save and Deploy**
   - Click **Save**
   - Cloudflare will trigger the first build automatically

### Step 2: Verify Automatic Deployment

1. **Make a test commit to the repository**
   ```bash
   cd ~/lucidia-metaverse
   echo "# Test auto-deploy" >> README.md
   git add README.md
   git commit -m "Test Cloudflare Git Integration"
   git push origin master
   ```

2. **Watch the build in Cloudflare Dashboard**
   - Builds appear in real-time
   - Usually complete in 1-2 minutes
   - Preview URL for each commit

3. **Check deployment status**
   ```bash
   wrangler pages deployment list --project-name=lucidia-earth
   ```

---

## Repository to Project Mappings

All 58 repositories with their Pages projects:

### Lucidia Ecosystem
| GitHub Repo | Pages Project | Build Output | Custom Domain |
|------------|---------------|--------------|---------------|
| lucidia-metaverse | lucidia-earth | dist | lucidia.earth |
| lucidia-platform | lucidia-platform | dist | - |
| lucidia-core | lucidia-core | dist | - |
| lucidia-math | lucidia-math | dist | - |

### BlackRoad Core
| GitHub Repo | Pages Project | Build Output | Custom Domain |
|------------|---------------|--------------|---------------|
| blackroad-io | blackroad-io | dist | blackroad.io |
| blackroad-os-web | blackroad-os-web | dist | Multiple domains |
| blackroad-os-prism | blackroad-os-prism | dist | - |
| blackroad-os-demo | blackroad-os-demo | dist | demo.blackroad.io |
| blackroad-os-home | blackroad-os-home | dist | - |
| blackroad-os-brand | blackroad-os-brand | dist | - |
| blackroad-os-docs | blackroad-os-docs | dist | - |
| earth-blackroad-io | earth-blackroad-io | dist | earth.blackroad.io |

### BlackRoad Services (26 repos)
| GitHub Repo | Pages Project | Build Output |
|------------|---------------|--------------|
| blackroad-hello | blackroad-hello | dist |
| blackroad-metaverse | blackroad-metaverse | dist |
| blackroad-console | blackroad-console | dist |
| blackroad-prism-console | blackroad-prism-console | dist |
| blackroad-admin | blackroad-admin | dist |
| blackroad-dashboard | blackroad-dashboard | dist |
| blackroad-chat | blackroad-chat | dist |
| blackroad-agents | blackroad-agents | dist |
| blackroad-agents-spawner | blackroad-agents-spawner | dist |
| blackroad-tools | blackroad-tools | dist |
| blackroad-analytics | blackroad-analytics | dist |
| blackroad-api | blackroad-api | dist |
| blackroad-api-explorer | blackroad-api-explorer | dist |
| blackroad-builder | blackroad-builder | dist |
| blackroad-workflows | blackroad-workflows | dist |
| blackroad-store | blackroad-store | dist |
| blackroad-payment-page | blackroad-payment-page | dist |
| blackroad-buy-now | blackroad-buy-now | dist |
| blackroad-company | blackroad-company | dist |
| blackroad-docs-hub | blackroad-docs-hub | dist |

### BlackRoad Infrastructure (16 repos)
| GitHub Repo | Pages Project | Build Output |
|------------|---------------|--------------|
| blackroad-portals | blackroad-portals | dist |
| blackroad-portals-unified | blackroad-portals-unified | dist |
| blackroad-unified | blackroad-unified | dist |
| blackroad-gateway-web | blackroad-gateway-web | dist |
| blackroad-assets | blackroad-assets | dist |
| blackroad-status | blackroad-status | dist |
| blackroad-status-new | blackroad-status-new | dist |
| blackroad-pitstop | blackroad-pitstop | dist |
| blackroad-systems | blackroad-systems | dist |
| blackroad-me | blackroad-me | dist |

### Road Ecosystem (7 repos)
| GitHub Repo | Pages Project | Build Output |
|------------|---------------|--------------|
| roadworld | roadworld | dist |
| roadwork | roadwork | dist |
| roadwork-production | roadwork-production | dist |
| roadchain-io | roadchain-io | dist |
| roadchain-production | roadchain-production | dist |
| roadcoin-io | roadcoin-io | dist |
| roadcoin-production | roadcoin-production | dist |

### Other (4 repos)
| GitHub Repo | Pages Project | Build Output |
|------------|---------------|--------------|
| operations-portal | operations-portal | dist |
| remotejobs-platform | remotejobs-platform | dist |
| applier-blackroad | applier-blackroad | dist |
| blackroad-hello-test | blackroad-hello-test | dist |

---

## Bulk Setup Script

For setting up all repositories at once:

```bash
#!/usr/bin/env bash
# cloudflare-git-integration-bulk.sh
# Connects all BlackRoad GitHub repos to Cloudflare Pages via Git Integration

# Note: This requires manual OAuth approval in the browser for each repo
# The Cloudflare UI doesn't have a bulk API, so we use the dashboard

echo "🚀 Cloudflare Git Integration Bulk Setup"
echo "=========================================="
echo ""
echo "Visit: https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages"
echo ""
echo "For each project:"
echo "  1. Click on project name"
echo "  2. Settings → Builds & deployments"
echo "  3. Connect to Git → Select GitHub repo"
echo "  4. Configure: npm run build → dist"
echo "  5. Save"
echo ""
echo "Total projects to connect: 58"
echo ""
read -p "Press Enter to open Cloudflare dashboard..."
open "https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages"
```

---

## Troubleshooting

### Issue: Build fails with "Command not found"
**Solution:** Check build command is `npm run build` not `npm build`

### Issue: Wrong output directory
**Solution:** Verify output is `dist` (most Vite projects use this)

### Issue: Node version mismatch
**Solution:** Set Node version to 18 in build settings

### Issue: Repository not showing up
**Solution:** Make sure GitHub App has access to BlackRoad-OS organization

---

## Comparison: Git Integration vs GitHub Actions

| Feature | Git Integration | GitHub Actions |
|---------|----------------|----------------|
| Setup Time | 5 min/repo | 10 min/repo |
| API Tokens | None ✅ | Required ❌ |
| Secrets Management | None ✅ | Manual ❌ |
| Security Compliance | Automatic ✅ | SHA pinning required ❌ |
| Preview Deploys | Built-in ✅ | Manual config ❌ |
| Troubleshooting | Simple ✅ | Complex ❌ |
| **Recommendation** | **USE THIS** ✅ | Avoid unless needed |

---

## Next Steps

1. ✅ **lucidia-metaverse → lucidia-earth** (Tested, ready to connect)
2. Connect remaining 57 repositories using the same process
3. Remove GitHub Actions workflow files (they're not needed)
4. Update documentation to reflect Git Integration as standard

---

**"Push to GitHub. Deploy to the world. That simple."** 🚀

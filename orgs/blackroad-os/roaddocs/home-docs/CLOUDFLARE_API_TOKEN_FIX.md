# Cloudflare API Token Permission Issue

## Problem Discovered

The Cloudflare API token we're using works for verification but lacks permissions for the Pages API:

```
✅ Token verify: SUCCESS
❌ Pages API: Authentication error
```

## Root Cause

The token `yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy` doesn't have the required permissions for:
- Creating Cloudflare Pages projects
- Managing Pages deployments
- Adding custom domains to Pages

## Solutions

### Option 1: Create New API Token (RECOMMENDED)

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use template: **Edit Cloudflare Pages**
4. Permissions needed:
   - Account > Cloudflare Pages > Edit
   - Zone > DNS > Edit (for custom domains)
   - Account > Account Settings > Read

5. Save the new token and update:
```bash
# Update environment
echo 'export CF_TOKEN="<new-token-here>"' >> ~/.blackroad-deploy-env
source ~/.blackroad-deploy-env
```

### Option 2: Use Wrangler CLI (CURRENT APPROACH)

Wrangler CLI uses OAuth and has full permissions by default.

**Setup:**
```bash
# Install wrangler
npm install -g wrangler

# Login
wrangler login

# Deploy to Pages
wrangler pages deploy <directory> --project-name=<project-name>
```

### Option 3: Manual Dashboard Setup

For now, we'll set up Pages projects manually:

1. Go to https://dash.cloudflare.com/
2. Select account: **BlackRoad OS**
3. Click "Workers & Pages"
4. Click "Create application" → "Pages"
5. Connect to GitHub repository
6. Add custom domain

## Current Status

- ✅ **Deployment scripts created** (ready to use once token is fixed)
- ✅ **GitHub Actions workflows** (ready for repositories)
- ✅ **Testing suite**
- ✅ **Monitoring dashboard**
- ⚠️ **API token** - needs Pages permissions

## Workaround: Wrangler-Based Deployment

I've created scripts that use Wrangler instead of direct API calls. See:
- `~/wrangler-deploy-all.sh` - Deploy all domains via Wrangler
- `~/WRANGLER_DEPLOYMENT_GUIDE.md` - Complete Wrangler guide

## Next Steps

1. **Short-term**: Use Wrangler CLI for deployments (works now!)
2. **Long-term**: Create proper API token with Pages permissions
3. **Alternative**: Use GitHub Actions (no local token needed)

## Files Affected

- `~/deploy-all-domains.py` - Needs new token
- `~/blackroad-autodeploy-system.sh` - Needs new token
- `~/mass-deploy-all-domains.sh` - Needs new token

But these will work once we have the right token!

---

**For immediate deployments, use Wrangler (Option 2 above).**

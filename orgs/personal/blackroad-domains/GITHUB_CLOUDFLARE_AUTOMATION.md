# GitHub to Cloudflare Seamless Deployment Guide

**Owner:** Alexa Louise Amundson
**Last Updated:** 2025-12-22
**Purpose:** Automate all GitHub repos to deploy to Cloudflare Pages on push

---

## 🎯 Overview

This guide sets up **automatic deployment** from GitHub to Cloudflare Pages:
- **Push to GitHub** → **Auto-deploy to Cloudflare Pages**
- **Pull Requests** → **Deploy to preview**
- **Merge to main** → **Deploy to production**

**No manual commands needed. Git push does everything.**

---

## 🚀 Two Methods for Seamless Deployment

### Method 1: Cloudflare Pages Git Integration (Recommended)
**Easiest setup. No code required.**

### Method 2: GitHub Actions with Wrangler
**More control. Customizable workflows.**

---

## 📋 Method 1: Cloudflare Pages Git Integration

### Setup Process

#### Step 1: Connect Repository to Cloudflare Pages

**Via Cloudflare Dashboard:**

1. **Login to Cloudflare Dashboard**
   - Go to https://dash.cloudflare.com
   - Select your account

2. **Navigate to Pages**
   - Click **Workers & Pages** in sidebar
   - Click **Create application**
   - Select **Pages** tab
   - Click **Connect to Git**

3. **Authorize GitHub**
   - Click **Connect GitHub**
   - Authorize Cloudflare Pages app
   - Select organization: `blackboxprogramming` or `BlackRoad-OS`

4. **Select Repository**
   - Choose repository (e.g., `lucidia-metaverse`)
   - Click **Begin setup**

5. **Configure Build Settings**

   **For Next.js/React/Vite projects:**
   ```
   Production branch: main
   Build command: npm run build
   Build output directory: dist (or build, or out)
   Root directory: / (or specific path)
   ```

   **For static sites:**
   ```
   Production branch: main
   Build command: (leave empty)
   Build output directory: / (or public)
   ```

6. **Environment Variables** (if needed)
   - Click **Add variable**
   - Add: `NODE_VERSION = 18`
   - Add any API keys or secrets

7. **Save and Deploy**
   - Click **Save and Deploy**
   - First deployment starts automatically

#### Step 2: Automatic Deployments

**After setup, deployments happen automatically:**

```bash
# Developer workflow
git add .
git commit -m "Update feature"
git push origin main

# Cloudflare automatically:
# 1. Detects push
# 2. Runs build
# 3. Deploys to production
# 4. Updates https://project-name.pages.dev
```

#### Step 3: Preview Deployments

**Pull requests get preview URLs:**

```bash
# Create feature branch
git checkout -b feature/new-ui
# Make changes
git add .
git commit -m "Add new UI"
git push origin feature/new-ui

# Create PR on GitHub
# Cloudflare automatically creates preview:
# https://abc123.project-name.pages.dev
```

### Connected Repositories Configuration

**All 58 Projects - Configuration Table**

| Repository | Pages Project | Build Command | Output Dir | Status |
|------------|---------------|---------------|------------|---------|
| lucidia-metaverse | lucidia-earth | `npm run build` | dist | 🔗 To Connect |
| blackroad-io | blackroad-io | `npm run build` | dist | 🔗 To Connect |
| blackroad-os-web | blackroad-os-web | `npm run build` | dist | ✅ Connected |
| roadworld | roadworld | `npm run build` | dist | 🔗 To Connect |
| blackroad-hello | blackroad-hello | `npm run build` | dist | 🔗 To Connect |
| ... | ... | ... | ... | ... |

**To connect each repository:**
1. Go to Pages → project → Settings → Builds & deployments
2. Click **Connect to Git** (if not connected)
3. Select repository
4. Configure build settings
5. Save

---

## 🔧 Method 2: GitHub Actions with Wrangler

### Universal GitHub Actions Workflow

Create `.github/workflows/deploy.yml` in each repository:

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build project
        run: npm run build

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy dist --project-name=${{ secrets.PAGES_PROJECT_NAME }}
```

### Setup GitHub Secrets

**For each repository:**

1. **Go to Repository Settings**
   - Navigate to repository on GitHub
   - Click **Settings** tab
   - Click **Secrets and variables** → **Actions**

2. **Add Secrets**
   - Click **New repository secret**

   **Add three secrets:**

   **CLOUDFLARE_API_TOKEN**
   ```
   Value: yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy
   ```

   **CLOUDFLARE_ACCOUNT_ID**
   ```
   Value: 463024cf9efed5e7b40c5fbe7938e256
   ```

   **PAGES_PROJECT_NAME**
   ```
   Value: lucidia-earth (or project-specific name)
   ```

### Automated Script to Add Workflows to All Repos

```bash
#!/usr/bin/env bash
# add-github-actions-to-all-repos.sh

REPOS=(
  "lucidia-metaverse:lucidia-earth"
  "blackroad-io:blackroad-io"
  "blackroad-os-web:blackroad-os-web"
  "roadworld:roadworld"
  "blackroad-hello:blackroad-hello"
  # Add all 58 repositories here
)

for repo_config in "${REPOS[@]}"; do
  IFS=':' read -r repo_name project_name <<< "$repo_config"

  echo "Setting up $repo_name → $project_name"

  # Clone or update repo
  if [ -d "$repo_name" ]; then
    cd "$repo_name"
    git pull origin main
  else
    gh repo clone "BlackRoad-OS/$repo_name"
    cd "$repo_name"
  fi

  # Create GitHub Actions workflow
  mkdir -p .github/workflows

  cat > .github/workflows/deploy.yml << EOF
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: \${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: \${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy dist --project-name=$project_name
EOF

  # Commit and push
  git add .github/workflows/deploy.yml
  git commit -m "Add automated Cloudflare Pages deployment"
  git push origin main

  # Set GitHub secrets
  gh secret set CLOUDFLARE_API_TOKEN --body "yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy"
  gh secret set CLOUDFLARE_ACCOUNT_ID --body "463024cf9efed5e7b40c5fbe7938e256"
  gh secret set PAGES_PROJECT_NAME --body "$project_name"

  cd ..
  echo "✅ Completed $repo_name"
done

echo "🎉 All repositories configured for automatic deployment!"
```

**Make it executable:**
```bash
chmod +x add-github-actions-to-all-repos.sh
```

---

## 🌐 Organization-Wide GitHub Secrets (Recommended)

Instead of setting secrets per-repo, set them **organization-wide**.

### Setup Organization Secrets

1. **Go to Organization Settings**
   - Navigate to https://github.com/organizations/BlackRoad-OS/settings/secrets/actions
   - Or: GitHub → Your organizations → BlackRoad-OS → Settings → Secrets and variables → Actions

2. **Add Organization Secrets**
   - Click **New organization secret**

   **CLOUDFLARE_API_TOKEN**
   ```
   Value: yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy
   Repository access: All repositories
   ```

   **CLOUDFLARE_ACCOUNT_ID**
   ```
   Value: 463024cf9efed5e7b40c5fbe7938e256
   Repository access: All repositories
   ```

3. **Set Project-Specific Secret Per Repo**
   - Only `PAGES_PROJECT_NAME` needs to be set per repository

**Benefits:**
- Set secrets once for entire organization
- Automatic access for all repos
- Easy secret rotation

---

## 📦 Complete Repository Configuration Matrix

### All 58 Cloudflare Pages Projects

| # | Repository | Pages Project | Auto-Deploy | Build Cmd | Output |
|---|------------|---------------|-------------|-----------|--------|
| 1 | lucidia-metaverse | lucidia-earth | 🔗 Setup | `npm run build` | dist |
| 2 | blackroad-io | blackroad-io | 🔗 Setup | `npm run build` | dist |
| 3 | blackroad-os-web | blackroad-os-web | ✅ Active | `npm run build` | dist |
| 4 | blackroad-os-prism | blackroad-os-prism | 🔗 Setup | `npm run build` | dist |
| 5 | blackroad-os-demo | blackroad-os-demo | 🔗 Setup | `npm run build` | dist |
| 6 | blackroad-os-home | blackroad-os-home | 🔗 Setup | `npm run build` | dist |
| 7 | blackroad-os-brand | blackroad-os-brand | 🔗 Setup | `npm run build` | dist |
| 8 | earth-blackroad-io | earth-blackroad-io | 🔗 Setup | `npm run build` | dist |
| 9 | roadworld | roadworld | 🔗 Setup | `npm run build` | dist |
| 10 | blackroad-hello | blackroad-hello | 🔗 Setup | `npm run build` | dist |
| ... | ... | ... | ... | ... | ... |
| 58 | (all projects) | (all projects) | 🔗 Setup | varies | varies |

**Legend:**
- ✅ Active - Already connected and deploying
- 🔗 Setup - Needs configuration
- ⚠️ Review - Needs build config check

---

## 🔄 Deployment Workflow Comparison

### Before (Manual):
```bash
# Developer has to:
cd ~/lucidia-metaverse
git pull origin main
npm install
npm run build
wrangler pages deploy dist --project-name=lucidia-earth
```

### After (Automatic):
```bash
# Developer only does:
git push origin main

# Everything else happens automatically on Cloudflare/GitHub
```

**Time saved:** ~5 minutes per deployment × multiple deployments daily = Hours saved weekly

---

## 🎨 Enhanced Workflows

### Multi-Environment Deployment

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main, staging, develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run build

      - name: Deploy to Production
        if: github.ref == 'refs/heads/main'
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy dist --project-name=lucidia-earth --branch=production

      - name: Deploy to Staging
        if: github.ref == 'refs/heads/staging'
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy dist --project-name=lucidia-earth --branch=staging

      - name: Deploy to Development
        if: github.ref == 'refs/heads/develop'
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy dist --project-name=lucidia-earth --branch=develop
```

### With Testing and Linting

```yaml
name: Test, Build, and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run lint
      - run: npm test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run build
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy dist --project-name=lucidia-earth
```

---

## 🚀 Quick Start Guide

### For a Single Repository

**Method 1: Cloudflare Dashboard (5 minutes)**

1. Login to Cloudflare → Pages → Create application → Connect to Git
2. Select repository
3. Configure build: `npm run build`, output: `dist`
4. Save and Deploy
5. Done! Future pushes auto-deploy

**Method 2: GitHub Actions (10 minutes)**

1. Create `.github/workflows/deploy.yml` in your repo
2. Copy the workflow template above
3. Set GitHub secrets (CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, PAGES_PROJECT_NAME)
4. Push to GitHub
5. Done! Future pushes auto-deploy

### For All 58 Repositories

**Option A: Cloudflare Dashboard (Manual but simple)**
- Go through each repository in Cloudflare Pages
- Click "Connect to Git"
- Select repository
- Configure and save
- Repeat 58 times (~2 hours total)

**Option B: Automated Script (Faster)**
```bash
# Run the automation script
./add-github-actions-to-all-repos.sh

# Sits back and watches automation magic
# Completes in ~20 minutes
```

---

## 📊 Monitoring Deployments

### Via Cloudflare Dashboard

1. Go to **Workers & Pages**
2. Click on project name
3. View **Deployments** tab
4. See:
   - Build logs
   - Deployment status
   - Preview URLs
   - Production URL

### Via GitHub Actions

1. Go to repository on GitHub
2. Click **Actions** tab
3. See workflow runs
4. Click run to see logs

### Via Wrangler CLI

```bash
# List recent deployments
wrangler pages deployment list --project-name=lucidia-earth

# Tail deployment logs
wrangler pages deployment tail

# View specific deployment
wrangler pages deployment view <deployment-id> --project-name=lucidia-earth
```

---

## 🔐 Security Best Practices

### API Token Management

**Create a scoped API token:**

1. Go to Cloudflare Dashboard → Profile → API Tokens
2. Click **Create Token**
3. Use template: **Edit Cloudflare Workers**
4. Permissions:
   - Account → Cloudflare Pages → Edit
   - Zone → Zone → Read (if using custom domains)
5. Set token expiration (optional but recommended)
6. Create token and save it securely

**Store in GitHub:**
- Organization secrets (recommended for all repos)
- Repository secrets (for specific repos)
- Never commit tokens to code

### Secret Rotation

**Quarterly rotation recommended:**

```bash
# Update organization secret
gh secret set CLOUDFLARE_API_TOKEN --org BlackRoad-OS --body "new-token-here"

# Or update per repository
gh secret set CLOUDFLARE_API_TOKEN --repo BlackRoad-OS/lucidia-metaverse --body "new-token-here"
```

---

## 🎯 Deployment Checklist

### Initial Setup (One-time)

- [ ] Choose deployment method (Cloudflare Git Integration or GitHub Actions)
- [ ] Set up organization-wide GitHub secrets
- [ ] Configure first repository as template
- [ ] Test deployment workflow
- [ ] Document repository-specific requirements

### Per Repository

- [ ] Create or update `.github/workflows/deploy.yml`
- [ ] Set repository secret `PAGES_PROJECT_NAME`
- [ ] Configure build settings
- [ ] Test with a commit
- [ ] Verify deployment at `https://project-name.pages.dev`
- [ ] Add custom domain (if needed)

### Ongoing Maintenance

- [ ] Monitor deployment success rates
- [ ] Review failed deployments
- [ ] Update Node.js version as needed
- [ ] Rotate API tokens quarterly
- [ ] Update workflow templates

---

## 🌐 Custom Domain Configuration

After automatic deployment is working, add custom domains:

```bash
# Via Cloudflare Dashboard
# Pages → Project → Custom domains → Add domain

# Supported domain mappings:
lucidia-earth.pages.dev → lucidia.earth
blackroad-io.pages.dev → blackroad.io
blackroad-os-web.pages.dev → blackroadqi.com, blackroadquantum.*
```

**DNS automatically configured by Cloudflare when you add custom domain.**

---

## 📈 Benefits Summary

### Automatic Deployment Benefits

✅ **Developer Experience**
- No manual deployment commands
- `git push` does everything
- Faster iteration cycles

✅ **Reliability**
- Consistent builds
- No human error
- Automated testing (if configured)

✅ **Productivity**
- ~5 min saved per deployment
- Multiple deployments per day
- Hours saved weekly across team

✅ **Collaboration**
- Preview URLs for PRs
- Easy code review
- Stakeholder previews

✅ **Rollback**
- One-click rollback in Cloudflare
- Git revert for code rollback
- Deployment history preserved

---

## 🔧 Troubleshooting

### Common Issues

**Build fails:**
```
Check:
- Build command is correct
- Output directory exists
- All dependencies in package.json
- Environment variables set
```

**Deployment succeeds but site broken:**
```
Check:
- Output directory setting
- Base path in build config
- Environment variables
- CORS settings
```

**GitHub Actions not triggering:**
```
Check:
- Workflow file in .github/workflows/
- File has .yml or .yaml extension
- Secrets are set correctly
- Branch name matches workflow trigger
```

### Debug Commands

```bash
# Test build locally
npm run build

# Check output directory
ls -la dist/

# Test with wrangler locally
wrangler pages dev dist

# View deployment logs
wrangler pages deployment tail --project-name=lucidia-earth
```

---

## 📚 Additional Resources

### Documentation
- **Cloudflare Pages Docs:** https://developers.cloudflare.com/pages/
- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Wrangler Docs:** https://developers.cloudflare.com/workers/wrangler/

### Support
- **Cloudflare Community:** https://community.cloudflare.com/
- **GitHub Support:** https://support.github.com/

---

## 🎉 Next Steps

1. **Choose deployment method** (Cloudflare Git or GitHub Actions)
2. **Set up first repository** as proof of concept
3. **Test workflow** with a commit
4. **Roll out to all repositories** using automation script
5. **Monitor and optimize** deployment times

---

**Once configured, you'll never manually deploy again. Every `git push` becomes a production deployment.** 🚀

---

**"Push once, deploy everywhere."** 🛣️

**Generated by:** Claude Code (Cece)
**Last Updated:** 2025-12-22

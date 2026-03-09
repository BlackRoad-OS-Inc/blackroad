# BlackRoad Universal Deployment System

**Never worry about deploying domains again!**

This system provides a single command to deploy ANY domain to Cloudflare with zero DNS configuration headaches.

---

## 🚀 Quick Start

```bash
# Deploy a new Next.js site
~/blackroad-deploy-system.sh docker mysite.blackroad.io ~/projects/mysite

# Done! Your site is live at https://mysite.blackroad.io in ~2 minutes
```

---

## 📋 Commands

### 1. Deploy to Cloudflare Pages (Static Sites)

```bash
~/blackroad-deploy-system.sh pages <domain> <project-dir>
```

**Best for:** Next.js, React, Vue, static HTML
**Pros:** Free CDN, automatic builds, unlimited bandwidth
**Example:**
```bash
~/blackroad-deploy-system.sh pages marketing.blackroad.io ~/projects/marketing-site
```

### 2. Deploy to Docker on aria64 (Dynamic Sites)

```bash
~/blackroad-deploy-system.sh docker <domain> <project-dir>
```

**Best for:** APIs, custom backends, full-stack apps
**Pros:** Full control, any tech stack, runs on your Pi
**Example:**
```bash
~/blackroad-deploy-system.sh docker api.lucidia.earth ~/projects/lucidia-api
```

### 3. Route Existing Port Through Tunnel

```bash
~/blackroad-deploy-system.sh tunnel <domain> <port>
```

**Best for:** Already-running containers, quick routing
**Example:**
```bash
~/blackroad-deploy-system.sh tunnel newdomain.blackroad.io 3060
```

### 4. Check Deployment Status

```bash
~/blackroad-deploy-system.sh status <domain>
```

**Example:**
```bash
~/blackroad-deploy-system.sh status lucidia.earth
```

### 5. List All Deployments

```bash
~/blackroad-deploy-system.sh list
```

Shows all Docker containers, Pages projects, and tunnel routes.

---

## 🎯 How It Works

### Method 1: Cloudflare Pages

```
1. Create/update GitHub repo
2. Deploy to Cloudflare Pages
3. Add custom domain
4. DNS auto-configured
5. SSL auto-provisioned
✅ Live in ~2 minutes!
```

**No manual DNS configuration needed!**

### Method 2: Docker on aria64

```
1. Create/update GitHub repo
2. Clone to aria64
3. Build Docker image
4. Run container on next available port
5. Add to Caddy reverse proxy
6. Route through Cloudflare Tunnel
7. DNS auto-configured via tunnel
✅ Live in ~5 minutes!
```

**Everything automated, including DNS!**

### Method 3: Cloudflare Tunnel

```
1. Add domain to Caddy config
2. Route DNS through tunnel
3. Tunnel auto-creates CNAME
✅ Live in ~30 seconds!
```

**Perfect for quick deployments!**

---

## 🔧 What Gets Automated

### ✅ GitHub
- Creates repository if doesn't exist
- Pushes code automatically
- Manages branches

### ✅ Docker (aria64)
- Finds next available port
- Builds image
- Runs container with restart policy
- Updates Caddy configuration
- Reloads Caddy

### ✅ Cloudflare
- Deploys to Pages (Method 1)
- Configures custom domains
- Routes DNS through tunnel (Method 2 & 3)
- Provisions SSL certificates
- Everything proxied through Cloudflare

### ✅ DNS
- **Zero manual configuration!**
- Tunnel automatically creates CNAMEs
- Pages automatically configures domains
- Cloudflare handles everything

---

## 📊 Current Infrastructure

### aria64 Deployments

| Container | Port | Domain | Method |
|-----------|------|--------|--------|
| lucidia-earth | 3040 | lucidia.earth | Docker |
| blackroad-docs | 3050 | docs.blackroad.io | Docker |
| blackroad.io | 3000 | blackroad.io | Docker |
| +16 more | 3001-3024 | Various | Docker |

### Cloudflare Pages

- **40+ projects** deployed
- Custom domains configured
- Auto-deploys from GitHub

### Available Ports

- **3051-3100**: Available for new deployments
- Automatically assigned by deployment script

---

## 🎬 Real Examples

### Example 1: New Landing Page

```bash
cd ~/projects
npx create-next-app landing-page
cd landing-page

# Deploy to Pages (static, fast)
~/blackroad-deploy-system.sh pages landing.blackroad.io ~/projects/landing-page

# ✅ Live at https://landing.blackroad.io
```

### Example 2: API Server

```bash
cd ~/projects/my-api

# Deploy to Docker (dynamic, full control)
~/blackroad-deploy-system.sh docker api.myapp.io ~/projects/my-api

# ✅ Live at https://api.myapp.io
# Container running on aria64
```

### Example 3: Quick Route

```bash
# You have a container running on port 3070
# Just need to make it public

~/blackroad-deploy-system.sh tunnel experimental.blackroad.io 3070

# ✅ Live at https://experimental.blackroad.io in 30 seconds
```

---

## 🔍 Troubleshooting

### Site not loading after deployment

```bash
# Check status
~/blackroad-deploy-system.sh status yourdomain.com

# Check Docker container
ssh aria64 "docker logs your-container-name"

# Check Caddy
ssh aria64 "docker logs caddy | tail -50"
```

### DNS not resolving

```bash
# Wait 1-2 minutes for propagation
# Then check
dig +short yourdomain.com @1.1.1.1

# Should show Cloudflare IPs (104.x.x.x or 172.x.x.x)
```

### Container crashed

```bash
# Restart it
ssh aria64 "docker restart container-name"

# Or redeploy
~/blackroad-deploy-system.sh docker yourdomain.com ~/projects/yourproject
```

---

## 🛠 Under the Hood

### Technologies Used

- **Cloudflare Pages**: Static site hosting
- **Cloudflare Tunnel**: Secure routing without port forwarding
- **Docker**: Containerization
- **Caddy**: Reverse proxy with auto-HTTPS
- **GitHub**: Code hosting
- **Wrangler**: Cloudflare CLI
- **cloudflared**: Tunnel CLI

### Why This Works

1. **Cloudflare Tunnel** creates CNAMEs automatically (no DNS API needed!)
2. **OAuth token** has Pages & Tunnel permissions (sufficient!)
3. **Caddy** handles local routing on aria64
4. **Everything proxied** through Cloudflare (free SSL, DDoS protection)

### No DNS API Token Required!

Unlike traditional deployment systems that need DNS write permissions, this system uses:
- Cloudflare Tunnel for Docker deployments (auto-creates DNS)
- Cloudflare Pages for static sites (auto-configures custom domains)
- **Result**: No manual DNS configuration ever!

---

## 📝 Adding to PATH

Make the script globally available:

```bash
# Add to your shell profile
echo 'export PATH="$HOME:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Now use from anywhere
blackroad-deploy-system.sh list
```

Or create an alias:

```bash
echo 'alias deploy="~/blackroad-deploy-system.sh"' >> ~/.zshrc
source ~/.zshrc

# Now just use
deploy docker api.myapp.io ~/projects/myapp
```

---

## 🎓 Best Practices

### When to use Pages vs Docker

**Use Pages when:**
- Static site (Next.js, React, Vue)
- Don't need server-side logic
- Want fastest possible load times
- Want automatic GitHub integration

**Use Docker when:**
- Need server-side processing
- Custom backend logic
- Database connections
- WebSockets
- Full control over environment

### Port Organization

- **3000-3031**: Existing sites (don't touch)
- **3040-3049**: Lucidia ecosystem
- **3050-3059**: Documentation sites
- **3060-3099**: New projects
- **8000+**: Special services (LLM, etc.)

### Domain Strategy

- **main.blackroad.io**: Main application
- **subdomain.blackroad.io**: Features/services
- **separate.domain**: Major products

---

## 🚀 What's Next

### Potential Enhancements

1. **Auto-scaling**: Detect high traffic and spin up replicas
2. **Health checks**: Auto-restart failed containers
3. **Backups**: Automatic container image backups
4. **Monitoring**: Integrate with status dashboard
5. **CI/CD**: Auto-deploy on git push

### Already Working

- ✅ Zero-config DNS
- ✅ Automatic SSL
- ✅ Container management
- ✅ Port allocation
- ✅ GitHub integration
- ✅ Cloudflare integration
- ✅ Status checking
- ✅ Deployment listing

---

## 📞 Support

Issues? Check:

1. **Script output**: Detailed error messages
2. **Container logs**: `docker logs container-name`
3. **Caddy logs**: `docker logs caddy`
4. **DNS**: `dig +short domain @1.1.1.1`
5. **Status**: `~/blackroad-deploy-system.sh status domain`

---

**You now have a production-grade deployment system that works with ANY domain, requires ZERO DNS configuration, and deploys in minutes!** 🎉

Never worry about deploying again. Just run the script and your site goes live.

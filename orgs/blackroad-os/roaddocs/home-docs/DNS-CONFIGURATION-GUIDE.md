# BlackRoad OS DNS Configuration Guide

**Purpose:** Configure Cloudflare DNS to route traffic to Railway and Cloudflare Workers
**Date:** 2025-12-14
**Status:** Ready for configuration

---

## 🎯 Overview

BlackRoad OS uses a **subdomain-oriented architecture** where:
- **Each service = one subdomain**
- **DNS is the router**
- **Cloudflare provides edge layer**
- **Railway provides compute layer**

---

## 📋 Service Mapping

| Service | Subdomain | Platform | Status |
|---------|-----------|----------|--------|
| API | api.blackroad.io | Cloudflare Workers | ✅ LIVE |
| Web | www.blackroad.io | Railway | 🔄 Deploying |
| Console | app.blackroad.io | Railway | 🔄 Deploying |
| Agents | agents.blackroad.io | Railway | 🔄 Deploying |
| Operator | ops.blackroad.io | Railway | 🔄 Deploying |

---

## 🔧 Cloudflare DNS Configuration

### Step 1: Get Railway Deployment URLs

Once Railway deployments complete, get the URLs from:

```bash
# Option 1: Railway Dashboard
https://railway.app/dashboard

# Option 2: Railway CLI (if token is valid)
cd /path/to/repo
railway status

# Option 3: GitHub Actions logs
https://github.com/BlackRoad-OS/{repo}/actions
```

Railway provides URLs in format:
```
{service}-production.up.railway.app
```

### Step 2: Configure DNS Records in Cloudflare

Navigate to: https://dash.cloudflare.com → Select blackroad.io → DNS

Add the following CNAME records:

#### API (Already Configured)
```
Type: CNAME
Name: api
Target: api.blackroad.io.workers.dev
Proxy: ✅ Proxied (Orange cloud)
TTL: Auto
```

#### Web Portal
```
Type: CNAME
Name: www
Target: blackroad-os-web-production.up.railway.app
Proxy: ✅ Proxied (Orange cloud)
TTL: Auto
```

#### Prism Console
```
Type: CNAME
Name: app
Target: blackroad-os-prism-console-production.up.railway.app
Proxy: ✅ Proxied (Orange cloud)
TTL: Auto
```

#### Agents API
```
Type: CNAME
Name: agents
Target: blackroad-os-agents-production.up.railway.app
Proxy: ✅ Proxied (Orange cloud)
TTL: Auto
```

#### Operator Service
```
Type: CNAME
Name: ops
Target: blackroad-os-operator-production.up.railway.app
Proxy: ✅ Proxied (Orange cloud)
TTL: Auto
```

---

## 🔐 SSL/TLS Configuration

### Cloudflare SSL Settings

Navigate to: SSL/TLS → Overview

**Recommended Settings:**
- **Encryption Mode:** Full (strict)
- **Always Use HTTPS:** ✅ On
- **Minimum TLS Version:** TLS 1.2
- **Automatic HTTPS Rewrites:** ✅ On
- **Certificate Transparency Monitoring:** ✅ On

### Edge Certificates

Cloudflare automatically provisions SSL certificates for:
- *.blackroad.io (wildcard)
- blackroad.io (apex)

**Certificate Validity:** Auto-renewed
**No action required** - Cloudflare handles this automatically

---

## 🌐 Apex Domain Configuration

### Option 1: Redirect to www (Recommended)

Create a Page Rule:
```
URL: blackroad.io/*
Setting: Forwarding URL (301 Permanent Redirect)
Destination: https://www.blackroad.io/$1
```

### Option 2: Direct Railway Mapping

```
Type: CNAME (flattened)
Name: @
Target: blackroad-os-web-production.up.railway.app
Proxy: ✅ Proxied
```

---

## ⚡ Performance Optimization

### Cloudflare Page Rules

Navigate to: Rules → Page Rules

**Rule 1: Static Assets Caching**
```
URL: *.blackroad.io/_next/static/*
Settings:
  - Cache Level: Cache Everything
  - Edge Cache TTL: 1 month
  - Browser Cache TTL: 1 month
```

**Rule 2: API Caching (Conservative)**
```
URL: api.blackroad.io/*
Settings:
  - Cache Level: Bypass (or Cache by status code)
  - Browser Cache TTL: Respect Existing Headers
```

**Rule 3: Health Endpoints**
```
URL: *.blackroad.io/health
Settings:
  - Cache Level: Bypass
  - Always Online: Off
```

### Cloudflare Workers Routes

Navigate to: Workers & Pages → Overview

**Existing Routes:**
- `api.blackroad.io/*` → blackroad-api (Cloudflare Worker)

**No additional routes needed** - Railway services handle their own routing

---

## 🚀 Railway Custom Domain Configuration

### For Each Service

In Railway dashboard, navigate to each service:

1. Click service → Settings → Domains
2. Add custom domain:
   - www.blackroad.io (for web)
   - app.blackroad.io (for console)
   - agents.blackroad.io (for agents)
   - ops.blackroad.io (for operator)
3. Railway provides CNAME target
4. Add CNAME record in Cloudflare (see Step 2 above)
5. Wait for DNS propagation (1-5 minutes)
6. Railway auto-provisions SSL certificate

### Verification

Railway shows ✅ when:
- DNS record is correct
- SSL certificate is provisioned
- Service is accessible

---

## 📊 DNS Propagation & Testing

### Check DNS Propagation

```bash
# Check CNAME records
dig www.blackroad.io CNAME
dig app.blackroad.io CNAME
dig agents.blackroad.io CNAME
dig ops.blackroad.io CNAME

# Check with specific DNS server
dig @1.1.1.1 www.blackroad.io

# Check from multiple locations
https://www.whatsmydns.net/#CNAME/www.blackroad.io
```

### Test Service Availability

```bash
# API (Cloudflare Workers)
curl -I https://api.blackroad.io/health

# Web Portal (Railway)
curl -I https://www.blackroad.io/health

# Prism Console (Railway)
curl -I https://app.blackroad.io/health

# Agents API (Railway)
curl -I https://agents.blackroad.io/health

# Operator Service (Railway)
curl -I https://ops.blackroad.io/health
```

**Expected Response:**
```
HTTP/2 200
content-type: application/json
```

---

## 🔍 Troubleshooting

### Issue: DNS Not Resolving

**Check:**
1. CNAME record exists in Cloudflare
2. CNAME target is correct (from Railway)
3. Cloudflare proxy is enabled (orange cloud)
4. Wait 5 minutes for propagation

**Fix:**
```bash
# Flush local DNS cache
# macOS:
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Linux:
sudo systemd-resolve --flush-caches

# Windows:
ipconfig /flushdns
```

### Issue: SSL Certificate Error

**Check:**
1. Cloudflare SSL mode is "Full (strict)"
2. Railway has provisioned SSL certificate
3. Custom domain is added in Railway dashboard

**Fix:**
- Wait 5-10 minutes for certificate provisioning
- Check Railway service logs for SSL errors
- Verify Cloudflare SSL settings

### Issue: 502 Bad Gateway

**Possible Causes:**
1. Railway service is down
2. Railway service hasn't started yet
3. Health check endpoint doesn't exist

**Fix:**
```bash
# Check Railway service status
railway status

# Check service logs
railway logs

# Restart service
railway up
```

### Issue: Slow Response Times

**Check:**
1. Railway service region (should be US)
2. Cloudflare caching settings
3. Railway service performance metrics

**Fix:**
- Enable Cloudflare caching for static assets
- Optimize service startup time
- Consider Railway Pro plan for better performance

---

## 📈 Monitoring DNS & SSL

### Cloudflare Analytics

View real-time traffic:
```
Cloudflare Dashboard → Analytics & Logs
```

**Key Metrics:**
- Requests per second
- Bandwidth usage
- Cache hit ratio
- SSL/TLS version distribution

### Cloudflare Health Checks

Navigate to: Traffic → Health Checks

Create health checks for:
```
Name: BlackRoad API
URL: https://api.blackroad.io/health
Interval: 60 seconds
Notification: Email on failure

Name: BlackRoad Web
URL: https://www.blackroad.io/health
Interval: 60 seconds
Notification: Email on failure
```

---

## 🔄 Automated DNS Updates

### Using Cloudflare API

```bash
# Set environment variables
CLOUDFLARE_API_TOKEN="your-token"
CLOUDFLARE_ZONE_ID="d6566eba4500b460ffec6650d3b4baf6"

# Update CNAME record
curl -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/{record_id}" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "www",
    "content": "new-railway-url.up.railway.app",
    "proxied": true
  }'
```

### GitHub Actions Integration

Add to deployment workflow:
```yaml
- name: Update Cloudflare DNS
  env:
    CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
  run: |
    RAILWAY_URL=$(railway status --json | jq -r '.deployments[0].url')
    # Update Cloudflare CNAME to point to Railway URL
    # (API call as shown above)
```

---

## 📝 DNS Record Summary

Once configured, your DNS should look like:

```
blackroad.io
├── @ (apex)          → 301 redirect to www.blackroad.io
├── www               → CNAME blackroad-os-web-production.up.railway.app
├── api               → CNAME api.blackroad.io.workers.dev (Cloudflare Worker)
├── app               → CNAME blackroad-os-prism-console-production.up.railway.app
├── agents            → CNAME blackroad-os-agents-production.up.railway.app
└── ops               → CNAME blackroad-os-operator-production.up.railway.app
```

**All records proxied through Cloudflare (orange cloud) ✅**

---

## ✅ Verification Checklist

After DNS configuration:

- [ ] All CNAME records created in Cloudflare
- [ ] All records proxied (orange cloud)
- [ ] SSL/TLS mode set to "Full (strict)"
- [ ] Custom domains added in Railway
- [ ] Railway SSL certificates provisioned
- [ ] DNS propagation complete (5-10 minutes)
- [ ] All health checks returning 200 OK
- [ ] Status page accessible at www.blackroad.io/status.html
- [ ] Cloudflare analytics showing traffic
- [ ] No SSL certificate errors

---

## 🎯 Next Steps

1. **Wait for Railway deployments** to complete
2. **Get Railway URLs** from dashboard or CLI
3. **Add CNAME records** in Cloudflare
4. **Add custom domains** in Railway
5. **Wait for DNS propagation** (5-10 minutes)
6. **Test all endpoints** with curl
7. **Monitor** Cloudflare analytics and Railway logs
8. **Document** final URLs in service inventory

---

**Status:** Ready to configure once Railway deployments complete
**Estimated Time:** 15-20 minutes for complete DNS setup
**Downtime:** Zero (new services, no existing traffic)

---

*🌐 DNS Configuration Guide for BlackRoad OS*

*Generated with [Claude Code](https://claude.com/claude-code)*

*Co-Authored-By: Claude <noreply@anthropic.com>*

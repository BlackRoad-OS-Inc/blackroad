# DNS Update Guide for BlackRoad Sites

**Target Server:** aria64 at `192.168.4.64`

---

## Quick Summary

Update these DNS records in Cloudflare to make your sites live:

| Domain | Type | Name | Content | Proxy | TTL |
|--------|------|------|---------|-------|-----|
| **lucidia.earth** | A | @ | 192.168.4.64 | ✅ ON | Auto |
| **lucidia.earth** | A | www | 192.168.4.64 | ✅ ON | Auto |
| **blackroad.io** | A | docs | 192.168.4.64 | ✅ ON | Auto |

---

## Option 1: Cloudflare Dashboard (Easiest)

### For lucidia.earth

1. Go to https://dash.cloudflare.com
2. Select the **lucidia.earth** zone
3. Click **DNS** in the left sidebar
4. Click **Add record**

**Record 1 (Root domain):**
- Type: `A`
- Name: `@`
- IPv4 address: `192.168.4.64`
- Proxy status: **Proxied** (orange cloud ON)
- TTL: Auto
- Click **Save**

**Record 2 (www subdomain):**
- Type: `A`
- Name: `www`
- IPv4 address: `192.168.4.64`
- Proxy status: **Proxied** (orange cloud ON)
- TTL: Auto
- Click **Save**

### For docs.blackroad.io

1. Go to https://dash.cloudflare.com
2. Select the **blackroad.io** zone
3. Click **DNS** in the left sidebar
4. Click **Add record**

**Record (docs subdomain):**
- Type: `A`
- Name: `docs`
- IPv4 address: `192.168.4.64`
- Proxy status: **Proxied** (orange cloud ON)
- TTL: Auto
- Click **Save**

---

## Option 2: Cloudflare API (Command Line)

If you have a valid API token with DNS edit permissions, use these commands:

### Setup

```bash
export CF_API_TOKEN="your_api_token_here"
export CF_ZONE_LUCIDIA="your_lucidia_zone_id"
export CF_ZONE_BLACKROAD="your_blackroad_zone_id"
```

### Update lucidia.earth

```bash
# Create/update @ record
curl -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_LUCIDIA/dns_records" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"type":"A","name":"@","content":"192.168.4.64","ttl":1,"proxied":true}'

# Create/update www record
curl -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_LUCIDIA/dns_records" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"type":"A","name":"www","content":"192.168.4.64","ttl":1,"proxied":true}'
```

### Update docs.blackroad.io

```bash
# Create/update docs record
curl -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_BLACKROAD/dns_records" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"type":"A","name":"docs","content":"192.168.4.64","ttl":1,"proxied":true}'
```

---

## Option 3: Cloudflare CLI (wrangler)

```bash
# Install wrangler if needed
npm install -g wrangler

# Login
wrangler login

# Add DNS records
wrangler dns add lucidia.earth @ A 192.168.4.64 --proxied
wrangler dns add lucidia.earth www A 192.168.4.64 --proxied
wrangler dns add blackroad.io docs A 192.168.4.64 --proxied
```

---

## Verification

After updating DNS, verify propagation:

### Check DNS Resolution

```bash
# Check lucidia.earth
dig +short lucidia.earth @1.1.1.1
dig +short www.lucidia.earth @1.1.1.1

# Check docs.blackroad.io
dig +short docs.blackroad.io @1.1.1.1
```

You should see Cloudflare IPs (104.x.x.x or 172.x.x.x) if proxied.

### Test HTTP Response

```bash
# Test lucidia.earth
curl -I https://lucidia.earth

# Test docs.blackroad.io
curl -I https://docs.blackroad.io
```

You should get `HTTP/1.1 200 OK` responses.

---

## What Happens After DNS Update

### Immediate (0-5 minutes)
- DNS records are updated in Cloudflare
- Cloudflare starts routing traffic to 192.168.4.64

### DNS Propagation (5-30 minutes)
- Global DNS servers update their caches
- Some users might still see old IPs during this period

### Fully Propagated (30 minutes - 48 hours)
- All DNS servers worldwide have the new records
- Everyone sees the new sites

---

## Current Setup Verification

Before updating DNS, verify your servers are ready:

### Check aria64 Containers

```bash
ssh aria64 "docker ps | grep -E 'lucidia|blackroad-docs'"
```

Expected output:
```
lucidia-earth     0.0.0.0:3040->3000/tcp
blackroad-docs    0.0.0.0:3050->3000/tcp
```

### Check Local Access

```bash
# Test lucidia.earth locally
ssh aria64 "curl -I http://localhost:3040"

# Test docs.blackroad.io locally
ssh aria64 "curl -I http://localhost:3050"
```

Both should return `HTTP/1.1 200 OK`.

### Check Caddy Configuration

```bash
ssh aria64 "docker exec caddy cat /etc/caddy/Caddyfile | grep -E 'lucidia|docs.blackroad'"
```

Expected output:
```
lucidia.earth, www.lucidia.earth {
    reverse_proxy localhost:3040
}

docs.blackroad.io {
    reverse_proxy localhost:3050
}
```

---

## Troubleshooting

### DNS Not Resolving

**Problem:** `dig` shows no results or old IPs

**Solutions:**
1. Clear local DNS cache: `sudo dscacheutil -flushcache` (macOS)
2. Wait 5-10 minutes for propagation
3. Check Cloudflare dashboard to verify records were saved
4. Use `dig @1.1.1.1` to query Cloudflare DNS directly

### Site Not Loading

**Problem:** DNS resolves but site doesn't load

**Solutions:**
1. Check if container is running: `ssh aria64 "docker ps | grep lucidia"`
2. Check container logs: `ssh aria64 "docker logs lucidia-earth"`
3. Test local port: `ssh aria64 "curl -I http://localhost:3040"`
4. Check Caddy logs: `ssh aria64 "docker logs caddy | tail -50"`
5. Reload Caddy: `ssh aria64 "docker exec caddy caddy reload --config /etc/caddy/Caddyfile"`

### SSL/HTTPS Issues

**Problem:** Certificate errors or not using HTTPS

**Solutions:**
1. Ensure Cloudflare proxy is **ON** (orange cloud)
2. Cloudflare handles SSL automatically when proxied
3. Caddy will get Let's Encrypt cert for direct access
4. Wait a few minutes for certificates to provision

### 502 Bad Gateway

**Problem:** Cloudflare shows 502 error

**Solutions:**
1. Container might be crashed: `docker restart lucidia-earth`
2. Port mapping issue: Check `docker ps` output
3. Caddy config issue: Verify `/etc/caddy/Caddyfile`
4. Firewall blocking port 80/443 on aria64

---

## Post-Update Checklist

After DNS is updated and propagated:

- [ ] Visit https://lucidia.earth in browser
- [ ] Visit https://www.lucidia.earth (should redirect or show same content)
- [ ] Visit https://docs.blackroad.io in browser
- [ ] Test on mobile device
- [ ] Check page load speed
- [ ] Verify SSL certificate is valid
- [ ] Test all internal links
- [ ] Check navigation and scroll
- [ ] Verify search works (docs site)
- [ ] Test dark mode (both sites)

---

## Quick Access Links

Once DNS is live:

- **Lucidia:** https://lucidia.earth
- **Docs:** https://docs.blackroad.io
- **Main Site:** https://blackroad.io

---

## Need Help?

If you encounter issues:

1. **Check Status**: All containers running? `docker ps`
2. **Check Logs**: Any errors? `docker logs [container]`
3. **Check DNS**: Propagated? `dig +short domain @1.1.1.1`
4. **Check Caddy**: Config correct? `docker exec caddy cat /etc/caddy/Caddyfile`

**Both sites are ready and waiting for DNS! 🚀**

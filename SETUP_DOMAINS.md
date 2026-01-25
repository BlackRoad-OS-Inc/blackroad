# 🌐 Quick Domain Setup Guide

**Goal:** Set up pitstop.blackroad.io and universe.blackroad.io

---

## ⚡ FAST SETUP (5 minutes each)

### Step 1: Setup pitstop.blackroad.io

1. **Open:** https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages
2. **Click:** `blackroad-pitstop` project
3. **Click:** `Custom domains` tab
4. **Click:** `Set up a custom domain` button
5. **Enter:** `pitstop.blackroad.io`
6. **Click:** `Continue`
7. **Wait:** ~2 minutes for DNS + SSL ✅

### Step 2: Setup universe.blackroad.io

1. **Stay in:** https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages
2. **Click:** `blackroad-metaverse` project
3. **Click:** `Custom domains` tab
4. **Click:** `Set up a custom domain` button
5. **Enter:** `universe.blackroad.io`
6. **Click:** `Continue`
7. **Wait:** ~2 minutes for DNS + SSL ✅

---

## ✅ Verify Setup

### Test pitstop.blackroad.io
```bash
# Wait 2-3 minutes, then:
curl -I https://pitstop.blackroad.io

# Should return: HTTP/2 200
```

Open in browser: https://pitstop.blackroad.io
- ✅ Should show beautiful login page
- ✅ Green padlock (SSL valid)
- ✅ Login with: alexa / blackroad2025

### Test universe.blackroad.io
```bash
# Wait 2-3 minutes, then:
curl -I https://universe.blackroad.io

# Should return: HTTP/2 200
```

Open in browser: https://universe.blackroad.io
- ✅ Should show metaverse loading screen
- ✅ Green padlock (SSL valid)
- ✅ 18 systems loading animation

---

## 🎯 What Cloudflare Does Automatically

When you add a custom domain, Cloudflare automatically:

1. **Creates DNS Record:**
   ```
   Type: CNAME
   Name: pitstop (or universe)
   Target: blackroad-pitstop.pages.dev
   Proxy: ✅ Enabled (orange cloud)
   ```

2. **Provisions SSL Certificate:**
   - Free Let's Encrypt certificate
   - Auto-renewal every 90 days
   - Takes 1-2 minutes

3. **Configures Edge:**
   - Global CDN distribution
   - HTTPS enforcement
   - HTTP/2 and HTTP/3 support

---

## 📊 Expected Result

After setup (2-5 minutes):

| Domain | Points To | Status |
|--------|-----------|--------|
| pitstop.blackroad.io | blackroad-pitstop.pages.dev | ✅ LIVE |
| universe.blackroad.io | blackroad-metaverse.pages.dev | ✅ LIVE |

---

## 🔐 Current Live URLs

### Before Custom Domain:
- Pitstop: https://9b04dc61.blackroad-pitstop.pages.dev
- Universe: https://16e54ddf.blackroad-metaverse.pages.dev

### After Custom Domain (YOU ARE HERE):
- Pitstop: https://pitstop.blackroad.io 🎯
- Universe: https://universe.blackroad.io 🎯

---

## 🐛 Troubleshooting

### "Too many redirects"
- SSL/TLS mode should be "Full (strict)"
- Fix: Cloudflare Dashboard → SSL/TLS → Overview → Set to "Full (strict)"

### "DNS_PROBE_FINISHED_NXDOMAIN"
- Wait 5 more minutes for DNS propagation
- Clear browser cache: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)

### "Certificate error"
- Wait 2-3 minutes for SSL provisioning
- If persists: Remove domain and re-add

---

## ✨ THAT'S IT!

Total time: **5 minutes** (mostly waiting for DNS/SSL)

Once done:
- ✅ pitstop.blackroad.io → Login portal
- ✅ universe.blackroad.io → Metaverse

---

**BlackRoad OS, Inc.**
© 2025 • Built with 💚

# 🌐 Custom Domain Setup: universe.blackroad.io

**Goal:** Point `universe.blackroad.io` to the BlackRoad Metaverse deployment on Cloudflare Pages

---

## 📋 Prerequisites

- Cloudflare account with access to `blackroad.io` zone
- BlackRoad Metaverse deployed to Cloudflare Pages (✅ **DONE**)
- Current deployment: https://16e54ddf.blackroad-metaverse.pages.dev

---

## 🚀 Setup Steps

### Step 1: Access Cloudflare Pages Dashboard

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Workers & Pages** from the left sidebar
3. Click on **blackroad-metaverse** project

### Step 2: Add Custom Domain

1. In the project dashboard, click the **Custom domains** tab
2. Click **Set up a custom domain**
3. Enter: `universe.blackroad.io`
4. Click **Continue**

### Step 3: DNS Configuration (Automatic)

Cloudflare will automatically:
- Create a CNAME record in your `blackroad.io` DNS zone
- Point `universe.blackroad.io` to `blackroad-metaverse.pages.dev`
- Enable proxying (orange cloud) for security and caching

The DNS record will look like:
```
Type: CNAME
Name: universe
Content: blackroad-metaverse.pages.dev
Proxy: Proxied (orange cloud)
```

### Step 4: Verify & Wait

1. DNS propagation takes 1-5 minutes (usually instant with Cloudflare)
2. Cloudflare will automatically provision an SSL certificate (free)
3. You'll see a green checkmark when the domain is active

### Step 5: Test

Visit: https://universe.blackroad.io

You should see the BlackRoad Metaverse loading screen! 🌌

---

## 🔧 Manual DNS Setup (If Needed)

If automatic setup doesn't work, manually add the DNS record:

1. Go to **DNS** section in Cloudflare Dashboard
2. Select the `blackroad.io` zone
3. Click **Add record**
4. Fill in:
   - **Type:** CNAME
   - **Name:** universe
   - **Target:** blackroad-metaverse.pages.dev
   - **Proxy status:** Proxied (orange cloud)
   - **TTL:** Auto
5. Click **Save**

---

## ✅ Verification

Once set up, verify everything works:

### DNS Check
```bash
dig universe.blackroad.io
# Should return Cloudflare IP addresses
```

### HTTPS Check
```bash
curl -I https://universe.blackroad.io
# Should return 200 OK with valid SSL
```

### Browser Check
Open https://universe.blackroad.io and verify:
- ✅ SSL certificate is valid (green padlock)
- ✅ Loading screen appears
- ✅ 18 systems load successfully
- ✅ Can enter the universe

---

## 🌐 All BlackRoad Domains

After setup, the metaverse will be accessible at:

| Domain | Purpose | Status |
|--------|---------|--------|
| **universe.blackroad.io** | Primary custom domain | 🔜 Pending setup |
| master.blackroad-metaverse.pages.dev | Master branch deployment | ✅ Live |
| 16e54ddf.blackroad-metaverse.pages.dev | Latest deployment | ✅ Live |
| 652eeedd.blackroad-metaverse.pages.dev | Previous deployment | ✅ Live |

---

## 🎯 Post-Setup Tasks

After domain is live:

### 1. Update Documentation
Update these files with the new URL:
- [ ] README.md
- [ ] STATUS.md
- [ ] DEPLOYMENT.md
- [ ] COMPLETE_UNIVERSE.md

### 2. Update HTML Meta Tags
Add to `universe.html` and `index.html`:
```html
<meta property="og:url" content="https://universe.blackroad.io">
<link rel="canonical" href="https://universe.blackroad.io">
```

### 3. Configure Redirects (Optional)
In Cloudflare Pages settings, add redirect rules:
```toml
# _redirects file
/metaverse    https://universe.blackroad.io   302
/universe     https://universe.blackroad.io   302
```

### 4. Analytics & Monitoring
- [ ] Add Cloudflare Web Analytics
- [ ] Set up uptime monitoring
- [ ] Configure performance alerts

---

## 🔒 Security & Performance

### SSL/TLS Settings
Recommended Cloudflare settings:
- **SSL/TLS encryption mode:** Full (strict)
- **Minimum TLS version:** TLS 1.2
- **Automatic HTTPS Rewrites:** ON
- **Always Use HTTPS:** ON

### Caching
- **Browser cache TTL:** 4 hours
- **Edge cache TTL:** Respect existing headers
- **Cache level:** Standard

### Security Headers
Add via Cloudflare Transform Rules or in HTML:
```html
<meta http-equiv="Content-Security-Policy" content="default-src 'self' https: data: blob: 'unsafe-inline' 'unsafe-eval'">
<meta http-equiv="X-Content-Type-Options" content="nosniff">
<meta http-equiv="X-Frame-Options" content="SAMEORIGIN">
```

---

## 📊 Expected Timeline

| Step | Time |
|------|------|
| Add custom domain in dashboard | 2 minutes |
| DNS propagation | 1-5 minutes |
| SSL certificate provisioning | 1-2 minutes |
| **Total** | **5-10 minutes** |

---

## 🐛 Troubleshooting

### Issue: "Too many redirects"
**Solution:**
- Check SSL/TLS mode is "Full (strict)"
- Verify no redirect loops in Pages settings

### Issue: "DNS_PROBE_FINISHED_NXDOMAIN"
**Solution:**
- Wait 5 minutes for DNS propagation
- Clear browser DNS cache
- Try: `ipconfig /flushdns` (Windows) or `sudo dscacheutil -flushcache` (Mac)

### Issue: "Certificate error"
**Solution:**
- Wait 2-3 minutes for SSL provisioning
- If persists, remove and re-add the custom domain

### Issue: "404 Not Found"
**Solution:**
- Verify Pages deployment is successful
- Check that `pages_build_output_dir = "."` is set in wrangler.toml
- Redeploy if needed: `wrangler pages deploy . --project-name=blackroad-metaverse`

---

## 🎉 Success Criteria

You'll know everything is working when:

1. ✅ `https://universe.blackroad.io` loads without errors
2. ✅ SSL certificate shows as valid (green padlock)
3. ✅ Loading screen displays all 18 systems
4. ✅ Can click "Enter Universe" and see 3D world
5. ✅ All controls work (WASD, mouse, etc.)
6. ✅ No console errors in browser DevTools

---

## 📞 Support

If you encounter issues:
- **Cloudflare Support:** https://dash.cloudflare.com/?to=/:account/support
- **Email:** blackroad.systems@gmail.com
- **Check deployment logs:** `wrangler pages deployments list --project-name=blackroad-metaverse`

---

## 🔄 Future Domains (Planned)

- `earth.blackroad.io` - Earth simulation
- `app.blackroad.io` - Main application
- `api.blackroad.io` - Backend API
- `docs.blackroad.io` - Documentation
- `portal.blackroad.io` - Login portal

---

**Built with 💚 by Alexa & Claude**

**Last Updated:** December 22, 2025

🌐 **GET UNIVERSE.BLACKROAD.IO LIVE!** 🌐

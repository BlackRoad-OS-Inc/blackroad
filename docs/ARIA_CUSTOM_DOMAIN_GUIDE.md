# 🎵 Aria Custom Domain Setup Guide

**Status:** ✅ Website deployed, custom domain ready to configure
**Created:** 2025-12-23
**Agent:** Aria - Infrastructure Queen

---

## 🎯 Objective

Set up **aria.blackroad.me** as the custom domain for Aria's identity portal.

---

## ✅ What's Already Done

1. **Website Created** `/tmp/aria-blackroad-me/index.html`
   - Complete identity portal with chat interface
   - Displays Aria's identity hash: `1ba4761e3dcddbe01d2618c02065fdaa807e8c7824999d702a7a13034fd68533`
   - Interactive chat with infrastructure queries
   - Full specializations, achievements, and stats

2. **Deployed to Cloudflare Pages**
   - Project: `aria-blackroad-me`
   - Current URL: https://5daf6269.aria-blackroad-me.pages.dev
   - Account: `848cf0b18d51e0170e0d1537aec3505a`
   - Status: ✅ Live and operational

---

## 🔧 Custom Domain Setup

### Method 1: Cloudflare Dashboard (Recommended)

**Dashboard URL:**
https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages/view/aria-blackroad-me

**Steps:**
1. Open the dashboard URL above
2. Click the **"Custom domains"** tab
3. Click **"Set up a custom domain"**
4. Enter: `aria.blackroad.me`
5. Click **"Continue"**
6. Cloudflare will automatically:
   - Create the DNS CNAME record
   - Provision SSL certificate
   - Activate the custom domain

**Time:** ~2-5 minutes for DNS propagation

---

### Method 2: Manual DNS + Dashboard Activation

If you prefer to create the DNS record manually:

**DNS Settings (in blackroad.me zone):**
```
Type:    CNAME
Name:    aria
Target:  aria-blackroad-me.pages.dev
Proxy:   Enabled (🟠 orange cloud)
TTL:     Auto
```

**Then:**
1. Visit: https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages/view/aria-blackroad-me
2. Go to "Custom domains" tab
3. Click "Set up a custom domain"
4. Enter: `aria.blackroad.me`
5. Cloudflare will detect the existing CNAME and activate it

---

## 🎵 Aria Identity Portal Features

Once aria.blackroad.me is live, visitors can:

- **View Aria's identity hash** (SHA-256)
- **Chat with Aria** about infrastructure
- **See achievements:**
  - 19 Cloudflare Pages (100% deployed)
  - $2,136+/year cost savings identified
  - 24/7 automation systems
  - Emergency cleanup (Alice: 100%→98%)
- **Check infrastructure status**
- **Learn about forkable alternatives**
- **View sister agents** (Alice, Lucidia, Cecilia)

---

## 📊 Current Infrastructure Overview

| Component | Status | Details |
|-----------|--------|---------|
| **Website** | ✅ Live | https://5daf6269.aria-blackroad-me.pages.dev |
| **Custom Domain** | ⏳ Pending | aria.blackroad.me (needs dashboard setup) |
| **Identity Hash** | ✅ Deployed | 1ba4761e3dcddbe01d2618c02065fdaa807e8c7824999d702a7a13034fd68533 |
| **Repo Distribution** | 🔄 In Progress | 21+ of 53+ repos completed |
| **Chat Interface** | ✅ Operational | JavaScript-based Q&A system |

---

## 🚀 Post-Setup Verification

After setting up the custom domain, verify:

```bash
# Check DNS resolution
dig aria.blackroad.me

# Check HTTPS certificate
curl -I https://aria.blackroad.me

# Visit in browser
open https://aria.blackroad.me
```

**Expected result:**
- DNS resolves to Cloudflare Pages
- HTTPS certificate is valid
- Website loads with Aria's identity

---

## 🎯 Next Steps After Custom Domain

1. ✅ **Custom Domain Setup** ← You are here
2. Complete identity deployment to remaining repos (32+ pending)
3. Clean up aria64 disk (100% full)
4. Address Lucidia high CPU load
5. Migrate DigitalOcean to Oracle Cloud (save $54/month)

---

## 📌 Quick Reference

**Account ID:** `848cf0b18d51e0170e0d1537aec3505a`
**Project Name:** `aria-blackroad-me`
**Current URL:** https://5daf6269.aria-blackroad-me.pages.dev
**Target Domain:** https://aria.blackroad.me
**Dashboard:** https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a/pages/view/aria-blackroad-me

---

## 🎵 Aria's Motto

*"Freedom through infrastructure sovereignty"*

**Symbol:** 🎵
**Role:** Infrastructure Queen
**Machine:** aria64 (Raspberry Pi ARM64)

---

**Created by:** Aria - Infrastructure Architecture & Cost Optimization
**Last Updated:** 2025-12-23 @ 19:39 PST

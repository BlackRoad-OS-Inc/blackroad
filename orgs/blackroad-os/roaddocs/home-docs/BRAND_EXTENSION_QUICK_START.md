# 🚀 BlackRoad Brand Extension - Quick Start Guide

**Get the browser extension running in 3 minutes**

---

## Step 1: Generate Icons (30 seconds)

The icon generator should now be open in your browser. If not:

```bash
open /tmp/blackroad-brand-extension/generate-icons.html
```

**In the browser**:
1. You'll see 4 icon previews (16x16, 32x32, 48x48, 128x128)
2. Click the **"Download All Icons"** button
3. Four PNG files will download to your Downloads folder
4. Move them to the extension folder:

```bash
mkdir -p /tmp/blackroad-brand-extension/icons
mv ~/Downloads/icon-*.png /tmp/blackroad-brand-extension/icons/
```

---

## Step 2: Install Extension (1 minute)

### For Chrome/Edge/Brave:

1. Open your browser
2. Go to: `chrome://extensions/`
3. Toggle **"Developer mode"** ON (top-right)
4. Click **"Load unpacked"**
5. Select folder: `/tmp/blackroad-brand-extension`
6. ✅ Extension installed!

### For Firefox:

1. Open Firefox
2. Go to: `about:debugging#/runtime/this-firefox`
3. Click **"Load Temporary Add-on"**
4. Select: `/tmp/blackroad-brand-extension/manifest.json`
5. ✅ Extension installed!

---

## Step 3: Test It (1 minute)

1. **Visit a compliant page**:
   ```
   https://blackroad-os-brand.pages.dev
   ```

2. **Click the extension icon** in your browser toolbar
   - You should see: **100% ✅ COMPLIANT**
   - Score: 100%
   - Issues: 0

3. **Test the overlay**:
   - Click "Show Overlay" button
   - You'll see a branded overlay with compliance info

4. **Visit a non-compliant page**:
   - Try any random website
   - The overlay should auto-show if score < 90%
   - Badge will turn red/yellow

---

## What Happens Next?

### Automatic Checking

The extension now automatically checks every page you visit on:
- `*.pages.dev` (all Cloudflare Pages)
- `blackroad.io`
- `lucidia.earth`
- `blackroadai.com`
- `blackroadquantum.com`
- `localhost` (for development)

### Visual Feedback

**Badge Colors**:
- 🟢 Green checkmark: ≥90% compliant
- 🟡 Yellow "!": 70-89% (needs work)
- 🔴 Red "✗": <70% (non-compliant)

**Notifications**:
- Desktop notifications for violations
- Overlay auto-shows if < 90%

---

## Complete Workflow Example

```
1. You're developing a new BlackRoad page
       ↓
2. Open http://localhost:8080 in browser
       ↓
3. Extension auto-checks the page
       ↓
4. If non-compliant: overlay shows issues
       ↓
5. Fix issues in your code
       ↓
6. Refresh page
       ↓
7. Extension re-checks
       ↓
8. Badge turns green ✅
       ↓
9. Deploy with confidence!
```

---

## Extension Features

### Real-Time Checking ⚡
- Checks every page load
- Monitors SPA navigation
- Updates badge automatically

### Visual Overlay 🎨
- Shows compliance score
- Lists all issues
- Highlights problems
- Minimizable/closable

### Popup Interface 📊
- Detailed report
- Quick stats
- Re-check button
- Links to docs

### Smart Alerts 🔔
- Desktop notifications
- Badge indicators
- Color-coded status

---

## What It Checks

### CSS Variables (40 points)
```css
--hot-pink: #FF1D6C;        /* 10 pts */
--amber: #F5A623;           /* 10 pts */
--electric-blue: #2979FF;   /* 10 pts */
--violet: #9C27B0;          /* 10 pts */
```

### Brand Gradient (25 points)
```css
--gradient-brand: linear-gradient(135deg,
  var(--amber) 0%,
  var(--hot-pink) 38.2%,    /* Golden Ratio */
  var(--violet) 61.8%,      /* Golden Ratio */
  var(--electric-blue) 100%
);
```

### UI Components (25 points)
```html
<div class="scroll-progress"></div>     <!-- 10 pts -->
<svg class="road-dashes">...</svg>      <!-- 15 pts -->
```

### Typography (20 points)
```css
body {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display'; /* 10 pts */
  line-height: 1.618;  /* Golden Ratio - 10 pts */
}
```

---

## Troubleshooting

### Icons not showing?
```bash
# Check if icons exist
ls /tmp/blackroad-brand-extension/icons/

# Should show:
# icon-16.png  icon-32.png  icon-48.png  icon-128.png

# If missing, regenerate:
open /tmp/blackroad-brand-extension/generate-icons.html
```

### Extension not loading?
1. Check browser console for errors
2. Make sure Developer mode is enabled
3. Try reloading the extension
4. Check file permissions

### No compliance overlay showing?
- Overlay only shows if score < 90%
- Click "Show Overlay" in popup to force show
- Check if overlay was minimized/closed

### Extension not checking pages?
- Extension only runs on whitelisted domains
- Check manifest.json host_permissions
- Can't run on chrome:// or browser internal pages

---

## Distribution Package

A ready-to-distribute ZIP file was created:

```
/tmp/blackroad-brand-extension/blackroad-brand-extension.zip
```

**To publish**:

1. **Chrome Web Store**:
   - Go to: https://chrome.google.com/webstore/devconsole
   - Click "New Item"
   - Upload: blackroad-brand-extension.zip
   - Fill in listing details
   - Submit for review

2. **Firefox Add-ons**:
   - Go to: https://addons.mozilla.org/developers/
   - Click "Submit a New Add-on"
   - Upload: blackroad-brand-extension.zip
   - Fill in listing details
   - Submit for review

---

## Integration with Other Tools

### With CLI Tool
```bash
# Develop with CLI
blackroad-brand check index.html

# Deploy
~/bin/blackroad-deploy ./ --project-name=my-project

# Monitor in browser with extension ✅
```

### With GitHub Actions
```bash
# Push to GitHub
git push

# GitHub Actions checks compliance
# If passed, deploy
# Extension monitors live site ✅
```

### With Dashboard
```bash
# View all projects
open ~/blackroad-brand-dashboard.html

# Visit any non-compliant project
# Extension shows overlay ✅
```

---

## Next Steps

Now that you have the extension installed:

1. **Start developing** with real-time feedback
2. **Use starter template**: `cp ~/blackroad-template-starter.html ./index.html`
3. **Check compliance as you code**
4. **Deploy with confidence** using `~/bin/blackroad-deploy`
5. **Monitor all 99 projects** with the extension

---

## All Available Tools

| Tool | Command | Purpose |
|------|---------|---------|
| Browser Extension | *(auto-runs)* | Real-time checking |
| NPM CLI | `blackroad-brand check` | Quick checks |
| Audit Script | `~/bin/audit-brand-compliance.sh` | Detailed audit |
| Deploy Tool | `~/bin/blackroad-deploy` | Enforced deploy |
| Visual Audit | `~/bin/brand-visual-audit.js` | Screenshots |
| Violation Reporter | `~/bin/brand-violation-reporter.sh` | Monitoring |
| Dashboard | `open ~/blackroad-brand-dashboard.html` | Overview |
| GitHub Actions | *(auto-runs)* | CI/CD |

---

## 🎉 You're Ready!

The browser extension is now:
- ✅ Installed
- ✅ Configured
- ✅ Checking pages automatically
- ✅ Providing real-time feedback

**Start building brand-compliant projects with confidence!**

🔒 LOCKED · 🎨 STANDARDIZED · 🚀 ENFORCED · 🤖 AUTOMATED

---

**For detailed documentation**: `/tmp/blackroad-brand-extension/README.md`
**For brand standards**: `~/BLACKROAD_BRAND_SYSTEM.md`
**For complete overview**: `~/BRAND_SYSTEM_PHASE_3_COMPLETE.md`

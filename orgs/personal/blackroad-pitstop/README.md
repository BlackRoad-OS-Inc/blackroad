# 🔐 BlackRoad Pitstop

**Secure Authentication Portal for BlackRoad OS Systems**

**Live:** https://pitstop.blackroad.io (pending setup)

---

## 🎯 What is Pitstop?

Pitstop is the **secure gateway** to all BlackRoad OS metaverse files and systems. It provides:

- 🔐 **Authentication** - Login required to access any files
- 📁 **File Management** - Browse and access all metaverse files
- 🌌 **System Access** - Launch universe, view code, read docs
- 👤 **Session Management** - Secure 24-hour sessions
- 🎨 **Beautiful UI** - Modern glass morphism design

---

## 🚀 Features

### Authentication System
- Username/password login
- Session management (24-hour expiry)
- Secure logout
- Auto-redirect on session expiry

### Dashboard
- **File Grid** - Visual cards for all metaverse files
- **Stats Overview** - Total files, systems, code lines, deployments
- **Quick Access** - One-click to open any file
- **Live Badges** - Shows file status (LIVE, SYSTEM, DOCS, etc.)

### Security
- Client-side session storage
- No backend required (static hosting)
- Protected file access
- Automatic session validation

---

## 🔑 Default Credentials

For demo/testing purposes:

```
Username: alexa
Password: blackroad2025

Username: admin
Password: blackroad2025
```

**⚠️ IMPORTANT:** Change these credentials in `index.html` before production deployment!

---

## 📁 File Structure

```
blackroad-pitstop/
├── index.html           # Login page with authentication
├── dashboard.html       # File dashboard (protected)
├── wrangler.toml        # Cloudflare Pages config
├── package.json         # Project metadata
├── README.md            # This file
└── .gitignore           # Git ignore rules
```

---

## 🛠️ Setup & Deployment

### Deploy to Cloudflare Pages

```bash
cd /Users/alexa/blackroad-pitstop
wrangler pages deploy . --project-name=blackroad-pitstop
```

### Custom Domain Setup

1. Go to Cloudflare Dashboard → Pages → blackroad-pitstop
2. Click "Custom domains" → "Set up a custom domain"
3. Enter: `pitstop.blackroad.io`
4. DNS auto-configured by Cloudflare

---

## 🔐 Security Configuration

### Changing Login Credentials

Edit `index.html` around line 250:

```javascript
const VALID_CREDENTIALS = {
    'yourusername': 'yourpassword',
    'admin': 'strongpassword123'
};
```

### Session Duration

Edit `index.html` around line 257:

```javascript
const SESSION_DURATION = 24 * 60 * 60 * 1000; // 24 hours
```

---

## 🌐 Integration with Metaverse

All BlackRoad OS systems accessible through authenticated dashboard:

- universe.blackroad.io - Complete metaverse
- earth.blackroad.io - Earth simulation
- app.blackroad.io - Main application
- api.blackroad.io - Backend API

---

## 📊 Statistics

- **Total Files:** 32
- **Systems:** 18
- **Code Lines:** 14K+
- **Deployments:** 3

---

## 📞 Support

**BlackRoad OS, Inc.**
- Email: blackroad.systems@gmail.com
- Primary: blackroad@gmail.com

---

## 📜 License

© 2025 BlackRoad OS, Inc. All rights reserved.

---

**Built with 💚 by BlackRoad OS, Inc.**

**December 22, 2025**

🔐 **SECURE ACCESS TO THE METAVERSE** 🔐

---

## 📜 License & Copyright

**Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.**

**CEO:** Alexa Amundson | **PROPRIETARY AND CONFIDENTIAL**

This software is NOT for commercial resale. Testing purposes only.

### 🏢 Enterprise Scale:
- 30,000 AI Agents
- 30,000 Human Employees
- CEO: Alexa Amundson

**Contact:** blackroad.systems@gmail.com

See [LICENSE](LICENSE) for complete terms.

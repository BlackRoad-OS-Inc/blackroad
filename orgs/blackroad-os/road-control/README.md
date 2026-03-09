# 🖤🛣️ BlackRoad Control Panel

## ⚡️ INFRASTRUCTURE REVOLUTION ALERT ⚡️

**!!!!!!!!!!!!!!!!!!!!!! WE ARE MOVING AWAY FROM CLOUDFLARE FOR DEPLOYMENTS !!!!!!!!!!!!!!!!!!!!!!**

Beautiful web UI for managing the BlackRoad Domain Registry. Domain dashboard, DNS record editor, deployment manager, and infrastructure analytics all in one place.

---

## 🚀 What This Is

Single-page web application (HTML + CSS + JavaScript) that provides a graphical interface for all BlackRoad Domain Registry operations. Uses the BlackRoad design system with Amber, Hot Pink, Electric Blue, and Violet color scheme.

### **Features:**

- ✅ **Domain Dashboard** - View all domains with beautiful cards
- ✅ **DNS Record Editor** - Add, edit, delete DNS records
- ✅ **Deployment Manager** - Trigger and monitor deployments
- ✅ **SSL Certificate Status** - Track Let's Encrypt certificates
- ✅ **Infrastructure Analytics** - Pi cluster health monitoring
- ✅ **BlackRoad Design System** - Amber (#F5A623), Hot Pink (#FF1D6C), Electric Blue (#2979FF), Violet (#9C27B0)
- ✅ **Responsive Design** - Works on desktop, tablet, mobile
- ✅ **Real-time Updates** - Auto-refreshing status indicators

---

## 📊 Current Status

**Status:** Built and ready for deployment to alice Pi

**Target Environment:**
- **Host:** alice (192.168.4.49)
- **Port:** 8083
- **API:** road-registry-api (lucidia:8090)
- **Deploy API:** road-deploy (alice:9001)

---

## 🏗️ Architecture

```
┌──────────────────────────────────────┐
│   road-control (Web UI)              │
│   HTML + CSS + JS                    │
│   Port 8083                          │
└──────────────────────────────────────┘
           ↓             ↓
    road-registry-api  road-deploy
    (lucidia:8090)     (alice:9001)
```

---

## 🎨 Screenshots

### **Domain Dashboard**
```
┌─────────────────────────────────────────────────────────────┐
│ 🖤🛣️ BlackRoad Domain Registry                            │
│ Your Infrastructure. Your Rules.                            │
│                                                             │
│ ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│ │ Domains  │  │ Records  │  │ Deploy   │  │ Analytics│  │
│ │    5     │  │    29    │  │    12    │  │    4 Pis │  │
│ └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                                                             │
│ [Domains] [DNS Records] [Deployments] [Analytics]          │
│                                                             │
│ ┌───────────────────────────────────────────────────────┐ │
│ │ blackroad.io                                   [View] │ │
│ │ Registrar: GoDaddy | Status: active            [DNS ] │ │
│ │ ns1.blackroad.io, ns2.blackroad.io           [Deploy]│ │
│ └───────────────────────────────────────────────────────┘ │
│ ┌───────────────────────────────────────────────────────┐ │
│ │ lucidia.earth                                  [View] │ │
│ │ Registrar: Self-managed | Status: active       [DNS ] │ │
│ │ ns1.blackroad.io, ns2.blackroad.io           [Deploy]│ │
│ └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Files

```
road-control/
├── public/
│   ├── index.html       # Main UI (250 lines)
│   ├── css/
│   │   └── style.css    # BlackRoad design system (350 lines)
│   └── js/
│       └── app.js       # API client + UI logic (400 lines)
└── README.md            # This file
```

---

## 🚀 Quick Start

### **Option 1: Python HTTP Server**

```bash
cd ~/road-control/public
python3 -m http.server 8083
```

### **Option 2: Node.js HTTP Server**

```bash
npm install -g http-server
cd ~/road-control/public
http-server -p 8083
```

### **Option 3: nginx (Production)**

```bash
# Copy to nginx web root
sudo cp -r ~/road-control/public/* /var/www/road-control/

# Create nginx config
sudo cat > /etc/nginx/sites-available/road-control << 'EOF'
server {
    listen 8083;
    server_name alice alice.local 192.168.4.49;

    root /var/www/road-control;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy (optional - if running on same host)
    location /api/ {
        proxy_pass http://lucidia:8090/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
EOF

# Enable and reload
sudo ln -s /etc/nginx/sites-available/road-control /etc/nginx/sites-enabled/
sudo nginx -t
sudo nginx -s reload
```

### **Deployment to Alice Pi:**

```bash
# 1. Copy files to alice
scp -r ~/road-control pi@alice:~/

# 2. SSH into alice
ssh pi@alice

# 3. Install nginx (if not installed)
sudo apt install -y nginx

# 4. Copy to web root
sudo mkdir -p /var/www/road-control
sudo cp -r ~/road-control/public/* /var/www/road-control/
sudo chown -R www-data:www-data /var/www/road-control

# 5. Create nginx config
sudo nano /etc/nginx/sites-available/road-control
# (paste config from above)

# 6. Enable and start
sudo ln -s /etc/nginx/sites-available/road-control /etc/nginx/sites-enabled/
sudo nginx -t
sudo nginx -s reload

# 7. Access
# http://alice:8083
# http://192.168.4.49:8083
```

---

## 🔧 Configuration

### **API Endpoints**

Edit `public/js/app.js`:

```javascript
const API_BASE = 'http://lucidia:8090/api';  // road-registry-api
const DEPLOY_API = 'http://alice:9001/api';  // road-deploy
```

### **Update Frequency**

Edit `public/js/app.js`:

```javascript
// Auto-refresh every 30 seconds
setInterval(() => {
    loadTabData(currentTab);
}, 30000);
```

---

## 🎨 BlackRoad Design System

### **Colors:**

```css
:root {
    --amber: #F5A623;        /* Primary accent */
    --hot-pink: #FF1D6C;     /* Secondary accent */
    --electric-blue: #2979FF; /* Tertiary accent */
    --violet: #9C27B0;       /* Quaternary accent */
    --black: #000000;        /* Background */
    --white: #FFFFFF;        /* Text */
    --gray-900: #111111;     /* Card backgrounds */
    --gray-800: #1a1a1a;     /* Sections */
    --gray-700: #2a2a2a;     /* Borders */
    --gray-600: #3a3a3a;     /* Hover states */
}
```

### **Typography:**

```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
```

### **Gradients:**

```css
.gradient-text {
    background: linear-gradient(90deg,
        var(--amber),
        var(--hot-pink),
        var(--electric-blue),
        var(--violet)
    );
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}
```

---

## 📱 Features

### **1. Domain Dashboard**

- View all registered domains
- Domain cards with status indicators
- Quick actions: View, Edit DNS, Deploy
- Add new domain modal

### **2. DNS Record Editor**

- List all DNS records across domains
- Add A, AAAA, CNAME, MX, TXT records
- Edit TTL values
- Delete records with confirmation

### **3. Deployment Manager**

- Trigger new deployments
- View deployment history
- Monitor deployment status
- Rollback functionality

### **4. Analytics Dashboard**

- Pi cluster health status (alice, lucidia, aria, octavia)
- Domain count, record count, deployment count
- Infrastructure overview
- Network topology diagram

---

## 🔐 Security

### **No Authentication (Local Network Only)**

This UI is designed for use on local network (192.168.4.0/24). Configure firewall to restrict access:

```bash
# Allow access from local network only
sudo ufw allow from 192.168.4.0/24 to any port 8083
```

### **Future: Add Authentication**

For public access, add authentication:
- Basic Auth via nginx
- OAuth2 Proxy
- Keycloak integration

---

## 🌐 Usage

### **Access the Control Panel:**

```
http://alice:8083
http://alice.local:8083
http://192.168.4.49:8083
```

### **Add a Domain:**

1. Click "Add Domain" button
2. Enter domain name (e.g., `example.com`)
3. Select registrar
4. Enter nameservers (comma-separated)
5. Click "Add Domain"

### **Manage DNS Records:**

1. Click "DNS Records" tab
2. Click "Add Record" button
3. Select domain and record type
4. Enter name and value
5. Click "Add Record"

### **Deploy a Website:**

1. Click "Deployments" tab
2. Click "New Deployment" button
3. Select domain
4. Enter GitHub repo URL
5. Enter branch and build command
6. Click "Deploy"

---

## 🌐 Integration

### **Works With:**

- **road-registry-api** - Fetches domains, records, deployments
- **road-deploy** - Triggers deployments
- **PowerDNS** - Displays DNS status

### **API Calls:**

```javascript
// Get all domains
GET http://lucidia:8090/api/domains

// Add domain
POST http://lucidia:8090/api/domains

// Add DNS record
POST http://lucidia:8090/api/domains/:domain/records

// Trigger deployment
POST http://alice:9001/api/deploy
```

---

## 🖤🛣️ The Vision

**Part of the BlackRoad Domain Registry ecosystem:**

```
                          ┌─────────────────┐
                          │  road-control   │
                          │  (This Web UI)  │
                          └─────────────────┘
                              ↓         ↓
                    ┌──────────────┐  ┌──────────────┐
                    │ road-registry│  │ road-deploy  │
                    │     -api     │  │              │
                    └──────────────┘  └──────────────┘
                           ↓                 ↓
                    ┌──────────────┐  ┌──────────────┐
                    │   PowerDNS   │  │  nginx+aria  │
                    │  (lucidia)   │  │  (websites)  │
                    └──────────────┘  └──────────────┘
```

**Beautiful UI → Powerful APIs → Total Control**

**Total independence. Total control. Total sovereignty.**

---

## 📚 Related Repos

- [road-dns-deploy](https://github.com/BlackRoad-OS/road-dns-deploy) - PowerDNS deployment
- [road-registry-api](https://github.com/BlackRoad-OS/road-registry-api) - Domain management API
- [road-deploy](https://github.com/BlackRoad-OS/road-deploy) - Deployment engine

---

## 📞 Support

- **Email:** blackroad.systems@gmail.com
- **GitHub Issues:** [BlackRoad-OS/road-control/issues](https://github.com/BlackRoad-OS/road-control/issues)

---

**Built with 🖤 by BlackRoad OS, Inc.**

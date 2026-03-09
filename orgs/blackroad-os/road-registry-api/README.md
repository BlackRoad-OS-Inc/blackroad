# 🖤🛣️ BlackRoad Domain Registry API

## ⚡️ INFRASTRUCTURE REVOLUTION ALERT ⚡️

**!!!!!!!!!!!!!!!!!!!!!! WE ARE MOVING AWAY FROM CLOUDFLARE FOR DEPLOYMENTS !!!!!!!!!!!!!!!!!!!!!!**

REST API for managing domains, DNS records, and deployments in the BlackRoad self-hosted infrastructure.

---

## 🚀 What This Is

Node.js + Express + PostgreSQL API server that provides programmatic access to the BlackRoad Domain Registry. Integrates with PowerDNS for DNS management and tracks deployment status.

### **Features:**

- ✅ **Domain CRUD Operations** - Add, list, update, delete domains
- ✅ **DNS Record Management** - Create and manage A, NS, SOA, CNAME, MX records
- ✅ **PowerDNS Integration** - Automatically syncs zones with PowerDNS
- ✅ **Deployment Tracking** - Monitor deployment status and history
- ✅ **SSL Certificate Management** - Track Let's Encrypt certificates
- ✅ **RESTful API** - Clean JSON API design

---

## 📊 Current Status

**Status:** Built and ready for deployment to lucidia Pi

**Target Environment:**
- **Host:** lucidia (192.168.4.38)
- **Port:** 8080
- **Database:** PostgreSQL (road_registry)
- **Integration:** PowerDNS API (localhost:9053)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│ road-registry-api (Port 8080)           │
│  ├─ Express REST API                    │
│  ├─ PostgreSQL Client (road_registry)  │
│  └─ PowerDNS API Client (port 9053)    │
└─────────────────────────────────────────┘
         ↓                    ↓
    PostgreSQL           PowerDNS API
   (road_registry)      (localhost:9053)
```

---

## 📦 API Endpoints

### **Health Check**
```bash
GET /health
```

### **Domains**
```bash
# List all domains
GET /api/domains

# Get single domain
GET /api/domains/:domain

# Add new domain
POST /api/domains
{
  "domain": "example.com",
  "registrar": "GoDaddy",
  "nameservers": ["ns1.blackroad.io", "ns2.blackroad.io"],
  "records": [
    {"type": "A", "name": "@", "value": "192.168.4.82"}
  ]
}

# Update domain
PUT /api/domains/:domain

# Delete domain
DELETE /api/domains/:domain
```

### **DNS Records**
```bash
# List records for domain
GET /api/domains/:domain/records

# Add DNS record
POST /api/domains/:domain/records
{
  "type": "A",
  "name": "www",
  "value": "192.168.4.82",
  "ttl": 3600
}

# Delete DNS record
DELETE /api/records/:id
```

### **Deployments**
```bash
# List all deployments
GET /api/deployments

# Create new deployment
POST /api/deployments
{
  "domain": "example.com",
  "repo_url": "https://github.com/user/repo",
  "branch": "main",
  "deploy_path": "dist"
}

# Get deployment status
GET /api/deployments/:id
```

### **PowerDNS Sync**
```bash
# Sync all zones to PowerDNS
POST /api/sync/powerdns
```

---

## 🚀 Quick Start

### **Prerequisites:**
- Node.js 18+
- PostgreSQL 15+
- PowerDNS running on localhost:9053

### **Installation:**

```bash
# 1. Clone repo
git clone https://github.com/BlackRoad-OS/road-registry-api.git
cd road-registry-api

# 2. Install dependencies
npm install

# 3. Configure environment
cat > .env << EOF
PORT=8080
DATABASE_URL=postgresql://postgres:password@localhost:5432/road_registry
PDNS_API_URL=http://localhost:9053
PDNS_API_KEY=blackroad-pdns-api-key-2026
EOF

# 4. Initialize database
psql -U postgres -c "CREATE DATABASE road_registry;"
psql -U postgres -d road_registry < schema.sql

# 5. Start server
npm start
```

### **Deployment to Lucidia Pi:**

```bash
# 1. Copy files to lucidia
scp -r ~/road-registry-api pi@lucidia:~/

# 2. SSH into lucidia
ssh pi@lucidia

# 3. Install dependencies
cd ~/road-registry-api
npm install

# 4. Create database
psql -U postgres -c "CREATE DATABASE road_registry;"
psql -U postgres -d road_registry < schema.sql

# 5. Configure environment
cat > .env << EOF
PORT=8080
DATABASE_URL=postgresql://pdns:blackroad-dns-2026@localhost:5432/road_registry
PDNS_API_URL=http://localhost:9053
PDNS_API_KEY=blackroad-pdns-api-key-2026
EOF

# 6. Install PM2 (process manager)
sudo npm install -g pm2

# 7. Start with PM2
pm2 start server.js --name road-registry-api
pm2 save
pm2 startup
```

---

## 🔧 Usage Examples

### **Add a Domain**

```bash
curl -X POST http://lucidia:8080/api/domains \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "blackroad.io",
    "registrar": "GoDaddy",
    "nameservers": ["ns1.blackroad.io", "ns2.blackroad.io"],
    "records": [
      {"type": "A", "name": "@", "value": "192.168.4.82"},
      {"type": "A", "name": "www", "value": "192.168.4.82"}
    ]
  }'
```

### **List All Domains**

```bash
curl http://lucidia:8080/api/domains
```

### **Add DNS Record**

```bash
curl -X POST http://lucidia:8080/api/domains/blackroad.io/records \
  -H "Content-Type: application/json" \
  -d '{
    "type": "A",
    "name": "api",
    "value": "192.168.4.38",
    "ttl": 3600
  }'
```

### **Track Deployment**

```bash
curl -X POST http://lucidia:8080/api/deployments \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "blackroad.io",
    "repo_url": "https://github.com/BlackRoad-OS/blackroad-os-landing",
    "branch": "main",
    "status": "in_progress"
  }'
```

---

## 🗂️ Files

- **server.js** - Express API server (275 lines)
- **schema.sql** - PostgreSQL database schema
- **package.json** - Node.js dependencies
- **.env** - Environment configuration
- **README.md** - This file

---

## 🗄️ Database Schema

```sql
-- Domains table
CREATE TABLE domains (
  id UUID PRIMARY KEY,
  domain VARCHAR(255) UNIQUE NOT NULL,
  registrar VARCHAR(100),
  nameservers TEXT[],
  status VARCHAR(50) DEFAULT 'active',
  owner_email VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DNS Records table
CREATE TABLE dns_records (
  id UUID PRIMARY KEY,
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  record_type VARCHAR(10) NOT NULL,
  name VARCHAR(255) NOT NULL,
  value TEXT NOT NULL,
  ttl INTEGER DEFAULT 3600,
  priority INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Deployments table
CREATE TABLE deployments (
  id UUID PRIMARY KEY,
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  repo_url TEXT NOT NULL,
  branch VARCHAR(100) DEFAULT 'main',
  commit_sha VARCHAR(40),
  status VARCHAR(50) DEFAULT 'pending',
  deployed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- SSL Certificates table
CREATE TABLE ssl_certificates (
  id UUID PRIMARY KEY,
  domain_id UUID REFERENCES domains(id) ON DELETE CASCADE,
  provider VARCHAR(50) DEFAULT 'letsencrypt',
  issued_at TIMESTAMP,
  expires_at TIMESTAMP,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🔐 Security

### **Environment Variables:**
- `DATABASE_URL` - PostgreSQL connection string
- `PDNS_API_KEY` - PowerDNS API authentication
- `PORT` - API server port (default: 8080)

### **Firewall:**
```bash
# Allow API access from local network only
sudo ufw allow from 192.168.4.0/24 to any port 8080
```

---

## 📊 Monitoring

### **Health Check:**
```bash
curl http://lucidia:8080/health
```

### **PM2 Status:**
```bash
pm2 status
pm2 logs road-registry-api
pm2 monit
```

---

## 🌐 Integration with Other Components

### **PowerDNS**
- Automatically creates zones in PowerDNS when domains are added
- Syncs DNS records to PowerDNS database
- API endpoint: `/api/sync/powerdns`

### **road-deploy (Deployment Engine)**
- Tracks deployment status in database
- Updates deployment records via API
- Webhook support for automated deployments

### **road-control (Web UI)**
- Provides web interface for API endpoints
- Domain dashboard, DNS editor, deployment manager
- Calls this API for all operations

---

## 🖤🛣️ The Vision

**Part of the BlackRoad Domain Registry ecosystem:**

```
GitHub → [road-dns-deploy] → [road-registry-api] → [road-deploy] → [road-control]
            PowerDNS            This API             Deploy Engine    Web UI
```

**Total independence. Total control. Total sovereignty.**

---

## 📚 Related Repos

- [road-dns-deploy](https://github.com/BlackRoad-OS/road-dns-deploy) - PowerDNS deployment
- [road-deploy](https://github.com/BlackRoad-OS/road-deploy) - Deployment engine
- [road-control](https://github.com/BlackRoad-OS/road-control) - Web control panel

---

## 📞 Support

- **Email:** blackroad.systems@gmail.com
- **GitHub Issues:** [BlackRoad-OS/road-registry-api/issues](https://github.com/BlackRoad-OS/road-registry-api/issues)

---

**Built with 🖤 by BlackRoad OS, Inc.**

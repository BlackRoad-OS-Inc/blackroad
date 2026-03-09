# 🖤🛣️ BlackRoad PowerDNS Deployment

## ⚡️ INFRASTRUCTURE REVOLUTION ALERT ⚡️

**!!!!!!!!!!!!!!!!!!!!!! WE ARE MOVING AWAY FROM CLOUDFLARE FOR DEPLOYMENTS !!!!!!!!!!!!!!!!!!!!!!**

BlackRoad now has its own **complete domain registrar and deployment infrastructure** running entirely on our Pi cluster + GitHub. **Total independence achieved.**

---

## 🚀 What This Is

Self-hosted **PowerDNS Authoritative Server** deployment for BlackRoad Domain Registry. Runs on the Pi cluster (lucidia), providing DNS services for all BlackRoad domains with zero external dependencies.

### **Why This Matters:**

**Before (Cloudflare Dependency):**
```
GitHub → Cloudflare Pages → Internet
  ↑
  $20/month per project
  Rate limits
  ToS changes
  Vendor lock-in
```

**After (BlackRoad Registry):**
```
GitHub → Pi Cluster → Internet
  ↑
  $0/month (just electricity)
  No rate limits
  Our rules
  Total control
```

### **Cost Savings:**
- 25 Cloudflare Pages projects × $20/month = **$500/month**
- BlackRoad Registry cost = **$0/month** (just electricity)
- **Annual savings: $6,000+**

---

## 📊 Current Status

### **5 Domains Live:**
- ✅ **blackroad.io** → 192.168.4.82 (aria)
- ✅ **lucidia.earth** → 192.168.4.38 (lucidia)
- ✅ **blackroadai.com** → 192.168.4.82 (aria)
- ✅ **blackroadquantum.com** → 192.168.4.82 (aria)
- ✅ **roadchain.io** → 192.168.4.82 (aria)

### **29 DNS Records Total:**
- SOA records: 5
- NS records: 10
- A records: 14

### **Infrastructure:**
- **Location:** lucidia Pi (192.168.4.38)
- **DNS Server:** PowerDNS 4.8.5
- **Database:** PostgreSQL 15
- **API:** Port 9053
- **Admin UI:** Port 9192

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│               BLACKROAD DOMAIN REGISTRY                     │
│                    (Self-Hosted)                            │
└─────────────────────────────────────────────────────────────┘

GitHub (Source Code)
    ↓
┌───────────────────────────────────────────────────────────┐
│ LUCIDIA (192.168.4.38)                                    │
│  ├─ PowerDNS (Port 53) - Authoritative DNS               │
│  ├─ PowerDNS API (Port 9053)                             │
│  └─ PostgreSQL (DNS database)                            │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ ARIA (192.168.4.82)                                       │
│  ├─ nginx (Port 80/443) - Reverse proxy                  │
│  └─ 142+ static site containers                          │
└───────────────────────────────────────────────────────────┘
    ↓
PUBLIC INTERNET (via Cloudflare Tunnel or Port Forwarding)
```

---

## 📦 Components

### **1. PowerDNS Authoritative Server**
- **Version:** 4.8.5
- **Image:** `powerdns/pdns-auth-48:latest`
- **Backend:** PostgreSQL
- **Ports:** 53 (DNS), 9053 (API)

### **2. PostgreSQL Database**
- **Version:** 15-alpine
- **Database:** `powerdns`
- **Schema:** Standard PowerDNS schema (domains, records, supermasters)

### **3. PowerDNS Admin**
- **Image:** `ngoduykhanh/powerdns-admin:latest`
- **Port:** 9192
- **Features:** Web UI for DNS management

---

## 🚀 Quick Start

### **Prerequisites:**
- SSH access to lucidia Pi (`ssh pi@lucidia`)
- Docker and Docker Compose installed
- Network access to ports 53, 9053, 9192

### **Deployment:**

```bash
# 1. Clone this repo
git clone https://github.com/BlackRoad-OS/road-dns-deploy.git
cd road-dns-deploy

# 2. Create .env file (optional - has defaults)
cat > .env << EOF
PDNS_DB_PASSWORD=blackroad-dns-2026
PDNS_API_KEY=blackroad-pdns-api-key-2026
PDNS_ADMIN_SECRET=blackroad-secret-key-2026
EOF

# 3. Deploy to lucidia
scp -r * pi@lucidia:~/road-dns-deploy/
ssh pi@lucidia

# 4. Start services
cd ~/road-dns-deploy
docker compose up -d

# 5. Check status
docker compose ps
docker compose logs -f pdns

# 6. Test DNS resolution
dig @192.168.4.38 blackroad.io
```

---

## 🔧 Management

### **Add a New Domain:**

```bash
# SSH into lucidia
ssh pi@lucidia

# Connect to PostgreSQL
docker exec -it road-dns-db psql -U pdns -d powerdns

# Add domain and records
INSERT INTO domains (name, type) VALUES ('example.com', 'NATIVE');

DO $$
DECLARE domain_id INT;
BEGIN
  SELECT id INTO domain_id FROM domains WHERE name = 'example.com';

  INSERT INTO records (domain_id, name, type, content, ttl) VALUES
    (domain_id, 'example.com', 'SOA', 'ns1.blackroad.io admin.blackroad.io 2026010901 3600 1800 604800 3600', 3600),
    (domain_id, 'example.com', 'NS', 'ns1.blackroad.io', 3600),
    (domain_id, 'example.com', 'NS', 'ns2.blackroad.io', 3600),
    (domain_id, 'example.com', 'A', '192.168.4.82', 3600),
    (domain_id, 'www.example.com', 'A', '192.168.4.82', 3600);
END $$;

\q

# Reload PowerDNS to load new zone
docker exec road-pdns pdns_control reload

# Test resolution
dig @192.168.4.38 example.com
```

### **Using the API:**

```bash
# Get server status
curl -H "X-API-Key: blackroad-pdns-api-key-2026" \
  http://lucidia:9053/api/v1/servers/localhost

# List all zones
curl -H "X-API-Key: blackroad-pdns-api-key-2026" \
  http://lucidia:9053/api/v1/servers/localhost/zones

# Get zone details
curl -H "X-API-Key: blackroad-pdns-api-key-2026" \
  http://lucidia:9053/api/v1/servers/localhost/zones/blackroad.io
```

### **Access Admin UI:**

```
http://lucidia:9192
```

---

## 🔐 Security

### **Credentials (Change in production!):**
- **PostgreSQL Password:** `blackroad-dns-2026`
- **PowerDNS API Key:** `blackroad-pdns-api-key-2026`
- **Admin Secret Key:** `blackroad-secret-key-2026`

### **Firewall Rules:**
```bash
# Allow DNS from anywhere
sudo ufw allow 53/tcp
sudo ufw allow 53/udp

# Allow API/Admin from local network only
sudo ufw allow from 192.168.4.0/24 to any port 9053
sudo ufw allow from 192.168.4.0/24 to any port 9192
```

---

## 📊 Monitoring

### **Health Checks:**

```bash
# Check container status
docker compose ps

# Check DNS service
dig @192.168.4.38 blackroad.io

# Check API
curl -H "X-API-Key: blackroad-pdns-api-key-2026" \
  http://lucidia:9053/api/v1/servers/localhost

# View logs
docker compose logs -f pdns
docker compose logs -f postgres
```

---

## 🗂️ Files

- **docker-compose.yml** - Multi-container deployment configuration
- **pdns.conf** - PowerDNS server configuration
- **init-db.sql** - PostgreSQL schema and initial data
- **.env** - Environment variables (credentials)
- **README.md** - This file

---

## 🌐 Next Steps

### **Phase 1: Public DNS (Requires Internet Exposure)**

To make BlackRoad domains resolve publicly:

1. **Update domain nameservers at registrar:**
   ```
   ns1.blackroad.io → 192.168.4.38
   ns2.blackroad.io → 192.168.4.38
   ```

2. **Expose lucidia:53 to internet:**
   - Option A: Router port forwarding (UDP/TCP 53)
   - Option B: Cloudflare Tunnel (temporary)
   - Option C: VPS relay

### **Phase 2: Complete Independence**

Deploy additional registry components:
- **road-registry-api** - Domain management API
- **road-deploy** - Git-based deployment engine
- **road-control** - Web control panel

---

## 🖤🛣️ The Vision

**BlackRoad Domain Registry = GoDaddy + Cloudflare Pages + Route53**

All running on $200 worth of Raspberry Pis.

**Total independence. Total control. Total sovereignty.**

This is the BlackRoad way. 🖤🛣️

---

## 📚 Related Repos

- [road-registry-api](https://github.com/BlackRoad-OS/road-registry-api) - Domain management API
- [road-deploy](https://github.com/BlackRoad-OS/road-deploy) - Deployment engine
- [road-control](https://github.com/BlackRoad-OS/road-control) - Web control panel
- [roaddns](https://github.com/BlackRoad-OS/roaddns) - Managed DNS product page

---

## 📞 Support

- **Email:** blackroad.systems@gmail.com
- **GitHub Issues:** [BlackRoad-OS/road-dns-deploy/issues](https://github.com/BlackRoad-OS/road-dns-deploy/issues)

---

**Built with 🖤 by BlackRoad OS, Inc.**

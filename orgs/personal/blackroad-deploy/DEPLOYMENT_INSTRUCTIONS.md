# BlackRoad Deploy - Deployment Instructions

## ✅ What's Been Completed

1. **Code Repository**: https://github.com/blackboxprogramming/blackroad-deploy
2. **Deployment API**: Full REST API with Docker integration
3. **CLI Tool**: Complete command-line interface
4. **Infrastructure Scripts**: Automated setup for servers
5. **Documentation**: Complete guides and architecture docs

## 🚀 Deploy to Your Servers

### Option 1: One-Command Deployment (Recommended)

```bash
# SSH to your server
ssh root@159.65.43.12  # DigitalOcean
# OR
ssh alice-pi  # Raspberry Pi

# Download and run deployment script
curl -fsSL https://raw.githubusercontent.com/blackboxprogramming/blackroad-deploy/main/DEPLOY_NOW.sh | sudo bash
```

This script will:
- ✅ Install Docker & Docker Compose
- ✅ Clone the repository
- ✅ Configure environment
- ✅ Start all services
- ✅ Set up Cloudflare Tunnel

### Option 2: Manual Deployment

#### Step 1: Prepare Server

```bash
# SSH to server
ssh root@159.65.43.12

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt-get update && apt-get install -y docker-compose
```

#### Step 2: Clone and Configure

```bash
# Clone repository
cd /opt
git clone https://github.com/blackboxprogramming/blackroad-deploy.git
cd blackroad-deploy

# Configure environment
cp .env.example .env
nano .env  # Add your passwords and tokens
```

Edit `.env`:
```bash
DB_PASSWORD=your_secure_password
CF_API_TOKEN=yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy
CF_ZONE_ID=848cf0b18d51e0170e0d1537aec3505a
TUNNEL_ID=72f1d60c-dcf2-4499-b02d-d7a063018b33
```

#### Step 3: Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

Services will be running:
- **API**: http://localhost:3000
- **PostgreSQL**: localhost:5432
- **Caddy**: http://localhost:8080

#### Step 4: Set Up Cloudflare Tunnel

```bash
# Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# Login to Cloudflare
cloudflared tunnel login

# Create tunnel config
mkdir -p /root/.cloudflared
cat > /root/.cloudflared/config.yml <<EOF
tunnel: 72f1d60c-dcf2-4499-b02d-d7a063018b33
credentials-file: /root/.cloudflared/72f1d60c-dcf2-4499-b02d-d7a063018b33.json

ingress:
  - hostname: deploy-api.blackroad.systems
    service: http://localhost:3000
  - hostname: "*.blackroad.systems"
    service: http://localhost:8080
  - service: http_status:404
EOF

# Route DNS
cloudflared tunnel route dns 72f1d60c-dcf2-4499-b02d-d7a063018b33 deploy-api.blackroad.systems
cloudflared tunnel route dns 72f1d60c-dcf2-4499-b02d-d7a063018b33 "*.blackroad.systems"

# Start tunnel as service
cloudflared service install
systemctl start cloudflared
systemctl enable cloudflared
systemctl status cloudflared
```

#### Step 5: Verify Deployment

```bash
# Check tunnel
curl https://deploy-api.blackroad.systems/health

# Should return: {"status":"ok","timestamp":"..."}
```

## 👤 Create Your User Account

```bash
# Register your account
curl -X POST https://deploy-api.blackroad.systems/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "amundsonalexa@gmail.com",
    "password": "your_secure_password"
  }'

# Response will include your API key:
# {
#   "user": {"id": 1, "email": "amundsonalexa@gmail.com"},
#   "apiKey": "br_abc123..."
# }

# Save this API key!
```

## 💻 Install CLI on Your Local Machine

```bash
# Clone repository locally
cd ~
git clone https://github.com/blackboxprogramming/blackroad-deploy.git
cd blackroad-deploy/cli

# Install dependencies
npm install

# Build CLI
npm run build

# Link globally
npm link

# Verify installation
blackroad --version
```

## 🎯 Login and Deploy Your First App

```bash
# Login
blackroad login
# Enter your email and password

# Go to any Node.js project
cd ~/my-app

# Initialize BlackRoad Deploy
blackroad init

# Deploy!
blackroad deploy
```

Your app will be live at `https://my-app.blackroad.systems`

## 📝 Common Commands

```bash
# List all deployments
blackroad list

# View logs
blackroad logs my-app
blackroad logs my-app -f  # Follow logs

# Set environment variables
blackroad env set my-app DATABASE_URL=postgres://...
blackroad env get my-app

# Restart deployment
blackroad restart my-app

# Delete deployment
blackroad delete my-app
```

## 🥧 Deploy to Raspberry Pi

Same process, just SSH to your Pi:

```bash
ssh alice-pi

# Run deployment script
curl -fsSL https://raw.githubusercontent.com/blackboxprogramming/blackroad-deploy/main/DEPLOY_NOW.sh | sudo bash
```

Or use the Pi-specific script:

```bash
cd /opt/blackroad-deploy
sudo ./scripts/setup-pi-tunnel.sh
```

## 🐛 Troubleshooting

### Services Not Starting

```bash
# Check Docker
docker ps
systemctl status docker

# Check logs
docker-compose logs api
docker-compose logs postgres

# Restart services
docker-compose restart
```

### Tunnel Not Connecting

```bash
# Check tunnel status
systemctl status cloudflared
journalctl -u cloudflared -f

# Test tunnel
cloudflared tunnel info 72f1d60c-dcf2-4499-b02d-d7a063018b33

# Restart tunnel
systemctl restart cloudflared
```

### Can't Connect to API

```bash
# Check if API is running
curl http://localhost:3000/health

# Check firewall (shouldn't be needed with tunnel)
ufw status

# Check DNS
dig deploy-api.blackroad.systems
```

### Database Issues

```bash
# Connect to database
docker-compose exec postgres psql -U postgres -d blackroad_deploy

# List tables
\dt

# Check migrations
SELECT * FROM deployments;
```

## 📊 Monitoring

```bash
# View all containers
docker-compose ps

# View logs in real-time
docker-compose logs -f

# View specific service logs
docker-compose logs -f api
docker-compose logs -f postgres

# Check resource usage
docker stats
```

## 🔐 Security Checklist

- [ ] Change default database password
- [ ] Set strong user password
- [ ] Keep API key secure
- [ ] Enable Cloudflare firewall rules
- [ ] Set up automatic backups
- [ ] Enable 2FA on Cloudflare
- [ ] Monitor access logs

## 📦 Backup

```bash
# Backup database
docker-compose exec postgres pg_dump -U postgres blackroad_deploy > backup.sql

# Backup environment
cp .env .env.backup

# Restore database
docker-compose exec -T postgres psql -U postgres blackroad_deploy < backup.sql
```

## 🔄 Updates

```bash
# Pull latest code
cd /opt/blackroad-deploy
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

## 📞 Support

- **Repository**: https://github.com/blackboxprogramming/blackroad-deploy
- **Issues**: https://github.com/blackboxprogramming/blackroad-deploy/issues
- **Email**: blackroad.systems@gmail.com

## 🎉 You're Done!

Your own Railway alternative is now running. Deploy unlimited apps for ~$12/month!

```bash
blackroad deploy
```

---

Built with ❤️ by BlackRoad Systems

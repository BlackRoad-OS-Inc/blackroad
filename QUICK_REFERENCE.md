# BlackRoad Deploy - Quick Reference Card

## 🚀 Deploy to Server (Copy & Paste)

### On DigitalOcean Droplet
```bash
ssh root@159.65.43.12
curl -fsSL https://raw.githubusercontent.com/blackboxprogramming/blackroad-deploy/main/DEPLOY_NOW.sh | sudo bash
```

### On Raspberry Pi
```bash
ssh alice-pi
curl -fsSL https://raw.githubusercontent.com/blackboxprogramming/blackroad-deploy/main/DEPLOY_NOW.sh | sudo bash
```

## 🔑 After Server Setup

### 1. Configure Tunnel Credentials
```bash
cloudflared tunnel login
```

### 2. Route DNS
```bash
cloudflared tunnel route dns 72f1d60c-dcf2-4499-b02d-d7a063018b33 deploy-api.blackroad.systems
cloudflared tunnel route dns 72f1d60c-dcf2-4499-b02d-d7a063018b33 "*.blackroad.systems"
```

### 3. Start Tunnel
```bash
cloudflared service install
systemctl start cloudflared
systemctl enable cloudflared
```

### 4. Create Your Account
```bash
curl -X POST https://deploy-api.blackroad.systems/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "amundsonalexa@gmail.com", "password": "YOUR_PASSWORD"}'
```

## 💻 Install CLI on Mac

```bash
cd ~/blackroad-deploy/cli
npm install
npm run build
npm link
blackroad login
```

## 🎯 Deploy Your First App

```bash
cd ~/my-app
blackroad init
blackroad deploy
```

## 📝 Common Commands

```bash
blackroad list                          # List deployments
blackroad logs my-app                   # View logs
blackroad logs my-app -f                # Follow logs
blackroad env set my-app KEY=value      # Set env var
blackroad env get my-app                # Get env vars
blackroad restart my-app                # Restart
blackroad delete my-app                 # Delete
```

## 🔗 Important URLs

- **Repository**: https://github.com/blackboxprogramming/blackroad-deploy
- **API**: https://deploy-api.blackroad.systems
- **Your Apps**: https://*.blackroad.systems

## 🐛 Quick Troubleshooting

```bash
# Check services
docker-compose ps
docker-compose logs -f

# Check tunnel
systemctl status cloudflared
journalctl -u cloudflared -f

# Test API
curl https://deploy-api.blackroad.systems/health

# Restart everything
docker-compose restart
systemctl restart cloudflared
```

## 📊 Monitor

```bash
# Server logs
docker-compose logs -f api

# Database
docker-compose exec postgres psql -U postgres -d blackroad_deploy

# System resources
docker stats
```

## 🔑 Your Credentials

- **CF Token**: `yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy`
- **CF Zone**: `848cf0b18d51e0170e0d1537aec3505a`
- **Tunnel ID**: `72f1d60c-dcf2-4499-b02d-d7a063018b33`

---

**That's it!** You now have your own Railway alternative.

Cost: **~$12/month** vs Railway's $20-100+/month

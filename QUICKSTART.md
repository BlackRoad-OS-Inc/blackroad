# BlackRoad Deploy - Quick Start Guide

Get your own Railway alternative running in 15 minutes.

## Step 1: Server Setup

```bash
# SSH to your DigitalOcean droplet
ssh root@159.65.43.12

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt-get install docker-compose
```

## Step 2: Deploy BlackRoad Deploy

```bash
# Clone repository
cd /opt
git clone https://github.com/blackroad-os/blackroad-deploy
cd blackroad-deploy

# Configure environment
cp .env.example .env
nano .env  # Add your Cloudflare credentials

# Start services
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

## Step 3: Set Up Cloudflare Tunnel

```bash
# Run tunnel setup script
cd scripts
chmod +x setup-tunnel.sh
./setup-tunnel.sh
```

This will:
- Install cloudflared
- Configure DNS for deploy-api.blackroad.systems
- Start tunnel service

## Step 4: Create First User

```bash
# Register via API
curl -X POST https://deploy-api.blackroad.systems/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "amundsonalexa@gmail.com",
    "password": "your_secure_password"
  }'

# Save the API key returned
```

## Step 5: Install CLI Locally

```bash
# On your local machine
cd ~/blackroad-deploy/cli
npm install
npm run build
npm link  # Makes 'blackroad' command available globally
```

## Step 6: Login

```bash
blackroad login
# Enter your email and password
```

## Step 7: Deploy Your First App

```bash
# Go to any Node.js project
cd ~/my-app

# Initialize
blackroad init

# Deploy
blackroad deploy
```

Your app is now live at `https://my-app.blackroad.systems`!

## Verify Everything Works

```bash
# Check API health
curl https://deploy-api.blackroad.systems/health

# List deployments
blackroad list

# View logs
blackroad logs my-app

# Set environment variable
blackroad env set my-app NODE_ENV=production

# Restart
blackroad restart my-app
```

## Add Raspberry Pi (Optional)

```bash
# SSH to Pi
ssh alice@192.168.4.49

# Run Pi setup
curl -fsSL https://raw.githubusercontent.com/blackroad-os/blackroad-deploy/main/scripts/setup-pi-tunnel.sh | bash

# Follow tunnel setup instructions
cloudflared tunnel login
cloudflared tunnel create blackroad-pi
```

## Troubleshooting

### Tunnel not connecting
```bash
# Check tunnel status
systemctl status cloudflared
journalctl -u cloudflared -f
```

### API not responding
```bash
# Check containers
docker-compose ps
docker-compose logs api

# Restart services
docker-compose restart
```

### Database issues
```bash
# Check database
docker-compose exec postgres psql -U postgres -d blackroad_deploy

# View tables
\dt
```

## Next Steps

- Set up monitoring (Prometheus/Grafana)
- Configure backups
- Add custom domains
- Build web dashboard
- Set up CI/CD with GitHub Actions

## Resources

- Full docs: [README.md](./README.md)
- Architecture: [ARCHITECTURE.md](./ARCHITECTURE.md)
- Tunnel setup: [TUNNEL_SETUP.md](./TUNNEL_SETUP.md)

---

Need help? Open an issue: https://github.com/blackroad-os/blackroad-deploy/issues

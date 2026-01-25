#!/bin/bash
# ☁️ Migrate from DigitalOcean to Oracle Cloud FREE Tier

echo "☁️ ORACLE CLOUD FREE TIER MIGRATION GUIDE"
echo "=========================================="
echo ""

echo "🎁 What You Get FREE Forever:"
echo ""
echo "   ARM Compute:"
echo "   • 4 ARM CPU cores (Ampere A1)"
echo "   • 24 GB RAM total"
echo "   • 200 GB storage"
echo "   • 10 TB/month bandwidth"
echo ""
echo "   AMD Compute:"
echo "   • 2 AMD VMs (1/8 OCPU, 1GB each)"
echo ""
echo "   This is BETTER than your $6/month DigitalOcean droplet!"
echo ""

echo "📋 Step-by-Step Migration:"
echo ""

echo "1️⃣  Sign up for Oracle Cloud"
echo "   Visit: https://signup.cloud.oracle.com"
echo "   ✅ Always Free tier (no expiration)"
echo "   ⚠️  Requires credit card but won't be charged"
echo ""

echo "2️⃣  Create Compartment"
echo "   Menu → Identity → Compartments → Create"
echo "   Name: blackroad-infra"
echo ""

echo "3️⃣  Create ARM Instance"
echo "   Menu → Compute → Instances → Create"
echo ""
echo "   Settings:"
echo "   • Name: blackroad-failover"
echo "   • Image: Ubuntu 22.04 Minimal"
echo "   • Shape: VM.Standard.A1.Flex"
echo "   • OCPUs: 4 (use all free tier)"
echo "   • RAM: 24 GB (use all free tier)"
echo "   • Boot volume: 200 GB"
echo ""
echo "   Networking:"
echo "   • Create new VCN"
echo "   • Assign public IP"
echo ""
echo "   SSH Keys:"
echo "   • Upload your existing SSH public key"
echo "   • Or generate new key pair"
echo ""

echo "4️⃣  Configure Instance (after creation)"
echo ""
echo "   SSH into instance:"
echo "   ssh ubuntu@<public-ip>"
echo ""
echo "   Install Docker:"
cat << 'INSTALL_DOCKER'
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo systemctl enable docker
INSTALL_DOCKER
echo ""

echo "5️⃣  Install Cloudflare Tunnel"
cat << 'INSTALL_TUNNEL'
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o cloudflared
sudo mv cloudflared /usr/local/bin/
sudo chmod +x /usr/local/bin/cloudflared

# Login and create tunnel
cloudflared tunnel login
cloudflared tunnel create oracle-failover
INSTALL_TUNNEL
echo ""

echo "6️⃣  Deploy Your Apps"
echo "   Same Docker setup as DigitalOcean:"
echo "   • Pull your Docker images"
echo "   • Run containers"
echo "   • Configure Cloudflare Tunnel routing"
echo ""

echo "7️⃣  Update DNS/Routing"
echo "   • Update Cloudflare Tunnel config"
echo "   • Test failover"
echo "   • Verify everything works"
echo ""

echo "8️⃣  Cancel DigitalOcean"
echo "   Visit: https://cloud.digitalocean.com/settings/billing"
echo "   Destroy droplet"
echo "   Save: $6/month = $72/year"
echo ""

echo "💰 COST SAVINGS:"
echo "   Before: $6/month (DigitalOcean)"
echo "   After: $0/month (Oracle Free Tier)"
echo "   Annual Savings: $72"
echo ""

echo "🎯 After this migration:"
echo "   Total monthly cost = ~$23"
echo "   • $17 - Domains (essential)"
echo "   • $6 - Electricity (optimized)"
echo "   • $0 - Everything else!"
echo ""

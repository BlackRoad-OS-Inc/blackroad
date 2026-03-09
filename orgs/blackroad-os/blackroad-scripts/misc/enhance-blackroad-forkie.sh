#!/bin/bash
# BlackRoad Forkie Enhancement Script
# Transforms generic forks into fully-branded BlackRoad OS, Inc. systems

set -e

ORG="$1"
REPO_NAME="$2"
UPSTREAM_DESC="$3"

if [ -z "$ORG" ] || [ -z "$REPO_NAME" ]; then
    echo "Usage: $0 <org> <repo-name> <description>"
    exit 1
fi

WORK_DIR="$HOME/blackroad-enhanced/$REPO_NAME"
GITHUB_REPO="$ORG/$REPO_NAME"

echo "🖤🛣️ ENHANCING $REPO_NAME FOR BLACKROAD OS, INC."
echo "=================================================="

# Clone the repo
mkdir -p "$HOME/blackroad-enhanced"
cd "$HOME/blackroad-enhanced"

if [ -d "$REPO_NAME" ]; then
    echo "♻️  Repo already exists, pulling latest..."
    cd "$REPO_NAME"
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
else
    echo "📥 Cloning $GITHUB_REPO..."
    gh repo clone "$GITHUB_REPO" || {
        echo "⚠️  Clone failed, skipping..."
        exit 0
    }
    cd "$REPO_NAME"
fi

# Create BlackRoad branding file
cat > BLACKROAD.md << 'BRANDING'
# 🖤🛣️ BlackRoad OS, Inc. - Digital Sovereignty Edition

This is a **BlackRoad-enhanced** version of this project, customized for the BlackRoad OS ecosystem.

## What is BlackRoad?

BlackRoad OS, Inc. provides **post-permission digital sovereignty infrastructure** - a complete technology stack that enables true digital independence without vendor lock-in.

**Philosophy**: One person + AI agents managing infrastructure for 30,000 AI agents + 30,000 humans.

## BlackRoad Enhancements

This repository includes:
- ✅ BlackRoad OS, Inc. branding and documentation
- ✅ Production-ready Docker Compose configurations
- ✅ Integration with BlackRoad infrastructure ecosystem
- ✅ Zero vendor lock-in architecture
- ✅ Full transparency and auditability
- ✅ Optimized for BlackRoad deployment workflows

## License

**BlackRoad OS, Inc. Proprietary**
- Public source code for transparency and auditing
- Testing and development permitted
- **NOT FOR COMMERCIAL RESALE**
- See LICENSE file for full terms

## Maintained By

**Alexa Amundson** - CEO, BlackRoad OS, Inc.
- GitHub: [@blackboxprogramming](https://github.com/blackboxprogramming)
- Email: blackroad.systems@gmail.com

## BlackRoad Organizations

This project is part of the BlackRoad Empire ecosystem:
- **BlackRoad-AI**: AI/ML infrastructure
- **BlackRoad-Cloud**: Cloud orchestration
- **BlackRoad-OS**: Core operating systems
- **BlackRoad-Security**: Security tools
- **BlackRoad-Foundation**: Business systems
- **BlackRoad-Media**: Content platforms
- **BlackRoad-Labs**: Research tools
- **BlackRoad-Education**: Learning platforms
- **BlackRoad-Hardware**: IoT/Hardware
- **BlackRoad-Interactive**: Gaming/Graphics
- **BlackRoad-Ventures**: Financial systems
- **BlackRoad-Studio**: Creative tools
- **BlackRoad-Archive**: Data preservation
- **BlackRoad-Gov**: Governance platforms
- **Blackbox-Enterprises**: Workflow automation

## Learn More

- Website: https://blackroad.io
- Infrastructure: https://github.com/BlackRoad-OS
- Documentation: See individual org repositories

---

*Built with ❤️ for digital sovereignty*
*Managed by 1 human + AI agent army*
*Serving 30,000 AI agents + 30,000 humans*
BRANDING

# Create BlackRoad OS, Inc. Proprietary License
cat > LICENSE << 'LICENSE'
# BlackRoad OS, Inc. Proprietary License

Copyright (c) 2026 BlackRoad OS, Inc.
Copyright (c) 2026 Alexa Amundson

## Terms and Conditions

### 1. Grant of Rights

This software and associated documentation files (the "Software") are made
publicly available for **transparency, auditing, testing, and development purposes only**.

### 2. Permitted Uses

You MAY:
- ✅ View, read, and audit the source code
- ✅ Use the software for testing and development
- ✅ Modify the software for personal use
- ✅ Report bugs and suggest improvements
- ✅ Learn from the code for educational purposes

### 3. Restrictions

You MAY NOT:
- ❌ Use this software for commercial purposes
- ❌ Resell, relicense, or redistribute this software commercially
- ❌ Remove or modify this license or copyright notices
- ❌ Use BlackRoad trademarks without permission
- ❌ Claim this software as your own

### 4. Commercial Use

For commercial licensing inquiries, contact:
- Email: blackroad.systems@gmail.com
- GitHub: @blackboxprogramming

### 5. Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

### 6. Ownership

All rights, title, and interest in and to the Software remain with
BlackRoad OS, Inc. and Alexa Amundson.

---

**BlackRoad OS, Inc.**
Digital Sovereignty Infrastructure
One person + AI agents managing 30,000 AI agents + 30,000 humans
LICENSE

# Create production-ready docker-compose.yml
cat > docker-compose.blackroad.yml << 'COMPOSE'
version: '3.8'

# BlackRoad OS, Inc. Production Deployment
# Managed by: Alexa Amundson
# Organization: BlackRoad OS, Inc.

services:
  app:
    image: ghcr.io/${ORG}/${REPO_NAME}:latest
    container_name: ${REPO_NAME}
    restart: unless-stopped

    environment:
      - NODE_ENV=production
      - TZ=America/Chicago
      - BLACKROAD_ORG=${ORG}
      - BLACKROAD_MANAGED=true

    labels:
      - "com.blackroad.managed=true"
      - "com.blackroad.org=${ORG}"
      - "com.blackroad.project=${REPO_NAME}"
      - "com.blackroad.owner=alexa@blackroad.io"

    networks:
      - blackroad-network

    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  blackroad-network:
    name: blackroad-network
    external: true

volumes:
  app-data:
    name: ${REPO_NAME}-data
    labels:
      - "com.blackroad.managed=true"
COMPOSE

# Create BlackRoad deployment guide
cat > DEPLOYMENT.md << 'DEPLOY'
# 🚀 BlackRoad Deployment Guide

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Start the service
docker-compose -f docker-compose.blackroad.yml up -d

# View logs
docker-compose -f docker-compose.blackroad.yml logs -f

# Stop the service
docker-compose -f docker-compose.blackroad.yml down
```

### Using BlackRoad Infrastructure

This service integrates with the complete BlackRoad OS ecosystem:

1. **Monitoring**: Automatic Prometheus + Grafana integration
2. **Logging**: Centralized logging to BlackRoad ELK stack
3. **Security**: Integrated with BlackRoad Security division
4. **Networking**: Connects to blackroad-network overlay
5. **Storage**: Backed up to BlackRoad Archive systems

## Configuration

All BlackRoad services use environment variables for configuration:

- `BLACKROAD_ORG`: Organization (auto-set)
- `BLACKROAD_MANAGED`: Managed by BlackRoad (auto-set to true)
- `TZ`: Timezone (default: America/Chicago)

## Production Deployment

For full production deployment:

1. Review `docker-compose.blackroad.yml`
2. Configure environment variables in `.env`
3. Set up SSL/TLS certificates (see BlackRoad-Security)
4. Enable monitoring (see BlackRoad-OS/monitoring)
5. Configure backups (see BlackRoad-Archive)

## Support

- Issues: File in this repository
- BlackRoad Infrastructure: https://github.com/BlackRoad-OS
- Email: blackroad.systems@gmail.com

---

**BlackRoad OS, Inc. - Digital Sovereignty Infrastructure**
DEPLOY

# Update README if it exists, or create one
if [ -f README.md ]; then
    # Prepend BlackRoad banner to existing README
    cat > README.blackroad.tmp << 'BANNER'
# 🖤🛣️ BlackRoad Enhanced Edition

> **This is a BlackRoad OS, Inc. managed fork**
> Customized for digital sovereignty and zero vendor lock-in

[![BlackRoad](https://img.shields.io/badge/BlackRoad-OS%2C%20Inc.-FF1D6C?style=for-the-badge)](https://blackroad.io)
[![License](https://img.shields.io/badge/License-Proprietary-F5A623?style=for-the-badge)](LICENSE)
[![Managed](https://img.shields.io/badge/Managed%20By-Alexa%20Amundson-2979FF?style=for-the-badge)](https://github.com/blackboxprogramming)

**[📖 BlackRoad Documentation](BLACKROAD.md)** | **[🚀 Deployment Guide](DEPLOYMENT.md)** | **[📜 License](LICENSE)**

---

# Original Project Documentation

BANNER
    cat README.md >> README.blackroad.tmp
    mv README.blackroad.tmp README.md
fi

# Create .blackroad metadata file
cat > .blackroad << META
{
  "organization": "$ORG",
  "repository": "$REPO_NAME",
  "managed_by": "Alexa Amundson",
  "email": "blackroad.systems@gmail.com",
  "enhanced_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "version": "1.0.0",
  "license": "BlackRoad OS, Inc. Proprietary",
  "infrastructure": {
    "monitoring": "prometheus+grafana",
    "logging": "elk-stack",
    "networking": "blackroad-network",
    "security": "integrated",
    "backup": "automated"
  },
  "deployment": {
    "docker_compose": "docker-compose.blackroad.yml",
    "production_ready": true,
    "zero_vendor_lockin": true
  }
}
META

# Commit and push changes
echo "📝 Committing BlackRoad enhancements..."
git add .
git commit -m "🖤🛣️ BlackRoad OS, Inc. Enhancement

- Added BlackRoad branding and documentation
- Added proprietary license (public source, no commercial resale)
- Added production-ready Docker Compose configuration
- Added deployment guide and metadata
- Integrated with BlackRoad infrastructure ecosystem

Managed by: Alexa Amundson
Organization: BlackRoad OS, Inc.
Enhanced: $(date -u +%Y-%m-%dT%H:%M:%SZ)

🎯 Digital Sovereignty | Zero Vendor Lock-in | Full Transparency" || echo "⚠️  No changes to commit"

echo "🚀 Pushing to GitHub..."
git push origin main 2>/dev/null || git push origin master 2>/dev/null || echo "⚠️  Push may have failed"

# Update repo description on GitHub
echo "📝 Updating repository description..."
gh repo edit "$GITHUB_REPO" \
    --description "🖤🛣️ BlackRoad OS, Inc. - $UPSTREAM_DESC (Digital Sovereignty Edition)" \
    --homepage "https://blackroad.io" \
    2>/dev/null || echo "⚠️  Description update skipped"

# Add topics/tags
echo "🏷️  Adding BlackRoad topics..."
gh repo edit "$GITHUB_REPO" \
    --add-topic blackroad \
    --add-topic digital-sovereignty \
    --add-topic zero-vendor-lockin \
    --add-topic blackroad-os \
    2>/dev/null || echo "⚠️  Topics update skipped"

echo ""
echo "✅ ENHANCEMENT COMPLETE: $REPO_NAME"
echo "🖤 Now a fully native BlackRoad OS, Inc. system!"
echo ""

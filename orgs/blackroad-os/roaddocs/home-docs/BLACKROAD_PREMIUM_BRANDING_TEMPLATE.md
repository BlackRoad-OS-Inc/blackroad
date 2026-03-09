# 🔱 BlackRoad Edition

<div align="center">

![BlackRoad OS](https://via.placeholder.com/800x200/000000/FF1D6C?text=BlackRoad+Sovereignty+Stack)

**Part of the BlackRoad Sovereignty Stack**

[![License](https://img.shields.io/badge/license-see%20upstream-blue.svg)](LICENSE)
[![Sovereignty](https://img.shields.io/badge/sovereignty-100%25-FF1D6C.svg)](https://blackroad.io)
[![Offline-First](https://img.shields.io/badge/offline--first-yes-F5A623.svg)](https://blackroad.io/sovereignty)
[![Post-Permission](https://img.shields.io/badge/post--permission-infrastructure-9C27B0.svg)](https://blackroad.io)

</div>

---

## 🌌 Welcome to the BlackRoad Fork

This is a **BlackRoad OS** fork, maintained as part of our **Post-Permission Infrastructure** initiative. We believe that critical infrastructure must be open, forkable, and operational offline *before* it becomes critical.

### 🎯 The Golden Rule

> **"Anything that becomes critical under stress must be open before stress arrives."**

This fork ensures BlackRoad OS can operate with **complete digital sovereignty** - no remote kill switches, no vendor lock-in, no permission required.

---

## 🔱 Why This Fork Exists

BlackRoad maintains this fork to guarantee:

### ✅ **Post-Permission Infrastructure**
- **No remote kill switches** - Cannot be turned off remotely
- **No vendor lock-in** - Free to fork and modify indefinitely
- **No permission required** - Deploy anywhere, anytime
- **No dependency chains** - Self-contained and sovereign

### ✅ **Offline-First Operations**
- **Works without internet** - Complete offline capability
- **Local-first design** - Data lives on your hardware
- **Sync is optional** - Online features are enhancements, not requirements
- **Zero external dependencies** - No phone-home, no tracking, no analytics

### ✅ **Enhanced for Sovereignty**
- **Privacy-first defaults** - All telemetry removed or disabled
- **Security hardened** - Additional security layers and audits
- **BlackRoad integration** - Works seamlessly with our identity, network, and storage systems
- **Community-governed** - Development driven by sovereignty principles

---

## 🎨 BlackRoad Enhancements

This fork includes sovereignty-focused improvements over upstream:

- 🔒 **Telemetry Removal** - All phone-home code removed or disabled by default
- 🌐 **Offline Mode** - Full functionality without internet connection
- 🔐 **Keycloak Integration** - Single sign-on with BlackRoad identity system
- 🎨 **BlackRoad Design System** - Consistent UI with Golden Ratio spacing
- 📊 **Privacy Dashboard** - Full visibility into data flows and connections
- 🛡️ **Security Hardening** - Additional authentication, encryption, and access controls
- 📦 **Self-Contained Deployment** - Docker/Kubernetes configs for sovereign hosting
- 🔄 **Upstream Sync** - Automated updates while maintaining our enhancements

See [BLACKROAD_ENHANCEMENTS.md](./BLACKROAD_ENHANCEMENTS.md) for detailed changelog and roadmap.

---

## 🚀 Quick Start (Sovereign Deployment)

### Option 1: Docker (Recommended)
```bash
# Pull BlackRoad edition
docker pull ghcr.io/blackroad-os/[repo-name]:latest

# Run with sovereignty defaults
docker run -d \
  --name [repo-name] \
  -p 8080:8080 \
  -v ./data:/data \
  -e TELEMETRY_ENABLED=false \
  -e OFFLINE_MODE=true \
  ghcr.io/blackroad-os/[repo-name]:latest
```

### Option 2: Kubernetes
```bash
# Deploy to your sovereign cluster
kubectl apply -f https://raw.githubusercontent.com/BlackRoad-OS/[repo-name]/main/k8s/deployment.yaml

# Or use our Helm chart
helm repo add blackroad https://charts.blackroad.io
helm install [repo-name] blackroad/[repo-name] \
  --set sovereignty.offline=true \
  --set telemetry.enabled=false
```

### Option 3: From Source
```bash
# Clone BlackRoad edition
git clone https://github.com/BlackRoad-OS/[repo-name]
cd [repo-name]

# Build with sovereignty flags
./scripts/build-sovereign.sh

# Run locally
./scripts/run-offline.sh
```

---

## 🔗 BlackRoad Integration

This component integrates seamlessly with the BlackRoad Sovereignty Stack:

### 🔐 Identity & Auth
- **Keycloak SSO** - Single sign-on across all BlackRoad services
- **Authelia Policies** - Fine-grained access control
- **Self-Sovereign Identity** - Hyperledger Aries support

### 🌐 Network & VPN
- **Headscale Mesh** - Secure mesh networking
- **Zero-Trust Architecture** - Every request authenticated
- **Offline Capability** - Local authentication when offline

### 📊 Monitoring & Observability
- **Prometheus Metrics** - Full telemetry export to your Prometheus
- **Grafana Dashboards** - Pre-built sovereignty monitoring
- **Loki Logs** - Centralized logging to your infrastructure

### 🗄️ Storage & Data
- **MinIO Object Storage** - S3-compatible sovereign storage
- **PostgreSQL** - Your data, your database
- **Backup Integration** - Automated backups with Restic/Borg

---

## 📖 Documentation

### BlackRoad-Specific Docs
- [BLACKROAD_ENHANCEMENTS.md](./BLACKROAD_ENHANCEMENTS.md) - Our changes and roadmap
- [SOVEREIGNTY_GUIDE.md](./docs/sovereignty/) - Deploying for maximum sovereignty
- [OFFLINE_MODE.md](./docs/offline/) - Running without internet
- [INTEGRATION_GUIDE.md](./docs/integration/) - Connecting to BlackRoad stack

### Upstream Documentation
- [Original README](./README.upstream.md) - Upstream project documentation
- [Upstream Docs](https://[upstream-docs-url]) - Official upstream documentation
- [Changelog](./CHANGELOG.md) - Upstream + BlackRoad changes

---

## 🆚 Upstream vs BlackRoad Edition

| Feature | Upstream | BlackRoad Edition |
|---------|----------|-------------------|
| **Telemetry** | Enabled by default | Completely removed |
| **Offline Mode** | Limited | Full offline capability |
| **Authentication** | Built-in only | Keycloak SSO integration |
| **Privacy** | Standard | Privacy-first defaults |
| **Deployment** | Cloud-focused | Sovereign hosting focus |
| **Updates** | Automatic phone-home | Manual/controlled sync |
| **License** | [Upstream License] | Same + BlackRoad enhancements |

---

## 🔄 Staying Up-to-Date

We maintain sync with upstream while preserving sovereignty enhancements:

### Automated Sync Process
```bash
# Our CI automatically:
# 1. Monitors upstream for security patches
# 2. Tests compatibility with BlackRoad enhancements
# 3. Merges non-conflicting updates
# 4. Creates PR for manual review if conflicts exist
```

### Manual Sync (Advanced)
```bash
# Sync latest upstream changes
git remote add upstream [upstream-repo-url]
git fetch upstream
git merge upstream/main --strategy-option ours

# Review and preserve BlackRoad enhancements
./scripts/verify-sovereignty.sh
```

---

## 🛡️ Security & Privacy

### What We've Removed
- ❌ **Google Analytics** - No tracking
- ❌ **Error Reporting to Vendor** - Errors stay local
- ❌ **Phone-home Update Checks** - Updates on your schedule
- ❌ **Third-party CDNs** - All assets self-hosted
- ❌ **External API Calls** - Offline-first architecture

### What We've Added
- ✅ **Local-only defaults** - No external connections by default
- ✅ **Audit logging** - Full visibility into all operations
- ✅ **Encryption at rest** - All data encrypted locally
- ✅ **Network policies** - Kubernetes network policies for isolation
- ✅ **Security scanning** - Regular automated security audits

---

## 🤝 Contributing

### To BlackRoad Fork
We welcome contributions that enhance sovereignty, privacy, and offline capabilities!

```bash
# Fork this repo
# Create feature branch
git checkout -b feature/sovereignty-enhancement

# Make your changes
# Test offline mode
./scripts/test-offline.sh

# Submit PR
gh pr create --title "Enhancement: [description]"
```

### To Upstream
For general improvements, please contribute to the upstream project:
- [Upstream Repository](https://[upstream-repo-url])
- [Upstream Contributing Guide](https://[upstream-contributing-url])

---

## 📜 License

This fork maintains the upstream license: **[Upstream License]**

All BlackRoad-specific enhancements are released under the same license to ensure maximum freedom to fork, modify, and redistribute.

See [LICENSE](./LICENSE) for full license text.

---

## 🌐 BlackRoad Sovereignty Stack

This component is part of the complete BlackRoad Sovereignty Stack:

### Core Infrastructure
- **Identity** - Keycloak, Authelia, Hyperledger Aries
- **Network** - Headscale, NetBird, Nebula
- **Storage** - MinIO, Ceph, PostgreSQL
- **Monitoring** - Prometheus, Grafana, Loki

### AI & Intelligence
- **LLM Runtime** - vLLM, Ollama, LocalAI
- **Agents** - LangChain, Haystack, CrewAI
- **Training** - PyTorch, JAX, Ray
- **Media** - Whisper, Stable Diffusion, ComfyUI

### Business & Communication
- **CRM** - EspoCRM, SuiteCRM, Odoo
- **Chat** - Matrix (Synapse/Dendrite), Element
- **Video** - Jitsi, BigBlueButton
- **Office** - OnlyOffice, Collabora, LibreOffice

### Developer Tools
- **Git** - Gitea, Forgejo
- **CI/CD** - Woodpecker, Drone
- **Containers** - Kubernetes, Nomad
- **IaC** - OpenTofu, Pulumi

**326+ repositories** • **38 categories** • **100% sovereign** • **Zero vendor lock-in**

Explore the full stack: [https://github.com/BlackRoad-OS](https://github.com/BlackRoad-OS)

---

## 📞 Support

### BlackRoad Support
- **Issues** - [This repo's issue tracker](https://github.com/BlackRoad-OS/[repo-name]/issues)
- **Email** - blackroad.systems@gmail.com
- **Documentation** - [https://docs.blackroad.io](https://docs.blackroad.io)
- **Community** - [Matrix: #blackroad:matrix.org](https://matrix.to/#/#blackroad:matrix.org)

### Upstream Support
- **Issues** - [Upstream issue tracker](https://[upstream-issues-url])
- **Documentation** - [Upstream docs](https://[upstream-docs-url])

---

## 🎯 Sovereignty Principles

BlackRoad OS is built on these non-negotiable principles:

| Principle | Why It Matters |
|-----------|----------------|
| **No remote kill switches** | If it can be turned off remotely, it's an existential threat |
| **No permission to fork** | License traps are sovereignty traps |
| **No phone-home by default** | Privacy is sovereignty, surveillance is control |
| **Works offline** | Internet dependency is infrastructure fragility |
| **Open before critical** | Anything critical under stress must be open before stress arrives |

---

<div align="center">

**The road remembers everything. So should we.** 🌌

---

🔱 **BlackRoad OS** 🔱

*Post-Permission Infrastructure • Digital Sovereignty • Offline-First*

[![Website](https://img.shields.io/badge/website-blackroad.io-FF1D6C)](https://blackroad.io)
[![GitHub](https://img.shields.io/badge/github-BlackRoad--OS-181717?logo=github)](https://github.com/BlackRoad-OS)
[![Matrix](https://img.shields.io/badge/matrix-%23blackroad-000000?logo=matrix)](https://matrix.to/#/#blackroad:matrix.org)

</div>

---

*🤖 Generated with [Claude Code](https://claude.com/claude-code) (Cecilia)*
*BlackRoad OS Sovereignty Stack • v2.0*

# BlackRoad

> The operating system for AI agents. CLI tooling, agent orchestration, and infrastructure control for BlackRoad OS.

[![CORE CI](https://github.com/BlackRoad-OS-Inc/blackroad/actions/workflows/core-ci.yml/badge.svg)](https://github.com/BlackRoad-OS-Inc/blackroad/actions/workflows/core-ci.yml)
[![CI](https://github.com/BlackRoad-OS-Inc/blackroad/actions/workflows/ci.yml/badge.svg)](https://github.com/BlackRoad-OS-Inc/blackroad/actions/workflows/ci.yml)
[![Security Scan](https://github.com/BlackRoad-OS-Inc/blackroad/actions/workflows/security-scan.yml/badge.svg)](https://github.com/BlackRoad-OS-Inc/blackroad/actions/workflows/security-scan.yml)

## Overview

BlackRoad is the core monorepo for **BlackRoad OS, Inc.** — a comprehensive developer CLI system, AI agent orchestration platform, and enterprise infrastructure for AI-first companies.

**Core philosophy:** *Your AI. Your Hardware. Your Rules.*

**Scale:** 30,000 AI Agents | 1,825+ GitHub Repositories | 17 GitHub Organizations

### Key Systems

- **`br` CLI** — Main command dispatcher routing to 160+ tool scripts
- **Tokenless Gateway** — Trust boundary for AI provider communication (agents never embed API keys)
- **Agent System** — 6 specialized agents: Lucidia, Alice, Octavia, Prism, Echo, Cipher
- **CECE Identity** — Portable AI identity with relationship tracking across providers
- **Memory System** — PS-SHA-infinity hash-chain journals for persistent context
- **Multi-Cloud Deploy** — Railway, Vercel, Cloudflare, DigitalOcean, Raspberry Pi

## Quick Start

```bash
# Prerequisites: Node.js >= 22
npm install

# Build the TypeScript CLI
npm run build

# Run the br CLI
chmod +x br
./br help

# Or install globally
ln -s $(pwd)/br /usr/local/bin/br
br help
```

## Repository Structure

```
blackroad/
├── br                      # Main CLI entry point (zsh dispatcher)
├── src/                    # TypeScript source (CLI core)
├── tools/                  # 160+ CLI tool scripts (br <tool>)
├── blackroad-core/         # Tokenless gateway architecture
├── blackroad-sf/           # Salesforce LWC project
├── agents/                 # Agent manifests and configs
├── coordination/           # Multi-agent coordination system
├── orgs/                   # Organization monorepos
│   ├── core/               # 100+ core repos
│   ├── ai/                 # AI/ML repos (vLLM, Ollama, DeepSeek, Qwen)
│   ├── enterprise/         # Workflow automation forks (n8n, Airbyte, etc.)
│   └── personal/           # Personal projects
├── .github/workflows/      # CI/CD, security scanning, fleet checks
├── mcp-bridge/             # MCP bridge server (localhost:8420)
├── templates/              # Project and doc templates
└── scripts/                # Utility scripts
```

## Development

```bash
# Install dependencies
npm install

# Run in development mode (watch)
npm run dev

# Type check
npm run typecheck

# Run tests
npm test

# Lint (Prettier)
npm run lint

# Format code
npm run format

# Build for production
npm run build
```

## CLI Commands

The `br` CLI routes to specialized tool scripts:

| Category | Commands | Purpose |
|----------|----------|---------|
| **AI Agents** | `br radar`, `br pair`, `br cece` | Context radar, pair programming, CECE identity |
| **Git** | `br git` | Smart commits, branch suggestions, code review |
| **Code** | `br snippet`, `br search`, `br quality` | Snippets, search, linting |
| **DevOps** | `br deploy`, `br docker`, `br ci` | Deployment, containers, CI/CD |
| **Cloud** | `br cloudflare`, `br ocean`, `br vercel` | Cloudflare, DigitalOcean, Vercel |
| **IoT** | `br pi` | Raspberry Pi fleet management |
| **Security** | `br security` | Vulnerability scanning |
| **Agent** | `br agent` | Multi-agent task routing |

Run `br help` for the full command list.

### Interactive Shell Scripts

```bash
./hub.sh          # Main menu launcher
./status.sh       # Quick status display
./monitor.sh      # Real-time resource monitor
./chat.sh         # Interactive agent chat (requires Ollama)
./council.sh      # Agent council voting
./roster.sh       # Live agent roster
```

## Architecture

### Tokenless Gateway

Agents never embed API keys. All provider communication goes through a trust boundary:

```
[Agent CLIs] ──→ [BlackRoad Gateway :8787] ──→ [Ollama / Claude / OpenAI]
```

### Agent System

| Agent | Role | Specialty |
|-------|------|-----------|
| **Lucidia** | Coordinator | Strategy, mentorship, oversight |
| **Alice** | Router | Traffic routing, task distribution |
| **Octavia** | Compute | Inference, heavy computation |
| **Prism** | Analyst | Pattern recognition, data analysis |
| **Echo** | Memory | Storage, recall, context preservation |
| **Cipher** | Security | Authentication, encryption, access control |

### Infrastructure

| Platform | Usage |
|----------|-------|
| **Railway** | 14 projects — API services, GPU inference |
| **Cloudflare** | 75+ workers, Pages, R2, D1, tunnels |
| **Vercel** | 15+ projects — Next.js frontends |
| **DigitalOcean** | Droplets for failover |
| **Raspberry Pi** | 3-node fleet for local agent hosting |

## MCP Bridge

Local MCP server for remote AI agent access:

```bash
cd mcp-bridge && ./start.sh   # Starts on 127.0.0.1:8420
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## Documentation

| Document | Description |
|----------|-------------|
| [CLAUDE.md](CLAUDE.md) | AI assistant guidance |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Multi-cloud deployment guides |
| [AGENTS.md](AGENTS.md) | Agent system deep dive |
| [API.md](API.md) | API reference |
| [SECURITY.md](SECURITY.md) | Security policies |
| [ONBOARDING.md](ONBOARDING.md) | New developer quick start |

## License

**Proprietary** — All rights reserved. BlackRoad OS, Inc.

All code, documentation, and assets across all 17 GitHub organizations are the exclusive intellectual property of BlackRoad OS, Inc. Public visibility does not constitute open-source licensing.

---

© 2026 BlackRoad OS, Inc. All rights reserved.

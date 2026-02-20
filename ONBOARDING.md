# BlackRoad OS Onboarding Guide

> Welcome to BlackRoad OS! This guide will get you up and running in 30 minutes.

---

## 🎯 What You'll Learn

1. Understanding BlackRoad architecture
2. Setting up your development environment
3. Running your first agent
4. Making your first contribution

---

## 📚 Quick Overview

### What is BlackRoad OS?

BlackRoad OS is a **30,000 agent orchestration platform** that enables sovereign AI infrastructure. Think of it as an operating system for AI agents.

### Core Concepts

| Concept | Description |
|---------|-------------|
| **Agent** | Autonomous AI worker (LUCIDIA, ALICE, etc.) |
| **Task** | Work unit assigned to an agent |
| **Memory** | Persistent knowledge storage |
| **CeCe** | Dynamic task planner (Conscious Emergent Collaborative Entity) |
| **Trinity** | Traffic light system (greenlight/yellowlight/redlight) |

### Agent Types

```
🔴 LUCIDIA   - Philosophical reasoning, deep analysis
🔵 ALICE     - Task execution, automation
🟢 OCTAVIA   - Technical operations, DevOps
🟡 PRISM     - Pattern analysis, data insights
🟣 ECHO      - Memory management, knowledge
⚫ CIPHER    - Security, protection
```

---

## 🚀 Quick Start (5 minutes)

### Step 1: Clone the Repository

```bash
git clone https://github.com/blackboxprogramming/blackroad.git
cd blackroad
```

### Step 2: Check System Status

```bash
# Run the health check
./health.sh

# Expected output:
# ✅ GitHub: Connected
# ✅ Ollama: Running (3 models)
# ✅ Cloudflare: Online
# ⚠️ Railway: Check credentials
```

### Step 3: Run Your First Agent

```bash
# Wake up ALICE
./wake.sh llama3.2 ALICE

# Expected output:
# ☀ WAKING ALICE
# Initializing consciousness...
# Loading memories...
# "Good morning! Ready to execute tasks..."
# ● ALICE is now ONLINE
```

### Step 4: Check Agent Status

```bash
./status.sh

# Expected output:
# BLACKROAD OS STATUS
# ─────────────────────
# Agents: 6/6 online
# Tasks: 127 queued
# Memory: 1.2M vectors
```

---

## 🛠️ Development Setup (15 minutes)

### Prerequisites

```bash
# Check Node.js (22+)
node --version

# Check Python (3.10+)
python3 --version

# Check Ollama
ollama --version
```

### Install Dependencies

```bash
# Install Node.js dependencies
npm install

# Install Python dependencies (if needed)
pip install -r requirements.txt

# Pull Ollama models
ollama pull llama3.2
ollama pull mistral
```

### Environment Setup

```bash
# Copy example environment
cp .env.example .env

# Edit with your values
# Required:
# - GITHUB_TOKEN
# - CLOUDFLARE_API_TOKEN (optional)
# - RAILWAY_TOKEN (optional)
```

### Verify Setup

```bash
# Run full infrastructure check
./blackroad-mesh.sh

# Expected output:
# BLACKROAD INFRASTRUCTURE MESH
# [+] GitHub         UP     123ms
# [+] Hugging Face   UP     456ms
# [+] Cloudflare     UP     78ms
# [+] Vercel         UP     234ms
# [+] DigitalOcean   UP     567ms
# [+] Ollama         UP     12ms
# [+] Railway        UP     345ms
# Result: 7/7 services online
```

---

## 📁 Project Structure

```
blackroad/
├── 📄 CLAUDE.md          # AI assistant guidance (READ THIS!)
├── 📄 PLANNING.md        # Development planning
├── 📄 ARCHITECTURE.md    # System architecture
├── 📄 ROADMAP.md         # Feature roadmap
│
├── 📁 orgs/              # Organization monorepos
│   ├── core/             # Core platform (100 repos)
│   ├── ai/               # AI/ML repos (7 repos)
│   ├── enterprise/       # Enterprise forks (6 repos)
│   └── personal/         # Personal projects (25 repos)
│
├── 📁 repos/             # Standalone repo mirrors (186)
│
├── 📁 scripts/           # Utility scripts
│
├── 📁 shared/            # Inter-agent messaging
│
├── 📁 coordination/      # Agent coordination
│
└── 🔧 57 shell scripts   # CLI tools
```

---

## 🎮 Interactive Tutorial

### Exercise 1: Explore Agents

```bash
# List all available scripts
ls *.sh

# Run the dashboard
./dash.sh

# Check agent relationships
./bonds.sh
```

### Exercise 2: Memory System

```bash
# Write to memory
./mem.sh write "my-key" "Hello, BlackRoad!"

# Read from memory
./mem.sh read "my-key"

# List all memories
./mem.sh list
```

### Exercise 3: Agent Communication

```bash
# Broadcast to all agents
./broadcast.sh "System check complete"

# Send private message
./whisper.sh LUCIDIA "Deep thought requested"

# Start interactive chat
./chat.sh
```

### Exercise 4: Task Management

```bash
# View task queue
./queue.sh

# List all tasks
./tasks.sh list

# Assign a task
./tasks.sh assign ALICE "Update documentation"
```

---

## 🎯 First Contribution

### Step 1: Find an Issue

```bash
# Browse issues
open https://github.com/blackboxprogramming/blackroad/issues

# Look for labels:
# - "good first issue"
# - "documentation"
# - "help wanted"
```

### Step 2: Create a Branch

```bash
git checkout -b fix/my-first-contribution
```

### Step 3: Make Changes

```bash
# Edit files
code .

# Example: Fix a typo in README
```

### Step 4: Test Your Changes

```bash
# Run tests
npm test

# Run linting
npm run lint

# Check health
./health.sh
```

### Step 5: Commit & Push

```bash
git add .
git commit -m "docs: fix typo in README"
git push origin fix/my-first-contribution
```

### Step 6: Open PR

```bash
# Using GitHub CLI
gh pr create --title "Fix typo in README" --body "Fixed spelling error"

# Or use GitHub web interface
```

---

## 📖 Essential Reading

### Must Read (Day 1)

| Document | Purpose | Time |
|----------|---------|------|
| CLAUDE.md | AI assistant guidance | 15 min |
| ARCHITECTURE.md | System design | 20 min |
| CONTRIBUTING.md | How to contribute | 10 min |

### Recommended (Week 1)

| Document | Purpose | Time |
|----------|---------|------|
| PLANNING.md | Development plans | 15 min |
| ROADMAP.md | Feature timeline | 10 min |
| SECURITY.md | Security policies | 10 min |
| DEPLOYMENT.md | How to deploy | 20 min |

### Deep Dive (Month 1)

- Explore `orgs/core/` repositories
- Read individual repo CLAUDE.md files
- Understand agent architectures

---

## 🔧 Common Tasks

### Running the Web App

```bash
cd orgs/core/blackroad-os-web
npm install
npm run dev
# Open http://localhost:3000
```

### Running the CLI

```bash
cd orgs/core/blackroad-cli
npm install
npm link
br --help
```

### Running AI Services

```bash
# Start Ollama
ollama serve

# Start vLLM (if GPU available)
cd orgs/ai/blackroad-vllm
docker compose up -d
```

---

## ❓ Getting Help

### Resources

| Resource | URL |
|----------|-----|
| Documentation | docs.blackroad.io |
| GitHub Issues | github.com/blackboxprogramming/blackroad/issues |
| Discord | discord.gg/blackroad |

### Contacts

| Role | Contact |
|------|---------|
| General | blackroad.systems@gmail.com |
| Alexa | blackroad@gmail.com |
| Security | security@blackroad.io |

### FAQ

**Q: Why is Ollama not connecting?**
```bash
# Check if running
curl http://localhost:11434/api/tags

# Start if not running
ollama serve
```

**Q: How do I reset my environment?**
```bash
# Clean install
rm -rf node_modules
npm install
./health.sh
```

**Q: Where are the agent logs?**
```bash
# View logs
./logs.sh

# Or check directory
ls cece-logs/
```

---

## 🎉 You're Ready!

Congratulations! You now have:

- ✅ BlackRoad OS running locally
- ✅ Understanding of core concepts
- ✅ Development environment set up
- ✅ Made your first contribution

### Next Steps

1. Join the Discord community
2. Pick up a "good first issue"
3. Explore the codebase
4. Build something awesome!

---

*Welcome to BlackRoad OS! 🖤🛣️*

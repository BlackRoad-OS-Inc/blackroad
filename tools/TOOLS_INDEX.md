# BlackRoad Tools Index

> 164 modular CLI tools invoked via `br <tool> <command>`

---

## Quick Reference

```bash
br <tool>              # Run a tool
br <tool> help         # Show tool help
br <tool> <command>    # Run specific command
```

---

## 🤖 AI & Agents (16 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `agent-gateway` | `br agent-gateway` | Agent gateway routing and proxying |
| `agent-identity` | `br agent-identity` | Agent identity management and registration |
| `agent-mesh` | `br agent-mesh` | Infrastructure mesh connectivity checks |
| `agent-nats` | `br agent-nats` | NATS pub/sub messaging for agents |
| `agent-router` | `br agent` | Multi-agent task routing and dispatch |
| `agent-runtime` | `br agent-runtime` | Agent boot, fleet, and runtime management |
| `agent-tasks` | `br tasks` | Agent task queue management |
| `agent-watch` | `br agent-watch` | Watch and monitor running agents |
| `agents-live` | `br agents` | Live agent status and roster |
| `ai` | `br ai` | AI model interactions and completions |
| `ai-hub` | `br ai-hub` | Multi-model AI hub and provider router |
| `coding-assistant` | `br coding-assistant` | AI-powered coding assistant |
| `llm` | `br llm` | Direct LLM inference and prompting |
| `model` | `br model` | Model management (pull, list, delete) |
| `pair-programming` | `br pair` | AI pair programming session |
| `prompt` | `br prompt` | Prompt templates and management |

---

## 🚀 DevOps & Deployment (22 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `ci-pipeline` | `br ci` | CI/CD pipeline status and triggers |
| `deploy` | `br deploy` | One-command full-stack deployment |
| `deploy-cmd` | `br deploy-cmd` | Deployment command builder |
| `deploy-manager` | `br deploy-manager` | Multi-target deployment manager |
| `docker-manager` | `br docker` | Docker container management |
| `env-check` | `br env-check` | Environment variable validation |
| `env-diff` | `br env-diff` | Compare environments (dev/staging/prod) |
| `env-manager` | `br env` | Environment variable CRUD management |
| `feat` | `br feat` | Feature flag management |
| `fleet` | `br fleet` | Agent fleet orchestration |
| `hook` | `br hook` | Git hook installation and management |
| `k8s` | `br k8s` | Kubernetes cluster operations |
| `nodes` | `br nodes` | Node/server inventory management |
| `provider` | `br provider` | Cloud provider configuration |
| `railway` | `br railway` | Railway.app deployment and logs |
| `vercel` | `br vercel` | Vercel deployment and previews |
| `vercel-pro` | `br vercel-pro` | Advanced Vercel management |
| `web-app` | `br web-app` | Web app scaffolding and management |
| `web-dev` | `br web-dev` | Local dev server management |
| `worker-bridge` | `br worker-bridge` | Cloudflare Worker bridge service |
| `workers` | `br workers` | Cloudflare Workers management |
| `worlds` | `br worlds` | Multi-world/environment management |

---

## ☁️ Cloud & Infrastructure (11 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `cloudflare` | `br cloudflare` | Cloudflare DNS, Workers, Pages |
| `ocean-droplets` | `br ocean` | DigitalOcean droplet management |
| `pi` | `br pi` | Raspberry Pi device management |
| `pi-domains` | `br pi-domains` | Pi-served domain management |
| `pi-fleet` | `br pi-fleet` | Raspberry Pi fleet orchestration |
| `pi-manager` | `br pi-manager` | Individual Pi configuration |
| `pi-monitor` | `br pi-monitor` | Pi health and resource monitoring |
| `ssh` | `br ssh` | SSH key and session management |
| `ssl-manager` | `br ssl` | SSL certificate management |
| `tunnel` | `br tunnel` | Cloudflare/ngrok tunnel management |
| `domains` | `br domains` | Domain registry and DNS management |

---

## 🔒 Security (11 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `audit` | `br audit` | Security audit runner |
| `audit-log` | `br audit-log` | Audit log viewer and exporter |
| `auth` | `br auth` | Authentication and token management |
| `compliance-scanner` | `br compliance` | Compliance policy scanner |
| `ip-audit` | `br ip-audit` | IP address and network audit |
| `scan` | `br scan` | Code and dependency vulnerability scan |
| `secret-rotation` | `br secret-rotation` | Automated secrets rotation |
| `secrets-vault` | `br vault` | Encrypted secrets vault (AES-256) |
| `security-hardening` | `br security-hardening` | System security hardening checks |
| `security-scanner` | `br security-scanner` | Full-stack security scanner |
| `wifi-scanner` | `br wifi` | WiFi network scanner |

---

## 🔧 Git & Code Quality (13 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `diff` | `br diff` | Enhanced git diff viewer |
| `format` | `br format` | Code formatter (multi-language) |
| `gen` | `br gen` | Code generation from templates |
| `git-ai` | `br git-ai` | AI-powered git commit messages |
| `git-graph` | `br git-graph` | Git history visualization |
| `git-integration` | `br git` | Smart git operations and patterns |
| `git-smart` | `br git-smart` | Smart branch and merge suggestions |
| `lint` | `br lint` | Multi-language linter runner |
| `pr-check` | `br pr` | Pull request checks and reviews |
| `repo-manager` | `br repo` | Repository management and sync |
| `review` | `br review` | AI-assisted code review |
| `tree` | `br tree` | Enhanced directory tree viewer |
| `org-sync` | `br org-sync` | Cross-org repository synchronization |

---

## 🗄️ Database (9 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `cache` | `br cache` | Redis/KV cache management |
| `db-browser` | `br db-browser` | Interactive SQLite/DB browser |
| `db-client` | `br db` | Universal database client |
| `db-migrate` | `br db-migrate` | Database migration runner |
| `kv` | `br kv` | Key-value store operations |
| `oracle` | `br oracle` | Oracle DB integration |
| `schema` | `br schema` | Database schema visualization |
| `snapshot` | `br snapshot` | Database snapshot and restore |
| `smart-search` | `br smart-search` | AI-powered code/data search |

---

## 📊 Monitoring & Observability (16 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `analytics` | `br analytics` | Platform analytics dashboard |
| `dashboard` | `br dashboard` | Unified monitoring dashboard |
| `health-check` | `br health` | Service health check runner |
| `health-cron` | `br health-cron` | Scheduled health check cron |
| `log-parser` | `br log-parser` | Log parsing and filtering |
| `log-tail` | `br log-tail` | Real-time log tailing |
| `logs` | `br logs` | Multi-service log aggregator |
| `logs-cf` | `br logs-cf` | Cloudflare Worker log tailing |
| `metrics-dashboard` | `br metrics` | Metrics collection and display |
| `perf-monitor` | `br perf` | Performance monitoring |
| `pulse` | `br pulse` | System pulse/heartbeat monitor |
| `status-all` | `br status` | All-services status overview |
| `status-live` | `br status-live` | Live real-time status feed |
| `trace` | `br trace` | Distributed tracing viewer |
| `trace-http` | `br trace-http` | HTTP request tracing |
| `watch` | `br watch` | File/service watcher |

---

## 🛠️ Developer Tools (20 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `alias` | `br alias` | Shell alias management |
| `api-tester` | `br api` | HTTP API testing and history |
| `bench` | `br bench` | Performance benchmarking |
| `brand` | `br brand` | Brand asset management |
| `broadcast` | `br broadcast` | Multi-channel message broadcast |
| `collab` | `br collab` | Team collaboration tools |
| `context` | `br context` | Project context management |
| `context-radar` | `br radar` | AI context radar and suggestions |
| `docs` | `br docs` | Documentation generator |
| `edu` | `br edu` | Developer education resources |
| `email` | `br email` | Email notification sender |
| `file-finder` | `br find` | Advanced file search |
| `flow` | `br flow` | Workflow visualization |
| `gateway` | `br gateway` | API gateway management |
| `geb` | `br geb` | Code snippet grabber/executor |
| `journal` | `br journal` | Developer journal (daily logs) |
| `mail` | `br mail` | Mail integration |
| `mock` | `br mock` | Mock data generator |
| `mock-server` | `br mock-server` | Mock HTTP server |
| `pdf-read` | `br pdf` | PDF reader and extractor |

---

## 📋 Project Management (17 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `cost` | `br cost` | Cloud cost tracking |
| `cron` | `br cron` | Cron job management |
| `org` | `br org` | Organization management |
| `org-audit` | `br org-audit` | Organization audit and reporting |
| `profile` | `br profile` | Developer profile management |
| `project-init` | `br init` | Project scaffolding and init |
| `quick-notes` | `br notes` | Quick developer notes |
| `report` | `br report` | Automated report generation |
| `roundup` | `br roundup` | Daily/weekly roundup |
| `schedule` | `br schedule` | Task scheduling |
| `session-manager` | `br session` | Workspace session management |
| `signal` | `br signal` | System signals and notifications |
| `standup` | `br standup` | Daily standup generator |
| `task-manager` | `br task` | Task management system |
| `task-runner` | `br run` | Task runner and executor |
| `template` | `br template` | Project and file templates |
| `timeline` | `br timeline` | Project timeline viewer |

---

## 🧪 Testing & QA (8 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `load-test` | `br load` | Load and stress testing |
| `rate` | `br rate` | Rate limiting and throttle testing |
| `replay` | `br replay` | Request replay and regression |
| `test-suite` | `br test` | Test suite runner with coverage |
| `trace` | `br trace` | Trace test execution |
| `trace-http` | `br trace-http` | HTTP trace testing |
| `verify` | `br verify` | System integrity verification |
| `web-monitor` | `br web-monitor` | Web endpoint monitoring |

---

## 🌐 Integrations & Misc (21 tools)

| Tool | Command | Description |
|------|---------|-------------|
| `cece-identity` | `br cece` | CECE portable AI identity system |
| `chain` | `br chain` | Blockchain/chain operations |
| `dependency-helper` | `br deps` | Dependency management and auditing |
| `deps-graph` | `br deps-graph` | Dependency graph visualization |
| `gov-api` | `br gov` | Government API integrations |
| `memory-api` | `br memory` | Agent memory API operations |
| `notify` | `br notify` | Multi-channel notifications |
| `notifications` | `br notifications` | Notification management |
| `ping` | `br ping` | Network ping and connectivity |
| `port` | `br port` | Port scanning and management |
| `queue-job` | `br queue` | Job queue management |
| `relay` | `br relay` | Message relay and forwarding |
| `snippet-manager` | `br snippet` | Code snippet library |
| `stripe` | `br stripe` | Stripe payments integration |
| `sync` | `br sync` | Cross-service data sync |
| `talk` | `br talk` | Agent-to-agent communication |
| `webhook-test` | `br webhook` | Webhook testing and inspection |
| `whoami` | `br whoami` | Identity and auth status |
| `world` | `br world` | 8-bit ASCII world generator |
| `provider` | `br provider` | AI provider switching |
| `web-monitor` | `br web-monitor` | External web monitoring |

---

## Stats

| Category | Count |
|----------|-------|
| AI & Agents | 16 |
| DevOps & Deployment | 22 |
| Cloud & Infrastructure | 11 |
| Security | 11 |
| Git & Code Quality | 13 |
| Database | 9 |
| Monitoring & Observability | 16 |
| Developer Tools | 20 |
| Project Management | 17 |
| Testing & QA | 8 |
| Integrations & Misc | 21 |
| **Total** | **164** |

---

*Last updated: 2026-02-24*
*All tools are `br` subcommands — see `br help` for full usage.*

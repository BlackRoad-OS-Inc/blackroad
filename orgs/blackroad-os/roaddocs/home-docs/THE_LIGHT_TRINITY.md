# 🚦 THE LIGHT TRINITY
## The Complete Visual Language of BlackRoad OS
### 🟢 GreenLight · 🟡 YellowLight · 🔴 RedLight
**Version 1.0 — December 23, 2025**

---

## **THE TRINITY**

```
          🟢 GREENLIGHT
       Project Management
    Tasks · Workflows · States
              ↓
        Coordinates
              ↓
    ┌─────────┴─────────┐
    ↓                   ↓
🟡 YELLOWLIGHT    🔴 REDLIGHT
Infrastructure     Templates
Repos · Deploys    Worlds · Sites
    └─────────┬─────────┘
              ↓
         Integrates
              ↓
    🛣️ BLACKROAD CODEX
   PS-SHA∞ Memory System
```

**The Trinity:**
- **🟢 GreenLight** = What we're building (project management)
- **🟡 YellowLight** = How we're deploying it (infrastructure)
- **🔴 RedLight** = What users see (visual experiences)

Together: **The complete development stack.** 🛣️

---

## **QUICK REFERENCE**

| Light | Focus | Emoji Dictionary | Memory Templates | Key Domains |
|-------|-------|------------------|------------------|-------------|
| 🟢 **Green** | Project Mgmt | 429 emojis, 20 categories | `memory-greenlight-templates.sh` | Tasks, workflows, billing, AI, Linear, Slack |
| 🟡 **Yellow** | Infrastructure | Platform-specific | `memory-yellowlight-templates.sh` | Repos, connectors, deployments, CI/CD |
| 🔴 **Red** | Templates | Category-specific | `memory-redlight-templates.sh` | Worlds, websites, animations, design |

---

## **🟢 GREENLIGHT: PROJECT MANAGEMENT**

### Purpose
Track the **state and progress** of everything in BlackRoad OS.

### Core Concepts
- **Lifecycle States**: 15 states from ⬛ void → ✅ done
- **Scale Indicators**: 👉 micro → 🌌 universal
- **Domain Tags**: 18 domains (🛣️ platform, 🌀 ai, ⛓️ chain, etc.)
- **Priority Levels**: 🔥 p0 → 🧊 p5
- **Effort Sizing**: 🫧 trivial → 🌍 colossal

### Key Features
- **Emoji-based states** (no Jira, no Asana, no Salesforce)
- **NATS subject patterns** (`greenlight.{state}.{scale}.{domain}.{id}`)
- **Database-backed** (PostgreSQL enums and tables)
- **Memory integration** (all actions logged to PS-SHA∞)

### Example
```bash
# Create GreenLight task
source ~/memory-greenlight-templates.sh

gl_feature \
    "RedLight Earth template" \
    "Interactive 3D globe with cities and networks" \
    "🍖" \
    "⭐"

# Update state
gl_wip \
    "earth-template" \
    "Adding biome layers" \
    "🌸" \
    "👉"

# Complete phase
gl_phase_done \
    "implementation" \
    "Earth Template" \
    "All features complete, 60 FPS, deployed to earth.blackroad.io" \
    "🌌"
```

### Files
- `~/GREENLIGHT_EMOJI_DICTIONARY.md` (429 lines, complete reference)
- `~/GREENLIGHT_CLAUDE_QUICK_REFERENCE.md` (quick start)
- `~/GREENLIGHT_CICD_INFRASTRUCTURE_EXTENSION.md` (CI/CD integration)
- `~/GREENLIGHT_BILLING_EXTENSION.md` (Stripe integration)
- `~/GREENLIGHT_AI_EXTENSION.md` (HuggingFace integration)
- `~/GREENLIGHT_LINEAR_EXTENSION.md` (Linear integration)
- `~/GREENLIGHT_SLACK_EXTENSION.md` (Slack integration)
- `~/memory-greenlight-templates.sh` (1200 lines, all templates)
- `~/greenlight-deploy.sh` (deployment automation)
- `~/greenlight-status.sh` (live dashboard)

---

## **🟡 YELLOWLIGHT: INFRASTRUCTURE**

### Purpose
Manage the **infrastructure backbone** of BlackRoad OS.

### Core Concepts
- **Repositories**: GitHub orgs, repos, branches, PRs
- **Connectors**: APIs, webhooks, integrations (GitHub, Stripe, Linear, Slack, HuggingFace, etc.)
- **Deployments**: Cloudflare, Railway, DigitalOcean, Raspberry Pi
- **CI/CD**: GitHub Actions, automated workflows
- **Health Monitoring**: Health checks, alerts, recovery

### Key Features
- **Multi-platform support** (☁️ Cloudflare, 🚂 Railway, 🥧 Pi, 🌊 DigitalOcean)
- **Connector patterns** (webhook validation, API calls, event publishing)
- **Deployment tracking** (version, platform, environment, status)
- **Integration with GreenLight** (all deployments logged as tasks)

### Example
```bash
# Deploy API to Railway
source ~/memory-yellowlight-templates.sh

yl_deployment_succeeded \
    "blackroad-api" \
    "railway" \
    "https://blackroad-api.railway.app" \
    "1.2.3" \
    "production"

# Configure integration
yl_integration_configured \
    "stripe" \
    "blackroad-api" \
    "webhook" \
    "Billing events → api.blackroad.io/webhooks/stripe"

# Health check
yl_health_check \
    "api.blackroad.io" \
    "https://api.blackroad.io/health" \
    "120"
```

### Files
- `~/YELLOWLIGHT_INFRASTRUCTURE_SYSTEM.md` (complete reference)
- `~/memory-yellowlight-templates.sh` (all infrastructure templates)

### Current Infrastructure
**GitHub:**
- 15 organizations
- 66+ repositories
- Active orgs: BlackRoad-OS, blackboxprogramming, schematiq

**Cloudflare:**
- 16 zones (domains)
- 8 Pages projects
- 8 KV namespaces
- 1 D1 database
- Cloudflare Tunnel (codex-infinity)

**Railway:**
- 12+ projects
- Postgres, Redis, web services

**Servers:**
- DigitalOcean: 159.65.43.12 (codex-infinity)
- Raspberry Pi: 192.168.4.38 (lucidia)
- Raspberry Pi: 192.168.4.64 (blackroad-pi)
- Raspberry Pi: 192.168.4.99 (lucidia alternate)
- iPhone Koder: 192.168.4.68:8080

**APIs:**
- Anthropic (Claude), OpenAI (GPT), Google (Gemini), xAI (Grok)
- Stripe (billing), GitHub, Linear, Slack, HuggingFace

---

## **🔴 REDLIGHT: TEMPLATES**

### Purpose
Provide **visual templates** for worlds, websites, and experiences.

### Core Concepts
- **World Templates**: Interactive 3D environments (Three.js)
- **Website Templates**: Landing pages, dashboards, apps
- **Animation Templates**: Motion graphics, visual effects
- **Design Systems**: Schematiq components, themes

### Key Features
- **Self-contained** (single HTML files)
- **Three.js powered** (3D worlds and animations)
- **BlackRoad branded** (gradient: #FF9D00 → #0066FF)
- **Deploy-ready** (Cloudflare Pages, GitHub Pages, Railway)

### Template Categories
**Worlds (13 templates):**
- `blackroad-earth.html` - Global network visualization
- `blackroad-earth-biomes.html` - Living Earth with climate zones
- `blackroad-earth-game.html` - Interactive Earth game
- `blackroad-living-planet.html` - Animated living planet
- `blackroad-metaverse.html` - Metaverse environment
- `blackroad-world-template.html` - Base starter

**Animations (4 templates):**
- `blackroad-animation.html` - Animation system
- `blackroad-motion.html` - Motion graphics
- `schematiq-animation.html` - Design system animations

**Websites (1 template):**
- `schematiq-page.html` - Schematiq design system

### Example
```bash
# Create template
source ~/memory-redlight-templates.sh

rl_template_create \
    "blackroad-mars" \
    "world" \
    "Interactive Mars globe with rover missions"

# Deploy template
rl_template_deploy \
    "blackroad-mars" \
    "https://mars.blackroad.io" \
    "cloudflare"

# Add world features
rl_biome_add \
    "blackroad-mars" \
    "olympus-mons" \
    "Tallest volcano in solar system, 21km elevation"

# Record performance
rl_performance_metrics \
    "blackroad-mars" \
    "60" \
    "1.5" \
    "220"
```

### Files
- `~/REDLIGHT_TEMPLATE_SYSTEM.md` (complete reference)
- `~/memory-redlight-templates.sh` (all template management)
- `/tmp/*.html` (18 template files extracted from files.zip)

---

## **INTEGRATION PATTERNS**

### Cross-Light Coordination

```bash
# 1. Create GreenLight task
source ~/memory-greenlight-templates.sh
gl_feature \
    "Deploy Mars Template" \
    "Create and deploy interactive Mars world" \
    "🍖" "⭐"

# 2. Create RedLight template
source ~/memory-redlight-templates.sh
rl_template_create \
    "blackroad-mars" \
    "world" \
    "Interactive Mars with rover missions"

# 3. Deploy via YellowLight
source ~/memory-yellowlight-templates.sh
yl_pages_deploy \
    "blackroad-mars" \
    "https://mars.blackroad.io" \
    "abc123"

# 4. Update GreenLight
gl_phase_done \
    "deployment" \
    "Mars Template" \
    "Template live at mars.blackroad.io" \
    "🌌"
```

### Memory System Integration

All three Lights log to the **PS-SHA∞ memory system**:

```bash
~/memory-system.sh summary

# Shows entries from:
# - GreenLight (tasks, phases, coordination)
# - YellowLight (deployments, integrations, health)
# - RedLight (templates, features, analytics)
```

### NATS Event Bus

```
# GreenLight publishes
greenlight.wip.micro.creative.mars-template

# YellowLight publishes
yellowlight.deployment.cloudflare.succeeded

# RedLight publishes
redlight.world.mars.deployed

# All subscribe to each other's events
```

---

## **DATABASE SCHEMA**

### GreenLight Tables
```sql
greenlight_items (tasks, issues, epics)
greenlight_states (lifecycle tracking)
greenlight_assignments (ownership)
greenlight_tags (domain, priority, effort)
```

### YellowLight Tables
```sql
yellowlight_repos (GitHub repositories)
yellowlight_connectors (API integrations)
yellowlight_deployments (service deployments)
yellowlight_integrations (cross-service connections)
yellowlight_workflows (CI/CD pipelines)
```

### RedLight Tables
```sql
redlight_templates (template metadata)
redlight_deployments (template deployments)
redlight_analytics (usage metrics)
```

---

## **CLI COMMANDS**

### GreenLight
```bash
source ~/memory-greenlight-templates.sh
gl_announce <agent> <project> <tasks> <goal>
gl_progress <agent> <completed> <next>
gl_deploy <service> <url> <details>
gl_phase_done <phase> <project> <summary>
```

### YellowLight
```bash
source ~/memory-yellowlight-templates.sh
yl_deployment_succeeded <service> <platform> <url>
yl_integration_configured <service_a> <service_b> <type>
yl_health_check <service> <url>
yl_workflow_done <repo> <result> <duration>
```

### RedLight
```bash
source ~/memory-redlight-templates.sh
rl_template_create <name> <category> <description>
rl_template_deploy <name> <url> <platform>
rl_biome_add <world> <biome> <properties>
rl_performance_metrics <name> <fps> <load_time>
```

---

## **VISUAL SUMMARY**

```
🟢 GREENLIGHT
├── 📋 Tasks (inbox → wip → done)
├── 🎯 Projects (phases: discovery → deployment)
├── 👥 Assignments (human, agent, team)
├── 🔥 Priorities (p0 → p5)
└── 🌍 Domains (platform, ai, chain, etc.)

🟡 YELLOWLIGHT
├── 🐙 Repos (GitHub orgs, PRs, branches)
├── 🔌 Connectors (APIs, webhooks, WebSockets)
├── 🚀 Deployments (Cloudflare, Railway, Pi)
├── 🧪 CI/CD (GitHub Actions, workflows)
└── 💚 Health (checks, alerts, recovery)

🔴 REDLIGHT
├── 🌍 Worlds (18 templates: Earth, Mars, metaverse)
├── ✨ Animations (motion, particles, shaders)
├── 🌐 Websites (Schematiq, landing pages)
├── 🎨 Design (components, themes, brand)
└── 📊 Analytics (views, FPS, sessions)
```

---

## **THE COLOR PALETTE**

All three Lights share the **BlackRoad gradient**:

```
#FF9D00  Amber    🟠
#FF6B00  Orange   🟠
#FF0066  Pink     🟥
#FF006B  Magenta  🟥
#D600AA  Purple   🟣
#7700FF  Violet   🟣
#0066FF  Blue     🔵
```

### Usage
- **🟢 GreenLight**: Lifecycle states, priority levels
- **🟡 YellowLight**: Platform tags, health indicators
- **🔴 RedLight**: Brand identity, glow effects, UI accents

---

## **WORKFLOW EXAMPLE: Earth to Mars**

```bash
# 1. GreenLight: Plan the project
source ~/memory-greenlight-templates.sh

gl_phase_start "planning" "Mars Template" \
    "Design Mars world based on Earth template" "🎢"

# 2. RedLight: Copy Earth template
source ~/memory-redlight-templates.sh

rl_template_copy \
    "blackroad-earth" \
    "blackroad-mars" \
    "Create Mars variant with red planet features"

# 3. RedLight: Add Mars-specific features
rl_biome_add "blackroad-mars" "polar-ice-cap" \
    "CO2 ice, seasonal variations"
rl_biome_add "blackroad-mars" "valles-marineris" \
    "Largest canyon in solar system"

# 4. GreenLight: Update progress
gl_progress "cece" "Mars template created with 5 biomes" \
    "Testing performance and deploying" "👉" "🎨"

# 5. YellowLight: Deploy to Cloudflare
source ~/memory-yellowlight-templates.sh

wrangler pages deploy blackroad-mars.html \
    --project-name=mars-blackroad

yl_pages_deploy \
    "blackroad-mars" \
    "https://mars.blackroad.io" \
    "v1.0.0"

# 6. RedLight: Log deployment
rl_template_deploy \
    "blackroad-mars" \
    "https://mars.blackroad.io" \
    "cloudflare"

# 7. GreenLight: Complete phase
gl_phase_done "deployment" "Mars Template" \
    "Deployed to mars.blackroad.io, 60 FPS, 5 biomes, rover missions" \
    "🌌"

# 8. Memory: Check history
~/memory-system.sh summary
```

---

## **STATUS: DEPLOYED**

### GreenLight ✅
- ✅ Emoji dictionary (429 emojis, 20 categories)
- ✅ Memory templates (1200 lines)
- ✅ Extensions (CI/CD, Billing, AI, Linear, Slack)
- ✅ Deploy automation (`greenlight-deploy.sh`)
- ✅ Status dashboard (`greenlight-status.sh`)

### YellowLight ✅
- ✅ Infrastructure documentation
- ✅ Memory templates (all platforms)
- ✅ Connector architecture
- ✅ Deployment patterns
- ✅ Health monitoring

### RedLight ✅
- ✅ Template system documentation
- ✅ Memory templates (all categories)
- ✅ 18 templates cataloged
- ✅ Brand colors defined
- ✅ Deployment patterns

### Integration ✅
- ✅ Cross-Light coordination
- ✅ Memory system integration
- ✅ NATS event bus
- ✅ Database schemas
- ✅ CLI commands unified

---

## **NEXT STEPS**

1. **Deploy RedLight templates** to Cloudflare Pages
2. **Integrate YellowLight** connectors (Stripe, Linear, Slack webhooks)
3. **Build GreenLight dashboard** (real-time state visualization)
4. **Create Trinity CLI** (unified command interface)
5. **Add to BlackRoad Codex** (integrate with verification suite)

---

## **THE VISION**

**Before the Trinity:**
- Jira for tasks ❌
- Manual deployments ❌
- Scattered templates ❌
- No unified memory ❌

**After the Trinity:**
- 🟢 GreenLight for everything (emoji-based, instant clarity)
- 🟡 YellowLight for infrastructure (automated, monitored)
- 🔴 RedLight for visuals (branded, deploy-ready)
- 🛣️ PS-SHA∞ for memory (immutable, verifiable)

**The Result:**
"Every action, deployment, and template is tracked, logged, and retrievable.
The road remembers everything." 🛣️

---

**Created:** December 23, 2025
**Author:** Cece + Alexa
**Version:** 1.0.0
**Status:** 🎯 CANONICAL

**Files Created:**
- `THE_LIGHT_TRINITY.md` (this document)
- `GREENLIGHT_EMOJI_DICTIONARY.md` (429 lines)
- `YELLOWLIGHT_INFRASTRUCTURE_SYSTEM.md` (complete reference)
- `REDLIGHT_TEMPLATE_SYSTEM.md` (complete reference)
- `memory-greenlight-templates.sh` (1200 lines)
- `memory-yellowlight-templates.sh` (infrastructure templates)
- `memory-redlight-templates.sh` (template management)

**Total Lines:** ~4000+ lines of documentation and automation

🟢🟡🔴 **The Trinity is complete.** 🛣️

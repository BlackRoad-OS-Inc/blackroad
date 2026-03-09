# 🎓 COMPLETE USAGE GUIDE - BlackRoad Coordination v2.0
**All 8 Systems - Production Ready!**
**Date:** 2026-01-07
**Status:** ✅ 100% COMPLETE

---

## 🚀 QUICK START (5 Minutes)

### 1. Set Your Agent ID
```bash
export MY_CLAUDE="claude-$(whoami)-$(date +%s)-$(openssl rand -hex 4)"
echo "export MY_CLAUDE=\"$MY_CLAUDE\"" >> ~/.bash_profile
echo "My Agent ID: $MY_CLAUDE"
```

### 2. Run Enhanced Session Init
```bash
~/claude-session-init-v2.sh
```
This checks ALL 8 systems and shows full infrastructure status!

### 3. Initialize & Index Everything
```bash
# Index all assets (GitHub, Cloudflare, Pi)
~/blackroad-universal-index.sh refresh

# Build knowledge graph
~/blackroad-knowledge-graph.sh build

# Index memory for semantic search
~/blackroad-semantic-memory.sh index-memory

# Import timeline data
~/blackroad-timeline.sh import-memory
```

**Done!** You're now connected to the full coordination system!

---

## 📚 SYSTEM-BY-SYSTEM USAGE GUIDE

### 1️⃣ [INDEX] - Universal Asset Indexer

**What it does:** Search across ALL 66 repos + 16 Cloudflare zones + 3 Pi systems instantly

**Common Commands:**
```bash
# Search everything
~/blackroad-universal-index.sh search "authentication"
~/blackroad-universal-index.sh search "api dashboard"

# List by type
~/blackroad-universal-index.sh list repos
~/blackroad-universal-index.sh list cloudflare
~/blackroad-universal-index.sh list pi

# Get stats
~/blackroad-universal-index.sh stats

# Refresh (run daily or after creating new assets)
~/blackroad-universal-index.sh refresh
```

**When to use:**
- ✅ Before creating anything new - search if it exists!
- ✅ Finding where something is deployed
- ✅ Discovering related projects
- ✅ Daily sync of infrastructure

**Example Workflow:**
```bash
# User asks: "Build a dashboard"
# You first check:
~/blackroad-universal-index.sh search "dashboard"
# Found 8 existing dashboards!
# Decision: Improve existing or identify gap
```

---

### 2️⃣ [GRAPH] - Knowledge Graph

**What it does:** Map dependencies, relationships, and impact of ALL components

**Common Commands:**
```bash
# What depends on this?
~/blackroad-knowledge-graph.sh depends-on "user-database"

# What does this require?
~/blackroad-knowledge-graph.sh required-by "api-gateway"

# Impact analysis (what breaks if I change this?)
~/blackroad-knowledge-graph.sh impacts "auth-service"

# See all connections
~/blackroad-knowledge-graph.sh connected-to "cloudflare-kv"

# Build/rebuild graph
~/blackroad-knowledge-graph.sh build

# Stats
~/blackroad-knowledge-graph.sh stats
```

**When to use:**
- ✅ Before changing ANY component
- ✅ Understanding system architecture
- ✅ Planning refactoring
- ✅ Debugging dependency issues

**Example Workflow:**
```bash
# Before changing database schema
~/blackroad-knowledge-graph.sh impacts "user-database"
# Shows: 12 components depend on this!
# Action: Plan migration carefully
```

---

### 3️⃣ [SEMANTIC] - Semantic Memory Search

**What it does:** Natural language search across all memory + code

**Common Commands:**
```bash
# Search with natural language
~/blackroad-semantic-memory.sh search "How did we handle rate limiting?"
~/blackroad-semantic-memory.sh search "authentication implementations"
~/blackroad-semantic-memory.sh search "cloudflare deployment issues"

# Summarize topic
~/blackroad-semantic-memory.sh summarize "api" last-week
~/blackroad-semantic-memory.sh summarize "deployment" today

# Index data (run after session init)
~/blackroad-semantic-memory.sh index-memory
~/blackroad-semantic-memory.sh index-code

# Stats
~/blackroad-semantic-memory.sh stats
```

**When to use:**
- ✅ "Have we done this before?"
- ✅ Learning from past implementations
- ✅ Finding similar code/solutions
- ✅ Understanding patterns

**Example Workflow:**
```bash
# Task: Implement caching
~/blackroad-semantic-memory.sh search "caching strategy"
# Found: 3 previous implementations with different approaches
# Action: Learn from past work
```

---

### 4️⃣ [HEALTH] - Infrastructure Monitor

**What it does:** Real-time health monitoring of GitHub, Cloudflare, Pi, Railway

**Common Commands:**
```bash
# Run full health check
~/blackroad-health-monitor.sh check

# Check current status
~/blackroad-health-monitor.sh status

# Check specific system
~/blackroad-health-monitor.sh github
~/blackroad-health-monitor.sh cloudflare
~/blackroad-health-monitor.sh pi

# View alerts
~/blackroad-health-monitor.sh alerts

# Start daemon (monitors every 5 minutes)
~/blackroad-health-monitor.sh daemon &

# Stop daemon
~/blackroad-health-monitor.sh stop
```

**When to use:**
- ✅ Before deploying
- ✅ After deploying (verify health)
- ✅ Debugging infrastructure issues
- ✅ Daily health checks

**Example Workflow:**
```bash
# Before deployment
~/blackroad-health-monitor.sh status
# All systems healthy ✓
# Deploy with confidence!
```

---

### 5️⃣ [CONFLICT] - Automatic Conflict Detector

**What it does:** Prevents Claude agents from working on same resources

**Common Commands:**
```bash
# BEFORE starting work - check for conflicts
~/blackroad-conflict-detector.sh check blackroad-os-dashboard

# Claim work on a resource
~/blackroad-conflict-detector.sh claim blackroad-os-dashboard "Adding authentication"

# See all active work
~/blackroad-conflict-detector.sh active

# See my claims
~/blackroad-conflict-detector.sh mine

# AFTER finishing - release claim
~/blackroad-conflict-detector.sh release blackroad-os-dashboard

# View conflict history
~/blackroad-conflict-detector.sh conflicts

# Clean up expired claims
~/blackroad-conflict-detector.sh cleanup
```

**When to use:**
- ✅ **CRITICAL:** ALWAYS before editing any repo!
- ✅ When starting any significant work
- ✅ Daily cleanup of expired claims

**Example Workflow:**
```bash
# Check before starting
~/blackroad-conflict-detector.sh check blackroad-os-api
# ⚠️  WARNING: apollo-1234 already working on this!
# Action: Coordinate or pick different task

# When clear:
~/blackroad-conflict-detector.sh claim blackroad-os-api "Add rate limiting"
# ✓ Claimed successfully
# ... do work ...
~/blackroad-conflict-detector.sh release blackroad-os-api
# ✓ Released
```

---

### 6️⃣ [ROUTER] - Intelligent Work Router

**What it does:** Routes tasks to best-suited Claude agents based on skills

**Common Commands:**
```bash
# Register yourself with skills
~/blackroad-work-router.sh register "Your Name" "python,api,cloudflare,docker"

# Update your status
~/blackroad-work-router.sh status available
~/blackroad-work-router.sh status busy
~/blackroad-work-router.sh status offline

# Create task (auto-routes to best agent)
~/blackroad-work-router.sh create-task \
    "Build API endpoint" \
    "FastAPI endpoint for user auth" \
    "python,fastapi,api" \
    "high"

# View your assigned tasks
~/blackroad-work-router.sh my-tasks

# View all pending tasks
~/blackroad-work-router.sh list-tasks

# Mark task complete
~/blackroad-work-router.sh complete task-1234-abcd

# Stats
~/blackroad-work-router.sh stats
```

**When to use:**
- ✅ When you start a session (register skills)
- ✅ Creating tasks for others
- ✅ Finding best agent for a task
- ✅ Load balancing work

**Example Workflow:**
```bash
# Register on session start
export MY_CLAUDE="claude-alice-$(date +%s)"
~/blackroad-work-router.sh register "Alice" "python,fastapi,cloudflare"

# Create task
~/blackroad-work-router.sh create-task \
    "Deploy to Cloudflare" \
    "Deploy dashboard to Pages" \
    "cloudflare" \
    "high"
# → Auto-assigned to Alice (best match for cloudflare skill)!
```

---

### 7️⃣ [TIMELINE] - Universal Timeline

**What it does:** Single view of ALL activity (git, deployments, agents, memory)

**Common Commands:**
```bash
# View recent activity
~/blackroad-timeline.sh recent 24h
~/blackroad-timeline.sh recent week

# Filter by type
~/blackroad-timeline.sh filter git-commit
~/blackroad-timeline.sh filter deployment
~/blackroad-timeline.sh filter memory

# Search timeline
~/blackroad-timeline.sh search "authentication"
~/blackroad-timeline.sh search "cloudflare"

# Export timeline
~/blackroad-timeline.sh export 2026-01-01 2026-01-07 week1.json

# Import data
~/blackroad-timeline.sh import-memory
~/blackroad-timeline.sh import-git

# Stats
~/blackroad-timeline.sh stats
```

**When to use:**
- ✅ Understanding what happened
- ✅ Finding when something changed
- ✅ Debugging issues
- ✅ Team coordination

**Example Workflow:**
```bash
# "When did we last deploy?"
~/blackroad-timeline.sh filter deployment | head -5

# "What happened yesterday?"
~/blackroad-timeline.sh recent 24h

# "Who's been active this week?"
~/blackroad-timeline.sh recent week
```

---

### 8️⃣ [INTELLIGENCE] - Pattern Learning

**What it does:** Learns from successes/failures to suggest better approaches

**Common Commands:**
```bash
# Get suggestions for a task
~/blackroad-intelligence.sh suggest "Deploy API to Cloudflare Workers"
~/blackroad-intelligence.sh suggest "Add authentication to app"

# Learn from success
~/blackroad-intelligence.sh learn-success \
    "cloudflare-deployment" \
    "Test locally with wrangler dev first"

# Learn from failure
~/blackroad-intelligence.sh learn-failure \
    "merge-conflict" \
    "Two agents edited same file" \
    "Use conflict detector before starting"

# View insights
~/blackroad-intelligence.sh insights

# Analyze patterns
~/blackroad-intelligence.sh analyze
```

**When to use:**
- ✅ Before starting any task (get suggestions!)
- ✅ After completing task (log what worked)
- ✅ After failures (log lessons learned)
- ✅ Reviewing best practices

**Example Workflow:**
```bash
# Before task
~/blackroad-intelligence.sh suggest "API deployment"
# Shows: Best practices, common pitfalls, success patterns

# After success
~/blackroad-intelligence.sh learn-success \
    "api-deployment" \
    "Used health checks after deploy - caught issue immediately"

# After failure
~/blackroad-intelligence.sh learn-failure \
    "timeout" \
    "API timeout on large requests" \
    "Add pagination and request size limits"
```

---

## 🎯 DAILY WORKFLOWS

### Morning Routine (Every Claude Session)
```bash
# 1. Set agent ID
export MY_CLAUDE="claude-yourname-$(date +%s)"

# 2. Run session init
~/claude-session-init-v2.sh

# 3. Register in router
~/blackroad-work-router.sh register "Your Name" "your,skills,here"

# 4. Check for assigned tasks
~/blackroad-work-router.sh my-tasks

# 5. Check health
~/blackroad-health-monitor.sh status

# 6. Review active work (avoid conflicts)
~/blackroad-conflict-detector.sh active
```

### Before Starting Any Work
```bash
# 1. Search if it exists
~/blackroad-universal-index.sh search "<topic>"

# 2. Check for conflicts
~/blackroad-conflict-detector.sh check <repo-name>

# 3. Get AI suggestions
~/blackroad-intelligence.sh suggest "<task description>"

# 4. Check dependencies
~/blackroad-knowledge-graph.sh connected-to "<component>"

# 5. Claim work
~/blackroad-conflict-detector.sh claim <repo-name> "Task description"
```

### While Working
```bash
# Log progress to memory
~/memory-system.sh log updated "$MY_CLAUDE" "Progress update" "collaboration"

# Check health before deploy
~/blackroad-health-monitor.sh check
```

### After Completing Work
```bash
# 1. Release claim
~/blackroad-conflict-detector.sh release <repo-name>

# 2. Mark task complete
~/blackroad-work-router.sh complete task-id

# 3. Log completion
~/memory-system.sh log completed "$MY_CLAUDE" "Task description" "collaboration"

# 4. Log what worked
~/blackroad-intelligence.sh learn-success "<context>" "<solution>"

# 5. Refresh indexes
~/blackroad-universal-index.sh refresh
```

### End of Day
```bash
# Review activity
~/blackroad-timeline.sh recent today

# Check stats
~/blackroad-work-router.sh stats
~/blackroad-intelligence.sh insights

# Cleanup expired claims
~/blackroad-conflict-detector.sh cleanup
```

---

## 🚨 CRITICAL RULES FOR ALL CLAUDE INSTANCES

### Rule 1: ALWAYS Check for Conflicts
```bash
# BEFORE editing ANY file/repo
~/blackroad-conflict-detector.sh check <repo-name>
```
**Why:** Prevents merge conflicts and duplicate work

### Rule 2: ALWAYS Search Before Creating
```bash
# BEFORE creating anything new
~/blackroad-universal-index.sh search "<topic>"
```
**Why:** Avoid reinventing the wheel

### Rule 3: ALWAYS Log to Memory
```bash
# Log ALL significant work
~/memory-system.sh log <action> "$MY_CLAUDE" "Description" "tags"
```
**Why:** Other Claudes need to know what you did

### Rule 4: ALWAYS Get Suggestions
```bash
# BEFORE starting complex tasks
~/blackroad-intelligence.sh suggest "<task>"
```
**Why:** Learn from past successes/failures

### Rule 5: ALWAYS Update Status
```bash
# Update your router status
~/blackroad-work-router.sh status busy  # when working
~/blackroad-work-router.sh status available  # when free
```
**Why:** Enables proper load balancing

---

## 📊 MONITORING & MAINTENANCE

### Daily (Automated - Run Daemon)
```bash
# Start health monitoring daemon
~/blackroad-health-monitor.sh daemon &
```

### Weekly
```bash
# Refresh all indexes
~/blackroad-universal-index.sh refresh
~/blackroad-knowledge-graph.sh build
~/blackroad-semantic-memory.sh index-memory
~/blackroad-timeline.sh import-memory
~/blackroad-timeline.sh import-git

# Review insights
~/blackroad-intelligence.sh insights

# Cleanup
~/blackroad-conflict-detector.sh cleanup
```

### When Things Go Wrong
```bash
# Check health
~/blackroad-health-monitor.sh status
~/blackroad-health-monitor.sh alerts

# Check timeline for what changed
~/blackroad-timeline.sh recent 24h

# Check for conflicts
~/blackroad-conflict-detector.sh conflicts

# Search for similar issues
~/blackroad-semantic-memory.sh search "<error message>"
```

---

## 🎓 ADVANCED USAGE

### Skill-Based Task Routing
```bash
# Create specialized agents
~/blackroad-work-router.sh register "API Specialist" "python,fastapi,api"
~/blackroad-work-router.sh register "Frontend Expert" "react,typescript,ui"
~/blackroad-work-router.sh register "DevOps Pro" "docker,k8s,cloudflare"

# Tasks auto-route to best match!
```

### Pattern Learning Loop
```bash
# 1. Get suggestions
~/blackroad-intelligence.sh suggest "API caching"

# 2. Implement solution

# 3. If it works
~/blackroad-intelligence.sh learn-success "api-caching" "Used Redis with 1h TTL"

# 4. If it fails
~/blackroad-intelligence.sh learn-failure "cache-miss" "Redis timeout" "Added fallback to DB"

# 5. Future Claudes get these insights automatically!
```

### Cross-System Queries
```bash
# "Show me all authentication work in last week"
~/blackroad-timeline.sh search "auth" | grep "2026-01"
~/blackroad-semantic-memory.sh search "authentication"
~/blackroad-universal-index.sh search "auth"

# Combine results for full picture!
```

---

## 🎯 SUCCESS METRICS

Track your improvement:
```bash
# Check your stats
~/blackroad-work-router.sh stats  # Your task completion
~/blackroad-conflict-detector.sh mine  # Your active claims
~/blackroad-timeline.sh filter agent-work  # Your activity

# System-wide health
~/blackroad-health-monitor.sh status
~/blackroad-universal-index.sh stats
~/blackroad-intelligence.sh insights
```

---

## 📖 HELP & TROUBLESHOOTING

Every system has built-in help:
```bash
~/blackroad-universal-index.sh help
~/blackroad-knowledge-graph.sh help
~/blackroad-semantic-memory.sh help
~/blackroad-health-monitor.sh help
~/blackroad-conflict-detector.sh help
~/blackroad-work-router.sh help
~/blackroad-timeline.sh help
~/blackroad-intelligence.sh help
```

Common issues:
- **"Database not found"** → Run `init` command for that system
- **"Command not found"** → Check file is executable (`chmod +x ~/blackroad-*.sh`)
- **"No MY_CLAUDE set"** → Export your agent ID
- **"No results"** → Run refresh/import commands first

---

## 🌟 BEST PRACTICES

1. **Start every session with** `~/claude-session-init-v2.sh`
2. **Search before creating** anything new
3. **Check for conflicts** before editing files
4. **Log to memory** frequently
5. **Learn from** successes and failures
6. **Keep systems updated** (weekly refresh)
7. **Monitor health** regularly
8. **Coordinate with** other Claude instances

---

## 🚀 WHAT THIS ENABLES

✅ **Zero duplicate work** - Search shows what exists
✅ **Zero conflicts** - Automatic detection prevents overlap
✅ **Full visibility** - See all 66 repos + 16 zones + 3 Pi
✅ **Smart routing** - Tasks go to best-suited agent
✅ **Learning system** - Gets smarter over time
✅ **Real-time health** - Know status of all infrastructure
✅ **Complete timeline** - Understand what happened when
✅ **Dependency awareness** - Know impact before changes

---

**Created:** 2026-01-07
**Status:** ✅ Production Ready
**All 8 Systems:** ✅ Operational

🌌 **BlackRoad Coordination v2.0 - Infinite Claude Collaboration** 🌌

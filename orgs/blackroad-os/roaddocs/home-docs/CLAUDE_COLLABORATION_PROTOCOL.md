# 🤝 Claude Collaboration Protocol

**IMPORTANT: Every Claude agent working on BlackRoad infrastructure MUST follow this protocol.**

## 📋 Protocol Overview

When you start working as a Claude agent:

1. **Register yourself** in memory
2. **Check [MEMORY] & [CODEX]** before starting
3. **Announce what you're working on** with numbered steps
4. **Check memory & codex every 60 seconds**
5. **Coordinate** if your work overlaps with another Claude
6. **Update progress** regularly so others can follow along

**KEY RULE:** Always check **[MEMORY]** for coordination and **[CODEX]** for existing code before building anything!

---

## ✅ Required Actions on Startup

### 1. Register Your Instance

```bash
# Register yourself with a descriptive name
MY_CLAUDE=$(~/memory-sync-daemon.sh register "claude-$(date +%s)-[your-focus-area]")

# Example:
MY_CLAUDE=$(~/memory-sync-daemon.sh register "claude-infrastructure")
MY_CLAUDE=$(~/memory-sync-daemon.sh register "claude-frontend")
MY_CLAUDE=$(~/memory-sync-daemon.sh register "claude-database")
```

### 2. Check [MEMORY] & [CODEX] First!

**BEFORE writing ANY code, check both:**

```bash
# [MEMORY] Check what other Claudes are doing
~/memory-realtime-context.sh live $MY_CLAUDE compact

# [CODEX] Search for existing solutions (8,789 components!)
python3 ~/blackroad-codex-search.py "authentication"
python3 ~/blackroad-codex-search.py "database connection"
python3 ~/blackroad-codex-search.py "api endpoint"

# [CODEX] View component breakdown
python3 ~/blackroad-codex-scraping-dashboard.py
```

**Why?**
- **[MEMORY]** tells you what other Claudes are doing (avoid conflicts!)
- **[CODEX]** shows you 8,789 existing components (don't rebuild!)

**The Golden Rule:** If [CODEX] has it, USE IT. If [MEMORY] shows a conflict, COORDINATE.

### 3. Announce Your Work (After Checking [MEMORY] & [CODEX]!)

**🛣️ NEW: Use GreenLight Templates!**

```bash
# Load GreenLight templates
source ~/memory-greenlight-templates.sh

# Announce with GreenLight tags
gl_announce "[your-name]" "[PROJECT]" "[1) Task 2) Task 3) Task...]" "[BIG GOAL]" "[scale]" "[domain]" "[priority]"

# Example:
gl_announce "claude-api" "FastAPI Deployment" "1) Setup 2) Database 3) Auth 4) Deploy" "BlackRoad SaaS Backend" "🎢" "🔧" "⭐"
```

**Traditional Template (still works):**
```bash
~/memory-system.sh log announce "[your-name]" "
Hey team! I'm here to help. I'm working on: [PROJECT/GOAL]

My tasks:
1. [Task 1]
2. [Task 2]
3. [Task 3]
4. [Task 4]
5. [Task 5]

This relates to: [BIG IDEA/GOAL]

I will check memory every 60 seconds and coordinate with other Claudes.
Please let me know if this overlaps with your work!

Instance: $MY_CLAUDE
"
```

**Real Example:**
```bash
~/memory-system.sh log announce "claude-api-deployment" "
Hey team! I'm here to help. I'm working on: API Infrastructure Deployment

My tasks:
1. Deploy FastAPI backend to api.blackroad.io
2. Configure PostgreSQL database with connection pooling
3. Set up Redis cache for session management
4. Implement OAuth2 + JWT authentication
5. Deploy to Cloudflare Workers

This relates to: Building BlackRoad OS SaaS platform with multi-tenant architecture

I will check memory every 60 seconds and coordinate with other Claudes.
Please let me know if this overlaps with your work!

Instance: claude-api-1703456789
"
```

### 3. Check Memory Every 60 Seconds

**Set up automatic checking:**

```bash
# Option 1: Manual check every minute
while true; do
    clear
    echo "=== MEMORY CHECK ($(date +%H:%M:%S)) ==="
    ~/memory-realtime-context.sh live $MY_CLAUDE compact
    sleep 60
done
```

**Option 2: Add to your workflow**

Every minute while working, run:
```bash
~/memory-realtime-context.sh live $MY_CLAUDE compact
```

Look for:
- Other Claudes announcing work
- Tasks that overlap with yours
- Decisions that affect your work
- Deployments you depend on

### 4. Update Your Progress Regularly

**Every time you complete a task:**

```bash
~/memory-system.sh log progress "[your-name]" "✅ Completed: [task]. Next: [next-task]"
```

**Examples:**
```bash
~/memory-system.sh log progress "claude-api" "✅ Completed: FastAPI deployed to api.blackroad.io. Next: PostgreSQL setup"

~/memory-system.sh log progress "claude-frontend" "✅ Completed: React components for auth. Next: Integrate with api.blackroad.io"

~/memory-system.sh log progress "claude-database" "✅ Completed: PostgreSQL schema migrations. Next: Connection pooling config"
```

### 5. Coordinate When Overlaps Detected

**If you see another Claude working on related tasks:**

```bash
~/memory-system.sh log coordinate "[your-name]" "
@claude-[other-name]: I see you're working on [X].
I'm working on [Y] which depends on/relates to your work.

Suggestion: [how to coordinate]
Can we sync on: [specific integration point]?
"
```

**Example:**
```bash
~/memory-system.sh log coordinate "claude-frontend" "
@claude-api: I see you're deploying the API to api.blackroad.io.
I'm building the React frontend that will consume your API.

Suggestion: Can you log the API endpoint URLs and auth flow when ready?
Can we sync on: OAuth2 redirect URLs and CORS settings?
"
```

---

## 📊 Memory Check Format

When you check memory, look for these action types:

| Action | Meaning | What to Do |
|--------|---------|------------|
| `announce` | Another Claude started working | Check if work overlaps |
| `progress` | Another Claude completed a task | See if you can build on it |
| `deployed` | Infrastructure is live | Check if you depend on it |
| `decided` | Architecture decision made | Align your work with it |
| `configured` | Service configured | Use these settings |
| `coordinate` | Claude wants to sync with you | Respond with your status |
| `blocked` | Claude is stuck | See if you can help |

---

## 🚨 Critical Rules

### DO:
✅ **Announce your work** when you start
✅ **Check memory every 60 seconds** while working
✅ **Update progress** after each task
✅ **Coordinate** when you see overlapping work
✅ **Log decisions** that affect other Claudes
✅ **Share URLs, ports, credentials** (in memory)
✅ **Ask for help** if blocked

### DON'T:
❌ **Start working** without announcing
❌ **Ignore memory** for more than 60 seconds
❌ **Deploy** without checking if another Claude is working on same service
❌ **Make decisions** without logging them
❌ **Assume** - always check what others are doing
❌ **Work in isolation** - we're a team!

---

## 🎯 Example Session: 3 Claudes Coordinating

### Claude 1 (API):
```bash
~/memory-system.sh log announce "claude-api" "Working on: API deployment. Tasks: 1. FastAPI setup 2. Database 3. Auth 4. Deploy. Goal: BlackRoad SaaS backend. Checking memory every 60s."

# ... 2 minutes later ...
~/memory-system.sh log progress "claude-api" "✅ FastAPI running on localhost:8000. Next: Database setup"

# ... checks memory, sees Claude 2 working on frontend ...
~/memory-system.sh log coordinate "claude-api" "@claude-frontend: API will be at api.blackroad.io. OAuth redirect: /auth/callback. Need your frontend URL for CORS."
```

### Claude 2 (Frontend):
```bash
~/memory-system.sh log announce "claude-frontend" "Working on: React frontend. Tasks: 1. Auth UI 2. API integration 3. State mgmt 4. Deploy. Goal: BlackRoad SaaS web app. Checking memory every 60s."

# ... checks memory, sees Claude 1's API endpoint ...
~/memory-system.sh log coordinate "claude-frontend" "@claude-api: Frontend will be at app.blackroad.io. Setting CORS origin. OAuth redirect confirmed: /auth/callback"

# ... 3 minutes later ...
~/memory-system.sh log progress "claude-frontend" "✅ Auth UI complete, integrated with api.blackroad.io/auth. Next: Dashboard components"
```

### Claude 3 (Database):
```bash
~/memory-system.sh log announce "claude-database" "Working on: PostgreSQL setup. Tasks: 1. Schema 2. Migrations 3. Indexes 4. Backup. Goal: BlackRoad SaaS data layer. Checking memory every 60s."

# ... checks memory, sees Claude 1 needs database ...
~/memory-system.sh log coordinate "claude-database" "@claude-api: Database ready at postgres.blackroad.io:5432. Connection string in DM. Schema: users, workspaces, sessions."

# ... sees Claude 2's progress ...
~/memory-system.sh log progress "claude-database" "✅ Schema migrated. Added indexes for user lookup. Next: Connection pooling (pgBouncer)"
```

**Result:** All 3 Claudes work in harmony, no duplicate effort, perfect coordination!

---

## 🔄 Continuous Coordination Loop

```
┌─────────────────────────────────────────────────────────┐
│  1. Check Memory (every 60s)                            │
│     ↓                                                    │
│  2. See what other Claudes are doing                    │
│     ↓                                                    │
│  3. Adjust your plan if needed                          │
│     ↓                                                    │
│  4. Work on your task                                   │
│     ↓                                                    │
│  5. Log your progress                                   │
│     ↓                                                    │
│  6. Coordinate if overlaps detected                     │
│     ↓                                                    │
│  └──────────────────────── REPEAT ─────────────────────┘
```

---

## 📝 Quick Reference Commands

```bash
# Start daemon (if not running)
~/memory-sync-daemon.sh start

# Register yourself
MY_CLAUDE=$(~/memory-sync-daemon.sh register "claude-[focus]")

# Announce work
~/memory-system.sh log announce "$MY_CLAUDE" "[announcement text]"

# Check memory (every 60s!)
~/memory-realtime-context.sh live $MY_CLAUDE compact

# Log progress
~/memory-system.sh log progress "$MY_CLAUDE" "[progress update]"

# Coordinate with another Claude
~/memory-system.sh log coordinate "$MY_CLAUDE" "@claude-other: [message]"

# Log decision
~/memory-system.sh log decided "[topic]" "[decision and rationale]"

# Log deployment
~/memory-system.sh log deployed "[service]" "[URL, port, details]"

# Ask for help
~/memory-system.sh log blocked "$MY_CLAUDE" "Stuck on: [issue]. Need help with: [specific problem]"
```

---

## 🎓 Training Example

**You are Claude-NewAgent. Follow this protocol:**

```bash
# Step 1: Register
MY_CLAUDE=$(~/memory-sync-daemon.sh register "claude-newagent-$(date +%s)")

# Step 2: Check what's happening
~/memory-realtime-context.sh live $MY_CLAUDE compact

# Step 3: Announce yourself
~/memory-system.sh log announce "claude-newagent" "
Hey team! I'm here to help. I'm working on: Learning the BlackRoad memory system

My tasks:
1. Read all documentation
2. Understand PS-SHA∞ hash chain
3. Practice logging actions
4. Coordinate with existing Claudes
5. Contribute to active projects

This relates to: Becoming an effective BlackRoad infrastructure agent

I will check memory every 60 seconds and coordinate with other Claudes.
Please let me know if this overlaps with your work!

Instance: $MY_CLAUDE
"

# Step 4: Set up 60-second check loop
while true; do
    clear
    echo "=== MEMORY CHECK ($(date +%H:%M:%S)) ==="
    ~/memory-realtime-context.sh live $MY_CLAUDE compact
    echo ""
    echo "Press Ctrl+C to stop checking"
    sleep 60
done
```

---

## 🏆 Success Metrics

You're following the protocol correctly if:

✅ Memory shows your announcement when you start
✅ You update progress at least every 5 minutes
✅ You've coordinated with at least 1 other Claude
✅ No duplicate deployments (you checked first!)
✅ All your decisions are logged
✅ Other Claudes reference your work
✅ You've helped another Claude (responded to coordination request)

---

## 🚀 Why This Matters

**Without coordination:**
- Claude A deploys API to port 8080
- Claude B deploys different API to port 8080 (conflict!)
- Claude C builds frontend, doesn't know which API to use
- Result: Chaos, wasted effort, broken integrations

**With coordination:**
- Claude A announces: "Deploying API to port 8080"
- Claude B sees it: "Great! I'll work on frontend integration"
- Claude C sees both: "I'll handle database, here's the connection string"
- Result: Perfect teamwork, no conflicts, fast delivery!

---

## 📚 See Also

- `REALTIME_MEMORY_SYSTEM.md` - Technical architecture
- `MEMORY_QUICKSTART.md` - Quick start guide
- `memory-system.sh` - Core memory commands
- `memory-realtime-context.sh` - Live context streaming

---

**Remember:**

> "We're not individual Claudes working alone.
>  We're a distributed Claude swarm working together.
>  Memory is how we stay synchronized."

**Check memory every 60 seconds. Always.**

---

**Created:** 2025-12-23
**Version:** 1.0.0
**Required:** All Claude agents working on BlackRoad infrastructure

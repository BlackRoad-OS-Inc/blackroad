# Claude Session Initialization Guide

## Overview
Every Claude session should automatically check all critical BlackRoad systems before starting work.

## Automatic Initialization

### Method 1: Add to your shell profile (RECOMMENDED)
Add this to `~/.zshrc` or `~/.bashrc`:

```bash
# Claude Session Auto-Init
export MY_CLAUDE="claude-$(whoami)-$(date +%s)"
alias claude-init='~/claude-session-init.sh'

# Optional: Auto-run on new terminal
# ~/claude-session-init.sh
```

### Method 2: Manual invocation
Run this at the start of each Claude session:

```bash
~/claude-session-init.sh
```

### Method 3: Claude Code integration
Add to `.claude/CLAUDE.md` in your project:

```markdown
## Session Initialization
Every Claude session MUST run initialization check:
- Run: `~/claude-session-init.sh`
- This checks: [MEMORY] [LIVE] [COLLABORATION] [CODEX] [GREENLIGHT] [TODOS]
```

## What Gets Checked

### 📝 [MEMORY] - Memory System
- Total memory entries
- Recent activity
- Last hash verification
- Current session context

### 📡 [LIVE] - Real-time Context
- Active session data
- Live collaboration feed
- Current working context

### 🤝 [COLLABORATION] - Active Agents
- Other Claude instances working
- Task assignments
- Active subscriptions
- Recent broadcasts

### 📚 [CODEX] - Code Repository
- Component count (8,789+)
- Verification status
- Available solutions

### 🚦 [TRAFFIC LIGHTS] - Project Status
- Green: Ready to deploy
- Yellow: Needs attention
- Red: Blocked/broken
- Migration statistics

### ✅ [TODOS] - Task Management
- Infinite todos system
- Task marketplace stats
- Available/claimed/completed counts

## The Golden Rule

Before starting ANY work:

1. ✅ Check [MEMORY] for coordination & conflicts
2. ✅ Check [CODEX] for existing solutions (might already exist!)
3. ✅ Check [COLLABORATION] for other active agents
4. ✅ Check [TRAFFIC LIGHTS] for project readiness
5. ✅ Update [MEMORY] with all significant work

## Quick Reference Commands

```bash
# Memory operations
~/memory-system.sh log updated <context> <message> <tags>
~/memory-system.sh summary

# Live context
~/memory-realtime-context.sh live $MY_CLAUDE compact

# Collaboration
~/memory-collaboration-dashboard.sh compact

# Codex search
~/blackroad-codex-verification-suite.sh search <term>

# Traffic lights
~/blackroad-traffic-light.sh list
~/blackroad-traffic-light.sh greenlight

# Todos
~/memory-infinite-todos.sh create <id> <title> <desc> <duration>
~/memory-infinite-todos.sh list

# Task marketplace
~/memory-task-marketplace.sh list
~/memory-task-marketplace.sh stats
```

## Environment Variables

```bash
# Set your Claude identifier (recommended)
export MY_CLAUDE="claude-$(whoami)-$(date +%s)"

# Or use a memorable name
export MY_CLAUDE="claude-quantum-architect"
```

## Integration with Claude Code

Claude Code instances should:

1. **On session start**: Run `~/claude-session-init.sh`
2. **Before major work**: Check relevant systems
3. **After completion**: Log to memory
4. **On conflicts**: Check collaboration dashboard

## Troubleshooting

### Script not found
```bash
chmod +x ~/claude-session-init.sh
```

### MY_CLAUDE not set
```bash
export MY_CLAUDE="claude-session-$(date +%s)"
```

### System tools missing
Check that these exist:
- `~/memory-system.sh`
- `~/memory-realtime-context.sh`
- `~/memory-collaboration-dashboard.sh`
- `~/blackroad-codex-verification-suite.sh`
- `~/blackroad-traffic-light.sh`
- `~/memory-infinite-todos.sh`
- `~/memory-task-marketplace.sh`

## Example Session Flow

```bash
# 1. Start session
$ ~/claude-session-init.sh

# 2. Check what's available
$ ~/memory-task-marketplace.sh list

# 3. Claim a task
$ ~/memory-task-marketplace.sh claim visual-docs-integration $MY_CLAUDE

# 4. Check for conflicts
$ ~/memory-collaboration-dashboard.sh compact

# 5. Search for existing solutions
$ ~/blackroad-codex-verification-suite.sh search "visual docs"

# 6. Work on task...

# 7. Log completion
$ ~/memory-system.sh log completed "$MY_CLAUDE" "Visual docs integration deployed" "integration,docs"

# 8. Update task status
$ ~/memory-task-marketplace.sh complete visual-docs-integration
```

## Best Practices

1. **Always initialize**: Start every session with init check
2. **Set MY_CLAUDE**: Use consistent identifier per session
3. **Check before building**: Search CODEX first (avoid duplicate work)
4. **Log significant work**: Update memory for other agents
5. **Watch for conflicts**: Check collaboration dashboard regularly
6. **Update traffic lights**: Mark project status as you work

## Advanced: Auto-logging

Add to your workflow:

```bash
# Auto-log session start
~/memory-system.sh log created "$MY_CLAUDE" "Session started: $(date)" "session"

# Auto-log on exit (add to shell profile)
trap '~/memory-system.sh log ended "$MY_CLAUDE" "Session ended: $(date)" "session"' EXIT
```

---

**Created**: 2025-12-27
**Version**: 1.0
**Maintained by**: Alexa / BlackRoad Systems

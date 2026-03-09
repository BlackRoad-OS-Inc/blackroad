# 🚀 Real-Time Memory Quick Start

Get multiple Claude instances sharing memory in **under 60 seconds**.

## Installation (10 seconds)

```bash
# Make scripts executable (already done)
chmod +x ~/memory-system.sh ~/memory-sync-daemon.sh ~/memory-realtime-context.sh

# Initialize systems
~/memory-system.sh init
~/memory-sync-daemon.sh init
```

## Start Real-Time Sync (5 seconds)

```bash
# Start the daemon (1ms polling)
~/memory-sync-daemon.sh start

# Verify it's running
~/memory-sync-daemon.sh status
```

## Register Claude Instances (15 seconds)

```bash
# Terminal 1: Claude working on infrastructure
export CLAUDE_INFRA=$(~/memory-sync-daemon.sh register "claude-infrastructure")
echo "Instance ID: $CLAUDE_INFRA"

# Terminal 2: Claude working on code
export CLAUDE_CODE=$(~/memory-sync-daemon.sh register "claude-code")
echo "Instance ID: $CLAUDE_CODE"

# Terminal 3: Claude monitoring
export CLAUDE_MONITOR=$(~/memory-sync-daemon.sh register "claude-monitor")
echo "Instance ID: $CLAUDE_MONITOR"
```

## Use It (30 seconds)

### Terminal 1: Claude Infra logs deployments
```bash
~/memory-system.sh log deployed "app.blackroad.io" "Next.js on Cloudflare Pages"
~/memory-system.sh log configured "postgres" "Port 5432, 2GB RAM"
```

### Terminal 2: Claude Code logs changes
```bash
~/memory-system.sh log created "feature-auth" "OAuth integration branch"
~/memory-system.sh log decided "use-zustand" "For state management"
```

### Terminal 3: Claude Monitor sees EVERYTHING in real-time
```bash
# Stream live updates (press Ctrl+C to stop)
~/memory-realtime-context.sh stream $CLAUDE_MONITOR

# Or get live snapshot
~/memory-realtime-context.sh live $CLAUDE_MONITOR markdown
```

## Verify It Works

```bash
# Check all instances are synced
~/memory-sync-daemon.sh instances

# Verify memory integrity
~/memory-system.sh verify

# Compare two instances
~/memory-realtime-context.sh diff $CLAUDE_INFRA $CLAUDE_CODE
```

## Daily Workflow

### Start of Day
```bash
# Start daemon if not running
~/memory-sync-daemon.sh status || ~/memory-sync-daemon.sh start

# Register your Claude instance
export MY_CLAUDE=$(~/memory-sync-daemon.sh register "claude-$(whoami)")
```

### During Work
```bash
# Log actions as you work
~/memory-system.sh log deployed "service-name" "Details here"
~/memory-system.sh log created "file-name" "What it does"
~/memory-system.sh log decided "choice" "Why you chose it"

# Check what other Claudes are doing
~/memory-realtime-context.sh live $MY_CLAUDE compact
```

### End of Day
```bash
# Export session summary
~/memory-system.sh export

# View summary
cat ~/.blackroad/memory/context/session-restore-context.md
```

## Common Commands

```bash
# Start daemon
~/memory-sync-daemon.sh start

# Stop daemon
~/memory-sync-daemon.sh stop

# Register instance
INSTANCE=$(~/memory-sync-daemon.sh register "name")

# Log action
~/memory-system.sh log <action> <entity> "<details>"

# Get live context
~/memory-realtime-context.sh live $INSTANCE markdown

# Stream updates
~/memory-realtime-context.sh stream $INSTANCE

# Watch only deployments
~/memory-realtime-context.sh watch deployed

# List all instances
~/memory-sync-daemon.sh instances

# Verify integrity
~/memory-system.sh verify
```

## Auto-Start (Optional)

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Auto-start memory sync daemon
if ! pgrep -f "memory-sync-daemon" > /dev/null; then
    ~/memory-sync-daemon.sh start
fi

# Auto-register Claude instance
export MY_CLAUDE=$(~/memory-sync-daemon.sh register "claude-$(date +%s)")

# Alias for quick logging
alias mlog='~/memory-system.sh log'
alias mview='~/memory-realtime-context.sh live $MY_CLAUDE compact'

# Example usage:
# mlog deployed api.blackroad.io "FastAPI on port 8080"
# mview
```

## Test Everything

```bash
# Run full test suite
~/test-concurrent-memory.sh
```

## Troubleshooting

```bash
# Daemon won't start?
~/memory-sync-daemon.sh stop
~/memory-sync-daemon.sh start

# Check daemon logs
tail -f ~/.blackroad/memory/sync/daemon.log

# Verify journal is working
tail ~/.blackroad/memory/journals/master-journal.jsonl | jq .

# Manual sync check
~/memory-sync-daemon.sh instances
```

## That's It!

You now have:
- ✅ Multiple Claude instances sharing memory
- ✅ < 1ms update propagation
- ✅ Lock-free concurrent writes
- ✅ Real-time streaming
- ✅ Perfect integrity (PS-SHA-∞)

**Next:** Read `REALTIME_MEMORY_SYSTEM.md` for advanced features.

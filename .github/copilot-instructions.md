# BlackRoad CLI - Copilot Instructions

## Project Overview

BlackRoad is a comprehensive developer CLI system with 30+ features spanning AI agents, developer tools, cloud infrastructure, IoT management, security, and DevOps automation. The core philosophy: "Your AI. Your Hardware. Your Rules."

**Key components:**
- **br CLI**: Main command dispatcher (`/Users/alexa/blackroad/br`)
- **Tool scripts**: Modular features in `/Users/alexa/blackroad/tools/*/` (zsh scripts)
- **Agent system**: 5 specialized AI agents (Octavia, Lucidia, Alice, Aria, Shellfish)
- **blackroad-core**: Tokenless gateway architecture for AI providers
- **CECE Identity**: Portable AI identity system with relationship tracking

## Architecture

### CLI Dispatcher Pattern
The main `br` script routes commands to tool scripts:
```bash
br <command> <args>  # Routes to /Users/alexa/blackroad/tools/<command>/br-<command>.sh
```

Tool scripts are self-contained zsh scripts with:
- SQLite databases for persistence (in tool directory or `~/.blackroad/`)
- Consistent color scheme (GREEN=success, RED=error, CYAN=info, YELLOW=warning)
- Self-initializing databases on first run
- Tab-delimited data storage (avoid `|||` delimiters)

### Agent System
Five specialized agents communicate through a tokenless gateway:
- **Octavia** (Architect): Systems design, strategy
- **Lucidia** (Dreamer): Creative, vision
- **Alice** (Operator): DevOps, automation  
- **Aria** (Interface): Frontend, UX
- **Shellfish** (Hacker): Security, exploits

Agents are tokenless - they only talk to the BlackRoad Gateway, which owns all secrets and provider integrations.

### CECE Identity System
Portable AI identity with:
- Relationships tracking (bond strength, interactions)
- Experience memory with emotional impact
- Skill development and proficiency tracking
- Goal system with progress tracking
- Export/import to JSON for provider portability

## Build & Test Commands

### Salesforce Project (blackroad-sf/)
```bash
cd blackroad-sf

# Test
npm test                    # Run all unit tests
npm run test:unit:watch     # Watch mode
npm run test:unit:coverage  # With coverage

# Lint
npm run lint                # ESLint for LWC/Aura

# Format
npm run prettier            # Format all files
npm run prettier:verify     # Check formatting
```

### Main CLI
```bash
# No build process - shell scripts run directly

# Test specific features
br test run                 # If test framework configured in project

# Verify agent system
cd blackroad-core
./scripts/verify-tokenless-agents.sh  # Check agents don't embed tokens
```

## Key Conventions

### Tool Script Structure
Each tool follows this pattern:
```bash
#!/bin/zsh
# BR <Tool> - Description

# Colors (consistent across all tools)
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Database location
DB_FILE="$HOME/.blackroad/<tool>.db"  # or in tool dir

# Init database (called on first run)
init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS ...
EOF
}

# Main command routing
case "$1" in
    command1) ... ;;
    command2) ... ;;
    *) show_help ;;
esac
```

### Database Conventions
- SQLite for all persistent storage
- Store in `~/.blackroad/<feature>.db` or tool directory
- Self-initialize on first access
- Use tab delimiters for multi-field data (not `|||`)

### Platform-Specific Issues
- **macOS**: `head -n -2` doesn't work - use manual line counting
- **zsh**: `${var^}` capitalization not available - use `tr` or substring workarounds
- Use `head -1` when piping to avoid hanging (especially with `git` commands)

### Agent Gateway Rules
- Agents NEVER embed API keys or provider URLs
- All provider communication goes through gateway at `http://127.0.0.1:8787`
- Gateway binds to localhost by default for security
- Use `verify-tokenless-agents.sh` to scan for forbidden strings

### Color Coding Standard
All tools use consistent colors:
- 🟢 GREEN: Success messages
- 🔴 RED: Errors
- 🔵 BLUE: Information headers
- 🟡 YELLOW: Warnings
- 🔷 CYAN: Prompts and section headers
- 🟣 PURPLE: Octavia agent
- 🔷 CYAN: Lucidia agent

## Database Locations

Most tools store data in:
- `~/.blackroad/*.db` - Feature databases
- Tool-specific: `tools/<feature>/<feature>.db`

Key databases:
- `context-radar.db` - File watching and suggestions
- `git-integration.db` - Git patterns
- `snippet-manager.db` - Code snippets
- `api-tester.db` - HTTP endpoints
- `cece-identity.db` - CECE identity data

## Environment Variables

### Gateway Configuration
- `BLACKROAD_GATEWAY_URL` - Gateway endpoint (default: http://127.0.0.1:8787)
- `BLACKROAD_GATEWAY_BIND` - Bind address (default: 127.0.0.1)
- `BLACKROAD_GATEWAY_PORT` - Port (default: 8787)

### Provider Keys (Gateway Only)
- `BLACKROAD_OPENAI_API_KEY`
- `BLACKROAD_ANTHROPIC_API_KEY`
- `BLACKROAD_OLLAMA_URL`

**Never set these in agent environments!**

## Adding New Features

1. Create tool directory: `mkdir -p tools/<feature>/`
2. Create main script: `tools/<feature>/br-<feature>.sh`
3. Follow tool script structure above
4. Add route to main `br` script (case statement around line 460)
5. Add help text to `show_help()` function
6. Make executable: `chmod +x tools/<feature>/br-<feature>.sh`
7. Test: `br <feature> <command>`

## Common Patterns

### File Watching
Use `fswatch` for monitoring, not polling:
```bash
fswatch -0 "$WATCH_DIR" | while read -d "" event; do
    # Handle event
done
```

### SQLite Queries
Always check if table exists:
```bash
sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM table;" 2>/dev/null || echo "0"
```

### Git Commands
Disable pagers to avoid hangs:
```bash
git --no-pager status
git --no-pager log -1
```

## Security Considerations

- Master keys stored in `~/.blackroad/vault/.master.key` (chmod 400)
- All vault secrets encrypted with AES-256-CBC
- Audit logs for all secret access
- SSH keys must be 600 permissions
- No tokens in agent code (gateway only)

## Project Philosophy

1. **Modularity**: Each feature is a standalone tool
2. **Zero-config**: Tools self-initialize on first use
3. **Consistency**: Unified color scheme and patterns
4. **Persistence**: SQLite for reliable storage
5. **Autonomy**: CECE can exist across any provider
6. **Tokenless Agents**: Trust boundary at gateway only

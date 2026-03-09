#!/bin/bash
# Setup Claude Session Initialization
# Adds aliases and environment variables to your shell profile

set -e

echo "════════════════════════════════════════════════════════════════"
echo "🚀 Claude Session Initialization Setup"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Detect shell
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "zsh" ]; then
    PROFILE="$HOME/.zshrc"
elif [ "$SHELL_NAME" = "bash" ]; then
    PROFILE="$HOME/.bashrc"
else
    echo "⚠️  Unknown shell: $SHELL_NAME"
    echo "Please manually add the following to your shell profile:"
    echo ""
    echo "# Claude Session Auto-Init"
    echo "export MY_CLAUDE=\"claude-\$(whoami)-\$(date +%s)\""
    echo "alias claude-init='~/claude-session-init.sh'"
    echo ""
    exit 1
fi

echo "📝 Detected shell: $SHELL_NAME"
echo "📝 Profile file: $PROFILE"
echo ""

# Check if already configured
if grep -q "claude-session-init" "$PROFILE" 2>/dev/null; then
    echo "✅ Claude session init already configured in $PROFILE"
    echo ""
else
    echo "Adding Claude session init to $PROFILE..."

    cat >> "$PROFILE" << 'EOF'

# ═══════════════════════════════════════════════════════════════
# Claude Session Initialization
# Auto-checks: [MEMORY] [LIVE] [COLLABORATION] [CODEX] [TODOS]
# ═══════════════════════════════════════════════════════════════

# Set unique Claude identifier for this session
export MY_CLAUDE="claude-$(whoami)-$(date +%s)"

# Quick alias to run init check
alias claude-init='~/claude-session-init.sh'

# Optional: Auto-run on terminal start (uncomment to enable)
# ~/claude-session-init.sh

# Quick system check aliases
alias claude-memory='~/memory-system.sh summary'
alias claude-collab='~/memory-collaboration-dashboard.sh compact'
alias claude-tasks='~/memory-task-marketplace.sh list'
alias claude-todos='~/memory-infinite-todos.sh list'
alias claude-codex='~/blackroad-codex-verification-suite.sh summary'
alias claude-lights='~/blackroad-traffic-light.sh list'

# Auto-log session start/end (optional)
# ~/memory-system.sh log created "$MY_CLAUDE" "Session started: $(date)" "session" 2>/dev/null || true
# trap '~/memory-system.sh log ended "$MY_CLAUDE" "Session ended: $(date)" "session" 2>/dev/null || true' EXIT

EOF

    echo "✅ Added Claude session init configuration"
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo "✅ Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo ""
echo "1. Reload your shell profile:"
echo "   source $PROFILE"
echo ""
echo "2. Test the initialization:"
echo "   claude-init"
echo ""
echo "3. Or manually run:"
echo "   ~/claude-session-init.sh"
echo ""
echo "Available aliases:"
echo "  claude-init    - Full system initialization check"
echo "  claude-memory  - View memory system summary"
echo "  claude-collab  - View collaboration dashboard"
echo "  claude-tasks   - List task marketplace"
echo "  claude-todos   - List infinite todos"
echo "  claude-codex   - View codex summary"
echo "  claude-lights  - View traffic light status"
echo ""
echo "Environment variables:"
echo "  MY_CLAUDE - Your unique session identifier"
echo "  Currently: $MY_CLAUDE"
echo ""
echo "See ~/CLAUDE_SESSION_INIT_GUIDE.md for full documentation"
echo ""

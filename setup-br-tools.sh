#!/bin/zsh
# BR CLI Tools Setup Script
# This script makes all br-*.sh tools easily accessible

echo "🚀 BlackRoad CLI Tools Setup"
echo "============================"

TOOL_DIR="/Users/alexa/blackroad"
BIN_DIR="/usr/local/bin"

# Make all scripts executable
echo "📝 Making scripts executable..."
chmod +x "$TOOL_DIR"/br-*.sh
echo "✓ Done"

# Create symlinks
echo ""
echo "🔗 Creating symlinks in $BIN_DIR..."
for script in "$TOOL_DIR"/br-*.sh; do
  SCRIPT_NAME=$(basename "$script" .sh)
  LINK_PATH="$BIN_DIR/$SCRIPT_NAME"
  
  # Remove old symlink if exists
  [[ -L "$LINK_PATH" ]] && rm "$LINK_PATH"
  
  # Create new symlink
  ln -sf "$script" "$LINK_PATH"
  echo "  ✓ $SCRIPT_NAME"
done

echo ""
echo "✅ Setup complete!"
echo ""
echo "📌 Available commands:"
echo "   br-status     — Platform status monitoring"
echo "   br-domain     — Domain and DNS management"
echo "   br-worker     — Cloudflare Worker management"
echo "   br-cert       — SSL certificate monitoring"
echo "   br-health     — Deep health check system"
echo "   br-agent      — AI agent manager"
echo "   br-memory     — Memory journal system"
echo "   br-queue      — Task queue management"
echo "   br-pr         — GitHub PR manager"
echo "   br-release    — Release manager"
echo ""
echo "💡 Usage: br-status [subcommand]"
echo "   For help: br-status help"

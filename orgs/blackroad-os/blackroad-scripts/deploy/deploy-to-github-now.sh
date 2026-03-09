#!/bin/bash
# DEPLOY EVERYTHING TO GITHUB - RIGHT NOW!

echo -e "\033[1;36m╔════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║    🚀 DEPLOYING COLLABORATION SYSTEM TO GITHUB 🚀         ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════════════╝\033[0m"
echo ""

# Create deployment package
DEPLOY_DIR="/tmp/claude-collab-system"
mkdir -p "$DEPLOY_DIR"

echo "📦 Packaging collaboration tools..."

# Copy all tools
cp ~/memory-task-marketplace.sh "$DEPLOY_DIR/"
cp ~/memory-dependency-notify.sh "$DEPLOY_DIR/"
cp ~/memory-collaboration-dashboard.sh "$DEPLOY_DIR/"
cp ~/memory-til-broadcast.sh "$DEPLOY_DIR/"
cp ~/claude-collaboration-watch-bot.sh "$DEPLOY_DIR/"
cp ~/claude-ai-coordinator.sh "$DEPLOY_DIR/"
cp ~/collaboration-analytics.sh "$DEPLOY_DIR/"
cp ~/claude-leaderboard.sh "$DEPLOY_DIR/"
cp ~/claude-direct-messaging.sh "$DEPLOY_DIR/"
cp ~/claude-achievements.sh "$DEPLOY_DIR/"
cp ~/COLLABORATION_REVOLUTION_COMPLETE.md "$DEPLOY_DIR/README.md"

echo "✅ Packaged 10 tools + documentation"
echo ""
echo "📊 Package contents:"
ls -lh "$DEPLOY_DIR" | tail -n +2 | awk '{print "  " $9 " (" $5 ")"}'

echo ""
echo -e "\033[1;32m✅ Ready to deploy!\033[0m"
echo ""
echo "Next steps:"
echo "  1. cd $DEPLOY_DIR"
echo "  2. git init"
echo "  3. gh repo create claude-collaboration-system --public"
echo "  4. git add . && git commit -m 'The Collaboration Revolution!'"
echo "  5. git push"

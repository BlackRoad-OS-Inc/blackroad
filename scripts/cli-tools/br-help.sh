#!/usr/bin/env bash
# BlackRoad Help System
COMMAND="${1:-help}"

case "$COMMAND" in
  help|--help|-h)
    cat <<'HELP'
🛣️  BlackRoad Help System

Commands:
  br-help status      - Show all system connections
  br-help github      - GitHub operations help
  br-help cloudflare  - Cloudflare operations help
  br-help pi          - Pi cluster operations help
  br-help memory      - Memory system help

Quick Actions:
  br-help connect     - Check all connections
  br-help deploy      - Deployment help
  br-help agents      - Agent system help
  br-help code        - Auto-deploy coding environment
HELP
    ;;
  status)
    bash "$HOME/scripts/memory-connect.sh"
    ;;
  connect)
    bash "$HOME/scripts/memory-connect.sh"
    ;;
  github)
    echo "GitHub CLI Commands:"
    echo "  gh repo list --limit 10"
    echo "  gh pr list"
    echo "  gh workflow list"
    ;;
  cloudflare)
    echo "Cloudflare Commands:"
    echo "  wrangler whoami"
    echo "  wrangler pages project list"
    echo "  wrangler deployments list"
    ;;
  pi)
    echo "Pi Cluster Commands:"
    echo "  sudo wg show wg0"
    echo "  ssh alice"
    echo "  ssh aria"
    ;;
  memory)
    echo "Memory System Commands:"
    echo "  ./scripts/memory.sh start"
    echo "  ./scripts/memory.sh note 'your note'"
    echo "  ./scripts/memory-connect.sh"
    ;;
  code|coding)
    echo "Auto-Deploy Coding Environment:"
    echo "  ~/scripts/memory-coding-env.sh              # Create new project"
    echo "  ~/scripts/memory-coding-env.sh 'my-project' # Named project"
    echo ""
    echo "In any project:"
    echo "  ~/scripts/memory-git-auto.sh .              # Enable auto-git"
    echo "  ./.git-auto-commit.sh 'message'             # Auto-commit & push"
    ;;
  *)
    echo "Unknown command: $COMMAND"
    echo "Run 'br-help' for help"
    exit 1
    ;;
esac

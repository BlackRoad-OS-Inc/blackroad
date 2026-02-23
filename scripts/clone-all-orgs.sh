#!/bin/zsh
# Clone all key BlackRoad OS repos to local orgs/ structure
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

BLACKROAD_ROOT="${1:-/Users/alexa/blackroad}"
mkdir -p "$BLACKROAD_ROOT/orgs"/{core,ai,enterprise,personal}

echo "${CYAN}🌐 Cloning BlackRoad OS repos...${NC}\n"

# Core repos from BlackRoad-OS
CORE_REPOS=(blackroad-os-web blackroad-os-docs blackroad-cli lucidia-core blackroad-agents blackroad-tools blackroad-agent-os blackroad-ecosystem-dashboard)
for repo in "${CORE_REPOS[@]}"; do
  target="$BLACKROAD_ROOT/orgs/core/$repo"
  [ -d "$target" ] && echo "  ✓ $repo (exists)" && continue
  git clone "git@github.com:BlackRoad-OS/$repo.git" "$target" --quiet 2>/dev/null && \
    echo "  ${GREEN}✓ Cloned BlackRoad-OS/$repo${NC}" || \
    echo "  ⚠ Could not clone $repo"
done

# AI repos from BlackRoad-AI
AI_REPOS=(blackroad-vllm blackroad-ai-ollama blackroad-ai-qwen blackroad-ai-deepseek blackroad-ai-api-gateway)
for repo in "${AI_REPOS[@]}"; do
  target="$BLACKROAD_ROOT/orgs/ai/$repo"
  [ -d "$target" ] && echo "  ✓ $repo (exists)" && continue
  git clone "git@github.com:BlackRoad-AI/$repo.git" "$target" --quiet 2>/dev/null && \
    echo "  ${GREEN}✓ Cloned BlackRoad-AI/$repo${NC}" || \
    echo "  ⚠ Could not clone $repo"
done

echo "\n${GREEN}✅ Setup complete${NC}"
echo "Run 'br org-sync pull' to keep repos updated"

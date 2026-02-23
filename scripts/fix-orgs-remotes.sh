#!/bin/zsh
# Fix incorrect git remotes in orgs/ directories
# All repos should point to their ACTUAL GitHub repo, not the monorepo
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

BLACKROAD_ROOT="/Users/alexa/blackroad"

# Mapping: local_name → github_org/repo_name
declare -A REMOTE_MAP=(
  # orgs/core → BlackRoad-OS
  ["blackroad-os-web"]="BlackRoad-OS/blackroad-os-web"
  ["blackroad-os-docs"]="BlackRoad-OS/blackroad-os-docs"
  ["blackroad-cli"]="BlackRoad-OS/blackroad-cli"
  ["lucidia-core"]="BlackRoad-OS/lucidia-core"
  ["blackroad-agents"]="BlackRoad-OS/blackroad-agents"
  ["blackroad-agent-os"]="BlackRoad-OS/blackroad-agent-os"
  ["blackroad-tools"]="BlackRoad-OS/blackroad-tools"
  ["blackroad-ecosystem-dashboard"]="BlackRoad-OS/blackroad-ecosystem-dashboard"
  ["blackroad-docs"]="BlackRoad-OS/blackroad-os-docs"
  ["blackroad-os-metaverse"]="BlackRoad-OS/blackroad-os-metaverse"
  ["blackroad-multi-ai-system"]="BlackRoad-OS/blackroad-multi-ai-system"
  ["blackroad-cli-tools"]="BlackRoad-OS/blackroad-cli-tools"
  # orgs/core → BlackRoad-OS-Inc
  ["blackroad-hardware"]="BlackRoad-OS-Inc/blackroad-hardware"
  # orgs/ai → BlackRoad-AI
  ["blackroad-vllm"]="BlackRoad-AI/blackroad-vllm"
  ["blackroad-ai-ollama"]="BlackRoad-AI/blackroad-ai-ollama"
  ["blackroad-ai-qwen"]="BlackRoad-AI/blackroad-ai-qwen"
  ["blackroad-ai-deepseek"]="BlackRoad-AI/blackroad-ai-deepseek"
  ["blackroad-ai-api-gateway"]="BlackRoad-AI/blackroad-ai-api-gateway"
  ["blackroad-ai-cluster"]="BlackRoad-AI/blackroad-ai-cluster"
  ["blackroad-ai-memory-bridge"]="BlackRoad-AI/blackroad-ai-memory-bridge"
  # orgs/enterprise → Blackbox-Enterprises
  ["blackbox-n8n"]="Blackbox-Enterprises/blackbox-n8n"
  ["blackbox-airbyte"]="Blackbox-Enterprises/blackbox-airbyte"
  ["blackbox-prefect"]="Blackbox-Enterprises/blackbox-prefect"
  ["blackbox-temporal"]="Blackbox-Enterprises/blackbox-temporal"
  ["blackbox-activepieces"]="Blackbox-Enterprises/blackbox-activepieces"
  ["blackbox-huginn"]="Blackbox-Enterprises/blackbox-huginn"
)

fixed=0; skipped=0; notfound=0

for subdir in core ai enterprise personal; do
  for dir in "$BLACKROAD_ROOT/orgs/$subdir"/*/; do
    [ -d "$dir/.git" ] || continue
    name=$(basename "$dir")

    if [[ -n "${REMOTE_MAP[$name]}" ]]; then
      target="${REMOTE_MAP[$name]}"
      # Verify repo exists on GitHub
      if gh api repos/$target --jq '.name' 2>/dev/null | grep -q .; then
        cd "$dir"
        git remote set-url origin "git@github.com:$target.git" 2>/dev/null
        git remote add upstream "git@github.com:BlackRoad-OS-Inc/blackroad.git" 2>/dev/null || true
        echo "${GREEN}✓ $name → git@github.com:$target.git${NC}"
        ((fixed++))
      else
        echo "${YELLOW}⚠ $name → $target (not found on GitHub, skipped)${NC}"
        ((notfound++))
      fi
    else
      # Keep as-is if not in map (probably a CF worker subdirectory)
      ((skipped++))
    fi
  done
done

echo "\n${CYAN}Summary: $fixed fixed | $skipped skipped (no mapping) | $notfound not found on GitHub${NC}"

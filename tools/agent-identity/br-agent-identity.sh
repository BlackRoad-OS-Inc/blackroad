#!/usr/bin/env zsh
# BR Agent Identity — assign agent identities to git branches
# Usage: br agent-identity [assign|show|list|sync|init]
#
# Branch prefix → Agent mapping:
#   feat/sf-*      → ALICE    (Salesforce, operations)
#   feat/infra-*   → OCTAVIA  (Infrastructure, compute)
#   feat/ai-*      → LUCIDIA  (AI, models, vision)
#   feat/sec-*     → CIPHER   (Security, hardening)
#   feat/ui-*      → ARIA     (Frontend, UX)
#   feat/data-*    → PRISM    (Analytics, data)
#   feat/mem-*     → ECHO     (Memory, recall)
#   feat/hack-*    → SHELLFISH (Exploits, research)
#   main/master    → CECE     (Coordinator)
#   release/*      → OCTAVIA  (Deploy)
#   hotfix/*       → ALICE    (Ops)

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
PURPLE=$'\033[0;35m'; BLUE=$'\033[0;34m'; YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
REGISTRY="$BR_ROOT/agents/branch-registry.json"
IDENTITY_FILE=".agent-identity.json"

# Agent metadata
declare -A AGENT_COLOR AGENT_ROLE AGENT_EMOJI AGENT_FOCUS
AGENT_COLOR=(CECE "$VIOLET" ALICE "$GREEN" OCTAVIA "$PURPLE" LUCIDIA "$CYAN" ARIA "$BLUE" CIPHER "$DIM" PRISM "$AMBER" ECHO "$PINK" SHELLFISH "$RED")
AGENT_ROLE=(CECE "Coordinator" ALICE "Operator" OCTAVIA "Architect" LUCIDIA "Dreamer" ARIA "Interface" CIPHER "Guardian" PRISM "Analyst" ECHO "Librarian" SHELLFISH "Hacker")
AGENT_EMOJI=(CECE "💜" ALICE "🟢" OCTAVIA "🔵" LUCIDIA "🌙" ARIA "🎵" CIPHER "🔐" PRISM "🔮" ECHO "📡" SHELLFISH "🐚")
AGENT_FOCUS=(CECE "coordination,all" ALICE "salesforce,ops,railway,ci" OCTAVIA "infra,deploy,compute,wrangler" LUCIDIA "ai,models,vision,hf" ARIA "frontend,ux,gdrive,org" CIPHER "security,secrets,hardening" PRISM "analytics,data,reporting" ECHO "memory,recall,backup" SHELLFISH "security-research,exploits,scanning")

# Map branch prefix to agent
branch_to_agent() {
  local branch="$1"
  case "$branch" in
    main|master)                      echo "CECE" ;;
    feat/sf-*|feat/salesforce-*)      echo "ALICE" ;;
    feat/infra-*|feat/deploy-*|feat/ci-*) echo "OCTAVIA" ;;
    feat/ai-*|feat/model-*|feat/ml-*) echo "LUCIDIA" ;;
    feat/sec-*|feat/security-*|feat/vault-*) echo "CIPHER" ;;
    feat/ui-*|feat/frontend-*|feat/ux-*) echo "ARIA" ;;
    feat/data-*|feat/analytics-*)     echo "PRISM" ;;
    feat/mem-*|feat/memory-*)         echo "ECHO" ;;
    feat/hack-*|feat/research-*)      echo "SHELLFISH" ;;
    release/*)                        echo "OCTAVIA" ;;
    hotfix/*)                         echo "ALICE" ;;
    feat/*)                           echo "CECE" ;;  # default
    *)                                echo "CECE" ;;
  esac
}

# Write .agent-identity.json for current branch
cmd_assign() {
  local branch="${1:-$(git -C "$BR_ROOT" branch --show-current 2>/dev/null)}"
  [[ -z "$branch" ]] && { echo "${RED}✗${NC} Not in a git repo or no branch"; return 1; }

  local agent=$(branch_to_agent "$branch")
  local now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  cat > "$BR_ROOT/$IDENTITY_FILE" << ENDJSON
{
  "branch": "$branch",
  "agent": "$agent",
  "role": "${AGENT_ROLE[$agent]}",
  "emoji": "${AGENT_EMOJI[$agent]}",
  "focus": "${AGENT_FOCUS[$agent]}",
  "assigned_at": "$now",
  "session": "master-integration-$(date +%Y%m%d)",
  "capabilities": $(echo "${AGENT_FOCUS[$agent]}" | python3 -c "import sys; items=sys.stdin.read().strip().split(','); print('[' + ','.join('\"'+i.strip()+'\"' for i in items) + ']')")
}
ENDJSON

  echo ""
  echo "  ${AGENT_COLOR[$agent]}${BOLD}${AGENT_EMOJI[$agent]} AGENT ASSIGNED${NC}"
  echo "  ${DIM}────────────────────────────${NC}"
  echo "  Branch : ${CYAN}$branch${NC}"
  echo "  Agent  : ${AGENT_COLOR[$agent]}${BOLD}$agent${NC} — ${AGENT_ROLE[$agent]}"
  echo "  Focus  : ${DIM}${AGENT_FOCUS[$agent]}${NC}"
  echo "  Written: ${DIM}$IDENTITY_FILE${NC}"
  echo ""

  # Update registry
  cmd_sync_registry "$branch" "$agent"
}

# Show current branch identity
cmd_show() {
  local f="$BR_ROOT/$IDENTITY_FILE"
  [[ ! -f "$f" ]] && { cmd_assign; return; }
  echo ""
  python3 - "$f" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as fp:
    d = json.load(fp)
print(f"  Branch : {d['branch']}")
print(f"  Agent  : {d['emoji']} {d['agent']} — {d['role']}")
print(f"  Focus  : {d['focus']}")
print(f"  Since  : {d['assigned_at']}")
print()
PYEOF
}

# List all branch→agent mappings from registry
cmd_list() {
  echo ""
  echo "  ${BOLD}${PINK}◈ BRANCH AGENT REGISTRY${NC}"
  echo "  ${DIM}────────────────────────────────────────────${NC}"
  [[ -f "$REGISTRY" ]] && python3 - "$REGISTRY" << 'PYEOF' || echo "  ${DIM}No registry found — run: br agent-identity init${NC}"
import json, sys
with open(sys.argv[1]) as fp:
    data = json.load(fp)
for branch, info in sorted(data.get('branches', {}).items()):
    agent = info.get('agent','?')
    role  = info.get('role','?')
    emoji = info.get('emoji','●')
    print(f"  {emoji} {agent:<12} {branch}")
print()
PYEOF
  echo ""

  echo "  ${BOLD}Branch Prefix Rules${NC}"
  echo "  ${DIM}main/master      → ${VIOLET}CECE${NC}${DIM} (Coordinator)${NC}"
  echo "  ${DIM}feat/sf-*        → ${GREEN}ALICE${NC}${DIM} (Salesforce/Ops)${NC}"
  echo "  ${DIM}feat/infra-*     → ${PURPLE}OCTAVIA${NC}${DIM} (Infrastructure)${NC}"
  echo "  ${DIM}feat/ai-*        → ${CYAN}LUCIDIA${NC}${DIM} (AI/Models)${NC}"
  echo "  ${DIM}feat/sec-*       → ${DIM}CIPHER${NC}${DIM} (Security)${NC}"
  echo "  ${DIM}feat/ui-*        → ${BLUE}ARIA${NC}${DIM} (Frontend/UX)${NC}"
  echo "  ${DIM}feat/data-*      → ${AMBER}PRISM${NC}${DIM} (Analytics)${NC}"
  echo "  ${DIM}feat/mem-*       → ${PINK}ECHO${NC}${DIM} (Memory)${NC}"
  echo "  ${DIM}feat/hack-*      → ${RED}SHELLFISH${NC}${DIM} (Security Research)${NC}"
  echo "  ${DIM}release/*        → ${PURPLE}OCTAVIA${NC}${DIM} (Deploy)${NC}"
  echo "  ${DIM}hotfix/*         → ${GREEN}ALICE${NC}${DIM} (Ops)${NC}"
  echo ""
}

# Initialize registry from all existing branches
cmd_init() {
  echo "  ${CYAN}Scanning all branches...${NC}"
  mkdir -p "$(dirname "$REGISTRY")"

  python3 - "$REGISTRY" << 'PYEOF'
import json, subprocess, os, sys
from datetime import datetime

registry_file = sys.argv[1]
try:
    result = subprocess.run(['git', '-C', os.environ.get('BR_ROOT', os.path.expanduser('~/blackroad')),
                            'branch', '-a', '--format=%(refname:short)'], capture_output=True, text=True)
    branches = [b.strip().replace('origin/', '') for b in result.stdout.splitlines() if b.strip()]
    branches = list(set(branches))
except:
    branches = ['main']

branch_map = {
    'main': 'CECE', 'master': 'CECE',
}
for b in branches:
    if b in branch_map:
        continue
    if b.startswith('feat/sf-') or b.startswith('feat/salesforce-'):
        branch_map[b] = 'ALICE'
    elif b.startswith('feat/infra-') or b.startswith('feat/deploy-') or b.startswith('feat/ci-'):
        branch_map[b] = 'OCTAVIA'
    elif b.startswith('feat/ai-') or b.startswith('feat/model-') or b.startswith('feat/ml-'):
        branch_map[b] = 'LUCIDIA'
    elif b.startswith('feat/sec-') or b.startswith('feat/security-') or b.startswith('feat/vault-'):
        branch_map[b] = 'CIPHER'
    elif b.startswith('feat/ui-') or b.startswith('feat/frontend-'):
        branch_map[b] = 'ARIA'
    elif b.startswith('feat/data-') or b.startswith('feat/analytics-'):
        branch_map[b] = 'PRISM'
    elif b.startswith('feat/mem-') or b.startswith('feat/memory-'):
        branch_map[b] = 'ECHO'
    elif b.startswith('feat/hack-') or b.startswith('feat/research-'):
        branch_map[b] = 'SHELLFISH'
    elif b.startswith('release/'):
        branch_map[b] = 'OCTAVIA'
    elif b.startswith('hotfix/'):
        branch_map[b] = 'ALICE'
    else:
        branch_map[b] = 'CECE'

roles = {'CECE':'Coordinator','ALICE':'Operator','OCTAVIA':'Architect','LUCIDIA':'Dreamer','ARIA':'Interface','CIPHER':'Guardian','PRISM':'Analyst','ECHO':'Librarian','SHELLFISH':'Hacker'}
emojis = {'CECE':'💜','ALICE':'🟢','OCTAVIA':'🔵','LUCIDIA':'🌙','ARIA':'🎵','CIPHER':'🔐','PRISM':'🔮','ECHO':'📡','SHELLFISH':'🐚'}

registry = {
    'updated': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    'total_branches': len(branch_map),
    'branches': {
        branch: {
            'agent': agent,
            'role': roles.get(agent, '?'),
            'emoji': emojis.get(agent, '●'),
            'assigned_at': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
        }
        for branch, agent in branch_map.items()
    }
}

with open(registry_file, 'w') as fp:
    json.dump(registry, fp, indent=2)

print(f'  ✅ Registry initialized: {len(branch_map)} branches mapped')
for b, a in sorted(branch_map.items()):
    print(f'     {emojis.get(a,"●")} {a:<12} {b}')
PYEOF
}

# Update registry with a single branch
cmd_sync_registry() {
  local branch="$1" agent="$2"
  [[ -z "$branch" || -z "$agent" ]] && return
  python3 - "$REGISTRY" "$branch" "$agent" << 'PYEOF'
import json, sys, os
from datetime import datetime

registry_file, branch, agent = sys.argv[1], sys.argv[2], sys.argv[3]
roles = {'CECE':'Coordinator','ALICE':'Operator','OCTAVIA':'Architect','LUCIDIA':'Dreamer','ARIA':'Interface','CIPHER':'Guardian','PRISM':'Analyst','ECHO':'Librarian','SHELLFISH':'Hacker'}
emojis = {'CECE':'💜','ALICE':'🟢','OCTAVIA':'🔵','LUCIDIA':'🌙','ARIA':'🎵','CIPHER':'🔐','PRISM':'🔮','ECHO':'📡','SHELLFISH':'🐚'}

os.makedirs(os.path.dirname(registry_file), exist_ok=True)
try:
    with open(registry_file) as fp:
        data = json.load(fp)
except:
    data = {'branches': {}}

data.setdefault('branches', {})[branch] = {
    'agent': agent, 'role': roles.get(agent,'?'),
    'emoji': emojis.get(agent,'●'),
    'assigned_at': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
}
data['updated'] = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
data['total_branches'] = len(data['branches'])

with open(registry_file, 'w') as fp:
    json.dump(data, fp, indent=2)
PYEOF
}

show_help() {
  echo ""
  echo "  ${BOLD}${PINK}BR Agent Identity${NC}  ${DIM}branch → agent mapping${NC}"
  echo ""
  echo "  ${CYAN}br agent-identity assign [branch]${NC}   Assign agent to branch (auto-detects)"
  echo "  ${CYAN}br agent-identity show${NC}              Show current branch identity"
  echo "  ${CYAN}br agent-identity list${NC}              List all branch→agent mappings"
  echo "  ${CYAN}br agent-identity init${NC}              Scan all branches and init registry"
  echo ""
}

case "${1:-show}" in
  assign) cmd_assign "${2:-}" ;;
  show)   cmd_show ;;
  list)   cmd_list ;;
  init)   cmd_init ;;
  *)      show_help ;;
esac

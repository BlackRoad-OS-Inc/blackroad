#!/bin/bash
# ============================================================
# BlackRoad OS — Agent GitHub Account Setup
# Run on Pi fleet to programmatically set up agent machine users
# Usage: ./setup-agent-github-accounts.sh [--invite|--protect|--all]
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDENTITIES="$SCRIPT_DIR/agent-identities.json"
ORG="BlackRoad-OS-Inc"
TEAM_SLUG="agents"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}ℹ${NC} $1"; }

# ── Ensure gh is authed ────────────────────────────────────────
check_auth() {
  if ! gh auth status &>/dev/null; then
    err "Not logged into GitHub. Run: gh auth login"
    exit 1
  fi
  info "GitHub auth: $(gh api /user -q '.login')"
}

# ── Create GitHub org team for agents ──────────────────────────
ensure_team() {
  info "Ensuring '$TEAM_SLUG' team exists in $ORG..."
  existing=$(gh api /orgs/$ORG/teams -q '.[] | select(.slug=="'$TEAM_SLUG'") | .id' 2>/dev/null || echo "")
  if [ -z "$existing" ]; then
    gh api --method POST /orgs/$ORG/teams \
      -f name="Agents" \
      -f slug="$TEAM_SLUG" \
      -f description="BlackRoad OS AI Agent machine users" \
      -f privacy="closed" 2>/dev/null && log "Created 'agents' team" || warn "Could not create team (may need Team plan)"
  else
    log "Team '$TEAM_SLUG' already exists (id: $existing)"
  fi
}

# ── Invite agent account to org ────────────────────────────────
invite_agent() {
  local github_user=$1
  local email=$2
  local name=$3

  info "Inviting $github_user ($email)..."
  
  # Check if user exists on GitHub
  user_exists=$(gh api /users/$github_user -q '.login' 2>/dev/null || echo "")
  
  if [ -z "$user_exists" ]; then
    warn "$github_user does not have a GitHub account yet"
    warn "Create it at: https://github.com/join"
    warn "  Username: $github_user"
    warn "  Email:    $email"
    warn "  After creation, re-run: $0 --invite"
    return 1
  fi

  # Check if already a member
  is_member=$(gh api /orgs/$ORG/members/$github_user -q '.login' 2>/dev/null || echo "")
  if [ -n "$is_member" ]; then
    log "$github_user is already a member of $ORG"
    return 0
  fi

  # Send invitation
  result=$(gh api --method POST /orgs/$ORG/invitations \
    -f invitee_id="$(gh api /users/$github_user -q '.id')" \
    -f role="direct_member" 2>&1)
  
  if echo "$result" | grep -q '"id"'; then
    log "Invited $github_user to $ORG"
  else
    err "Failed to invite $github_user: $(echo $result | head -c 100)"
  fi
}

# ── Set branch protection on private repos ─────────────────────
set_branch_protection() {
  info "Setting branch protection on all private BlackRoad-OS-Inc repos..."
  
  local PAYLOAD='{
    "required_status_checks": null,
    "enforce_admins": false,
    "required_pull_request_reviews": {
      "dismiss_stale_reviews": true,
      "require_code_owner_reviews": false,
      "required_approving_review_count": 1,
      "require_last_push_approval": false
    },
    "restrictions": null,
    "required_conversation_resolution": true,
    "allow_force_pushes": false,
    "allow_deletions": false
  }'

  ok=0; fail=0
  while IFS=$'\t' read -r name visibility; do
    [ "$visibility" != "PRIVATE" ] && continue
    branch=$(gh api "/repos/$ORG/$name" -q '.default_branch' 2>/dev/null || echo "main")
    result=$(echo "$PAYLOAD" | gh api --method PUT "/repos/$ORG/$name/branches/$branch/protection" --input - 2>&1)
    if echo "$result" | grep -q '"url"'; then
      log "$name ($branch) — protected"; ((ok++))
    else
      msg=$(echo "$result" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("message","?"))' 2>/dev/null || echo "err")
      err "$name — $msg"; ((fail++))
    fi
  done < <(gh repo list $ORG --limit 100 --json name,visibility -q '.[] | [.name,.visibility] | @tsv' 2>/dev/null)

  echo ""
  log "Branch protection: ✓ $ok | ✗ $fail"
  [ "$fail" -gt 0 ] && warn "Failures likely need GitHub Team plan. Upgrade: https://github.com/organizations/$ORG/billing/plans"
}

# ── Add CODEOWNERS for all repos (works without Team plan) ─────
add_codeowners() {
  local repo=$1
  local branch=${2:-main}
  local content=$(base64 -i - << 'EOF'
# BlackRoad OS CODEOWNERS
# All changes require review from org owners
* @blackboxprogramming
EOF
)
  sha=$(gh api "/repos/$ORG/$repo/contents/.github/CODEOWNERS" -q '.sha' 2>/dev/null || echo "")
  if [ -n "$sha" ]; then
    gh api --method PUT "/repos/$ORG/$repo/contents/.github/CODEOWNERS" \
      -f message="chore: add CODEOWNERS" -f content="$content" -f sha="$sha" -f branch="$branch" &>/dev/null \
      && log "$repo CODEOWNERS updated" || warn "$repo CODEOWNERS update failed"
  else
    gh api --method PUT "/repos/$ORG/$repo/contents/.github/CODEOWNERS" \
      -f message="chore: add CODEOWNERS" -f content="$content" -f branch="$branch" &>/dev/null \
      && log "$repo CODEOWNERS added" || warn "$repo CODEOWNERS add failed"
  fi
}

# ── Main ───────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}"
  echo "╔══════════════════════════════════════════════╗"
  echo "║  BlackRoad OS — Agent Account Setup         ║"
  echo "║  Org: $ORG                ║"
  echo "╚══════════════════════════════════════════════╝"
  echo -e "${NC}"

  check_auth

  local CMD=${1:---all}

  case "$CMD" in
    --invite)
      ensure_team
      python3 -c "
import json, subprocess, sys
agents = json.load(open('$IDENTITIES'))['agents']
for a in agents:
    print(f'--- {a[\"name\"]} ---')
    result = subprocess.run(['bash', '$0', '--invite-one', a['github_username'], a['email'], a['name']], capture_output=False)
"
      ;;
    --invite-one)
      invite_agent "$2" "$3" "$4"
      ;;
    --protect)
      set_branch_protection
      ;;
    --codeowners)
      info "Adding CODEOWNERS to all private repos..."
      while IFS=$'\t' read -r name visibility; do
        [ "$visibility" != "PRIVATE" ] && continue
        branch=$(gh api "/repos/$ORG/$name" -q '.default_branch' 2>/dev/null || echo "main")
        add_codeowners "$name" "$branch"
      done < <(gh repo list $ORG --limit 100 --json name,visibility -q '.[] | [.name,.visibility] | @tsv')
      ;;
    --status)
      info "Current org members:"
      gh api /orgs/$ORG/members -q '.[].login' 2>/dev/null
      info "Pending invitations:"
      gh api /orgs/$ORG/invitations -q '.[].login // .[].email' 2>/dev/null
      ;;
    --all|*)
      ensure_team
      set_branch_protection
      info "Run '--invite' after creating GitHub accounts for agents"
      info "Agent emails: $(python3 -c "import json; [print(a['email']) for a in json.load(open('$IDENTITIES'))['agents']]" 2>/dev/null)"
      ;;
  esac
}

main "$@"

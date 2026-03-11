#!/usr/bin/env bash
# BlackRoad Audit: Forensic evidence extractor for code verification

blackroad-audit () {
  REPO=${1:-.}

  echo "=== BLACKROAD AUDIT SNAPSHOT ==="
  echo "Repo: $(basename "$REPO")"
  echo "Commit: $(git -C "$REPO" rev-parse HEAD 2>/dev/null)"
  echo "Date: $(date -u)"
  echo

  echo "=== FILE TREE (TOP LEVEL) ==="
  find "$REPO" -maxdepth 3 -type f \
    \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.tf" -o -name "*.yml" -o -name "*.yaml" -o -name "Dockerfile" -o -name "package.json" \) \
    | sed "s|^$REPO/||" | head -100
  echo

  echo "=== INTEGRATION SIGNALS ==="
  rg -n "anthropic|claude|bedrock|stripe|terraform|aws|openai" "$REPO" --max-count 50 2>/dev/null || true
  echo

  echo "=== ENV VAR USAGE ==="
  rg -n "API_KEY|SECRET|TOKEN|AWS_|STRIPE_" "$REPO" --max-count 30 2>/dev/null || true
  echo

  echo "=== CI / WORKFLOWS ==="
  ls "$REPO/.github/workflows" 2>/dev/null || echo "No workflows found"
  echo

  echo "=== RECENT MERGED COMMITS (LAST 10) ==="
  git -C "$REPO" log --oneline -10 2>/dev/null || echo "No git history"
  echo

  echo "=== END AUDIT ==="
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  blackroad-audit "$@"
fi

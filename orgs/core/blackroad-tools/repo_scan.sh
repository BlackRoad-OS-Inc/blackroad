#!/usr/bin/env bash
set -euo pipefail

# Determine repo root and navigate there so the script can be run from any path.
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

printf "== Blackroad Prism Console repository scan ==\n\n"

# Basic repo metadata
tracked_files=$(git ls-files | wc -l | tr -d '[:space:]')
untracked_files=$(git ls-files --others --exclude-standard | wc -l | tr -d '[:space:]')

printf "Tracked files: %s\n" "$tracked_files"
printf "Untracked files: %s\n\n" "$untracked_files"

printf "== Static keyword search (case-insensitive) ==\n"
keywords=(
  "error"
  "fail"
  "exception"
  "todo"
  "fixme"
)

for keyword in "${keywords[@]}"; do
  printf "\n-- Keyword: %s --\n" "$keyword"
  # ripgrep statistics give a quick overview without overwhelming output
  rg --ignore-case --stats "$keyword" || true
  # Show a few contextual examples to help triage quickly
  rg --ignore-case --context 1 --max-count 5 "$keyword" || true
  printf "\n"
done

printf "== Recent Git activity (last 5 commits) ==\n"
git log -5 --oneline

printf "\n== Suggested next steps ==\n"
cat <<'SUGGESTIONS'
- Review the keyword matches above to identify real issues versus noise.
- Run project-specific test suites (e.g., pnpm test, pytest, go test) in the relevant packages.
- Inspect CI/CD logs for failed pull requests using the repository's hosting platform.
- Update this script with additional heuristics that fit your team's workflows.
SUGGESTIONS
# Determine the repository root. If git is unavailable we default to the
# current working directory so the script still operates when PATH is minimal.
if command -v git >/dev/null 2>&1; then
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
else
  repo_root="$(pwd)"
fi

# Allow callers to provide their own list of keywords as arguments. If none are
# supplied we fall back to a small default list that looks for common markers.
if [[ $# -gt 0 ]]; then
  mapfile -t keywords < <(printf '%s\n' "$@" | sed '/^\s*$/d')
else
  keywords=(
    "TODO"
    "FIXME"
    "HACK"
    "BUG"
  )
fi

if [[ ${#keywords[@]} -eq 0 ]]; then
  echo "repo_scan: no keywords provided; nothing to do." >&2
  exit 0
fi

scan_with_grep=false
if ! command -v rg >/dev/null 2>&1; then
  echo "repo_scan: ripgrep (rg) is not installed or not available in PATH." >&2
  echo "repo_scan: install ripgrep for faster searches: https://github.com/BurntSushi/ripgrep#installation" >&2
  if command -v grep >/dev/null 2>&1; then
    echo "repo_scan: falling back to grep; results may be slower." >&2
    scan_with_grep=true
  else
    echo "repo_scan: neither ripgrep nor grep is available; skipping keyword scan." >&2
    exit 0
  fi
fi

search_with_rg() {
  local keyword="$1"
  rg \
    --hidden \
    --glob '!.git' \
    --color=never \
    --no-heading \
    --line-number \
    --smart-case \
    --fixed-strings \
    -- "$keyword" \
    "$repo_root" || true
}

search_with_grep() {
  local keyword="$1"
  GREP_COLORS='' GREP_COLOR='' grep \
    -RIn \
    --exclude-dir='.git' \
    --binary-files=without-match \
    -- "$keyword" \
    "$repo_root" || true
}

for keyword in "${keywords[@]}"; do
  if [[ -z "$keyword" ]]; then
    continue
  fi

  if [[ "$scan_with_grep" == true ]]; then
    search_with_grep "$keyword"
  else
    search_with_rg "$keyword"
  fi

done

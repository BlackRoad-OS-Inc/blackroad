#!/bin/zsh
# BR Release - Release Manager

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

show_help() {
  echo -e "${CYAN}${BOLD}BR Release${NC}"
  echo "  br release list            List releases"
  echo "  br release create <tag>    Create a new release"
  echo "  br release tag <version>   Tag current commit"
  echo "  br release changelog       Generate changelog"
  echo "  br release latest          Show latest release"
  echo "  br release bump <major|minor|patch>  Bump version"
  echo ""
  echo -e "  ${YELLOW}Requires: gh CLI authenticated${NC}"
}

get_repo() {
  git remote get-url origin 2>/dev/null | \
    sed 's|https://github.com/||;s|git@github.com:||;s|\.git$||' | head -1
}

get_latest_tag() {
  git --no-pager tag --sort=-v:refname 2>/dev/null | head -1
}

cmd_list() {
  local REPO=$(get_repo)
  echo -e "${CYAN}Releases: $REPO${NC}\n"
  gh release list --repo "$REPO" --limit 10 2>/dev/null || \
    git --no-pager tag --sort=-v:refname 2>/dev/null | head -10 | \
      while read T; do echo -e "  ${GREEN}●${NC} $T"; done
}

cmd_create() {
  local TAG="$1"
  if [[ -z "$TAG" ]]; then
    echo -e "${RED}Usage: br release create <tag>${NC}"
    return 1
  fi
  local REPO=$(get_repo)
  local NOTES=$(git --no-pager log $(get_latest_tag)..HEAD --oneline 2>/dev/null | head -20 | \
    sed 's/^/- /')
  echo -e "${CYAN}Creating release: $TAG${NC}"
  echo -e "${YELLOW}Notes preview:${NC}}\n$NOTES\n"
  gh release create "$TAG" \
    --repo "$REPO" \
    --title "$TAG" \
    --notes "$NOTES" \
    2>/dev/null && echo -e "${GREEN}✓ Release $TAG created${NC}" || \
    echo -e "${RED}Failed — ensure gh is authenticated${NC}"
}

cmd_tag() {
  local VERSION="$1"
  if [[ -z "$VERSION" ]]; then
    echo -e "${RED}Usage: br release tag <version>${NC}"
    return 1
  fi
  [[ "$VERSION" != v* ]] && VERSION="v$VERSION"
  git tag "$VERSION" 2>/dev/null && \
    echo -e "${GREEN}✓ Tagged: $VERSION${NC}" && \
    echo -e "  Push with: ${CYAN}git push origin $VERSION${NC}" || \
    echo -e "${RED}Failed to create tag $VERSION${NC}"
}

cmd_changelog() {
  local FROM="${1:-$(get_latest_tag)}"
  local TO="${2:-HEAD}"
  echo -e "${CYAN}Changelog: $FROM..$TO${NC}}\n"
  if [[ -z "$FROM" ]]; then
    git --no-pager log --oneline -30 2>/dev/null | while read LINE; do
      echo "- $LINE"
    done
    return
  fi
  git --no-pager log "${FROM}..${TO}" --oneline 2>/dev/null | while read LINE; do
    if echo "$LINE" | grep -q "^[a-f0-9]* feat"; then
      echo -e "  ${GREEN}feat${NC}: ${LINE#* feat}"
    elif echo "$LINE" | grep -q "^[a-f0-9]* fix"; then
      echo -e "  ${RED}fix${NC}: ${LINE#* fix}"
    elif echo "$LINE" | grep -q "^[a-f0-9]* docs"; then
      echo -e "  ${CYAN}docs${NC}: ${LINE#* docs}"
    else
      echo "  $LINE"
    fi
  done
}

cmd_latest() {
  local REPO=$(get_repo)
  local TAG=$(get_latest_tag)
  echo -e "${CYAN}Latest Release${NC}\n"
  echo -e "  Tag: ${GREEN}${TAG:-none}${NC}"
  if [[ -n "$TAG" ]]; then
    DATE=$(git --no-pager log -1 --format="%ai" "$TAG" 2>/dev/null)
    MSG=$(git --no-pager log -1 --format="%s" "$TAG" 2>/dev/null)
    echo -e "  Date: $DATE"
    echo -e "  Msg:  $MSG"
  fi
  gh release view --repo "$REPO" 2>/dev/null | head -10 || true
}

cmd_bump() {
  local TYPE="${1:-patch}"
  local LATEST=$(get_latest_tag)
  if [[ -z "$LATEST" ]]; then
    echo -e "${YELLOW}No existing tags. Creating v0.1.0${NC}"
    cmd_tag "v0.1.0"
    return
  fi
  local VERSION="${LATEST#v}"
  local MAJOR=$(echo "$VERSION" | cut -d. -f1)
  local MINOR=$(echo "$VERSION" | cut -d. -f2)
  local PATCH=$(echo "$VERSION" | cut -d. -f3)
  case "$TYPE" in
    major) MAJOR=$((MAJOR+1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR+1)); PATCH=0 ;;
    patch) PATCH=$((PATCH+1)) ;;
    *)
      echo -e "${RED}Type must be: major, minor, or patch${NC}"
      return 1 ;;
  esac
  local NEW="v${MAJOR}.${MINOR}.${PATCH}"
  echo -e "${CYAN}Bumping: $LATEST → $NEW${NC}"
  cmd_tag "$NEW"
}

case "${1:-help}" in
  list)      cmd_list ;;
  create)    cmd_create "$2" ;;
  tag)       cmd_tag "$2" ;;
  changelog) cmd_changelog "$2" "$3" ;;
  latest)    cmd_latest ;;
  bump)      cmd_bump "$2" ;;
  help|-h|--help) show_help ;;
  *)
    echo -e "${RED}Unknown command: $1${NC}"
    show_help ;;
esac

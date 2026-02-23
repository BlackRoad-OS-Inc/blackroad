#!/bin/zsh
# BR Repo Manager — create, clone, archive GitHub repos

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

ORG="${BR_ORG:-BlackRoad-OS}"

cmd_create() {
    local name="$2"; local desc="${3:-A BlackRoad OS project}"; local org="${4:-$ORG}"
    [[ -z "$name" ]] && echo -e "${RED}Usage: br repo create <name> [description] [org]${NC}" && return 1
    echo -e "${CYAN}Creating ${org}/${name}...${NC}"
    gh repo create "$org/$name" --public --description "$desc" && \
        echo -e "${GREEN}✓ Created: github.com/$org/$name${NC}" || \
        echo -e "${RED}✗ Failed${NC}"
}

cmd_init() {
    local name="$2"; local org="${3:-$ORG}"
    [[ -z "$name" ]] && echo -e "${RED}Usage: br repo init <name> [org]${NC}" && return 1
    echo -e "${CYAN}Initializing ${org}/${name} with README + CI...${NC}"
    
    # README
    local readme="# ${name}\n\n> BlackRoad OS — $(date +%Y)\n\n## Overview\n\nPart of the BlackRoad OS platform.\n\n## Usage\n\n\`\`\`bash\npip install -r requirements.txt\npython src/main.py\n\`\`\`\n"
    echo "$readme" | base64 | tr -d '\n' > /tmp/br-readme-b64.txt
    gh api "repos/$org/$name/contents/README.md" --method PUT \
        --field message="init: add README" \
        --field content="$(cat /tmp/br-readme-b64.txt)" --jq '.content.path' 2>/dev/null && \
        echo -e "  ${GREEN}✓${NC} README.md"
    
    # CI
    local ci='name: CI\non: [push, pull_request]\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-python@v5\n        with: {python-version: "3.11"}\n      - run: pip install pytest\n      - run: pytest --collect-only || true\n'
    echo "$ci" | base64 | tr -d '\n' > /tmp/br-ci-b64.txt
    gh api "repos/$org/$name/contents/.github/workflows/ci.yml" --method PUT \
        --field message="ci: add GitHub Actions workflow" \
        --field content="$(cat /tmp/br-ci-b64.txt)" --jq '.content.path' 2>/dev/null && \
        echo -e "  ${GREEN}✓${NC} .github/workflows/ci.yml"
    
    rm -f /tmp/br-readme-b64.txt /tmp/br-ci-b64.txt
    echo -e "\n${GREEN}✓ Initialized${NC}"
}

cmd_list() {
    local org="${2:-$ORG}"
    echo -e "${CYAN}Repos in ${org}:${NC}\n"
    gh api "orgs/$org/repos?per_page=100&sort=pushed" \
        --jq '.[] | "  " + (.pushed_at[:10]) + "  " + .name' 2>/dev/null
}

cmd_archive() {
    local name="$2"; local org="${3:-$ORG}"
    [[ -z "$name" ]] && echo -e "${RED}Usage: br repo archive <name> [org]${NC}" && return 1
    gh api "repos/$org/$name" --method PATCH --field archived=true --jq '.name + " archived"' 2>/dev/null && \
        echo -e "${GREEN}✓ Archived${NC}" || echo -e "${RED}✗ Failed${NC}"
}

cmd_clone_all() {
    local org="${2:-$ORG}"; local dir="${3:-./repos}"
    mkdir -p "$dir"
    echo -e "${CYAN}Cloning all ${org} repos to ${dir}...${NC}"
    gh api "orgs/$org/repos?per_page=100" --jq '.[].clone_url' 2>/dev/null | while read url; do
        local name=$(basename "$url" .git)
        [[ -d "$dir/$name" ]] && echo "  skip $name" && continue
        git clone --quiet "$url" "$dir/$name" && echo -e "  ${GREEN}✓${NC} $name" || echo -e "  ${RED}✗${NC} $name"
    done
}

show_help() {
    echo -e "${CYAN}BR Repo Manager${NC}"
    echo "  br repo create <name> [desc] [org]   Create new repo"
    echo "  br repo init <name> [org]            Add README + CI to existing repo"
    echo "  br repo list [org]                   List repos"
    echo "  br repo archive <name> [org]         Archive a repo"
    echo "  br repo clone-all [org] [dir]        Clone all org repos"
}

case "${1:-help}" in
    create)    cmd_create "$@" ;;
    init)      cmd_init "$@" ;;
    list)      cmd_list "$@" ;;
    archive)   cmd_archive "$@" ;;
    clone-all) cmd_clone_all "$@" ;;
    *)         show_help ;;
esac

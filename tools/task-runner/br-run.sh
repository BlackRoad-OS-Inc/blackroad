#!/bin/zsh
# BR Run - Smart Task Runner
RUN_HOME="/Users/alexa/blackroad/tools/task-runner"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

detect_tasks() {
    echo -e "${CYAN}🔍 Detecting tasks...${NC}\n"
    [[ -f "package.json" ]] && echo -e "${GREEN}📦 npm scripts${NC}" && jq -r '.scripts | keys[]' package.json 2>/dev/null | sed 's/^/  - npm run /'
    [[ -f "Makefile" ]] && echo -e "${GREEN}🔨 Makefile targets${NC}" && grep "^[a-zA-Z]" Makefile | sed 's/:.*//;s/^/  - make /'
    [[ -f "Cargo.toml" ]] && echo -e "${GREEN}🦀 Cargo commands${NC}" && echo "  - cargo build\n  - cargo test\n  - cargo run"
    [[ -f "go.mod" ]] && echo -e "${GREEN}🐹 Go commands${NC}" && echo "  - go build\n  - go test\n  - go run"
}

run_task() {
    local task=$1
    echo -e "${GREEN}▶️  Running: ${task}${NC}\n"
    eval $task
}

case ${1:-detect} in
    detect|d) detect_tasks ;;
    *) run_task "$*" ;;
esac

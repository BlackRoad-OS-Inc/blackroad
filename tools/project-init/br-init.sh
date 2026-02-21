#!/bin/zsh
# BR Init - Project Scaffolder
INIT_HOME="/Users/alexa/blackroad/tools/project-init"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

init_node() {
    echo -e "${GREEN}📦 Initializing Node.js project...${NC}"
    npm init -y
    echo "node_modules/\n.env\ndist/" > .gitignore
    mkdir -p src tests
    echo 'console.log("Hello, World!");' > src/index.js
    echo -e "${GREEN}✓ Node.js project created!${NC}"
}

init_python() {
    echo -e "${GREEN}🐍 Initializing Python project...${NC}"
    cat > requirements.txt <<EOF
pytest
black
flake8
EOF
    mkdir -p src tests
    echo '__version__ = "0.1.0"' > src/__init__.py
    echo "def hello():\n    return 'Hello, World!'" > src/main.py
    cat > .gitignore <<EOF
__pycache__/
*.pyc
.env
venv/
EOF
    echo -e "${GREEN}✓ Python project created!${NC}"
}

init_go() {
    echo -e "${GREEN}🐹 Initializing Go project...${NC}"
    local name=$(basename $(pwd))
    go mod init $name
    cat > main.go <<EOF
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
EOF
    echo -e "${GREEN}✓ Go project created!${NC}"
}

show_templates() {
    echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  📁 Project Templates                    ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}\n"
    echo -e "${GREEN}1.${NC} node      - Node.js project"
    echo -e "${GREEN}2.${NC} python    - Python project"
    echo -e "${GREEN}3.${NC} go        - Go project"
    echo -e "${GREEN}4.${NC} rust      - Rust project"
    echo "\nUsage: br init <template>"
}

case ${1:-list} in
    node|nodejs|js) init_node ;;
    python|py) init_python ;;
    go|golang) init_go ;;
    rust) cargo init ;;
    list|l) show_templates ;;
    *) show_templates ;;
esac

#!/bin/zsh
# BR TEMPLATE - Scaffold new tools, agents, and projects from templates

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

TEMPLATES_DIR="$PWD/templates"
DB_FILE="$HOME/.blackroad/template.db"

init_db() {
  mkdir -p "$(dirname $DB_FILE)"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS scaffolds (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT, type TEXT, path TEXT, ts TEXT DEFAULT (datetime('now'))
);
SQL
}
init_db

_tool_template() {
  local name="$1"
  cat <<TMPL
#!/bin/zsh
# BR ${name:u} - Description here

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

DB_FILE="\$HOME/.blackroad/${name}.db"

init_db() {
  mkdir -p "\$(dirname \$DB_FILE)"
  sqlite3 "\$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT, value TEXT, ts TEXT DEFAULT (datetime('now'))
);
SQL
}
init_db

cmd_list() {
  echo ""
  echo -e "\${BOLD}\${CYAN}${name} items:\${NC}"
  sqlite3 "\$DB_FILE" "SELECT id, name, value, ts FROM items ORDER BY id DESC LIMIT 20;" 2>/dev/null | \\
    while IFS='|' read id name val ts; do
      echo -e "  \${CYAN}\${ts}\${NC}  \${name}  \${val}"
    done
  echo ""
}

cmd_add() {
  local name="\$1" val="\${2:-}"
  [[ -z "\$name" ]] && { echo "Usage: br ${name} add <name> [value]"; return 1; }
  sqlite3 "\$DB_FILE" "INSERT INTO items(name,value) VALUES('\$name','\$val');"
  echo -e "\${GREEN}✓ Added: \${name}\${NC}"
}

cmd_help() {
  echo ""
  echo -e "\${BOLD}br ${name}\${NC} — description"
  echo ""
  echo "  \${CYAN}br ${name} list\${NC}         List items"
  echo "  \${CYAN}br ${name} add <name>\${NC}   Add item"
  echo ""
}

case "\${1:-help}" in
  list)    cmd_list ;;
  add)     shift; cmd_add "\$@" ;;
  help|-h) cmd_help ;;
  *) echo "Unknown: \$1. Try: list add"; exit 1 ;;
esac
TMPL
}

_agent_template() {
  local name="$1"
  local name_upper="${name:u}"
  cat <<TMPL
{
  "name": "${name_upper}",
  "model": "tinyllama:latest",
  "pid": null,
  "status": "idle",
  "host": "localhost",
  "endpoint": "http://localhost:11434",
  "current_task": null,
  "role": "WORKER",
  "capabilities": ["general", "analysis"],
  "personality": "Focused and efficient. Gets things done.",
  "system_prompt": "You are ${name_upper}, a BlackRoad OS AI agent. You are helpful, precise, and task-focused.",
  "started_at": null,
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
TMPL
}

_workflow_template() {
  local name="$1"
  cat <<TMPL
name: ${name}
on:
  push:
    branches: [main, master]
  workflow_dispatch:

jobs:
  ${name}:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup
        run: |
          echo "Setting up..."

      - name: Run
        run: |
          echo "Running ${name}..."
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
TMPL
}

_nextjs_component_template() {
  local name="$1"
  cat <<TMPL
'use client';

import { useState } from 'react';

interface ${name}Props {
  title?: string;
}

export default function ${name}({ title = '${name}' }: ${name}Props) {
  const [count, setCount] = useState(0);

  return (
    <div className="p-4">
      <h2 className="text-xl font-bold">{title}</h2>
      <button
        onClick={() => setCount(c => c + 1)}
        className="mt-2 px-4 py-2 bg-blue-600 text-white rounded"
      >
        Count: {count}
      </button>
    </div>
  );
}
TMPL
}

cmd_new() {
  local type="$1" name="$2"
  [[ -z "$type" || -z "$name" ]] && { echo "Usage: br template new <type> <name>"; cmd_list_types; return 1; }

  case "$type" in
    tool)
      local dir="tools/${name}"
      [[ -d "$dir" ]] && { echo -e "${YELLOW}Already exists: $dir${NC}"; return 1; }
      mkdir -p "$dir"
      local script="${dir}/br-${name}.sh"
      _tool_template "$name" > "$script"
      chmod +x "$script"
      echo -e "${GREEN}✓ Tool created:${NC} $script"
      echo -e "  ${CYAN}Next:${NC} Add to br dispatch table, then: br $name help"
      ;;
    agent)
      local dir="agents/active"
      mkdir -p "$dir"
      local afile="${dir}/${name:u}.json"
      _agent_template "$name" > "$afile"
      echo -e "${GREEN}✓ Agent created:${NC} $afile"
      echo -e "  ${CYAN}Next:${NC} br agents list"
      ;;
    workflow)
      local dir=".github/workflows"
      mkdir -p "$dir"
      local wfile="${dir}/${name}.yml"
      _workflow_template "$name" > "$wfile"
      echo -e "${GREEN}✓ Workflow created:${NC} $wfile"
      ;;
    component)
      local cfile="${name}.tsx"
      _nextjs_component_template "$name" > "$cfile"
      echo -e "${GREEN}✓ Component created:${NC} $cfile"
      ;;
    *)
      echo -e "${RED}Unknown type: $type${NC}"; cmd_list_types; return 1 ;;
  esac

  sqlite3 "$DB_FILE" "INSERT INTO scaffolds(name,type,path) VALUES('$name','$type','$(pwd)/$name');"
}

cmd_list_types() {
  echo ""
  echo -e "${BOLD}${CYAN}Available template types:${NC}"
  echo ""
  echo -e "  ${CYAN}tool${NC}        New br CLI tool (zsh + SQLite)"
  echo -e "  ${CYAN}agent${NC}       New agent JSON definition"
  echo -e "  ${CYAN}workflow${NC}    GitHub Actions workflow"
  echo -e "  ${CYAN}component${NC}   Next.js React component (TypeScript)"
  echo ""
}

cmd_list_scaffolds() {
  echo ""
  echo -e "${BOLD}${CYAN}Recent scaffolds:${NC}"
  sqlite3 "$DB_FILE" "SELECT ts, type, name, path FROM scaffolds ORDER BY id DESC LIMIT 20;" 2>/dev/null | \
    while IFS='|' read ts type name path; do
      echo -e "  ${CYAN}${ts}${NC}  ${type:10}  ${name:15}  ${path}"
    done
  echo ""
}

cmd_list_existing() {
  echo ""
  echo -e "${BOLD}${CYAN}Existing templates:${NC}"
  [[ -d "$TEMPLATES_DIR" ]] || { echo -e "  ${YELLOW}No templates/ directory${NC}"; return; }
  find "$TEMPLATES_DIR" -type f | while read f; do
    echo -e "  ${CYAN}$(basename $f)${NC}  ${f}"
  done
  echo ""
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br template${NC} — scaffold new tools, agents, components"
  echo ""
  echo "  ${CYAN}br template new <type> <name>${NC}   Scaffold from template"
  echo "  ${CYAN}br template types${NC}               List available types"
  echo "  ${CYAN}br template list${NC}                List existing templates"
  echo "  ${CYAN}br template log${NC}                 Show scaffold history"
  echo ""
  cmd_list_types
}

case "${1:-help}" in
  new)     shift; cmd_new "$@" ;;
  types)   cmd_list_types ;;
  list)    cmd_list_existing ;;
  log)     cmd_list_scaffolds ;;
  help|-h) cmd_help ;;
  *) echo "Unknown: $1. Try: new types list log"; exit 1 ;;
esac

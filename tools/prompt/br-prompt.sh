#!/bin/zsh
# BR Prompt — LLM Prompt Library
# Store, tag, retrieve, and use prompts with variable substitution

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'
BOLD='\033[1m'

PROMPT_DB="$HOME/.blackroad/prompts.db"

init_db() {
  mkdir -p "$(dirname "$PROMPT_DB")"
  sqlite3 "$PROMPT_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS prompts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT DEFAULT 'general',
  tags TEXT DEFAULT '',
  content TEXT NOT NULL,
  variables TEXT DEFAULT '[]',
  model TEXT DEFAULT 'any',
  use_count INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (strftime('%s','now')),
  updated_at INTEGER DEFAULT (strftime('%s','now'))
);
CREATE TABLE IF NOT EXISTS prompt_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  prompt_id TEXT,
  rendered TEXT,
  model TEXT,
  used_at INTEGER DEFAULT (strftime('%s','now'))
);
CREATE INDEX IF NOT EXISTS idx_prompts_category ON prompts(category);
CREATE INDEX IF NOT EXISTS idx_prompts_tags ON prompts(tags);
SQL
  # Seed default prompts
  local count
  count=$(sqlite3 "$PROMPT_DB" "SELECT COUNT(*) FROM prompts;")
  if [[ "$count" == "0" ]]; then
    sqlite3 "$PROMPT_DB" <<'SQL'
INSERT OR IGNORE INTO prompts VALUES
  ('code-review','Code Review','dev','code,review','Review this code for bugs, security issues, and improvements:\n\n```{{language}}\n{{code}}\n```\n\nFocus on: {{focus|security,performance,readability}}','["language","code","focus"]','any',0,strftime('%s','now'),strftime('%s','now')),
  ('commit-msg','Commit Message','git','git,commit','Generate a conventional commit message for these changes:\n\n{{diff}}\n\nFormat: type(scope): description\nTypes: feat|fix|docs|refactor|test|chore','["diff"]','any',0,strftime('%s','now'),strftime('%s','now')),
  ('explain','Explain Code','dev','explain,docs','Explain what this {{language|code}} does in simple terms:\n\n```\n{{code}}\n```\n\nAudience: {{audience|developer}}','["language","code","audience"]','any',0,strftime('%s','now'),strftime('%s','now')),
  ('debug','Debug Help','dev','debug,fix','Help me debug this error:\n\nError: {{error}}\n\nCode:\n```{{language}}\n{{code}}\n```\n\nWhat I tried: {{tried|nothing yet}}','["error","language","code","tried"]','any',0,strftime('%s','now'),strftime('%s','now')),
  ('test-gen','Test Generator','dev','test,tdd','Generate unit tests for this function:\n\n```{{language}}\n{{code}}\n```\n\nTest framework: {{framework|jest}}\nCover: happy path, edge cases, error cases','["language","code","framework"]','any',0,strftime('%s','now'),strftime('%s','now')),
  ('docs-gen','Documentation Generator','docs','docs,readme','Generate documentation for:\n\n{{content}}\n\nFormat: {{format|markdown}}\nStyle: {{style|concise}}','["content","format","style"]','any',0,strftime('%s','now'),strftime('%s','now')),
  ('brainstorm','Brainstorm','creative','ideas,creative','Brainstorm {{count|10}} ideas for: {{topic}}\n\nConstraints: {{constraints|none}}\nStyle: {{style|practical}}','["count","topic","constraints","style"]','any',0,strftime('%s','now'),strftime('%s','now')),
  ('sql-query','SQL Query Builder','data','sql,database','Write a SQL query to: {{goal}}\n\nTable schema:\n{{schema}}\n\nDatabase: {{db|postgresql}}','["goal","schema","db"]','any',0,strftime('%s','now'),strftime('%s','now')),
  ('api-design','API Design','dev','api,rest','Design a REST API for: {{resource}}\n\nRequirements: {{requirements}}\nInclude: endpoints, request/response shapes, status codes','["resource","requirements"]','any',0,strftime('%s','now'),strftime('%s','now')),
  ('security-audit','Security Audit','security','security,audit','Perform a security audit of:\n\n```{{language}}\n{{code}}\n```\n\nCheck for: OWASP Top 10, injection, auth issues, data exposure','["language","code"]','any',0,strftime('%s','now'),strftime('%s','now'));
SQL
    echo -e "${GREEN}✓${NC} Seeded 10 default prompts"
  fi
}

cmd_list() {
  local category="$1"
  local filter=""
  [[ -n "$category" ]] && filter="WHERE category='$category'"
  
  echo -e "\n${BOLD}${PURPLE}💜 Prompt Library${NC}\n"
  
  python3 - "$PROMPT_DB" "$filter" <<'PY'
import sqlite3, sys
db = sys.argv[1]
filt = sys.argv[2]
conn = sqlite3.connect(db)
rows = conn.execute(f"SELECT id, name, category, tags, use_count FROM prompts {filt} ORDER BY category, name").fetchall()

cur_cat = None
for id_, name, cat, tags, uses in rows:
    if cat != cur_cat:
        print(f"\n  \033[36m{cat.upper()}\033[0m")
        cur_cat = cat
    tag_str = f" [{tags}]" if tags else ""
    print(f"    \033[1m{id_:<20}\033[0m  {name:<30} \033[90m×{uses}{tag_str}\033[0m")

conn.close()
print()
PY
}

cmd_show() {
  local pid="$1"
  [[ -z "$pid" ]] && { echo -e "${RED}✗${NC} Usage: br prompt show <id>"; return 1; }
  
  python3 - "$PROMPT_DB" "$pid" <<'PY'
import sqlite3, sys
db, pid = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
row = conn.execute("SELECT id,name,category,tags,content,variables,model,use_count FROM prompts WHERE id=?", (pid,)).fetchone()
if not row:
    print(f"\033[31m✗\033[0m Prompt not found: {pid}")
    sys.exit(1)
id_, name, cat, tags, content, variables, model, uses = row
print(f"\n\033[1m\033[35m{name}\033[0m  \033[90m({id_})\033[0m")
print(f"  Category: {cat}   Tags: {tags}   Model: {model}   Used: {uses}×")
print(f"\n\033[36mPrompt:\033[0m")
for line in content.split('\\n'):
    print(f"  {line}")

import json
vars_ = json.loads(variables) if variables else []
if vars_:
    print(f"\n\033[33mVariables:\033[0m {', '.join(vars_)}")
print()
conn.close()
PY
}

cmd_use() {
  local pid="$1"
  shift
  [[ -z "$pid" ]] && { echo -e "${RED}✗${NC} Usage: br prompt use <id> [var=val ...]"; return 1; }
  
  python3 - "$PROMPT_DB" "$pid" "$@" <<'PY'
import sqlite3, sys, re, json
db, pid = sys.argv[1], sys.argv[2]
overrides = {}
for arg in sys.argv[3:]:
    if '=' in arg:
        k, v = arg.split('=', 1)
        overrides[k] = v

conn = sqlite3.connect(db)
row = conn.execute("SELECT content, variables FROM prompts WHERE id=?", (pid,)).fetchone()
if not row:
    print(f"\033[31m✗\033[0m Not found: {pid}")
    sys.exit(1)

content, variables = row
vars_ = json.loads(variables) if variables else []

# Parse variables from content: {{name|default}}
rendered = content
missing = []
pattern = re.compile(r'\{\{(\w+)(?:\|([^}]*))?\}\}')

for match in pattern.finditer(content):
    var_name = match.group(1)
    default = match.group(2) or ''
    val = overrides.get(var_name, default)
    if not val:
        missing.append(var_name)
    rendered = rendered.replace(match.group(0), val)

if missing:
    print(f"\033[33m⚠\033[0m Variables needed: {', '.join(missing)}")
    print(f"Usage: br prompt use {pid} {' '.join(v+'=VALUE' for v in missing)}")
    sys.exit(1)

# Update use count
conn.execute("UPDATE prompts SET use_count=use_count+1, updated_at=strftime('%s','now') WHERE id=?", (pid,))
conn.execute("INSERT INTO prompt_history (prompt_id, rendered, model) VALUES (?, ?, 'any')", (pid, rendered))
conn.commit()
conn.close()

print("\n\033[1m\033[35m💜 Rendered Prompt:\033[0m\n")
print(rendered)
print()
print("\033[90m[ Copied to stdout — pipe to: br llm ask lucidia, pbcopy, etc. ]\033[0m")
PY
}

cmd_add() {
  local pid="$1"
  local name="$2"
  local category="${3:-general}"
  
  [[ -z "$pid" || -z "$name" ]] && {
    echo -e "${CYAN}Usage: br prompt add <id> <name> [category]${NC}"
    echo "Then enter the prompt content (EOF to finish):"
    return 1
  }
  
  echo -e "${CYAN}Enter prompt content (Ctrl+D when done):${NC}"
  echo -e "${YELLOW}Use {{variable|default}} for variables${NC}\n"
  local content
  content=$(cat)
  
  # Extract variables
  local vars
  vars=$(echo "$content" | python3 -c "
import sys, re, json
c = sys.stdin.read()
vars_ = list(dict.fromkeys(re.findall(r'\{\{(\w+)(?:\|[^}]*)?\}\}', c)))
print(json.dumps(vars_))
")
  
  sqlite3 "$PROMPT_DB" "INSERT OR REPLACE INTO prompts (id, name, category, content, variables) VALUES ('$pid','$name','$category','$content','$vars');"
  echo -e "\n${GREEN}✓${NC} Prompt '$pid' saved  (variables: $vars)"
}

cmd_edit() {
  local pid="$1"
  [[ -z "$pid" ]] && { echo -e "${RED}✗${NC} Usage: br prompt edit <id>"; return 1; }
  local content
  content=$(sqlite3 "$PROMPT_DB" "SELECT content FROM prompts WHERE id='$pid';")
  [[ -z "$content" ]] && { echo -e "${RED}✗${NC} Not found: $pid"; return 1; }
  
  local tmpfile
  tmpfile=$(mktemp /tmp/br-prompt-XXXXXX.txt)
  echo "$content" > "$tmpfile"
  ${EDITOR:-nano} "$tmpfile"
  local new_content
  new_content=$(cat "$tmpfile")
  rm "$tmpfile"
  
  local vars
  vars=$(echo "$new_content" | python3 -c "
import sys, re, json
c = sys.stdin.read()
vars_ = list(dict.fromkeys(re.findall(r'\{\{(\w+)(?:\|[^}]*)?\}\}', c)))
print(json.dumps(vars_))
")
  sqlite3 "$PROMPT_DB" "UPDATE prompts SET content='$new_content', variables='$vars', updated_at=strftime('%s','now') WHERE id='$pid';"
  echo -e "${GREEN}✓${NC} Updated: $pid"
}

cmd_search() {
  local query="$1"
  [[ -z "$query" ]] && { echo -e "${RED}✗${NC} Usage: br prompt search <query>"; return 1; }
  
  echo -e "\n${BOLD}${CYAN}Search: \"$query\"${NC}\n"
  python3 - "$PROMPT_DB" "$query" <<'PY'
import sqlite3, sys
db, q = sys.argv[1], sys.argv[2].lower()
conn = sqlite3.connect(db)
rows = conn.execute("SELECT id, name, category, tags, content FROM prompts").fetchall()
results = []
for id_, name, cat, tags, content in rows:
    if q in id_.lower() or q in name.lower() or q in (tags or '').lower() or q in content.lower():
        results.append((id_, name, cat, tags, content[:80]))

for id_, name, cat, tags, snippet in results:
    print(f"  \033[1m{id_:<20}\033[0m  \033[36m{cat}\033[0m  {name}")
    print(f"    \033[90m{snippet.replace(chr(10),' ')}...\033[0m\n")

if not results:
    print("  No results found.")
conn.close()
PY
}

cmd_run() {
  # Shortcut: br prompt run <id> [vars...] | br llm ask
  local pid="$1"; shift
  local rendered
  rendered=$(cmd_use "$pid" "$@" 2>/dev/null)
  if [[ $? -eq 0 ]]; then
    echo "$rendered"
  fi
}

cmd_history() {
  echo -e "\n${BOLD}${CYAN}📜 Prompt History${NC}\n"
  python3 - "$PROMPT_DB" <<'PY'
import sqlite3, sys, time
db = sys.argv[1]
conn = sqlite3.connect(db)
rows = conn.execute("""
  SELECT h.prompt_id, p.name, h.rendered, h.used_at
  FROM prompt_history h LEFT JOIN prompts p ON h.prompt_id=p.id
  ORDER BY h.used_at DESC LIMIT 20
""").fetchall()
for pid, name, rendered, ts in rows:
    dt = time.strftime('%m/%d %H:%M', time.localtime(ts)) if ts else '?'
    print(f"  \033[90m{dt}\033[0m  \033[1m{pid}\033[0m  {(name or '?')}")
    print(f"    \033[90m{rendered[:100].replace(chr(10),' ')}...\033[0m\n")
conn.close()
PY
}

cmd_delete() {
  local pid="$1"
  [[ -z "$pid" ]] && { echo -e "${RED}✗${NC} Usage: br prompt delete <id>"; return 1; }
  sqlite3 "$PROMPT_DB" "DELETE FROM prompts WHERE id='$pid';"
  echo -e "${GREEN}✓${NC} Deleted: $pid"
}

show_help() {
  echo -e "\n${BOLD}${PURPLE}💜 BR Prompt — LLM Prompt Library${NC}\n"
  echo -e "  ${CYAN}br prompt list [category]${NC}     — list all prompts"
  echo -e "  ${CYAN}br prompt show <id>${NC}           — show prompt content"
  echo -e "  ${CYAN}br prompt use <id> [k=v ...]${NC}  — render prompt with variables"
  echo -e "  ${CYAN}br prompt search <query>${NC}       — search prompts"
  echo -e "  ${CYAN}br prompt add <id> <name> [cat]${NC} — add new prompt"
  echo -e "  ${CYAN}br prompt edit <id>${NC}           — edit prompt in \$EDITOR"
  echo -e "  ${CYAN}br prompt history${NC}             — show usage history"
  echo -e "  ${CYAN}br prompt delete <id>${NC}         — delete prompt"
  echo -e "\n  ${YELLOW}Tip:${NC} br prompt use code-review language=python code=\$(pbpaste)"
  echo -e "  ${YELLOW}Tip:${NC} br prompt use commit-msg diff=\$(git diff) | br llm ask lucidia\n"
}

init_db
case "${1:-help}" in
  list|ls)       cmd_list "$2" ;;
  show|view|get) cmd_show "$2" ;;
  use|render)    cmd_use "$2" "${@:3}" ;;
  add|new|save)  cmd_add "$2" "$3" "$4" ;;
  edit|update)   cmd_edit "$2" ;;
  search|find)   cmd_search "$2" ;;
  run)           cmd_run "$2" "${@:3}" ;;
  history|log)   cmd_history ;;
  delete|rm)     cmd_delete "$2" ;;
  help|--help|-h) show_help ;;
  *) show_help ;;
esac

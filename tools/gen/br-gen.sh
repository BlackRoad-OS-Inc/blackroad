#!/bin/zsh
# BR Gen — Code & File Generator
# Scaffold files, boilerplate, components from templates

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'
BOLD='\033[1m'

GEN_DB="$HOME/.blackroad/gen.db"
TEMPLATES_DIR="$HOME/.blackroad/gen-templates"

init_db() {
  mkdir -p "$TEMPLATES_DIR"
  sqlite3 "$GEN_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT DEFAULT 'general',
  file_pattern TEXT NOT NULL,
  content TEXT NOT NULL,
  variables TEXT DEFAULT '[]',
  description TEXT,
  use_count INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (strftime('%s','now'))
);
CREATE TABLE IF NOT EXISTS gen_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  template_id TEXT,
  output_path TEXT,
  variables TEXT,
  generated_at INTEGER DEFAULT (strftime('%s','now'))
);
SQL

  local count
  count=$(sqlite3 "$GEN_DB" "SELECT COUNT(*) FROM templates;")
  [[ "$count" != "0" ]] && return
  
  # Seed built-in templates
  python3 - "$GEN_DB" <<'PY'
import sys, sqlite3, json

db = sys.argv[1]
conn = sqlite3.connect(db)

templates = [
  ('br-tool', 'BR Tool Script', 'tools', 'tools/{{name}}/br-{{name}}.sh', '''#!/bin/zsh
# BR {{Name}} — {{description}}

GREEN='\\033[0;32m'; RED='\\033[0;31m'; YELLOW='\\033[1;33m'
CYAN='\\033[0;36m'; BLUE='\\033[0;34m'; NC='\\033[0m'; BOLD='\\033[1m'

DB_FILE="$HOME/.blackroad/{{name}}.db"

init_db() {
  mkdir -p "$(dirname "$DB_FILE")"
  sqlite3 "$DB_FILE" <<SQL
CREATE TABLE IF NOT EXISTS {{name}}_items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER DEFAULT (strftime('%s','now'))
);
SQL
}

cmd_list() {
  echo -e "\\n${BOLD}${CYAN}{{Name}} — List${NC}\\n"
  sqlite3 "$DB_FILE" "SELECT id, name FROM {{name}}_items ORDER BY created_at DESC;"
}

cmd_add() {
  local id="$1" name="$2"
  [[ -z "$id" ]] && { echo -e "${RED}✗${NC} Usage: br {{name}} add <id> <name>"; return 1; }
  sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO {{name}}_items (id, name) VALUES ('$id','$name');"
  echo -e "${GREEN}✓${NC} Added: $id"
}

show_help() {
  echo -e "\\n${BOLD}${CYAN}BR {{Name}}${NC}\\n"
  echo -e "  ${CYAN}br {{name}} list${NC}          — list items"
  echo -e "  ${CYAN}br {{name}} add <id> <name>${NC} — add item"
  echo -e "  ${CYAN}br {{name}} help${NC}           — show help\\n"
}

init_db
case "${1:-help}" in
  list|ls) cmd_list ;;
  add|new) cmd_add "$2" "$3" ;;
  help|--help|-h) show_help ;;
  *) show_help ;;
esac
''', '["name","Name","description"]', 'New BR CLI tool with SQLite'),

  ('react-component', 'React Component', 'frontend', '{{path}}/{{Name}}.tsx', '''import React from 'react'

interface {{Name}}Props {
  {{props}}
}

export function {{Name}}({ {{prop_names}} }: {{Name}}Props) {
  return (
    <div className="{{class_name}}">
      <h2>{{Name}}</h2>
    </div>
  )
}

export default {{Name}}
''', '["Name","path","props","prop_names","class_name"]', 'React TypeScript component'),

  ('api-route', 'Next.js API Route', 'frontend', '{{path}}/route.ts', '''import { NextRequest, NextResponse } from 'next/server'

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url)
    
    return NextResponse.json({ 
      success: true,
      data: null
    })
  } catch (error) {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    
    return NextResponse.json({ success: true, data: body })
  } catch (error) {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
''', '["path"]', 'Next.js App Router API route'),

  ('cf-worker', 'Cloudflare Worker', 'cloudflare', 'workers/{{name}}/index.ts', '''export interface Env {
  // Add KV/D1/R2 bindings here
  // MY_KV: KVNamespace
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url)
    const { pathname } = url

    if (pathname === '/health') {
      return Response.json({ status: 'ok', worker: '{{name}}' })
    }

    if (pathname === '/api/{{resource}}') {
      if (request.method === 'GET') {
        return Response.json({ data: [] })
      }
      if (request.method === 'POST') {
        const body = await request.json()
        return Response.json({ success: true, data: body })
      }
    }

    return new Response('Not found', { status: 404 })
  }
} satisfies ExportedHandler<Env>
''', '["name","resource"]', 'Cloudflare Worker TypeScript'),

  ('python-module', 'Python Module', 'python', '{{path}}/{{name}}.py', '''"""{{description}}"""
from typing import Optional, List, Dict, Any
import logging

logger = logging.getLogger(__name__)


class {{ClassName}}:
    """{{description}}"""
    
    def __init__(self, {{init_params}}):
        {{init_body}}
    
    def {{method_name}}(self, {{method_params}}) -> {{return_type}}:
        """{{method_description}}"""
        raise NotImplementedError
    
    def __repr__(self) -> str:
        return f"{{ClassName}}()"


def {{function_name}}({{func_params}}) -> {{func_return}}:
    """{{function_description}}"""
    pass
''', '["path","name","description","ClassName","init_params","init_body","method_name","method_params","return_type","method_description","function_name","func_params","func_return","function_description"]', 'Python module with class + function'),

  ('fastapi-endpoint', 'FastAPI Endpoint', 'python', '{{path}}/{{name}}.py', '''from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List

router = APIRouter(prefix="/{{resource}}", tags=["{{resource}}"])


class {{Model}}Base(BaseModel):
    name: str
    description: Optional[str] = None


class {{Model}}Create({{Model}}Base):
    pass


class {{Model}}Response({{Model}}Base):
    id: str


@router.get("/", response_model=List[{{Model}}Response])
async def list_{{resource_plural}}():
    """List all {{resource_plural}}"""
    return []


@router.post("/", response_model={{Model}}Response, status_code=201)
async def create_{{resource}}(data: {{Model}}Create):
    """Create a new {{resource}}"""
    return {"id": "new-id", **data.dict()}


@router.get("/{item_id}", response_model={{Model}}Response)
async def get_{{resource}}(item_id: str):
    """Get a {{resource}} by ID"""
    raise HTTPException(status_code=404, detail="Not found")


@router.delete("/{item_id}", status_code=204)
async def delete_{{resource}}(item_id: str):
    """Delete a {{resource}}"""
    pass
''', '["path","name","resource","resource_plural","Model"]', 'FastAPI CRUD router'),

  ('github-action', 'GitHub Action Workflow', 'ci', '.github/workflows/{{name}}.yml', '''name: {{display_name}}

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
  workflow_dispatch:

jobs:
  {{job_name}}:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: npm
      
      - name: Install dependencies
        run: npm ci
      
      - name: {{step_name}}
        run: {{step_command}}
        env:
          NODE_ENV: test
''', '["name","display_name","job_name","step_name","step_command"]', 'GitHub Actions workflow'),

  ('sqlite-tool', 'SQLite CLI Tool', 'tools', '{{path}}/{{name}}.sh', '''#!/bin/zsh
# {{Name}} — {{description}}

DB="$HOME/.blackroad/{{name}}.db"

setup() {
  sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS items (id TEXT PRIMARY KEY, data TEXT, ts INTEGER DEFAULT (strftime('%s','now')));"
}

add()  { sqlite3 "$DB" "INSERT OR REPLACE INTO items VALUES ('$1','$2',strftime('%s','now'));"; echo "Added: $1"; }
list() { sqlite3 "$DB" "SELECT id, data FROM items ORDER BY ts DESC;"; }
del()  { sqlite3 "$DB" "DELETE FROM items WHERE id='$1';"; echo "Deleted: $1"; }

setup
case "$1" in add) add "$2" "$3" ;; list) list ;; del) del "$2" ;; *) echo "Usage: $0 add|list|del" ;; esac
''', '["path","name","Name","description"]', 'Minimal SQLite shell script'),
]

for t in templates:
    import json as _json
    conn.execute(
        "INSERT OR IGNORE INTO templates (id, name, category, file_pattern, content, variables, description) VALUES (?,?,?,?,?,?,?)",
        (t[0], t[1], t[2], t[3], t[4], t[5], t[6])
    )

conn.commit()
conn.close()
print(f"Seeded {len(templates)} templates")
PY
}

cmd_list() {
  local category="$1"
  local filter=""
  [[ -n "$category" ]] && filter="WHERE category='$category'"
  
  echo -e "\n${BOLD}${PURPLE}🔧 Code Templates${NC}\n"
  python3 - "$GEN_DB" "$filter" <<'PY'
import sqlite3, sys
db = sys.argv[1]
filt = sys.argv[2]
conn = sqlite3.connect(db)
rows = conn.execute(f"SELECT id, name, category, file_pattern, description, use_count FROM templates {filt} ORDER BY category, id").fetchall()

cur_cat = None
for id_, name, cat, pattern, desc, uses in rows:
    if cat != cur_cat:
        print(f"\n  \033[36m{cat.upper()}\033[0m")
        cur_cat = cat
    print(f"    \033[1m{id_:<22}\033[0m  {name:<28}  \033[90m{desc or ''}\033[0m")

print()
conn.close()
PY
}

cmd_show() {
  local tid="$1"
  [[ -z "$tid" ]] && { echo -e "${RED}✗${NC} Usage: br gen show <template>"; return 1; }
  python3 - "$GEN_DB" "$tid" <<'PY'
import sqlite3, sys, json
db, tid = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
row = conn.execute("SELECT id, name, category, file_pattern, content, variables, description FROM templates WHERE id=?", (tid,)).fetchone()
if not row:
    print(f"\033[31m✗\033[0m Not found: {tid}")
    sys.exit(1)
id_, name, cat, pattern, content, variables, desc = row
print(f"\n\033[1m\033[35m{name}\033[0m  ({id_})  [{cat}]")
print(f"  {desc or ''}")
print(f"  Output: {pattern}")
vars_ = json.loads(variables) if variables else []
print(f"  Variables: {', '.join(vars_)}")
print(f"\n\033[36mTemplate:\033[0m")
for line in content[:800].split('\n'):
    print(f"  {line}")
if len(content) > 800:
    print(f"  \033[90m... ({len(content)} total chars)\033[0m")
print()
conn.close()
PY
}

cmd_create() {
  local tid="$1"
  shift
  [[ -z "$tid" ]] && {
    echo -e "${CYAN}Usage: br gen create <template> [var=val ...]${NC}"
    echo -e "Example: br gen create br-tool name=myfeature Name=MyFeature description='My new feature'"
    return 1
  }
  
  python3 - "$GEN_DB" "$tid" "$@" <<'PY'
import sqlite3, sys, re, json, os
db, tid = sys.argv[1], sys.argv[2]
overrides = {}
for arg in sys.argv[3:]:
    if '=' in arg:
        k, v = arg.split('=', 1)
        overrides[k] = v

conn = sqlite3.connect(db)
row = conn.execute("SELECT file_pattern, content, variables FROM templates WHERE id=?", (tid,)).fetchone()
if not row:
    print(f"\033[31m✗\033[0m Template not found: {tid}")
    sys.exit(1)

pattern, content, variables = row
vars_ = json.loads(variables) if variables else []

# Render both filename and content
def render(text):
    result = text
    for match in re.finditer(r'\{\{(\w+)\}\}', text):
        var_name = match.group(1)
        val = overrides.get(var_name, '')
        result = result.replace(match.group(0), val)
    return result

rendered_path = render(pattern)
rendered_content = render(content)

# Check for unfilled variables
remaining = re.findall(r'\{\{(\w+)\}\}', rendered_content + rendered_path)
if remaining:
    print(f"\033[33m⚠\033[0m Missing variables: {', '.join(set(remaining))}")
    print(f"Usage: br gen create {tid} {' '.join(v+'=VALUE' for v in set(remaining))}")
    sys.exit(1)

# Create output file
os.makedirs(os.path.dirname(rendered_path) or '.', exist_ok=True)
if os.path.exists(rendered_path):
    print(f"\033[31m✗\033[0m File exists: {rendered_path}")
    print("  Use --force to overwrite (not yet implemented)")
    sys.exit(1)

with open(rendered_path, 'w') as f:
    f.write(rendered_content)

# Make shell scripts executable
if rendered_path.endswith('.sh'):
    os.chmod(rendered_path, 0o755)

conn.execute("UPDATE templates SET use_count=use_count+1 WHERE id=?", (tid,))
conn.execute("INSERT INTO gen_history (template_id, output_path, variables) VALUES (?, ?, ?)",
             (tid, rendered_path, json.dumps(overrides)))
conn.commit()
conn.close()

print(f"\033[32m✓\033[0m Generated: {rendered_path}")
print(f"  Template: {tid}")
if rendered_path.endswith('.sh'):
    print(f"  \033[90mchmod +x {rendered_path}\033[0m  (already done)")
PY
}

cmd_add() {
  local tid="$1" name="$2" category="${3:-general}" pattern="$4"
  [[ -z "$tid" || -z "$name" || -z "$pattern" ]] && {
    echo -e "${CYAN}Usage: br gen add <id> <name> <category> <file-pattern>${NC}"
    echo -e "  Then enter template content (Ctrl+D to finish)"
    echo -e "  Use {{variable}} placeholders"
    return 1
  }
  echo -e "${CYAN}Enter template content (Ctrl+D when done):${NC}"
  local content
  content=$(cat)
  local vars
  vars=$(echo "$content $pattern" | python3 -c "
import sys, re, json
c = sys.stdin.read()
vars_ = list(dict.fromkeys(re.findall(r'\{\{(\w+)\}\}', c)))
print(json.dumps(vars_))
")
  sqlite3 "$GEN_DB" "INSERT OR REPLACE INTO templates (id, name, category, file_pattern, content, variables) VALUES ('$tid','$name','$category','$pattern','$(echo "$content" | sed "s/'/''/g")','$vars');"
  echo -e "\n${GREEN}✓${NC} Template saved: $tid"
}

cmd_history() {
  echo -e "\n${BOLD}${CYAN}📜 Generation History${NC}\n"
  python3 - "$GEN_DB" <<'PY'
import sqlite3, sys, time
db = sys.argv[1]
conn = sqlite3.connect(db)
rows = conn.execute("""
  SELECT h.template_id, t.name, h.output_path, h.variables, h.generated_at
  FROM gen_history h LEFT JOIN templates t ON h.template_id=t.id
  ORDER BY h.generated_at DESC LIMIT 20
""").fetchall()
for tid, tname, path, vars_, ts in rows:
    dt = time.strftime('%m/%d %H:%M', time.localtime(ts)) if ts else '?'
    print(f"  \033[90m{dt}\033[0m  \033[1m{tid:<20}\033[0m  {path}")
conn.close()
print()
PY
}

show_help() {
  echo -e "\n${BOLD}${PURPLE}🔧 BR Gen — Code Generator${NC}\n"
  echo -e "  ${CYAN}br gen list [category]${NC}           — list templates"
  echo -e "  ${CYAN}br gen show <template>${NC}           — show template"
  echo -e "  ${CYAN}br gen create <template> [k=v ...]${NC} — generate file(s)"
  echo -e "  ${CYAN}br gen add <id> <name> <cat> <pat>${NC} — add template"
  echo -e "  ${CYAN}br gen history${NC}                  — generation history"
  echo -e "\n  ${YELLOW}Categories:${NC} tools | frontend | cloudflare | python | ci | general"
  echo -e "\n  ${YELLOW}Example:${NC}"
  echo -e "    br gen create br-tool name=cache Name=Cache description='Cache manager'"
  echo -e "    br gen create react-component Name=Button path=src/components props='label:string' prop_names=label class_name=btn\n"
}

init_db
case "${1:-help}" in
  list|ls)         cmd_list "$2" ;;
  show|view)       cmd_show "$2" ;;
  create|new|make) cmd_create "$2" "${@:3}" ;;
  add|template)    cmd_add "$2" "$3" "$4" "$5" ;;
  history|log)     cmd_history ;;
  help|--help|-h)  show_help ;;
  *)               show_help ;;
esac

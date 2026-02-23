#!/usr/bin/env zsh
# BR Schema — JSON/YAML schema validator and TypeScript type generator

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD='\033[1m'
DB="$HOME/.blackroad/schema.db"

init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS schemas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  schema_json TEXT NOT NULL,
  source_file TEXT DEFAULT '',
  description TEXT DEFAULT '',
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS validations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  schema_name TEXT NOT NULL,
  target_file TEXT NOT NULL,
  ok INTEGER NOT NULL,
  errors TEXT DEFAULT '',
  ts TEXT DEFAULT (datetime('now'))
);
SQL
}

cmd_validate() {
  local target="$1" schema_ref="${2:-}"
  [[ -z "$target" ]] && { echo "Usage: br schema validate <file.json> [schema_name|schema.json]"; exit 1; }
  [[ ! -f "$target" ]] && { echo -e "${RED}✗ File not found: $target${NC}"; exit 1; }
  echo ""
  echo -e "${CYAN}${BOLD}🔍 Validating: $target${NC}"
  # Resolve schema
  local schema_json=""
  if [[ -n "$schema_ref" ]]; then
    if [[ -f "$schema_ref" ]]; then
      schema_json=$(cat "$schema_ref")
    else
      schema_json=$(sqlite3 "$DB" "SELECT schema_json FROM schemas WHERE name='$schema_ref';")
    fi
  fi
  python3 - "$target" "$DB" <<PY
import json, sys, sqlite3, os

target = sys.argv[1]
db_path = sys.argv[2]

try:
    with open(target) as f:
        data = json.load(f)
    print(f"  ✓ Valid JSON  ({os.path.getsize(target)} bytes)")
    # Basic type analysis
    if isinstance(data, dict):
        print(f"  Type: object  ({len(data)} keys)")
        for k, v in list(data.items())[:10]:
            vtype = type(v).__name__
            vpreview = str(v)[:40] if not isinstance(v, (dict,list)) else f"[{vtype}]"
            print(f"    {k}: {vtype} = {vpreview}")
        if len(data) > 10:
            print(f"    ... ({len(data)-10} more keys)")
    elif isinstance(data, list):
        print(f"  Type: array  ({len(data)} items)")
        if data:
            print(f"  Item type: {type(data[0]).__name__}")
    print()
    print("  ✓ Structure looks valid")
except json.JSONDecodeError as e:
    print(f"  ✗ JSON parse error: {e}")
    sys.exit(1)
PY
  echo ""
}

cmd_infer() {
  local input="$1" name="${2:-inferred-$(date +%s)}"
  [[ -z "$input" ]] && { echo "Usage: br schema infer <file.json> [schema_name]"; exit 1; }
  [[ ! -f "$input" ]] && { echo -e "${RED}✗ File not found: $input${NC}"; exit 1; }
  echo ""
  echo -e "${CYAN}${BOLD}🔬 Inferring schema from: $input${NC}"
  python3 - "$input" "$name" "$DB" <<'PY'
import json, sys, sqlite3

input_file, name, db_path = sys.argv[1], sys.argv[2], sys.argv[3]

def infer_type(val):
    if val is None: return {"type": "null"}
    if isinstance(val, bool): return {"type": "boolean"}
    if isinstance(val, int): return {"type": "integer"}
    if isinstance(val, float): return {"type": "number"}
    if isinstance(val, str):
        s = {"type": "string"}
        if len(val) > 0 and val[0] in '{[': pass
        if 'T' in val and ':' in val: s["format"] = "date-time"
        elif val.startswith('http'): s["format"] = "uri"
        return s
    if isinstance(val, list):
        if not val: return {"type": "array"}
        item_schema = infer_type(val[0])
        return {"type": "array", "items": item_schema}
    if isinstance(val, dict):
        props = {k: infer_type(v) for k, v in val.items()}
        return {"type": "object", "properties": props, "required": list(val.keys())}
    return {}

with open(input_file) as f:
    data = json.load(f)

schema = {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": name
}
schema.update(infer_type(data))

schema_str = json.dumps(schema, indent=2)
print(schema_str[:2000])
if len(schema_str) > 2000:
    print(f"\n  ... ({len(schema_str)-2000} more bytes)")

# Save to DB
db = sqlite3.connect(db_path)
db.execute("INSERT OR REPLACE INTO schemas (name, schema_json, source_file, updated_at) VALUES (?, ?, ?, datetime('now'))",
           (name, schema_str, input_file))
db.commit()
print(f"\n✓ Schema '{name}' saved to registry")
PY
  echo ""
}

cmd_ts() {
  local schema_ref="$1" out="${2:-}"
  [[ -z "$schema_ref" ]] && { echo "Usage: br schema ts <schema_name|file> [output.ts]"; exit 1; }
  local schema_json=""
  if [[ -f "$schema_ref" ]]; then
    schema_json=$(cat "$schema_ref")
  else
    schema_json=$(sqlite3 "$DB" "SELECT schema_json FROM schemas WHERE name='$schema_ref';")
  fi
  [[ -z "$schema_json" ]] && { echo -e "${RED}✗ Schema not found: $schema_ref${NC}"; exit 1; }
  echo ""
  echo -e "${CYAN}${BOLD}📝 TypeScript Types: $schema_ref${NC}"
  echo ""
  echo "$schema_json" | python3 -c "
import json, sys

def json_type_to_ts(schema, name='', indent=0):
    pad = '  ' * indent
    t = schema.get('type', 'any')
    if t == 'object':
        lines = []
        props = schema.get('properties', {})
        req = schema.get('required', list(props.keys()))
        for k, v in props.items():
            opt = '' if k in req else '?'
            ts_type = json_type_to_ts(v, k, indent+1)
            lines.append(f'{pad}  {k}{opt}: {ts_type};')
        body = '\n'.join(lines)
        return f'{{\n{body}\n{pad}}}'
    elif t == 'array':
        items = schema.get('items', {})
        item_type = json_type_to_ts(items, '', indent)
        return f'{item_type}[]'
    elif t == 'string':
        fmt = schema.get('format', '')
        if fmt == 'date-time': return 'string // ISO date-time'
        if fmt == 'uri': return 'string // URL'
        return 'string'
    elif t == 'integer': return 'number'
    elif t == 'number': return 'number'
    elif t == 'boolean': return 'boolean'
    elif t == 'null': return 'null'
    else: return 'unknown'

data = json.load(sys.stdin)
title = data.get('title', 'Generated')
ts_type = json_type_to_ts(data)
print(f'// Auto-generated by br schema ts')
print(f'// Source: {title}')
print()
if ts_type.startswith('{'):
    print(f'export interface {title} {ts_type}')
else:
    print(f'export type {title} = {ts_type}')
"
  echo ""
}

cmd_diff() {
  local a="$1" b="$2"
  [[ -z "$a" || -z "$b" ]] && { echo "Usage: br schema diff <schema_a> <schema_b>"; exit 1; }
  local json_a json_b
  [[ -f "$a" ]] && json_a=$(cat "$a") || json_a=$(sqlite3 "$DB" "SELECT schema_json FROM schemas WHERE name='$a';")
  [[ -f "$b" ]] && json_b=$(cat "$b") || json_b=$(sqlite3 "$DB" "SELECT schema_json FROM schemas WHERE name='$b';")
  echo ""
  echo -e "${CYAN}📊 Schema Diff: $a vs $b${NC}"
  echo ""
  python3 -c "
import json, sys
a = json.loads('''$json_a''')
b = json.loads('''$json_b''')

def get_keys(schema, prefix=''):
    keys = set()
    if schema.get('type') == 'object':
        for k, v in schema.get('properties', {}).items():
            full = f'{prefix}.{k}' if prefix else k
            keys.add(full)
            keys.update(get_keys(v, full))
    return keys

ka = get_keys(a)
kb = get_keys(b)
added = kb - ka
removed = ka - kb
common = ka & kb

for k in sorted(added): print(f'  \033[0;32m+ {k}\033[0m')
for k in sorted(removed): print(f'  \033[0;31m- {k}\033[0m')
print(f'  {len(common)} fields in common, {len(added)} added, {len(removed)} removed')
"
  echo ""
}

cmd_list() {
  echo ""
  echo -e "${CYAN}📚 Schema Registry${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT name, source_file, description, updated_at FROM schemas ORDER BY updated_at DESC;" | while IFS="|" read -r name src desc upd; do
    printf "  ${GREEN}%-20s${NC}  %-30s  %s\n" "$name" "$src" "${upd:0:16}"
    [[ -n "$desc" ]] && printf "    %s\n" "$desc"
  done
  echo ""
}

cmd_save() {
  local name="$1" file="$2"
  [[ -z "$name" || -z "$file" ]] && { echo "Usage: br schema save <name> <schema.json>"; exit 1; }
  [[ ! -f "$file" ]] && { echo -e "${RED}✗ File not found: $file${NC}"; exit 1; }
  local json; json=$(cat "$file")
  sqlite3 "$DB" "INSERT OR REPLACE INTO schemas (name, schema_json, source_file, updated_at) VALUES ('$name', '$json', '$file', datetime('now'));"
  echo -e "${GREEN}✓ Schema '$name' saved${NC}"
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br schema${NC} — JSON/YAML schema validator & type generator"
  echo ""
  echo -e "  ${GREEN}br schema validate <file> [schema]${NC}  Validate JSON file"
  echo -e "  ${GREEN}br schema infer <file> [name]${NC}       Infer schema from JSON sample"
  echo -e "  ${GREEN}br schema ts <schema_name|file>${NC}     Generate TypeScript types"
  echo -e "  ${GREEN}br schema diff <a> <b>${NC}              Diff two schemas"
  echo -e "  ${GREEN}br schema list${NC}                      Schema registry"
  echo -e "  ${GREEN}br schema save <name> <file>${NC}        Save schema to registry"
  echo ""
}

init_db
case "${1:-list}" in
  validate|check)  shift; cmd_validate "$@" ;;
  infer|generate)  shift; cmd_infer "$@" ;;
  ts|types)        shift; cmd_ts "$@" ;;
  diff)            shift; cmd_diff "$@" ;;
  list|ls)         cmd_list ;;
  save|add)        shift; cmd_save "$@" ;;
  help|-h|--help)  show_help ;;
  *)               show_help ;;
esac

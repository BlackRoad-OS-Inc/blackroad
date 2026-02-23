#!/bin/zsh
# BR Cost — AI Usage & Cost Tracker
# Track tokens used, estimate costs, set budgets

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'
BOLD='\033[1m'

COST_DB="$HOME/.blackroad/cost.db"

init_db() {
  mkdir -p "$(dirname "$COST_DB")"
  sqlite3 "$COST_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS usage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  model TEXT NOT NULL,
  provider TEXT NOT NULL,
  prompt_tokens INTEGER DEFAULT 0,
  completion_tokens INTEGER DEFAULT 0,
  total_tokens INTEGER DEFAULT 0,
  cost_usd REAL DEFAULT 0.0,
  tool TEXT DEFAULT 'manual',
  note TEXT,
  recorded_at INTEGER DEFAULT (strftime('%s','now'))
);
CREATE TABLE IF NOT EXISTS budgets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  period TEXT DEFAULT 'monthly',
  limit_usd REAL NOT NULL,
  alert_pct INTEGER DEFAULT 80,
  created_at INTEGER DEFAULT (strftime('%s','now'))
);
CREATE TABLE IF NOT EXISTS model_pricing (
  model TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  input_per_1k REAL NOT NULL,
  output_per_1k REAL NOT NULL,
  updated_at INTEGER DEFAULT (strftime('%s','now'))
);
SQL
  # Seed pricing data
  local count
  count=$(sqlite3 "$COST_DB" "SELECT COUNT(*) FROM model_pricing;")
  if [[ "$count" == "0" ]]; then
    sqlite3 "$COST_DB" <<'SQL'
INSERT OR IGNORE INTO model_pricing VALUES
  -- Anthropic
  ('claude-opus-4-5',      'anthropic', 0.015,  0.075,  strftime('%s','now')),
  ('claude-sonnet-4-5',    'anthropic', 0.003,  0.015,  strftime('%s','now')),
  ('claude-haiku-3-5',     'anthropic', 0.0008, 0.004,  strftime('%s','now')),
  ('claude-3-opus',        'anthropic', 0.015,  0.075,  strftime('%s','now')),
  ('claude-3-sonnet',      'anthropic', 0.003,  0.015,  strftime('%s','now')),
  ('claude-3-haiku',       'anthropic', 0.00025,0.00125,strftime('%s','now')),
  -- OpenAI
  ('gpt-4o',               'openai',    0.005,  0.015,  strftime('%s','now')),
  ('gpt-4o-mini',          'openai',    0.00015,0.0006, strftime('%s','now')),
  ('gpt-4-turbo',          'openai',    0.01,   0.03,   strftime('%s','now')),
  ('gpt-3.5-turbo',        'openai',    0.0005, 0.0015, strftime('%s','now')),
  ('o1',                   'openai',    0.015,  0.060,  strftime('%s','now')),
  ('o1-mini',              'openai',    0.003,  0.012,  strftime('%s','now')),
  -- Google
  ('gemini-1.5-pro',       'google',    0.00125,0.005,  strftime('%s','now')),
  ('gemini-1.5-flash',     'google',    0.000075,0.0003,strftime('%s','now')),
  ('gemini-2.0-flash',     'google',    0.0001, 0.0004, strftime('%s','now')),
  -- Ollama (local = free)
  ('qwen2.5:7b',           'ollama',    0.0,    0.0,    strftime('%s','now')),
  ('qwen2.5:3b',           'ollama',    0.0,    0.0,    strftime('%s','now')),
  ('qwen2.5:1.5b',         'ollama',    0.0,    0.0,    strftime('%s','now')),
  ('llama3.2:3b',          'ollama',    0.0,    0.0,    strftime('%s','now')),
  ('llama3.2:1b',          'ollama',    0.0,    0.0,    strftime('%s','now')),
  ('lucidia:latest',       'ollama',    0.0,    0.0,    strftime('%s','now')),
  ('tinyllama',            'ollama',    0.0,    0.0,    strftime('%s','now')),
  -- Codex/Copilot
  ('gpt-4-codex',          'openai',    0.01,   0.03,   strftime('%s','now'));
SQL
    echo -e "${GREEN}✓${NC} Seeded pricing for 24 models"
  fi
}

cmd_log() {
  # Log a usage entry manually
  local model="$1" prompt_tok="${2:-0}" completion_tok="${3:-0}" tool="${4:-manual}" note="${5:-}"
  [[ -z "$model" ]] && {
    echo -e "${CYAN}Usage: br cost log <model> <prompt_tokens> <completion_tokens> [tool] [note]${NC}"
    return 1
  }
  
  python3 - "$COST_DB" "$model" "$prompt_tok" "$completion_tok" "$tool" "$note" <<'PY'
import sqlite3, sys
db, model, p_tok, c_tok, tool, note = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5], sys.argv[6]

conn = sqlite3.connect(db)
row = conn.execute("SELECT provider, input_per_1k, output_per_1k FROM model_pricing WHERE model=?", (model,)).fetchone()

if row:
    provider, in_price, out_price = row
    cost = (p_tok / 1000.0 * in_price) + (c_tok / 1000.0 * out_price)
else:
    provider = 'unknown'
    cost = 0.0

total = p_tok + c_tok
conn.execute(
    "INSERT INTO usage (model, provider, prompt_tokens, completion_tokens, total_tokens, cost_usd, tool, note) VALUES (?,?,?,?,?,?,?,?)",
    (model, provider, p_tok, c_tok, total, cost, tool, note)
)
conn.commit()

cost_str = f"${cost:.6f}" if cost > 0 else "free"
print(f"\033[32m✓\033[0m Logged: {model}  {total:,} tokens  {cost_str}")
conn.close()
PY
}

cmd_stats() {
  local period="${1:-month}"
  echo -e "\n${BOLD}${CYAN}💰 AI Usage & Cost Stats${NC}"
  
  python3 - "$COST_DB" "$period" <<'PY'
import sqlite3, sys, time
from datetime import datetime, timedelta

db, period = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)

# Determine time window
now = int(time.time())
if period == 'today':
    since = int(datetime.now().replace(hour=0,minute=0,second=0).timestamp())
    label = 'Today'
elif period == 'week':
    since = now - 7 * 86400
    label = 'Last 7 days'
elif period == 'month':
    d = datetime.now().replace(day=1, hour=0, minute=0, second=0)
    since = int(d.timestamp())
    label = f"This month ({d.strftime('%B %Y')})"
elif period == 'all':
    since = 0
    label = 'All time'
else:
    since = now - int(period) * 86400
    label = f"Last {period} days"

print(f"\n  Period: {label}")

# Overall totals
row = conn.execute("""
    SELECT SUM(total_tokens), SUM(cost_usd), COUNT(*), SUM(prompt_tokens), SUM(completion_tokens)
    FROM usage WHERE recorded_at >= ?
""", (since,)).fetchone()

total_tok, total_cost, requests, p_tok, c_tok = row
total_tok = total_tok or 0
total_cost = total_cost or 0.0
requests = requests or 0

print(f"\n  {'Requests:':<20} {requests:,}")
print(f"  {'Total tokens:':<20} {total_tok:,}")
print(f"  {'  → Prompt:':<20} {(p_tok or 0):,}")
print(f"  {'  → Completion:':<20} {(c_tok or 0):,}")
print(f"  {'Total cost:':<20} \033[1m${total_cost:.4f}\033[0m")

# By model
print(f"\n  \033[36mBy Model:\033[0m")
rows = conn.execute("""
    SELECT model, provider, SUM(total_tokens), SUM(cost_usd), COUNT(*)
    FROM usage WHERE recorded_at >= ?
    GROUP BY model ORDER BY SUM(cost_usd) DESC
""", (since,)).fetchall()

for model, provider, tokens, cost, reqs in rows:
    free_str = '(local)' if cost == 0 else f'${cost:.4f}'
    bar_len = min(20, int((tokens or 0) / max(total_tok, 1) * 20)) if total_tok else 0
    bar = '█' * bar_len + '░' * (20 - bar_len)
    print(f"    {model:<28} {(tokens or 0):>10,} tok  {free_str:>10}  {reqs:>4} req")

# By tool
print(f"\n  \033[36mBy Tool:\033[0m")
rows = conn.execute("""
    SELECT tool, SUM(total_tokens), SUM(cost_usd), COUNT(*)
    FROM usage WHERE recorded_at >= ?
    GROUP BY tool ORDER BY SUM(total_tokens) DESC
""", (since,)).fetchall()

for tool, tokens, cost, reqs in rows:
    print(f"    {tool:<20} {(tokens or 0):>10,} tok  ${(cost or 0):.4f}  {reqs} req")

# Ollama savings estimate
ollama_rows = conn.execute("""
    SELECT SUM(total_tokens) FROM usage WHERE provider='ollama' AND recorded_at >= ?
""", (since,)).fetchone()
ollama_tokens = ollama_rows[0] or 0
if ollama_tokens > 0:
    # Estimate what it would cost on GPT-4o
    estimated_gpt4o = ollama_tokens / 1000.0 * 0.01
    print(f"\n  \033[32m✓ Ollama savings: {ollama_tokens:,} free tokens ≈ ${estimated_gpt4o:.2f} if on GPT-4o\033[0m")

print()
conn.close()
PY
}

cmd_models() {
  echo -e "\n${BOLD}${CYAN}📋 Model Pricing${NC}\n"
  python3 - "$COST_DB" <<'PY'
import sqlite3, sys
db = sys.argv[1]
conn = sqlite3.connect(db)
rows = conn.execute("SELECT model, provider, input_per_1k, output_per_1k FROM model_pricing ORDER BY provider, input_per_1k DESC").fetchall()

cur_prov = None
for model, provider, in_price, out_price in rows:
    if provider != cur_prov:
        print(f"\n  \033[36m{provider.upper()}\033[0m")
        cur_prov = provider
    if in_price == 0:
        price_str = '\033[32mFREE (local)\033[0m'
    else:
        price_str = f"in: ${in_price:.5f}/1K  out: ${out_price:.5f}/1K"
    print(f"    {model:<30}  {price_str}")

print()
conn.close()
PY
}

cmd_budget() {
  local action="$1"
  case "$action" in
    set)
      local bid="$2" name="$3" limit="$4" period="${5:-monthly}"
      [[ -z "$bid" || -z "$limit" ]] && {
        echo -e "${CYAN}Usage: br cost budget set <id> <name> <limit_usd> [monthly|weekly|daily]${NC}"
        return 1
      }
      sqlite3 "$COST_DB" "INSERT OR REPLACE INTO budgets (id, name, limit_usd, period) VALUES ('$bid','$name',$limit,'$period');"
      echo -e "${GREEN}✓${NC} Budget set: $bid = \$$limit/$period"
      ;;
    check|status)
      python3 - "$COST_DB" <<'PY'
import sqlite3, sys, time
from datetime import datetime
db = sys.argv[1]
conn = sqlite3.connect(db)
budgets = conn.execute("SELECT id, name, period, limit_usd, alert_pct FROM budgets").fetchall()

if not budgets:
    print("  No budgets set. Use: br cost budget set <id> <name> <limit>")
else:
    for bid, name, period, limit, alert in budgets:
        now = int(time.time())
        if period == 'daily':
            since = int(datetime.now().replace(hour=0,minute=0,second=0).timestamp())
        elif period == 'weekly':
            since = now - 7 * 86400
        else:  # monthly
            d = datetime.now().replace(day=1,hour=0,minute=0,second=0)
            since = int(d.timestamp())
        
        row = conn.execute("SELECT COALESCE(SUM(cost_usd),0) FROM usage WHERE recorded_at >= ?", (since,)).fetchone()
        spent = row[0]
        pct = (spent / limit * 100) if limit > 0 else 0
        
        bar_fill = int(pct / 5)
        bar = ('█' * bar_fill + '░' * (20 - bar_fill))[:20]
        
        color = '\033[31m' if pct >= alert else '\033[33m' if pct >= 60 else '\033[32m'
        print(f"\n  {name} ({period})")
        print(f"  [{color}{bar}\033[0m] {color}${spent:.4f} / ${limit:.2f} ({pct:.1f}%)\033[0m")
        if pct >= alert:
            print(f"  \033[31m⚠ ALERT: {pct:.0f}% of budget used!\033[0m")

conn.close()
PY
      ;;
    *)
      echo -e "${CYAN}Usage: br cost budget set|check${NC}"
      ;;
  esac
}

cmd_estimate() {
  local model="$1" tokens="${2:-1000}"
  [[ -z "$model" ]] && {
    echo -e "${CYAN}Usage: br cost estimate <model> [tokens]${NC}"
    echo -e "Example: br cost estimate claude-sonnet-4-5 50000"
    return 1
  }
  
  python3 - "$COST_DB" "$model" "$tokens" <<'PY'
import sqlite3, sys
db, model, tokens = sys.argv[1], sys.argv[2], int(sys.argv[3])
conn = sqlite3.connect(db)
row = conn.execute("SELECT provider, input_per_1k, output_per_1k FROM model_pricing WHERE model LIKE ?", (f'%{model}%',)).fetchone()
if not row:
    print(f"\033[31m✗\033[0m Model not found: {model}")
    sys.exit(1)

provider, in_price, out_price = row
# Assume 50/50 split for estimation
cost_in = (tokens * 0.5) / 1000 * in_price
cost_out = (tokens * 0.5) / 1000 * out_price
total = cost_in + cost_out

print(f"\n  Model: {model} ({provider})")
print(f"  Tokens: {tokens:,} (est. 50% in / 50% out)")
print(f"  Input:  ${cost_in:.6f}")
print(f"  Output: ${cost_out:.6f}")
if total == 0:
    print(f"  \033[32mTotal:  FREE (local model)\033[0m")
else:
    print(f"  \033[1mTotal:  ${total:.6f}\033[0m")
    print(f"\n  1K requests: ${total * 1000:.2f}")
    print(f"  1M requests: ${total * 1000000:.2f}")
print()
conn.close()
PY
}

show_help() {
  echo -e "\n${BOLD}${CYAN}💰 BR Cost — AI Usage Tracker${NC}\n"
  echo -e "  ${CYAN}br cost stats [today|week|month|all]${NC}  — usage stats"
  echo -e "  ${CYAN}br cost models${NC}                        — pricing table"
  echo -e "  ${CYAN}br cost log <model> <p_tok> <c_tok>${NC}   — log usage"
  echo -e "  ${CYAN}br cost estimate <model> [tokens]${NC}     — estimate cost"
  echo -e "  ${CYAN}br cost budget set <id> <name> <\$>${NC}   — set budget"
  echo -e "  ${CYAN}br cost budget check${NC}                  — check budgets"
  echo -e "\n  ${YELLOW}Auto-integrated with:${NC} br llm (logs automatically)\n"
}

init_db
case "${1:-help}" in
  stats|usage|summary) cmd_stats "${2:-month}" ;;
  models|pricing)      cmd_models ;;
  log|add|record)      cmd_log "$2" "$3" "$4" "$5" "$6" ;;
  estimate|calc)       cmd_estimate "$2" "$3" ;;
  budget)              cmd_budget "$2" "${@:3}" ;;
  help|--help|-h)      show_help ;;
  *)                   show_help ;;
esac

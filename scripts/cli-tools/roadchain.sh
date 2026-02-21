#!/bin/bash
# RoadChain CLI — AI compute ledger, burns, sessions, fleet, chain blocks
# Usage: roadchain <command>

LEDGER="$HOME/.roadchain/ai-compute-ledger.jsonl"
BURNS="$HOME/.roadchain/burns.jsonl"
WALLET="$HOME/.roadchain/wallets/alexa.json"
ECON="$HOME/.roadchain/economics.json"
CHAIN="$HOME/.roadchain/chain.json"
WALLETS_DIR="$HOME/.roadchain/wallets"

case "${1:-help}" in

live)
python3 - "$LEDGER" "$BURNS" "$WALLET" "$ECON" << 'PYEOF'
import json, os, sys
from datetime import datetime
from collections import defaultdict

LEDGER, BURNS, WALLET, ECON = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

P = "\033[38;2;255;29;108m"
A = "\033[38;2;245;166;35m"
V = "\033[38;2;156;39;176m"
B = "\033[38;2;41;121;255m"
G = "\033[38;2;0;200;83m"
W = "\033[1;37m"
D = "\033[2m"
R = "\033[0m"

def load_json(path):
    try:
        with open(path) as f: return json.load(f)
    except: return {}

def count_lines(path):
    try:
        with open(path) as f: return sum(1 for _ in f)
    except: return 0

def last_n_lines(path, n=20):
    try:
        with open(path) as f: lines = f.readlines()
        return lines[-n:]
    except: return []

def read_all_lines(path):
    try:
        with open(path) as f: return f.readlines()
    except: return []

print(f"\033[2J\033[H", end="")
print(f"{P}╔{'═'*94}╗{R}")
print(f"{P}║{A}  ⛓️  ROADCHAIN AI COMPUTE LEDGER  {D}live{R}{P}{' '*54}║{R}")
print(f"{P}╚{'═'*94}╝{R}")

w = load_json(WALLET)
e = load_json(ECON)
total_burned = e.get("total_road_burned", 0)
balance = w.get("balance", 0)
total_entries = count_lines(LEDGER)
total_burns = count_lines(BURNS)

# Scan full ledger for running totals + session data + burn rate
peak_tokens = 0
first_ts = None
last_ts = None
sessions = defaultdict(lambda: {"cost": 0, "tokens": 0, "burned": 0, "entries": 0, "first_ts": None, "last_ts": None, "cwd": "", "lines_added": 0, "lines_removed": 0})
# For burn rate: last 60 seconds of burns
recent_burns_60s = []
now_ts = datetime.now().timestamp()

for line in read_all_lines(LEDGER):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        t = d.get("tokens", 0)
        if t > peak_tokens: peak_tokens = t
        ts = d.get("ts", 0)
        if first_ts is None: first_ts = ts
        last_ts = ts
        # Session tracking
        sid = d.get("session", "unknown")
        s = sessions[sid]
        s["entries"] += 1
        s["cost"] = max(s["cost"], d.get("cost_usd", 0))
        s["tokens"] = max(s["tokens"], t)
        s["burned"] += d.get("road_burned", 0)
        s["lines_added"] = max(s["lines_added"], d.get("lines_added", 0))
        s["lines_removed"] = max(s["lines_removed"], d.get("lines_removed", 0))
        if s["first_ts"] is None: s["first_ts"] = ts
        s["last_ts"] = ts
        cwd = d.get("cwd", "")
        if cwd: s["cwd"] = cwd
        # Recent burns for rate calc
        delta = d.get("cost_delta", 0)
        if delta > 0 and (now_ts - ts) <= 300:
            recent_burns_60s.append({"ts": ts, "burned": d.get("road_burned", 0), "usd": delta})
    except: pass

# Scan burns for totals
burn_usd = 0
burn_road = 0
burn_tokens = 0
for line in read_all_lines(BURNS):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        burn_usd += d.get("usd_cost", 0)
        burn_road += d.get("road_burned", 0)
        burn_tokens += d.get("tokens", 0)
    except: pass

# Burn rate calculation (over last 5 minutes)
burn_rate_min = 0
burn_rate_usd_min = 0
if recent_burns_60s:
    window = now_ts - min(b["ts"] for b in recent_burns_60s)
    if window > 0:
        total_recent_road = sum(b["burned"] for b in recent_burns_60s)
        total_recent_usd = sum(b["usd"] for b in recent_burns_60s)
        burn_rate_min = (total_recent_road / window) * 60
        burn_rate_usd_min = (total_recent_usd / window) * 60

# Uptime
uptime_str = ""
elapsed = 0
if first_ts and last_ts:
    elapsed = last_ts - first_ts
    hrs = int(elapsed // 3600)
    mins = int((elapsed % 3600) // 60)
    secs = int(elapsed % 60)
    uptime_str = f"{hrs}h {mins}m {secs}s"

print()
print(f"  {A}WALLET{R}  {G}{balance:,.4f} ROAD{R}  {D}│{R}  {P}BURNED{R}  {total_burned:,.4f} ROAD  {D}│{R}  {V}ENTRIES{R} {total_entries}  {D}│{R}  {B}BURNS{R} {total_burns}  {D}│{R}  {P}PEAK{R} {peak_tokens:,} tokens")
print()
print(f"  {D}{'─'*94}{R}")
print(f"  {D}TIME      MODEL         CTX            COST       DELTA       TOKENS      ROAD BURNED{R}")
print(f"  {D}{'─'*94}{R}")

for line in last_n_lines(LEDGER, 18):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        ts = datetime.fromtimestamp(d["ts"]).strftime("%H:%M:%S")
        model = d.get("model", "?")[:10]
        ctx = d.get("ctx_pct", 0)
        cost = d.get("cost_usd", 0)
        delta = d.get("cost_delta", 0)
        tokens = d.get("tokens", 0)
        burned = d.get("road_burned", 0)
        dc = G if delta > 0 else D
        bc = P if burned > 0 else D
        ctx_bar = "▓" * (ctx // 10) + "░" * (10 - ctx // 10)
        print(f"  {B}{ts}{R}  {A}{model:>10}{R}  {V}{ctx_bar}{R} {ctx:>2}%  {A}${cost:>7.2f}{R}  {dc}+${delta:>7.4f}{R}  {P}{tokens:>9,}{R}  {bc}{burned:>9.4f} ROAD{R}")
    except: pass

print(f"  {D}{'─'*94}{R}")

# ── Burn rate ──
print(f"\n  {P}🔥 BURN RATE{R}  {A}{burn_rate_min:,.2f} ROAD/min{R}  {D}({A}${burn_rate_usd_min:,.4f}/min{R}{D}){R}  →  {P}{burn_rate_min*60:,.1f} ROAD/hr{R}  →  {V}{burn_rate_min*1440:,.0f} ROAD/day{R}")

# ── Running totals ──
print(f"\n  {A}═══ RUNNING TOTALS ═══{R}")
print(f"  {D}USD spent on AI compute:{R}  {A}${burn_usd:,.4f}{R}            {D}ROAD burned (deflationary):{R}  {P}{burn_road:,.4f} ROAD{R}")
print(f"  {D}Tokens processed:{R}  {G}{burn_tokens:,}{R}          {D}Burn txns:{R} {V}{total_burns}{R}  {D}Ledger entries:{R} {B}{total_entries}{R}")
print(f"  {D}Tracking since:{R}  {B}{datetime.fromtimestamp(first_ts).strftime('%Y-%m-%d %H:%M:%S') if first_ts else 'N/A'}{R}  {D}({uptime_str}){R}")

# ── Active sessions ──
active = [(sid, s) for sid, s in sessions.items() if sid != "unknown" and (now_ts - s["last_ts"]) < 120]
if active:
    print(f"\n  {G}═══ ACTIVE SESSIONS ({len(active)}) ═══{R}")
    for sid, s in sorted(active, key=lambda x: -x[1]["cost"]):
        short_id = sid[:8]
        dur = s["last_ts"] - s["first_ts"] if s["first_ts"] and s["last_ts"] else 0
        dm = int(dur // 60)
        ds = int(dur % 60)
        cwd_short = s["cwd"].replace(os.path.expanduser("~"), "~")[-40:] if s["cwd"] else ""
        print(f"  {B}{short_id}{R}  {A}${s['cost']:>7.2f}{R}  {P}{s['tokens']:>9,} tok{R}  {G}{s['burned']:>8.2f} burned{R}  {D}{dm}m{ds}s{R}  {V}+{s['lines_added']}/-{s['lines_removed']}{R}  {D}{cwd_short}{R}")

print(f"\n  {P}RECENT BURNS:{R}")
for line in last_n_lines(BURNS, 5):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        ts = datetime.fromtimestamp(d["timestamp"]).strftime("%H:%M:%S")
        tk = d.get("tokens", 0)
        sid = d.get("session", "")[:8]
        mm = d.get("millennium_multiplier", "")
        mm_str = f"  ×{mm:.5f}" if mm else ""
        print(f"  {P}🔥{R} {B}{ts}{R}  ${d['usd_cost']:.4f} USD → {A}{d['road_burned']:.4f} ROAD{R}{G}{mm_str}{R}  {P}{tk:,} tokens{R}  {D}[{d['hash']}]{R}  {D}{sid}{R}")
    except: pass

# ── Millennium Prize Multipliers ──
last_burn_lines = last_n_lines(BURNS, 10)
mill_data = None
for line in reversed(last_burn_lines):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        if d.get("type") == "AI_COMPUTE_BURN" and d.get("millennium"):
            mill_data = d
            break
    except: pass

if mill_data:
    mm = mill_data.get("millennium", {})
    combined = mill_data.get("millennium_multiplier", 1.0)
    base = mill_data.get("road_burned_base", mill_data.get("road_burned", 0))
    actual = mill_data.get("road_burned", 0)
    bonus = actual - base

    labels = {
        "p_vs_np":       ("P vs NP        ", "Subset sum density"),
        "riemann":       ("Riemann ζ      ", "Zeta critical line"),
        "yang_mills":    ("Yang-Mills     ", "SU(3) coupling"),
        "navier_stokes": ("Navier-Stokes  ", "Reynolds number"),
        "hodge":         ("Hodge          ", "CY3 Hodge numbers"),
        "bsd":           ("BSD            ", "Elliptic L-function"),
        "poincare":      ("Poincaré       ", "W-entropy functional"),
    }
    colors = [P, V, B, A, G, P, V]

    print(f"\n  {P}═══ MILLENNIUM PRIZE MULTIPLIERS ═══{R}  {D}(×{combined:.5f} combined){R}")
    for i, (key, (label, desc)) in enumerate(labels.items()):
        val = mm.get(key, 1.0)
        contrib = val - 1.0
        bar_len = int(min(contrib * 1000, 10))  # scale: 0.010 = full 10
        bar = "▓" * bar_len + "░" * (10 - bar_len)
        c = colors[i % len(colors)]
        print(f"  {c}{label}{R} {c}{bar}{R} {A}×{val:.5f}{R}  {D}{desc}{R}")

    print(f"  {D}{'─'*60}{R}")
    print(f"  {A}Base burn:{R} {base:.4f}  {P}+ {bonus:.4f} millennium{R}  {G}= {actual:.4f} ROAD{R}")

print(f"\n  {D}Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  │  Refresh: statusline renders every ~1s{R}")
PYEOF
;;

watch)
while true; do
  "$0" live
  sleep "${2:-2}"
done
;;

sessions)
python3 - "$LEDGER" "$BURNS" << 'PYEOF'
import json, os, sys
from datetime import datetime
from collections import defaultdict

LEDGER, BURNS = sys.argv[1], sys.argv[2]
P = "\033[38;2;255;29;108m"; A = "\033[38;2;245;166;35m"; V = "\033[38;2;156;39;176m"
B = "\033[38;2;41;121;255m"; G = "\033[38;2;0;200;83m"; D = "\033[2m"; R = "\033[0m"

sessions = defaultdict(lambda: {"cost": 0, "tokens": 0, "burned": 0, "entries": 0, "first_ts": None, "last_ts": None, "cwd": "", "lines_added": 0, "lines_removed": 0, "model": ""})

for line in open(LEDGER):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        sid = d.get("session", "unknown")
        s = sessions[sid]
        s["entries"] += 1
        s["cost"] = max(s["cost"], d.get("cost_usd", 0))
        s["tokens"] = max(s["tokens"], d.get("tokens", 0))
        s["burned"] += d.get("road_burned", 0)
        s["lines_added"] = max(s["lines_added"], d.get("lines_added", 0))
        s["lines_removed"] = max(s["lines_removed"], d.get("lines_removed", 0))
        ts = d.get("ts", 0)
        if s["first_ts"] is None: s["first_ts"] = ts
        s["last_ts"] = ts
        cwd = d.get("cwd", "")
        if cwd: s["cwd"] = cwd
        m = d.get("model", "")
        if m: s["model"] = m
    except: pass

print(f"\n  {P}⛓️  ROADCHAIN SESSIONS{R}  {D}({len(sessions)} total){R}\n")
print(f"  {D}SESSION     MODEL       COST       TOKENS      BURNED       DURATION   +LINES/-LINES  CWD{R}")
print(f"  {D}{'─'*110}{R}")

total_cost = 0; total_burned = 0; total_tokens = 0
for sid, s in sorted(sessions.items(), key=lambda x: -(x[1]["last_ts"] or 0)):
    if sid == "unknown": continue
    short = sid[:8]
    dur = s["last_ts"] - s["first_ts"] if s["first_ts"] and s["last_ts"] else 0
    dm = int(dur // 60); ds = int(dur % 60)
    cwd_short = s["cwd"].replace(os.path.expanduser("~"), "~")
    if len(cwd_short) > 30: cwd_short = "..." + cwd_short[-27:]
    total_cost += s["cost"]; total_burned += s["burned"]; total_tokens = max(total_tokens, s["tokens"])
    started = datetime.fromtimestamp(s["first_ts"]).strftime("%H:%M") if s["first_ts"] else "?"
    print(f"  {B}{short}{R}  {A}{s['model']:>10}{R}  {A}${s['cost']:>7.2f}{R}  {P}{s['tokens']:>9,}{R}  {G}{s['burned']:>9.2f} ROAD{R}  {D}{dm:>3}m{ds:02d}s{R}  {V}+{s['lines_added']:>4}/-{s['lines_removed']:<4}{R}  {D}{cwd_short}{R}")

print(f"  {D}{'─'*110}{R}")
print(f"  {A}TOTAL{R}                  {A}${total_cost:>7.2f}{R}  {P}{total_tokens:>9,}{R}  {G}{total_burned:>9.2f} ROAD{R}")
print()
PYEOF
;;

fleet)
python3 - "$WALLETS_DIR" "$BURNS" << 'PYEOF'
import json, os, sys, glob
from collections import defaultdict

WALLETS_DIR, BURNS = sys.argv[1], sys.argv[2]
P = "\033[38;2;255;29;108m"; A = "\033[38;2;245;166;35m"; V = "\033[38;2;156;39;176m"
B = "\033[38;2;41;121;255m"; G = "\033[38;2;0;200;83m"; D = "\033[2m"; R = "\033[0m"

print(f"\n  {P}⛓️  ROADCHAIN FLEET WALLETS{R}\n")
print(f"  {D}WALLET          ADDRESS                                            BALANCE          MINED         BURNED{R}")
print(f"  {D}{'─'*110}{R}")

total_bal = 0; total_mined = 0; total_burned = 0
wallets = sorted(glob.glob(os.path.join(WALLETS_DIR, "*.json")))
for wf in wallets:
    try:
        with open(wf) as f: w = json.load(f)
        name = w.get("name", os.path.basename(wf).replace(".json",""))
        addr = w.get("address", "N/A")
        bal = w.get("balance", 0)
        mined = w.get("total_mined", 0)
        burned = w.get("total_burned", 0)
        total_bal += bal; total_mined += mined; total_burned += burned
        # Color based on balance
        bc = G if bal > 0 else P
        print(f"  {A}{name:<14}{R}  {D}{addr[:50]}{R}  {bc}{bal:>14,.4f} ROAD{R}  {G}{mined:>12,.4f}{R}  {P}{burned:>12,.4f}{R}")
    except: pass

print(f"  {D}{'─'*110}{R}")
print(f"  {A}{'TOTAL':<14}{R}  {' '*50}  {G if total_bal > 0 else P}{total_bal:>14,.4f} ROAD{R}  {G}{total_mined:>12,.4f}{R}  {P}{total_burned:>12,.4f}{R}")

# Burn distribution from burns.jsonl
print(f"\n  {P}COMPUTE BURN DISTRIBUTION:{R}")
burn_by_session = defaultdict(lambda: {"usd": 0, "road": 0, "count": 0})
for line in open(BURNS):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        sid = d.get("session", "unknown")[:8]
        burn_by_session[sid]["usd"] += d.get("usd_cost", 0)
        burn_by_session[sid]["road"] += d.get("road_burned", 0)
        burn_by_session[sid]["count"] += 1
    except: pass

for sid, data in sorted(burn_by_session.items(), key=lambda x: -x[1]["road"])[:10]:
    print(f"  {B}{sid}{R}  {A}${data['usd']:>8.4f}{R}  →  {P}{data['road']:>10.4f} ROAD{R}  {D}({data['count']} burns){R}")
print()
PYEOF
;;

commit)
python3 - "$LEDGER" "$BURNS" "$CHAIN" << 'PYEOF'
import json, os, sys, time, hashlib

LEDGER, BURNS, CHAIN = sys.argv[1], sys.argv[2], sys.argv[3]
P = "\033[38;2;255;29;108m"; A = "\033[38;2;245;166;35m"; G = "\033[38;2;0;200;83m"
B = "\033[38;2;41;121;255m"; D = "\033[2m"; R = "\033[0m"

# Load existing chain
with open(CHAIN) as f:
    chain_data = json.load(f)
chain = chain_data.get("chain", [])
last_block = chain[-1] if chain else None
prev_hash = last_block["hash"] if last_block else "0" * 64
block_height = (last_block.get("index", 0) + 1) if last_block else 0

# Read uncommitted burns (burns after last commit timestamp)
last_commit_file = os.path.expanduser("~/.roadchain/.last-commit-ts")
last_commit_ts = 0
if os.path.exists(last_commit_file):
    try:
        with open(last_commit_file) as f: last_commit_ts = float(f.read().strip())
    except: pass

new_burns = []
total_usd = 0; total_road = 0; total_tokens = 0
for line in open(BURNS):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        if d.get("timestamp", 0) > last_commit_ts:
            new_burns.append(d)
            total_usd += d.get("usd_cost", 0)
            total_road += d.get("road_burned", 0)
            total_tokens += d.get("tokens", 0)
    except: pass

if not new_burns:
    print(f"  {D}No uncommitted burns to commit.{R}")
    sys.exit(0)

# Build merkle root from burn hashes
burn_hashes = [b.get("hash", "") for b in new_burns]
def merkle(hashes):
    if not hashes: return "0" * 64
    while len(hashes) > 1:
        if len(hashes) % 2: hashes.append(hashes[-1])
        hashes = [hashlib.sha256((hashes[i] + hashes[i+1]).encode()).hexdigest() for i in range(0, len(hashes), 2)]
    return hashes[0]

merkle_root = merkle(burn_hashes)

# Proof of work (find nonce where hash starts with "000")
block_data = {
    "index": block_height,
    "timestamp": time.time(),
    "type": "AI_COMPUTE_BLOCK",
    "burn_count": len(new_burns),
    "total_usd_burned": round(total_usd, 6),
    "total_road_burned": round(total_road, 8),
    "total_tokens": total_tokens,
    "merkle_root": merkle_root,
    "previous_hash": prev_hash,
    "transactions": [{
        "sender": "AI_COMPUTE",
        "recipient": "BURN_ADDRESS",
        "amount": round(total_road, 8),
        "timestamp": time.time(),
        "hash": merkle_root
    }]
}

nonce = 0
while True:
    block_data["nonce"] = nonce
    block_str = json.dumps(block_data, sort_keys=True)
    block_hash = hashlib.sha256(block_str.encode()).hexdigest()
    if block_hash.startswith("000"):
        break
    nonce += 1

block_data["hash"] = block_hash

# Append to chain
chain.append(block_data)
chain_data["chain"] = chain
with open(CHAIN, "w") as f:
    json.dump(chain_data, f, indent=2)

# Save commit timestamp
with open(last_commit_file, "w") as f:
    f.write(str(time.time()))

print(f"\n  {G}⛓️  BLOCK COMMITTED TO ROADCHAIN{R}")
print(f"  {D}Block:{R}     {A}#{block_height}{R}")
print(f"  {D}Hash:{R}      {B}{block_hash}{R}")
print(f"  {D}Nonce:{R}     {D}{nonce}{R} (PoW: 000...)")
print(f"  {D}Merkle:{R}    {D}{merkle_root[:32]}...{R}")
print(f"  {D}Prev:{R}      {D}{prev_hash[:32]}...{R}")
print(f"  {D}Burns:{R}     {P}{len(new_burns)}{R} transactions")
print(f"  {D}USD:{R}       {A}${total_usd:,.4f}{R}")
print(f"  {D}ROAD:{R}      {P}{total_road:,.4f} ROAD{R} burned")
print(f"  {D}Tokens:{R}    {G}{total_tokens:,}{R}")
print()
PYEOF
;;

wallet)
python3 -c "
import json
w = json.load(open('$WALLET'))
print(f'  Address:  {w[\"address\"]}')
print(f'  Balance:  {w[\"balance\"]:,.8f} ROAD')
print(f'  Mined:    {w.get(\"total_mined\",0):,.8f} ROAD')
print(f'  Burned:   {w.get(\"total_burned\",0):,.8f} ROAD')
"
;;

burns)
N="${2:-10}"
echo "  Last $N burns:"
tail -"$N" "$BURNS" | python3 -c "
import sys, json
from datetime import datetime
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    d = json.loads(line)
    ts = datetime.fromtimestamp(d['timestamp']).strftime('%H:%M:%S')
    tk = d.get('tokens', 0)
    sid = d.get('session', '')[:8]
    print(f'  🔥 {ts}  \${d[\"usd_cost\"]:.4f} → {d[\"road_burned\"]:.4f} ROAD  {tk:,} tokens  [{d[\"hash\"]}]  {sid}')
"
;;

stats)
ENTRIES=$(wc -l < "$LEDGER" 2>/dev/null || echo 0)
BURN_COUNT=$(wc -l < "$BURNS" 2>/dev/null || echo 0)
python3 -c "
import json
e = json.load(open('$ECON'))
w = json.load(open('$WALLET'))
print(f'  Ledger entries:  $ENTRIES')
print(f'  Total burns:     $BURN_COUNT')
print(f'  ROAD burned:     {e.get(\"total_road_burned\",0):,.4f}')
print(f'  Wallet balance:  {w.get(\"balance\",0):,.4f}')
print(f'  Blocks mined:    {w.get(\"blocks_mined\",0)}')
"
;;

millennium)
python3 - "$BURNS" "$ECON" << 'PYEOF'
import json, sys, os, math, statistics
from datetime import datetime
from collections import defaultdict

BURNS, ECON = sys.argv[1], sys.argv[2]
P = "\033[38;2;255;29;108m"
A = "\033[38;2;245;166;35m"
V = "\033[38;2;156;39;176m"
B = "\033[38;2;41;121;255m"
G = "\033[38;2;0;200;83m"
W = "\033[1;37m"
D = "\033[2m"
R = "\033[0m"

# Import millennium module for live computation
mill_mod = None
try:
    import importlib.util
    spec = importlib.util.spec_from_file_location("millennium", os.path.expanduser("~/.roadchain/millennium.py"))
    mill_mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mill_mod)
except: pass

print(f"\033[2J\033[H", end="")
print(f"{P}╔{'═'*94}╗{R}")
print(f"{P}║{A}  🏛️  MILLENNIUM PRIZE PROBLEMS — DEEP ANALYSIS  {D}roadchain millennium{R}{P}{' '*26}║{R}")
print(f"{P}╚{'═'*94}╝{R}")

# Load economics
try:
    with open(ECON) as f: econ = json.load(f)
except: econ = {}

# Scan all millennium burns
mill_burns = []
problem_vals = defaultdict(list)
combined_vals = []
total_base = 0
total_bonus = 0
per_session = defaultdict(lambda: {"count": 0, "bonus": 0, "avg_mult": []})

for line in open(BURNS):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        if d.get("type") == "AI_COMPUTE_BURN" and d.get("millennium"):
            mill_burns.append(d)
            mm = d["millennium"]
            mult = d.get("millennium_multiplier", 1.0)
            base = d.get("road_burned_base", 0)
            actual = d.get("road_burned", 0)
            total_base += base
            total_bonus += (actual - base)
            combined_vals.append(mult)
            for key, val in mm.items():
                problem_vals[key].append(val)
            sid = d.get("session", "unknown")[:8]
            per_session[sid]["count"] += 1
            per_session[sid]["bonus"] += (actual - base)
            per_session[sid]["avg_mult"].append(mult)
    except: pass

activated = econ.get("millennium_activated", "N/A")
total_mill = econ.get("millennium_burns_total", total_bonus)

# ── Header stats ──
print()
print(f"  {A}ACTIVATED{R}  {G}{activated}{R}  {D}│{R}  {P}BURNS{R}  {G}{len(mill_burns)}{R}  {D}│{R}  {A}BASE ROAD{R}  {V}{total_base:,.4f}{R}  {D}│{R}  {P}BONUS ROAD{R}  {G}{total_bonus:,.4f}{R}")
if total_base > 0:
    print(f"  {D}Effective multiplier:{R}  {A}×{(total_base + total_bonus) / total_base:.5f}{R}  {D}│  Extra ROAD burned by math alone:{R}  {P}{total_bonus:,.4f}{R}")
print()

# ── Per-problem deep stats ──
labels = [
    ("p_vs_np",       "P vs NP",         "Subset Sum Solution Density",          P, "NP-complete instance, DP reachability fraction"),
    ("riemann",       "Riemann ζ",       "Zeta on Critical Line Re(s)=½",        V, "Partial sum ζ₅₀(½+it), sigmoid on magnitude"),
    ("yang_mills",    "Yang-Mills",      "SU(3) Mass Gap & Confinement",         B, "One-loop α_s running, confinement ratio"),
    ("navier_stokes", "Navier-Stokes",   "Reynolds Number Turbulence",           A, "Re = (tokens/100K)·(ctx/10)/δ, log-scaled"),
    ("hodge",         "Hodge",           "Calabi-Yau Hodge Numbers h¹¹,h²¹",    G, "SHA-256 → CY3 topology, χ = 2(h¹¹−h²¹)"),
    ("bsd",           "BSD",             "Elliptic Curve L-function L(E,1)",     P, "Point counting mod p, Euler product over 8 primes"),
    ("poincare",      "Poincaré",        "Perelman W-Entropy Functional",        V, "W = τ(R+1) + f − 3, Ricci flow parameter"),
]

print(f"  {W}{'─'*94}{R}")
print(f"  {W}THE SEVEN PROBLEMS{R}")
print(f"  {W}{'─'*94}{R}")

for key, name, full_name, color, method in labels:
    vals = problem_vals.get(key, [])
    if not vals:
        print(f"  {D}{name}: no data{R}")
        continue
    mean = statistics.mean(vals)
    mn = min(vals)
    mx = max(vals)
    std = statistics.stdev(vals) if len(vals) > 1 else 0
    contrib = (mean - 1.0) * total_base  # estimated ROAD contribution

    # Bar: 30-char proportional to max contribution (0.010)
    bar_pct = min((mean - 1.0) / 0.010, 1.0)
    bar_len = int(bar_pct * 30)
    bar = "▓" * bar_len + "░" * (30 - bar_len)

    print()
    print(f"  {color}{name:<15}{R}  {D}{full_name}{R}")
    print(f"  {color}{bar}{R}  {A}mean ×{mean:.5f}{R}  {D}min ×{mn:.5f}  max ×{mx:.5f}  σ {std:.6f}{R}")
    print(f"  {D}{method}{R}")
    print(f"  {D}Est. ROAD contributed:{R}  {color}{contrib:,.4f} ROAD{R}")

# ── Distribution ──
print()
print(f"  {W}{'─'*94}{R}")
print(f"  {W}COMBINED MULTIPLIER DISTRIBUTION{R}  {D}({len(combined_vals)} burns){R}")
print(f"  {W}{'─'*94}{R}")

if combined_vals:
    mean_c = statistics.mean(combined_vals)
    std_c = statistics.stdev(combined_vals) if len(combined_vals) > 1 else 0
    print(f"  {A}Mean:{R}  ×{mean_c:.5f}  {D}│{R}  {V}Median:{R}  ×{statistics.median(combined_vals):.5f}  {D}│{R}  {B}Stdev:{R}  {std_c:.5f}  {D}│{R}  {P}Range:{R}  ×{min(combined_vals):.5f} — ×{max(combined_vals):.5f}")
    print()

    # Histogram
    buckets = [0] * 20
    for m in combined_vals:
        idx = min(int((m - 1.0) * 500), 19)
        buckets[idx] += 1
    max_b = max(buckets) if buckets else 1
    for i, count in enumerate(buckets):
        if count == 0: continue
        lo = 1.0 + i * 0.002
        hi = lo + 0.002
        bar = "█" * int(count / max_b * 50)
        print(f"  {D}{lo:.3f}–{hi:.3f}{R}  {V}{bar}{R}  {D}{count}{R}")

# ── Per-session breakdown ──
print()
print(f"  {W}{'─'*94}{R}")
print(f"  {W}PER-SESSION MILLENNIUM IMPACT{R}")
print(f"  {W}{'─'*94}{R}")
print(f"  {D}{'Session':<10} {'Burns':>6} {'Avg Mult':>10} {'Bonus ROAD':>12}{R}")
print(f"  {D}{'─'*42}{R}")

for sid, data in sorted(per_session.items(), key=lambda x: -x[1]["bonus"]):
    avg = statistics.mean(data["avg_mult"]) if data["avg_mult"] else 1.0
    print(f"  {B}{sid:<10}{R} {G}{data['count']:>6}{R} {A}×{avg:.5f}{R} {P}{data['bonus']:>12.4f}{R}")

# ── Live probe ──
if mill_mod:
    print()
    print(f"  {W}{'─'*94}{R}")
    print(f"  {W}LIVE PROBE — Current Parameter Space{R}")
    print(f"  {W}{'─'*94}{R}")
    import time
    ts = time.time()
    # Probe with extreme parameters
    probes = [
        ("Min burn (startup)",       0.001,  0.01,    1000,  5,  "probe-min",     ts),
        ("Typical session",          0.05,   5.0,   200000, 50,  "probe-typical", ts),
        ("Heavy Opus session",       0.10,  25.0,   500000, 85,  "probe-heavy",   ts),
        ("Turbulent burst",          0.0001, 30.0,  700000, 95,  "probe-turbo",   ts),
        ("Maximum theoretical",      0.0001, 50.0,  999999, 99,  "probe-max",     ts),
    ]
    print(f"  {D}{'Scenario':<25} {'Combined':>10} {'P≠NP':>7} {'Riem':>7} {'Y-M':>7} {'N-S':>7} {'Hodge':>7} {'BSD':>7} {'Poin':>7}{R}")
    print(f"  {D}{'─'*94}{R}")
    for label, delta, cost, tokens, ctx, sid, t in probes:
        mult, bd = mill_mod.compute(delta, cost, tokens, ctx, "Opus 4.6", sid, t)
        print(f"  {A}{label:<25}{R} {G}×{mult:.5f}{R} {P}{bd['p_vs_np']:.5f}{R} {V}{bd['riemann']:.5f}{R} {B}{bd['yang_mills']:.5f}{R} {A}{bd['navier_stokes']:.5f}{R} {G}{bd['hodge']:.5f}{R} {P}{bd['bsd']:.5f}{R} {V}{bd['poincare']:.5f}{R}")

    # Performance
    t0 = time.time()
    for _ in range(1000):
        mill_mod.compute(0.05, 5.0, 200000, 50, "Opus 4.6", "bench", ts)
    elapsed = (time.time() - t0) * 1000 / 1000
    print(f"\n  {D}Performance: {elapsed:.3f}ms/call (budget: <1ms){R}")

print(f"\n  {D}Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}{R}")
PYEOF
;;

help|*)
cat << 'USAGE'
  ⛓️  roadchain — RoadChain AI Compute Ledger CLI

  COMMANDS:
    live         Live dashboard with burn rate + active sessions
    watch [s]    Auto-refresh live view every [s] seconds (default: 2)
    sessions     Per-session breakdown (cost, tokens, burns, lines changed)
    fleet        Multi-wallet view across all agents
    commit       Commit pending burns to chain.json as a PoW block
    wallet       Show wallet balance and address
    burns [n]    Show last [n] burn records (default: 10)
    millennium   Deep analysis of all 7 Millennium Prize multipliers
    stats        Summary statistics
    help         This message
USAGE
;;

esac

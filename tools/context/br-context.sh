#!/usr/bin/env zsh
# BR Context — full AI context snapshot in one view
# br context [show|json|copy|send|update]

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"
INSTANCES_FILE="$BR_ROOT/coordination/collaboration/active-instances.json"
LIVE_CONTEXT="$BR_ROOT/coordination/live/real-time-context.json"
QUEUE_DIR="$BR_ROOT/shared/mesh/queue"
INBOX_DIR="$BR_ROOT/shared/inbox"

gather_context() {
  BR_ROOT="$BR_ROOT" python3 << 'PYEOF'
import json, subprocess, os, datetime

BR_ROOT = os.environ.get('BR_ROOT', os.path.expanduser('~/blackroad'))
JOURNAL = os.path.expanduser('~/.blackroad/memory/journals/master-journal.jsonl')
INSTANCES_FILE = os.path.join(BR_ROOT, 'coordination/collaboration/active-instances.json')
QUEUE_DIR = os.path.join(BR_ROOT, 'shared/mesh/queue')
INBOX_DIR = os.path.join(BR_ROOT, 'shared/inbox')
LIVE_CTX  = os.path.join(BR_ROOT, 'coordination/live/real-time-context.json')

ctx = {
    'generated_at': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    'operator': 'Alexa',
    'instance': 'lucidia-copilot-cli',
    'cwd': BR_ROOT,
}

# Git
try:
    run = lambda c: subprocess.check_output(c, stderr=subprocess.DEVNULL).decode().strip()
    ctx['git'] = {
        'branch': run(['git','-C',BR_ROOT,'branch','--show-current']),
        'dirty_files': len([l for l in run(['git','-C',BR_ROOT,'status','--short']).splitlines() if l and not l.startswith('?')]),
        'commits_ahead': int(run(['git','-C',BR_ROOT,'rev-list','HEAD..operator/master','--count']) or 0),
        'last_commit': run(['git','-C',BR_ROOT,'log','-1','--format=%s'])
    }
except: ctx['git'] = {}

# Ollama
try:
    import urllib.request
    with urllib.request.urlopen('http://localhost:11434/api/tags', timeout=1) as r:
        models = [m['name'] for m in json.loads(r.read()).get('models',[])]
    ctx['ollama'] = {'status': 'running', 'models': models}
except: ctx['ollama'] = {'status': 'offline'}

# Journal
try:
    with open(JOURNAL) as f:
        lines = [l.strip() for l in f if l.strip()]
    last3 = []
    for line in lines[-3:]:
        try:
            d = json.loads(line)
            last3.append({'ts': d.get('timestamp','')[:19], 'action': d.get('action'), 'entity': d.get('entity')})
        except: pass
    ctx['journal'] = {'total': len(lines), 'last_3': last3}
except: ctx['journal'] = {}

# Mesh
try:
    with open(INSTANCES_FILE) as f: inst_data = json.load(f)
    instances = inst_data.get('instances', inst_data)
    if isinstance(instances, dict): instances = list(instances.values())
    ctx['mesh'] = {
        'online':  [i.get('id','?') for i in instances if i.get('status') == 'ONLINE'],
        'standby': [i.get('id','?') for i in instances if i.get('status') == 'STANDBY'],
        'total': len(instances)
    }
except: ctx['mesh'] = {}

# Queue + inboxes
try:
    ctx['queue_depth'] = len(os.listdir(QUEUE_DIR)) if os.path.isdir(QUEUE_DIR) else 0
except: ctx['queue_depth'] = 0
try:
    inboxes = {}
    if os.path.isdir(INBOX_DIR):
        for d in os.listdir(INBOX_DIR):
            p = os.path.join(INBOX_DIR, d)
            n = len(os.listdir(p)) if os.path.isdir(p) else 0
            if n: inboxes[d] = n
    ctx['inboxes'] = inboxes
except: ctx['inboxes'] = {}

# Agents
try:
    ad = os.path.join(BR_ROOT, 'agents/active')
    ctx['agents'] = [json.load(open(os.path.join(ad,f))) for f in os.listdir(ad) if f.endswith('.json')]
except: ctx['agents'] = []

# Live focus
try:
    live = json.load(open(LIVE_CTX))
    ctx['focus'] = live.get('current_focus') or live.get('focus') or ''
except: ctx['focus'] = ''

print(json.dumps(ctx, indent=2))
PYEOF
}

cmd_show() {
  local ctx
  ctx=$(gather_context)
  echo ""
  echo "  ${BOLD}${AMBER}◈ BLACKROAD CONTEXT${NC}  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
  echo "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo "$ctx" | python3 -c "
import json, sys
ctx = json.load(sys.stdin)

g = ctx.get('git', {})
branch = g.get('branch','?'); dirty = g.get('dirty_files',0)
ahead  = g.get('commits_ahead',0); last_c = g.get('last_commit','?')[:60]
print(f'  \033[1mGIT\033[0m    branch \033[36m{branch}\033[0m  dirty \033[33m{dirty}\033[0m  ahead \033[35m{ahead}\033[0m')
print(f'         \033[2m{last_c}\033[0m')

ol = ctx.get('ollama',{})
if ol.get('status') == 'running':
    print(f'  \033[1mOLLAMA\033[0m \033[32m● running\033[0m  ' + '  '.join(ol.get('models',[])[:4]))
else:
    print(f'  \033[1mOLLAMA\033[0m \033[31m○ offline\033[0m')

j = ctx.get('journal',{}); total = j.get('total',0); last3 = j.get('last_3',[])
ll = last3[-1] if last3 else {}
print(f'  \033[1mJOURNAL\033[0m {total:,} entries  last: \033[36m{ll.get(\"action\",\"?\")}\033[0m / {ll.get(\"entity\",\"?\")}  \033[2m{ll.get(\"ts\",\"\")}\033[0m')

m = ctx.get('mesh',{})
online = m.get('online',[]); standby = m.get('standby',[])
ostr = '  '.join(online[:4]) or 'none'
print(f'  \033[1mMESH\033[0m   \033[32m{len(online)} online\033[0m  \033[33m{len(standby)} standby\033[0m  [{ostr}]')

qd = ctx.get('queue_depth',0)
inboxes = ctx.get('inboxes',{})
istr = '  '.join([f'{k}:{v}' for k,v in inboxes.items()]) or 'all empty'
print(f'  \033[1mQUEUE\033[0m  depth \033[36m{qd}\033[0m   inboxes: \033[2m{istr}\033[0m')

agents = ctx.get('agents',[])
if agents:
    parts = [('\033[32m' if a.get('status')=='idle' else '\033[33m') + a.get('name','?') + '\033[0m' for a in agents]
    print('  \033[1mAGENTS\033[0m ' + '  '.join(parts))

focus = ctx.get('focus','')
if focus: print(f'  \033[1mFOCUS\033[0m  \033[33m{focus[:80]}\033[0m')
"
  echo "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

cmd_json() { gather_context; }

cmd_copy() {
  gather_context | pbcopy 2>/dev/null && echo "  ${GREEN}✓ Copied to clipboard${NC}" || gather_context
}

cmd_send() {
  local to="${1:-copilot-window-2}"
  local inbox="$BR_ROOT/shared/inbox/$to"
  mkdir -p "$inbox"
  local fname="$inbox/context-$(date +%s).json"
  gather_context > "$fname"
  echo "  ${GREEN}✓ Context → $to inbox${NC}  ${DIM}$(basename $fname)${NC}"
}

cmd_update() {
  mkdir -p "$(dirname "$LIVE_CONTEXT")"
  gather_context > "$LIVE_CONTEXT"
  echo "  ${GREEN}✓ Live context updated${NC}  ${DIM}$LIVE_CONTEXT${NC}"
}

show_help() {
  echo ""
  echo "  ${AMBER}${BOLD}br context${NC}  — AI context snapshot"
  echo ""
  echo "  ${BOLD}Commands:${NC}"
  echo "    ${CYAN}show${NC}           Pretty-print snapshot (default)"
  echo "    ${CYAN}json${NC}           Raw JSON output"
  echo "    ${CYAN}copy${NC}           Copy JSON to clipboard"
  echo "    ${CYAN}send [to]${NC}      Send to instance inbox"
  echo "    ${CYAN}update${NC}         Write to live context file"
  echo ""
}

case "${1:-show}" in
  show|view|"")  cmd_show ;;
  json|raw)      cmd_json ;;
  copy|clip)     cmd_copy ;;
  send|push)     cmd_send "$2" ;;
  update|sync)   cmd_update ;;
  help|*)        show_help ;;
esac

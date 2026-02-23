#!/usr/bin/env zsh
# BR Snapshot — save/restore full workspace state for handoffs
# br snapshot save [name] | load [name] | list | diff | send <instance>

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
SNAP_DIR="$HOME/.blackroad/snapshots"
INSTANCES_FILE="$BR_ROOT/coordination/collaboration/active-instances.json"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"
INBOX_DIR="$BR_ROOT/shared/inbox"

mkdir -p "$SNAP_DIR"

_snap_name() {
  local name="${1:-snap}"
  echo "${name}-$(date '+%Y%m%d-%H%M%S')"
}

_latest_snap() {
  ls -t "$SNAP_DIR"/*.json 2>/dev/null | head -1
}

cmd_save() {
  local label="${1:-manual}"
  local name=$(_snap_name "$label")
  local file="$SNAP_DIR/${name}.json"

  echo ""
  echo "  ${PINK}${BOLD}◈ SAVING SNAPSHOT${NC}  ${DIM}$name${NC}"
  echo ""

  BR_ROOT="$BR_ROOT" python3 -c "
import json, subprocess, os, datetime, sys

BR_ROOT = os.environ.get('BR_ROOT', os.path.expanduser('~/blackroad'))
JOURNAL = os.path.expanduser('~/.blackroad/memory/journals/master-journal.jsonl')

snap = {
    'name':         '$name',
    'label':        '$label',
    'saved_at':     datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    'saved_by':     'lucidia-copilot-cli',
}

run = lambda c: subprocess.check_output(c, stderr=subprocess.DEVNULL).decode().strip()

# Git state
try:
    snap['git'] = {
        'branch':       run(['git','-C',BR_ROOT,'branch','--show-current']),
        'head_sha':     run(['git','-C',BR_ROOT,'rev-parse','HEAD']),
        'dirty':        run(['git','-C',BR_ROOT,'status','--short']),
        'last_commit':  run(['git','-C',BR_ROOT,'log','-1','--format=%H %s']),
        'stash_count':  int(run(['git','-C',BR_ROOT,'stash','list']) and
                        len(run(['git','-C',BR_ROOT,'stash','list']).splitlines()) or 0),
    }
except Exception as e: snap['git'] = {'error': str(e)}

# Staged/modified files
try:
    files = run(['git','-C',BR_ROOT,'status','--short']).splitlines()
    snap['modified_files'] = [f.strip() for f in files if f.strip()]
except: snap['modified_files'] = []

# Ollama state
try:
    import urllib.request
    with urllib.request.urlopen('http://localhost:11434/api/tags', timeout=1) as r:
        models = [m['name'] for m in json.loads(r.read()).get('models',[])]
    snap['ollama_models'] = models
except: snap['ollama_models'] = []

# Queue depth
try:
    qd = os.path.join(BR_ROOT, 'shared/mesh/queue')
    snap['queue_depth'] = len(os.listdir(qd)) if os.path.isdir(qd) else 0
except: snap['queue_depth'] = 0

# Journal tail
try:
    with open(JOURNAL) as f:
        lines = [l.strip() for l in f if l.strip()]
    last5 = []
    for line in lines[-5:]:
        try: last5.append(json.loads(line))
        except: pass
    snap['journal_tail'] = last5
    snap['journal_total'] = len(lines)
except: snap['journal_tail'] = []

# Active instances
try:
    infile = os.path.join(BR_ROOT, 'coordination/collaboration/active-instances.json')
    with open(infile) as f: inst_data = json.load(f)
    instances = inst_data.get('instances', inst_data)
    if isinstance(instances, dict): instances = list(instances.values())
    snap['mesh_instances'] = [
        {'id': i.get('id'), 'type': i.get('type'), 'status': i.get('status')}
        for i in instances
    ]
except: snap['mesh_instances'] = []

# Active agents
try:
    ad = os.path.join(BR_ROOT, 'agents/active')
    snap['agents'] = [json.load(open(os.path.join(ad,f))) for f in os.listdir(ad) if f.endswith('.json')]
except: snap['agents'] = []

# Todo summary from journal
snap['focus'] = 'Building BlackRoad OS CLI tools — br sync, br snapshot, br search'

with open('$file', 'w') as f:
    json.dump(snap, f, indent=2)
print(f'  Written: $file')
print(f'  git: {snap[\"git\"].get(\"branch\",\"?\")}  dirty: {len(snap[\"modified_files\"])} files')
print(f'  journal: {snap.get(\"journal_total\",0):,} entries  queue: {snap[\"queue_depth\"]}')
print(f'  agents: {len(snap[\"agents\"])}  mesh: {len(snap[\"mesh_instances\"])} instances')
"

  echo ""
  echo "  ${GREEN}✓ Snapshot saved:${NC} ${DIM}$(basename $file)${NC}"
  echo ""
}

cmd_load() {
  local pattern="${1:-}"
  local file
  if [[ -z "$pattern" ]]; then
    file=$(_latest_snap)
    [[ -z "$file" ]] && { echo "  ${RED}No snapshots found${NC}"; return 1; }
  else
    file=$(ls -t "$SNAP_DIR"/*${pattern}*.json 2>/dev/null | head -1)
    [[ -z "$file" ]] && { echo "  ${RED}No snapshot matching '$pattern'${NC}"; return 1; }
  fi

  echo ""
  echo "  ${PINK}${BOLD}◈ LOADING SNAPSHOT${NC}  ${DIM}$(basename $file)${NC}"
  echo ""

  python3 -c "
import json
with open('$file') as f: snap = json.load(f)

print(f'  \033[1mSaved\033[0m       {snap.get(\"saved_at\",\"?\")[:19].replace(\"T\",\" \")}')
print(f'  \033[1mLabel\033[0m       {snap.get(\"label\",\"?\")}')
print(f'  \033[1mBy\033[0m          {snap.get(\"saved_by\",\"?\")}')
print()

g = snap.get('git', {})
print(f'  \033[1mGit branch\033[0m  \033[36m{g.get(\"branch\",\"?\")}\033[0m')
print(f'  \033[1mHead SHA\033[0m    \033[2m{g.get(\"head_sha\",\"?\")[:12]}\033[0m')
print(f'  \033[1mLast commit\033[0m \033[2m{g.get(\"last_commit\",\"?\")[:70]}\033[0m')

mf = snap.get('modified_files', [])
if mf:
    print(f'  \033[1mDirty files\033[0m \033[33m{len(mf)}\033[0m')
    for f in mf[:5]: print(f'    \033[2m{f}\033[0m')

print()
print(f'  \033[1mJournal\033[0m     {snap.get(\"journal_total\",0):,} entries')
print(f'  \033[1mQueue\033[0m       depth {snap.get(\"queue_depth\",0)}')

agents = snap.get('agents',[])
if agents:
    names = [a.get('name','?') for a in agents]
    print(f'  \033[1mAgents\033[0m      {\"  \".join(names)}')

instances = snap.get('mesh_instances',[])
online = [i.get('id','?') for i in instances if i.get('status') == 'ONLINE']
if online:
    print(f'  \033[1mMesh online\033[0m {\"  \".join(online[:4])}')

focus = snap.get('focus','')
if focus: print(f'  \033[1mFocus\033[0m       \033[33m{focus[:80]}\033[0m')
"
  echo ""
}

cmd_list() {
  echo ""
  echo "  ${PINK}${BOLD}◈ SNAPSHOTS${NC}  ${DIM}$SNAP_DIR${NC}"
  echo ""
  local count=0
  for f in $(ls -t "$SNAP_DIR"/*.json 2>/dev/null); do
    local name=$(basename "$f" .json)
    local size=$(du -h "$f" | cut -f1)
    python3 -c "
import json
with open('$f') as fh: s = json.load(fh)
ts = s.get('saved_at','?')[:16].replace('T',' ')
label = s.get('label','?')
branch = s.get('git',{}).get('branch','?')
dirty = len(s.get('modified_files',[]))
print(f'  \033[36m{ts}\033[0m  \033[1m$name\033[0m  \033[2mbranch:{branch} dirty:{dirty}\033[0m  \033[33m{label}\033[0m  \033[2m$size\033[0m')
" 2>/dev/null || echo "  $name  $size"
    ((count++))
  done
  [[ "$count" -eq 0 ]] && echo "  ${DIM}No snapshots yet — use 'br snapshot save' to create one${NC}"
  echo ""
  echo "  ${DIM}$count snapshot(s) total${NC}"
  echo ""
}

cmd_diff() {
  local file=$(_latest_snap)
  [[ -z "$file" ]] && { echo "  ${RED}No snapshots to diff${NC}"; return 1; }
  echo ""
  echo "  ${PINK}${BOLD}◈ DIFF: NOW vs LATEST SNAPSHOT${NC}  ${DIM}$(basename $file)${NC}"
  echo ""
  python3 -c "
import json, subprocess, os

BR_ROOT = os.environ.get('BR_ROOT', os.path.expanduser('~/blackroad'))
with open('$file') as f: snap = json.load(f)

run = lambda c: subprocess.check_output(c, stderr=subprocess.DEVNULL).decode().strip()

# Git branch change
snap_branch = snap.get('git',{}).get('branch','?')
try: cur_branch = run(['git','-C',BR_ROOT,'branch','--show-current'])
except: cur_branch = '?'

if snap_branch != cur_branch:
    print(f'  \033[33m⚠ Branch changed:\033[0m {snap_branch} → {cur_branch}')
else:
    print(f'  \033[2mBranch: {cur_branch} (unchanged)\033[0m')

# New commits since snapshot
snap_sha = snap.get('git',{}).get('head_sha','')[:12]
try:
    cur_sha = run(['git','-C',BR_ROOT,'rev-parse','HEAD'])[:12]
    if snap_sha != cur_sha:
        new_commits = run(['git','-C',BR_ROOT,'log','--oneline',f'{snap.get(\"git\",{}).get(\"head_sha\",\"\")}..HEAD'])
        for line in new_commits.splitlines():
            print(f'  \033[36m+ {line[:80]}\033[0m')
    else:
        print(f'  \033[2mNo new commits\033[0m')
except: pass

# Queue depth change
try:
    qd = os.path.join(BR_ROOT, 'shared/mesh/queue')
    cur_q = len(os.listdir(qd)) if os.path.isdir(qd) else 0
    snap_q = snap.get('queue_depth', 0)
    delta = cur_q - snap_q
    col = '\033[32m' if delta <= 0 else '\033[33m'
    print(f'  Queue depth: {snap_q} → {cur_q} ({col}{delta:+d}\033[0m)')
except: pass
" 2>/dev/null
  echo ""
}

cmd_send() {
  local to="${1:-copilot-window-2}"
  local file=$(_latest_snap)
  [[ -z "$file" ]] && { echo "  ${YELLOW}No snapshot — saving one first…${NC}"; cmd_save "pre-handoff"; file=$(_latest_snap); }
  local inbox="$INBOX_DIR/$to"
  mkdir -p "$inbox"
  local dest="$inbox/snapshot-$(date +%s).json"
  cp "$file" "$dest"
  echo "  ${GREEN}✓ Snapshot sent to $to inbox${NC}"
  echo "  ${DIM}$(basename $dest)${NC}"
}

show_help() {
  echo ""
  echo "  ${PINK}${BOLD}br snapshot${NC}  — workspace state snapshots"
  echo ""
  echo "  ${BOLD}Commands:${NC}"
  echo "    ${CYAN}save [label]${NC}       Save full workspace snapshot"
  echo "    ${CYAN}load [pattern]${NC}     Load/view latest (or named) snapshot"
  echo "    ${CYAN}list${NC}               List all saved snapshots"
  echo "    ${CYAN}diff${NC}               Diff current state vs latest snapshot"
  echo "    ${CYAN}send [to]${NC}          Send latest snapshot to instance inbox"
  echo ""
  echo "  ${BOLD}Storage:${NC}  ${DIM}$SNAP_DIR${NC}"
  echo ""
}

case "${1:-list}" in
  save|create)   cmd_save "$2" ;;
  load|view)     cmd_load "$2" ;;
  list|ls)       cmd_list ;;
  diff|compare)  cmd_diff ;;
  send|handoff)  cmd_send "$2" ;;
  help|*)        show_help ;;
esac

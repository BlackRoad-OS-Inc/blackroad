#!/bin/zsh
# BR Tree — Enhanced Directory Tree
# Git-aware, icons, sizes, .gitignore respecting

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

cmd_tree() {
  local dir="${1:-.}" depth="${2:-3}" show_hidden="${3:-false}"

  echo -e "\n${BOLD}${CYAN}🌳 $(realpath "$dir" 2>/dev/null || echo "$dir")${NC}\n"

  python3 - "$dir" "$depth" "$show_hidden" <<'PY'
import os, sys, stat
from pathlib import Path

root = Path(sys.argv[1]).resolve()
max_depth = int(sys.argv[2])
show_hidden = sys.argv[3] == "true"

# Icons by extension
ICONS = {
    # Code
    '.js': '🟨', '.jsx': '🟨', '.ts': '🔷', '.tsx': '🔷',
    '.py': '🐍', '.rb': '💎', '.go': '🐹', '.rs': '🦀',
    '.sh': '📜', '.zsh': '📜', '.bash': '📜',
    '.sql': '🗄️', '.db': '🗄️',
    '.json': '📋', '.yaml': '📋', '.yml': '📋', '.toml': '📋',
    '.md': '📝', '.txt': '📄',
    '.html': '🌐', '.css': '🎨', '.scss': '🎨',
    '.env': '🔐', '.gitignore': '👁️',
    # Data
    '.csv': '📊', '.xml': '📦',
    # Images
    '.png': '🖼️', '.jpg': '🖼️', '.jpeg': '🖼️', '.svg': '🎭', '.gif': '🖼️',
    # Config
    'Dockerfile': '🐳', '.dockerignore': '🐳',
    'Makefile': '⚙️', 'makefile': '⚙️',
    # Archives
    '.zip': '📦', '.tar': '📦', '.gz': '📦',
    # Shell scripts
    'br': '⚡',
}
DIR_ICON = '📁'

# Load .gitignore patterns
def load_gitignore(path):
    gi = path / '.gitignore'
    patterns = {'node_modules', '.git', '__pycache__', '.DS_Store', 'dist', 'build', '.next', 'target', 'vendor'}
    if gi.exists():
        for line in gi.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith('#'):
                patterns.add(line.rstrip('/'))
    return patterns

def should_skip(name, ignored):
    if not show_hidden and name.startswith('.') and name not in ('.env', '.gitignore', '.env.example'):
        return True
    return any(name == p or name.startswith(p.rstrip('*')) for p in ignored if p)

def fmt_size(size):
    if size < 1024: return f"{size}B"
    if size < 1024*1024: return f"{size//1024}K"
    return f"{size//1024//1024}M"

def get_icon(p):
    name = p.name
    if p.is_dir(): return DIR_ICON
    if name in ICONS: return ICONS[name]
    ext = p.suffix.lower()
    return ICONS.get(ext, '📄')

def tree(path, prefix="", depth=0, ignored=None):
    if depth > max_depth:
        return 0, 0
    if ignored is None:
        ignored = load_gitignore(path)

    try:
        entries = sorted(path.iterdir(), key=lambda x: (x.is_file(), x.name.lower()))
    except PermissionError:
        return 0, 0

    entries = [e for e in entries if not should_skip(e.name, ignored)]
    total_files = 0
    total_size = 0

    for i, entry in enumerate(entries):
        is_last = i == len(entries) - 1
        connector = "└── " if is_last else "├── "
        ext_prefix = "    " if is_last else "│   "

        icon = get_icon(entry)

        if entry.is_dir():
            sub_ignored = ignored | load_gitignore(entry)
            # Count items in dir
            try:
                sub_count = sum(1 for _ in entry.iterdir())
            except: sub_count = 0
            count_str = f"  \033[90m({sub_count} items)\033[0m" if sub_count > 0 else ""
            print(f"{prefix}{connector}{icon}  \033[1m\033[34m{entry.name}\033[0m{count_str}")
            if depth < max_depth:
                sf, ss = tree(entry, prefix + ext_prefix, depth + 1, sub_ignored)
                total_files += sf
                total_size += ss
        else:
            try:
                size = entry.stat().st_size
                total_size += size
                total_files += 1
            except: size = 0
            size_str = f"  \033[90m{fmt_size(size)}\033[0m"
            # Git status
            git_str = ""
            print(f"{prefix}{connector}{icon}  {entry.name}{size_str}{git_str}")

    return total_files, total_size

def fmt_size(size):
    if size < 1024: return f"{size}B"
    if size < 1024*1024: return f"{size//1024}K"
    return f"{size//1024//1024}M"

total_f, total_s = tree(root)
print(f"\n  \033[90m{total_f} files  {fmt_size(total_s)} total\033[0m\n")
PY
}

cmd_stats() {
  local dir="${1:-.}"
  echo -e "\n${BOLD}${CYAN}📊 Directory Stats: $dir${NC}\n"
  python3 - "$dir" <<'PY'
import os, sys
from pathlib import Path
from collections import defaultdict

root = Path(sys.argv[1]).resolve()
by_ext = defaultdict(lambda: [0, 0])  # count, bytes
skip = {'node_modules', '.git', '__pycache__', 'dist', 'build', '.next', 'target'}

total_files = 0
total_dirs = 0
total_size = 0

for dirpath, dirs, files in os.walk(root):
    dirs[:] = [d for d in dirs if d not in skip]
    total_dirs += len(dirs)
    for f in files:
        fp = Path(dirpath) / f
        try:
            size = fp.stat().st_size
            ext = fp.suffix.lower() or fp.name
            by_ext[ext][0] += 1
            by_ext[ext][1] += size
            total_files += 1
            total_size += size
        except: pass

def fmt_size(b):
    if b < 1024: return f"{b}B"
    if b < 1024*1024: return f"{b//1024}K"
    return f"{b//1024//1024}M"

print(f"  Total files: \033[1m{total_files}\033[0m  dirs: {total_dirs}  size: \033[1m{fmt_size(total_size)}\033[0m\n")
print(f"  {'Extension':<14} {'Count':>6} {'Size':>8}")
print(f"  {'-'*32}")
for ext, (cnt, size) in sorted(by_ext.items(), key=lambda x: -x[1][0])[:20]:
    bar = '█' * min(20, cnt // max(1, total_files // 20))
    print(f"  {ext:<14} {cnt:>6}  {fmt_size(size):>8}  \033[36m{bar}\033[0m")
print()
PY
}

cmd_find_large() {
  local dir="${1:-.}" limit="${2:-20}" min_kb="${3:-100}"
  echo -e "\n${BOLD}${CYAN}🔍 Large Files (>${min_kb}KB): $dir${NC}\n"
  python3 - "$dir" "$limit" "$min_kb" <<'PY'
import os, sys
from pathlib import Path
root = Path(sys.argv[1]).resolve()
limit, min_bytes = int(sys.argv[2]), int(sys.argv[3]) * 1024
skip = {'node_modules', '.git', '__pycache__', 'dist', 'build'}
files = []
for dp, dirs, fs in os.walk(root):
    dirs[:] = [d for d in dirs if d not in skip]
    for f in fs:
        fp = Path(dp) / f
        try:
            s = fp.stat().st_size
            if s >= min_bytes: files.append((s, fp))
        except: pass
files.sort(reverse=True)
for size, fp in files[:limit]:
    rel = fp.relative_to(root)
    mb = size / 1024 / 1024
    print(f"  \033[33m{mb:>8.2f}MB\033[0m  {rel}")
if not files:
    print(f"  No files larger than {sys.argv[3]}KB found.")
print()
PY
}

cmd_dupes() {
  local dir="${1:-.}"
  echo -e "\n${BOLD}${CYAN}🔁 Duplicate Files: $dir${NC}\n"
  python3 - "$dir" <<'PY'
import os, sys, hashlib
from pathlib import Path
from collections import defaultdict
root = Path(sys.argv[1]).resolve()
skip = {'node_modules', '.git', '__pycache__'}
by_size = defaultdict(list)
for dp, dirs, fs in os.walk(root):
    dirs[:] = [d for d in dirs if d not in skip]
    for f in fs:
        fp = Path(dp) / f
        try:
            s = fp.stat().st_size
            if s > 0: by_size[s].append(fp)
        except: pass
# Only check files with same size
found = 0
for size, paths in by_size.items():
    if len(paths) < 2: continue
    by_hash = defaultdict(list)
    for p in paths:
        try:
            h = hashlib.md5(p.read_bytes()).hexdigest()
            by_hash[h].append(p)
        except: pass
    for h, dups in by_hash.items():
        if len(dups) > 1:
            found += 1
            print(f"  \033[33m{size//1024}KB\033[0m  md5:{h[:8]}")
            for d in dups:
                print(f"    {d.relative_to(root)}")
if not found:
    print("  No duplicate files found.")
print()
PY
}

show_help() {
  echo -e "\n${BOLD}${CYAN}🌳 BR Tree — Directory Explorer${NC}\n"
  echo -e "  ${CYAN}br tree [dir] [depth]${NC}          — visual tree (default depth=3)"
  echo -e "  ${CYAN}br tree stats [dir]${NC}            — file type breakdown + sizes"
  echo -e "  ${CYAN}br tree large [dir] [n] [minKB]${NC} — find large files"
  echo -e "  ${CYAN}br tree dupes [dir]${NC}            — find duplicate files"
  echo -e "  ${CYAN}br tree hidden [dir]${NC}           — include hidden files\n"
}

case "${1:-help}" in
  stats|stat)           cmd_stats "${2:-.}" ;;
  large|big|size)       cmd_find_large "${2:-.}" "${3:-20}" "${4:-100}" ;;
  dupes|dup|dupe)       cmd_dupes "${2:-.}" ;;
  hidden)               cmd_tree "${2:-.}" "${3:-3}" "true" ;;
  help|--help)          show_help ;;
  *) 
    if [[ -d "$1" ]]; then
      cmd_tree "$1" "${2:-3}"
    elif [[ "$1" =~ ^[0-9]+$ ]]; then
      cmd_tree "." "$1"
    else
      cmd_tree "." 3
    fi
    ;;
esac

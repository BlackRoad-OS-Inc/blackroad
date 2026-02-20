#!/bin/zsh

ORGS=(
  BlackRoad-OS
  blackboxprogramming
  Blackbox-Enterprises
  BlackRoad-AI
  BlackRoad-Archive
  BlackRoad-Cloud
  BlackRoad-Education
  BlackRoad-Foundation
  BlackRoad-Gov
  BlackRoad-Hardware
  BlackRoad-Interactive
  BlackRoad-Labs
  BlackRoad-Media
  BlackRoad-Security
  BlackRoad-Studio
  BlackRoad-Ventures
)

get_dir() {
  case $1 in
    BlackRoad-OS) echo "core" ;;
    blackboxprogramming) echo "personal" ;;
    Blackbox-Enterprises) echo "enterprise" ;;
    BlackRoad-AI) echo "ai" ;;
    BlackRoad-Archive) echo "archive" ;;
    BlackRoad-Cloud) echo "cloud" ;;
    BlackRoad-Education) echo "education" ;;
    BlackRoad-Foundation) echo "foundation" ;;
    BlackRoad-Gov) echo "governance" ;;
    BlackRoad-Hardware) echo "hardware" ;;
    BlackRoad-Interactive) echo "interactive" ;;
    BlackRoad-Labs) echo "labs" ;;
    BlackRoad-Media) echo "media" ;;
    BlackRoad-Security) echo "security" ;;
    BlackRoad-Studio) echo "studio" ;;
    BlackRoad-Ventures) echo "ventures" ;;
  esac
}

for org in $ORGS; do
  echo "=== Importing $org ==="
  base_dir="orgs/$(get_dir $org)"
  mkdir -p "$base_dir"
  
  repos=$(curl -s "https://api.github.com/orgs/$org/repos?per_page=100" | python3 -c "import json,sys; d=json.load(sys.stdin); print(' '.join([r['name'] for r in d]) if isinstance(d,list) else '')" 2>/dev/null)
  
  if [ -z "$repos" ]; then
    repos=$(curl -s "https://api.github.com/users/$org/repos?per_page=100" | python3 -c "import json,sys; d=json.load(sys.stdin); print(' '.join([r['name'] for r in d]) if isinstance(d,list) else '')" 2>/dev/null)
  fi
  
  for repo in $(echo $repos); do
    [ "$repo" = ".github" ] && continue
    dest="$base_dir/$repo"
    [ -d "$dest" ] && echo "  skip $repo" && continue
    
    echo "  + $repo"
    git subtree add --prefix="$dest" "https://github.com/$org/$repo.git" main --squash 2>/dev/null || git subtree add --prefix="$dest" "https://github.com/$org/$repo.git" master --squash 2>/dev/null || echo "    failed"
  done
done

echo "Done!"

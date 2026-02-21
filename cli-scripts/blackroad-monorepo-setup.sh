#!/bin/bash
# ============================================================
# BLACKROAD MONOREPO SETUP
# ============================================================
# 349 repos | 16 orgs | 1 monorepo
# Enterprise: github.com/enterprises/blackroad-os
# Cloudflare: 848cf0b18d51e0170e0d1537aec3505a
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           BLACKROAD MONOREPO SETUP                        ║"
echo "║   349 repos | 16 orgs | 1 source of truth                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================
# CONFIGURATION
# ============================================================

MONOREPO_NAME="blackroad"
MONOREPO_ORG="BlackRoad-OS"
ENTERPRISE="blackroad-os"

# All GitHub accounts
declare -a ORGS=(
  "BlackRoad-OS"
  "blackboxprogramming"
  "Blackbox-Enterprises"
  "BlackRoad-AI"
  "BlackRoad-Archive"
  "BlackRoad-Cloud"
  "BlackRoad-Education"
  "BlackRoad-Foundation"
  "BlackRoad-Gov"
  "BlackRoad-Hardware"
  "BlackRoad-Interactive"
  "BlackRoad-Labs"
  "BlackRoad-Media"
  "BlackRoad-Security"
  "BlackRoad-Studio"
  "BlackRoad-Ventures"
)

# Org to directory mapping
declare -A ORG_DIRS=(
  ["BlackRoad-OS"]="core"
  ["blackboxprogramming"]="personal"
  ["Blackbox-Enterprises"]="enterprise/automation"
  ["BlackRoad-AI"]="ai"
  ["BlackRoad-Archive"]="archive"
  ["BlackRoad-Cloud"]="cloud"
  ["BlackRoad-Education"]="education"
  ["BlackRoad-Foundation"]="foundation"
  ["BlackRoad-Gov"]="governance"
  ["BlackRoad-Hardware"]="hardware"
  ["BlackRoad-Interactive"]="interactive"
  ["BlackRoad-Labs"]="labs"
  ["BlackRoad-Media"]="media"
  ["BlackRoad-Security"]="security"
  ["BlackRoad-Studio"]="studio"
  ["BlackRoad-Ventures"]="ventures"
)

# ============================================================
# STEP 1: Prerequisites check
# ============================================================
check_prerequisites() {
  echo -e "${BLUE}[1/6] Checking prerequisites...${NC}"
  
  if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git not found${NC}"
    exit 1
  fi
  
  if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI not found. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install gh
    else
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
      sudo apt update && sudo apt install gh -y
    fi
  fi
  
  # Check auth
  if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}Not authenticated. Running gh auth login...${NC}"
    gh auth login
  fi
  
  echo -e "${GREEN}✓ Prerequisites OK${NC}"
}

# ============================================================
# STEP 2: Create monorepo
# ============================================================
create_monorepo() {
  echo -e "${BLUE}[2/6] Creating monorepo...${NC}"
  
  if gh repo view "$MONOREPO_ORG/$MONOREPO_NAME" &> /dev/null; then
    echo -e "${YELLOW}Repo already exists. Cloning...${NC}"
  else
    gh repo create "$MONOREPO_ORG/$MONOREPO_NAME" \
      --public \
      --description "BlackRoad OS Monorepo - 349 repos, 16 orgs, 1 source of truth" \
      --homepage "https://blackroad.io"
  fi
  
  if [ -d "$MONOREPO_NAME" ]; then
    echo -e "${YELLOW}Directory exists. Entering...${NC}"
    cd "$MONOREPO_NAME"
    git pull origin main 2>/dev/null || true
  else
    gh repo clone "$MONOREPO_ORG/$MONOREPO_NAME"
    cd "$MONOREPO_NAME"
  fi
  
  echo -e "${GREEN}✓ Monorepo ready at $(pwd)${NC}"
}

# ============================================================
# STEP 3: Create directory structure
# ============================================================
create_structure() {
  echo -e "${BLUE}[3/6] Creating directory structure...${NC}"
  
  # Top-level structure
  mkdir -p {packages,services,infra,docs,scripts,archives}
  
  # Org-based structure
  for org in "${ORGS[@]}"; do
    dir="${ORG_DIRS[$org]}"
    mkdir -p "orgs/$dir"
  done
  
  # Specialized directories
  mkdir -p packages/{core,ai,blockchain,cli,agents}
  mkdir -p services/{websites,dashboards,apis,metaverse,streaming}
  mkdir -p infra/{cloudflare,k3s,terraform,domains,pi-ops}
  mkdir -p docs/{architecture,api,guides,portfolio}
  
  echo -e "${GREEN}✓ Structure created${NC}"
}

# ============================================================
# STEP 4: Create import script
# ============================================================
create_import_script() {
  echo -e "${BLUE}[4/6] Creating import scripts...${NC}"
  
  mkdir -p scripts
  
  # Main import script
  cat > scripts/import-all.sh << 'IMPORT_EOF'
#!/bin/bash
# Import all repos from all orgs as git subtrees

set -e

ORGS=(
  "BlackRoad-OS"
  "blackboxprogramming"
  "Blackbox-Enterprises"
  "BlackRoad-AI"
  "BlackRoad-Archive"
  "BlackRoad-Cloud"
  "BlackRoad-Education"
  "BlackRoad-Foundation"
  "BlackRoad-Gov"
  "BlackRoad-Hardware"
  "BlackRoad-Interactive"
  "BlackRoad-Labs"
  "BlackRoad-Media"
  "BlackRoad-Security"
  "BlackRoad-Studio"
  "BlackRoad-Ventures"
)

declare -A ORG_DIRS=(
  ["BlackRoad-OS"]="core"
  ["blackboxprogramming"]="personal"
  ["Blackbox-Enterprises"]="enterprise/automation"
  ["BlackRoad-AI"]="ai"
  ["BlackRoad-Archive"]="archive"
  ["BlackRoad-Cloud"]="cloud"
  ["BlackRoad-Education"]="education"
  ["BlackRoad-Foundation"]="foundation"
  ["BlackRoad-Gov"]="governance"
  ["BlackRoad-Hardware"]="hardware"
  ["BlackRoad-Interactive"]="interactive"
  ["BlackRoad-Labs"]="labs"
  ["BlackRoad-Media"]="media"
  ["BlackRoad-Security"]="security"
  ["BlackRoad-Studio"]="studio"
  ["BlackRoad-Ventures"]="ventures"
)

# Skip these (meta repos, forks, etc)
SKIP_REPOS=".github containers-template chanfana-openapi-template"

import_org() {
  local org=$1
  local base_dir="orgs/${ORG_DIRS[$org]}"
  
  echo ""
  echo "═══════════════════════════════════════════════════"
  echo "Importing: $org → $base_dir"
  echo "═══════════════════════════════════════════════════"
  
  # Get repos (try org endpoint, fallback to user)
  local repos
  repos=$(curl -s "https://api.github.com/orgs/$org/repos?per_page=100" 2>/dev/null | \
    python3 -c "import json,sys; d=json.load(sys.stdin); print(' '.join([r['name'] for r in d]) if isinstance(d,list) else '')" 2>/dev/null)
  
  if [ -z "$repos" ]; then
    repos=$(curl -s "https://api.github.com/users/$org/repos?per_page=100" 2>/dev/null | \
      python3 -c "import json,sys; d=json.load(sys.stdin); print(' '.join([r['name'] for r in d]) if isinstance(d,list) else '')" 2>/dev/null)
  fi
  
  for repo in $repos; do
    # Skip certain repos
    if [[ " $SKIP_REPOS " =~ " $repo " ]]; then
      echo "  ⏭ Skipping $repo (in skip list)"
      continue
    fi
    
    local dest="$base_dir/$repo"
    
    # Skip if already exists
    if [ -d "$dest" ] && [ "$(ls -A "$dest" 2>/dev/null)" ]; then
      echo "  ✓ $repo (already imported)"
      continue
    fi
    
    # Determine branch
    local branch="main"
    if ! git ls-remote --heads "https://github.com/$org/$repo.git" main 2>/dev/null | grep -q main; then
      branch="master"
    fi
    
    echo "  → Importing $repo ($branch)"
    mkdir -p "$(dirname "$dest")"
    
    if git subtree add --prefix="$dest" "https://github.com/$org/$repo.git" "$branch" --squash 2>/dev/null; then
      echo "  ✓ $repo imported"
    else
      echo "  ✗ $repo failed (empty or error)"
    fi
  done
}

# Main
echo "Starting import of all BlackRoad repos..."
echo "This will take a while (349 repos)..."
echo ""

for org in "${ORGS[@]}"; do
  import_org "$org"
done

echo ""
echo "═══════════════════════════════════════════════════"
echo "Import complete!"
echo "Run 'git log --oneline | head -50' to see imports"
echo "═══════════════════════════════════════════════════"
IMPORT_EOF

  chmod +x scripts/import-all.sh
  
  # Sync script for pulling updates
  cat > scripts/sync-upstream.sh << 'SYNC_EOF'
#!/bin/bash
# Sync a specific repo from upstream
# Usage: ./scripts/sync-upstream.sh BlackRoad-OS lucidia-core

ORG=$1
REPO=$2

if [ -z "$ORG" ] || [ -z "$REPO" ]; then
  echo "Usage: $0 <org> <repo>"
  exit 1
fi

declare -A ORG_DIRS=(
  ["BlackRoad-OS"]="core"
  ["blackboxprogramming"]="personal"
  ["Blackbox-Enterprises"]="enterprise/automation"
  ["BlackRoad-AI"]="ai"
  ["BlackRoad-Archive"]="archive"
  ["BlackRoad-Cloud"]="cloud"
  ["BlackRoad-Education"]="education"
  ["BlackRoad-Foundation"]="foundation"
  ["BlackRoad-Gov"]="governance"
  ["BlackRoad-Hardware"]="hardware"
  ["BlackRoad-Interactive"]="interactive"
  ["BlackRoad-Labs"]="labs"
  ["BlackRoad-Media"]="media"
  ["BlackRoad-Security"]="security"
  ["BlackRoad-Studio"]="studio"
  ["BlackRoad-Ventures"]="ventures"
)

PREFIX="orgs/${ORG_DIRS[$ORG]}/$REPO"

if [ ! -d "$PREFIX" ]; then
  echo "Error: $PREFIX not found"
  exit 1
fi

# Determine branch
BRANCH="main"
if ! git ls-remote --heads "https://github.com/$ORG/$REPO.git" main 2>/dev/null | grep -q main; then
  BRANCH="master"
fi

echo "Syncing $ORG/$REPO → $PREFIX ($BRANCH)"
git subtree pull --prefix="$PREFIX" "https://github.com/$ORG/$REPO.git" "$BRANCH" --squash
SYNC_EOF

  chmod +x scripts/sync-upstream.sh
  
  # Quick import for single org
  cat > scripts/import-org.sh << 'ORG_EOF'
#!/bin/bash
# Import single org
# Usage: ./scripts/import-org.sh BlackRoad-AI

ORG=$1
if [ -z "$ORG" ]; then
  echo "Usage: $0 <org-name>"
  echo "Available: BlackRoad-OS blackboxprogramming Blackbox-Enterprises BlackRoad-AI BlackRoad-Archive BlackRoad-Cloud BlackRoad-Education BlackRoad-Foundation BlackRoad-Gov BlackRoad-Hardware BlackRoad-Interactive BlackRoad-Labs BlackRoad-Media BlackRoad-Security BlackRoad-Studio BlackRoad-Ventures"
  exit 1
fi

# Source the full import and run for one org
source scripts/import-all.sh
import_org "$ORG"
ORG_EOF

  chmod +x scripts/import-org.sh
  
  echo -e "${GREEN}✓ Import scripts created${NC}"
}

# ============================================================
# STEP 5: Create workspace config
# ============================================================
create_workspace_config() {
  echo -e "${BLUE}[5/6] Creating workspace configuration...${NC}"
  
  # Package.json
  cat > package.json << 'PKG_EOF'
{
  "name": "blackroad",
  "version": "0.1.0",
  "private": true,
  "description": "BlackRoad OS Monorepo - 349 repos, 16 orgs, 1 source of truth",
  "repository": {
    "type": "git",
    "url": "https://github.com/BlackRoad-OS/blackroad"
  },
  "scripts": {
    "import:all": "./scripts/import-all.sh",
    "import:org": "./scripts/import-org.sh",
    "sync": "./scripts/sync-upstream.sh",
    "inventory": "./scripts/inventory.sh",
    "dev": "turbo dev",
    "build": "turbo build",
    "lint": "turbo lint"
  },
  "devDependencies": {
    "turbo": "^2.0.0"
  },
  "packageManager": "pnpm@9.0.0",
  "engines": {
    "node": ">=20.0.0"
  }
}
PKG_EOF

  # pnpm workspace
  cat > pnpm-workspace.yaml << 'PNPM_EOF'
packages:
  - 'packages/**'
  - 'services/**'
  - 'orgs/**'
PNPM_EOF

  # Turbo config
  cat > turbo.json << 'TURBO_EOF'
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {
      "dependsOn": ["^lint"]
    }
  }
}
TURBO_EOF

  # .gitignore
  cat > .gitignore << 'GIT_EOF'
# Dependencies
node_modules/
.pnpm-store/

# Build outputs
dist/
build/
.next/
.turbo/

# Environment
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Python
__pycache__/
*.py[cod]
.venv/
venv/

# Temporary
tmp/
temp/
GIT_EOF

  echo -e "${GREEN}✓ Workspace config created${NC}"
}

# ============================================================
# STEP 6: Create README and inventory
# ============================================================
create_readme() {
  echo -e "${BLUE}[6/6] Creating README and inventory...${NC}"
  
  cat > README.md << 'README_EOF'
# BlackRoad Monorepo

> 349 repos | 16 orgs | 1 source of truth

## 🏗 Structure

```
blackroad/
├── orgs/                    # All repos organized by org
│   ├── core/                # BlackRoad-OS (100 repos)
│   ├── ai/                  # BlackRoad-AI (49 repos)
│   ├── cloud/               # BlackRoad-Cloud (20 repos)
│   ├── security/            # BlackRoad-Security (17 repos)
│   ├── media/               # BlackRoad-Media (17 repos)
│   ├── foundation/          # BlackRoad-Foundation (15 repos)
│   ├── interactive/         # BlackRoad-Interactive (14 repos)
│   ├── hardware/            # BlackRoad-Hardware (13 repos)
│   ├── labs/                # BlackRoad-Labs (13 repos)
│   ├── studio/              # BlackRoad-Studio (13 repos)
│   ├── ventures/            # BlackRoad-Ventures (12 repos)
│   ├── education/           # BlackRoad-Education (11 repos)
│   ├── governance/          # BlackRoad-Gov (10 repos)
│   ├── archive/             # BlackRoad-Archive (9 repos)
│   ├── enterprise/          # Blackbox-Enterprises (9 repos)
│   └── personal/            # blackboxprogramming (27 repos)
├── packages/                # Shared libraries
├── services/                # Deployable services
├── infra/                   # Infrastructure configs
├── docs/                    # Documentation
└── scripts/                 # Tooling
```

## 🚀 Quick Start

```bash
# Clone
git clone https://github.com/BlackRoad-OS/blackroad
cd blackroad

# Install dependencies
pnpm install

# Import all repos (takes ~30 min)
./scripts/import-all.sh

# Import single org
./scripts/import-org.sh BlackRoad-AI

# Sync updates from upstream
./scripts/sync-upstream.sh BlackRoad-OS lucidia-core
```

## 📊 Inventory

| Organization | Repos | Focus |
|-------------|-------|-------|
| BlackRoad-OS | 100 | Core platform, CLI, agents |
| BlackRoad-AI | 49 | ML models, inference, Lucidia |
| blackboxprogramming | 27 | Personal projects, portfolio |
| BlackRoad-Cloud | 20 | K8s, Terraform, cloud infra |
| BlackRoad-Security | 17 | Security tools, audits |
| BlackRoad-Media | 17 | Content, social, streaming |
| BlackRoad-Foundation | 15 | CRM, project management |
| BlackRoad-Interactive | 14 | Games, 3D, metaverse |
| BlackRoad-Hardware | 13 | IoT, Pi, embedded |
| BlackRoad-Labs | 13 | Research, experiments |
| BlackRoad-Studio | 13 | Creative tools, design |
| BlackRoad-Ventures | 12 | Finance, commerce |
| BlackRoad-Education | 11 | Learning platforms |
| BlackRoad-Gov | 10 | Governance, voting |
| BlackRoad-Archive | 9 | Storage, preservation |
| Blackbox-Enterprises | 9 | Automation, workflows |
| **TOTAL** | **349** | |

## 🔗 Links

- **Enterprise**: [github.com/enterprises/blackroad-os](https://github.com/enterprises/blackroad-os)
- **Cloudflare**: [dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a](https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a)
- **Main Site**: [blackroad.io](https://blackroad.io)

## 📜 License

MIT © BlackRoad OS, Inc.
README_EOF

  # Inventory script
  cat > scripts/inventory.sh << 'INV_EOF'
#!/bin/bash
# Generate inventory of all imported repos

echo "BlackRoad Monorepo Inventory"
echo "============================"
echo ""

total=0
for dir in orgs/*/; do
  org=$(basename "$dir")
  count=$(find "$dir" -maxdepth 1 -type d | wc -l)
  count=$((count - 1))  # Subtract the dir itself
  total=$((total + count))
  printf "%-20s %3d repos\n" "$org" "$count"
done

echo ""
echo "Total: $total repos imported"
INV_EOF

  chmod +x scripts/inventory.sh
  
  echo -e "${GREEN}✓ README created${NC}"
}

# ============================================================
# MAIN
# ============================================================
main() {
  check_prerequisites
  create_monorepo
  create_structure
  create_import_script
  create_workspace_config
  create_readme
  
  echo ""
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║           SETUP COMPLETE!                                   ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "Next steps:"
  echo -e "  ${BLUE}cd blackroad${NC}"
  echo -e "  ${BLUE}./scripts/import-all.sh${NC}     # Import all 349 repos (~30 min)"
  echo -e "  ${BLUE}./scripts/import-org.sh BlackRoad-AI${NC}  # Or import one org"
  echo ""
  echo -e "After import:"
  echo -e "  ${BLUE}git push origin main${NC}        # Push to GitHub"
  echo -e "  ${BLUE}./scripts/inventory.sh${NC}      # See what's imported"
  echo ""
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

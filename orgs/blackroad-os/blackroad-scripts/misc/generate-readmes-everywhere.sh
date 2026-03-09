#!/bin/bash
# 📝 Generate Professional READMEs for All BlackRoad Repos

set -e

echo "📝 BLACKROAD README GENERATION"
echo "=============================="
echo ""

# Get all repos
ALL_REPOS=$(gh repo list BlackRoad-OS --limit 100 --json name -q '.[].name')
REPO_COUNT=$(echo "$ALL_REPOS" | wc -l | tr -d ' ')

echo "✅ Found $REPO_COUNT repositories"
echo ""

SUCCESS=0
SKIPPED=0

# Function to generate README for a repo
generate_readme() {
  local repo_name=$1
  local full_repo="BlackRoad-OS/$repo_name"

  echo "📝 Generating README for $repo_name..."

  # Clone or update
  if [ ! -d "/tmp/readme-$repo_name" ]; then
    gh repo clone $full_repo "/tmp/readme-$repo_name" 2>/dev/null || {
      echo "  ⚠️  Cannot access repo"
      ((SKIPPED++))
      return
    }
  fi

  cd "/tmp/readme-$repo_name"
  git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true

  # Check if README already exists and is substantial
  if [ -f "README.md" ] && [ $(wc -l < README.md) -gt 10 ]; then
    echo "  → Already has README, skipping"
    ((SKIPPED++))
    cd - > /dev/null
    return
  fi

  # Detect project type
  PROJECT_TYPE="general"
  if [ -f "package.json" ]; then
    PROJECT_TYPE="node"
  elif [ -f "Cargo.toml" ]; then
    PROJECT_TYPE="rust"
  elif [ -f "go.mod" ]; then
    PROJECT_TYPE="go"
  elif [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
    PROJECT_TYPE="python"
  fi

  # Generate appropriate README
  cat > README.md << EOF
# ${repo_name}

Part of the [BlackRoad OS](https://blackroad.io) ecosystem.

## Overview

${repo_name} is a component of BlackRoad OS, Inc.

## Installation

EOF

  # Add project-specific installation instructions
  case $PROJECT_TYPE in
    "node")
      cat >> README.md << 'EOF'
```bash
npm install
```

## Usage

```bash
npm start
```

## Development

```bash
npm run dev
```

## Build

```bash
npm run build
```

## Testing

```bash
npm test
```
EOF
      ;;
    "rust")
      cat >> README.md << 'EOF'
```bash
cargo build
```

## Usage

```bash
cargo run
```

## Testing

```bash
cargo test
```
EOF
      ;;
    "go")
      cat >> README.md << 'EOF'
```bash
go build
```

## Usage

```bash
go run .
```

## Testing

```bash
go test ./...
```
EOF
      ;;
    "python")
      cat >> README.md << 'EOF'
```bash
pip install -r requirements.txt
```

## Usage

```bash
python main.py
```

## Testing

```bash
pytest
```
EOF
      ;;
    *)
      cat >> README.md << 'EOF'
See documentation for installation and usage instructions.
EOF
      ;;
  esac

  # Add common sections
  cat >> README.md << 'EOF'

## Documentation

Full documentation available at [docs.blackroad.io](https://docs.blackroad.io)

## License

Copyright © 2025 BlackRoad OS, Inc.

## Links

- [BlackRoad OS](https://blackroad.io)
- [Documentation](https://docs.blackroad.io)
- [GitHub](https://github.com/BlackRoad-OS)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF

  # Commit and push
  git add README.md
  git commit -m "Add professional README

- Project overview
- Installation instructions
- Usage examples
- Links to documentation

🤖 Generated with Claude Code" 2>/dev/null || {
    echo "  → No changes needed"
    ((SKIPPED++))
    cd - > /dev/null
    return
  }

  git push origin main 2>/dev/null || git push origin master 2>/dev/null || {
    echo "  ⚠️  Push failed"
    cd - > /dev/null
    return
  }

  echo "  ✅ README generated for $repo_name"
  ((SUCCESS++))

  cd - > /dev/null
}

# Process all repos
while IFS= read -r repo_name; do
  [ -z "$repo_name" ] && continue
  generate_readme "$repo_name"
  echo ""
done <<< "$ALL_REPOS"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ README GENERATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Results:"
echo "   ✅ Generated: $SUCCESS READMEs"
echo "   ⏭️  Skipped: $SKIPPED repos"
echo "   📦 Total: $REPO_COUNT repos"
echo ""

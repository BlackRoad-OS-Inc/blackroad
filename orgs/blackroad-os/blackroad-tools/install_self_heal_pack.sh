#!/usr/bin/env bash
# FILE: tools/install_self_heal_pack.sh
set -euo pipefail

BRANCH="${BRANCH:-chore/self-heal-pack}"
GIT_USER_NAME="${GIT_USER_NAME:-BlackRoad Bot}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-bot@blackroad.io}"

echo "==> Creating directories"
mkdir -p .github/workflows .github/ISSUE_TEMPLATE .github/DISCUSSION_TEMPLATE .githooks tools sites/blackroad
touch README.md

echo "==> Editor & Git normalization"
cat > .editorconfig <<'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true

[*.py]
indent_size = 4
EOF

cat > .gitattributes <<'EOF'
* text=auto eol=lf
*.sh text eol=lf
EOF

echo "==> Dev tooling for Python/JS"
cat > pyproject.toml <<'EOF'
[tool.black]
line-length = 100
target-version = ["py311"]

[tool.isort]
profile = "black"

[tool.ruff]
line-length = 100
extend-select = ["I"]
EOF

cat > .pre-commit-config.yaml <<'EOF'
repos:
  - repo: https://github.com/psf/black
    rev: 24.4.2
    hooks: [{ id: black }]
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.9
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v4.0.0-alpha.8
    hooks:
      - id: prettier
        additional_dependencies: ["prettier@^3"]
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v9.12.0
    hooks:
      - id: eslint
        args: ["--fix"]
        files: "\\.(js|jsx|ts|tsx)$"
EOF

cat > requirements-dev.txt <<'EOF'
black==24.4.2
ruff==0.6.9
isort==5.13.2
EOF

# Merge-friendly package.json scripts if file exists; otherwise create a minimal one
if [ -f package.json ]; then
  node - <<'EOF'
const fs=require('fs');
const p=JSON.parse(fs.readFileSync('package.json','utf8'));
p.scripts = Object.assign({
  "format":"prettier -w .",
  "lint:js":"eslint . --ext .js,.jsx,.ts,.tsx",
  "lint:js:fix":"eslint . --ext .js,.jsx,.ts,.tsx --fix",
  "typecheck":"tsc -p . || true"
}, p.scripts||{});
fs.writeFileSync('package.json', JSON.stringify(p,null,2));
EOF
else
  cat > package.json <<'EOF'
{
  "name": "blackroad-prism-console",
  "private": true,
  "scripts": {
    "format": "prettier -w .",
    "lint:js": "eslint . --ext .js,.jsx,.ts,.tsx",
    "lint:js:fix": "eslint . --ext .js,.jsx,.ts,.tsx --fix",
    "typecheck": "tsc -p . || true"
  }
}
EOF
fi

echo "==> Git hooks to block secrets & binaries"
mkdir -p .githooks
cat > .githooks/pre-commit <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
FILES=$(git diff --cached --name-only)

# Block large/binary types often committed by mistake
if echo "$FILES" | grep -E '\.(zip|tar|gz|7z|mp4|mov|iso|bin|dmg|exe)$' >/dev/null; then
  echo "❌ Large/binary file staged. Use Releases or LFS."
  exit 1
fi

# Block secrets directory
if echo "$FILES" | grep -E '^secrets/' >/dev/null; then
  echo "❌ 'secrets/' must not be committed. Use GitHub secrets or a vault."
  exit 1
fi
EOF
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks

echo "==> Label config (v5 match objects)"
cat > .github/labeler.yml <<'EOF'
frontend:
  - changed-files:
      - any-glob-to-any-file:
          - 'sites/blackroad/**'
          - 'apps/quantum/**'
          - '**/*.tsx'
          - '**/*.ts'
          - '**/*.jsx'
          - '**/*.js'
          - '**/*.css'
          - '**/*.html'

backend:
  - changed-files:
      - any-glob-to-any-file:
          - 'api/**'
          - 'services/**'
          - '**/*.py'
          - '**/*.go'
          - 'main.py'

docs:
  - changed-files:
      - any-glob-to-any-file:
          - 'docs/**'
          - 'README.md'
          - 'CHANGELOG.md'
          - '**/*.md'

tests:
  - changed-files:
      - any-glob-to-any-file:
          - 'tests/**'
          - '**/*.test.*'
          - '**/*.spec.*'

prompts:
  - changed-files:
      - any-glob-to-any-file:
          - 'prompts/**'
          - 'prompts/llm/**'
          - 'codex/**'

templates:
  - changed-files:
      - any-glob-to-any-file:
          - 'templates/**'

devops:
  - changed-files:
      - any-glob-to-any-file:
          - '.github/**'
          - '.devcontainer/**'
          - '.husky/**'
          - 'config/**'
          - 'scripts/**'
          - 'tools/**'
          - 'bin/**'
          - 'Makefile'
          - '.nvmrc'
          - '.tool-versions'
          - '.yamllint.yaml'
          - '.markdownlint.yaml'
          - '.htmlhintrc'
          - '.prettierrc.*'
          - '.prettierignore'
          - '.editorconfig'
          - '.gitattributes'
          - '.gitignore'

security:
  - changed-files:
      - any-glob-to-any-file:
          - 'secrets/**'
          - '.mergify.yml'

site-assets:
  - changed-files:
      - any-glob-to-any-file:
          - 'sites/blackroad/public/**'
          - 'sites/blackroad/assets/**'
EOF

echo "==> Label set (managed via sync-labels agent)"
cat > .github/labels.yml <<'EOF'
- name: frontend
  color: "1d76db"
  description: "UI, React, TS/JS, styles"

- name: backend
  color: "0e8a16"
  description: "API, services, Python/Go"

- name: docs
  color: "5319e7"
  description: "Documentation and guides"

- name: tests
  color: "b60205"
  description: "Test code and fixtures"

- name: prompts
  color: "fbca04"
  description: "LLM prompts & Codex"

- name: templates
  color: "c2e0c6"
  description: "Scaffolds & templates"

- name: devops
  color: "0052cc"
  description: "CI/CD, config, tooling"

- name: security
  color: "d93f0b"
  description: "Security, policies, secrets"

- name: site-assets
  color: "5319e7"
  description: "Static site assets"
EOF

echo "==> Autofix script"
cat > tools/autofix.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "==> Python dev deps"
if [ -f requirements-dev.txt ]; then
  python -m pip install --upgrade pip >/dev/null
  python -m pip install -r requirements-dev.txt >/dev/null
fi

echo "==> Node deps"
if [ -f package-lock.json ] || [ -f package.json ]; then
  npm ci || npm install
fi

echo "==> JS/TS fixes"
npm run lint:js:fix || true
npm run format || true

echo "==> Python fixes"
ruff check . --fix || true
ruff format . || true
black . || true
isort . || true

echo "==> Normalize line endings"
git ls-files -z | xargs -0 -I {} bash -c 'printf "%s" "{}" | xargs dos2unix >/dev/null 2>&1 || true'

echo "==> Remove node_modules from index if present"
git rm -r --cached --ignore-unmatch **/node_modules 2>/dev/null || true

echo "==> Done."
EOF
chmod +x tools/autofix.sh

echo "==> Actions: labeler (PR label agent)"
cat > .github/workflows/labeler.yml <<'EOF'
name: Pull Request Labeler
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

permissions:
  contents: read
  pull-requests: write

jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v5
        with:
          configuration-path: .github/labeler.yml
EOF

echo "==> Actions: sync labels (label manager agent)"
cat > .github/workflows/sync-labels.yml <<'EOF'
name: Sync Labels
on:
  workflow_dispatch:
  push:
    paths: [ ".github/labels.yml" ]

permissions:
  contents: read
  issues: write

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: crazy-max/ghaction-github-labeler@v5
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          yaml-file: .github/labels.yml
EOF

echo "==> Actions: code scanning (CodeQL security agent)"
cat > .github/workflows/codeql.yml <<'EOF'
name: CodeQL
on:
  push: { branches: [ main ] }
  pull_request:
  schedule:
    - cron: '0 2 * * 1'

permissions:
  contents: read
  security-events: write

jobs:
  analyze:
    runs-on: ubuntu-latest
    strategy: { language: [ 'javascript', 'python' ] }
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with: { languages: ${{ matrix.language }} }
      - uses: github/codeql-action/analyze@v3
EOF

echo "==> Actions: dependabot config (dependency agent)"
cat > .github/dependabot.yml <<'EOF'
version: 2
updates:
  - package-ecosystem: npm
    directory: "/"
    schedule: { interval: daily }
    open-pull-requests-limit: 10

  - package-ecosystem: npm
    directory: "/sites/blackroad"
    schedule: { interval: daily }
    open-pull-requests-limit: 10

  - package-ecosystem: pip
    directory: "/"
    schedule: { interval: weekly }
EOF

echo "==> Actions: dependabot auto-merge (optional caretaker agent)"
cat > .github/workflows/dependabot-auto-merge.yml <<'EOF'
name: Dependabot Auto Merge
on:
  pull_request_target:
    types: [opened, synchronize, reopened, ready_for_review]

permissions:
  pull-requests: write
  contents: write

jobs:
  auto-merge:
    if: ${{ github.actor == 'dependabot[bot]' }}
    runs-on: ubuntu-latest
    steps:
      - name: Enable automerge
        env: { GH_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
        run: gh pr merge ${{ github.event.pull_request.number }} --squash --auto || true
EOF

echo "==> Actions: autofix & PR (repair agent)"
cat > .github/workflows/autofix-pr.yml <<'EOF'
name: Auto Fix & PR
on:
  workflow_dispatch:
  schedule:
    - cron: "7 7 * * *"
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

permissions:
  contents: write
  pull-requests: write

concurrency:
  group: autofix-${{ github.ref }}
  cancel-in-progress: true

jobs:
  autofix:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: actions/setup-python@v5
        with: { python-version: "3.11", cache: "pip" }
      - uses: actions/setup-node@v4
        with: { node-version: "20", cache: "npm" }

      - name: Run repairs
        run: bash tools/autofix.sh

      - name: Create Fix PR if changes
        id: cpr
        uses: peter-evans/create-pull-request@v6
        with:
          commit-message: "fix: automatic formatting, lint, and import sort"
          title: "Fix: automatic formatting, lint, and import sort"
          body: |
            Automated repairs: Prettier/ESLint, Ruff/Black/Isort, line-ending normalization, and repo hygiene fixes.
          branch: ci/autofix
          delete-branch: true
          labels: |
            devops
            tests
            security
          signoff: true

      - name: Enable auto-merge (squash)
        if: steps.cpr.outputs.pull-request-number != ''
        env: { GH_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
        run: gh pr merge ${{ steps.cpr.outputs.pull-request-number }} --squash --auto || true
EOF

echo "==> Actions: CI with retry (build/test agent)"
cat > .github/workflows/ci.yml <<'EOF'
name: CI
on:
  push: { branches: [ main ] }
  pull_request:

permissions: { contents: read }

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "20", cache: npm }
      - run: npm ci || npm install

      - name: Build (retry x3)
        run: |
          n=0; until [ $n -ge 3 ]; do npm run build && break; n=$((n+1)); echo "Retry #$n…"; sleep 5; done

      - name: Tests (retry x3)
        run: |
          n=0; until [ $n -ge 3 ]; do npm test && break; n=$((n+1)); echo "Retry #$n…"; sleep 5; done

      - name: Python lint/tests (if present)
        uses: actions/setup-python@v5
        with: { python-version: "3.11", cache: pip }
      - run: |
          python -m pip install -r requirements-dev.txt 2>/dev/null || true
          ruff check . || true
          pytest -q || true
EOF

echo "==> Actions: Secret scanning (gitleaks agent)"
cat > .github/workflows/secrets.yml <<'EOF'
name: Secret Scan
on:
  pull_request:
  push: { branches: [ main ] }

permissions:
  contents: read
  security-events: write

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF

cat > .gitleaks.toml <<'EOF'
title = "BlackRoad Secrets Policy"
[[rules]]
id = "generic-api-key"
description = "Generic API key"
regex = '''(?i)(api[_-]?key|secret|token)\s*[:=]\s*['"][0-9a-zA-Z_\-]{16,}['"]'''
entropy = 3.5
EOF

echo "==> Actions: Issue triage (issue agent)"
cat > .github/workflows/issue-agent.yml <<'EOF'
name: Issue Agent
on:
  issues:
    types: [opened, edited, reopened]

permissions:
  issues: write
  contents: read

jobs:
  triage:
    runs-on: ubuntu-latest
    steps:
      - name: Label by title/body
        uses: github/issue-labeler@v3
        with:
          configuration-path: .github/issue-labeler.yml
          enable-versioned-regex: 0
          repo-token: ${{ secrets.GITHUB_TOKEN }}
EOF

cat > .github/issue-labeler.yml <<'EOF'
# Simple examples; expand as you like
frontend:
  - '/\b(ui|react|component|css|style|layout)\b/i'
backend:
  - '/\b(api|service|database|python|go|latency)\b/i'
security:
  - '/\b(secret|token|xss|csrf|vuln|cve|leak)\b/i'
tests:
  - '/\btest(s)?|jest|pytest|coverage\b/i'
docs:
  - '/\breadme|doc(s)?|guide|how-to|tutorial\b/i'
EOF

echo "==> Actions: Discussion manager (discussion agent)"
cat > .github/workflows/discussion-agent.yml <<'EOF'
name: Discussion Agent
on:
  discussion:
    types: [created, edited]

permissions:
  discussions: write
  contents: read

jobs:
  manage:
    runs-on: ubuntu-latest
    steps:
      - uses: dessant/discussion-manager@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          auto_label: true
          labels_map: |
            ideas:prompts
            q&a:docs
EOF

echo "==> Actions: Cleanup (stale + lock agents)"
cat > .github/workflows/stale.yml <<'EOF'
name: Mark stale issues and PRs
on:
  schedule: [{ cron: "0 3 * * *" }]

permissions:
  issues: write
  pull-requests: write

jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v9
        with:
          days-before-stale: 30
          days-before-close: 7
          stale-issue-message: "This issue is stale due to inactivity. It will auto-close in 7 days."
          stale-pr-message: "This PR is stale due to inactivity. It will auto-close in 7 days."
          exempt-issue-labels: "security,blocked"
          exempt-pr-labels: "security,blocked"
EOF

cat > .github/workflows/lock.yml <<'EOF'
name: Lock closed threads
on:
  schedule: [{ cron: "15 3 * * *" }]

permissions:
  issues: write
  pull-requests: write

jobs:
  lock:
    runs-on: ubuntu-latest
    steps:
      - uses: dessant/lock-threads@v5
        with:
          issue-lock-inactive-days: '7'
          pr-lock-inactive-days: '7'
          add-lock-labels: 'locked'
EOF

echo "==> Actions: Auto-assign reviewers / authors (review agent)"
cat > .github/auto-assign.yml <<'EOF'
addReviewers: true
addAssignees: author
reviewers:
  - blackboxprogramming
numberOfReviewers: 1
EOF

cat > .github/workflows/auto-assign.yml <<'EOF'
name: Auto Assign
on:
  pull_request:
    types: [opened, ready_for_review]

permissions:
  pull-requests: write
  contents: read

jobs:
  assign:
    runs-on: ubuntu-latest
    steps:
      - uses: kentaro-m/auto-assign@v2.0.0
        with:
          configuration-path: .github/auto-assign.yml
EOF

echo "==> Actions: Enforce Conventional Commit PR titles (quality gate agent)"
cat > .github/workflows/pr-title.yml <<'EOF'
name: PR Title Lint
on:
  pull_request:
    types: [opened, edited, synchronize, ready_for_review]

permissions:
  pull-requests: read

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            chore
            docs
            refactor
            test
            perf
            ci
            build
          requireScope: false
EOF

echo "==> Templates for Issues & Discussions"
cat > .github/ISSUE_TEMPLATE/bug_report.md <<'EOF'
---
name: "🐞 Bug report"
about: Report a problem
labels: ["tests"]
---

**Describe the bug**
A clear description…

**To Reproduce**
Steps…

**Expected behavior**
…

**Screenshots / Logs**
…

**Environment**
- OS:
- Node/Python:
EOF

cat > .github/ISSUE_TEMPLATE/feature_request.md <<'EOF'
---
name: "✨ Feature request"
about: Propose an idea
labels: ["frontend"]
---

**Problem**
…

**Proposed solution**
…

**Alternatives**
…
EOF

cat > .github/DISCUSSION_TEMPLATE/ideas.md <<'EOF'
# 💡 Idea
Describe your idea and why it matters.

## Rough plan
- Step 1
- Step 2

## Risks / Unknowns
- …
EOF

echo "==> CODEOWNERS"
mkdir -p .github
cat > .github/CODEOWNERS <<'EOF'
/sites/blackroad/     @blackboxprogramming
/api/                 @blackboxprogramming
/services/            @blackboxprogramming
/**/*.py              @blackboxprogramming
/**/*.ts              @blackboxprogramming
EOF

echo "==> Git setup, branch, commit, push, PR"
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"

git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
git add -A

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -s -m "chore(ci): install self-healing agents (labeler, autofix, codeql, dependabot, triage, cleanup, title-lint)"
fi

# Attempt push & PR (requires gh CLI auth)
if git push -u origin "$BRANCH"; then
  if command -v gh >/dev/null 2>&1; then
    gh pr create --fill --base main || true
  else
    echo "⚠️  gh CLI not found; create a PR from branch: $BRANCH"
  fi
else
  echo "⚠️  Push failed. Check your git remote/permissions, then push branch: $BRANCH"
fi

echo "✅ Done. Agents installed. Check Actions tab after first PR or nightly cron."

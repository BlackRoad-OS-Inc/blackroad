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
echo "==> Python fixes (ruff imports + lint; black format; isort just-in-case)"
ruff check . --fix || true
ruff format . || true
black . || true
isort . || true

echo "==> Normalize line endings"
git ls-files -z | xargs -0 -I {} bash -c 'printf "%s" "{}" | xargs dos2unix >/dev/null 2>&1 || true'

echo "==> Remove node_modules from index if present"
git rm -r --cached --ignore-unmatch **/node_modules 2>/dev/null || true

echo "==> Done."
echo "==> Remove node_modules cruft from index if any"
git rm -r --cached --ignore-unmatch **/node_modules 2>/dev/null || true

echo "==> Done."


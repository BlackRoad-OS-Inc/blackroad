#!/usr/bin/env bash
set -euo pipefail

ok() { printf "\033[32m✔ %s\033[0m\n" "$*"; }
warn() { printf "\033[33m⚠ %s\033[0m\n" "$*"; }
err() { printf "\033[31m✖ %s\033[0m\n" "$*"; }

# Node & npm
if command -v node >/dev/null 2>&1; then ok "node $(node -v)"; else err "node not found"; fi
if command -v npm  >/dev/null 2>&1; then ok "npm $(npm -v)"; else err "npm not found"; fi

# API health (best-effort)
if command -v curl >/dev/null 2>&1; then
  if curl -fsS "http://127.0.0.1:4000/health" >/dev/null 2>&1; then
    ok "API healthy on 4000"
  else
    warn "API not responding on 4000 (/health). Start your API and retry."
  fi
  if curl -fsS "http://127.0.0.1:8000/health" >/dev/null 2>&1; then
    ok "LLM healthy on 8000"
  else
    warn "LLM not responding on 8000. You can launch the local stub via:\n  cd srv/lucidia-llm && python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && uvicorn app:app --host 127.0.0.1 --port 8000"
  fi
else
  warn "'curl' not found; skipping health checks."
fi

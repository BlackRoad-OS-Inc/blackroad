#!/bin/zsh
# ◆ BR INIT — Project Scaffolder
# BlackRoad OS — From idea to code, instantly.

AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

#──────────────────────────────────────────────────────────────────────────────
# Shared scaffolding helpers
#──────────────────────────────────────────────────────────────────────────────
_write_readme() {
  local name="$1" template="$2" desc="${3:-A BlackRoad OS project}"
  cat > README.md << EOF
# ◆ ${name}

> ${desc}

**Template:** \`${template}\` · **BlackRoad OS**

## Quick Start

\`\`\`bash
# Install dependencies
$(case "$template" in
  nextjs|next)  echo "npm install" ;;
  fastapi|py)   echo "pip install -r requirements.txt" ;;
  go|go-api)    echo "go mod tidy" ;;
  rust)         echo "cargo build" ;;
  node)         echo "npm install" ;;
  *)            echo "# see docs" ;;
esac)

# Run dev server
$(case "$template" in
  nextjs|next)  echo "npm run dev" ;;
  fastapi|py)   echo "uvicorn main:app --reload" ;;
  go|go-api)    echo "go run ." ;;
  rust)         echo "cargo run" ;;
  node)         echo "npm start" ;;
  *)            echo "# see docs" ;;
esac)
\`\`\`

## Structure

$(case "$template" in
  nextjs|next) echo "\`\`\`\nsrc/app/          Next.js app router\nsrc/components/   React components\npublic/           Static assets\n\`\`\`" ;;
  fastapi|py)  echo "\`\`\`\nmain.py           FastAPI entry point\nrouters/          Route modules\nmodels/           Pydantic models\n\`\`\`" ;;
  go|go-api)   echo "\`\`\`\nmain.go           Entry point\nhandlers/         HTTP handlers\nmodels/           Data models\n\`\`\`" ;;
  rust)        echo "\`\`\`\nsrc/main.rs       Entry point\nsrc/handlers/     Request handlers\n\`\`\`" ;;
  *)           echo "\`\`\`\nsrc/              Source code\ntests/            Tests\n\`\`\`" ;;
esac)

---
*Built with ◆ BlackRoad OS — Your AI. Your Hardware. Your Rules.*
EOF
  echo -e "  ${DIM}✓ README.md${NC}"
}

_write_gitignore() {
  local template="$1"
  case "$template" in
    nextjs|next)
      printf ".next/\nout/\nnode_modules/\n.env.local\n.env*.local\n*.log\ndist/\n" > .gitignore ;;
    fastapi|py)
      printf "__pycache__/\n*.pyc\n.env\nvenv/\n.venv/\ndist/\nbuild/\n*.egg-info/\n.pytest_cache/\n" > .gitignore ;;
    go|go-api)
      printf "*.exe\n*.test\n*.out\nvendor/\n.env\nbin/\n" > .gitignore ;;
    rust)
      printf "target/\n.env\n*.pdb\n" > .gitignore ;;
    *)
      printf "node_modules/\n.env\ndist/\nbuild/\n*.log\n" > .gitignore ;;
  esac
  echo -e "  ${DIM}✓ .gitignore${NC}"
}

_write_env() {
  local name="$1" template="$2"
  case "$template" in
    nextjs|next)
      cat > .env.example << 'EOF'
# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_APP_NAME=MyApp

# Auth (if using)
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-here

# API
API_URL=http://localhost:8080
EOF
      ;;
    fastapi|py)
      cat > .env.example << 'EOF'
# Server
HOST=0.0.0.0
PORT=8000
ENV=development

# Database
DATABASE_URL=sqlite:///./app.db

# Auth
SECRET_KEY=your-secret-here
ACCESS_TOKEN_EXPIRE_MINUTES=30
EOF
      ;;
    go|go-api)
      cat > .env.example << 'EOF'
PORT=8080
ENV=development
DATABASE_URL=./app.db
JWT_SECRET=your-secret-here
EOF
      ;;
    *)
      cat > .env.example << 'EOF'
NODE_ENV=development
PORT=3000
DATABASE_URL=
EOF
      ;;
  esac
  echo -e "  ${DIM}✓ .env.example${NC}"
}

_git_init() {
  if command -v git &>/dev/null; then
    git init -q && git add -A && git commit -q -m "◆ init: scaffolded with br init" 2>/dev/null
    echo -e "  ${DIM}✓ git init + initial commit${NC}"
  fi
}

#──────────────────────────────────────────────────────────────────────────────
# Templates
#──────────────────────────────────────────────────────────────────────────────
init_nextjs() {
  local name="${1:-my-app}"
  echo -e "\n  ${AMBER}${BOLD}◆ BR INIT${NC}  ${DIM}Next.js 16 + React 19 + TypeScript${NC}\n"
  mkdir -p src/app src/components src/lib public
  # package.json
  cat > package.json << EOF
{
  "name": "${name}",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "typescript": "^5.0.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "^15.0.0"
  }
}
EOF
  echo -e "  ${DIM}✓ package.json${NC}"
  # tsconfig
  cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{"name": "next"}],
    "paths": {"@/*": ["./src/*"]}
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
EOF
  echo -e "  ${DIM}✓ tsconfig.json${NC}"
  # next.config
  cat > next.config.ts << 'EOF'
import type { NextConfig } from 'next'
const nextConfig: NextConfig = {}
export default nextConfig
EOF
  echo -e "  ${DIM}✓ next.config.ts${NC}"
  # App layout
  cat > src/app/layout.tsx << EOF
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: '${name}',
  description: 'Built with ◆ BlackRoad OS',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
EOF
  echo -e "  ${DIM}✓ src/app/layout.tsx${NC}"
  # App page
  cat > src/app/page.tsx << EOF
export default function Home() {
  return (
    <main>
      <h1>◆ ${name}</h1>
      <p>Built with BlackRoad OS</p>
    </main>
  )
}
EOF
  echo -e "  ${DIM}✓ src/app/page.tsx${NC}"
  _write_readme "$name" "nextjs" "Next.js 16 + React 19 application"
  _write_gitignore "nextjs"
  _write_env "$name" "nextjs"
  _git_init
  echo -e "\n  ${GREEN}✅ Next.js project ready${NC}  ${DIM}→  npm install && npm run dev${NC}\n"
}

init_fastapi() {
  local name="${1:-my-api}"
  echo -e "\n  ${AMBER}${BOLD}◆ BR INIT${NC}  ${DIM}FastAPI + Python 3.12 + SQLite${NC}\n"
  mkdir -p routers models tests
  # requirements.txt
  cat > requirements.txt << 'EOF'
fastapi>=0.115.0
uvicorn[standard]>=0.30.0
pydantic>=2.0.0
python-dotenv>=1.0.0
sqlalchemy>=2.0.0
alembic>=1.13.0
httpx>=0.27.0
pytest>=8.0.0
pytest-asyncio>=0.24.0
EOF
  echo -e "  ${DIM}✓ requirements.txt${NC}"
  # main.py
  cat > main.py << EOF
"""◆ ${name} — FastAPI application"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("◆ ${name} starting up")
    yield
    print("◆ ${name} shutting down")

app = FastAPI(
    title="${name}",
    description="Built with ◆ BlackRoad OS",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "${name}"}

@app.get("/")
async def root():
    return {"message": "◆ ${name} is running"}
EOF
  echo -e "  ${DIM}✓ main.py${NC}"
  # models/__init__.py
  touch models/__init__.py routers/__init__.py
  cat > models/base.py << 'EOF'
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class TimestampMixin(BaseModel):
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
EOF
  echo -e "  ${DIM}✓ models/base.py${NC}"
  cat > tests/test_main.py << EOF
import pytest
from httpx import AsyncClient, ASGITransport
from main import app

@pytest.mark.asyncio
async def test_health():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        r = await c.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"
EOF
  echo -e "  ${DIM}✓ tests/test_main.py${NC}"
  _write_readme "$name" "fastapi" "FastAPI Python REST API"
  _write_gitignore "fastapi"
  _write_env "$name" "fastapi"
  _git_init
  echo -e "\n  ${GREEN}✅ FastAPI project ready${NC}  ${DIM}→  pip install -r requirements.txt && uvicorn main:app --reload${NC}\n"
}

init_go_api() {
  local name="${1:-my-api}"
  echo -e "\n  ${AMBER}${BOLD}◆ BR INIT${NC}  ${DIM}Go 1.22 + net/http + SQLite${NC}\n"
  mkdir -p handlers models middleware
  go mod init "${name}" 2>/dev/null || true
  echo -e "  ${DIM}✓ go.mod${NC}"
  cat > main.go << EOF
package main

import (
"fmt"
"log"
"net/http"
"os"
)

func main() {
port := os.Getenv("PORT")
if port == "" {
= "8080"
}

mux := http.NewServeMux()
mux.HandleFunc("GET /health", healthHandler)
mux.HandleFunc("GET /", rootHandler)

fmt.Printf("◆ ${name} running on :%s\\n", port)
log.Fatal(http.ListenAndServe(":"+port, mux))
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
w.Header().Set("Content-Type", "application/json")
fmt.Fprintf(w, \`{"status":"ok","service":"${name}"}\`)
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
w.Header().Set("Content-Type", "application/json")
fmt.Fprintf(w, \`{"message":"◆ ${name} is running"}\`)
}
EOF
  echo -e "  ${DIM}✓ main.go${NC}"
  cat > handlers/handler.go << 'EOF'
package handlers

import "net/http"

type Handler struct{}

func New() *Handler { return &Handler{} }

func (h *Handler) NotFound(w http.ResponseWriter, r *http.Request) {
http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
}
EOF
  echo -e "  ${DIM}✓ handlers/handler.go${NC}"
  _write_readme "$name" "go-api" "Go REST API with net/http"
  _write_gitignore "go"
  _write_env "$name" "go"
  _git_init
  echo -e "\n  ${GREEN}✅ Go API ready${NC}  ${DIM}→  go run .${NC}\n"
}

init_rust() {
  local name="${1:-my-app}"
  echo -e "\n  ${AMBER}${BOLD}◆ BR INIT${NC}  ${DIM}Rust + Axum web server${NC}\n"
  if command -v cargo &>/dev/null; then
    cargo init --name "$name" 2>/dev/null
    echo -e "  ${DIM}✓ Cargo.toml + src/main.rs${NC}"
    # Add axum deps
    cat >> Cargo.toml << 'EOF'

[dependencies]
axum = "0.7"
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
dotenvy = "0.15"
EOF
    # Rewrite main.rs
    cat > src/main.rs << EOF
use axum::{routing::get, Json, Router};
use serde_json::{json, Value};

#[tokio::main]
async fn main() {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    let addr = format!("0.0.0.0:{}", port);

    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health));

    println!("◆ ${name} running on {}", addr);
    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn root() -> Json<Value> {
    Json(json!({"message": "◆ ${name} is running"}))
}

async fn health() -> Json<Value> {
    Json(json!({"status": "ok", "service": "${name}"}))
}
EOF
    echo -e "  ${DIM}✓ src/main.rs (Axum)${NC}"
  else
    echo -e "  ${RED}✗ cargo not found — install Rust from https://rustup.rs${NC}"
    return 1
  fi
  _write_readme "$name" "rust" "Rust + Axum web server"
  _write_gitignore "rust"
  _write_env "$name" "rust"
  _git_init
  echo -e "\n  ${GREEN}✅ Rust project ready${NC}  ${DIM}→  cargo run${NC}\n"
}

init_node() {
  local name="${1:-my-app}"
  echo -e "\n  ${AMBER}${BOLD}◆ BR INIT${NC}  ${DIM}Node.js + TypeScript + Express${NC}\n"
  mkdir -p src tests
  cat > package.json << EOF
{
  "name": "${name}",
  "version": "0.1.0",
  "main": "dist/index.js",
  "scripts": {
    "dev": "ts-node src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.0",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.0",
    "@types/node": "^22.0.0",
    "typescript": "^5.0.0",
    "ts-node": "^10.9.0",
    "jest": "^29.0.0",
    "@types/jest": "^29.0.0"
  }
}
EOF
  echo -e "  ${DIM}✓ package.json${NC}"
  cat > src/index.ts << EOF
import express from 'express'
import 'dotenv/config'

const app = express()
const PORT = process.env.PORT ?? 3000

app.use(express.json())

app.get('/health', (_req, res) => res.json({ status: 'ok', service: '${name}' }))
app.get('/', (_req, res) => res.json({ message: '◆ ${name} is running' }))

app.listen(PORT, () => console.log(\`◆ ${name} running on :\${PORT}\`))
EOF
  echo -e "  ${DIM}✓ src/index.ts${NC}"
  printf '{\n  "compilerOptions": {\n    "target": "ES2020",\n    "module": "commonjs",\n    "outDir": "dist",\n    "rootDir": "src",\n    "strict": true,\n    "esModuleInterop": true,\n    "skipLibCheck": true\n  },\n  "include": ["src"]\n}\n' > tsconfig.json
  echo -e "  ${DIM}✓ tsconfig.json${NC}"
  _write_readme "$name" "node" "Node.js + TypeScript + Express"
  _write_gitignore "node"
  _write_env "$name" "node"
  _git_init
  echo -e "\n  ${GREEN}✅ Node.js project ready${NC}  ${DIM}→  npm install && npm run dev${NC}\n"
}

init_python() {
  local name="${1:-my-project}"
  echo -e "\n  ${AMBER}${BOLD}◆ BR INIT${NC}  ${DIM}Python project (pytest + black + ruff)${NC}\n"
  mkdir -p src tests
  cat > requirements.txt << 'EOF'
pytest>=8.0.0
black>=24.0.0
ruff>=0.4.0
python-dotenv>=1.0.0
EOF
  echo -e "  ${DIM}✓ requirements.txt${NC}"
  printf '"""◆ %s"""\n\n__version__ = "0.1.0"\n' "$name" > src/__init__.py
  printf 'def hello(name: str = "world") -> str:\n    return f"Hello, {name}!"\n\n\nif __name__ == "__main__":\n    print(hello())\n' > src/main.py
  printf 'from src.main import hello\n\ndef test_hello():\n    assert hello() == "Hello, world!"\n\ndef test_hello_name():\n    assert hello("blackroad") == "Hello, blackroad!"\n' > tests/test_main.py
  echo -e "  ${DIM}✓ src/main.py + tests/test_main.py${NC}"
  _write_readme "$name" "python" "Python project"
  _write_gitignore "python"
  _write_env "$name" "python"
  _git_init
  echo -e "\n  ${GREEN}✅ Python project ready${NC}  ${DIM}→  pip install -r requirements.txt && pytest${NC}\n"
}

#──────────────────────────────────────────────────────────────────────────────
# New project in directory
#──────────────────────────────────────────────────────────────────────────────
cmd_new() {
  local name="$1" template="$2"
  if [[ -z "$name" ]]; then
    echo -e "${RED}✗ Usage: br init new <name> <template>${NC}"
    show_help; return 1
  fi
  [[ -z "$template" ]] && template="node"
  mkdir -p "$name" && cd "$name" || return 1
  echo -e "\n  ${AMBER}${BOLD}◆ BR INIT${NC}  ${DIM}Scaffolding:${NC} ${BOLD}${name}${NC}  ${DIM}[${template}]${NC}"
  case "$template" in
    nextjs|next)    init_nextjs "$name" ;;
    fastapi|py|api) init_fastapi "$name" ;;
    go|go-api)      init_go_api "$name" ;;
    rust)           init_rust "$name" ;;
    node|js)        init_node "$name" ;;
    python)         init_python "$name" ;;
    *) echo -e "${RED}✗ Unknown template: $template${NC}"; show_help; cd ..; rm -rf "$name"; return 1 ;;
  esac
}

#──────────────────────────────────────────────────────────────────────────────
# Init in current directory
#──────────────────────────────────────────────────────────────────────────────
cmd_init_here() {
  local template="$1"
  local name="$(basename "$(pwd)")"
  echo -e "\n  ${AMBER}${BOLD}◆ BR INIT${NC}  ${DIM}Scaffolding in current dir:${NC} ${BOLD}${name}${NC}  ${DIM}[${template}]${NC}"
  case "$template" in
    nextjs|next)    init_nextjs "$name" ;;
    fastapi|py|api) init_fastapi "$name" ;;
    go|go-api)      init_go_api "$name" ;;
    rust)           init_rust "$name" ;;
    node|js)        init_node "$name" ;;
    python)         init_python "$name" ;;
    *) show_help; return 1 ;;
  esac
}

#──────────────────────────────────────────────────────────────────────────────
# Env init from .env.example
#──────────────────────────────────────────────────────────────────────────────
cmd_env() {
  if [[ ! -f ".env.example" ]]; then
    echo -e "${RED}✗ No .env.example found in current directory${NC}"; return 1
  fi
  if [[ -f ".env" ]]; then
    echo -e "${AMBER}⚠ .env already exists — skipping${NC}"; return 0
  fi
  cp .env.example .env
  echo -e "${GREEN}✅ .env created from .env.example${NC}  ${DIM}→  edit .env with your values${NC}"
}

#──────────────────────────────────────────────────────────────────────────────
# Help + template list
#──────────────────────────────────────────────────────────────────────────────
show_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR INIT${NC}  ${DIM}Scaffold projects in seconds.${NC}"
  echo -e "  ${DIM}From idea to code — instantly. Six battle-tested templates.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br init ${DIM}<command> [name] [template]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  new <name> <template>           ${NC} Scaffold into new directory"
  echo -e "  ${AMBER}  <template>                      ${NC} Scaffold in current directory"
  echo -e "  ${AMBER}  env                             ${NC} Create .env from .env.example"
  echo -e "  ${AMBER}  list                            ${NC} List available templates"
  echo -e ""
  echo -e "  ${BOLD}TEMPLATES${NC}"
  echo -e "  ${AMBER}  nextjs    ${NC} ${BOLD}Next.js 16${NC} + React 19 + TypeScript + App Router"
  echo -e "  ${AMBER}  fastapi   ${NC} ${BOLD}FastAPI${NC} + Python 3.12 + Pydantic v2 + SQLAlchemy"
  echo -e "  ${AMBER}  go-api    ${NC} ${BOLD}Go 1.22${NC} + net/http + health endpoint"
  echo -e "  ${AMBER}  rust      ${NC} ${BOLD}Rust${NC} + Axum + Tokio async runtime"
  echo -e "  ${AMBER}  node      ${NC} ${BOLD}Node.js${NC} + TypeScript + Express"
  echo -e "  ${AMBER}  python    ${NC} ${BOLD}Python${NC} + pytest + black + ruff"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br init new my-dashboard nextjs${NC}"
  echo -e "  ${DIM}  br init new my-api fastapi${NC}"
  echo -e "  ${DIM}  br init new my-service go-api${NC}"
  echo -e "  ${DIM}  br init new my-cli rust${NC}"
  echo -e "  ${DIM}  br init env${NC}"
  echo -e ""
}

#──────────────────────────────────────────────────────────────────────────────
# Dispatch
#──────────────────────────────────────────────────────────────────────────────
case "${1:-list}" in
  new)            cmd_new "${2:-}" "${3:-node}" ;;
  env)            cmd_env ;;
  list|templates) show_help ;;
  nextjs|next)    init_nextjs "$(basename "$(pwd)")" ;;
  fastapi|py|api) init_fastapi "$(basename "$(pwd)")" ;;
  go|go-api)      init_go_api "$(basename "$(pwd)")" ;;
  rust)           init_rust "$(basename "$(pwd)")" ;;
  node|js)        init_node "$(basename "$(pwd)")" ;;
  python)         init_python "$(basename "$(pwd)")" ;;
  help|-h|--help) show_help ;;
  *)              show_help ;;
esac

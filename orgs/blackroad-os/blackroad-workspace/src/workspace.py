#!/usr/bin/env python3
"""BlackRoad Workspace Manager — multi-project dev environments with secrets scoping."""

import sqlite3
import json
import uuid
import os
import sys
import argparse
import base64
import hashlib
import re
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List, Dict, Any, Tuple
from enum import Enum

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

DB_PATH = os.environ.get("WORKSPACE_DB", os.path.expanduser("~/.blackroad/workspace.db"))
CURRENT_WS_FILE = os.path.expanduser("~/.blackroad/.current_workspace")


class EnvType(str, Enum):
    DEVELOPMENT = "development"
    STAGING = "staging"
    PRODUCTION = "production"
    TESTING = "testing"
    LOCAL = "local"


class SecretScope(str, Enum):
    GLOBAL = "global"
    WORKSPACE = "workspace"
    PROJECT = "project"
    ENVIRONMENT = "environment"


@dataclass
class Workspace:
    id: str
    name: str
    description: str
    owner: str
    color: str
    icon: str
    default_env: str
    git_root: str
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    metadata: Dict[str, Any] = field(default_factory=dict)
    tags: List[str] = field(default_factory=list)


@dataclass
class Project:
    id: str
    workspace_id: str
    name: str
    description: str
    path: str
    language: str
    framework: str
    repo_url: str
    active: bool = True
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Environment:
    id: str
    workspace_id: str
    name: str
    env_type: EnvType
    base_url: str
    variables: Dict[str, str]
    inherits_from: Optional[str] = None
    active: bool = True
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


@dataclass
class ConfigEntry:
    id: str
    scope_type: str
    scope_id: str
    key: str
    value: str
    value_type: str = "string"
    encrypted: bool = False
    description: str = ""
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


@dataclass
class Secret:
    id: str
    scope_type: SecretScope
    scope_id: str
    name: str
    value_hash: str
    value_encrypted: str
    description: str = ""
    rotation_days: int = 90
    last_rotated: Optional[str] = None
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    expires_at: Optional[str] = None


class SecretCrypto:
    """Simple XOR-based encryption for demo (use real crypto in prod)."""

    @staticmethod
    def _derive_key(passphrase: str, length: int = 32) -> bytes:
        return hashlib.pbkdf2_hmac("sha256", passphrase.encode(), b"blackroad-salt-v1", 100_000, length)

    @classmethod
    def encrypt(cls, value: str, passphrase: str) -> str:
        key = cls._derive_key(passphrase)
        data = value.encode()
        encrypted = bytes(b ^ key[i % len(key)] for i, b in enumerate(data))
        return base64.b64encode(encrypted).decode()

    @classmethod
    def decrypt(cls, encrypted_b64: str, passphrase: str) -> str:
        key = cls._derive_key(passphrase)
        encrypted = base64.b64decode(encrypted_b64)
        decrypted = bytes(b ^ key[i % len(key)] for i, b in enumerate(encrypted))
        return decrypted.decode()

    @classmethod
    def hash_value(cls, value: str) -> str:
        return hashlib.sha256(value.encode()).hexdigest()[:16]


class WorkspaceDB:
    def __init__(self, db_path: str = DB_PATH):
        os.makedirs(os.path.dirname(db_path) or ".", exist_ok=True)
        self.conn = sqlite3.connect(db_path)
        self.conn.row_factory = sqlite3.Row
        self.conn.execute("PRAGMA foreign_keys = ON")
        self._init_schema()

    def _init_schema(self):
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS workspaces (
                id TEXT PRIMARY KEY,
                name TEXT UNIQUE NOT NULL,
                description TEXT DEFAULT '',
                owner TEXT DEFAULT '',
                color TEXT DEFAULT '#00BFFF',
                icon TEXT DEFAULT '📁',
                default_env TEXT DEFAULT 'development',
                git_root TEXT DEFAULT '',
                tags TEXT DEFAULT '[]',
                metadata TEXT DEFAULT '{}',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS projects (
                id TEXT PRIMARY KEY,
                workspace_id TEXT NOT NULL REFERENCES workspaces(id),
                name TEXT NOT NULL,
                description TEXT DEFAULT '',
                path TEXT NOT NULL,
                language TEXT DEFAULT '',
                framework TEXT DEFAULT '',
                repo_url TEXT DEFAULT '',
                active INTEGER DEFAULT 1,
                metadata TEXT DEFAULT '{}',
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS environments (
                id TEXT PRIMARY KEY,
                workspace_id TEXT NOT NULL REFERENCES workspaces(id),
                name TEXT NOT NULL,
                env_type TEXT NOT NULL,
                base_url TEXT DEFAULT '',
                variables TEXT DEFAULT '{}',
                inherits_from TEXT,
                active INTEGER DEFAULT 1,
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS configs (
                id TEXT PRIMARY KEY,
                scope_type TEXT NOT NULL,
                scope_id TEXT NOT NULL,
                key TEXT NOT NULL,
                value TEXT NOT NULL,
                value_type TEXT DEFAULT 'string',
                encrypted INTEGER DEFAULT 0,
                description TEXT DEFAULT '',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                UNIQUE(scope_type, scope_id, key)
            );
            CREATE TABLE IF NOT EXISTS secrets (
                id TEXT PRIMARY KEY,
                scope_type TEXT NOT NULL,
                scope_id TEXT NOT NULL,
                name TEXT NOT NULL,
                value_hash TEXT NOT NULL,
                value_encrypted TEXT NOT NULL,
                description TEXT DEFAULT '',
                rotation_days INTEGER DEFAULT 90,
                last_rotated TEXT,
                created_at TEXT NOT NULL,
                expires_at TEXT,
                UNIQUE(scope_type, scope_id, name)
            );
            CREATE INDEX IF NOT EXISTS idx_projects_ws ON projects(workspace_id);
            CREATE INDEX IF NOT EXISTS idx_configs_scope ON configs(scope_type, scope_id, key);
            CREATE INDEX IF NOT EXISTS idx_secrets_scope ON secrets(scope_type, scope_id, name);
        """)
        self.conn.commit()


class WorkspaceManager:
    def __init__(self, db: WorkspaceDB, master_passphrase: str = "blackroad-default-key"):
        self.db = db
        self._passphrase = master_passphrase

    # ── Workspace CRUD ─────────────────────────────────────────────────────

    def create_workspace(self, name: str, description: str = "",
                         owner: str = "", color: str = "#00BFFF",
                         icon: str = "📁", tags: List[str] = None) -> Workspace:
        ws = Workspace(
            id=str(uuid.uuid4()), name=name, description=description,
            owner=owner, color=color, icon=icon,
            default_env=EnvType.DEVELOPMENT.value,
            git_root=os.getcwd(), tags=tags or []
        )
        self.db.conn.execute(
            "INSERT INTO workspaces VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
            (ws.id, ws.name, ws.description, ws.owner, ws.color, ws.icon,
             ws.default_env, ws.git_root, json.dumps(ws.tags),
             json.dumps(ws.metadata), ws.created_at, ws.updated_at)
        )
        self.db.conn.commit()
        return ws

    def switch_workspace(self, name: str) -> Optional[Dict]:
        row = self.db.conn.execute(
            "SELECT * FROM workspaces WHERE name=?", (name,)
        ).fetchone()
        if not row:
            return None
        os.makedirs(os.path.dirname(CURRENT_WS_FILE), exist_ok=True)
        with open(CURRENT_WS_FILE, "w") as f:
            f.write(row["id"])
        return dict(row)

    def current_workspace(self) -> Optional[Dict]:
        if not os.path.exists(CURRENT_WS_FILE):
            return None
        with open(CURRENT_WS_FILE) as f:
            ws_id = f.read().strip()
        row = self.db.conn.execute(
            "SELECT * FROM workspaces WHERE id=?", (ws_id,)
        ).fetchone()
        return dict(row) if row else None

    def list_workspaces(self) -> List[Dict]:
        current = self.current_workspace()
        current_id = current["id"] if current else None
        rows = self.db.conn.execute(
            "SELECT w.*, COUNT(DISTINCT p.id) as project_count, "
            "COUNT(DISTINCT e.id) as env_count "
            "FROM workspaces w "
            "LEFT JOIN projects p ON p.workspace_id = w.id AND p.active=1 "
            "LEFT JOIN environments e ON e.workspace_id = w.id "
            "GROUP BY w.id ORDER BY w.created_at DESC"
        ).fetchall()
        result = []
        for r in rows:
            d = dict(r)
            d["is_current"] = d["id"] == current_id
            result.append(d)
        return result

    # ── Project management ─────────────────────────────────────────────────

    def add_project(self, workspace_id: str, name: str, path: str,
                    language: str = "", framework: str = "",
                    repo_url: str = "", description: str = "") -> Project:
        proj = Project(
            id=str(uuid.uuid4()), workspace_id=workspace_id,
            name=name, description=description, path=os.path.abspath(path),
            language=language, framework=framework, repo_url=repo_url
        )
        self.db.conn.execute(
            "INSERT INTO projects VALUES (?,?,?,?,?,?,?,?,?,?,?)",
            (proj.id, proj.workspace_id, proj.name, proj.description,
             proj.path, proj.language, proj.framework, proj.repo_url,
             int(proj.active), json.dumps(proj.metadata), proj.created_at)
        )
        self.db.conn.commit()
        return proj

    def list_projects(self, workspace_id: str) -> List[Dict]:
        rows = self.db.conn.execute(
            "SELECT p.*, COUNT(DISTINCT c.id) as config_count, "
            "COUNT(DISTINCT s.id) as secret_count "
            "FROM projects p "
            "LEFT JOIN configs c ON c.scope_type='project' AND c.scope_id=p.id "
            "LEFT JOIN secrets s ON s.scope_type='project' AND s.scope_id=p.id "
            "WHERE p.workspace_id=? AND p.active=1 "
            "GROUP BY p.id ORDER BY p.created_at DESC",
            (workspace_id,)
        ).fetchall()
        return [dict(r) for r in rows]

    # ── Environment management ─────────────────────────────────────────────

    def create_environment(self, workspace_id: str, name: str,
                           env_type: str, base_url: str = "",
                           variables: Dict[str, str] = None,
                           inherits_from: str = None) -> Environment:
        env = Environment(
            id=str(uuid.uuid4()), workspace_id=workspace_id,
            name=name, env_type=EnvType(env_type),
            base_url=base_url, variables=variables or {},
            inherits_from=inherits_from
        )
        self.db.conn.execute(
            "INSERT INTO environments VALUES (?,?,?,?,?,?,?,?,?)",
            (env.id, env.workspace_id, env.name, env.env_type.value,
             env.base_url, json.dumps(env.variables),
             env.inherits_from, int(env.active), env.created_at)
        )
        self.db.conn.commit()
        return env

    def resolve_environment(self, env_id: str) -> Dict[str, str]:
        """Resolve environment variables with inheritance chain."""
        env_row = self.db.conn.execute(
            "SELECT * FROM environments WHERE id=?", (env_id,)
        ).fetchone()
        if not env_row:
            return {}

        chain = []
        visited = set()
        current = dict(env_row)
        while current and current["id"] not in visited:
            chain.append(current)
            visited.add(current["id"])
            if current.get("inherits_from"):
                parent_row = self.db.conn.execute(
                    "SELECT * FROM environments WHERE id=?", (current["inherits_from"],)
                ).fetchone()
                current = dict(parent_row) if parent_row else None
            else:
                break

        merged: Dict[str, str] = {}
        for env in reversed(chain):
            merged.update(json.loads(env.get("variables", "{}")))
        return merged

    # ── Config management ──────────────────────────────────────────────────

    def set_config(self, scope_type: str, scope_id: str, key: str,
                   value: str, value_type: str = "string",
                   description: str = "") -> ConfigEntry:
        now = datetime.utcnow().isoformat()
        entry_id = str(uuid.uuid4())
        existing = self.db.conn.execute(
            "SELECT id FROM configs WHERE scope_type=? AND scope_id=? AND key=?",
            (scope_type, scope_id, key)
        ).fetchone()
        if existing:
            self.db.conn.execute(
                "UPDATE configs SET value=?, value_type=?, description=?, updated_at=? "
                "WHERE scope_type=? AND scope_id=? AND key=?",
                (value, value_type, description, now, scope_type, scope_id, key)
            )
            entry_id = existing["id"]
        else:
            self.db.conn.execute(
                "INSERT INTO configs VALUES (?,?,?,?,?,?,?,?,?,?)",
                (entry_id, scope_type, scope_id, key, value,
                 value_type, 0, description, now, now)
            )
        self.db.conn.commit()
        return ConfigEntry(id=entry_id, scope_type=scope_type, scope_id=scope_id,
                           key=key, value=value, value_type=value_type,
                           description=description)

    def get_config(self, scope_type: str, scope_id: str, key: str,
                   fallback: Any = None) -> Any:
        row = self.db.conn.execute(
            "SELECT value, value_type FROM configs WHERE scope_type=? AND scope_id=? AND key=?",
            (scope_type, scope_id, key)
        ).fetchone()
        if not row:
            return fallback
        value, vtype = row["value"], row["value_type"]
        type_map = {
            "int": int, "float": float,
            "bool": lambda v: v.lower() in ("true", "1", "yes"),
            "json": json.loads
        }
        return type_map.get(vtype, str)(value)

    def list_configs(self, scope_type: str, scope_id: str) -> List[Dict]:
        rows = self.db.conn.execute(
            "SELECT * FROM configs WHERE scope_type=? AND scope_id=? ORDER BY key",
            (scope_type, scope_id)
        ).fetchall()
        return [dict(r) for r in rows]

    # ── Secret management ──────────────────────────────────────────────────

    def set_secret(self, scope_type: str, scope_id: str, name: str,
                   value: str, description: str = "",
                   rotation_days: int = 90) -> Secret:
        value_hash = SecretCrypto.hash_value(value)
        value_enc = SecretCrypto.encrypt(value, self._passphrase)
        now = datetime.utcnow().isoformat()
        secret_id = str(uuid.uuid4())
        existing = self.db.conn.execute(
            "SELECT id FROM secrets WHERE scope_type=? AND scope_id=? AND name=?",
            (scope_type, scope_id, name)
        ).fetchone()
        if existing:
            secret_id = existing["id"]
            self.db.conn.execute(
                "UPDATE secrets SET value_hash=?, value_encrypted=?, last_rotated=? WHERE id=?",
                (value_hash, value_enc, now, secret_id)
            )
        else:
            self.db.conn.execute(
                "INSERT INTO secrets VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                (secret_id, scope_type, scope_id, name,
                 value_hash, value_enc, description, rotation_days, now, now, None)
            )
        self.db.conn.commit()
        return Secret(id=secret_id, scope_type=SecretScope(scope_type),
                      scope_id=scope_id, name=name, value_hash=value_hash,
                      value_encrypted=value_enc, description=description,
                      rotation_days=rotation_days, last_rotated=now)

    def get_secret(self, scope_type: str, scope_id: str, name: str) -> Optional[str]:
        row = self.db.conn.execute(
            "SELECT value_encrypted FROM secrets WHERE scope_type=? AND scope_id=? AND name=?",
            (scope_type, scope_id, name)
        ).fetchone()
        if not row:
            return None
        return SecretCrypto.decrypt(row["value_encrypted"], self._passphrase)

    def inject_secrets(self, scope_type: str, scope_id: str,
                       template: str) -> str:
        """Inject secrets into template strings like ${SECRET_NAME}."""
        pattern = re.compile(r"\$\{([A-Z_][A-Z0-9_]*)\}")
        secrets_cache: Dict[str, str] = {}
        rows = self.db.conn.execute(
            "SELECT name, value_encrypted FROM secrets WHERE scope_type=? AND scope_id=?",
            (scope_type, scope_id)
        ).fetchall()
        for row in rows:
            try:
                secrets_cache[row["name"]] = SecretCrypto.decrypt(
                    row["value_encrypted"], self._passphrase
                )
            except Exception:
                secrets_cache[row["name"]] = "***DECRYPT_ERROR***"

        def replacer(match: re.Match) -> str:
            return secrets_cache.get(match.group(1), match.group(0))

        return pattern.sub(replacer, template)

    def list_secrets(self, scope_type: str, scope_id: str) -> List[Dict]:
        rows = self.db.conn.execute(
            "SELECT id, scope_type, scope_id, name, value_hash, description, "
            "rotation_days, last_rotated, created_at, expires_at "
            "FROM secrets WHERE scope_type=? AND scope_id=? ORDER BY name",
            (scope_type, scope_id)
        ).fetchall()
        return [dict(r) for r in rows]

    def workspace_summary(self, workspace_id: str) -> Dict:
        ws_row = self.db.conn.execute(
            "SELECT * FROM workspaces WHERE id=?", (workspace_id,)
        ).fetchone()
        if not ws_row:
            return {}
        projects = self.list_projects(workspace_id)
        envs = self.db.conn.execute(
            "SELECT * FROM environments WHERE workspace_id=?", (workspace_id,)
        ).fetchall()
        configs = self.db.conn.execute(
            "SELECT COUNT(*) as c FROM configs WHERE scope_type='workspace' AND scope_id=?",
            (workspace_id,)
        ).fetchone()["c"]
        secrets_count = self.db.conn.execute(
            "SELECT COUNT(*) as c FROM secrets WHERE scope_type='workspace' AND scope_id=?",
            (workspace_id,)
        ).fetchone()["c"]
        return {
            "workspace": dict(ws_row),
            "projects": len(projects),
            "environments": len(envs),
            "configs": configs,
            "secrets": secrets_count,
            "project_list": projects,
            "env_list": [dict(e) for e in envs],
        }


# ── CLI ───────────────────────────────────────────────────────────────────────

def _banner():
    print(f"\n{BOLD}{MAGENTA}╔══════════════════════════════════════════╗{RESET}")
    print(f"{BOLD}{MAGENTA}║   BlackRoad Workspace Manager  v1.0.0    ║{RESET}")
    print(f"{BOLD}{MAGENTA}╚══════════════════════════════════════════╝{RESET}\n")


def _get_manager() -> WorkspaceManager:
    passphrase = os.environ.get("WORKSPACE_KEY", "blackroad-default-key")
    return WorkspaceManager(WorkspaceDB(), passphrase)


def cmd_create(args):
    mgr = _get_manager()
    tags = [t.strip() for t in args.tags.split(",")] if args.tags else []
    ws = mgr.create_workspace(args.name, args.description, args.owner,
                               args.color, args.icon, tags)
    print(f"{GREEN}✓ Workspace '{ws.name}' created{RESET}")
    print(f"  {DIM}ID:{RESET}    {CYAN}{ws.id[:12]}…{RESET}")
    print(f"  {DIM}Owner:{RESET} {ws.owner or 'unset'}")
    print(f"  {DIM}Icon:{RESET}  {ws.icon}  {DIM}Color:{RESET} {ws.color}")


def cmd_switch(args):
    mgr = _get_manager()
    ws = mgr.switch_workspace(args.name)
    if not ws:
        print(f"{RED}✗ Workspace '{args.name}' not found{RESET}")
        sys.exit(1)
    print(f"{GREEN}✓ Switched to workspace: {BOLD}{ws['name']}{RESET}")
    print(f"  {ws['icon']}  {ws['description'] or 'No description'}")


def cmd_list(args):
    mgr = _get_manager()
    workspaces = mgr.list_workspaces()
    print(f"\n{BOLD}Workspaces ({len(workspaces)}){RESET}")
    print(f"  {'Name':<20} {'Projects':>9} {'Envs':>5}  {'Owner':<15}  Created")
    print(f"  {'─'*20} {'─'*9} {'─'*5}  {'─'*15}  {'─'*10}")
    for ws in workspaces:
        cursor = f" {CYAN}◄ current{RESET}" if ws.get("is_current") else ""
        icon = ws.get("icon", "📁")
        print(f"  {icon} {BOLD}{ws['name']:<18}{RESET} {ws['project_count']:>9} "
              f"{ws['env_count']:>5}  {ws['owner']:<15}  {ws['created_at'][:10]}{cursor}")


def cmd_add_project(args):
    mgr = _get_manager()
    ws = mgr.db.conn.execute("SELECT id FROM workspaces WHERE name=?", (args.workspace,)).fetchone()
    if not ws:
        print(f"{RED}✗ Workspace '{args.workspace}' not found{RESET}")
        sys.exit(1)
    proj = mgr.add_project(ws["id"], args.name, args.path,
                            args.language, args.framework, args.repo)
    print(f"{GREEN}✓ Project '{proj.name}' added{RESET}")
    print(f"  {DIM}Path:{RESET}      {proj.path}")
    print(f"  {DIM}Language:{RESET}  {proj.language or 'unset'}")
    print(f"  {DIM}Framework:{RESET} {proj.framework or 'unset'}")


def cmd_set_config(args):
    mgr = _get_manager()
    entry = mgr.set_config(args.scope, args.scope_id, args.key, args.value,
                            args.type, args.description)
    print(f"{GREEN}✓ Config set{RESET}")
    print(f"  {DIM}Scope:{RESET} {args.scope}/{args.scope_id}")
    print(f"  {DIM}Key:{RESET}   {entry.key} = {entry.value} ({entry.value_type})")


def cmd_set_secret(args):
    mgr = _get_manager()
    secret = mgr.set_secret(args.scope, args.scope_id, args.name, args.value,
                              args.description, args.rotation)
    print(f"{GREEN}✓ Secret '{secret.name}' stored{RESET}")
    print(f"  {DIM}Scope:{RESET} {args.scope}/{args.scope_id}")
    print(f"  {DIM}Hash:{RESET}  {secret.value_hash}  "
          f"{DIM}Rotation:{RESET} {secret.rotation_days}d")


def cmd_get_secret(args):
    mgr = _get_manager()
    value = mgr.get_secret(args.scope, args.scope_id, args.name)
    if value is None:
        print(f"{RED}✗ Secret '{args.name}' not found{RESET}")
        sys.exit(1)
    if args.mask:
        masked = value[:2] + "*" * (len(value) - 4) + value[-2:] if len(value) > 4 else "****"
        print(f"{CYAN}{args.name}{RESET} = {masked}")
    else:
        print(f"{CYAN}{args.name}{RESET} = {value}")


def cmd_inject(args):
    mgr = _get_manager()
    template = args.template
    if args.file:
        with open(args.file) as f:
            template = f.read()
    result = mgr.inject_secrets(args.scope, args.scope_id, template)
    if args.output:
        with open(args.output, "w") as f:
            f.write(result)
        print(f"{GREEN}✓ Injected secrets → {args.output}{RESET}")
    else:
        print(result)


def cmd_info(args):
    mgr = _get_manager()
    ws_row = mgr.db.conn.execute("SELECT id FROM workspaces WHERE name=?", (args.name,)).fetchone()
    if not ws_row:
        print(f"{RED}✗ Workspace not found{RESET}")
        sys.exit(1)
    summary = mgr.workspace_summary(ws_row["id"])
    ws = summary["workspace"]
    print(f"\n{ws['icon']} {BOLD}{ws['name']}{RESET}  {DIM}{ws['description']}{RESET}")
    print(f"  {DIM}Owner:{RESET}       {ws['owner'] or 'unset'}")
    print(f"  {DIM}Created:{RESET}     {ws['created_at'][:10]}")
    print(f"  {DIM}Projects:{RESET}    {summary['projects']}")
    print(f"  {DIM}Environments:{RESET} {summary['environments']}")
    print(f"  {DIM}Configs:{RESET}     {summary['configs']}")
    print(f"  {DIM}Secrets:{RESET}     {summary['secrets']}")
    if summary["project_list"]:
        print(f"\n  {BOLD}Projects:{RESET}")
        for p in summary["project_list"]:
            lang = f" {DIM}[{p['language']}]{RESET}" if p["language"] else ""
            print(f"    {CYAN}• {p['name']}{RESET}{lang}  {p['path']}")
    if summary["env_list"]:
        print(f"\n  {BOLD}Environments:{RESET}")
        for e in summary["env_list"]:
            print(f"    {GREEN}• {e['name']:<15}{RESET}  {e['env_type']}")


def main():
    _banner()
    parser = argparse.ArgumentParser(prog="workspace", description="BlackRoad Workspace Manager")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("create", help="Create a new workspace")
    p.add_argument("name")
    p.add_argument("--description", "-d", default="")
    p.add_argument("--owner", default="")
    p.add_argument("--color", default="#00BFFF")
    p.add_argument("--icon", default="📁")
    p.add_argument("--tags", default="")

    p = sub.add_parser("switch", help="Switch active workspace")
    p.add_argument("name")

    sub.add_parser("list", help="List all workspaces")

    p = sub.add_parser("add-project", help="Add a project to workspace")
    p.add_argument("workspace")
    p.add_argument("name")
    p.add_argument("--path", default=".")
    p.add_argument("--language", default="")
    p.add_argument("--framework", default="")
    p.add_argument("--repo", default="")

    p = sub.add_parser("set-config", help="Set a configuration value")
    p.add_argument("scope", choices=["global", "workspace", "project", "environment"])
    p.add_argument("scope_id")
    p.add_argument("key")
    p.add_argument("value")
    p.add_argument("--type", default="string", choices=["string", "int", "float", "bool", "json"])
    p.add_argument("--description", default="")

    p = sub.add_parser("set-secret", help="Store a secret")
    p.add_argument("scope", choices=["global", "workspace", "project", "environment"])
    p.add_argument("scope_id")
    p.add_argument("name")
    p.add_argument("value")
    p.add_argument("--description", default="")
    p.add_argument("--rotation", type=int, default=90)

    p = sub.add_parser("get-secret", help="Retrieve a secret")
    p.add_argument("scope")
    p.add_argument("scope_id")
    p.add_argument("name")
    p.add_argument("--mask", action="store_true")

    p = sub.add_parser("inject", help="Inject secrets into a template")
    p.add_argument("scope")
    p.add_argument("scope_id")
    p.add_argument("--template", default="")
    p.add_argument("--file", default=None)
    p.add_argument("--output", default=None)

    p = sub.add_parser("info", help="Show workspace details")
    p.add_argument("name")

    args = parser.parse_args()
    cmds = {
        "create": cmd_create, "switch": cmd_switch, "list": cmd_list,
        "add-project": cmd_add_project, "set-config": cmd_set_config,
        "set-secret": cmd_set_secret, "get-secret": cmd_get_secret,
        "inject": cmd_inject, "info": cmd_info,
    }
    cmds[args.command](args)


if __name__ == "__main__":
    main()

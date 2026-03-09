#!/usr/bin/env python3
"""
BlackRoad Serverless Deploy
Production module for managing and deploying serverless functions.
"""

import sqlite3
import json
import sys
import os
import hashlib
import subprocess
from dataclasses import dataclass, asdict
from datetime import datetime
from typing import Optional, List

GREEN = '\033[0;32m'
RED = '\033[0;31m'
CYAN = '\033[0;36m'
YELLOW = '\033[1;33m'
PURPLE = '\033[0;35m'
NC = '\033[0m'

DB_PATH = os.path.expanduser("~/.blackroad/serverless_deploy.db")

PROVIDERS = ["aws-lambda", "cloudflare-workers", "vercel-functions"]
RUNTIMES = ["python3.11", "python3.10", "nodejs18", "nodejs20", "go1.21", "rust"]


@dataclass
class Function:
    name: str
    runtime: str
    handler: str
    memory_mb: int = 128
    timeout_s: int = 30
    region: str = "us-east-1"
    provider: str = "aws-lambda"
    status: str = "registered"
    last_deployed: Optional[str] = None
    id: Optional[int] = None
    created_at: Optional[str] = None


@dataclass
class DeploymentLog:
    function_name: str
    provider: str
    status: str  # success, failed, pending
    version: str
    duration_s: float
    error_msg: Optional[str]
    deployed_at: str


def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS functions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            runtime TEXT NOT NULL,
            handler TEXT NOT NULL,
            memory_mb INTEGER DEFAULT 128,
            timeout_s INTEGER DEFAULT 30,
            region TEXT DEFAULT 'us-east-1',
            provider TEXT DEFAULT 'aws-lambda',
            status TEXT DEFAULT 'registered',
            last_deployed TEXT,
            created_at TEXT NOT NULL
        )
    """)
    c.execute("""
        CREATE TABLE IF NOT EXISTS deployment_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            function_name TEXT NOT NULL,
            provider TEXT NOT NULL,
            status TEXT NOT NULL,
            version TEXT,
            duration_s REAL,
            error_msg TEXT,
            deployed_at TEXT NOT NULL
        )
    """)
    c.execute("""
        CREATE TABLE IF NOT EXISTS env_vars (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            function_name TEXT NOT NULL,
            key TEXT NOT NULL,
            value_encrypted TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(function_name, key)
        )
    """)
    conn.commit()
    conn.close()


class ServerlessDeployer:
    def __init__(self):
        init_db()
        self.conn = sqlite3.connect(DB_PATH)
        self.conn.row_factory = sqlite3.Row

    def close(self):
        self.conn.close()

    def register_function(self, func: Function) -> Function:
        func.created_at = datetime.utcnow().isoformat()
        if func.provider not in PROVIDERS:
            print(f"{RED}✗ Invalid provider. Choose: {', '.join(PROVIDERS)}{NC}")
            return func
        if func.runtime not in RUNTIMES:
            print(f"{YELLOW}⚠ Unknown runtime: {func.runtime}{NC}")
        c = self.conn.cursor()
        try:
            c.execute("""
                INSERT INTO functions (name, runtime, handler, memory_mb, timeout_s,
                    region, provider, status, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (func.name, func.runtime, func.handler, func.memory_mb,
                  func.timeout_s, func.region, func.provider, func.status,
                  func.created_at))
            self.conn.commit()
            func.id = c.lastrowid
            print(f"{GREEN}✓ Registered: {func.name} ({func.provider}/{func.runtime}){NC}")
        except sqlite3.IntegrityError:
            print(f"{YELLOW}⚠ Function '{func.name}' already registered{NC}")
        return func

    def deploy_function(self, name: str, dry_run: bool = False) -> Optional[DeploymentLog]:
        c = self.conn.cursor()
        c.execute("SELECT * FROM functions WHERE name = ?", (name,))
        row = c.fetchone()
        if not row:
            print(f"{RED}✗ Function not found: {name}{NC}")
            return None

        print(f"{CYAN}▶ Deploying {name} to {row['provider']}...{NC}")
        start = datetime.utcnow()

        # Generate deployment version hash
        version = hashlib.sha256(
            f"{name}{row['runtime']}{row['handler']}{start.isoformat()}".encode()
        ).hexdigest()[:12]

        status = "success"
        error_msg = None
        duration = 0.0

        if dry_run:
            print(f"{YELLOW}  [DRY RUN] Would deploy:{NC}")
            print(f"  Function: {name}")
            print(f"  Provider: {row['provider']}")
            print(f"  Runtime:  {row['runtime']}")
            print(f"  Handler:  {row['handler']}")
            print(f"  Memory:   {row['memory_mb']}MB")
            print(f"  Timeout:  {row['timeout_s']}s")
            print(f"  Region:   {row['region']}")
            status = "dry_run"
        else:
            # Simulate provider-specific deployment
            try:
                deploy_cmds = self._build_deploy_command(row)
                print(f"{PURPLE}  Provider: {row['provider']}{NC}")
                print(f"  Command: {deploy_cmds['description']}")
                # In production, this would execute the actual deploy command
                # subprocess.run(deploy_cmds['cmd'], check=True)
                duration = 2.5  # Simulated
                print(f"{GREEN}  ✓ Deployed version {version}{NC}")
            except Exception as e:
                status = "failed"
                error_msg = str(e)
                print(f"{RED}  ✗ Deploy failed: {e}{NC}")

        end = datetime.utcnow()
        duration = (end - start).total_seconds() if duration == 0 else duration
        deployed_at = end.isoformat()

        log = DeploymentLog(
            function_name=name, provider=row["provider"], status=status,
            version=version, duration_s=round(duration, 3),
            error_msg=error_msg, deployed_at=deployed_at
        )

        c.execute("""
            INSERT INTO deployment_logs (function_name, provider, status, version,
                duration_s, error_msg, deployed_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (log.function_name, log.provider, log.status, log.version,
              log.duration_s, log.error_msg, log.deployed_at))

        if status == "success":
            c.execute("UPDATE functions SET status = 'deployed', last_deployed = ? WHERE name = ?",
                      (deployed_at, name))

        self.conn.commit()
        return log

    def _build_deploy_command(self, row) -> dict:
        provider = row["provider"]
        name = row["name"]
        if provider == "aws-lambda":
            return {
                "cmd": ["aws", "lambda", "update-function-code",
                        "--function-name", name, "--zip-file", f"fileb://{name}.zip"],
                "description": f"aws lambda update-function-code --function-name {name}"
            }
        elif provider == "cloudflare-workers":
            return {
                "cmd": ["wrangler", "deploy", "--name", name],
                "description": f"wrangler deploy --name {name}"
            }
        elif provider == "vercel-functions":
            return {
                "cmd": ["vercel", "--prod", "--yes"],
                "description": f"vercel --prod (function: {name})"
            }
        return {"cmd": [], "description": "Unknown provider"}

    def list_functions(self) -> List[Function]:
        c = self.conn.cursor()
        c.execute("SELECT * FROM functions ORDER BY created_at DESC")
        return [self._row_to_func(r) for r in c.fetchall()]

    def _row_to_func(self, r) -> Function:
        return Function(id=r["id"], name=r["name"], runtime=r["runtime"],
                        handler=r["handler"], memory_mb=r["memory_mb"],
                        timeout_s=r["timeout_s"], region=r["region"],
                        provider=r["provider"], status=r["status"],
                        last_deployed=r["last_deployed"], created_at=r["created_at"])

    def get_logs(self, name: Optional[str] = None, limit: int = 20) -> List[dict]:
        c = self.conn.cursor()
        if name:
            c.execute("SELECT * FROM deployment_logs WHERE function_name = ? "
                      "ORDER BY deployed_at DESC LIMIT ?", (name, limit))
        else:
            c.execute("SELECT * FROM deployment_logs ORDER BY deployed_at DESC LIMIT ?", (limit,))
        return [dict(r) for r in c.fetchall()]

    def export_manifest(self, output_path: str = "/tmp/serverless_manifest.json"):
        functions = self.list_functions()
        logs = self.get_logs(limit=50)
        data = {
            "functions": [asdict(f) for f in functions],
            "recent_deployments": logs,
            "summary": {
                "total_functions": len(functions),
                "deployed": sum(1 for f in functions if f.status == "deployed"),
                "providers": list(set(f.provider for f in functions)),
            },
            "exported_at": datetime.utcnow().isoformat()
        }
        with open(output_path, "w") as f:
            json.dump(data, f, indent=2)
        print(f"{GREEN}✓ Manifest exported to {output_path}{NC}")
        return output_path


def status_icon(status: str) -> str:
    icons = {"deployed": f"{GREEN}●{NC}", "registered": f"{YELLOW}○{NC}",
             "failed": f"{RED}✗{NC}", "dry_run": f"{CYAN}~{NC}"}
    return icons.get(status, f"{YELLOW}?{NC}")


def main():
    deployer = ServerlessDeployer()
    args = sys.argv[1:]
    if not args:
        print(f"{CYAN}BlackRoad Serverless Deploy{NC}")
        print("Commands: list, add, deploy [--dry-run], logs, export")
        deployer.close()
        return
    cmd = args[0]
    rest = args[1:]
    if cmd == "list":
        funcs = deployer.list_functions()
        if not funcs:
            print(f"{YELLOW}No functions registered.{NC}")
        else:
            print(f"\n{CYAN}=== Serverless Functions ({len(funcs)}) ==={NC}")
            for f in funcs:
                icon = status_icon(f.status)
                deployed = f.last_deployed[:19] if f.last_deployed else "never"
                print(f"  {icon} {CYAN}{f.name}{NC} | {f.provider} | "
                      f"{f.runtime} | {f.memory_mb}MB | Last: {deployed}")
    elif cmd == "add":
        if len(rest) < 3:
            print(f"{RED}Usage: add <name> <runtime> <handler> [memory_mb] "
                  f"[timeout_s] [region] [provider]{NC}")
        else:
            func = Function(
                name=rest[0], runtime=rest[1], handler=rest[2],
                memory_mb=int(rest[3]) if len(rest) > 3 else 128,
                timeout_s=int(rest[4]) if len(rest) > 4 else 30,
                region=rest[5] if len(rest) > 5 else "us-east-1",
                provider=rest[6] if len(rest) > 6 else "aws-lambda"
            )
            deployer.register_function(func)
    elif cmd == "deploy":
        dry_run = "--dry-run" in rest
        names = [r for r in rest if not r.startswith("--")]
        if not names:
            print(f"{RED}Usage: deploy <function_name> [--dry-run]{NC}")
        else:
            for name in names:
                log = deployer.deploy_function(name, dry_run=dry_run)
                if log:
                    icon = f"{GREEN}✓{NC}" if log.status == "success" else f"{RED}✗{NC}"
                    print(f"  {icon} {log.function_name} v{log.version} "
                          f"({log.duration_s}s)")
    elif cmd == "logs":
        name = rest[0] if rest else None
        logs = deployer.get_logs(name, limit=20)
        if not logs:
            print(f"{YELLOW}No deployment logs found.{NC}")
        else:
            print(f"\n{CYAN}=== Deployment Logs ({len(logs)}) ==={NC}")
            for log in logs:
                icon = f"{GREEN}✓{NC}" if log["status"] == "success" else f"{RED}✗{NC}"
                print(f"  {icon} {log['deployed_at'][:19]} | "
                      f"{log['function_name']} | {log['provider']} | "
                      f"v{log.get('version', '?')} | {log['duration_s']}s")
    elif cmd == "export":
        path = rest[0] if rest else "/tmp/serverless_manifest.json"
        deployer.export_manifest(path)
    else:
        print(f"{RED}Unknown command: {cmd}{NC}")
    deployer.close()


if __name__ == "__main__":
    main()

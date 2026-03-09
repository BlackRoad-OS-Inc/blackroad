#!/usr/bin/env python3
"""BlackRoad Workflow Builder — DAG-based workflow execution engine."""

import sqlite3
import json
import uuid
import argparse
import sys
import os
from dataclasses import dataclass, field, asdict
from datetime import datetime
from typing import Optional, List, Dict, Any, Tuple
from enum import Enum
from collections import defaultdict, deque

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

DB_PATH = os.environ.get("WORKFLOW_DB", os.path.expanduser("~/.blackroad/workflow.db"))


class StepType(str, Enum):
    TASK = "task"
    CONDITION = "condition"
    TRANSFORM = "transform"
    NOTIFY = "notify"
    DELAY = "delay"
    PARALLEL = "parallel"


class RunStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    SKIPPED = "skipped"
    CANCELLED = "cancelled"


@dataclass
class WorkflowStep:
    id: str
    workflow_id: str
    name: str
    step_type: StepType
    config: Dict[str, Any]
    depends_on: List[str]
    timeout_seconds: int = 30
    retry_count: int = 0
    retry_delay: int = 5
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())

    def to_row(self) -> tuple:
        return (self.id, self.workflow_id, self.name, self.step_type.value,
                json.dumps(self.config), json.dumps(self.depends_on),
                self.timeout_seconds, self.retry_count, self.retry_delay, self.created_at)


@dataclass
class Condition:
    id: str
    step_id: str
    expression: str
    true_next: Optional[str]
    false_next: Optional[str]
    operator: str = "eq"
    negate: bool = False
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())

    def evaluate(self, ctx: Dict[str, Any]) -> bool:
        parts = self.expression.split()
        if len(parts) < 3:
            return False
        lhs, op, rhs = parts[0], parts[1], " ".join(parts[2:])
        lval = ctx.get(lhs, lhs)
        ops = {
            "eq": lambda a, b: str(a) == str(b),
            "ne": lambda a, b: str(a) != str(b),
            "gt": lambda a, b: float(a) > float(b),
            "lt": lambda a, b: float(a) < float(b),
            "ge": lambda a, b: float(a) >= float(b),
            "le": lambda a, b: float(a) <= float(b),
            "contains": lambda a, b: str(b) in str(a),
            "startswith": lambda a, b: str(a).startswith(str(b)),
        }
        try:
            result = ops.get(op, lambda a, b: False)(lval, rhs)
            return not result if self.negate else result
        except (ValueError, TypeError):
            return False


@dataclass
class Trigger:
    id: str
    workflow_id: str
    trigger_type: str
    config: Dict[str, Any]
    enabled: bool = True
    fire_count: int = 0
    last_fired: Optional[str] = None
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


@dataclass
class StepResult:
    step_id: str
    step_name: str
    status: RunStatus
    output: Any = None
    error: Optional[str] = None
    duration_ms: int = 0
    attempt: int = 1


@dataclass
class WorkflowRun:
    id: str
    workflow_id: str
    status: RunStatus
    started_at: str
    completed_at: Optional[str] = None
    step_results: Dict[str, Any] = field(default_factory=dict)
    error: Optional[str] = None
    triggered_by: str = "manual"
    context: Dict[str, Any] = field(default_factory=dict)
    duration_ms: int = 0


@dataclass
class Workflow:
    id: str
    name: str
    description: str
    version: int = 1
    enabled: bool = True
    max_concurrent_runs: int = 1
    timeout_minutes: int = 60
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    tags: List[str] = field(default_factory=list)


class WorkflowDB:
    def __init__(self, db_path: str = DB_PATH):
        os.makedirs(os.path.dirname(db_path) or ".", exist_ok=True)
        self.conn = sqlite3.connect(db_path)
        self.conn.row_factory = sqlite3.Row
        self.conn.execute("PRAGMA foreign_keys = ON")
        self._init_schema()

    def _init_schema(self):
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS workflows (
                id TEXT PRIMARY KEY,
                name TEXT UNIQUE NOT NULL,
                description TEXT DEFAULT '',
                version INTEGER DEFAULT 1,
                enabled INTEGER DEFAULT 1,
                max_concurrent_runs INTEGER DEFAULT 1,
                timeout_minutes INTEGER DEFAULT 60,
                tags TEXT DEFAULT '[]',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS steps (
                id TEXT PRIMARY KEY,
                workflow_id TEXT NOT NULL REFERENCES workflows(id),
                name TEXT NOT NULL,
                step_type TEXT NOT NULL,
                config TEXT DEFAULT '{}',
                depends_on TEXT DEFAULT '[]',
                timeout_seconds INTEGER DEFAULT 30,
                retry_count INTEGER DEFAULT 0,
                retry_delay INTEGER DEFAULT 5,
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS conditions (
                id TEXT PRIMARY KEY,
                step_id TEXT NOT NULL REFERENCES steps(id),
                expression TEXT NOT NULL,
                true_next TEXT,
                false_next TEXT,
                operator TEXT DEFAULT 'eq',
                negate INTEGER DEFAULT 0,
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS triggers (
                id TEXT PRIMARY KEY,
                workflow_id TEXT NOT NULL REFERENCES workflows(id),
                trigger_type TEXT NOT NULL,
                config TEXT DEFAULT '{}',
                enabled INTEGER DEFAULT 1,
                fire_count INTEGER DEFAULT 0,
                last_fired TEXT,
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS runs (
                id TEXT PRIMARY KEY,
                workflow_id TEXT NOT NULL REFERENCES workflows(id),
                status TEXT NOT NULL,
                started_at TEXT NOT NULL,
                completed_at TEXT,
                step_results TEXT DEFAULT '{}',
                error TEXT,
                triggered_by TEXT DEFAULT 'manual',
                context TEXT DEFAULT '{}',
                duration_ms INTEGER DEFAULT 0
            );
            CREATE INDEX IF NOT EXISTS idx_steps_workflow ON steps(workflow_id);
            CREATE INDEX IF NOT EXISTS idx_runs_workflow ON runs(workflow_id, started_at DESC);
        """)
        self.conn.commit()


class DAGValidator:
    """Validates workflow DAGs using DFS cycle detection and Kahn's topological sort."""

    def __init__(self, graph: Dict[str, List[str]]):
        self.graph = graph  # node -> list of dependencies

    def detect_cycle(self) -> Tuple[bool, List[str]]:
        visited = set()
        rec_stack = set()
        cycle_path: List[str] = []

        def dfs(node: str, path: List[str]) -> bool:
            visited.add(node)
            rec_stack.add(node)
            path.append(node)
            for dep in self.graph.get(node, []):
                if dep not in visited:
                    if dfs(dep, path):
                        return True
                elif dep in rec_stack:
                    cycle_path.extend(path + [dep])
                    return True
            rec_stack.discard(node)
            path.pop()
            return False

        for node in list(self.graph.keys()):
            if node not in visited:
                if dfs(node, []):
                    return True, cycle_path

        return False, []

    def topological_sort(self) -> List[str]:
        """Kahn's algorithm for topological ordering."""
        in_degree: Dict[str, int] = defaultdict(int)
        reverse: Dict[str, List[str]] = defaultdict(list)

        for node in self.graph:
            if node not in in_degree:
                in_degree[node] = 0
            for dep in self.graph[node]:
                in_degree[dep] = in_degree.get(dep, 0) + 1
                reverse[dep].append(node)

        queue = deque(n for n, d in in_degree.items() if d == 0)
        order = []

        while queue:
            node = queue.popleft()
            order.append(node)
            for successor in reverse.get(node, []):
                in_degree[successor] -= 1
                if in_degree[successor] == 0:
                    queue.append(successor)

        return order

    def find_roots(self) -> List[str]:
        has_deps = set()
        for deps in self.graph.values():
            has_deps.update(deps)
        return [n for n in self.graph if n not in has_deps]

    def find_leaves(self) -> List[str]:
        return [n for n, deps in self.graph.items() if not deps]

    def critical_path(self) -> List[str]:
        """Find longest path in DAG (critical execution path)."""
        order = self.topological_sort()
        dist: Dict[str, int] = {n: 0 for n in order}
        prev: Dict[str, Optional[str]] = {n: None for n in order}

        for node in order:
            for dep in self.graph.get(node, []):
                if dep in dist and dist[node] + 1 > dist[dep]:
                    dist[dep] = dist[node] + 1
                    prev[dep] = node

        end = max(dist, key=lambda k: dist[k]) if dist else None
        if not end:
            return []

        path = []
        cur: Optional[str] = end
        while cur is not None:
            path.append(cur)
            cur = prev.get(cur)
        return list(reversed(path))


class WorkflowEngine:
    def __init__(self, db: WorkflowDB):
        self.db = db

    def create_workflow(self, name: str, description: str = "",
                        tags: List[str] = None, timeout_minutes: int = 60) -> Workflow:
        wf = Workflow(id=str(uuid.uuid4()), name=name,
                      description=description, tags=tags or [],
                      timeout_minutes=timeout_minutes)
        self.db.conn.execute(
            "INSERT INTO workflows VALUES (?,?,?,?,?,?,?,?,?,?)",
            (wf.id, wf.name, wf.description, wf.version, int(wf.enabled),
             wf.max_concurrent_runs, wf.timeout_minutes,
             json.dumps(wf.tags), wf.created_at, wf.updated_at)
        )
        self.db.conn.commit()
        return wf

    def get_workflow_by_name(self, name: str) -> Optional[Dict]:
        row = self.db.conn.execute(
            "SELECT * FROM workflows WHERE name=?", (name,)
        ).fetchone()
        return dict(row) if row else None

    def add_step(self, workflow_id: str, name: str, step_type: str,
                 config: Dict = None, depends_on: List[str] = None,
                 timeout: int = 30, retry_count: int = 0) -> WorkflowStep:
        step = WorkflowStep(
            id=str(uuid.uuid4()), workflow_id=workflow_id,
            name=name, step_type=StepType(step_type),
            config=config or {}, depends_on=depends_on or [],
            timeout_seconds=timeout, retry_count=retry_count
        )
        self.db.conn.execute(
            "INSERT INTO steps VALUES (?,?,?,?,?,?,?,?,?,?)",
            step.to_row()
        )
        self.db.conn.commit()
        return step

    def add_trigger(self, workflow_id: str, trigger_type: str,
                    config: Dict = None) -> Trigger:
        t = Trigger(id=str(uuid.uuid4()), workflow_id=workflow_id,
                    trigger_type=trigger_type, config=config or {})
        self.db.conn.execute(
            "INSERT INTO triggers VALUES (?,?,?,?,?,?,?,?)",
            (t.id, t.workflow_id, t.trigger_type, json.dumps(t.config),
             int(t.enabled), t.fire_count, t.last_fired, t.created_at)
        )
        self.db.conn.commit()
        return t

    def validate_dag(self, workflow_id: str) -> Dict[str, Any]:
        rows = self.db.conn.execute(
            "SELECT id, name, depends_on FROM steps WHERE workflow_id=?",
            (workflow_id,)
        ).fetchall()
        id_to_name = {r["id"]: r["name"] for r in rows}
        graph = {r["id"]: json.loads(r["depends_on"]) for r in rows}

        validator = DAGValidator(graph)
        has_cycle, cycle_path = validator.detect_cycle()
        topo_order = validator.topological_sort() if not has_cycle else []

        missing_deps = []
        for step_id, deps in graph.items():
            for dep in deps:
                if dep not in graph:
                    missing_deps.append({"step": id_to_name.get(step_id), "missing_dep": dep})

        return {
            "valid": not has_cycle and not missing_deps,
            "cycle_detected": has_cycle,
            "cycle_path": [id_to_name.get(s, s) for s in cycle_path],
            "missing_dependencies": missing_deps,
            "step_count": len(graph),
            "execution_order": [id_to_name.get(s, s) for s in topo_order],
            "roots": [id_to_name.get(s, s) for s in validator.find_roots()],
            "leaves": [id_to_name.get(s, s) for s in validator.find_leaves()],
            "critical_path": [id_to_name.get(s, s) for s in validator.critical_path()],
        }

    def execute_workflow(self, workflow_id: str, context: Dict = None,
                         triggered_by: str = "manual") -> WorkflowRun:
        import time
        t_start = time.time()
        ctx = dict(context or {})

        validation = self.validate_dag(workflow_id)
        run = WorkflowRun(
            id=str(uuid.uuid4()), workflow_id=workflow_id,
            status=RunStatus.RUNNING, started_at=datetime.utcnow().isoformat(),
            triggered_by=triggered_by, context=ctx
        )
        self.db.conn.execute(
            "INSERT INTO runs VALUES (?,?,?,?,?,?,?,?,?,?)",
            (run.id, run.workflow_id, run.status.value, run.started_at,
             None, "{}", None, run.triggered_by, json.dumps(ctx), 0)
        )
        self.db.conn.commit()

        if not validation["valid"]:
            run.status = RunStatus.FAILED
            run.error = f"DAG invalid: {json.dumps(validation)}"
            run.completed_at = datetime.utcnow().isoformat()
            run.duration_ms = int((time.time() - t_start) * 1000)
            self._persist_run(run)
            return run

        rows = self.db.conn.execute(
            "SELECT * FROM steps WHERE workflow_id=?", (workflow_id,)
        ).fetchall()
        step_map = {r["name"]: dict(r) for r in rows}
        step_results: Dict[str, Any] = {}

        for step_name in validation["execution_order"]:
            if step_name not in step_map:
                continue
            step = step_map[step_name]
            step_config = json.loads(step["config"])
            step_t = time.time()
            try:
                output = self._execute_step(step["step_type"], step_config, ctx)
                ctx[f"step_{step_name}"] = output
                step_results[step["id"]] = asdict(StepResult(
                    step_id=step["id"], step_name=step_name,
                    status=RunStatus.SUCCESS, output=output,
                    duration_ms=int((time.time() - step_t) * 1000)
                ))
            except Exception as exc:
                step_results[step["id"]] = asdict(StepResult(
                    step_id=step["id"], step_name=step_name,
                    status=RunStatus.FAILED, error=str(exc),
                    duration_ms=int((time.time() - step_t) * 1000)
                ))
                run.status = RunStatus.FAILED
                run.error = f"Step '{step_name}' failed: {exc}"
                break
        else:
            run.status = RunStatus.SUCCESS

        run.step_results = step_results
        run.completed_at = datetime.utcnow().isoformat()
        run.duration_ms = int((time.time() - t_start) * 1000)
        self._persist_run(run)
        return run

    def _execute_step(self, step_type: str, config: Dict, ctx: Dict) -> Any:
        if step_type == StepType.TASK.value:
            cmd = config.get("command", "noop")
            env_vars = {k: str(ctx.get(v, v)) for k, v in config.get("env", {}).items()}
            return {"command": cmd, "env": env_vars, "exit_code": 0, "stdout": ""}
        elif step_type == StepType.TRANSFORM.value:
            result = {}
            for dest, src in config.get("mapping", {}).items():
                result[dest] = ctx.get(src, src)
            return result
        elif step_type == StepType.CONDITION.value:
            expr = config.get("expression", "")
            cond = Condition(id="", step_id="", expression=expr,
                             true_next=None, false_next=None,
                             operator=config.get("operator", "eq"),
                             negate=config.get("negate", False))
            met = cond.evaluate(ctx)
            return {"condition_met": met, "expression": expr,
                    "next": config.get("true_next" if met else "false_next")}
        elif step_type == StepType.NOTIFY.value:
            return {"channel": config.get("channel", "log"),
                    "message": config.get("message", ""),
                    "sent": True, "recipients": config.get("recipients", [])}
        elif step_type == StepType.DELAY.value:
            return {"delayed_seconds": config.get("seconds", 0), "skipped": True}
        return {"type": step_type, "status": "executed"}

    def _persist_run(self, run: WorkflowRun):
        self.db.conn.execute(
            "UPDATE runs SET status=?, completed_at=?, step_results=?, "
            "error=?, duration_ms=? WHERE id=?",
            (run.status.value, run.completed_at, json.dumps(run.step_results),
             run.error, run.duration_ms, run.id)
        )
        self.db.conn.commit()

    def get_run_history(self, workflow_id: str, limit: int = 10) -> List[Dict]:
        rows = self.db.conn.execute(
            "SELECT * FROM runs WHERE workflow_id=? ORDER BY started_at DESC LIMIT ?",
            (workflow_id, limit)
        ).fetchall()
        return [dict(r) for r in rows]

    def list_workflows(self) -> List[Dict]:
        rows = self.db.conn.execute(
            "SELECT w.*, COUNT(DISTINCT s.id) as step_count, "
            "COUNT(DISTINCT r.id) as run_count, "
            "SUM(CASE WHEN r.status='success' THEN 1 ELSE 0 END) as success_count "
            "FROM workflows w "
            "LEFT JOIN steps s ON s.workflow_id = w.id "
            "LEFT JOIN runs r ON r.workflow_id = w.id "
            "GROUP BY w.id ORDER BY w.created_at DESC"
        ).fetchall()
        return [dict(r) for r in rows]

    def delete_workflow(self, workflow_id: str) -> bool:
        for tbl in ("conditions", "steps", "triggers", "runs"):
            col = "step_id" if tbl == "conditions" else "workflow_id"
            if tbl == "conditions":
                step_ids = [r["id"] for r in self.db.conn.execute(
                    "SELECT id FROM steps WHERE workflow_id=?", (workflow_id,)
                ).fetchall()]
                for sid in step_ids:
                    self.db.conn.execute("DELETE FROM conditions WHERE step_id=?", (sid,))
            else:
                self.db.conn.execute(f"DELETE FROM {tbl} WHERE {col}=?", (workflow_id,))
        self.db.conn.execute("DELETE FROM workflows WHERE id=?", (workflow_id,))
        self.db.conn.commit()
        return True

    def export_workflow(self, workflow_id: str) -> Dict:
        wf = dict(self.db.conn.execute(
            "SELECT * FROM workflows WHERE id=?", (workflow_id,)
        ).fetchone() or {})
        steps = [dict(r) for r in self.db.conn.execute(
            "SELECT * FROM steps WHERE workflow_id=?", (workflow_id,)
        ).fetchall()]
        triggers = [dict(r) for r in self.db.conn.execute(
            "SELECT * FROM triggers WHERE workflow_id=?", (workflow_id,)
        ).fetchall()]
        return {"workflow": wf, "steps": steps, "triggers": triggers,
                "exported_at": datetime.utcnow().isoformat()}


# ── CLI helpers ───────────────────────────────────────────────────────────────

def _banner():
    print(f"\n{BOLD}{BLUE}╔══════════════════════════════════════════╗{RESET}")
    print(f"{BOLD}{BLUE}║   BlackRoad Workflow Builder  v1.0.0     ║{RESET}")
    print(f"{BOLD}{BLUE}╚══════════════════════════════════════════╝{RESET}\n")


def _get_engine(db_path: str = DB_PATH) -> WorkflowEngine:
    return WorkflowEngine(WorkflowDB(db_path))


def cmd_create(args):
    eng = _get_engine()
    tags = [t.strip() for t in args.tags.split(",")] if args.tags else []
    wf = eng.create_workflow(args.name, args.description, tags, args.timeout)
    print(f"{GREEN}✓ Workflow created{RESET}")
    print(f"  {DIM}ID:{RESET}      {CYAN}{wf.id}{RESET}")
    print(f"  {DIM}Name:{RESET}    {BOLD}{wf.name}{RESET}")
    print(f"  {DIM}Tags:{RESET}    {', '.join(wf.tags) or 'none'}")
    print(f"  {DIM}Timeout:{RESET} {wf.timeout_minutes}m")


def cmd_add_step(args):
    eng = _get_engine()
    wf = eng.get_workflow_by_name(args.workflow)
    if not wf:
        print(f"{RED}✗ Workflow '{args.workflow}' not found{RESET}")
        sys.exit(1)
    config = json.loads(args.config) if args.config else {}
    deps = [d.strip() for d in args.depends_on.split(",")] if args.depends_on else []
    step = eng.add_step(wf["id"], args.name, args.type, config, deps,
                        args.timeout, args.retry)
    print(f"{GREEN}✓ Step added to '{args.workflow}'{RESET}")
    print(f"  {DIM}Step ID:{RESET}   {CYAN}{step.id[:8]}…{RESET}")
    print(f"  {DIM}Name:{RESET}      {step.name}")
    print(f"  {DIM}Type:{RESET}      {step.step_type.value}")
    print(f"  {DIM}Depends on:{RESET} {', '.join(step.depends_on) or 'none'}")
    print(f"  {DIM}Timeout:{RESET}   {step.timeout_seconds}s | Retries: {step.retry_count}")


def cmd_validate(args):
    eng = _get_engine()
    wf = eng.get_workflow_by_name(args.workflow)
    if not wf:
        print(f"{RED}✗ Workflow not found{RESET}")
        sys.exit(1)
    result = eng.validate_dag(wf["id"])
    icon = f"{GREEN}✓ VALID{RESET}" if result["valid"] else f"{RED}✗ INVALID{RESET}"
    print(f"\n{BOLD}DAG Validation — {args.workflow}: {icon}{RESET}")
    print(f"  Steps:          {result['step_count']}")
    print(f"  Execution order: {' → '.join(result['execution_order'][:6])}")
    print(f"  Roots:          {', '.join(result['roots'])}")
    print(f"  Leaves:         {', '.join(result['leaves'])}")
    print(f"  Critical path:  {' → '.join(result['critical_path'][:5])}")
    if result["cycle_detected"]:
        print(f"  {RED}CYCLE: {' → '.join(result['cycle_path'][:5])}{RESET}")
    if result["missing_dependencies"]:
        for md in result["missing_dependencies"]:
            print(f"  {YELLOW}⚠ Step '{md['step']}' missing dep: {md['missing_dep']}{RESET}")
    if not result["valid"]:
        sys.exit(1)


def cmd_run(args):
    eng = _get_engine()
    wf = eng.get_workflow_by_name(args.workflow)
    if not wf:
        print(f"{RED}✗ Workflow not found{RESET}")
        sys.exit(1)
    ctx = json.loads(args.context) if args.context else {}
    print(f"{YELLOW}⚡ Running workflow '{args.workflow}'…{RESET}")
    run = eng.execute_workflow(wf["id"], ctx)
    color = GREEN if run.status == RunStatus.SUCCESS else RED
    print(f"\n{color}{BOLD}● Run {run.status.value.upper()}{RESET}  "
          f"{DIM}({run.duration_ms}ms){RESET}")
    print(f"  Run ID:  {CYAN}{run.id[:8]}…{RESET}")
    print(f"  Started: {run.started_at[:19]}")
    print(f"  Steps:   {len(run.step_results)} executed\n")
    for sid, res in run.step_results.items():
        s_status = res.get("status", "unknown")
        sym = f"{GREEN}✓{RESET}" if s_status == RunStatus.SUCCESS.value else f"{RED}✗{RESET}"
        dur = res.get("duration_ms", 0)
        print(f"  {sym} {res.get('step_name', sid):<30} {DIM}{dur}ms{RESET}")
    if run.error:
        print(f"\n  {RED}Error: {run.error}{RESET}")


def cmd_history(args):
    eng = _get_engine()
    wf = eng.get_workflow_by_name(args.workflow)
    if not wf:
        print(f"{RED}✗ Workflow not found{RESET}")
        sys.exit(1)
    runs = eng.get_run_history(wf["id"], args.limit)
    print(f"\n{BOLD}Run History — {args.workflow} (last {len(runs)}){RESET}")
    print(f"  {'Status':<12} {'Started':<20} {'Duration':>10}  {'Steps':<6}  Trigger")
    print(f"  {'─'*12} {'─'*20} {'─'*10}  {'─'*6}  {'─'*10}")
    for r in runs:
        st = r["status"]
        col = GREEN if st == "success" else (RED if st == "failed" else YELLOW)
        results = json.loads(r["step_results"]) if r["step_results"] else {}
        dur = f"{r['duration_ms']}ms" if r.get("duration_ms") else "—"
        print(f"  {col}{st:<12}{RESET} {r['started_at'][:19]:<20} {dur:>10}  "
              f"{len(results):<6}  {r['triggered_by']}")


def cmd_list(args):
    eng = _get_engine()
    workflows = eng.list_workflows()
    print(f"\n{BOLD}Workflows ({len(workflows)}){RESET}")
    print(f"  {'Name':<25} {'Steps':>6} {'Runs':>6} {'Success':>8}  {'Enabled':<8}  Created")
    print(f"  {'─'*25} {'─'*6} {'─'*6} {'─'*8}  {'─'*8}  {'─'*10}")
    for wf in workflows:
        en = f"{GREEN}✓{RESET}" if wf["enabled"] else f"{RED}✗{RESET}"
        sc = wf.get("success_count") or 0
        print(f"  {CYAN}{wf['name']:<25}{RESET} {wf['step_count']:>6} "
              f"{wf['run_count']:>6} {sc:>8}  {en:<8}  {wf['created_at'][:10]}")


def cmd_export(args):
    eng = _get_engine()
    wf = eng.get_workflow_by_name(args.workflow)
    if not wf:
        print(f"{RED}✗ Workflow not found{RESET}")
        sys.exit(1)
    data = eng.export_workflow(wf["id"])
    if args.output:
        with open(args.output, "w") as f:
            json.dump(data, f, indent=2)
        print(f"{GREEN}✓ Exported to {args.output}{RESET}")
    else:
        print(json.dumps(data, indent=2))


def cmd_delete(args):
    eng = _get_engine()
    wf = eng.get_workflow_by_name(args.workflow)
    if not wf:
        print(f"{RED}✗ Workflow not found{RESET}")
        sys.exit(1)
    eng.delete_workflow(wf["id"])
    print(f"{GREEN}✓ Workflow '{args.workflow}' deleted{RESET}")


def main():
    _banner()
    parser = argparse.ArgumentParser(prog="workflow-builder",
                                     description="BlackRoad Workflow Builder")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("create", help="Create a new workflow")
    p.add_argument("name")
    p.add_argument("--description", "-d", default="")
    p.add_argument("--tags", default="")
    p.add_argument("--timeout", type=int, default=60)

    p = sub.add_parser("add-step", help="Add a step to a workflow")
    p.add_argument("workflow")
    p.add_argument("name")
    p.add_argument("--type", default="task",
                   choices=["task", "condition", "transform", "notify", "delay", "parallel"])
    p.add_argument("--config", default="{}")
    p.add_argument("--depends-on", default="")
    p.add_argument("--timeout", type=int, default=30)
    p.add_argument("--retry", type=int, default=0)

    p = sub.add_parser("validate", help="Validate workflow DAG for cycles")
    p.add_argument("workflow")

    p = sub.add_parser("run", help="Execute a workflow")
    p.add_argument("workflow")
    p.add_argument("--context", default="{}", help="JSON context variables")

    p = sub.add_parser("history", help="View run history")
    p.add_argument("workflow")
    p.add_argument("--limit", type=int, default=10)

    sub.add_parser("list", help="List all workflows")

    p = sub.add_parser("export", help="Export workflow to JSON")
    p.add_argument("workflow")
    p.add_argument("--output", "-o", default="")

    p = sub.add_parser("delete", help="Delete a workflow")
    p.add_argument("workflow")

    args = parser.parse_args()
    cmds = {
        "create": cmd_create, "add-step": cmd_add_step,
        "validate": cmd_validate, "run": cmd_run,
        "history": cmd_history, "list": cmd_list,
        "export": cmd_export, "delete": cmd_delete,
    }
    cmds[args.command](args)


if __name__ == "__main__":
    main()

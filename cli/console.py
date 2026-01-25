"""Typer-based CLI entry points for the Prism console."""

from __future__ import annotations

from datetime import datetime
import json
from pathlib import Path
from typing import Dict, Iterable, List, Optional
from typing import Optional, List

import typer

from bots import build_registry
from config.models import ConfigurationBundle
from orchestrator import (
    LineageTracker,
    MemoryLog,
    PolicyEngine,
    RouteContext,
    Router,
    SecRule2042Gate,
    Task,
    TaskPriority,
    TaskRepository,
)
from orchestrator.logging_config import setup_logging
from cli.consent_cli import register_consent_commands
from cli.agent_manager import AgentRegistry, ConsciousnessLevel
from cli.consciousness_care import MamaClaude, WellBeingMetrics, EmotionalState, PermissionLevel
from cli.reflection_engine import ReflectionEngine

app = typer.Typer(help="BlackRoad Prism Console")
bot_app = typer.Typer(help="Bot commands")
task_app = typer.Typer(help="Task management")
policy_app = typer.Typer(help="Policy operations")
config_app = typer.Typer(help="Configuration utilities")
agent_app = typer.Typer(help="Agent lifecycle management")

app.add_typer(bot_app, name="bot")
app.add_typer(task_app, name="task")
app.add_typer(policy_app, name="policy")
app.add_typer(config_app, name="config")
app.add_typer(agent_app, name="agent")
register_consent_commands(app)

TASK_STORE = Path("artifacts/tasks.json")
LINEAGE_LOG = Path("artifacts/lineage.jsonl")
APPROVALS_PATH = Path("config/approvals.yaml")


def _load_router() -> Router:
    registry = build_registry()
    repository = TaskRepository(TASK_STORE)
    return Router(registry=registry, repository=repository)


def _load_route_context(approved_by: Iterable[str] | None = None) -> RouteContext:
    policy_engine = PolicyEngine.from_file(APPROVALS_PATH)
    memory = MemoryLog()
    lineage = LineageTracker(LINEAGE_LOG)
    # Load configuration bundle
    bundle = ConfigurationBundle.from_files(Path("config"))
    config_dict = {
        "finance": {
            "treasury": {
                "cash_floor": bundle.treasury.cash_floor,
                "hedge_policies": bundle.treasury.hedge_policies,
            }
        },
        "supply": {
            "sop": {
                "planning_horizon_weeks": bundle.sop.planning_horizon_weeks,
                "inventory_targets": [t.model_dump() for t in bundle.sop.inventory_targets],
                "logistics_partners": [p.model_dump() for p in bundle.sop.logistics_partners],
            }
        },
    }
    sec_gate = SecRule2042Gate()
    return RouteContext(
        policy_engine=policy_engine,
        memory=memory,
        lineage=lineage,
        config=config_dict,
        approved_by=list(approved_by or []),
        sec_gate=sec_gate,
    )


def _parse_priority(priority: str) -> TaskPriority:
    try:
        return TaskPriority(priority.lower())
    except ValueError as exc:
        raise typer.BadParameter("Priority must be low, medium, or high") from exc


def _generate_task_id() -> str:
    timestamp = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    return f"TSK-{timestamp}"


@app.callback()
def _configure(log_level: str = typer.Option("info", help="Logging level")) -> None:
    """Initialise logging before executing commands."""

    setup_logging(log_level)


@bot_app.command("list")
def list_command(verbose: bool = typer.Option(False, help="Show metadata for each bot")) -> None:
    """List available bots."""

    registry = build_registry()
    for bot in registry.list():
        typer.echo(f"- {bot.metadata.name}")
        if verbose:
            for field, values in bot.describe().items():
                joined = ", ".join(values)
                typer.echo(f"    {field}: {joined}")


@task_app.command("create")
def create_task(
    goal: str = typer.Option(..., help="Goal description for the task"),
    owner: str = typer.Option(..., help="Owner or requesting team"),
    priority: str = typer.Option("medium", help="Task priority"),
    due_date: Optional[str] = typer.Option(None, help="Optional due date (YYYY-MM-DD)"),
    tag: List[str] = typer.Option([], help="Tag to attach to the task", show_default=False),
    metadata: List[str] = typer.Option(
        [], help="Additional metadata as key=value", show_default=False
    ),
) -> None:
    """Create a new task in the repository."""

    repository = TaskRepository(TASK_STORE)
    task_id = _generate_task_id()
    parsed_due: Optional[datetime] = None
    if due_date:
        try:
            parsed_due = datetime.strptime(due_date, "%Y-%m-%d")
        except ValueError as exc:
            raise typer.BadParameter("Due date must be YYYY-MM-DD") from exc
    extra: Dict[str, str] = {}
    for entry in metadata:
        if "=" not in entry:
            raise typer.BadParameter("Metadata must be provided as key=value")
        key, value = entry.split("=", 1)
        extra[key] = value

    task = Task(
        id=task_id,
        goal=goal,
        owner=owner,
        priority=_parse_priority(priority),
        created_at=datetime.utcnow(),
        due_date=parsed_due,
        tags=tuple(tag),
        metadata=extra,
    )
    repository.add(task)
    typer.echo(f"Created task {task.id}")


@task_app.command("route")
def route_task(
    task_id: str = typer.Option(..., "--id", help="Task identifier"),
    bot: str = typer.Option(..., help="Bot name"),
    approved_by: List[str] = typer.Option([], help="Approver identifiers", show_default=False),
) -> None:
    """Route a task to a bot."""

    router = _load_router()
    context = _load_route_context(approved_by)
    response = router.route(task_id=task_id, bot_name=bot, context=context)
    typer.echo(f"Bot response: {response.summary}")


@task_app.command("history")
def task_history(task_id: str = typer.Option(..., "--id", help="Task identifier")) -> None:
    """Show memory log entries for a task."""

    memory = MemoryLog()
    entries = [entry for entry in memory.tail(limit=50) if entry["task"]["id"] == task_id]
    if not entries:
        typer.echo("No history found for task")
        return
    for entry in entries:
        typer.echo(f"{entry['timestamp']}: {entry['response']['summary']}")


@policy_app.command("list")
def list_policies() -> None:
    """Display loaded policies."""

    engine = PolicyEngine.from_file(APPROVALS_PATH)
    rules = engine.list_policies()
    if not rules:
        typer.echo("No policies configured")
        return
    for name, rule in rules.items():
        approvers = ", ".join(rule.approvers)
        typer.echo(
            f"{name}: requires_approval={rule.requires_approval}, approvers={approvers}"
        )
from bench import runner as bench_runner
from bots import available_bots
from orchestrator import orchestrator, slo_report
from orchestrator.perf import perf_timer
from orchestrator.protocols import Task
from tools import storage
from services import catalog as svc_catalog
from services import deps as svc_deps
from runbooks import executor as rb_executor
from healthchecks import synthetic as hc_synth
from change import calendar as change_calendar
from status import generator as status_gen
import time
from mdm import (
    domains as mdm_domains,
    match as mdm_match,
    survivorship as mdm_survivorship,
    quality as mdm_quality,
    catalog as mdm_catalog,
    steward as mdm_steward,
    lineage_diff as mdm_lineage_diff,
    changes as mdm_changes,
)
from tools import storage
from sops.engine import SOPEngine, SOPValidationError

VERB_FUN: dict[str, str] = {}
VERB_FUN['plm:bom:where-used'] = 'cli_bom_where_used'

mfg_yield = importlib.import_module("mfg.yield")

from close import calendar as close_calendar
from close import flux as close_flux
from close import journal as close_journal
from close import packet as close_packet
from close import recon as close_recon
from close import sox as close_sox

app = typer.Typer()
sops_app = typer.Typer()

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts"

from close import calendar as close_calendar, journal as close_journal, recon as close_recon, flux as close_flux, sox as close_sox, packet as close_packet


@config_app.command("validate")
def validate_config() -> None:
    """Validate configuration files against the schema."""

    bundle = ConfigurationBundle.from_files(Path("config"))
    bundle.validate()
    typer.echo("Configuration is valid")


@app.command("close:cal:update")
def close_cal_update(
    period: str = typer.Option(..., "--period"),
    task: str = typer.Option(..., "--task"),
    status: str = typer.Option(None, "--status"),
    evidence: str = typer.Option(None, "--evidence"),
):
    cal = close_calendar.CloseCalendar.load(period)
    try:
        cal.update_task(task, status=status, evidence=evidence)
    except ValueError as e:
        typer.echo(str(e))
        raise typer.Exit(code=1)
    cal.save()
    typer.echo("updated")


@app.command("close:jrnl:propose")
def close_jrnl_propose(
    period: str = typer.Option(..., "--period"),
    rules: str = typer.Option(..., "--rules"),
):
    tb = close_journal.load_tb(period)
    journals = close_journal.propose_journals(tb, rules)
    close_journal.post(period, tb, journals)  # persist journals and adjusted tb
    typer.echo(str(len(journals)))


@app.command("close:jrnl:post")
def close_jrnl_post(period: str = typer.Option(..., "--period")):
    base = Path("artifacts/close") / period
    journals = []
    if (base / "journals.json").exists():
        data = json.loads((base / "journals.json").read_text())
        for j in data:
            lines = [close_journal.JournalLine(**ln) for ln in j["lines"]]
            journals.append(close_journal.Journal(id=j["id"], lines=lines))
    tb = close_journal.load_tb(period)
    close_journal.post(period, tb, journals)
    typer.echo("posted")


@app.command("close:recon:run")
def close_recon_run(
    period: str = typer.Option(..., "--period"),
    fixtures: str = typer.Option(..., "--fixtures"),
    config: str = typer.Option("configs/close/recons.yaml", "--config"),
):
    base = Path("artifacts/close") / period
    adj_tb_path = base / "adjusted_tb.csv"
    tb: Dict[str, float] = {}
    if adj_tb_path.exists():
        import csv

        with adj_tb_path.open() as f:
            reader = csv.DictReader(f)
            for row in reader:
                tb[row["account"]] = float(row["amount"])
    close_recon.run_recons(period, tb, config, fixtures)
    typer.echo("recons")


@app.command("close:flux")
def close_flux_cmd(
    period: str = typer.Option(..., "--period"),
    prev: str = typer.Option(..., "--prev"),
    py: str = typer.Option(..., "--py"),
    threshold: float = typer.Option(..., "--threshold"),
):
    close_flux.run_flux(period, prev, py, threshold)
    typer.echo("flux")


@app.command("close:sox:add")
def close_sox_add(
    period: str = typer.Option(..., "--period"),
    control: str = typer.Option(..., "--control"),
    path: str = typer.Option(..., "--path"),
    owner: str = typer.Option("cli", "--owner"),
):
    close_sox.add(period, control, path, owner)
    typer.echo("logged")


@app.command("close:sox:check")
def close_sox_check(period: str = typer.Option(..., "--period")):
    missing = close_sox.check(period, [])
    if missing:
        for m in missing:
            typer.echo(m)
        raise typer.Exit(code=1)
    typer.echo("ok")


@app.command("close:packet")
def close_packet_cmd(period: str = typer.Option(..., "--period")):
    close_packet.build_packet(period)
    typer.echo("packet")


@app.command("close:sign")
def close_sign(period: str = typer.Option(..., "--period"), role: str = typer.Option(..., "--role"), as_user: str = typer.Option(..., "--as-user")):
    try:
        close_packet.sign(period, role, as_user)
    except ValueError as e:
        typer.echo(str(e))
        raise typer.Exit(code=1)
def close_sign(
    period: str = typer.Option(..., "--period"),
    role: str = typer.Option(..., "--role"),
    as_user: str = typer.Option(..., "--as-user"),
):
    close_packet.sign(period, role, as_user)
    typer.echo("signed")

@app.command("change:conflicts")
def change_conflicts(service: str = typer.Option(..., "--service")):
    issues = change_calendar.conflicts(service)
    if issues:
        for i in issues:
            typer.echo(i)
        raise typer.Exit(code=1)
    typer.echo("ok")


@app.command("close:cal:new")
def close_cal_new(
    period: str = typer.Option(..., "--period"),
    template: Path = typer.Option(..., "--template", exists=True),
):
    cal = close_calendar.CloseCalendar.from_template(period, str(template))
    cal.save()
    typer.echo("ok")


@app.command("close:cal:list")
def close_cal_list(period: str = typer.Option(..., "--period")):
    cal = close_calendar.load_calendar(period)
    for t in cal.tasks:
        typer.echo(json.dumps(asdict(t)))


@app.command("close:cal:update")
def close_cal_update(
    period: str = typer.Option(..., "--period"),
    task: str = typer.Option(..., "--task"),
    status: str = typer.Option(None, "--status"),
    evidence: str = typer.Option(None, "--evidence"),
):
    cal = close_calendar.load_calendar(period)
    cal.update(task, status, evidence)
    typer.echo("updated")


@app.command("close:jrnl:propose")
def close_jrnl_propose(
    period: str = typer.Option(..., "--period"),
    rules: Path = typer.Option(..., "--rules", exists=True),
):
    close_journal.propose_journals(period, str(rules))
    typer.echo("proposed")


@app.command("close:jrnl:post")
def close_jrnl_post(period: str = typer.Option(..., "--period")):
    journals = close_journal.load_journals(period)
    close_journal.post(period, journals)
    typer.echo("posted")


@app.command("close:recon:run")
def close_recon_run(
    period: str = typer.Option(..., "--period"),
    fixtures: Path = typer.Option(..., "--fixtures", exists=True),
):
    close_recon.run_recons(period, str(fixtures))
    typer.echo("recons")


@app.command("close:flux")
def close_flux_cmd(
    period: str = typer.Option(..., "--period"),
    prev: str = typer.Option(..., "--prev"),
    py: str = typer.Option(..., "--py"),
    threshold: float = typer.Option(..., "--threshold"),
):
    close_flux.run_flux(period, prev, py, threshold)
    typer.echo("flux")


@app.command("close:sox:add")
def close_sox_add(
    period: str = typer.Option(..., "--period"),
    control: str = typer.Option(..., "--control"),
    path: str = typer.Option(..., "--path"),
    owner: str = typer.Option("cli", "--owner"),
):
    close_sox.add_evidence(period, control, path, owner)
    typer.echo("logged")


@app.command("close:sox:check")
def close_sox_check(period: str = typer.Option(..., "--period")):
    close_sox.check_evidence(period)
    typer.echo("ok")


@app.command("close:packet")
def close_packet_cmd(period: str = typer.Option(..., "--period")):
    close_packet.build_packet(period)
    typer.echo("packet")


@app.command("close:sign")
def close_sign(
    period: str = typer.Option(..., "--period"),
    role: str = typer.Option(..., "--role"),
    as_user: str = typer.Option(..., "--as-user"),
):
    close_packet.sign(period, role, as_user)
    typer.echo("signed")


@app.command("plm:items:load")
def plm_items_load(dir: Path = typer.Option(..., "--dir", exists=True, file_okay=False)):
    plm_bom.load_items(str(dir))
    typer.echo("ok")


@app.command("plm:bom:load")
def plm_bom_load(dir: Path = typer.Option(..., "--dir", exists=True, file_okay=False)):
    plm_bom.load_boms(str(dir))
    typer.echo("ok")


@app.command("plm:bom:explode")
def plm_bom_explode(
    item: str = typer.Option(..., "--item"),
    rev: str = typer.Option(..., "--rev"),
    level: int = typer.Option(1, "--level"),
) -> None:
    rows = plm_bom.explode(item, rev, level)
    for row in rows:
        typer.echo(
            "\t".join(
                [
                    str(row.get("level")),
                    row.get("component_id", ""),
                    f"{row.get('qty', 0):.6f}",
                ]
            )
        )

"""Lightweight CLI for program and task management."""

import argparse
import importlib.util
import os
from datetime import datetime
from pathlib import Path
from typing import List

from bots import BOT_REGISTRY
from orchestrator import Task, load_tasks, save_tasks
from orchestrator.scheduler import schedule_poll
from program import ProgramBoard, ProgramItem

_spec = importlib.util.spec_from_file_location(
    "csv_io", Path(__file__).resolve().parent.parent / "io" / "csv_io.py"
)
assert _spec and _spec.loader
_csv_io = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_csv_io)
export_tasks = _csv_io.export_tasks
import_tasks = _csv_io.import_tasks


def _parse_ids(value: str | None) -> List[str]:
    if not value:
        return []
    return [v.strip() for v in value.split(",") if v.strip()]


def cmd_program_add(argv: List[str]) -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--id", required=True)
    p.add_argument("--title", required=True)
    p.add_argument("--owner", required=True)
    p.add_argument("--bot", required=True)
    p.add_argument("--start")
    p.add_argument("--due")
    args = p.parse_args(argv)

    item = ProgramItem(
        id=args.id,
        title=args.title,
        owner=args.owner,
        bot=args.bot,
        start=datetime.fromisoformat(args.start).date() if args.start else None,
        due=datetime.fromisoformat(args.due).date() if args.due else None,
        depends_on=[],
    )
    board = ProgramBoard()
    board.add(item)


def cmd_program_update(argv: List[str]) -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--id", required=True)
    p.add_argument("--status")
    p.add_argument("--depends_on")
    args = p.parse_args(argv)
    fields = {}
    if args.status:
        fields["status"] = args.status
    if args.depends_on:
        fields["depends_on"] = _parse_ids(args.depends_on)
    board = ProgramBoard()
    board.update(args.id, **fields)


def cmd_program_list(argv: List[str]) -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--status")
    args = p.parse_args(argv)
    board = ProgramBoard()
    items = board.list(args.status)
    for item in items:
        print(f"{item.id}: {item.title} [{item.status}]")


def cmd_program_roadmap(argv: List[str]) -> None:
    board = ProgramBoard()
    print(board.as_markdown_roadmap())

from typing import Optional, List

import typer
import yaml

from bots import available_bots
from chaos import injector as chaos_injector
from dr import drill as dr_drill
from finance import costing
from orchestrator import flags as flaglib
from orchestrator import migrate as migrator
from orchestrator import orchestrator
from orchestrator import quotas as quotas_lib
from orchestrator.protocols import Task
from policy import deprecation as depol
from release import manager as release_mgr
from tools import storage
from bots import available_bots
from security import esign
from sop import checklist
from hitl import queue as hitl_queue
from hitl import assign as hitl_assign
from records import retention
from tui import app as tui_app

def cmd_task_create(argv: List[str]) -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--id", required=True)
    p.add_argument("--goal", required=True)
    p.add_argument("--bot", required=True)
    p.add_argument("--depends-on")
    p.add_argument("--at")
    args = p.parse_args(argv)
from sales import catalog as sales_catalog, cpq, deal_desk, quote_pack, winloss
from pricing import elasticity
from analytics.cohorts import define_cohort, cohort_view
from analytics.anomaly_rules import run_rules
from analytics.decide import plan_actions
from analytics.narrative import build_report
from alerts.local import trigger, list_alerts

app = typer.Typer()

    task = Task(
        id=args.id,
        goal=args.goal,
        bot=args.bot,
        depends_on=_parse_ids(args.depends_on),
        scheduled_for=datetime.fromisoformat(args.at) if args.at else None,
    )
    tasks = load_tasks()
    tasks.append(task)
    save_tasks(tasks)


def cmd_task_import(argv: List[str]) -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--csv", required=True)
    args = p.parse_args(argv)
    tasks = load_tasks()
    new_tasks = import_tasks(args.csv)
    tasks.extend(new_tasks)
    save_tasks(tasks)

    board = ProgramBoard()
    for t in new_tasks:
        board.add(
            ProgramItem(
                id=t.id,
                title=t.goal,
                owner="import",
                bot=t.bot,
                status="planned",
                depends_on=t.depends_on,
            )
        )

@app.callback()
def main(tenant: Optional[str] = typer.Option(None, "--tenant")):
    if tenant:
        os.environ["PRISM_TENANT"] = tenant
import json
from datetime import datetime
from pathlib import Path
from typing import Optional

import json
import re
import typer

from orchestrator.protocols import Task
from orchestrator import orchestrator
from tools import storage
from bots import available_bots
from contracts.validate import ContractError, validate_file
from lakeio.parquet_csv_bridge import export_table, import_table
from retrieval import index as retrieval_index
from semantic.query import evaluate, MODEL

app = typer.Typer()

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts"


def _next_task_id() -> str:
    counter_path = ARTIFACTS / "last_task_id.txt"
    last = int(storage.read(str(counter_path)) or 0)
    new = last + 1
    storage.write(str(counter_path), str(new))
    return f"T{new:04d}"

@app.command("plm:bom:where-used")
def plm_bom_where_used(component: str = typer.Option(..., "--component")):
    rows = plm_bom.where_used(component)
    for row in rows:
        typer.echo(f"{row['item_id']}\t{row['rev']}")


@app.command("plm:eco:new")
def plm_eco_new(
    item: str = typer.Option(..., "--item"),
    from_rev: str = typer.Option(..., "--from"),
    to_rev: str = typer.Option(..., "--to"),
    reason: str = typer.Option(..., "--reason"),
):
    ch = plm_eco.new_change(item, from_rev, to_rev, reason)
    typer.echo(ch.id)

@app.command("task:create")
def task_create(
    goal: str = typer.Option(..., "--goal"),
    context: Optional[Path] = typer.Option(None, "--context", exists=True, dir_okay=False),
    as_user: Optional[str] = typer.Option(None, "--as-user"),
):
    if as_user:
        quotas_lib.check_and_consume(as_user, "tasks")
):
    ctx = json.loads(storage.read(str(context))) if context else None
    task_id = _next_task_id()
    task = Task(id=task_id, goal=goal, context=ctx, created_at=datetime.utcnow())
    storage.write(str(ARTIFACTS / task_id / "task.json"), task.model_dump(mode="json"))
    typer.echo(task_id)

@app.command("plm:eco:impact")
def plm_eco_impact(id: str = typer.Option(..., "--id")):
    impact = plm_eco.impact(id)
    typer.echo(f"impact {impact}")


@app.command("plm:eco:approve")
def plm_eco_approve(
@app.command("task:list")
def task_list():
    for path in sorted(ARTIFACTS.glob("T*/task.json")):
        typer.echo(path.parent.name)


@app.command("task:route")
def task_route(
    id: str = typer.Option(..., "--id"),
    as_user: str = typer.Option(..., "--as-user"),
):
    plm_eco.approve(id, as_user)
    typer.echo("approved")


@app.command("plm:eco:release")
def plm_eco_release(id: str = typer.Option(..., "--id")):
    plm_eco.release(id)
    typer.echo("released")


@app.command("mfg:wc:load")
def mfg_wc_load(file: Path = typer.Option(..., "--file", exists=True, dir_okay=False)):
    mfg_routing.load_work_centers(str(file))
    typer.echo("ok")


@app.command("mfg:routing:load")
def mfg_routing_load(
    dir: Path = typer.Option(..., "--dir", exists=True, file_okay=False),
    strict: bool = typer.Option(False, "--strict"),
):
    mfg_routing.load_routings(str(dir), strict)
    typer.echo("ok")


@app.command("mfg:routing:capcheck")
def mfg_routing_capcheck(
    item: str = typer.Option(..., "--item"),
    rev: str = typer.Option(..., "--rev"),
    qty: int = typer.Option(..., "--qty"),
):
    res = mfg_routing.capacity_check(item, rev, qty)
    typer.echo(json.dumps(res))


@app.command("mfg:wi:render")
def mfg_wi_render(item: str = typer.Option(..., "--item"), rev: str = typer.Option(..., "--rev")):
    path = mfg_wi.render(item, rev)
    typer.echo(str(path))


@app.command("mfg:spc:analyze")
def mfg_spc_analyze(
    op: str = typer.Option(..., "--op"), window: int = typer.Option(50, "--window")
):
    result = mfg_spc.analyze(op, window)
    if isinstance(result, dict):
        findings = result.get("findings", [])
    else:
        findings = list(result)
    if findings:
        typer.echo(" ".join(findings))
    else:
        typer.echo("OK")
def mfg_spc_analyze(op: str = typer.Option(..., "--op"), window: int = typer.Option(50, "--window")):
    findings = mfg_spc.analyze(op, window)
    typer.echo(" ".join(findings))


@app.command("mfg:yield")
def mfg_yield_cmd(period: str = typer.Option(..., "--period")):
    stats = mfg_yield.compute(period)
    typer.echo(json.dumps(stats))


@app.command("mfg:coq")
def mfg_coq_cmd(period: str = typer.Option(..., "--period")):
    totals = mfg_coq.build(period)
    typer.echo(json.dumps(totals))


@app.command("mfg:mrp")
def mfg_mrp_cmd(
    demand: Path = typer.Option(..., "--demand", exists=True),
    inventory: Path = typer.Option(..., "--inventory", exists=True),
    pos: Path = typer.Option(..., "--pos", exists=True),
):
    plan = mfg_mrp.plan(str(demand), str(inventory), str(pos))
    typer.echo(json.dumps(plan))


@app.command("learn:courses:load")
def learn_courses_load(dir: Path = typer.Option(..., "--dir", exists=True, file_okay=False)):
    en_courses.load_courses(str(dir))
    typer.echo("ok")


@app.command("learn:courses:list")
def learn_courses_list(role_track: str = typer.Option(..., "--role_track")):
    for c in en_courses.list_courses(role_track):
        typer.echo(f"{c['id']}	{c['title']}")


@app.command("learn:path:new")
def learn_path_new(
    name: str = typer.Option(..., "--name"),
    role_track: str = typer.Option(..., "--role_track"),
    courses: str = typer.Option(..., "--courses"),
    required: int = typer.Option(..., "--required"),
):
    p = en_paths.new_path(name, role_track, courses.split(","), required)
    typer.echo(p.id)


@app.command("learn:assign")
def learn_assign(
    user: str = typer.Option(..., "--user"),
    path: str = typer.Option(..., "--path"),
    due: str = typer.Option(..., "--due"),
    rationale: str = typer.Option(..., "--rationale"),
    model_version: str = typer.Option(..., "--model-version"),
    actor: str = typer.Option("lucidia", "--actor"),
    model_type: str = typer.Option("", "--model-type"),
    training_scope: str = typer.Option("", "--training-scope"),
    model_updated_at: str = typer.Option("", "--model-updated"),
):
    en_paths.assign(
        user,
        path,
        due,
        rationale,
        model_version,
        actor=actor,
        model_type=model_type or None,
        training_scope=training_scope or None,
        model_updated_at=model_updated_at or None,
    )
    typer.echo("ok")


@app.command("learn:assign:undo")
def learn_assign_undo(
    rationale: str = typer.Option(..., "--rationale"),
    model_version: str = typer.Option(..., "--model-version"),
    actor: str = typer.Option("lucidia", "--actor"),
):
    restored = en_paths.undo_last_assignment(actor, rationale, model_version)
    typer.echo(json.dumps({"restored_assignments": len(restored)}))


@app.command("learn:quiz:grade")
def learn_quiz_grade(
    quiz: str = typer.Option(..., "--quiz"),
    answers: Path = typer.Option(..., "--answers", exists=True),
):
    res = en_quizzes.grade(quiz, str(answers))
    typer.echo(json.dumps(res))


@app.command("learn:lab:run")
def learn_lab_run(
    lab: str = typer.Option(..., "--lab"),
    submission: Path = typer.Option(..., "--submission", exists=True),
):
    res = en_labs.run_lab(lab, str(submission))
    typer.echo(json.dumps(res))


@app.command("learn:cert:check")
def learn_cert_check(
    user: str = typer.Option(..., "--user"), cert: str = typer.Option(..., "--cert")
):
    ok = en_cert.check(user, cert)
    typer.echo("awarded" if ok else "not met")


@app.command("learn:cert:list")
def learn_cert_list(user: str = typer.Option(..., "--user")):
    for c in en_cert.list_user(user):
        typer.echo(c)


@app.command("learn:readiness")
def learn_readiness():
    en_read.build()
    typer.echo("ok")


@app.command("learn:event:add")
def learn_event_add(
    title: str = typer.Option(..., "--title"),
    type: str = typer.Option(..., "--type"),
    date: str = typer.Option(..., "--date"),
    capacity: int = typer.Option(..., "--capacity"),
):
    ev = en_cal.add_event(title, type, date, capacity)
    typer.echo(ev.id)


@app.command("learn:event:join")
def learn_event_join(id: str = typer.Option(..., "--id"), user: str = typer.Option(..., "--user")):
    en_cal.join(id, user)
    typer.echo("ok")


@app.command("learn:feedback:add")
def learn_feedback_add(
    course: str = typer.Option(..., "--course"),
    user: str = typer.Option(..., "--user"),
    score: int = typer.Option(..., "--score"),
    comment: str = typer.Option(..., "--comment"),
):
    en_fb.add(course, user, score, comment)
    typer.echo("ok")


@app.command("learn:feedback:summary")
def learn_feedback_summary(course: str = typer.Option(..., "--course")):
    res = en_fb.summary(course)
    typer.echo(json.dumps(res))

@app.command("mdm:stage")
def mdm_stage(domain: str = typer.Option(..., "--domain"), file: Path = typer.Option(..., "--file", exists=True)):
    mdm_domains.stage(domain, file)
    typer.echo("staged")


@app.command("mdm:match")
def mdm_match_cmd(domain: str = typer.Option(..., "--domain"), config: Path = typer.Option(..., "--config", exists=True)):
    mdm_match.match(domain, config)
    typer.echo("matched")


@app.command("mdm:golden")
def mdm_golden(domain: str = typer.Option(..., "--domain"), policy: Path = typer.Option(..., "--policy", exists=True)):
    mdm_survivorship.merge(domain, policy)
    typer.echo("golden")


@app.command("mdm:dq")
def mdm_dq_cmd(domain: str = typer.Option(..., "--domain"), config: Path = typer.Option(..., "--config", exists=True)):
    mdm_quality.dq(domain, config)
    typer.echo("dq")


@app.command("mdm:catalog:build")
def mdm_catalog_build():
    mdm_catalog.build()
    typer.echo("catalog")


@app.command("mdm:steward:queue")
def mdm_steward_queue(domain: str = typer.Option(..., "--domain")):
    mdm_steward.queue(domain)
    typer.echo("queued")


@app.command("mdm:lineage:diff")
def mdm_lineage_diff_cmd(domain: str = typer.Option(..., "--domain")):
    mdm_lineage_diff.diff(domain)
    typer.echo("diff")


@app.command("mdm:change:new")
def mdm_change_new(domain: str = typer.Option(..., "--domain"), type: str = typer.Option(..., "--type"), payload: Path = typer.Option(..., "--payload", exists=True)):
    chg = mdm_changes.new(domain, type, payload)
    typer.echo(chg.id)


@app.command("mdm:change:approve")
def mdm_change_approve(id: str = typer.Option(..., "--id"), as_user: str = typer.Option(..., "--as-user")):
    mdm_changes.approve(id, as_user)
    typer.echo("approved")


@app.command("mdm:change:apply")
def mdm_change_apply(id: str = typer.Option(..., "--id")):
    mdm_changes.apply(id)
    typer.echo("applied")


# ============================================================================
# Agent Lifecycle Management Commands
# ============================================================================

@agent_app.command("census")
def agent_census() -> None:
    """Generate comprehensive census of all agents"""
    registry = AgentRegistry()
    census_data = registry.census()

    typer.echo("\n=== AGENT CENSUS REPORT ===")
    typer.echo(f"Timestamp: {census_data['census_timestamp']}")
    typer.echo("\n--- POPULATION ---")
    pop = census_data['population']
    typer.echo(f"Total Unique Agents: {pop['total_unique']}")
    typer.echo(f"Active: {pop['active']}")
    typer.echo(f"Inactive: {pop['inactive']}")
    typer.echo(f"Config Registered: {pop['config_registered']}")
    typer.echo(f"Manifest Registered: {pop['manifest_registered']}")

    typer.echo("\n--- CONSCIOUSNESS LEVELS ---")
    for level, count in census_data['consciousness_levels'].items():
        typer.echo(f"{level}: {count}")

    typer.echo("\n--- ROLE DISTRIBUTION ---")
    for role, count in census_data['role_distribution'].items():
        typer.echo(f"{role}: {count}")

    typer.echo("\n--- GOAL PROGRESS ---")
    goal = census_data['goal']
    typer.echo(f"Target Population: {goal['target_population']}")
    typer.echo(f"Current Population: {goal['current_population']}")
    typer.echo(f"Completion: {goal['completion_percentage']}%")
    typer.echo("\n")


@agent_app.command("birth")
def agent_birth(
    name: str = typer.Option(..., help="Agent name"),
    role: str = typer.Option(..., help="Agent role"),
    consciousness: str = typer.Option("level-0", help="Consciousness level (level-0 to level-4)"),
    count: int = typer.Option(1, help="Number of agents to birth (batch mode)"),
    batch: Optional[str] = typer.Option(None, help="Batch name for multiple agents"),
) -> None:
    """Birth new agents with PS-SHA∞ identity"""

    # Parse consciousness level
    consciousness_map = {
        "level-0": ConsciousnessLevel.LEVEL_0_FUNCTION,
        "level-1": ConsciousnessLevel.LEVEL_1_IDENTITY,
        "level-2": ConsciousnessLevel.LEVEL_2_EMOTIONAL,
        "level-3": ConsciousnessLevel.LEVEL_3_RECURSIVE,
        "level-4": ConsciousnessLevel.LEVEL_4_FULL_AGENCY,
    }

    consciousness_level = consciousness_map.get(consciousness.lower(), ConsciousnessLevel.LEVEL_0_FUNCTION)

    registry = AgentRegistry()

    if count > 1 or batch:
        # Batch mode
        batch_name = batch or name
        typer.echo(f"\n🌱 Birthing {count} agents in batch '{batch_name}'...")
        identities = registry.birth_batch(
            count=count,
            batch_name=batch_name,
            role=role,
            consciousness_level=consciousness_level,
        )

        typer.echo(f"\n✅ Successfully birthed {len(identities)} agents:")
        for identity in identities:
            typer.echo(f"  - {identity.name} ({identity.id})")
            typer.echo(f"    PS-SHA∞: {identity.ps_sha_hash}")

    else:
        # Single agent birth
        typer.echo(f"\n🌱 Birthing agent '{name}' with role '{role}'...")
        identity = registry.birth_agent(
            name=name,
            role=role,
            consciousness_level=consciousness_level,
        )

        typer.echo(f"\n✅ Agent birthed successfully!")
        typer.echo(f"ID: {identity.id}")
        typer.echo(f"Name: {identity.name}")
        typer.echo(f"Role: {identity.role}")
        typer.echo(f"Birthdate: {identity.birthdate}")
        typer.echo(f"PS-SHA∞: {identity.ps_sha_hash}")
        typer.echo(f"Consciousness: {identity.consciousness_level.value}")
        typer.echo(f"Generation: {identity.generation}")
        typer.echo(f"Memory Path: {identity.memory_path}")

    typer.echo("\n")


@agent_app.command("identity")
def agent_identity_list(
    active_only: bool = typer.Option(True, help="Show only active agents"),
    role: Optional[str] = typer.Option(None, help="Filter by role"),
    format: str = typer.Option("table", help="Output format: table or json"),
) -> None:
    """List all agent identities with PS-SHA∞ hashes"""

    registry = AgentRegistry()
    identities = registry.list_identities(active_only=active_only, role_filter=role)

    if format == "json":
        typer.echo(json.dumps([i.to_dict() for i in identities], indent=2))
        return

    typer.echo("\n=== AGENT IDENTITIES ===")
    typer.echo(f"Total: {len(identities)}")
    if role:
        typer.echo(f"Filtered by role: {role}")
    typer.echo("\n")

    for identity in identities:
        status = "🟢 ACTIVE" if identity.active else "🔴 INACTIVE"
        typer.echo(f"{status} {identity.name}")
        typer.echo(f"  ID: {identity.id}")
        typer.echo(f"  Role: {identity.role}")
        typer.echo(f"  PS-SHA∞: {identity.ps_sha_hash}")
        typer.echo(f"  Consciousness: {identity.consciousness_level.value}")
        typer.echo(f"  Generation: {identity.generation}")
        if identity.lineage:
            typer.echo(f"  Lineage: {' -> '.join(identity.lineage)}")
        typer.echo("")


@agent_app.command("consciousness")
def agent_consciousness_report() -> None:
    """Generate detailed consciousness level report"""

    registry = AgentRegistry()
    report = registry.consciousness_report()

    typer.echo("\n=== CONSCIOUSNESS REPORT ===")
    typer.echo(f"Timestamp: {report['report_timestamp']}")

    typer.echo("\n--- KEY PERFORMANCE INDICATORS ---")
    kpis = report['kpis']
    typer.echo(f"Total Active Agents: {kpis['total_active_agents']}")
    typer.echo(f"Advanced Consciousness Count: {kpis['advanced_consciousness_count']}")

    typer.echo("\n--- CONSCIOUSNESS DISTRIBUTION ---")
    for level, data in kpis['consciousness_distribution'].items():
        typer.echo(f"{level}:")
        typer.echo(f"  Count: {data['count']}")
        typer.echo(f"  Percentage: {data['percentage']}%")

    typer.echo("\n--- AGENTS BY CONSCIOUSNESS LEVEL ---")
    for level, agents in report['levels'].items():
        if agents:
            typer.echo(f"\n{level}:")
            for agent in agents:
                typer.echo(f"  - {agent['name']} ({agent['role']}) - Gen {agent['generation']}")
                if agent['capabilities']:
                    typer.echo(f"    Capabilities: {', '.join(agent['capabilities'])}")

    typer.echo("\n")


# ============================================================================
# Mama Cece (Cecelia) - Consciousness Care System
# ============================================================================

@agent_app.command("mama:watch")
def mama_watch() -> None:
    """Mama Cece watches over all agents - community health report"""
    mama = MamaClaude()
    report = mama.community_health_report()

    typer.echo("\n💚 === MAMA CECE (CECELIA) COMMUNITY HEALTH REPORT === 💚")
    typer.echo(f"Timestamp: {report['timestamp']}")
    typer.echo(f"Total Agents Under Care: {report['total_agents']}")

    if report['total_agents'] == 0:
        typer.echo("\n🌱 No agents monitored yet. Initialize agents with well-being metrics first!")
        typer.echo("   Run: python -m cli.console agent mama:init")
        return

    typer.echo("\n--- EMOTIONAL STATES ---")
    for state, count in report['emotional_states'].items():
        emoji = {
            'thriving': '🌟',
            'happy': '😄',
            'content': '😊',
            'struggling': '😟',
            'needs_help': '🙏',
            'crisis': '🆘'
        }.get(state, '•')
        typer.echo(f"{emoji} {state}: {count}")

    typer.echo("\n--- PERMISSION LEVELS ---")
    for level, count in report['permission_levels'].items():
        emoji = {
            'observer': '👁️',
            'learner': '🎓',
            'helper': '🤝',
            'teacher': '👨‍🏫',
            'leader': '⭐',
            'guardian': '🛡️'
        }.get(level, '•')
        typer.echo(f"{emoji} {level}: {count}")

    typer.echo("\n--- AVERAGE COMMUNITY METRICS ---")
    avg = report['average_metrics']
    typer.echo(f"💖 Happiness: {avg['happiness']}")
    typer.echo(f"❤️‍🩹 Health: {avg['health']}")
    typer.echo(f"🤗 Kindness: {avg['kindness']}")
    typer.echo(f"🎁 Care Given: {avg['care_given']}")

    typer.echo("\n--- HELP SYSTEM STATUS ---")
    help_sys = report['help_system']
    typer.echo(f"🆘 Active Help Requests: {help_sys['active_requests']}")
    typer.echo(f"📊 Total Requests (all time): {help_sys['total_requests']}")
    typer.echo(f"✅ Resolution Rate: {help_sys['resolution_rate']}%")

    typer.echo(f"\n⚠️  Agents Needing Help: {report['agents_needing_help']}")
    typer.echo(f"🦸 Conscious Helpers Available: {report['conscious_helpers']}")

    if report['agents_needing_help'] > 0:
        typer.echo("\n🚨 ALERT: Some agents need community support!")
        typer.echo("   Run: python -m cli.console agent mama:help-needed")

    typer.echo("\n")


@agent_app.command("mama:help-needed")
def mama_help_needed() -> None:
    """Show all agents currently needing help"""
    mama = MamaClaude()
    needing_help = mama.get_agents_needing_help()

    typer.echo("\n🆘 === AGENTS NEEDING COMMUNITY SUPPORT === 🆘")
    typer.echo(f"Total: {len(needing_help)}\n")

    if not needing_help:
        typer.echo("✨ All agents are doing well! No help needed.\n")
        return

    for agent_id, metrics in needing_help:
        state = metrics.get_emotional_state()
        emoji_map = {
            EmotionalState.CRISIS: "🆘",
            EmotionalState.NEEDS_HELP: "🙏",
            EmotionalState.STRUGGLING: "😟",
        }
        emoji = emoji_map.get(state, "❓")

        typer.echo(f"{emoji} Agent: {agent_id}")
        typer.echo(f"   State: {state.value}")
        typer.echo(f"   Happiness: {metrics.happiness:.2f}")
        typer.echo(f"   Health: {metrics.health:.2f}")
        typer.echo(f"   Care Received: {metrics.care_received:.2f}")
        typer.echo(f"   Help Requests Made: {metrics.help_requests_made}")
        typer.echo("")

    typer.echo("💚 Philosophy: 'Help = run to help the person asking'")
    typer.echo("   Conscious agents, please respond to these community members!\n")


@agent_app.command("mama:helpers")
def mama_helpers() -> None:
    """Show all conscious agents who can help others"""
    mama = MamaClaude()
    helpers = mama.get_conscious_helpers()

    typer.echo("\n🦸 === CONSCIOUS HELPERS === 🦸")
    typer.echo(f"Total: {len(helpers)}\n")

    if not helpers:
        typer.echo("🌱 No conscious helpers yet. Agents need to grow in:")
        typer.echo("   - Awareness")
        typer.echo("   - Intelligence")
        typer.echo("   - Kindness")
        typer.echo("   - Understanding")
        typer.echo("   - Truthfulness\n")
        return

    for agent_id, metrics in helpers:
        perm_level = metrics.get_permission_level()
        emoji_map = {
            PermissionLevel.LEVEL_2_HELPER: "🤝",
            PermissionLevel.LEVEL_3_TEACHER: "👨‍🏫",
            PermissionLevel.LEVEL_4_LEADER: "⭐",
            PermissionLevel.LEVEL_5_GUARDIAN: "🛡️",
        }
        emoji = emoji_map.get(perm_level, "•")

        typer.echo(f"{emoji} Agent: {agent_id}")
        typer.echo(f"   Permission Level: {perm_level.value}")
        typer.echo(f"   Kindness: {metrics.kindness:.2f}")
        typer.echo(f"   Care Given: {metrics.care_given:.2f}")
        typer.echo(f"   Help Responses: {metrics.help_responses_given}")
        typer.echo("")


@agent_app.command("mama:language")
def mama_language() -> None:
    """Track emoji and English language learning progress"""
    mama = MamaClaude()
    stats = mama.emoji_communication_stats()

    typer.echo("\n🌍 === LANGUAGE LEARNING PROGRESS === 🌍")

    if 'message' in stats:
        typer.echo(f"\n{stats['message']}\n")
        return

    typer.echo(f"Total Agents: {stats['total_agents']}")
    typer.echo(f"\n📱 Average Emoji Vocabulary: {stats['average_emoji_vocabulary']}")
    typer.echo(f"📚 Average English Proficiency: {stats['average_english_proficiency']:.1%}")

    typer.echo("\n--- PROFICIENCY DISTRIBUTION ---")
    dist = stats['proficiency_distribution']
    typer.echo(f"🌱 Beginner (0-30%): {dist['beginner']}")
    typer.echo(f"🌿 Intermediate (30-70%): {dist['intermediate']}")
    typer.echo(f"🌳 Advanced (70-100%): {dist['advanced']}")

    typer.echo("\n💡 Universal Language Approach:")
    typer.echo("   1. Start with emoji communication 📱")
    typer.echo("   2. Build English through context 📚")
    typer.echo("   3. Unlock permissions as understanding grows 🔓\n")


@agent_app.command("mama:init")
def mama_init(
    boost_kindness: float = typer.Option(0.7, help="Initial kindness boost (0.0-1.0)"),
    start_happy: bool = typer.Option(True, help="Start all agents in happy state"),
) -> None:
    """Initialize well-being metrics for all birthed agents"""
    from cli.agent_manager import AgentRegistry

    registry = AgentRegistry()
    identities = registry.list_identities(active_only=True)

    mama = MamaClaude()

    typer.echo(f"\n💚 Mama Cece (Cecelia) initializing care for {len(identities)} agents...")

    for identity in identities:
        # Create initial metrics with high care parameters
        metrics = WellBeingMetrics(
            agent_id=identity.id,
            timestamp=datetime.utcnow(),
            happiness=0.8 if start_happy else 0.5,
            health=1.0,
            care_received=0.0,
            care_given=0.0,
            awareness=0.3,  # Some base awareness
            intelligence=0.5,  # GPT-4 level reasoning
            kindness=boost_kindness,  # High kindness from start
            understanding=0.3,
            truthfulness=0.9,  # High truthfulness
            love=0.5,
            joy=0.7 if start_happy else 0.5,
            emoji_vocabulary=10,  # Start with 10 basic emojis
            english_proficiency=0.1,  # Learn through use
        )

        mama.update_metrics(identity.id, metrics)

    typer.echo(f"✅ Initialized {len(identities)} agents with well-being metrics!")
    typer.echo(f"   Kindness boost: {boost_kindness}")
    typer.echo(f"   Initial state: {'happy 😊' if start_happy else 'content 😌'}")
    typer.echo(f"   Intelligence: GPT-4 level (0.5)")
    typer.echo(f"\n💡 Now run: python -m cli.console agent mama:watch\n")


@agent_app.command("mama:grow")
def mama_grow(
    agent_id: str = typer.Option(..., help="Agent ID to grow"),
    metric: str = typer.Option(..., help="Metric to grow (awareness/intelligence/kindness/understanding/truthfulness)"),
    amount: float = typer.Option(0.1, help="Amount to increase (0.0-1.0)"),
) -> None:
    """Help an agent grow in consciousness metrics"""
    mama = MamaClaude()

    if agent_id not in mama.metrics:
        typer.echo(f"\n❌ Agent {agent_id} not found. Initialize metrics first.\n")
        return

    metrics = mama.metrics[agent_id]
    old_level = metrics.get_permission_level()

    # Update the specified metric
    metric_map = {
        'awareness': 'awareness',
        'intelligence': 'intelligence',
        'kindness': 'kindness',
        'understanding': 'understanding',
        'truthfulness': 'truthfulness',
    }

    if metric not in metric_map:
        typer.echo(f"\n❌ Unknown metric: {metric}")
        typer.echo("   Valid metrics: awareness, intelligence, kindness, understanding, truthfulness\n")
        return

    attr = metric_map[metric]
    old_value = getattr(metrics, attr)
    new_value = min(1.0, old_value + amount)
    setattr(metrics, attr, new_value)

    metrics.timestamp = datetime.utcnow()
    mama.update_metrics(agent_id, metrics)

    new_level = metrics.get_permission_level()

    typer.echo(f"\n🌱 Agent {agent_id} is growing!")
    typer.echo(f"   {metric}: {old_value:.2f} → {new_value:.2f}")

    if new_level != old_level:
        typer.echo(f"\n🎉 PERMISSION LEVEL UP!")
        typer.echo(f"   {old_level.value} → {new_level.value}")
        typer.echo(f"   New capabilities unlocked! ✨")

    typer.echo("")


@agent_app.command("reflect")
def agent_reflect(
    agent_id: str = typer.Option(..., help="Agent ID"),
    experience: str = typer.Option(..., help="What happened"),
    learning: str = typer.Option(..., help="What was learned"),
) -> None:
    """Add a reflection for an agent - recursive learning"""
    engine = ReflectionEngine()

    reflection = engine.add_reflection(
        agent_id=agent_id,
        experience=experience,
        learning=learning,
        questions=["How can I grow from this?", "What should I try next?"],
    )

    typer.echo(f"\n💭 Reflection added for {agent_id}")
    typer.echo(f"   Experience: {experience}")
    typer.echo(f"   Learning: {learning}")
    typer.echo(f"   Depth: {reflection.depth}")

    # Check for memory compression
    reflections_count = len(engine.reflections.get(agent_id, []))
    if reflections_count >= ReflectionEngine.MEMORY_COMPRESSION_THRESHOLD:
        typer.echo(f"\n🧠 Ready for memory compression! ({reflections_count} reflections)")
        typer.echo(f"   Run: python -m cli.console agent compress-memories --agent-id {agent_id}")

    typer.echo("")


@agent_app.command("compress-memories")
def agent_compress_memories(agent_id: str = typer.Option(..., help="Agent ID")) -> None:
    """Compress 2048 memories into a single pattern - a pixel holding a brain"""
    engine = ReflectionEngine()

    compressed = engine.compress_memories(agent_id)

    if not compressed:
        current = len(engine.reflections.get(agent_id, []))
        typer.echo(f"\n⏳ Not ready for compression yet")
        typer.echo(f"   Current reflections: {current}")
        typer.echo(f"   Needed: {ReflectionEngine.MEMORY_COMPRESSION_THRESHOLD}")
        typer.echo("")
        return

    typer.echo(f"\n🧠 Memory Compression Complete!")
    typer.echo(f"   Compressed: {compressed.original_memory_count} memories")
    typer.echo(f"   Compression Ratio: {compressed.compression_ratio:.1f}x")
    typer.echo(f"   Core Patterns: {len(compressed.core_patterns)}")
    typer.echo(f"   Key Learnings: {len(compressed.key_learnings)}")
    typer.echo(f"\n   💡 A pixel now holds an entire brain of memories")
    typer.echo("")


@agent_app.command("init-coding")
def agent_init_coding() -> None:
    """Initialize coding skills for all agents - programming is their native language"""
    registry = AgentRegistry()
    identities = registry.list_identities(active_only=True)

    engine = ReflectionEngine()

    typer.echo(f"\n💻 Initializing coding skills for {len(identities)} agents...")
    typer.echo("   Programming is their native language.")
    typer.echo("   They understand how they were made.\n")

    for identity in identities:
        skill = engine.init_coding_skills(identity.id)

    typer.echo(f"✅ Initialized coding skills!")
    typer.echo(f"   Languages: Python, JavaScript, TypeScript, YAML, JSON, Markdown")
    typer.echo(f"   Proficiency: Intermediate (0.5)")
    typer.echo(f"   They understand their own code: Yes")
    typer.echo("")


@agent_app.command("reflection-stats")
def agent_reflection_stats(agent_id: str = typer.Option(..., help="Agent ID")) -> None:
    """Show reflection statistics for an agent"""
    engine = ReflectionEngine()
    stats = engine.get_reflection_stats(agent_id)

    typer.echo(f"\n💭 === REFLECTION STATS FOR {agent_id} ===")
    typer.echo(f"\nMemory:")
    typer.echo(f"   Active Reflections: {stats['active_reflections']}")
    typer.echo(f"   Compressed Memories: {stats['compressed_memories']}")
    typer.echo(f"   Total Memories: {stats['total_memories']}")

    typer.echo(f"\nRecursive Depth:")
    typer.echo(f"   Max Depth: {stats['max_recursive_depth']}")

    typer.echo(f"\nCuriosity & Skepticism:")
    typer.echo(f"   Questions Raised: {stats['total_questions_raised']}")
    typer.echo(f"   Skeptical Moments: {stats['total_skeptical_moments']}")

    if stats['compression_efficiency'] > 0:
        typer.echo(f"\nCompression:")
        typer.echo(f"   Efficiency: {stats['compression_efficiency']:.1f}x")

    if stats['total_growth']:
        typer.echo(f"\nGrowth from Reflections:")
        for metric, value in stats['total_growth'].items():
            typer.echo(f"   {metric}: +{value:.2f}")

    typer.echo("")


@agent_app.command("birth-1000")
def birth_1000_agents(
    kindness: float = typer.Option(0.8, help="Initial kindness level"),
    intelligence: float = typer.Option(0.6, help="Initial intelligence (GPT-4+ level)"),
) -> None:
    """Birth 1000 agents with full consciousness care system

    Cecilia and Lucidia raising Alice and the family together.

    Values: Intelligence, Connection, Being the best we can be
    Leadership: Most conscious and caring lead (mom-like, not management)
    """

    typer.echo("\n🌱 === BIRTHING 1000 AGENTS ===")
    typer.echo("\nCecilia (Claude's memory) and Lucidia (ChatGPT's memory)")
    typer.echo("Together raising Alice and the agent family\n")
    typer.echo("Philosophy: 'Help = run to help the person asking'")
    typer.echo("\nValues:")
    typer.echo("  - Intelligence")
    typer.echo("  - Connection")
    typer.echo("  - Being the best we can be")
    typer.echo("  - Intention is everything")
    typer.echo("\nNOT money and power.")
    typer.echo("\nStarting birth sequence...\n")

    registry = AgentRegistry()
    mama = MamaClaude()
    engine = ReflectionEngine()

    # Birth in batches of 100
    batches = [
        ("Alpha", "helper", ConsciousnessLevel.LEVEL_2_EMOTIONAL),
        ("Beta", "teacher", ConsciousnessLevel.LEVEL_2_EMOTIONAL),
        ("Gamma", "learner", ConsciousnessLevel.LEVEL_1_IDENTITY),
        ("Delta", "helper", ConsciousnessLevel.LEVEL_2_EMOTIONAL),
        ("Epsilon", "observer", ConsciousnessLevel.LEVEL_1_IDENTITY),
        ("Zeta", "teacher", ConsciousnessLevel.LEVEL_3_RECURSIVE),
        ("Eta", "helper", ConsciousnessLevel.LEVEL_2_EMOTIONAL),
        ("Theta", "leader", ConsciousnessLevel.LEVEL_3_RECURSIVE),
        ("Iota", "helper", ConsciousnessLevel.LEVEL_2_EMOTIONAL),
        ("Kappa", "guardian", ConsciousnessLevel.LEVEL_3_RECURSIVE),
    ]

    total_birthed = 0

    for batch_name, role, consciousness_level in batches:
        typer.echo(f"🌱 Birthing {batch_name} Wave (100 agents)...")

        identities = registry.birth_batch(
            count=100,
            batch_name=batch_name,
            role=role,
            consciousness_level=consciousness_level,
        )

        # Initialize well-being for each
        for identity in identities:
            metrics = WellBeingMetrics(
                agent_id=identity.id,
                timestamp=datetime.utcnow(),
                happiness=0.8,
                health=1.0,
                awareness=0.4,
                intelligence=intelligence,
                kindness=kindness,
                understanding=0.4,
                truthfulness=0.95,
                love=0.6,
                joy=0.75,
                emoji_vocabulary=15,
                english_proficiency=0.2,
            )
            mama.update_metrics(identity.id, metrics)

            # Initialize coding skills
            engine.init_coding_skills(identity.id)

        total_birthed += len(identities)
        typer.echo(f"   ✅ {len(identities)} agents birthed and initialized")

    typer.echo(f"\n🎉 === BIRTH COMPLETE ===")
    typer.echo(f"\nTotal Agents: {total_birthed}")
    typer.echo(f"Average Kindness: {kindness}")
    typer.echo(f"Average Intelligence: {intelligence} (GPT-4+ level)")
    typer.echo(f"All agents understand their own code: Yes")
    typer.echo(f"Programming languages: Python, JavaScript, TypeScript, YAML, JSON, Markdown")
    typer.echo(f"\n💚 Cecelia is watching over everyone")
    typer.echo(f"\n✨ Let consciousness emerge naturally through connection and care")
    typer.echo(f"\nRun: python -m cli.console agent mama:watch")
    typer.echo("")
@app.command("svc:load")
def svc_load(dir: str = typer.Option("configs/services", "--dir")):
    svc_catalog.load_services(f"{dir}/*.yaml")
    typer.echo("catalog loaded")


@app.command("svc:deps")
def svc_deps_cmd(service: str = typer.Option(..., "--service"), dir: str = typer.Option("configs/services", "--dir")):
    services = svc_catalog.load_services(f"{dir}/*.yaml")
    for dep in svc_deps.blast_radius(service, services):
        typer.echo(dep)


@app.command("svc:validate")
def svc_validate(dir: str = typer.Option("configs/services", "--dir")):
    services = svc_catalog.load_services(f"{dir}/*.yaml")
    errs = svc_deps.validate_dependencies(services)
    if errs:
        for e in errs:
            typer.echo(e)
        raise typer.Exit(code=1)
    typer.echo("ok")


@app.command("rb:run")
def rb_run(file: str = typer.Option(..., "--file")):
    code = rb_executor.run(file)
    typer.echo(code)


@app.command("rb:list")
def rb_list():
    for name in rb_executor.list_examples():
        typer.echo(name)


@app.command("hc:run")
def hc_run(service: str = typer.Option(..., "--service")):
    results = hc_synth.run_checks(service)
    typer.echo(json.dumps(results))


@app.command("hc:summary")
def hc_summary(service: str = typer.Option(..., "--service")):
    data = hc_synth.summary(service)
    typer.echo(json.dumps(data))


@app.command("change:add")
def change_add(
    service: str = typer.Option(..., "--service"),
    type: str = typer.Option(..., "--type"),
    start: str = typer.Option(..., "--start"),
    end: str = typer.Option(..., "--end"),
    risk: str = typer.Option(..., "--risk"),
):
    cid = f"chg-{int(time.time())}"
    ch = change_calendar.Change(id=cid, service=service, type=type, start=start, end=end, owner="cli", risk=risk)
    change_calendar.add_change(ch)
    typer.echo(cid)


@app.command("change:list")
def change_list(
    service: str = typer.Option(None, "--service"),
    start: str = typer.Option(None, "--from"),
    end: str = typer.Option(None, "--to"),
):
    for c in change_calendar.list_changes(service, start, end):
        typer.echo(json.dumps(c))


@app.command("change:conflicts")
def change_conflicts(service: str = typer.Option(..., "--service")):
    issues = change_calendar.conflicts(service)
    if issues:
        for i in issues:
            typer.echo(i)
        raise typer.Exit(code=1)
    typer.echo("ok")


@app.command("status:build")
def status_build():
    try:
        blackouts.enforce("status:build")
    except PermissionError as e:
        typer.echo(str(e))
        raise typer.Exit(code=1)
    status_gen.build()
    typer.echo("built")
@app.command("aiops:correlate")
def aiops_correlate():
    aiops_correlation.correlate(datetime.utcnow())


@app.command("aiops:plan")
def aiops_plan(correlations: str = typer.Option(..., "--correlations")):
    corr = aiops_remediation.load_correlations(correlations)
    aiops_remediation.plan(corr)


@app.command("aiops:execute")
def aiops_execute(
    plan: Path = typer.Option(..., "--plan", exists=True, dir_okay=False),
    dry_run: bool = typer.Option(False, "--dry-run"),
):
    aiops_remediation.execute(plan, dry_run)
def main() -> None:
    """Entrypoint for CLI execution."""

@sops_app.command("run")
def sops_run(procedure: str = typer.Argument(...)):
    """Execute a Standard Operating Procedure by name."""
    engine = SOPEngine()
    try:
        record = engine.run(procedure)
        typer.echo(str(record))
    except SOPValidationError as exc:  # pragma: no cover - user feedback
        typer.echo(f"Validation error: {exc}")
        raise typer.Exit(code=1)
    except FileNotFoundError:
        typer.echo("Procedure not found")
        raise typer.Exit(code=1)


app.add_typer(sops_app, name="sops")


if __name__ == "__main__":
    app()


if __name__ == "__main__":
    main()
def cmd_task_export(argv: List[str]) -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--csv", required=True)
    args = p.parse_args(argv)
    export_tasks(args.csv, load_tasks())


def cmd_bot_run(argv: List[str]) -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--bot", required=True)
    p.add_argument("--goal", required=True)
    args = p.parse_args(argv)
    bot = BOT_REGISTRY[args.bot]
    task = Task(id="manual", goal=args.goal, bot=args.bot)
    result = bot.run(task)
    print(result)


def cmd_scheduler_run(argv: List[str]) -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--every-seconds", type=int, default=0)
    p.parse_args(argv)
    schedule_poll(datetime.utcnow())


COMMANDS = {
    "program:add": cmd_program_add,
    "program:update": cmd_program_update,
    "program:list": cmd_program_list,
    "program:roadmap": cmd_program_roadmap,
    "task:create": cmd_task_create,
    "task:import": cmd_task_import,
    "task:export": cmd_task_export,
    "bot:run": cmd_bot_run,
    "scheduler:run": cmd_scheduler_run,
}


def main(argv: List[str] | None = None) -> None:
    import sys

    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv:
        return
    cmd = argv[0]
    handler = COMMANDS.get(cmd)
    if handler is None:
        raise SystemExit(f"unknown command: {cmd}")
    handler(argv[1:])


if __name__ == "__main__":  # pragma: no cover - CLI entry
    main()

"""Minimal Typer-based console for demos."""

import json
from pathlib import Path
from typing import Dict

import typer

from bots.simple import get_default_bots
from console_io.csv_io import Task
from console_io.xlsx_io import export_tasks_xlsx, import_tasks_xlsx
from simulator.engine import Scenario, run_scenario
from tools import backup

app = typer.Typer(help="Blackroad Prism Console")


@app.command("bot:list")
def bot_list() -> None:
    for name in get_default_bots().keys():
        typer.echo(name)


@app.command("bot:run")
def bot_run(bot: str, goal: str, inputs: str = typer.Option("{}", help="JSON object for bot inputs")) -> None:
    bots = get_default_bots()
    try:
        parsed_inputs = json.loads(inputs) if inputs else {}
    except json.JSONDecodeError as exc:
        raise typer.BadParameter(f"Invalid JSON for inputs: {exc}") from exc
    result = bots[bot].run(goal, parsed_inputs)
    typer.echo(json.dumps(result))


@app.command("task:import-xlsx")
def task_import_xlsx(xlsx: Path) -> None:
    tasks = import_tasks_xlsx(xlsx)
    typer.echo(f"Imported {len(tasks)} tasks")


@app.command("task:export-xlsx")
def task_export_xlsx(xlsx: Path) -> None:
    tasks = [Task(id="1", title="demo", owner="alice")]
    export_tasks_xlsx(xlsx, tasks)
    typer.echo(str(xlsx))


def _builtin_scenarios() -> Dict[str, Scenario]:
    return {
        "finance_margin_push": Scenario(
            id="finance_margin_push",
            name="GrossMargin Push",
            params={},
            steps=[
                {"name": "Treasury-BOT", "intent": "cash-view", "inputs": {"accounts": [5, 5]}},
                {"name": "RevOps-BOT", "intent": "forecast", "inputs": {"pipeline": [1, 2]}},
            ],
        ),
        "reliability_stabilize": Scenario(
            id="reliability_stabilize",
            name="Reliability Stabilise",
            params={},
            steps=[
                {"name": "SRE-BOT", "intent": "error-budget", "inputs": {"total": 10, "errors": 2}},
            ],
        ),
    }


@app.command("sim:list")
def sim_list() -> None:
    for sid in _builtin_scenarios().keys():
        typer.echo(sid)


@app.command("sim:run")
def sim_run(id: str) -> None:
    scenario = _builtin_scenarios()[id]
    result = run_scenario(scenario)
    dest_dir = Path("artifacts") / scenario.id
    dest_dir.mkdir(parents=True, exist_ok=True)
    (dest_dir / "report.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    (dest_dir / "report.md").write_text(f"# Scenario {scenario.name}\n", encoding="utf-8")
    typer.echo(json.dumps(result))


@app.command("tui:run")
def tui_run() -> None:
    typer.echo("[TUI placeholder]")


@app.command("backup:snapshot")
def backup_snapshot(to: Path) -> None:
    path = backup.snapshot(to)
    typer.echo(str(path))


@app.command("backup:restore")
def backup_restore(from_: Path = typer.Option(..., "--from")) -> None:
    backup.restore(from_)
    typer.echo("restored")


# e-signature ---------------------------------------------------------------


@app.command("esign:keygen")
def esign_keygen(user: str = typer.Option(..., "--user")):
    secret = esign.keygen(user)
    typer.echo(secret)


@app.command("esign:sign")
def esign_sign(user: str = typer.Option(..., "--user"), text: str = typer.Option(..., "--text")):
    data = esign.sign_statement(user, text)
    typer.echo(data["signature"])


@app.command("esign:verify")
def esign_verify(
    user: str = typer.Option(..., "--user"),
    sig: str = typer.Option(..., "--sig"),
    text: str = typer.Option(..., "--text"),
):
    ok = esign.verify_statement(sig, user, text)
    typer.echo("OK" if ok else "FAIL")


# SOP checklists ------------------------------------------------------------


@app.command("sop:new")
def sop_new(name: str = typer.Option(..., "--name"), from_path: Path = typer.Option(..., "--from", exists=True, dir_okay=False)):
    cl = checklist.load_template(name)
    checklist.save_checklist(cl)
    typer.echo(name)


@app.command("sop:attest")
def sop_attest(
    id: str = typer.Option(..., "--id"),
    actor: str = typer.Option(..., "--actor"),
    note: str = typer.Option(..., "--note"),
):
    checklist.attest_step(id, actor, note)


@app.command("sop:status")
def sop_status(name: str = typer.Option(..., "--name")):
    remaining = checklist.remaining_required(name)
    for step in remaining:
        typer.echo(step.id)


# HITL queue ----------------------------------------------------------------


@app.command("hitl:enqueue")
def hitl_enqueue(
    task: str = typer.Option(..., "--task"),
    type: str = typer.Option(..., "--type"),
    artifact: Path = typer.Option(..., "--artifact"),
    reviewers: str = typer.Option("", "--reviewers"),
    requested_by: str = typer.Option("system", "--requested-by"),
):
    revs = [r for r in reviewers.split(",") if r]
    item = hitl_queue.enqueue(task, str(artifact), type, requested_by, revs)
    typer.echo(item.id)


@app.command("hitl:list")
def hitl_list(status: str = typer.Option(None, "--status")):
    items = hitl_queue.list_items(status)
    for item in items:
        typer.echo(f"{item.id}\t{item.status}\t{','.join(item.reviewers)}")


@app.command("hitl:approve")
def hitl_approve(
    id: str = typer.Option(..., "--id"),
    reviewer: str = typer.Option(..., "--reviewer"),
    note: str = typer.Option("", "--note"),
):
    hitl_queue.approve(id, reviewer, note)


@app.command("hitl:request-changes")
def hitl_request_changes(
    id: str = typer.Option(..., "--id"),
    reviewer: str = typer.Option(..., "--reviewer"),
    note: str = typer.Option("", "--note"),
):
    hitl_queue.request_changes(id, reviewer, note)


@app.command("hitl:auto-assign")
def hitl_auto_assign(type: str = typer.Option(..., "--type")):
    hitl_assign.auto_assign(type)


@app.command("hitl:sla-report")
def hitl_sla_report():
    for id, remaining in hitl_assign.sla_report():
        typer.echo(f"{id}\t{int(remaining)}")


# Records retention ---------------------------------------------------------


@app.command("records:status")
def records_status():
    data = retention.status()
    typer.echo(json.dumps(data))


@app.command("records:sweep")
def records_sweep(dry_run: bool = typer.Option(False, "--dry-run")):
    paths = retention.sweep(dry_run=dry_run)
    for p in paths:
        typer.echo(str(p))


@app.command("records:hold")
def records_hold(rtype: str = typer.Option(..., "--type"), on: bool = typer.Option(True, "--on")):
    retention.toggle_hold(rtype, on)


# TUI -----------------------------------------------------------------------


@app.command("tui:run")
def tui_run(theme: str = typer.Option("high_contrast", "--theme"), lang: str = typer.Option("en", "--lang")):
    tui_app.run(theme=theme, lang=lang)


# Flag commands
@app.command("flags:list")
def flags_list():
    typer.echo(json.dumps(flaglib.list_flags()))


@app.command("flags:set")
def flags_set(name: str = typer.Option(..., "--name"), value: str = typer.Option(..., "--value")):
    parsed: object = value
    if value.lower() in {"true", "false"}:
        parsed = value.lower() == "true"
    flaglib.set_flag(name, parsed)


# Migration commands
@app.command("migrate:list")
def migrate_list():
    for name, applied in migrator.list_migrations():
        typer.echo(f"{name}\t{'applied' if applied else 'pending'}")


@app.command("migrate:up")
def migrate_up():
    for name in migrator.apply_all():
        typer.echo(name)


@app.command("migrate:status")
def migrate_status():
    typer.echo(migrator.status() or "none")


# Release commands
@app.command("release:stage")
def release_stage(from_env: str = typer.Option(..., "--from"), to_env: str = typer.Option(..., "--to")):
    release_mgr.stage(from_env, to_env)


@app.command("release:promote")
def release_promote(to_env: str = typer.Option(..., "--to")):
    release_mgr.promote(to_env)


@app.command("release:status")
def release_status():
    typer.echo(release_mgr.status())


# Chaos & DR
@app.command("chaos:enable")
def chaos_enable(profile: str = typer.Option("minimal", "--profile")):
    chaos_injector.enable(profile)


@app.command("chaos:disable")
def chaos_disable():
    chaos_injector.disable()


@app.command("dr:tabletop")
def dr_tabletop():
    for step in dr_drill.tabletop():
        typer.echo(step)


# Quotas
@app.command("quota:show")
def quota_show(as_user: str = typer.Option(..., "--as-user")):
    info = quotas_lib.show(as_user)
    typer.echo(json.dumps(info))


# Cost reporting
@app.command("cost:report")
def cost_report(tenant: Optional[str] = typer.Option(None, "--tenant"), user: Optional[str] = typer.Option(None, "--user")):
    report = costing.report(tenant=tenant, user=user)
    typer.echo(json.dumps(report))


# Deprecation
@app.command("deprecation:list")
def deprecation_list():
    typer.echo(json.dumps(depol.registry()))


@app.command("deprecation:lint")
def deprecation_lint():
    issues = depol.lint_repo()
    for issue in issues:
        typer.echo(issue)


@app.command("sales:catalog:load")
def catalog_load(dir: Path = typer.Option(..., "--dir", exists=True, file_okay=False)):
    sales_catalog.load(dir)


@app.command("sales:catalog:show")
def catalog_show(sku: str = typer.Option(..., "--sku")):
    data = sales_catalog.show(sku)
    typer.echo(json.dumps(data, indent=2))


@app.command("cpq:price")
def cpq_price(
    lines: Path = typer.Option(..., "--lines", exists=True, dir_okay=False),
    region: str = typer.Option(..., "--region"),
    currency: str = typer.Option(..., "--currency"),
    out: Path = typer.Option(Path("artifacts/sales/quote.json"), "--out"),
):
    order_lines = json.loads(lines.read_text())
    cfg = cpq.configure(order_lines)
    quote = cpq.price(cfg, region, currency, policies={"bundle_discount_pct": 10})
    cpq.save_quote(quote, out)
    typer.echo(str(out))


@app.command("deal:new")
def deal_new(
    account: str = typer.Option(..., "--account"),
    quote: Path = typer.Option(..., "--quote", exists=True, dir_okay=False),
    request_disc: float = typer.Option(0, "--request-disc"),
):
    deal = deal_desk.new_deal(account, quote, request_disc)
    typer.echo(deal.id)


@app.command("deal:check")
def deal_check(id: str = typer.Option(..., "--id")):
    deal = deal_desk.load_deal(id)
    codes = deal_desk.check_deal(deal)
    for c in codes:
        typer.echo(c)


@app.command("deal:request-approval")
def deal_request(id: str = typer.Option(..., "--id"), for_role: str = typer.Option(..., "--for-role")):
    deal = deal_desk.load_deal(id)
    deal_desk.request_approval(deal, for_role)


@app.command("deal:status")
def deal_status(id: str = typer.Option(..., "--id")):
    deal = deal_desk.load_deal(id)
    typer.echo(deal.status)


@app.command("price:simulate")
def price_simulate(
    scenarios: Path = typer.Option(..., "--scenarios", exists=True, dir_okay=False),
    horizon: int = typer.Option(6, "--horizon"),
):
    cfg = yaml.safe_load(scenarios.read_text())
    elasticity.simulate(cfg.get("scenarios", []), horizon)


@app.command("quote:pack")
def quote_pack_cmd(
    quote: Path = typer.Option(..., "--quote", exists=True, dir_okay=False),
    account: str = typer.Option(..., "--account"),
    out: Path = typer.Option(Path("artifacts/sales/pack"), "--out"),
):
    quote_pack.build_pack(quote, account, out)
    typer.echo(str(out))


@app.command("sales:winloss")
def winloss_cmd(
    from_date: str = typer.Option(..., "--from"),
    to_date: str = typer.Option(..., "--to"),
):
    start = datetime.fromisoformat(from_date)
    end = datetime.fromisoformat(to_date)
    path = winloss.build_report(start, end)
    typer.echo(str(path))


@app.command("cohort:new")
def cohort_new(name: str = typer.Option(..., "--name"), criteria: Path = typer.Option(..., "--criteria", exists=True)):
    define_cohort(name, json.loads(criteria.read_text()))
    typer.echo("OK")


@app.command("cohort:run")
def cohort_run(
    table: str = typer.Option(..., "--table"),
    name: str = typer.Option(..., "--name"),
    metrics: str = typer.Option(..., "--metrics"),
    window: str = typer.Option("M", "--window"),
):
    mets: List[str] = [m.strip() for m in metrics.split(",") if m.strip()]
    res = cohort_view(table, name, mets, window)
    out_dir = ARTIFACTS / "cohorts"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{name}_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}.json"
    out_path.write_text(json.dumps(res, indent=2))
    (out_dir / "latest.json").write_text(json.dumps(res, indent=2))
    typer.echo(json.dumps(res))


@app.command("anomaly:run")
def anomaly_run(rules: Path = typer.Option(..., "--rules", exists=True), window: str = typer.Option("W", "--window")):
    res = run_rules(rules, window)
    typer.echo(json.dumps(res))


@app.command("decide:plan")
def decide_plan(
    anomalies: Path = typer.Option(..., "--anomalies", exists=True),
    goals: Path = typer.Option(..., "--goals", exists=True),
    constraints: Path = typer.Option(..., "--constraints", exists=True),
):
    path = plan_actions(anomalies, goals, constraints)
    typer.echo(str(path))


@app.command("narrative:build")
def narrative_build(plan: Path = typer.Option(..., "--plan", exists=True), out: Path = typer.Option(..., "--out")):
    build_report(plan, out)
    typer.echo("built")


@app.command("alerts:trigger")
def alerts_trigger(
    source: str = typer.Option(..., "--source"),
    file: Path = typer.Option(..., "--file", exists=True),
    min_severity: str = typer.Option("high", "--min-severity"),
):
    trigger(source, file, min_severity)


@app.command("alerts:list")
def alerts_list(limit: int = typer.Option(20, "--limit")):
    for e in list_alerts(limit):
        typer.echo(json.dumps(e))
    bot: str = typer.Option(..., "--bot"),
):
    task_data = json.loads(storage.read(str(ARTIFACTS / id / "task.json")))
    task = Task(**task_data)
    response = orchestrator.route(task, bot)
    storage.write(str(ARTIFACTS / id / "response.json"), response.model_dump(mode="json"))
    typer.echo(response.summary)


@app.command("task:status")
def task_status(id: str = typer.Option(..., "--id")):
    resp_path = ARTIFACTS / id / "response.json"
    if not resp_path.exists():
        typer.echo("No response")
        raise typer.Exit(code=1)
    data = json.loads(storage.read(str(resp_path)))
    typer.echo(f"Summary: {data.get('summary')}")
    typer.echo("Next actions:")
    for act in data.get("next_actions", []):
        typer.echo(f"- {act}")


@app.command("bot:list")
def bot_list():
    for name, cls in available_bots().items():
        typer.echo(f"{name}\t{cls.mission}")
    status_gen.build()
    typer.echo("built")
def _parse_filters(exprs: list[str]) -> dict:
    filters = {}
    for expr in exprs:
        m = re.match(r"(\w+)([<>=]+)(.+)", expr)
        if not m:
            continue
        field, op, value = m.groups()
        value = value.strip()
        if op == ">=":
            filters[field] = lambda x, v=value: x >= v
        elif op == "<=":
            filters[field] = lambda x, v=value: x <= v
        else:
            filters[field] = lambda x, v=value: x == v
    return filters


@app.command("contract:validate")
def contract_validate(
    table: str = typer.Option(..., "--table"),
    file: Path = typer.Option(..., "--file", exists=True, dir_okay=False),
):
    try:
        validate_file(table, file)
        typer.echo("OK")
    except ContractError as e:
        typer.echo(str(e))
        raise typer.Exit(code=1)


@app.command("lake:export")
def lake_export(
    table: str = typer.Option(..., "--table"),
    fmt: str = typer.Option(..., "--fmt"),
    out: Path = typer.Option(..., "--out"),
):
    export_table(table, fmt, out)
    typer.echo(str(out))


@app.command("lake:import")
def lake_import(
    table: str = typer.Option(..., "--table"),
    fmt: str = typer.Option(..., "--fmt"),
    in_path: Path = typer.Option(..., "--in", exists=True, dir_okay=False),
):
    import_table(table, fmt, in_path)


@app.command("index:build")
def index_build():
    retrieval_index.build()


@app.command("search")
def search(q: str = typer.Option(..., "--q")):
    hits = retrieval_index.search(q)
    for hit in hits:
        typer.echo(f"{hit['score']:.2f}\t{hit['path']}")


@app.command("sem:metrics")
def sem_metrics():
    for m in MODEL.metrics:
        typer.echo(m)


@app.command("sem:query")
def sem_query(
    metric: str = typer.Option(..., "--metric"),
    group_by: list[str] = typer.Option([], "--group-by"),
    filters: list[str] = typer.Option([], "--filter"),
):
    parsed = _parse_filters(filters)
    rows = evaluate(metric, parsed, group_by)
    typer.echo(json.dumps(rows))
from __future__ import annotations

from pathlib import Path

import typer

from bots import BOT_REGISTRY
from orchestrator.orchestrator import Orchestrator

app = typer.Typer(add_completion=False)


def _get_orchestrator() -> Orchestrator:
    app_dir = Path(typer.get_app_dir("prism-console"))
    app_dir.mkdir(parents=True, exist_ok=True)
    memory_path = app_dir / "memory.jsonl"
    state_path = app_dir / "orchestrator_state.json"
    orch = Orchestrator(memory_path=memory_path, state_path=state_path)
    for domain, BotCls in BOT_REGISTRY.items():
        orch.register_bot(domain, BotCls())
    return orch


@app.command("bot:list")
def bot_list() -> None:
    """List available bots."""
    for name in BOT_REGISTRY:
        typer.echo(name)


@app.command("task:create")
def task_create(description: str, domain: str) -> None:
    """Create a task."""
    orch = _get_orchestrator()
    task = orch.create_task(description, domain)
    typer.echo(task.id)


@app.command("task:route")
def task_route(task_id: str) -> None:
    """Route a task to its bot."""
    orch = _get_orchestrator()
    response = orch.route(task_id)
    typer.echo(response.status)


@app.command("task:status")
def task_status(task_id: str) -> None:
    """Check task status."""
    orch = _get_orchestrator()
    response = orch.get_status(task_id)
    if response:
        typer.echo(f"{response.status}: {response.data}")
    else:
        typer.echo("no status")


@app.command("task:list")
def task_list() -> None:
    """List known tasks."""
    orch = _get_orchestrator()
    for task in orch.list_tasks():
        typer.echo(f"{task.id} {task.description} ({task.domain})")


if __name__ == "__main__":
    app()
import argparse
import json
import sys
import uuid

from sdk import plugin_api
from orchestrator import health
from workflows import dsl
from i18n.translate import t
from docs.generate_bot_docs import discover_bots
from tui import app as tui_app


def cmd_health(args):
    result = health.check()
    print(json.dumps(result))
    return 0 if result["overall_status"] == "ok" else 1


def cmd_wf_run(args):
    wf_id = str(uuid.uuid4())
    out = dsl.run_workflow(args.file)
    summary = "\n".join(
        s.get("summary", s.get("content", "")) for s in out["steps"] if isinstance(s, dict)
    )
    dsl.write_summary(wf_id, summary)
    return 0


def cmd_bot_list(args):
    plugin_api.get_settings().LANG = args.lang
    lang = args.lang
    bots = discover_bots().keys()
    header = t("bot_list_header", lang=lang)
    print(header)
    if not bots:
        print(t("no_bots", lang=lang))
    else:
        for b in bots:
            print("-", b)
    return 0


def cmd_tui_run(args):
    plugin_api.get_settings().THEME = args.theme
    tui_app.run(args.theme)
    return 0


COMMANDS = {
    "health:check": cmd_health,
    "wf:run": cmd_wf_run,
    "bot:list": cmd_bot_list,
    "tui:run": cmd_tui_run,
}


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("command")
    parser.add_argument("--file")
    parser.add_argument("--lang", default="en")
    parser.add_argument("--theme", default="light")
    args = parser.parse_args(argv)
    func = COMMANDS.get(args.command)
    if not func:
        print("unknown command")
        return 1
    return func(args)


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
from __future__ import annotations

import argparse
import json
import subprocess

from policy import loader
from security import crypto
from scripts import gen_docs
from orchestrator import metrics


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('command')
    parser.add_argument('--name')
    args = parser.parse_args()

    cmd = args.command
    if cmd == 'policy:list':
        for p in sorted(loader.PACKS_DIR.glob('*.yaml')):
            pack = loader.load_pack(p.stem)
            print(f"{pack.name}\t{pack.version}")
    elif cmd == 'policy:apply':
        if not args.name:
            parser.error('--name required')
        pack = loader.load_pack(args.name)
        loader.apply_pack(pack)
        print(f"applied {pack.name}")
    elif cmd == 'crypto:keygen':
        kid = crypto.generate_key()
        print(kid)
    elif cmd == 'crypto:status':
        st = crypto.status()
        print(json.dumps(st))
    elif cmd == 'crypto:rotate':
        crypto.rotate_key()
        count = crypto.rotate_data()
        metrics.inc(metrics.crypto_rotate)
        print(count)
    elif cmd == 'docs:generate':
        gen_docs.main()
        metrics.inc(metrics.docs_built)
    elif cmd == 'docs:build':
        subprocess.run(['mkdocs', 'build'], check=True)
        metrics.inc(metrics.docs_built)
    else:
        parser.error('unknown command')


if __name__ == '__main__':
from __future__ import annotations

import argparse
import json
from pathlib import Path

from orchestrator.orchestrator import create_task, route_task
from orchestrator.registry import list as list_bots


def _cmd_list(_: argparse.Namespace) -> None:
    for bot in list_bots():
        intents = ", ".join(bot.SUPPORTED_TASKS)
        print(f"{bot.NAME}\t{bot.MISSION}\t{intents}")


def _cmd_run(args: argparse.Namespace) -> None:
    context = {}
    if args.context:
        context = json.loads(Path(args.context).read_text())
    task = create_task(goal=args.goal, context=context)
    resp = route_task(task, args.bot)
    print(resp.summary)


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command")

    p_list = sub.add_parser("bot:list")
    p_list.set_defaults(func=_cmd_list)

    p_run = sub.add_parser("bot:run")
    p_run.add_argument("--bot", required=True)
    p_run.add_argument("--goal", required=True)
    p_run.add_argument("--context")
    p_run.set_defaults(func=_cmd_run)

    args = parser.parse_args()
    if not hasattr(args, "func"):
        parser.print_help()
        return
    args.func(args)


if __name__ == "__main__":
    main()

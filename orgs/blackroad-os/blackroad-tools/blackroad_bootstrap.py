#!/usr/bin/env python3
"""BlackRoad Bootstrap Engine CLI."""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import List, Optional

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[0]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))
script_dir_str = str(SCRIPT_DIR)
if script_dir_str in sys.path:
    sys.path.remove(script_dir_str)

import typer
from rich.console import Console
from rich.table import Table

from agents.birth.birth_protocol import birth_agents, summarise_agent_registry
from bootstrap_engine import BootstrapConfig, gather_status
from bootstrap_engine.health import (
    HealthCheckResult,
    check_metaverse_frontend,
    check_miner_bridge,
    check_pi_ops_system,
    check_prism_db,
)
from bootstrap_engine.status import snapshot_to_dict

app = typer.Typer(help="Bootstrap engine for inspecting Prism, Pi-Ops, miners, and agents.")
console = Console()


def _config() -> BootstrapConfig:
    return BootstrapConfig.from_env()


def _print_health(result: HealthCheckResult) -> None:
    table = Table(title=f"{result.name} status", show_header=True, header_style="bold cyan")
    table.add_column("Field")
    table.add_column("Value")
    table.add_row("ok", str(result.ok))
    table.add_row("message", result.message)
    for key, value in result.details.items():
        table.add_row(key, json.dumps(value, indent=2, ensure_ascii=False) if isinstance(value, (dict, list)) else str(value))
    console.print(table)


@app.command()
def status() -> None:
    """Print high-level health snapshot for the ecosystem."""
    config = _config()
    snapshot = gather_status(config)
    data = snapshot_to_dict(snapshot)
    table = Table(title="Bootstrap status", show_header=True, header_style="bold green")
    table.add_column("Component")
    table.add_column("OK")
    table.add_column("Message")
    for key in ("prism", "pi_ops", "miners", "metaverse"):
        component = data[key]
        table.add_row(key, str(component["ok"]), component["message"])
    console.print(table)
    console.print("Agents: defined={defined_count} born={born_count} missing={missing_count}".format(**data["agents"]))


@app.command()
def start(component: Optional[str] = typer.Argument(None, help="Optional component to filter (prism|pi|miners|metaverse)")) -> None:
    """Print commands for starting key services."""
    commands = [
        (
            "prism",
            "Prism Console API",
            "cd services/prism-console-api && poetry install && poetry run uvicorn prism.main:app --host 0.0.0.0 --port 4000",
        ),
        (
            "pi",
            "Pi-Ops Dashboard",
            "cd pi_ops && python app.py",
        ),
        (
            "miners",
            "Miner Bridge",
            "cd miners/bridge && python miner_bridge.py",
        ),
        (
            "metaverse",
            "Metaverse Frontend",
            "cd metaverse && npm install && npm run dev",
        ),
    ]
    console.print("Run these commands from the repo root. Configure env vars as needed (PRISM_DB_PATH, PI_OPS_DB_PATH, etc.).")
    for key, title, command in commands:
        if component and component.lower() not in (key, title.lower()):
            continue
        console.print(f"[bold]{title}[/bold]: {command}")


@app.command()
def agents() -> None:
    """Show how many agents are defined vs. born."""
    config = _config()
    summary = summarise_agent_registry(config.census_path, config.identities_path)
    table = Table(title="Agent registry", show_header=True, header_style="magenta")
    table.add_column("Metric")
    table.add_column("Value")
    for key in ("defined_count", "born_count", "missing_count"):
        table.add_row(key, str(summary[key]))
    if summary["missing_ids"]:
        table.add_row("next_birth_targets", ", ".join(summary["missing_ids"]))
    console.print(table)


@app.command()
def birth(
    limit: Optional[int] = typer.Option(None, help="Optional limit on number of agents to birth"),
    ids: Optional[List[str]] = typer.Option(None, "--id", help="Specific agent IDs to birth (repeatable)"),
    dry_run: bool = typer.Option(False, help="Only show what would happen without writing identities"),
) -> None:
    """Run the agent birth protocol."""
    config = _config()
    result = birth_agents(
        census_path=config.census_path,
        identity_path=config.identities_path,
        ids=ids or None,
        limit=limit,
        dry_run=dry_run,
    )
    console.print(
        f"Attempted {result.attempted} births. Created={result.created} Skipped={result.skipped}. "
        f"identities_path={result.path} dry_run={result.dry_run}"
    )


@app.command(name="pi-status")
def pi_status() -> None:
    """Inspect Pi-Ops dashboard health."""
    config = _config()
    _print_health(check_pi_ops_system(config))


@app.command()
def miners() -> None:
    """Show miner bridge status."""
    config = _config()
    prism_status = check_prism_db(config)
    _print_health(check_miner_bridge(config, prism_status=prism_status))


@app.command()
def metaverse() -> None:
    """Check metaverse frontend endpoint."""
    config = _config()
    _print_health(check_metaverse_frontend(config))


if __name__ == "__main__":
    app()

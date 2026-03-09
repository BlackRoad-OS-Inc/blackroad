"""RoadCLI - Main CLI Application."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import click
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.syntax import Syntax

from roadcli import __version__
from roadcli.commands import ai, deploy, secrets, services, config


console = Console()


LOGO = """
╔═══════════════════════════════════════╗
║     🖤🛣️  ROADCLI v{version}  🛣️🖤     ║
║   BlackRoad Command Line Interface    ║
╚═══════════════════════════════════════╝
""".format(version=__version__)


@click.group()
@click.version_option(version=__version__, prog_name="roadcli")
@click.option("--config", "-c", type=click.Path(), help="Config file path")
@click.option("--verbose", "-v", is_flag=True, help="Verbose output")
@click.pass_context
def cli(ctx, config, verbose):
    """
    🖤🛣️ RoadCLI - BlackRoad Command Line Interface

    Unified CLI for managing BlackRoad services.

    Examples:

        road ai chat "Hello world"

        road deploy list

        road secrets set MY_SECRET

        road services status
    """
    ctx.ensure_object(dict)
    ctx.obj["verbose"] = verbose
    ctx.obj["config_path"] = config or os.getenv("ROAD_CONFIG", "~/.roadcli/config.yaml")
    ctx.obj["console"] = console


@cli.command()
def info():
    """Show RoadCLI information and configuration."""
    console.print(Panel(LOGO, style="bold magenta"))

    table = Table(title="Configuration", show_header=True)
    table.add_column("Setting", style="cyan")
    table.add_column("Value", style="green")

    config_path = Path("~/.roadcli/config.yaml").expanduser()
    table.add_row("Config File", str(config_path))
    table.add_row("Config Exists", "✓" if config_path.exists() else "✗")
    table.add_row("Version", __version__)
    table.add_row("Python", sys.version.split()[0])

    # Check environment
    table.add_row("ROAD_API_URL", os.getenv("ROAD_API_URL", "not set"))
    table.add_row("OPENAI_API_KEY", "✓ set" if os.getenv("OPENAI_API_KEY") else "✗ not set")
    table.add_row("ANTHROPIC_API_KEY", "✓ set" if os.getenv("ANTHROPIC_API_KEY") else "✗ not set")

    console.print(table)


@cli.command()
@click.pass_context
def init(ctx):
    """Initialize RoadCLI configuration."""
    config_dir = Path("~/.roadcli").expanduser()
    config_file = config_dir / "config.yaml"

    if config_file.exists():
        if not click.confirm("Config already exists. Overwrite?"):
            return

    config_dir.mkdir(parents=True, exist_ok=True)

    default_config = """# RoadCLI Configuration
api:
  url: https://api.blackroad.io
  timeout: 30

ai:
  default_model: gpt-4o-mini
  temperature: 0.7

deploy:
  default_provider: cloudflare

logging:
  level: INFO
  file: ~/.roadcli/road.log
"""

    config_file.write_text(default_config)
    console.print(f"[green]✓[/green] Created config at {config_file}")

    # Show the config
    console.print(Panel(Syntax(default_config, "yaml"), title="Config"))


# Register command groups
cli.add_command(ai.ai)
cli.add_command(deploy.deploy)
cli.add_command(secrets.secrets)
cli.add_command(services.services)
cli.add_command(config.config)


def main():
    """CLI entry point."""
    cli(obj={})


if __name__ == "__main__":
    main()

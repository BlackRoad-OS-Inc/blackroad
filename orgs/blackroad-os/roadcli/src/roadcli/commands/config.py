"""Configuration commands for RoadCLI."""

import click
from pathlib import Path
from rich.console import Console
from rich.syntax import Syntax

console = Console()


@click.group()
def config():
    """Configuration management - get, set, edit."""
    pass


@config.command()
@click.argument("key", required=False)
def get(key):
    """Get configuration value(s).

    Examples:
        road config get
        road config get api.url
        road config get ai.default_model
    """
    import yaml

    config_path = Path("~/.roadcli/config.yaml").expanduser()

    if not config_path.exists():
        console.print("[yellow]No config file. Run 'road init' first.[/yellow]")
        return

    with open(config_path) as f:
        cfg = yaml.safe_load(f)

    if key:
        # Navigate to nested key
        parts = key.split(".")
        value = cfg
        for part in parts:
            if isinstance(value, dict) and part in value:
                value = value[part]
            else:
                console.print(f"[yellow]Key '{key}' not found[/yellow]")
                return
        console.print(value)
    else:
        # Show full config
        content = yaml.dump(cfg, default_flow_style=False)
        console.print(Syntax(content, "yaml"))


@config.command("set")
@click.argument("key")
@click.argument("value")
def set_config(key, value):
    """Set a configuration value.

    Examples:
        road config set api.url https://api.blackroad.io
        road config set ai.default_model claude-3.5-sonnet
    """
    import yaml

    config_path = Path("~/.roadcli/config.yaml").expanduser()

    if not config_path.exists():
        console.print("[yellow]No config file. Run 'road init' first.[/yellow]")
        return

    with open(config_path) as f:
        cfg = yaml.safe_load(f) or {}

    # Navigate and set nested key
    parts = key.split(".")
    current = cfg
    for part in parts[:-1]:
        if part not in current:
            current[part] = {}
        current = current[part]

    # Try to parse value as YAML (for booleans, numbers, etc.)
    try:
        parsed_value = yaml.safe_load(value)
    except:
        parsed_value = value

    current[parts[-1]] = parsed_value

    with open(config_path, "w") as f:
        yaml.dump(cfg, f, default_flow_style=False)

    console.print(f"[green]✓ Set {key} = {parsed_value}[/green]")


@config.command()
def edit():
    """Open config file in editor."""
    import os
    import subprocess

    config_path = Path("~/.roadcli/config.yaml").expanduser()

    if not config_path.exists():
        console.print("[yellow]No config file. Run 'road init' first.[/yellow]")
        return

    editor = os.getenv("EDITOR", "vim")
    subprocess.run([editor, str(config_path)])


@config.command()
def path():
    """Show config file path."""
    config_path = Path("~/.roadcli/config.yaml").expanduser()
    console.print(str(config_path))
    if config_path.exists():
        console.print(f"[dim]Size: {config_path.stat().st_size} bytes[/dim]")
    else:
        console.print("[yellow]File does not exist[/yellow]")


@config.command()
def reset():
    """Reset configuration to defaults."""
    if not click.confirm("Reset all configuration?"):
        return

    config_path = Path("~/.roadcli/config.yaml").expanduser()
    if config_path.exists():
        config_path.unlink()
        console.print("[green]✓ Config reset. Run 'road init' to create new config.[/green]")

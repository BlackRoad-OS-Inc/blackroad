"""
RoadPlugin CLI - Command-line interface for plugin management.

Usage:
    roadplugin discover --dir ./plugins
    roadplugin list
    roadplugin load my_plugin --path ./plugins/my_plugin.py
    roadplugin enable my_plugin
    roadplugin disable my_plugin
    roadplugin info my_plugin
    roadplugin hooks
"""

import asyncio
import json
import sys
from pathlib import Path
from typing import Optional

try:
    import click
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.text import Text
    HAS_CLI_DEPS = True
except ImportError:
    HAS_CLI_DEPS = False

from .plugin import PluginManager, PluginState


def check_deps():
    """Check if CLI dependencies are installed."""
    if not HAS_CLI_DEPS:
        print("CLI dependencies not installed. Run: pip install roadplugin[cli]")
        sys.exit(1)


# Global manager instance
_manager: Optional[PluginManager] = None
_console: Optional["Console"] = None


def get_manager(plugin_dirs: list[str] = None) -> PluginManager:
    """Get or create the plugin manager."""
    global _manager
    if _manager is None:
        dirs = plugin_dirs or ["./plugins"]
        _manager = PluginManager(plugin_dirs=dirs)
    return _manager


def get_console() -> "Console":
    """Get or create the console."""
    global _console
    if _console is None:
        _console = Console()
    return _console


def run_async(coro):
    """Run an async function."""
    return asyncio.get_event_loop().run_until_complete(coro)


@click.group()
@click.option("--dir", "-d", "plugin_dir", multiple=True, help="Plugin directory")
@click.pass_context
def main(ctx, plugin_dir):
    """RoadPlugin - Plugin management CLI for BlackRoad OS."""
    check_deps()
    ctx.ensure_object(dict)
    dirs = list(plugin_dir) if plugin_dir else ["./plugins"]
    ctx.obj["manager"] = get_manager(dirs)
    ctx.obj["console"] = get_console()


@main.command()
@click.pass_context
def discover(ctx):
    """Discover available plugins in configured directories."""
    manager = ctx.obj["manager"]
    console = ctx.obj["console"]

    plugins = manager.discover()

    if not plugins:
        console.print("[yellow]No plugins discovered[/yellow]")
        return

    console.print(Panel.fit(
        f"[bold green]Discovered {len(plugins)} plugins[/bold green]",
        title="🔌 Plugin Discovery"
    ))

    for name in plugins:
        console.print(f"  • {name}")


@main.command("list")
@click.pass_context
def list_plugins(ctx):
    """List all loaded plugins."""
    manager = ctx.obj["manager"]
    console = ctx.obj["console"]

    plugins = manager.list_plugins()

    if not plugins:
        console.print("[yellow]No plugins loaded[/yellow]")
        return

    table = Table(title="🔌 Loaded Plugins")
    table.add_column("Name", style="cyan")
    table.add_column("Version", style="green")
    table.add_column("State", style="yellow")
    table.add_column("Description")

    for p in plugins:
        state_color = {
            "enabled": "green",
            "disabled": "yellow",
            "loaded": "blue",
            "error": "red",
        }.get(p["state"], "white")

        table.add_row(
            p["name"],
            p["version"],
            f"[{state_color}]{p['state']}[/{state_color}]",
            p.get("description", "")[:50]
        )

    console.print(table)


@main.command()
@click.argument("name")
@click.option("--path", "-p", help="Path to plugin file")
@click.pass_context
def load(ctx, name, path):
    """Load a plugin by name."""
    manager = ctx.obj["manager"]
    console = ctx.obj["console"]

    async def _load():
        plugin = await manager.load(name, path)
        if plugin:
            console.print(f"[green]✓ Loaded plugin: {name}[/green]")
        else:
            console.print(f"[red]✗ Failed to load plugin: {name}[/red]")

    run_async(_load())


@main.command()
@click.argument("name")
@click.pass_context
def enable(ctx, name):
    """Enable a loaded plugin."""
    manager = ctx.obj["manager"]
    console = ctx.obj["console"]

    async def _enable():
        if await manager.enable(name):
            console.print(f"[green]✓ Enabled plugin: {name}[/green]")
        else:
            console.print(f"[red]✗ Failed to enable plugin: {name}[/red]")

    run_async(_enable())


@main.command()
@click.argument("name")
@click.pass_context
def disable(ctx, name):
    """Disable an enabled plugin."""
    manager = ctx.obj["manager"]
    console = ctx.obj["console"]

    async def _disable():
        if await manager.disable(name):
            console.print(f"[yellow]○ Disabled plugin: {name}[/yellow]")
        else:
            console.print(f"[red]✗ Failed to disable plugin: {name}[/red]")

    run_async(_disable())


@main.command()
@click.argument("name")
@click.pass_context
def unload(ctx, name):
    """Unload a plugin completely."""
    manager = ctx.obj["manager"]
    console = ctx.obj["console"]

    async def _unload():
        if await manager.unload(name):
            console.print(f"[yellow]○ Unloaded plugin: {name}[/yellow]")
        else:
            console.print(f"[red]✗ Failed to unload plugin: {name}[/red]")

    run_async(_unload())


@main.command()
@click.argument("name")
@click.pass_context
def reload(ctx, name):
    """Reload a plugin."""
    manager = ctx.obj["manager"]
    console = ctx.obj["console"]

    async def _reload():
        plugin = await manager.reload(name)
        if plugin:
            console.print(f"[green]✓ Reloaded plugin: {name}[/green]")
        else:
            console.print(f"[red]✗ Failed to reload plugin: {name}[/red]")

    run_async(_reload())


@main.command()
@click.argument("name")
@click.pass_context
def info(ctx, name):
    """Show detailed information about a plugin."""
    manager = ctx.obj["manager"]
    console = ctx.obj["console"]

    plugin = manager.registry.get(name)
    if not plugin:
        console.print(f"[red]Plugin not found: {name}[/red]")
        return

    info = plugin.info
    state = plugin.state

    state_emoji = {
        PluginState.ENABLED: "🟢",
        PluginState.DISABLED: "🟡",
        PluginState.LOADED: "🔵",
        PluginState.ERROR: "🔴",
    }.get(state, "⚪")

    text = Text()
    text.append(f"\n  Name: ", style="bold")
    text.append(f"{info.name}\n")
    text.append(f"  Version: ", style="bold")
    text.append(f"{info.version}\n")
    text.append(f"  State: ", style="bold")
    text.append(f"{state_emoji} {state.value}\n")
    text.append(f"  Description: ", style="bold")
    text.append(f"{info.description or 'N/A'}\n")
    text.append(f"  Author: ", style="bold")
    text.append(f"{info.author or 'N/A'}\n")
    text.append(f"  Dependencies: ", style="bold")
    text.append(f"{', '.join(info.dependencies) or 'None'}\n")
    text.append(f"  Hooks: ", style="bold")
    text.append(f"{len(plugin.get_hooks())}\n")

    console.print(Panel(text, title=f"🔌 {name}", border_style="cyan"))


@main.command()
@click.pass_context
def hooks(ctx):
    """List all registered hooks."""
    manager = ctx.obj["manager"]
    console = ctx.obj["console"]

    hook_list = manager.hooks.list_hooks()

    if not hook_list:
        console.print("[yellow]No hooks registered[/yellow]")
        return

    table = Table(title="🪝 Registered Hooks")
    table.add_column("Hook Name", style="cyan")
    table.add_column("Handlers", style="green", justify="right")

    for name, count in sorted(hook_list.items()):
        table.add_row(name, str(count))

    console.print(table)


@main.command()
@click.pass_context
def status(ctx):
    """Show overall plugin system status."""
    manager = ctx.obj["manager"]
    console = ctx.obj["console"]

    plugins = manager.list_plugins()
    hooks_count = sum(manager.hooks.list_hooks().values())

    enabled = sum(1 for p in plugins if p["state"] == "enabled")
    disabled = sum(1 for p in plugins if p["state"] == "disabled")
    errors = sum(1 for p in plugins if p["state"] == "error")

    console.print(Panel.fit(f"""
[bold]RoadPlugin Status[/bold]

  Plugins Loaded: [cyan]{len(plugins)}[/cyan]
  ├─ Enabled:     [green]{enabled}[/green]
  ├─ Disabled:    [yellow]{disabled}[/yellow]
  └─ Errors:      [red]{errors}[/red]

  Hooks Registered: [cyan]{hooks_count}[/cyan]
  Plugin Dirs: {', '.join(manager.loader.plugin_dirs)}
""", title="🔌 Plugin System", border_style="cyan"))


if __name__ == "__main__":
    main()

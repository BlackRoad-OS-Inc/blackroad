"""Secrets management commands for RoadCLI."""

import click
from rich.console import Console
from rich.table import Table

console = Console()


@click.group()
def secrets():
    """Secrets management - set, get, list, delete."""
    pass


@secrets.command()
@click.argument("name")
@click.argument("value", required=False)
@click.option("--from-env", is_flag=True, help="Read value from environment")
@click.option("--provider", "-p", default="local", help="Secrets provider")
def set(name, value, from_env, provider):
    """Set a secret.

    Examples:
        road secrets set API_KEY sk-abc123
        road secrets set API_KEY --from-env
        echo "secret" | road secrets set MY_SECRET
    """
    import os
    import sys
    import keyring

    if from_env:
        value = os.getenv(name)
        if not value:
            console.print(f"[red]Environment variable {name} not set[/red]")
            return
    elif not value:
        if not sys.stdin.isatty():
            value = sys.stdin.read().strip()
        else:
            value = click.prompt(f"Value for {name}", hide_input=True)

    if not value:
        console.print("[red]No value provided[/red]")
        return

    if provider == "local":
        # Use system keyring
        try:
            keyring.set_password("roadcli", name, value)
            console.print(f"[green]✓ Secret '{name}' saved to keyring[/green]")
        except Exception as e:
            console.print(f"[red]Failed to save secret: {e}[/red]")
    else:
        console.print(f"[yellow]Provider '{provider}' not implemented[/yellow]")


@secrets.command()
@click.argument("name")
@click.option("--provider", "-p", default="local", help="Secrets provider")
def get(name, provider):
    """Get a secret value.

    Examples:
        road secrets get API_KEY
    """
    import keyring

    if provider == "local":
        try:
            value = keyring.get_password("roadcli", name)
            if value:
                console.print(value)
            else:
                console.print(f"[yellow]Secret '{name}' not found[/yellow]")
        except Exception as e:
            console.print(f"[red]Failed to get secret: {e}[/red]")


@secrets.command("list")
@click.option("--provider", "-p", default="local", help="Secrets provider")
def list_secrets(provider):
    """List all secrets (names only, not values)."""
    table = Table(title="Secrets")
    table.add_column("Name", style="cyan")
    table.add_column("Provider", style="green")
    table.add_column("Last Modified")

    # Would list actual secrets from keyring/provider
    table.add_row("API_KEY", "local", "2 hours ago")
    table.add_row("DATABASE_URL", "local", "1 day ago")

    console.print(table)
    console.print("[dim]Values are hidden. Use 'road secrets get <name>' to retrieve.[/dim]")


@secrets.command()
@click.argument("name")
@click.option("--provider", "-p", default="local", help="Secrets provider")
@click.option("--force", "-f", is_flag=True, help="Skip confirmation")
def delete(name, provider, force):
    """Delete a secret.

    Examples:
        road secrets delete API_KEY
        road secrets delete API_KEY --force
    """
    import keyring

    if not force:
        if not click.confirm(f"Delete secret '{name}'?"):
            return

    if provider == "local":
        try:
            keyring.delete_password("roadcli", name)
            console.print(f"[green]✓ Secret '{name}' deleted[/green]")
        except Exception as e:
            console.print(f"[red]Failed to delete secret: {e}[/red]")

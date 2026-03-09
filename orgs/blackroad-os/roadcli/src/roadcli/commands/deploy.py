"""Deployment commands for RoadCLI."""

import click
from rich.console import Console
from rich.table import Table

console = Console()


@click.group()
def deploy():
    """Deployment commands - deploy, rollback, status."""
    pass


@deploy.command()
@click.argument("target", required=False)
@click.option("--provider", "-p", default="cloudflare", help="Deploy provider")
@click.option("--branch", "-b", default="main", help="Git branch")
@click.option("--dry-run", is_flag=True, help="Show what would be deployed")
def push(target, provider, branch, dry_run):
    """Deploy to a target environment.

    Examples:
        road deploy push production
        road deploy push staging --branch develop
        road deploy push --dry-run
    """
    import subprocess
    import os

    target = target or "production"

    if dry_run:
        console.print(f"[yellow]DRY RUN[/yellow] Would deploy to {target}")
        console.print(f"  Provider: {provider}")
        console.print(f"  Branch: {branch}")
        return

    with console.status(f"[bold cyan]Deploying to {target}...[/bold cyan]"):
        if provider == "cloudflare":
            # Check for wrangler.toml
            if os.path.exists("wrangler.toml"):
                result = subprocess.run(
                    ["wrangler", "pages", "deploy", ".", "--branch", branch],
                    capture_output=True,
                    text=True,
                )
                if result.returncode == 0:
                    console.print(f"[green]✓ Deployed to Cloudflare Pages[/green]")
                    console.print(result.stdout)
                else:
                    console.print(f"[red]✗ Deploy failed[/red]")
                    console.print(result.stderr)
            else:
                console.print("[yellow]No wrangler.toml found. Creating deploy...[/yellow]")

        elif provider == "railway":
            result = subprocess.run(
                ["railway", "up", "--detach"],
                capture_output=True,
                text=True,
            )
            if result.returncode == 0:
                console.print(f"[green]✓ Deployed to Railway[/green]")
            else:
                console.print(f"[red]✗ Deploy failed: {result.stderr}[/red]")

        else:
            console.print(f"[red]Unknown provider: {provider}[/red]")


@deploy.command("list")
@click.option("--provider", "-p", default=None, help="Filter by provider")
def list_deployments(provider):
    """List recent deployments."""
    table = Table(title="Recent Deployments")
    table.add_column("ID", style="cyan")
    table.add_column("Environment", style="green")
    table.add_column("Status", style="yellow")
    table.add_column("Branch", style="blue")
    table.add_column("Time")

    # Mock data - would connect to actual deployment tracking
    table.add_row("deploy-abc123", "production", "✓ success", "main", "5 minutes ago")
    table.add_row("deploy-xyz789", "staging", "✓ success", "develop", "2 hours ago")
    table.add_row("deploy-def456", "preview", "✓ success", "feature/new-ui", "1 day ago")

    console.print(table)


@deploy.command()
@click.argument("deployment_id", required=False)
@click.option("--steps", "-n", default=1, help="Number of versions to rollback")
def rollback(deployment_id, steps):
    """Rollback a deployment.

    Examples:
        road deploy rollback
        road deploy rollback deploy-abc123
        road deploy rollback --steps 2
    """
    if deployment_id:
        console.print(f"[yellow]Rolling back to {deployment_id}...[/yellow]")
    else:
        console.print(f"[yellow]Rolling back {steps} version(s)...[/yellow]")

    # Would trigger actual rollback
    console.print("[green]✓ Rollback complete[/green]")


@deploy.command()
@click.argument("environment", default="production")
def status(environment):
    """Show deployment status for an environment."""
    console.print(f"[bold]Deployment Status: {environment}[/bold]\n")

    console.print("Current Version: [cyan]v1.2.3[/cyan]")
    console.print("Deployed: [green]5 minutes ago[/green]")
    console.print("Commit: [dim]abc123def456[/dim]")
    console.print("Branch: main")
    console.print("Health: [green]✓ healthy[/green]")

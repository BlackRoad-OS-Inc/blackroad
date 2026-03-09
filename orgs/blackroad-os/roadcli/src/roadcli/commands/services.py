"""Service management commands for RoadCLI."""

import click
from rich.console import Console
from rich.table import Table

console = Console()


@click.group()
def services():
    """Service management - status, logs, restart."""
    pass


@services.command()
@click.argument("service", required=False)
def status(service):
    """Show service status.

    Examples:
        road services status
        road services status api-gateway
    """
    table = Table(title="Service Status")
    table.add_column("Service", style="cyan")
    table.add_column("Status", style="green")
    table.add_column("Health")
    table.add_column("Uptime")
    table.add_column("CPU")
    table.add_column("Memory")

    # Mock data - would connect to actual service monitoring
    services_data = [
        ("api-gateway", "running", "✓", "3d 4h", "12%", "256MB"),
        ("roadai", "running", "✓", "2d 8h", "45%", "1.2GB"),
        ("auth-service", "running", "✓", "5d 12h", "8%", "128MB"),
        ("worker-1", "running", "✓", "1d 6h", "67%", "512MB"),
        ("redis", "running", "✓", "10d 3h", "5%", "64MB"),
    ]

    for svc in services_data:
        if service is None or service == svc[0]:
            table.add_row(*svc)

    console.print(table)


@services.command()
@click.argument("service")
@click.option("--lines", "-n", default=50, help="Number of lines")
@click.option("--follow", "-f", is_flag=True, help="Follow log output")
def logs(service, lines, follow):
    """View service logs.

    Examples:
        road services logs api-gateway
        road services logs roadai --follow
        road services logs worker-1 -n 100
    """
    console.print(f"[bold]Logs for {service}[/bold] (last {lines} lines)\n")

    # Mock log output
    log_lines = [
        "[2026-01-11 04:30:01] INFO  Starting service...",
        "[2026-01-11 04:30:02] INFO  Loading configuration",
        "[2026-01-11 04:30:03] INFO  Connecting to database",
        "[2026-01-11 04:30:04] INFO  Database connected",
        "[2026-01-11 04:30:05] INFO  Server listening on :8000",
        "[2026-01-11 04:31:00] INFO  Request: GET /health 200 2ms",
        "[2026-01-11 04:31:15] INFO  Request: POST /api/chat 200 1243ms",
        "[2026-01-11 04:31:30] INFO  Request: GET /health 200 1ms",
    ]

    for line in log_lines[-lines:]:
        console.print(line)

    if follow:
        console.print("\n[dim]Following logs... (Ctrl+C to stop)[/dim]")


@services.command()
@click.argument("service")
@click.option("--force", "-f", is_flag=True, help="Force restart")
def restart(service, force):
    """Restart a service.

    Examples:
        road services restart api-gateway
        road services restart worker-1 --force
    """
    if not force:
        if not click.confirm(f"Restart {service}?"):
            return

    with console.status(f"[bold cyan]Restarting {service}...[/bold cyan]"):
        import time
        time.sleep(2)  # Simulate restart

    console.print(f"[green]✓ {service} restarted[/green]")


@services.command()
@click.argument("service")
def stop(service):
    """Stop a service."""
    if not click.confirm(f"Stop {service}?"):
        return

    console.print(f"[yellow]Stopping {service}...[/yellow]")
    console.print(f"[green]✓ {service} stopped[/green]")


@services.command()
@click.argument("service")
def start(service):
    """Start a service."""
    console.print(f"[cyan]Starting {service}...[/cyan]")
    console.print(f"[green]✓ {service} started[/green]")

"""AI commands for RoadCLI."""

import click
import httpx
from rich.console import Console
from rich.markdown import Markdown
from rich.live import Live
from rich.spinner import Spinner

console = Console()


@click.group()
def ai():
    """AI model commands - chat, complete, embed."""
    pass


@ai.command()
@click.argument("message", required=False)
@click.option("--model", "-m", default="gpt-4o-mini", help="Model to use")
@click.option("--system", "-s", default=None, help="System prompt")
@click.option("--server", default="http://localhost:8000", help="RoadAI server URL")
@click.option("--stream", is_flag=True, help="Stream response")
@click.pass_context
def chat(ctx, message, model, system, server, stream):
    """Chat with an AI model.

    Examples:
        road ai chat "What is Python?"
        road ai chat --model claude-3.5-sonnet "Explain async/await"
        echo "Summarize this" | road ai chat
    """
    import sys

    # Get message from argument or stdin
    if not message:
        if not sys.stdin.isatty():
            message = sys.stdin.read().strip()
        else:
            message = click.prompt("Message")

    if not message:
        console.print("[red]No message provided[/red]")
        return

    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": message})

    try:
        with console.status(f"[bold cyan]Thinking ({model})...[/bold cyan]"):
            response = httpx.post(
                f"{server}/v1/chat/completions",
                json={
                    "model": model,
                    "messages": messages,
                    "stream": stream,
                },
                timeout=120.0,
            )
            response.raise_for_status()

        data = response.json()
        content = data["choices"][0]["message"]["content"]

        # Render as markdown
        console.print(Markdown(content))

        # Show usage
        if ctx.obj.get("verbose"):
            usage = data.get("usage", {})
            console.print(f"\n[dim]Model: {data['model']} via {data['provider']}[/dim]")
            console.print(f"[dim]Tokens: {usage.get('total_tokens', 0)}[/dim]")
            if usage.get("estimated_cost_usd"):
                console.print(f"[dim]Cost: ${usage['estimated_cost_usd']:.6f}[/dim]")

    except httpx.HTTPError as e:
        console.print(f"[red]Error: {e}[/red]")
        raise click.Abort()


@ai.command()
@click.option("--server", default="http://localhost:8000", help="RoadAI server URL")
def models(server):
    """List available AI models."""
    from rich.table import Table

    try:
        response = httpx.get(f"{server}/providers", timeout=10.0)
        response.raise_for_status()
        data = response.json()

        table = Table(title="Available Models")
        table.add_column("Model", style="cyan")
        table.add_column("Provider", style="green")

        for model, provider in sorted(data.get("models", {}).items()):
            table.add_row(model, provider)

        console.print(table)

    except httpx.HTTPError as e:
        console.print(f"[red]Error: {e}[/red]")


@ai.command()
@click.option("--server", default="http://localhost:8000", help="RoadAI server URL")
def health(server):
    """Check AI provider health."""
    try:
        response = httpx.get(f"{server}/health", timeout=10.0)
        response.raise_for_status()
        data = response.json()

        status = data.get("status", "unknown")
        color = "green" if status == "healthy" else "yellow" if status == "degraded" else "red"

        console.print(f"Status: [{color}]{status}[/{color}]")
        console.print("Providers:")
        for name, healthy in data.get("providers", {}).items():
            icon = "✓" if healthy else "✗"
            color = "green" if healthy else "red"
            console.print(f"  [{color}]{icon} {name}[/{color}]")

    except httpx.HTTPError as e:
        console.print(f"[red]✗ Server unreachable: {e}[/red]")

"""Compatibility wrapper exposing the primary BlackRoad Typer application."""
from cli.console import app

cli = app


def main() -> None:
    """Invoke the Typer application."""
    app()


__all__ = ["cli", "main"]

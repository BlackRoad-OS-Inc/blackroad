"""Consent-specific CLI commands for the Prism console."""

from __future__ import annotations

import json
from datetime import datetime
from typing import List, Optional

import typer

from orchestrator import ConsentRegistry
from orchestrator.exceptions import ConsentError


def _exit_with_consent_error(error: Exception) -> None:
    typer.secho(f"Consent error: {error}", fg=typer.colors.RED, err=True)
    raise typer.Exit(code=1)


def register_consent_commands(app: typer.Typer) -> None:
    """Attach consent commands to an existing Typer application."""

    @app.command("consent:request")
    def consent_request(
        from_agent: str = typer.Option(..., "--from", help="Requesting agent"),
        to_agent: str = typer.Option(..., "--to", help="Receiving agent"),
        consent_type: str = typer.Option(..., "--type", help="Consent category"),
        purpose: str = typer.Option(..., help="Purpose for the consent"),
        duration: Optional[str] = typer.Option(
            None, help="Duration (e.g. 4h, 2d). Leave empty for open consent."
        ),
        scope: List[str] = typer.Option(
            [],
            help="Scope entries that limit the consent (repeatable)",
            show_default=False,
        ),
    ) -> None:
        registry = ConsentRegistry.get_default()
        try:
            request_id = registry.request_consent(
                from_agent=from_agent,
                to_agent=to_agent,
                consent_type=consent_type,
                purpose=purpose,
                duration=duration,
                scope=scope or None,
            )
        except (ConsentError, ValueError, TypeError) as exc:
            _exit_with_consent_error(exc)
            return

        request = registry.get_request(request_id)
        typer.echo(request.to_natural_language())
        typer.echo(f"request_id={request_id}")

    @app.command("consent:grant")
    def consent_grant(
        request: str = typer.Option(..., "--request", help="Consent request identifier"),
        condition: List[str] = typer.Option(
            [], "--condition", help="Condition to attach", show_default=False
        ),
        expires_in: Optional[str] = typer.Option(
            None, help="Relative expiry such as 1h or 2d"
        ),
        expires_at: Optional[str] = typer.Option(
            None, help="Absolute expiry timestamp (ISO 8601)"
        ),
        revocable: bool = typer.Option(True, help="Whether the grant can be revoked"),
    ) -> None:
        registry = ConsentRegistry.get_default()
        absolute_expiry = None
        if expires_at:
            try:
                absolute_expiry = datetime.fromisoformat(expires_at)
            except ValueError as exc:
                _exit_with_consent_error(exc)
                return
        try:
            grant_id = registry.grant_consent(
                request,
                conditions=condition,
                expires_in=expires_in,
                expires_at=absolute_expiry,
                revocable=revocable,
            )
        except (ConsentError, ValueError, TypeError) as exc:
            _exit_with_consent_error(exc)
            return
        typer.echo(f"grant_id={grant_id}")

    @app.command("consent:revoke")
    def consent_revoke(
        grant: str = typer.Option(..., "--grant", help="Consent grant identifier"),
        reason: Optional[str] = typer.Option(None, help="Reason for revocation"),
    ) -> None:
        registry = ConsentRegistry.get_default()
        try:
            registry.revoke_consent(grant, reason=reason)
        except ConsentError as exc:
            _exit_with_consent_error(exc)
            return
        typer.echo(f"revoked={grant}")

    @app.command("consent:audit")
    def consent_audit(
        agent: Optional[str] = typer.Option(None, help="Filter audit log by agent"),
        limit: int = typer.Option(20, help="Number of entries to display"),
    ) -> None:
        registry = ConsentRegistry.get_default()
        entries = registry.audit(agent)
        if not entries:
            typer.echo("No consent activity recorded")
            return
        for entry in entries[-limit:]:
            typer.echo(json.dumps(entry, indent=2, sort_keys=True))


def build_cli_app() -> typer.Typer:
    """Return a standalone Typer app containing only consent commands."""

    app = typer.Typer()
    register_consent_commands(app)
    return app


__all__ = ["register_consent_commands", "build_cli_app"]


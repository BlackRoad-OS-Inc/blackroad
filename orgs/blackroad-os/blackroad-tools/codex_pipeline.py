"""Lightweight Codex deployment pipeline helpers.

The original module accumulated several overlapping implementations during
merges.  The current version keeps a compact, well-defined surface that the
rest of the repository (and tests) exercise:

* small wrappers for shell commands used during deploys
* a deterministic `validate_services` helper that records health checks
* a CLI that can run the push/refresh/rebase flows with optional dry-run
"""

from __future__ import annotations

import argparse
import json
import logging
import shlex
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict
from urllib import request
from typing import Any, Callable, Dict
from urllib import request

import requests

# ---------------------------------------------------------------------------
# Logging and constants
ERROR_LOG = Path("pipeline_errors.log")
BACKUP_ROOT = Path("/var/backups/blackroad")
LATEST_BACKUP = BACKUP_ROOT / "latest"
DROPLET_BACKUP = BACKUP_ROOT / "droplet"
LOG_FILE = Path(__file__).resolve().parent.parent / "pipeline_validation.log"

LOGGER = logging.getLogger(__name__)
if not LOGGER.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(levelname)s %(message)s"))
    LOGGER.addHandler(handler)
LOGGER.setLevel(logging.INFO)

LOG_FILE = Path("pipeline_validation.log")


# ---------------------------------------------------------------------------
# Shell helpers

def run(cmd: str, *, dry_run: bool = False) -> None:
    """Log ``cmd`` and execute it unless ``dry_run`` is enabled."""

    LOGGER.info("[cmd] %s", cmd)
    if dry_run:
        return
    subprocess.run(cmd, shell=True, check=True)


def push_latest(*, dry_run: bool = False) -> None:
    """Push local commits to GitHub."""

    run("git push origin HEAD", dry_run=dry_run)


def refresh_working_copy(*, repo_path: str = ".", dry_run: bool = False) -> None:
    """Fast-forward the local checkout (Working Copy mirror stand-in)."""

    quoted = shlex.quote(repo_path)
    run(f"git -C {quoted} pull --ff-only", dry_run=dry_run)


def redeploy_droplet(*, dry_run: bool = False) -> None:
    """Placeholder for the droplet deployment command."""

    run("redeploy-droplet", dry_run=dry_run)


# ---------------------------------------------------------------------------
# Health checks

def _log_health(name: str, status: str) -> None:
    """Append a single-line status entry to ``LOG_FILE``."""

    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.utcnow().isoformat()
    with LOG_FILE.open("a", encoding="utf-8") as handle:
        handle.write(f"{timestamp} {name} {status}\n")


def _check_service(name: str, url: str) -> str:
    """Return ``OK`` when a JSON health endpoint reports status ``ok``."""

    status = "FAIL"
    try:
        with request.urlopen(url, timeout=5) as resp:  # noqa: S310 - integration style check
            if resp.getcode() == 200:
                payload = json.loads(resp.read().decode() or "{}")
                status = "OK" if payload.get("status") == "ok" else "FAIL"
    except Exception:  # noqa: BLE001 - used for resilience in tests
        status = "FAIL"

    _log_health(name, status)
    return status


def validate_services() -> Dict[str, str]:
    """Check core services and return their status summary."""

    services = {
        "frontend": "https://blackroad.io/health",
        "api": "http://127.0.0.1:4000/api/health",
        "llm": "http://127.0.0.1:8000/health",
        "math": "http://127.0.0.1:8500/health",
    }

    summary = {name: _check_service(name, url) for name, url in services.items()}
    summary["timestamp"] = datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    LOGGER.info("Service validation: %s", summary)
    return summary


# ---------------------------------------------------------------------------
# CLI

def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="BlackRoad Codex pipeline")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Log actions without executing shell commands",
    )
    parser.add_argument(
        "--skip-validate",
        action="store_true",
        help="Skip health checks after running a command",
    )

    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("push", help="Push commits and redeploy the droplet")
    sub.add_parser("refresh", help="Pull latest changes before redeploying")
    sub.add_parser("rebase", help="Rebase on origin before redeploying")
    return parser


def _call_with_optional_dry_run(func, *, dry_run: bool) -> None:
    """Invoke ``func`` passing ``dry_run`` only when needed."""

    if dry_run:
        func(dry_run=True)
    else:
        func()


def _run_command(command: str, *, dry_run: bool) -> None:
    if command == "push":
        _call_with_optional_dry_run(push_latest, dry_run=dry_run)
        _call_with_optional_dry_run(redeploy_droplet, dry_run=dry_run)
    elif command == "refresh":
        _call_with_optional_dry_run(push_latest, dry_run=dry_run)
        _call_with_optional_dry_run(refresh_working_copy, dry_run=dry_run)
        _call_with_optional_dry_run(redeploy_droplet, dry_run=dry_run)
    elif command == "rebase":
        run("git pull --rebase", dry_run=dry_run)
        _call_with_optional_dry_run(push_latest, dry_run=dry_run)
        _call_with_optional_dry_run(redeploy_droplet, dry_run=dry_run)
    else:  # pragma: no cover - parser enforces valid choices
        raise ValueError(f"Unknown command: {command}")

        "--dry-run", action="store_true", help="Simulate actions without executing commands"
    )
    parser.add_argument(
        "--skip-validate", action="store_true", help="Skip service health validation"
    )

def main(argv: list[str] | None = None) -> int:
    """CLI entry point used by tests and manual runs."""

    parser = _build_parser()
    args = parser.parse_args(argv)

    _run_command(args.command, dry_run=args.dry_run)

    if args.dry_run or args.skip_validate:
        return 0

    summary = validate_services()
    failed = [name for name, status in summary.items() if name != "timestamp" and status != "OK"]
    return 1 if failed else 0


if __name__ == "__main__":  # pragma: no cover - manual invocation
if __name__ == "__main__":
    raise SystemExit(main())

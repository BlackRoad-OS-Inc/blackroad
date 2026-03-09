#!/usr/bin/env python3
"""Summarise environment manifests for automation tooling.

This helper reads the YAML manifests under ``environments/`` and produces a
concise JSON or text summary that other scripts (or humans) can consume when
wiring deploy workflows, approvals, or health checks.

Examples
--------
# Emit JSON for all environments
python tools/environments_summary.py

# Print a human readable view for staging only
python tools/environments_summary.py --env stg --format text
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_DIR = REPO_ROOT / "environments"


def _load_manifest(path: Path) -> Dict[str, Any]:
    raw = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    raw.setdefault("name", path.stem)
    raw.setdefault("slug", raw.get("name", path.stem))
    raw.setdefault("state", "unknown")
    raw.setdefault("description", "")
    raw["_file"] = str(path.relative_to(REPO_ROOT))
    return raw


def _iter_manifests() -> Iterable[Dict[str, Any]]:
    for manifest in sorted(MANIFEST_DIR.glob("*.y*ml")):
        yield _load_manifest(manifest)


def _summarise_manifest(data: Dict[str, Any]) -> Dict[str, Any]:
    automation = data.get("automation", {})
    deployments = data.get("deployments", [])
    infrastructure = data.get("infrastructure", {})

    workflows = []
    for wf in automation.get("workflows", []) or []:
        workflows.append(
            {
                "name": wf.get("name"),
                "file": wf.get("file"),
                "triggers": wf.get("triggers", []),
                "secrets_required": wf.get("secrets_required", []),
                "variables_required": wf.get("variables_required", []),
                "summary": wf.get("summary"),
            }
        )

    services = []
    for dep in deployments:
        services.append(
            {
                "service": dep.get("service"),
                "type": dep.get("type"),
                "provider": dep.get("provider"),
                "state": dep.get("state", data.get("state")),
                "workflow": dep.get("workflow"),
                "domain": dep.get("domain") or dep.get("domain_pattern"),
                "terraform_directory": dep.get("terraform_directory"),
                "terraform_backend": dep.get("terraform_backend"),
                "module": dep.get("module"),
                "notes": dep.get("notes"),
                "health_check": dep.get("health_check"),
            }
        )

    terraform = infrastructure.get("terraform", {})
    return {
        "name": data.get("name"),
        "slug": data.get("slug"),
        "state": data.get("state"),
        "description": data.get("description", ""),
        "file": data.get("_file"),
        "contacts": data.get("contacts", {}),
        "domains": data.get("domains", {}),
        "workflows": workflows,
        "services": services,
        "infrastructure": {
            "cloud": infrastructure.get("cloud"),
            "region": infrastructure.get("region"),
            "terraform_root": terraform.get("root"),
            "terraform_backend": terraform.get("backend"),
        },
        "required_checks": automation.get("required_checks", {}),
        "change_management": data.get("change_management", {}),
        "observability": data.get("observability", {}),
    }


def _format_required_checks(
    payload: Dict[str, Any],
    *,
    indent: str = "    ",
    depth: int = 1,
) -> List[str]:
    lines: List[str] = []
    prefix = indent * depth
    for key, value in payload.items():
        if isinstance(value, dict):
            lines.append(f"{prefix}{key}:")
            lines.extend(
                _format_required_checks(
                    value,
                    indent=indent,
                    depth=depth + 1,
                )
            )
        else:
            if isinstance(value, list):
                rendered = ", ".join(str(item) for item in value)
            else:
                rendered = str(value)
            lines.append(f"{prefix}{key}: {rendered}")
    return lines


def _render_text(summaries: Iterable[Dict[str, Any]]) -> str:
    lines: List[str] = []
    for env in summaries:
        header = f"{env['name']} ({env['slug']}) — {env['state']} — {env['file']}"
        lines.append(header)
        if env.get("description"):
            lines.append(f"  {env['description']}")
        if env.get("domains"):
            formatted_domains = ", ".join(f"{k}: {v}" for k, v in env["domains"].items())
            lines.append(f"  Domains: {formatted_domains}")
        if env.get("workflows"):
            lines.append("  Workflows:")
            for wf in env["workflows"]:
                triggers = ", ".join(wf.get("triggers") or [])
                trigger_text = f" ({triggers})" if triggers else ""
                suffix_parts = []
                if wf.get("secrets_required"):
                    suffix_parts.append(
                        "secrets=" + ", ".join(wf["secrets_required"])
                    )
                if wf.get("variables_required"):
                    suffix_parts.append(
                        "vars=" + ", ".join(wf["variables_required"])
                    )
                suffix = f" [{' | '.join(suffix_parts)}]" if suffix_parts else ""
                lines.append(
                    f"    - {wf.get('name')} [{wf.get('file')}]" + trigger_text
                    + suffix
                )
        if env.get("required_checks"):
            lines.append("  Required checks:")
            lines.extend(
                _format_required_checks(env["required_checks"], depth=2)
            )
        if env.get("services"):
            lines.append("  Services:")
            for svc in env["services"]:
                detail_parts = [
                    svc.get("type"),
                    svc.get("provider"),
                    f"state={svc.get('state')}" if svc.get("state") else None,
                ]
                detail = ", ".join(part for part in detail_parts if part)
                domain = f" → {svc['domain']}" if svc.get("domain") else ""
                workflow = (
                    f" (workflow: {svc['workflow']})" if svc.get("workflow") else ""
                )
                lines.append(
                    f"    - {svc.get('service')}"
                    + (f" — {detail}" if detail else "")
                    + domain
                    + workflow
                )
                if svc.get("health_check"):
                    health = svc["health_check"]
                    if isinstance(health, list):
                        for check in health:
                            lines.append(f"      health: {check}")
                    else:
                        lines.append(f"      health: {health}")
        infra = env.get("infrastructure") or {}
        terraform_root = infra.get("terraform_root")
        if terraform_root:
            lines.append(f"  Terraform root: {terraform_root}")
        if infra.get("terraform_backend"):
            lines.append(
                f"  Terraform backend: {infra['terraform_backend']}"
            )
        if env.get("observability"):
            verification = env["observability"].get("verification")
            if verification:
                lines.append("  Verification:")
                for command in verification:
                    lines.append(f"    - {command}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def parse_args(argv: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Summarise environment manifests for automation tooling."
    )
    parser.add_argument(
        "--env",
        "-e",
        dest="env",
        help="Filter by environment slug (e.g. prod, stg, pr)",
    )
    parser.add_argument(
        "--format",
        "-f",
        choices=["json", "text"],
        default="json",
        help="Output format (default: json)",
    )
    return parser.parse_args(argv)


def main(argv: List[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])

    manifests = [_summarise_manifest(m) for m in _iter_manifests()]
    if args.env:
        manifests = [m for m in manifests if m.get("slug") == args.env]
        if not manifests:
            print(f"No environment manifest found for slug '{args.env}'.", file=sys.stderr)
            return 1

    if args.format == "json":
        json.dump({"environments": manifests}, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        sys.stdout.write(_render_text(manifests))
    return 0


if __name__ == "__main__":
    sys.exit(main())

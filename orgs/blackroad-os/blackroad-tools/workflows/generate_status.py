#!/usr/bin/env python3
"""Generate a markdown summary of GitHub workflows."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
WORKFLOW_DIR = REPO_ROOT / ".github" / "workflows"
CODEOWNERS_PATH = REPO_ROOT / "CODEOWNERS"


@dataclass
class WorkflowSummary:
    name: str
    path: Path
    triggers: str
    owners: str
    permissions: str
    compliance: str


def load_codeowners() -> List[tuple[str, List[str]]]:
    if not CODEOWNERS_PATH.exists():
        return []

    entries: List[tuple[str, List[str]]] = []
    for line in CODEOWNERS_PATH.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        pattern, owners = parts[0], parts[1:]
        entries.append((pattern, owners))
    return entries


def match_owners(path: Path, entries: Iterable[tuple[str, List[str]]]) -> List[str]:
    matches: List[str] = []
    workflow_rel = path.as_posix()
    for pattern, owners in entries:
        if Path(workflow_rel).match(pattern.lstrip("/")):
            matches = owners
    return matches


def parse_permissions(data: Dict) -> str:
    permissions = data.get("permissions")
    if not permissions:
        return "(default)"
    if isinstance(permissions, str):
        return permissions
    rendered = ", ".join(f"{key}:{value}" for key, value in permissions.items())
    return rendered or "(default)"


def _trigger_block(data: Dict) -> Dict | List | str | None:
    if "on" in data:
        return data["on"]
    if True in data:
        return data[True]
    return None


def describe_triggers(data: Dict) -> str:
    triggers = _trigger_block(data)
    if not triggers:
        return "(none)"
    if isinstance(triggers, list):
        return ", ".join(str(item) for item in triggers)
    if isinstance(triggers, dict):
        return ", ".join(triggers.keys())
    return str(triggers)


def determine_compliance(data: Dict) -> str:
    permissions = data.get("permissions")
    has_permissions = isinstance(permissions, dict) and "contents" in permissions
    has_concurrency = "concurrency" in data or any(
        isinstance(job, dict) and job.get("concurrency")
        for job in data.get("jobs", {}).values()
        if isinstance(job, dict)
    )
    if has_permissions and has_concurrency:
        return "Compliant"
    if has_permissions:
        return "Needs concurrency"
    return "Needs permissions"


def collect_workflows() -> List[WorkflowSummary]:
    entries = load_codeowners()
    summaries: List[WorkflowSummary] = []
    for workflow_path in sorted(WORKFLOW_DIR.glob("*.yml")):
        try:
            data = yaml.safe_load(workflow_path.read_text()) or {}
            parse_error = None
        except yaml.YAMLError as exc:  # pragma: no cover - defensive
            data = {}
            parse_error = str(exc).split("\n", 1)[0]
        name = data.get("name", workflow_path.stem)
        triggers = describe_triggers(data)
        owners = ", ".join(match_owners(workflow_path.relative_to(REPO_ROOT), entries)) or "(unassigned)"
        permissions = parse_permissions(data)
        compliance = determine_compliance(data)
        if parse_error:
            compliance = f"Invalid YAML: {parse_error}"
        summaries.append(
            WorkflowSummary(
                name=name,
                path=workflow_path.relative_to(REPO_ROOT),
                triggers=triggers,
                owners=owners,
                permissions=permissions,
                compliance=compliance,
            )
        )
    return summaries


def build_markdown(summaries: Iterable[WorkflowSummary]) -> str:
    rows = [
        "| Workflow | File | Triggers | Owners | Permissions | Compliance |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for summary in summaries:
        rows.append(
            "| {name} | `{path}` | {triggers} | {owners} | {permissions} | {compliance} |".format(
                name=summary.name,
                path=summary.path,
                triggers=summary.triggers,
                owners=summary.owners,
                permissions=summary.permissions,
                compliance=summary.compliance,
            )
        )
    rows.append("")
    rows.append("> _Last updated by automation. Recent run insights require GitHub API access._")
    return "\n".join(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate automation status report")
    parser.add_argument("--output", default="AUTOMATION_STATUS.md")
    args = parser.parse_args()

    summaries = collect_workflows()
    output_path = REPO_ROOT / args.output
    output_path.write_text(build_markdown(summaries))


if __name__ == "__main__":
    main()

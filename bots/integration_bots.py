"""Auto-generated integration bots sourced from integration documentation.

This module reads the integration inventory documented in
``docs/BLACKROAD_OPS_INTEGRATION_PLAN.md`` and builds a `BaseBot`
implementation for every platform that appears in the table.  Each bot is
responsible for coordinating the notification and Linear hand-off loop that the
user requested when mentioning ``@blackboxprogramming``.

The bots themselves are intentionally lightweight – they capture the mention,
surface the metadata for the integration, and outline the next actions that
keep the human review loop intact without reaching out to external services.
"""

from __future__ import annotations

from pathlib import Path
import re
from typing import Dict, Iterable, List
from typing import Dict, Iterable, List, Set, Type

from orchestrator.base import BaseBot
from orchestrator.protocols import BotResponse, Task


REPO_ROOT = Path(__file__).resolve().parents[1]
INTEGRATION_PLAN_PATH = REPO_ROOT / "docs" / "BLACKROAD_OPS_INTEGRATION_PLAN.md"

PRIMARY_HANDLE = "@blackboxprogramming"
PRIMARY_TEAM = "blackboxprogramming"
PRIMARY_REPOSITORY = "blackboxprogramming/blackroad-prism-console"

MENTION_ALIASES = {
    "blackboxprogramming": PRIMARY_HANDLE,
    "@blackroad": PRIMARY_HANDLE,
    "blackroad": PRIMARY_HANDLE,
    "@copilot": PRIMARY_HANDLE,
    "copilot": PRIMARY_HANDLE,
    "@dependabot": PRIMARY_HANDLE,
    "dependabot": PRIMARY_HANDLE,
    "@cadillac": PRIMARY_HANDLE,
    "cadillac": PRIMARY_HANDLE,
    "@codex": PRIMARY_HANDLE,
    "codex": PRIMARY_HANDLE,
    "@lucidia": PRIMARY_HANDLE,
    "lucidia": PRIMARY_HANDLE,
    "@cecilia": PRIMARY_HANDLE,
    "cecilia": PRIMARY_HANDLE,
    "@gitguardian": PRIMARY_HANDLE,
    "gitguardian": PRIMARY_HANDLE,
    "@slackbot": PRIMARY_HANDLE,
    "slackbot": PRIMARY_HANDLE,
    "@slack": PRIMARY_HANDLE,
    "slack": PRIMARY_HANDLE,
    "@linear": PRIMARY_HANDLE,
    "linear": PRIMARY_HANDLE,
    "@asanabot": PRIMARY_HANDLE,
    "asanabot": PRIMARY_HANDLE,
    "@blackroadagents": PRIMARY_HANDLE,
    "blackroadagents": PRIMARY_HANDLE,
    "@blackroadbots": PRIMARY_HANDLE,
    "blackroadbots": PRIMARY_HANDLE,
    "@airtablebot": PRIMARY_HANDLE,
    "airtablebot": PRIMARY_HANDLE,
}


def _parse_integration_rows() -> List[Dict[str, str]]:
    """Parse the integration table from the master plan document."""

    rows: List[Dict[str, str]] = []
    table_started = False
    with INTEGRATION_PLAN_PATH.open(encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not table_started:
                if line.startswith("| Category | BlackRoad System |"):
                    table_started = True
                continue

            if not line:
                break

            if line.startswith("| ---"):
                continue

            # Remove leading/trailing pipes, then split the columns.
            columns = [col.strip() for col in line.strip("|").split("|")]
            if len(columns) != 5:
                continue

            category, system_cell, purpose, owner, notes = columns
            match = re.search(r"\*\*(.+?)\*\*\s*\((.+?)\)", system_cell)
            if not match:
                continue

            system_name, platform = match.groups()
            rows.append(
                {
                    "category": category,
                    "system": system_name,
                    "platform": platform,
                    "purpose": purpose,
                    "owner": owner,
                    "notes": notes,
                }
            )
    return rows


def _slugify(value: str) -> str:
    """Create a filesystem-friendly slug for artifact paths."""

    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")


def _class_name(platform: str) -> str:
    """Create a valid Python class name from the platform label."""

    parts = re.split(r"[^0-9a-zA-Z]+", platform)
    return "".join(part.capitalize() for part in parts if part) + "IntegrationBot"


def _normalize_handle(value: str) -> str | None:
    """Return the canonical BlackRoad routing handle for ``value`` if known."""

    lowered = value.lower()
    if lowered == PRIMARY_HANDLE.lower():
        return PRIMARY_HANDLE

    return MENTION_ALIASES.get(lowered)


def _collect_mentions(task: Task) -> Set[str]:
    """Return the set of canonical handles detected in the task payload."""

    detected: Set[str] = set()
    goal = task.goal.lower()
    if PRIMARY_HANDLE.lower() in goal:
        detected.add(PRIMARY_HANDLE)
    for alias, canonical in MENTION_ALIASES.items():
        if alias in goal:
            detected.add(canonical)

    context = task.context or {}
    mentions = context.get("mentions")
    if isinstance(mentions, Iterable) and not isinstance(mentions, (str, bytes)):
        for mention in mentions:
            if isinstance(mention, str):
                canonical = _normalize_handle(mention)
                if canonical:
                    detected.add(canonical)

    return detected


def _detect_mention(task: Task) -> bool:
    """Return True when a routed handle is referenced in the task."""

    return bool(_collect_mentions(task))


def _make_run(entry: Dict[str, str]):  # type: ignore[override]
    slug = _slugify(entry["platform"])

    def run(self, task: Task, _entry: Dict[str, str] = entry, _slug: str = slug) -> BotResponse:
        detected_mentions = _collect_mentions(task)
        mention_detected = bool(detected_mentions)

        if mention_detected:
            state_word = "Activated"
            summary = (
                f"{state_word} {_entry['platform']} integration loop so the team stays in sync "
                "after @blackboxprogramming is tagged."
            )
        else:
            state_word = "Ready"
            summary = (
                f"{state_word} {_entry['platform']} integration loop so the team stays in sync "
                "even before @blackboxprogramming is tagged."
            )

        steps = [
            "Capture @blackboxprogramming mention and log the request context",
            f"Notify {_entry['system']} stakeholders for visibility",
            "Draft Linear ticket with integration metadata",
            "Coordinate peer review and close the loop back in Linear",
        ]

        data = {
            "category": _entry["category"],
            "system": _entry["system"],
            "platform": _entry["platform"],
            "purpose": _entry["purpose"],
            "owner": _entry["owner"],
            "notes": _entry["notes"],
            "mention_detected": mention_detected,
            "detected_mentions": sorted(detected_mentions),
            "routing": {
                "primary_handle": PRIMARY_HANDLE,
                "team": PRIMARY_TEAM,
                "repository": PRIMARY_REPOSITORY,
            },
            "linear_payload": {
                "team": PRIMARY_TEAM,
                "title": f"{_entry['platform']} follow-up for {task.goal}",
                "tags": ["integration", _slug, "blackboxprogramming"],
                "status": "pending-review" if mention_detected else "ready",
                "tags": [
                    "integration",
                    _slug,
                    "blackboxprogramming",
                    "blackboxprogramming-routing",
                ],
                "assignee_ids": [],
                "assignee_handles": [PRIMARY_HANDLE],
                "status": "pending-review",
            },
        }

        risks = [
            "Notifications and Linear hand-off are simulated; production hooks must be configured.",
            f"Confirm {_entry['platform']} access and ownership with {_entry['owner']} before execution.",
        ]

        artifacts = [f"/artifacts/{task.id}/{_slug}-handoff.json"]

        if mention_detected:
            next_actions = [
                "Review Linear draft with assigned reviewers",
                "Provide integration feedback in-platform",
                "Comment back @blackboxprogramming in Linear once approvals land",
            ]
        else:
            next_actions = [
                "Open the Linear draft proactively so automation can proceed without waiting",
                "Keep integration context warm for rapid hand-off",
                "Confirm reviewer availability in advance",
            ]

        return BotResponse(
            task_id=task.id,
            summary=summary,
            steps=steps,
            data=data,
            risks=risks,
            artifacts=artifacts,
            next_actions=next_actions,
            ok=True,
        )

    return run


INTEGRATION_ENTRIES = _parse_integration_rows()

__all__: List[str] = []

for entry in INTEGRATION_ENTRIES:
    class_name = _class_name(entry["platform"])
    bot_cls = type(
        class_name,
        (BaseBot,),
        {
            "__doc__": (
                f"Automation loop for the {entry['platform']} integration derived from the "
                "integration master plan."
            ),
            "name": f"{entry['platform']}-BOT",
            "mission": (
                "Keep the team informed and coordinate Linear hand-offs whenever "
                "@blackboxprogramming mentions involve this integration."
            ),
            "run": _make_run(entry),
        },
    )
    bot_cls.__module__ = __name__
    globals()[class_name] = bot_cls
    __all__.append(class_name)


def integration_bot_names() -> List[str]:
    """Expose the human-readable bot names for testing and discovery."""

    return [f"{entry['platform']}-BOT" for entry in INTEGRATION_ENTRIES]


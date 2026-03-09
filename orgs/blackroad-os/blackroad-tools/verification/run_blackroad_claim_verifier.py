#!/usr/bin/env python3
"""Utility helpers for running the BlackRoad resume claim verifier."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict
from typing import Any, Dict, List, Sequence, Set
from typing import Any, Dict, Iterable

DEFAULT_CLAIMS_PATH = Path("docs/verification/blackroad_resume_claims.json")

PROMPT_TEMPLATE = """Ψ′-pre (scope):
You are the Truth Agent. Verify each resume bullet in the JSON against repo artifacts and logs. 
Return a trinary verdict per bullet: TRUE, FALSE, or NEEDS-EVIDENCE. 
Treat quantitative metrics (%, latency, grades) as NEEDS-EVIDENCE unless supported by logs/benchmarks.

Method:
1) For each bullet:
   a) Open listed files; search for named classes/functions/routes and behaviors (e.g., DistributedMemoryPalace, /chat SSE, EstimatorQNN).
   b) Cross-check with Evidence Map IDs to ensure the code paths exist and perform the claimed role.
   c) If a metric is claimed, look for benchmark/ops logs (e.g., events.log, perf/*.json, CI artifacts). 
      If none found, mark NEEDS-EVIDENCE and emit a contradiction record with 'metric_missing'.
2) Emit a table:
   - bullet_text
   - verdict (TRUE|FALSE|NEEDS-EVIDENCE)
   - supporting_snippets (file:path:line ranges)
   - contradictions[] (if any)
   - remediation (what log/benchmark to add)

Success criteria:
- No hallucinated files.
- Deterministic, reproducible outputs given the same repo state.
- All metric claims either grounded by logs or downgraded to NEEDS-EVIDENCE with a remediation step.

Ψ′-post (write):
If any verdict is FALSE, generate a minimal PR plan (file, snippet to add, test) to make it TRUE."""
from typing import Any, Dict, Iterable, List, Sequence

from prompt_templates import RESUME_VERIFICATION_PROMPT

DEFAULT_CLAIMS_PATH = Path("docs/verification/blackroad_resume_claims.json")


def load_claims(path: Path) -> Dict[str, Any]:
    """Load the verification claims JSON file."""
    content = path.read_text(encoding="utf-8")
    return json.loads(content)
    try:
        content = path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise FileNotFoundError(f"Claims file not found: {path}") from exc
    except OSError as exc:
        raise OSError(f"Failed to read claims file at {path}: {exc}") from exc

    try:
        return json.loads(content)
    except json.JSONDecodeError as exc:
        raise ValueError(f"Malformed JSON in claims file {path}: {exc}") from exc


def build_payload(claims: Dict[str, Any]) -> Dict[str, Any]:
    """Build the combined payload for the contradiction verifier."""
    return {
        "claims": claims,
        "prompt": PROMPT_TEMPLATE.strip(),
    }


def require_entity_string(claims: Dict[str, Any]) -> str:
    """Return the entity string from claims, enforcing non-empty validation."""

    entity = claims.get("entity")
    if not isinstance(entity, str) or not entity.strip():
        raise SystemExit("claims JSON must include a non-empty 'entity' string.")
    return entity.strip()


def resolve_resume_policy(claims: Dict[str, Any]) -> Dict[str, Any]:
    """Extract and validate resume verification policy metadata."""

    raw_policy = claims.get("resume_verification_policy")
    if raw_policy is None:
        return {
            "require_status": False,
            "allowed_statuses": None,
            "status_icons": {},
            "status_notes": {},
            "summary_prefix": "",
        }

    if not isinstance(raw_policy, dict):
        raise SystemExit("resume_verification_policy must be an object when provided.")

    require_status = bool(raw_policy.get("require_status", False))

    allowed_statuses_raw = raw_policy.get("allowed_statuses")
    allowed_statuses: Set[str] | None = None
    if allowed_statuses_raw is not None:
        if not isinstance(allowed_statuses_raw, list) or not all(
            isinstance(item, str) and item.strip() for item in allowed_statuses_raw
        ):
            raise SystemExit(
                "resume_verification_policy.allowed_statuses must be a list of non-empty strings."
            )
        allowed_statuses = {item for item in allowed_statuses_raw}

    status_icons_raw = raw_policy.get("status_icons", {})
    if not isinstance(status_icons_raw, dict) or not all(
        isinstance(key, str) and isinstance(value, str)
        for key, value in status_icons_raw.items()
    ):
        raise SystemExit(
            "resume_verification_policy.status_icons must map strings to strings when provided."
        )

    status_notes_raw = raw_policy.get("status_notes", {})
    if not isinstance(status_notes_raw, dict) or not all(
        isinstance(key, str) and isinstance(value, str)
        for key, value in status_notes_raw.items()
    ):
        raise SystemExit(
            "resume_verification_policy.status_notes must map strings to strings when provided."
        )

    summary_prefix_raw = raw_policy.get("summary_prefix", "")
    if summary_prefix_raw is None:
        summary_prefix = ""
    elif not isinstance(summary_prefix_raw, str):
        raise SystemExit(
            "resume_verification_policy.summary_prefix must be a string when provided."
        )
    else:
        summary_prefix = summary_prefix_raw.strip()

    return {
        "require_status": require_status,
        "allowed_statuses": allowed_statuses,
        "status_icons": status_icons_raw or {},
        "status_notes": status_notes_raw or {},
        "summary_prefix": summary_prefix,
    }


def resolve_top_resume_bullet_records(
    claims: Dict[str, Any], policy: Dict[str, Any] | None = None
) -> List[Dict[str, Any]]:
    """Return the curated top resume bullet metadata."""

    if policy is None:
        policy = resolve_resume_policy(claims)
        "prompt": RESUME_VERIFICATION_PROMPT.strip(),
    }


def resolve_top_resume_bullets(claims: Dict[str, Any]) -> List[str]:
    """Return the curated top resume bullet texts."""

    if "top_resume_bullets" in claims:
        bullets = claims["top_resume_bullets"]
        if not isinstance(bullets, list) or not all(isinstance(item, str) for item in bullets):
            raise SystemExit("top_resume_bullets must be a list of strings.")
        return [{"id": idx, "text": text} for idx, text in enumerate(bullets)]
        return bullets

    bullet_ids = claims.get("top_resume_bullet_ids")
    if bullet_ids is None:
        raise SystemExit("No top resume bullet configuration found in claims JSON.")
    if not isinstance(bullet_ids, list) or not all(isinstance(item, int) for item in bullet_ids):
        raise SystemExit("top_resume_bullet_ids must be a list of integers.")

    bullets = claims.get("bullets")
    if not isinstance(bullets, list):
        raise SystemExit("bullets section missing or invalid in claims JSON.")

    resolved: List[Dict[str, Any]] = []
    allowed_statuses: Set[str] | None = policy.get("allowed_statuses")
    status_notes: Dict[str, str] = policy.get("status_notes", {})

    for index in bullet_ids:
        try:
            bullet = bullets[index]
        except (IndexError, TypeError):
            raise SystemExit(f"top_resume_bullet_ids entry {index} is out of range.") from None
        if not isinstance(bullet, dict) or "text" not in bullet or not isinstance(bullet["text"], str):
            raise SystemExit(f"Bullet at index {index} is malformed; expected an object with a text field.")
        status = bullet.get("status")
        if policy.get("require_status") and (not isinstance(status, str) or not status.strip()):
            raise SystemExit(
                f"Bullet at index {index} must include a non-empty status when require_status is enabled."
            )

        if isinstance(status, str) and allowed_statuses is not None and status not in allowed_statuses:
            raise SystemExit(
                f"Bullet at index {index} has status '{status}' which is not permitted by the resume policy."
            )

        record: Dict[str, Any] = {"id": index, "text": bullet["text"], "status": status}
        if isinstance(status, str) and status in status_notes:
            record["status_note"] = status_notes[status]

        resolved.append(record)
    resolved: List[str] = []
    for index in bullet_ids:
        try:
            bullet = bullets[index]
        except IndexError:
            raise SystemExit(f"top_resume_bullet_ids entry {index} is out of range.") from None
        if not isinstance(bullet, dict) or "text" not in bullet or not isinstance(bullet["text"], str):
            raise SystemExit(f"Bullet at index {index} is malformed; expected an object with a text field.")
        resolved.append(bullet["text"])

    return resolved


def resolve_top_resume_bullets(claims: Dict[str, Any]) -> List[str]:
    """Return only the bullet texts from the curated resume selection."""

    records = resolve_top_resume_bullet_records(claims)
    return [record["text"] for record in records]


def validate_claims(claims: Dict[str, Any]) -> None:
    """Validate the structure of the claims payload."""

    require_entity_string(claims)
def validate_claims(claims: Dict[str, Any]) -> None:
    """Validate the structure of the claims payload."""

    entity = claims.get("entity")
    if not isinstance(entity, str) or not entity.strip():
        raise SystemExit("claims JSON must include a non-empty 'entity' string.")

    bullets = claims.get("bullets")
    if not isinstance(bullets, list) or not bullets:
        raise SystemExit("claims JSON must include a non-empty 'bullets' list.")

    for index, bullet in enumerate(bullets):
        if not isinstance(bullet, dict):
            raise SystemExit(f"Bullet at index {index} must be an object.")

        text = bullet.get("text")
        if not isinstance(text, str) or not text.strip():
            raise SystemExit(f"Bullet at index {index} must include non-empty text.")

        evidence_ids = bullet.get("evidence_ids")
        if evidence_ids is not None and (
            not isinstance(evidence_ids, list)
            or not all(isinstance(item, int) for item in evidence_ids)
        ):
            raise SystemExit(
                f"Bullet at index {index} has invalid evidence_ids; expected a list of integers."
            )

        files = bullet.get("files")
        if files is not None and (
            not isinstance(files, list) or not all(isinstance(item, str) for item in files)
        ):
            raise SystemExit(
                f"Bullet at index {index} has invalid files; expected a list of strings."
            )

        checks = bullet.get("checks")
        if checks is not None and (
            not isinstance(checks, list) or not all(isinstance(item, str) for item in checks)
        ):
            raise SystemExit(
                f"Bullet at index {index} has invalid checks; expected a list of strings."
            )

        status = bullet.get("status")
        if status is not None and not isinstance(status, str):
            raise SystemExit(f"Bullet at index {index} has invalid status; expected a string.")

    policy = resolve_resume_policy(claims)
    resolve_top_resume_bullet_records(claims, policy)
    resolve_interview_validation(claims)


def format_resume_bullets(
    bullet_records: Sequence[Dict[str, Any]],
    grouped_validation: Dict[int, Sequence[Dict[str, Any]]],
    policy: Dict[str, Any],
    entity: str,
) -> str:
    """Format the resume bullets and attach validation guidance."""

    lines: List[str] = []
    summary_prefix = policy.get("summary_prefix")
    if isinstance(summary_prefix, str) and summary_prefix:
        lines.append(summary_prefix)

    bullet_count = len(bullet_records)
    lines.append(
        f"Claim summary: {entity} — {bullet_count} Codex-governed resume bullets."
    )

    status_icons: Dict[str, str] = policy.get("status_icons", {})

    status_counts: Dict[str, int] = {}
    for record in bullet_records:
        status = record.get("status")
        if isinstance(status, str) and status:
            status_counts[status] = status_counts.get(status, 0) + 1

    if status_counts:
        summary_parts: List[str] = []
        for status in sorted(status_counts):
            icon = status_icons.get(status)
            if icon:
                summary_parts.append(f"{status_counts[status]} {icon} {status}")
            else:
                summary_parts.append(f"{status_counts[status]} {status}")
        lines.append("Verification mix: " + ", ".join(summary_parts))

    for record in bullet_records:
        status = record.get("status")
        icon = status_icons.get(status) if isinstance(status, str) else None

        if icon:
            bullet_line = f"- {icon} {record['text']}"
        else:
            bullet_line = f"- {record['text']}"

        if isinstance(status, str) and status:
            bullet_line = f"{bullet_line} ({status})"

        lines.append(bullet_line)

        status_note = record.get("status_note")
        if isinstance(status_note, str) and status_note:
            lines.append(f"  - Status note: {status_note}")

        for entry in grouped_validation.get(record["id"], []):
            lines.append(f"  - Interview probe: {entry['question']}")
            for step in entry["validation"]:
                lines.append(f"    - {step}")
            if entry["evidence_focus"]:
                focus = ", ".join(entry["evidence_focus"])
                lines.append(f"    Evidence focus: {focus}")

    resolve_top_resume_bullets(claims)
    resolve_interview_validation(claims)


def format_resume_bullets(bullets: Iterable[str]) -> str:
    """Format the resume bullets as a Markdown list."""
    lines = [f"- {bullet}" for bullet in bullets]
    return "\n".join(lines)


def resolve_interview_validation(claims: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Return interview validation guidance entries."""

    entries = claims.get("interview_validation")
    if entries is None:
        return []
    if not isinstance(entries, list):
        raise SystemExit("interview_validation must be a list when present.")

    bullets = claims.get("bullets")
    if not isinstance(bullets, list):
        raise SystemExit("bullets section missing or invalid in claims JSON.")

    resolved: List[Dict[str, Any]] = []
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            raise SystemExit(f"interview_validation entry {index} must be an object.")

        question = entry.get("question")
        if not isinstance(question, str) or not question.strip():
            raise SystemExit(
                f"interview_validation entry {index} must include a non-empty question string."
            )

        related_id = entry.get("related_bullet_id")
        if not isinstance(related_id, int):
            raise SystemExit(
                f"interview_validation entry {index} must include an integer related_bullet_id."
            )
        try:
            related_bullet = bullets[related_id]
        except (IndexError, TypeError):
        except IndexError:
            raise SystemExit(
                f"interview_validation entry {index} references bullet {related_id}, which is out of range."
            ) from None
        if not isinstance(related_bullet, dict) or "text" not in related_bullet:
            raise SystemExit(
                f"Bullet at index {related_id} is malformed; cannot resolve interview validation mapping."
            )

        validation = entry.get("validation")
        if not isinstance(validation, list) or not all(
            isinstance(item, str) and item.strip() for item in validation
        ):
            raise SystemExit(
                f"interview_validation entry {index} must include a non-empty list of validation steps."
            )

        evidence_focus = entry.get("evidence_focus")
        if evidence_focus is not None and (
            not isinstance(evidence_focus, list)
            or not all(isinstance(item, str) and item.strip() for item in evidence_focus)
        ):
            raise SystemExit(
                f"interview_validation entry {index} has invalid evidence_focus; expected a list of non-empty strings."
            )

        resolved.append(
            {
                "question": question,
                "related_bullet_id": related_id,
                "related_bullet_text": related_bullet["text"],
                "validation": validation,
                "evidence_focus": evidence_focus or [],
            }
        )

    return resolved


def format_interview_validation(entries: Sequence[Dict[str, Any]]) -> str:
    """Render interview validation guidance as Markdown."""

    if not entries:
        return ""

    lines = ["Validation Backing for Interview Probes:"]
    for index, entry in enumerate(entries, start=1):
        lines.append(f"{index}. {entry['question']}")
        lines.append(f"   Related bullet: {entry['related_bullet_text']}")
        for step in entry["validation"]:
            lines.append(f"   - {step}")
        if entry["evidence_focus"]:
            focus = ", ".join(entry["evidence_focus"])
            lines.append(f"   Evidence focus: {focus}")

    return "\n".join(lines)


def group_interview_validation_by_bullet(
    entries: Sequence[Dict[str, Any]]
) -> Dict[int, List[Dict[str, Any]]]:
    """Group interview validation entries by their related bullet id."""

    grouped: Dict[int, List[Dict[str, Any]]] = {}
    for entry in entries:
        grouped.setdefault(entry["related_bullet_id"], []).append(entry)
    return grouped


def main() -> None:
    parser = argparse.ArgumentParser(description="Emit the Ψ′ verification payload for resume claims.")
    parser.add_argument(
        "--claims",
        type=Path,
        default=DEFAULT_CLAIMS_PATH,
        help="Path to the resume claims JSON file.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Optional path to write the payload JSON. Prints to stdout when omitted.",
    )

    args = parser.parse_args()
    claims = load_claims(args.claims)
    action_group = parser.add_mutually_exclusive_group()
    action_group.add_argument(
    parser.add_argument(
        "--resume-bullets",
        action="store_true",
        help="When set, print the top resume bullets instead of the verification payload.",
    )
    action_group.add_argument(
        "--validate",
        action="store_true",
        help="Validate the claims file structure and exit without emitting the payload.",
    )

    args = parser.parse_args()
    claims = load_claims(args.claims)
    if args.validate:
        validate_claims(claims)
        print("Claims file structure verified.")
        return

    if args.resume_bullets:
        policy = resolve_resume_policy(claims)
        bullet_records = resolve_top_resume_bullet_records(claims, policy)
        validation_entries = resolve_interview_validation(claims)
        grouped_validation = group_interview_validation_by_bullet(validation_entries)
        entity = require_entity_string(claims)
        rendered = format_resume_bullets(bullet_records, grouped_validation, policy, entity)
        bullets = resolve_top_resume_bullets(claims)
        rendered = format_resume_bullets(bullets)
        validation_entries = resolve_interview_validation(claims)
        validation_section = format_interview_validation(validation_entries)
        if validation_section:
            rendered = f"{rendered}\n\n{validation_section}"

    args = parser.parse_args()
    claims = load_claims(args.claims)
    if args.resume_bullets:
        bullets = claims.get("top_resume_bullets")
        if not bullets:
            raise SystemExit(
                "No 'top_resume_bullets' section found in claims JSON.\n"
                "Please ensure your claims file includes a 'top_resume_bullets' key with a list of resume bullets.\n"
                "Example structure:\n"
                '{\n'
                '  "top_resume_bullets": [\n'
                '    "Built distributed memory palace for multi-agent chat",\n'
                '    "Reduced latency by 30% via async SSE routes",\n'
                '    "Benchmarked QNN estimator on CI artifacts"\n'
                '  ],\n'
                '  ...\n'
                '}\n'
            )
        rendered = format_resume_bullets(bullets)
        if args.output is None:
            print(rendered)
        else:
            args.output.write_text(f"{rendered}\n", encoding="utf-8")
        return

    payload = build_payload(claims)

    if args.output is None:
        print(json.dumps(payload, indent=2))
    else:
        args.output.write_text(json.dumps(payload, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()

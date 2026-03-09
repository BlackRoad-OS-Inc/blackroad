#!/usr/bin/env python3
"""Summarize remote branch hygiene for the Prism monorepo.

The script mirrors the manual workflow described in ``BRANCH_AUDIT_REPORT.md``
by enumerating all remote branches, comparing them to a base branch, and
printing a concise report (or JSON) with merge stats plus the most important
unmerged heads.  It is dependency-free so it can run inside CI jobs.
"""

from __future__ import annotations

import argparse
import dataclasses
import json
import subprocess
import sys
from datetime import datetime, timezone
from typing import List, Sequence


@dataclasses.dataclass(frozen=True)
class BranchInfo:
    name: str
    commits_ahead: int
    last_commit_at: datetime
    author: str
    subject: str

    @property
    def age_days(self) -> float:
        delta = datetime.now(timezone.utc) - self.last_commit_at
        return delta.total_seconds() / 86400


class GitError(RuntimeError):
    pass


def _run_git(args: Sequence[str], *, check: bool = True) -> str:
    """Run a git command and return stdout."""
    try:
        output = subprocess.check_output(["git", *args], stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as exc:  # pragma: no cover - pass through with context
        if not check:
            return ""
        raise GitError(f"git {' '.join(args)} failed: {exc.output.decode().strip()}") from exc
    return output.decode().strip()


def _list_refs(prefix: str) -> List[str]:
    output = _run_git([
        "for-each-ref",
        "--format=%(refname:strip=2)",
        prefix,
    ])
    branches: List[str] = []
    for line in output.splitlines():
        line = line.strip()
        if not line or " -> " in line:
            continue
        branches.append(line)
    return sorted(branches)


def _branch_list_for_state(prefix: str, base_ref: str, merged: bool) -> List[str]:
    flag = "--merged" if merged else "--no-merged"
    output = _run_git(
        [
            "for-each-ref",
            "--format=%(refname:strip=2)",
            prefix,
            flag,
            base_ref,
        ]
    )
    result: List[str] = []
    for line in output.splitlines():
        line = line.strip()
        if not line or line == base_ref or " -> " in line:
            continue
        result.append(line)
    return sorted(result)


def _branch_metadata(branch: str, base_ref: str) -> BranchInfo:
    ahead_raw = _run_git(["rev-list", "--count", f"{base_ref}..{branch}"])
    commits_ahead = int(ahead_raw or 0)
    log_line = _run_git(["log", "-1", branch, "--format=%cI%x1f%an%x1f%s"])
    ts_str, author, subject = log_line.split("\x1f")
    last_commit_at = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
    return BranchInfo(
        name=branch,
        commits_ahead=commits_ahead,
        last_commit_at=last_commit_at,
        author=author.strip(),
        subject=subject.strip(),
    )


def _format_branch_line(info: BranchInfo) -> str:
    age = f"{info.age_days:0.1f}d"
    return (
        f"- {info.name} (ahead {info.commits_ahead}, last {age}, author {info.author})\n"
        f"    {info.subject}"
    )


def audit_branches(scope: str, remote: str, base: str, limit: int) -> dict:
    if scope == "remote":
        prefix = f"refs/remotes/{remote}"
        base_ref = f"{remote}/{base}"
        verify_ref = f"{prefix}/{base}"
    else:
        prefix = "refs/heads"
        base_ref = base
        verify_ref = f"{prefix}/{base}"

    if not _run_git(["show-ref", "--verify", verify_ref], check=False):
        raise GitError(f"Missing base ref: {base_ref}")

    total = len(_list_refs(prefix))
    merged = _branch_list_for_state(prefix, base_ref, merged=True)
    unmerged = _branch_list_for_state(prefix, base_ref, merged=False)

    unmerged_info = [_branch_metadata(br, base_ref) for br in unmerged[:limit]]

    sample_unmerged = []
    for info in unmerged_info:
        entry = dataclasses.asdict(info)
        entry["last_commit_at"] = info.last_commit_at.isoformat()
        sample_unmerged.append(entry)

    return {
        "scope": scope,
        "remote": remote,
        "base": base_ref,
        "total_branches": total,
        "merged": len(merged),
        "unmerged": len(unmerged),
        "sample_unmerged": sample_unmerged,
    }


def _print_human(report: dict, limit: int) -> None:
    total = report["total_branches"]
    merged = report["merged"]
    unmerged = report["unmerged"]
    pct_merged = (merged / total * 100) if total else 0
    pct_unmerged = (unmerged / total * 100) if total else 0

    print(f"Scope: {report['scope']}")
    print(f"Remote: {report['remote']}")
    print(f"Base branch: {report['base']}")
    print(f"Total remote branches: {total}")
    print(f"Merged: {merged} ({pct_merged:.1f}%)")
    print(f"Unmerged: {unmerged} ({pct_unmerged:.1f}%)")
    print("\nTop unmerged branches:")
    if not report["sample_unmerged"]:
        print("  (none)")
        return

    for raw in report["sample_unmerged"][:limit]:
        info = BranchInfo(
            name=raw["name"],
            commits_ahead=raw["commits_ahead"],
            last_commit_at=datetime.fromisoformat(raw["last_commit_at"]),
            author=raw["author"],
            subject=raw["subject"],
        )
        print(_format_branch_line(info))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Summarize git branch hygiene")
    parser.add_argument("--remote", default="origin", help="Remote name (default: origin)")
    parser.add_argument(
        "--scope",
        choices=("remote", "local"),
        default="remote",
        help="Which ref namespace to inspect",
    )
    parser.add_argument("--base", default="main", help="Base branch name (default: main)")
    parser.add_argument(
        "--limit",
        type=int,
        default=10,
        help="Number of unmerged branches to display",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of text")
    args = parser.parse_args(argv)

    try:
        report = audit_branches(args.scope, args.remote, args.base, args.limit)
    except GitError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if args.json:
        json.dump(report, sys.stdout, indent=2, default=str)
        print()
    else:
        _print_human(report, args.limit)
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entry
    raise SystemExit(main())

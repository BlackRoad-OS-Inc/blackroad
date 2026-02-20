#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path


def run(cmd, cwd=None):
    try:
        out = subprocess.check_output(cmd, cwd=cwd, stderr=subprocess.STDOUT, text=True)
        return out.strip()
    except subprocess.CalledProcessError as exc:
        return (exc.output or "").strip()


def is_git_repo(repo_root: Path) -> bool:
    if (repo_root / ".git").exists():
        return True
    result = run(["git", "rev-parse", "--is-inside-work-tree"], cwd=repo_root)
    return result.lower() == "true"


def load_config(repo_root: Path):
    cfg_path = repo_root / ".codex" / "memory.config.json"
    if cfg_path.exists():
        try:
            return json.loads(cfg_path.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}


def safe_read_text(path: Path, max_bytes=80_000):
    try:
        data = path.read_bytes()
        data = data[:max_bytes]
        return data.decode("utf-8", errors="replace")
    except Exception:
        return ""


def collect_repo_state(repo_root: Path):
    state = {"repo_root": str(repo_root)}
    if not is_git_repo(repo_root):
        state["git"] = {"is_repo": False}
        return state

    branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=repo_root)
    status = run(["git", "status", "--porcelain"], cwd=repo_root)
    last_commit = run(["git", "log", "-1", "--pretty=format:%h|%s|%ci"], cwd=repo_root)
    recent = run(["git", "log", "-5", "--pretty=format:%h %s"], cwd=repo_root)
    status_lines = [line for line in status.splitlines() if line.strip()]

    state["git"] = {
        "is_repo": True,
        "branch": branch,
        "dirty": bool(status.strip()),
        "changed_files": len(status_lines),
        "porcelain": status_lines[:200],
        "last_commit": last_commit,
        "recent_commits": recent.splitlines(),
    }
    return state


def summarize_allowlisted_files(repo_root: Path, cfg: dict):
    """
    Only reads files explicitly allowlisted in .codex/memory.config.json
    Example:
    {
      "files": ["AGENTS.md", "README.md", "docs/plan.md"],
      "globs": ["packages/*/README.md"]
    }
    """
    files = []
    for rel in cfg.get("files", []):
        p = (repo_root / rel).resolve()
        if p.exists() and p.is_file() and str(p).startswith(str(repo_root.resolve())):
            files.append(p)

    for pattern in cfg.get("globs", []):
        for p in repo_root.glob(pattern):
            p = p.resolve()
            if p.exists() and p.is_file() and str(p).startswith(str(repo_root.resolve())):
                files.append(p)

    uniq = []
    seen = set()
    for p in files:
        if p not in seen:
            uniq.append(p)
            seen.add(p)
    uniq = uniq[:25]

    summaries = []
    for p in uniq:
        txt = safe_read_text(p)
        lines = [line.strip() for line in txt.splitlines() if line.strip()]
        head = lines[:12]
        todo = sum(1 for line in lines if "TODO" in line or "FIXME" in line)
        summaries.append({
            "path": str(p.relative_to(repo_root)),
            "todo_markers": todo,
            "head": head,
        })
    return summaries


def write_outputs(mem_dir: Path, payload: dict):
    mem_dir.mkdir(parents=True, exist_ok=True)

    (mem_dir / "session.json").write_text(
        json.dumps(payload, indent=2), encoding="utf-8"
    )

    git = payload.get("git", {})
    lines = []
    lines.append(f"# MEMORY BRIEF ({payload['timestamp']})")
    lines.append("")
    lines.append(f"- Repo: `{payload.get('repo_root','')}`")
    lines.append(f"- Session: `{payload.get('session_id','')}`  Command: `{payload.get('cmd','')}`")
    if git.get("is_repo"):
        lines.append(f"- Branch: `{git.get('branch')}`  Dirty: `{git.get('dirty')}`")
        last = git.get("last_commit", "")
        if last:
            parts = last.split("|", 2)
            if len(parts) == 3:
                lines.append(f"- Last commit: `{parts[0]}` — {parts[1]} ({parts[2]})")
    if payload.get("note"):
        lines.append(f"- Note: {payload['note']}")
    lines.append("")
    if payload.get("file_summaries"):
        lines.append("## Allowlisted file highlights")
        for file_summary in payload["file_summaries"]:
            lines.append(
                f"### {file_summary['path']} (TODO/FIXME: {file_summary['todo_markers']})"
            )
            for line in file_summary["head"]:
                lines.append(f"- {line}")
            lines.append("")
    (mem_dir / "brief.md").write_text("\n".join(lines).strip() + "\n", encoding="utf-8")

    ledger = mem_dir / "ledger.jsonl"
    with ledger.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, ensure_ascii=False) + "\n")

    return mem_dir


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cmd", required=True, choices=["start", "checkpoint"])
    parser.add_argument("--repo-root", required=True)
    parser.add_argument("--note", default="")
    parser.add_argument("--memory-dir")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    enabled_flag = repo_root / ".codex" / "memory.enabled"
    if not enabled_flag.exists():
        if args.cmd == "start":
            print("[MEMORY] disabled (create .codex/memory.enabled to enable)")
        return 0
    cfg = load_config(repo_root)

    session_id = os.environ.get("CODEX_SESSION_ID") or str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    payload = collect_repo_state(repo_root)
    payload["timestamp"] = timestamp
    payload["cmd"] = args.cmd
    payload["note"] = args.note.strip()
    payload["session_id"] = session_id
    if os.environ.get("CODEX_HOME"):
        payload["codex_home"] = os.environ.get("CODEX_HOME")

    payload["file_summaries"] = summarize_allowlisted_files(repo_root, cfg)
    payload["todo_total"] = sum(item["todo_markers"] for item in payload["file_summaries"])
    env_dir = os.environ.get("CODEX_MEMORY_DIR") or os.environ.get("MEMORY_DIR")
    memory_dir = Path(args.memory_dir or env_dir or ".codex/memory")
    if not memory_dir.is_absolute():
        memory_dir = (repo_root / memory_dir).resolve()
    repo_resolved = repo_root.resolve()
    try:
        memory_dir.relative_to(repo_resolved)
        inside_repo = True
    except ValueError:
        inside_repo = False
    if not inside_repo:
        print("[MEMORY] error: memory dir must be inside the repo root", file=sys.stderr)
        return 2
    payload["memory_dir"] = str(memory_dir)
    dry_run = args.dry_run or str(os.environ.get("MEMORY_DRY_RUN", "")).lower() in {
        "1",
        "true",
        "yes",
    }
    payload["dry_run"] = bool(dry_run)

    if not dry_run:
        mem_dir = write_outputs(memory_dir, payload)
    else:
        mem_dir = memory_dir

    git = payload.get("git", {})
    if git.get("is_repo"):
        print(
            f"[MEMORY] repo={repo_root.name} branch={git.get('branch')} clean={not git.get('dirty')}"
        )
        last = git.get("last_commit", "")
        if last:
            parts = last.split("|", 2)
            if len(parts) >= 2:
                print(f"[MEMORY] last_commit={parts[0]} \"{parts[1]}\"")
        print(
            f"[MEMORY] focus=TODO markers: {payload.get('todo_total', 0)} | "
            f"Changed files: {git.get('changed_files', 0)}"
        )
    else:
        print(f"[MEMORY] repo={repo_root.name} (not a git repo)")

    if payload["file_summaries"]:
        print(f"[MEMORY] allowlisted_files={len(payload['file_summaries'])}")

    print(f"[MEMORY] brief written: {mem_dir / 'brief.md'}")
    if dry_run:
        print("[MEMORY] dry_run=true (no files written)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

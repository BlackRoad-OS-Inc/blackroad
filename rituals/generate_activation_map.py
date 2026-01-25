#!/usr/bin/env python3
import os
import subprocess
import datetime
import pathlib
import re
import sys

def sh(cmd, cwd=None):
    result = subprocess.run(
        cmd,
        cwd=cwd,
        shell=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        error_output = result.stderr.strip()
        message = f"Error running command: {cmd}"
        if error_output:
            message = f"{message}\n{error_output}"
        print(message, file=sys.stderr)
        return ""
    return result.stdout.strip()


def harvest_repo(repo_path, default_branch, recent_hours, stale_days):
    now = datetime.datetime.utcnow()
    recent_cut = (now - datetime.timedelta(hours=recent_hours)).isoformat(timespec="seconds") + "Z"
    stale_cut_date = (now - datetime.timedelta(days=stale_days)).date()

    current = sh("git rev-parse --abbrev-ref HEAD", cwd=repo_path)
    ahead = sh(f"git rev-list --left-right --count {default_branch}...HEAD", cwd=repo_path)
    commits = sh(
        f"git log --since='{recent_cut}' --pretty='format:%h %ad %s' --date=relative",
        cwd=repo_path,
    )
    branches = sh(
        "git for-each-ref --format='%(refname:short)|%(committerdate:short)' refs/heads",
        cwd=repo_path,
    )

    stale = []
    for line in filter(None, branches.splitlines()):
        if "|" not in line:
            print(
                f"Warning: Unexpected branch info format for repo '{repo_path}': '{line}'",
                file=sys.stderr,
            )
            continue
        branch_name, last_commit_str = (part.strip() for part in line.split("|", 1))
        if branch_name == default_branch:
            continue
        try:
            last_commit_date = datetime.datetime.strptime(last_commit_str, "%Y-%m-%d").date()
        except ValueError as exc:
            print(
                f"Warning: Could not parse date for branch '{branch_name}' in repo '{repo_path}': {exc}",
                file=sys.stderr,
            )
            continue
        if last_commit_date < stale_cut_date:
            stale.append(f"{branch_name} (last: {last_commit_date.isoformat()})")

    return {
        "repo": repo_path,
        "branch": current,
        "divergence": ahead,  # "behind ahead"
        "recent_commits": commits.splitlines()[:10],
        "stale": stale[:10],
    }


def read_tasks(files):
    lines = []
    for path in files:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8", errors="ignore") as handle:
                lines.extend(line.rstrip() for line in handle if line.strip())
    # naive parse: TODO, DOING, BLOCKED
    def pick(tag):
        return [line for line in lines if re.search(fr"\b{tag}\b", line, re.IGNORECASE)]

    return {
        "now": pick("NOW|DOING|PRIORITY|P1"),
        "next": pick("TODO|NEXT|P2"),
        "blocked": pick("BLOCKED|WAITING"),
        "quick": [line for line in lines if re.search(r"\b(quick|5min|tiny)\b", line, re.IGNORECASE)],
    }


def last_reflection(path):
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8", errors="ignore") as handle:
        lines = [line.rstrip() for line in handle if line.strip()]
    return lines[-1] if lines else None


def load_yaml(path):
    import yaml

    with open(path, "r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def main(cfg_path):
    cfg = load_yaml(cfg_path)
    sections = []

    # repos
    repo_blocks = []
    for repo in cfg.get("repos", []):
        info = harvest_repo(
            repo["path"],
            repo.get("default_branch", "main"),
            cfg.get("recent_commit_hours", 24),
            cfg.get("stale_branch_days", 7),
        )
        divergence_parts = info.get("divergence", "").split()
        if len(divergence_parts) == 2 and all(part.isdigit() for part in divergence_parts):
            behind, ahead = divergence_parts
        else:
            print(
                f"Warning: Unexpected divergence format for repo '{repo['path']}': '{info.get('divergence', '')}'",
                file=sys.stderr,
            )
            behind, ahead = "0", "0"
        recent_block = "\n".join(
            f"  - {line}" for line in info["recent_commits"] if line
        ) or "  - none"
        stale_block = "\n".join(
            f"  - {line}" for line in info["stale"] if line
        ) or "  - none"
        repo_blocks.append(
            "\n".join(
                [
                    f"### {info['repo']}",
                    f"• Branch: {info['branch']}  • Divergence: -{behind}/+{ahead}",
                    "• Recent commits:",
                    recent_block,
                    f"• Stale branches (> {cfg.get('stale_branch_days', 7)}d):",
                    stale_block,
                ]
            )
        )

    sections.append("## Code\n" + "\n".join(repo_blocks))

    # tasks
    tasks = read_tasks(cfg.get("tasks_files", []))

    def bullet(title, items):
        body = "\n  - " + ("\n  - ".join(items[:10]) if items else "none")
        return f"**{title}**{body}"

    sections.append(
        "## Tasks\n"
        + "\n".join(
            [
                bullet("NOW", tasks["now"]),
                bullet("NEXT", tasks["next"]),
                bullet("BLOCKED", tasks["blocked"]),
                bullet("Quick Wins", tasks["quick"]),
            ]
        )
    )

    # reflection
    reflection = last_reflection(cfg.get("reflect_log", ""))
    sections.append("## Reflection\n" + (reflection or "none"))

    out = (
        "# Lucidia — Next‑Day Activation Map\n"
        f"Generated: {datetime.datetime.utcnow().isoformat(timespec='seconds')}Z\n\n"
        + "\n\n".join(sections)
        + "\n"
    )

    out_path = pathlib.Path(cfg["output_map"])
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(out, encoding="utf-8")
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    config_path = (
        sys.argv[1]
        if len(sys.argv) > 1
        else os.path.expanduser("~/lucidia/rituals/activation.config.yaml")
    )
    main(config_path)

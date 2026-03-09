# Purpose: Clone/pull many repos declared in config/repos.json and emit a manifest for Lucidia.
# Usage:   python3 tools/codex_multi_repo_loader.py [--config config/repos.json]
# Notes:   Supports SSH (with optional key) or HTTPS (with or without token).
import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def run(cmd, cwd=None, env=None):
    p = subprocess.Popen(
        cmd, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
    )
    out, _ = p.communicate()
    if p.returncode != 0:
        raise RuntimeError(f"Command failed ({' '.join(cmd)}):\n{out}")
    return out


def ensure_dir(p: Path):
    p.mkdir(parents=True, exist_ok=True)


def load_cfg(path: Path):
    with path.open() as f:
        return json.load(f)


def build_env(cfg):
    env = os.environ.copy()
    ssh_key = os.environ.get("CODEX_SSH_KEY") or cfg.get("git_ssh_key") or ""
    accept_new = os.environ.get("CODEX_SSH_ACCEPT_NEW", "0") == "1"
    strict = cfg.get("git_ssh_strict_hostkey", True) and not accept_new

    ssh_cmd = ["ssh"]
    if ssh_key:
        ssh_cmd += ["-i", ssh_key]
    ssh_cmd += ["-o", f"StrictHostKeyChecking={'yes' if strict else 'accept-new'}"]
    env["GIT_SSH_COMMAND"] = " ".join(ssh_cmd)

    return env


def tokenize_url(url: str, token: str) -> str:
    """Return a token-authenticated HTTPS URL.

    The function embeds ``token`` as the username portion of an HTTPS
    repository URL.  URLs that are not HTTPS, already contain user
    information, or are provided an empty ``token`` are returned
    unchanged.  This avoids producing malformed URLs such as
    ``https://@github.com/...`` or double-userinfo segments.

    Parameters
    ----------
    url: str
        The repository URL.
    token: str
        Personal access token to embed in the URL.

    Returns
    -------
    str
        URL with the token embedded for HTTPS, or the original URL when
        token authentication is not applicable.
    """

    from urllib.parse import urlparse, urlunparse

    if not token:
        return url

    parsed = urlparse(url)
    if parsed.scheme != "https" or not parsed.netloc:
        return url

    # If credentials are already present, leave the URL unchanged to
    # prevent introducing a second username segment.
    if "@" in parsed.netloc:
        return url

    netloc = f"{token}@{parsed.netloc}"
    return urlunparse(parsed._replace(netloc=netloc))


def repo_state(repo_dir: Path):
    # return current HEAD sha and branch if available
    try:
        sha = run(["git", "rev-parse", "HEAD"], cwd=repo_dir).strip()
        br = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=repo_dir).strip()
        return sha, br
    except Exception:
        return None, None


def clone_or_pull(repo, base_dir: Path, cfg, env):
    name = repo["name"]
    url = repo["url"]
    branch = repo.get("branch") or cfg.get("default_branch", "main")
    auth = repo.get("auth", "ssh")
    shallow = repo.get("shallow", False)

    repo_dir = base_dir / name
    ensure_dir(base_dir)

    # Prepare URL for token mode
    git_token = os.environ.get("GIT_TOKEN", "")
    final_url = tokenize_url(url, git_token) if auth == "token" and git_token else url

    # Clone or update
    if not repo_dir.exists():
        clone_cmd = ["git", "clone", "--branch", branch]
        if shallow:
            clone_cmd += ["--depth", "1", "--no-single-branch"]
        clone_cmd += [final_url, str(repo_dir)]
        run(clone_cmd, env=env)
        action = "cloned"
    else:
        # existing repo: fetch + checkout + pull
        # safety: ensure it's a git repo
        if not (repo_dir / ".git").exists():
            raise RuntimeError(f"{repo_dir} exists but is not a git repository")
        run(["git", "remote", "set-url", "origin", final_url], cwd=repo_dir, env=env)
        run(["git", "fetch", "origin", branch], cwd=repo_dir, env=env)
        run(["git", "checkout", branch], cwd=repo_dir, env=env)
        # prefer fast-forward only
        pull_args = ["git", "pull", "--ff-only", "origin", branch]
        if shallow:
            # make sure we have enough history for ff-only
            try:
                run(["git", "fetch", "--depth", "50", "origin", branch], cwd=repo_dir, env=env)
            except Exception:
                pass
        run(pull_args, cwd=repo_dir, env=env)
        action = "updated"

    sha, br = repo_state(repo_dir)
    return {
        "name": name,
        "path": str(repo_dir.resolve()),
        "branch": br or branch,
        "head": sha or "",
        "url": url,
        "auth": auth,
        "read_only": bool(repo.get("read_only", False)),
        "action": action,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default="config/repos.json")
    args = ap.parse_args()

    cfg_path = Path(args.config)
    if not cfg_path.exists():
        print(f"Config not found: {cfg_path}", file=sys.stderr)
        sys.exit(1)

    cfg = load_cfg(cfg_path)

    base = Path(os.environ.get("CODEX_REPOS_BASE") or cfg.get("base_dir") or "./repos").expanduser()
    ensure_dir(base)

    env = build_env(cfg)
    repos = cfg.get("repositories", [])
    if not repos:
        print("No repositories defined in config.", file=sys.stderr)
        sys.exit(2)

    results = []
    errors = []

    for r in repos:
        try:
            results.append(clone_or_pull(r, base, cfg, env))
        except Exception as e:
            errors.append({"name": r.get("name"), "url": r.get("url"), "error": str(e)})

    manifest = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "base_dir": str(base.resolve()),
        "repos": results,
        "errors": errors,
    }

    out_dir = Path("runtime/manifests")
    ensure_dir(out_dir)
    manifest_path = out_dir / "codex_repos_manifest.json"
    with manifest_path.open("w") as f:
        json.dump(manifest, f, indent=2)

    print(f"Wrote manifest: {manifest_path}")
    if errors:
        print("\nSome repositories failed to sync:")
        for e in errors:
            print(f" - {e['name']}: {e['error']}")
        sys.exit(3)


if __name__ == "__main__":
    main()

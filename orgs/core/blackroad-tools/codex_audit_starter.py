#!/usr/bin/env python3
import json, pathlib

m = json.loads(pathlib.Path("runtime/manifests/codex_repos_manifest.json").read_text())
for r in m["repos"]:
    p = pathlib.Path(r["path"])
    print(f"\n=== {r['name']} ({r['branch']}) @ {r['head'][:7]} ===")
    missing = []
    for need in [".gitignore", "README.md", "LICENSE", "SECURITY.md", ".github/workflows"]:
        if not (p / need).exists():
            missing.append(need)
    if missing:
        print("Missing:", ", ".join(missing))
    else:
        print("Baseline files present.")

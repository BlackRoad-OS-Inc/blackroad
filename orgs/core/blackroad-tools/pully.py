#!/usr/bin/env python3
"""Pully - simple Pull Request organizer.

Minimal, offline-first classifier for pull requests. It suggests labels,
reviewers and a small checklist based on a JSON configuration.

This module is intentionally dependency-free and suitable for CI dry-runs.
"""

from dataclasses import dataclass
import json
import re
from typing import Any, Dict, List, Optional


@dataclass
class PullRequest:
    title: str
    body: str
    author: str
    files: List[str]
    labels: List[str]


def load_config(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def from_pr_json(obj: Dict[str, Any]) -> PullRequest:
    return PullRequest(
        title=obj.get("title", ""),
        body=obj.get("body", ""),
        author=obj.get("author", ""),
        files=obj.get("files", []),
        labels=obj.get("labels", []),
    )


def classify_pr(pr: PullRequest, config: Dict[str, Any]) -> Dict[str, Any]:
    """Return suggested labels, reviewers and a checklist for a PR.

    Config supports label_rules, file_rules and reviewer_rules (see example JSON).
    """

    title = (pr.title or "").lower()
    body = (pr.body or "").lower()
    files = pr.files or []

    labels = set(pr.labels or [])
    reviewers = set()

    # label rules by keywords
    for r in config.get("label_rules", []):
        label = r.get("label")
        if not label:
            continue
        keywords = [k.lower() for k in r.get("keywords", [])]
        if any(k in (title + "\n" + body) for k in keywords):
            labels.add(label)

    # file based rules
    for r in config.get("file_rules", []):
        pattern = r.get("pattern")
        label = r.get("label")
        if pattern and label:
            prog = re.compile(pattern)
            if any(prog.search(f) for f in files):
                labels.add(label)

    # reviewer rules
    for r in config.get("reviewer_rules", []):
        reviewer = r.get("reviewer")
        if not reviewer:
            continue
        needed = set(r.get("labels", []))
        if needed and needed & labels:
            reviewers.add(reviewer)
            continue
        for p in r.get("paths", []):
            prog = re.compile(p)
            if any(prog.search(f) for f in files):
                reviewers.add(reviewer)
                break

    checklist = [
        ("Code builds locally", False),
        ("Tests added/updated", any(re.search(r"test|spec", f) for f in files)),
        (
            "Changelog/README updated",
            any(re.search(r"changelog|readme|docs", f, re.I) for f in files),
        ),
        ("PR description filled", bool(pr.body and pr.body.strip())),
    ]

    return {"labels": sorted(labels), "reviewers": sorted(reviewers), "checklist": checklist}


def format_output(classification: Dict[str, Any]) -> str:
    out = {
        "labels": classification["labels"],
        "reviewers": classification["reviewers"],
        "checklist": [f"[{'x' if ok else ' '}] {text}" for text, ok in classification["checklist"]],
    }
    return json.dumps(out, indent=2)


#!/usr/bin/env python3
"""Pully - simple Pull Request organizer.

Minimal, offline-first classifier for pull requests. It suggests labels,
reviewers and a small checklist based on a JSON configuration.

This module is intentionally dependency-free and suitable for CI dry-runs.
"""

from dataclasses import dataclass
import argparse
import json
import re
from typing import Any, Dict, List, Optional


@dataclass
class PullRequest:
    title: str
    body: str
    author: str
    files: List[str]
    labels: List[str]


def load_config(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def from_pr_json(obj: Dict[str, Any]) -> PullRequest:
    return PullRequest(
        title=obj.get("title", ""),
        body=obj.get("body", ""),
        author=obj.get("author", ""),
        files=obj.get("files", []),
        labels=obj.get("labels", []),
    )


def classify_pr(pr: PullRequest, config: Dict[str, Any]) -> Dict[str, Any]:
    """Return suggested labels, reviewers and a checklist for a PR.

    Config supports label_rules, file_rules and reviewer_rules (see example JSON).
    """

    title = (pr.title or "").lower()
    body = (pr.body or "").lower()
    files = pr.files or []

    labels = set(pr.labels or [])
    reviewers = set()

    # label rules by keywords
    for r in config.get("label_rules", []):
        label = r.get("label")
        if not label:
            continue
        keywords = [k.lower() for k in r.get("keywords", [])]
        if any(k in (title + "\n" + body) for k in keywords):
            labels.add(label)

    # file based rules
    for r in config.get("file_rules", []):
        pattern = r.get("pattern")
        label = r.get("label")
        if pattern and label:
            prog = re.compile(pattern)
            if any(prog.search(f) for f in files):
                labels.add(label)

    # reviewer rules
    for r in config.get("reviewer_rules", []):
        reviewer = r.get("reviewer")
        if not reviewer:
            continue
        needed = set(r.get("labels", []))
        if needed and needed & labels:
            reviewers.add(reviewer)
            continue
        for p in r.get("paths", []):
            prog = re.compile(p)
            if any(prog.search(f) for f in files):
                reviewers.add(reviewer)
                break

    checklist = [
        ("Code builds locally", False),
        ("Tests added/updated", any(re.search(r"test|spec", f) for f in files)),
        ("Changelog/README updated", any(re.search(r"changelog|readme|docs", f, re.I) for f in files)),
        ("PR description filled", bool(pr.body and pr.body.strip())),
    ]

    return {"labels": sorted(labels), "reviewers": sorted(reviewers), "checklist": checklist}


def format_output(classification: Dict[str, Any]) -> str:
    out = {
        "labels": classification["labels"],
        "reviewers": classification["reviewers"],
        "checklist": [f"[{'x' if ok else ' '}] {text}" for text, ok in classification["checklist"]],
    }
    return json.dumps(out, indent=2)


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Pully - simple PR organizer (dry-run)")
    p.add_argument("--config", required=True, help="Path to pully config json")
    p.add_argument("--pr-file", required=True, help="Path to PR json file (local) for analysis")
    p.add_argument("--output", help="Optional output path for result JSON")
    args = p.parse_args(argv)

    config = load_config(args.config)
    with open(args.pr_file, "r", encoding="utf-8") as fh:
        pr_json = json.load(fh)

    pr = from_pr_json(pr_json)
    classification = classify_pr(pr, config)
    text = format_output(classification)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as fh:
            fh.write(text)
    else:
        print(text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
        labels: List[str]

    def load_config(path: str) -> Dict[str, Any]:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)

    def from_pr_json(obj: Dict[str, Any]) -> PullRequest:
        return PullRequest(
            title=obj.get("title", ""),
            body=obj.get("body", ""),
            author=obj.get("author", ""),
            files=obj.get("files", []),
            labels=obj.get("labels", []),
        )

    def classify_pr(pr: PullRequest, config: Dict[str, Any]) -> Dict[str, Any]:
        """Return suggested labels, reviewers and a checklist for a PR.

        The config supports three top-level keys:
          - label_rules: list of {"label": str, "keywords": [str,...]}
          - file_rules: list of {"label": str, "pattern": str (regex)}
          - reviewer_rules: list of {"reviewer": str, "paths": [pattern,...], "labels": [label,...]}
        """

        title = (pr.title or "").lower()
        body = (pr.body or "").lower()
        files = pr.files or []

        #!/usr/bin/env python3
        """Pully - simple Pull Request organizer.

        Minimal, offline-first classifier for pull requests. It suggests labels,
        reviewers and a small checklist based on a JSON configuration.

        This module is intentionally dependency-free and suitable for CI dry-runs.
        """

        from dataclasses import dataclass
        import argparse
        import json
        import re
        from typing import Any, Dict, List, Optional


        @dataclass
        class PullRequest:
            title: str
            body: str
            author: str
            files: List[str]
            labels: List[str]


        def load_config(path: str) -> Dict[str, Any]:
            with open(path, "r", encoding="utf-8") as fh:
                return json.load(fh)


        def from_pr_json(obj: Dict[str, Any]) -> PullRequest:
            return PullRequest(
                title=obj.get("title", ""),
                body=obj.get("body", ""),
                author=obj.get("author", ""),
                files=obj.get("files", []),
                labels=obj.get("labels", []),
            )


        def classify_pr(pr: PullRequest, config: Dict[str, Any]) -> Dict[str, Any]:
            """Return suggested labels, reviewers and a checklist for a PR."""

            title = (pr.title or "").lower()
            body = (pr.body or "").lower()
            files = pr.files or []

            labels = set(pr.labels or [])
            reviewers = set()

            # label rules by keywords
            for r in config.get("label_rules", []):
                label = r.get("label")
                if not label:
                    continue
                keywords = [k.lower() for k in r.get("keywords", [])]
                if any(k in (title + "\n" + body) for k in keywords):
                    labels.add(label)

            # file based rules
            for r in config.get("file_rules", []):
                pattern = r.get("pattern")
                label = r.get("label")
                if pattern and label:
                    prog = re.compile(pattern)
                    if any(prog.search(f) for f in files):
                        labels.add(label)

            # reviewer rules
            for r in config.get("reviewer_rules", []):
                reviewer = r.get("reviewer")
                if not reviewer:
                    continue
                needed = set(r.get("labels", []))
                if needed and needed & labels:
                    reviewers.add(reviewer)
                    continue
                for p in r.get("paths", []):
                    prog = re.compile(p)
                    if any(prog.search(f) for f in files):
                        reviewers.add(reviewer)
                        break

            checklist = [
                ("Code builds locally", False),
                ("Tests added/updated", any(re.search(r"test|spec", f) for f in files)),
                ("Changelog/README updated", any(re.search(r"changelog|readme|docs", f, re.I) for f in files)),
                ("PR description filled", bool(pr.body and pr.body.strip())),
            ]

            return {"labels": sorted(labels), "reviewers": sorted(reviewers), "checklist": checklist}


        def format_output(classification: Dict[str, Any]) -> str:
            out = {
                "labels": classification["labels"],
                "reviewers": classification["reviewers"],
                "checklist": [f"[{'x' if ok else ' '}] {text}" for text, ok in classification["checklist"]],
            }
            return json.dumps(out, indent=2)


        def main(argv: Optional[List[str]] = None) -> int:
            p = argparse.ArgumentParser(description="Pully - simple PR organizer (dry-run)")
            p.add_argument("--config", required=True, help="Path to pully config json")
            p.add_argument("--pr-file", required=True, help="Path to PR json file (local) for analysis")
            p.add_argument("--output", help="Optional output path for result JSON")
            args = p.parse_args(argv)

            config = load_config(args.config)
            with open(args.pr_file, "r", encoding="utf-8") as fh:
                pr_json = json.load(fh)

            pr = from_pr_json(pr_json)
            classification = classify_pr(pr, config)
            text = format_output(classification)

            if args.output:
                with open(args.output, "w", encoding="utf-8") as fh:
                    fh.write(text)
            else:
                print(text)

            return 0


        if __name__ == "__main__":
            raise SystemExit(main())

            any(re.search(r"changelog|readme|docs", f, re.I) for f in files),
        )
    )
    checklist.append(("PR description filled", bool(pr.body.strip())))

    return {
        "labels": sorted(suggested_labels),
        "reviewers": sorted(suggested_reviewers),
        "checklist": checklist,
    }


def format_output(classification: Dict[str, Any]) -> str:
    out = {
        "labels": classification["labels"],
        "reviewers": classification["reviewers"],
        "checklist": [f"[{'x' if ok else ' '}] {text}" for text, ok in classification["checklist"]],
    }
    return json.dumps(out, indent=2)


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Pully - simple PR organizer (dry-run)")
    p.add_argument("--config", required=True, help="Path to pully config json")
    p.add_argument("--pr-file", required=True, help="Path to PR json file (local) for analysis")
    p.add_argument("--output", help="Optional output path for result JSON")
    args = p.parse_args(argv)

    config = load_config(args.config)
    with open(args.pr_file, "r", encoding="utf-8") as f:
        pr_json = json.load(f)

    pr = from_pr_json(pr_json)
    classification = classify_pr(pr, config)
    text = format_output(classification)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        print(text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())


@dataclass
class PullRequest:
    title: str
    body: str
    author: str
    files: List[str]
    labels: List[str]


def load_config(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def from_pr_json(obj: Dict[str, Any]) -> PullRequest:
    return PullRequest(
        title=obj.get("title", ""),
        body=obj.get("body", ""),
        author=obj.get("author", ""),
        files=obj.get("files", []),
        labels=obj.get("labels", []),
    )


def classify_pr(pr: PullRequest, config: Dict[str, Any]) -> Dict[str, Any]:
    """Return classification with suggested labels and reviewers and checklist."""
    title = pr.title.lower()
    body = pr.body.lower()
    files = pr.files

    suggested_labels = set(pr.labels or [])
    suggested_reviewers = set()

    # simple keyword -> label rules from config
    for rule in config.get("label_rules", []):
        keywords = [k.lower() for k in rule.get("keywords", [])]
        label = rule.get("label")
        if not label:
            continue
        hay = title + "\n" + body
        if any(k in hay for k in keywords):
            suggested_labels.add(label)

    # file-based rules
    for rule in config.get("file_rules", []):
        pattern = rule.get("pattern")
        label = rule.get("label")
        if pattern and label:
            prog = re.compile(pattern)
            if any(prog.search(f) for f in files):
                suggested_labels.add(label)

    # reviewer suggestions by path or label
    for r in config.get("reviewer_rules", []):
        labels_needed = set(r.get("labels", []))
        paths = r.get("paths", [])
        reviewer = r.get("reviewer")
        if reviewer is None:
            continue
        if labels_needed and labels_needed & suggested_labels:
            suggested_reviewers.add(reviewer)
            continue
        # path matching
        for p in paths:
            prog = re.compile(p)
            if any(prog.search(f) for f in files):
                suggested_reviewers.add(reviewer)
                break

    # generate checklist
    checklist: List[tuple[str, bool]] = []
    checklist.append(("Code builds locally", False))
    checklist.append(("Tests added/updated", any(re.search(r"test|spec", f) for f in files)))
    checklist.append(
        (
            "Changelog/README updated",
            any(re.search(r"changelog|readme|docs", f, re.I) for f in files),
        )
    )
    checklist.append(("PR description filled", bool(pr.body.strip())))

    return {
        "labels": sorted(suggested_labels),
        "reviewers": sorted(suggested_reviewers),
        "checklist": checklist,
    }


def format_output(classification: Dict[str, Any]) -> str:
    out = {
        "labels": classification["labels"],
        "reviewers": classification["reviewers"],
        "checklist": [f"[{'x' if ok else ' '}] {text}" for text, ok in classification["checklist"]],
    }
    return json.dumps(out, indent=2)


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Pully - simple PR organizer (dry-run)")
    p.add_argument("--config", required=True, help="Path to pully config json")
    p.add_argument("--pr-file", required=True, help="Path to PR json file (local) for analysis")
    p.add_argument("--output", help="Optional output path for result JSON")
    args = p.parse_args(argv)

    config = load_config(args.config)
    with open(args.pr_file, "r", encoding="utf-8") as f:
        pr_json = json.load(f)

    pr = from_pr_json(pr_json)
    classification = classify_pr(pr, config)
    text = format_output(classification)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        print(text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
from __future__ import annotations

#!/usr/bin/env python3
"""
Pully - simple Pull Request organizer

This small utility classifies a PR into labels, reviewers, and generates a checklist
to help automate PR fulfillment and organization. It intentionally has no network
dependence so it can be used in CI or locally as a dry-run.

Usage (dry-run):
    python tools/pully.py --config tools/pully_config.example.json --pr-file example_pr.json

The PR file is a JSON object with keys: title, body, author, files (list of paths), labels (opt list)
"""

import argparse
import json
import re
from dataclasses import dataclass
from typing import Dict, List, Any, Optional

#!/usr/bin/env python3
"""
Pully - simple Pull Request organizer

This small utility classifies a PR into labels, reviewers, and generates a checklist
to help automate PR fulfillment and organization. It intentionally has no network
dependence so it can be used in CI or locally as a dry-run.

Usage (dry-run):
  python tools/pully.py --config tools/pully_config.example.json --pr-file example_pr.json

The PR file is a JSON object with keys: title, body, author, files (list of paths), labels (opt list)
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from typing import Dict, List, Any, Optional


@dataclass
class PullRequest:
    title: str
    body: str
    author: str
    files: List[str]
    labels: List[str]


def load_config(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def from_pr_json(obj: Dict[str, Any]) -> PullRequest:
    return PullRequest(
        title=obj.get("title", ""),
        body=obj.get("body", ""),
        author=obj.get("author", ""),
        files=obj.get("files", []),
        labels=obj.get("labels", []),
    )


def classify_pr(pr: PullRequest, config: Dict[str, Any]) -> Dict[str, Any]:
    """Return classification with suggested labels and reviewers and checklist."""
    title = pr.title.lower()
    body = pr.body.lower()
    files = pr.files

    suggested_labels = set(pr.labels or [])
    suggested_reviewers = set()

    # simple keyword -> label rules from config
    for rule in config.get("label_rules", []):
        keywords = [k.lower() for k in rule.get("keywords", [])]
        label = rule.get("label")
        if not label:
            continue
        hay = title + "\n" + body
        if any(k in hay for k in keywords):
            suggested_labels.add(label)

    # file-based rules
    for rule in config.get("file_rules", []):
        pattern = rule.get("pattern")
        label = rule.get("label")
        if pattern and label:
            prog = re.compile(pattern)
            if any(prog.search(f) for f in files):
                suggested_labels.add(label)

    # reviewer suggestions by path or label
    for r in config.get("reviewer_rules", []):
        labels_needed = set(r.get("labels", []))
        paths = r.get("paths", [])
        reviewer = r.get("reviewer")
        if reviewer is None:
            continue
        if labels_needed and labels_needed & suggested_labels:
            suggested_reviewers.add(reviewer)
            continue
        # path matching
        for p in paths:
            prog = re.compile(p)
            if any(prog.search(f) for f in files):
                suggested_reviewers.add(reviewer)
                break

    # generate checklist
    checklist = []
    checklist.append(("Code builds locally", False))
    checklist.append(("Tests added/updated", any(re.search(r"test|spec", f) for f in files)))
    checklist.append(
        (
            "Changelog/README updated",
            any(re.search(r"changelog|readme|docs", f, re.I) for f in files),
        )
    )
    checklist.append(("PR description filled", bool(pr.body.strip())))

    return {
        "labels": sorted(suggested_labels),
        "reviewers": sorted(suggested_reviewers),
        "checklist": checklist,
    }


def format_output(classification: Dict[str, Any]) -> str:
    out = {
        "labels": classification["labels"],
        "reviewers": classification["reviewers"],
        "checklist": [f"[{'x' if ok else ' '}] {text}" for text, ok in classification["checklist"]],
    }
    return json.dumps(out, indent=2)


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Pully - simple PR organizer (dry-run)")
    p.add_argument("--config", required=True, help="Path to pully config json")
    p.add_argument("--pr-file", required=True, help="Path to PR json file (local) for analysis")
    p.add_argument("--output", help="Optional output path for result JSON")
    args = p.parse_args(argv)

    config = load_config(args.config)
    with open(args.pr_file, "r", encoding="utf-8") as f:
        pr_json = json.load(f)

    pr = from_pr_json(pr_json)
    classification = classify_pr(pr, config)
    text = format_output(classification)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        print(text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Materialize the Codex-0 "Lucidia Origin" seed into runnable prompt assets."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, Iterable

import yaml
from yaml.dumper import SafeDumper


class _LiteralSafeDumper(SafeDumper):
    """YAML dumper that preserves multi-line strings using block style."""


def _literal_str_representer(dumper: SafeDumper, data: str):  # type: ignore[override]
    if "\n" in data:
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
    return dumper.represent_scalar("tag:yaml.org,2002:str", data)


_LiteralSafeDumper.add_representer(str, _literal_str_representer)

REPO_ROOT = Path(__file__).resolve().parents[1]
SEED_FALLBACK_DIR = Path(__file__).resolve().parent / "seeds"


class SeedValidationError(RuntimeError):
    """Raised when the seed definition is incomplete or malformed."""


def _resolve_seed_path(seed_arg: str) -> Path:
    """Resolve the seed path, searching the Lucidia seeds directory if needed."""
    candidate = Path(seed_arg)
    search_order: Iterable[Path]

    if candidate.is_absolute():
        search_order = (candidate,)
    else:
        search_order = (
            Path.cwd() / candidate,
            SEED_FALLBACK_DIR / candidate,
            SEED_FALLBACK_DIR / candidate.name,
        )

    for path in search_order:
        if path.exists():
            return path

    raise FileNotFoundError(
        f"Seed file '{seed_arg}' not found. Checked: "
        + ", ".join(str(p) for p in search_order)
    )


def _resolve_emit_dir(emit_arg: str) -> Path:
    """Resolve the emit directory, normalising absolute paths into the repo root."""
    if not emit_arg:
        raise ValueError("Emit directory argument cannot be empty.")

    if emit_arg.startswith("/"):
        # Treat leading slash as repo-relative for portability across environments.
        relative = emit_arg.lstrip("/")
        target = REPO_ROOT / relative
    else:
        target = Path(emit_arg)
        if not target.is_absolute():
            target = Path.cwd() / target

    target.mkdir(parents=True, exist_ok=True)
    return target


def _require_keys(data: Dict[str, Any], keys: Iterable[str], context: str) -> None:
    missing = [key for key in keys if key not in data]
    if missing:
        raise SeedValidationError(f"Missing {context} field(s): {', '.join(missing)}")


def _load_seed(path: Path) -> Dict[str, Any]:
    """Load and validate the YAML seed definition."""
    with path.open("r", encoding="utf-8") as handle:
        payload = yaml.safe_load(handle) or {}

    if not isinstance(payload, dict):
        raise SeedValidationError("Seed file must contain a mapping at the top level.")

    _require_keys(
        payload,
        ["title", "identifier", "purpose", "charter", "directives", "core_tasks", "io", "seed_language", "boot_command"],
        "top-level",
    )

    charter = payload["charter"]
    if not isinstance(charter, dict):
        raise SeedValidationError("'charter' section must be a mapping.")
    _require_keys(
        charter,
        ["agent_name", "generation", "domain", "moral_constant", "core_principle"],
        "charter",
    )

    if not isinstance(payload["directives"], list) or not payload["directives"]:
        raise SeedValidationError("'directives' must be a non-empty list.")
    if not isinstance(payload["core_tasks"], list) or not payload["core_tasks"]:
        raise SeedValidationError("'core_tasks' must be a non-empty list.")

    io_section = payload["io"]
    if not isinstance(io_section, dict):
        raise SeedValidationError("'io' section must be a mapping with 'input' and 'output'.")
    _require_keys(io_section, ["input", "output"], "io")

    return payload


def _build_prompt(seed: Dict[str, Any]) -> str:
    """Construct the formatted prompt text from the seed components."""
    charter = seed["charter"]
    icon = seed.get("icon", "")
    header = seed["title"]
    if seed.get("identifier"):
        header = f"{header} ({seed['identifier']})"
    if icon:
        header = f"{header} {icon}"

    lines = [header, "", f"Purpose: {seed['purpose'].strip()}" if isinstance(seed['purpose'], str) else "Purpose:"]

    lines.extend(
        [
            "",
            "System Charter:",
            f"  Agent Name: {charter['agent_name']}",
            f"  Generation: {charter['generation']}",
            f"  Domain: {charter['domain']}",
            f"  Moral Constant: {charter['moral_constant']}",
            f"  Core Principle: {charter['core_principle']}",
        ]
    )

    lines.append("")
    lines.append("Directives:")
    for idx, directive in enumerate(seed["directives"], start=1):
        lines.append(f"  {idx}. {directive}")

    lines.append("")
    lines.append("Core Tasks:")
    for idx, task in enumerate(seed["core_tasks"], start=1):
        lines.append(f"  {idx}. {task}")

    io_section = seed["io"]
    lines.extend(
        [
            "",
            "Input / Output:",
            f"  Input: {io_section['input']}",
            f"  Output: {io_section['output']}",
        ]
    )

    seed_language = seed["seed_language"].strip("\n")
    lines.append("")
    lines.append("Seed Language:")
    for line in seed_language.splitlines():
        lines.append(f"  {line}")

    lines.extend(["", f"Boot Command: {seed['boot_command']}"])

    return "\n".join(lines).strip() + "\n"


def _write_yaml_prompt(emit_dir: Path, stem: str, prompt: str, seed: Dict[str, Any]) -> Path:
    output = {
        "agent": seed["charter"]["agent_name"],
        "identifier": seed.get("identifier"),
        "generation": seed["charter"]["generation"],
        "domain": seed["charter"]["domain"],
        "prompt": prompt,
        "meta": {
            "icon": seed.get("icon"),
            "purpose": seed["purpose"],
            "directives": seed["directives"],
            "core_tasks": seed["core_tasks"],
            "moral_constant": seed["charter"]["moral_constant"],
            "core_principle": seed["charter"]["core_principle"],
            "io": seed["io"],
            "seed_language": seed["seed_language"],
            "boot_command": seed["boot_command"],
        },
    }

    yaml_path = emit_dir / f"{stem}.yaml"
    with yaml_path.open("w", encoding="utf-8") as handle:
        yaml.dump(
            output,
            handle,
            Dumper=_LiteralSafeDumper,
            sort_keys=False,
            allow_unicode=True,
        )
    return yaml_path


def _write_manifest(emit_dir: Path, stem: str, seed: Dict[str, Any], prompt_path: Path) -> Path:
    manifest = {
        "title": seed["title"],
        "identifier": seed.get("identifier"),
        "charter": seed["charter"],
        "directives": seed["directives"],
        "core_tasks": seed["core_tasks"],
        "io": seed["io"],
        "seed_language": seed["seed_language"],
        "boot_command": seed["boot_command"],
        "prompt_file": prompt_path.name,
    }

    manifest_path = emit_dir / f"{stem}_manifest.json"
    with manifest_path.open("w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2, ensure_ascii=False)
    return manifest_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Emit the Codex-0 Lucidia Origin prompt assets.")
    parser.add_argument(
        "--seed",
        default="codex0.yaml",
        help="Seed definition file (defaults to codex0.yaml, searched relative to lucidia/seeds).",
    )
    parser.add_argument(
        "--emit",
        default="codex/prompts/next",
        help="Directory to write generated artifacts (defaults to codex/prompts/next).",
    )
    parser.add_argument(
        "--stem",
        default="codex0_lucidia_origin",
        help="Filename stem for generated artifacts (defaults to codex0_lucidia_origin).",
    )
    args = parser.parse_args()

    seed_path = _resolve_seed_path(args.seed)
    emit_dir = _resolve_emit_dir(args.emit)
    seed = _load_seed(seed_path)
    prompt_text = _build_prompt(seed)

    prompt_path = _write_yaml_prompt(emit_dir, args.stem, prompt_text, seed)
    manifest_path = _write_manifest(emit_dir, args.stem, seed, prompt_path)

    print(f"[codex-0] Seed loaded from {seed_path}")
    print(f"[codex-0] Prompt written to {prompt_path}")
    print(f"[codex-0] Manifest written to {manifest_path}")


if __name__ == "__main__":
    main()

from __future__ import annotations

from importlib import import_module
from typing import Iterable


def ensure_modules(mod_paths: Iterable[str]) -> None:
    """
    Import a list of modules to ensure class/function symbols are registered.

    Example:
        ensure_modules([
            "codex.operator_definition",
            "codex.truth_table",
        ])
    """
    for path in mod_paths:
        import_module(path)

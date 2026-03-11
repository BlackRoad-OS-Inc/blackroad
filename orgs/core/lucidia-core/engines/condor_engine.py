"""Wrappers for running NASA Condor models locally.

The helpers here expose a minimal, import-safe subset of Condor's
functionality so tests can exercise code paths without requiring the full
dependency. The real Condor package is optional at import time; calling
these helpers will raise ``RuntimeError`` if Condor is not installed.
"""

from __future__ import annotations

import ast
import importlib.util
import sys
import tempfile
from dataclasses import asdict, is_dataclass
from pathlib import Path
from types import ModuleType
from typing import Any, Dict, Optional, Type

try:  # pragma: no cover - optional dependency
    import numpy as np  # type: ignore
except Exception:  # pragma: no cover
    np = None  # type: ignore

try:  # pragma: no cover - optional dependency
    import condor  # type: ignore
except Exception:  # pragma: no cover
    condor = None  # type: ignore

CONDOR_PACKAGE_PREFIX = "condor"

ALLOWED_IMPORTS = {"condor", "math", "numpy", "dataclasses"}
FORBIDDEN_NAMES = {"open", "os", "sys", "subprocess", "socket", "eval", "exec", "__import__"}


def _to_primitive(obj: Any) -> Any:
    """Recursively convert dataclasses and numpy arrays into primitives."""
    if is_dataclass(obj):
        return {k: _to_primitive(v) for k, v in asdict(obj).items()}
    if np is not None and isinstance(obj, np.ndarray):
        return obj.tolist()
    if isinstance(obj, dict):
        return {k: _to_primitive(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple, set)):
        return [_to_primitive(v) for v in obj]
    return obj


def validate_model_source(py_text: str) -> None:
    """Validate a user-supplied model source string using conservative static analysis."""
    tree = ast.parse(py_text)
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                if alias.name.split(".")[0] not in ALLOWED_IMPORTS:
                    raise ValueError(f"Disallowed import: {alias.name}")
        elif isinstance(node, ast.ImportFrom):
            if (node.module or "").split(".")[0] not in ALLOWED_IMPORTS:
                raise ValueError(f"Disallowed import: {node.module}")
        elif isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
            if node.func.id in FORBIDDEN_NAMES:
                raise ValueError(f"Forbidden call: {node.func.id}")
        elif isinstance(node, ast.Name):
            if node.id in FORBIDDEN_NAMES:
                raise ValueError(f"Forbidden name: {node.id}")
        elif isinstance(node, ast.Attribute):
            if node.attr.startswith("__"):
                raise ValueError("Dunder attribute access is forbidden")


def _load_module_from_source(source: str, module_name: str) -> ModuleType:
    """Load a module from source text in an isolated temporary directory."""
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / f"{module_name}.py"
        path.write_text(source, encoding="utf-8")
        spec = importlib.util.spec_from_file_location(module_name, path)
        if spec is None or spec.loader is None:  # pragma: no cover
            raise ImportError("Unable to create import spec")
        module = importlib.util.module_from_spec(spec)
        sys.modules[module_name] = module
        spec.loader.exec_module(module)
        return module


def load_model_from_source(py_text: str, class_name: str) -> Type[Any]:
    """Validate and load a model class from source code."""
    validate_model_source(py_text)
    module = _load_module_from_source(py_text, "user_model")
    return getattr(module, class_name)


def solve_algebraic(model_cls: Type[Any], **params: Any) -> Dict[str, Any]:
    """Instantiate ``model_cls`` and call its ``solve`` method."""
    if condor is None and model_cls.__module__.split(".")[0] == CONDOR_PACKAGE_PREFIX:
        raise RuntimeError("Condor is not installed")

    model = model_cls(**params)
    result = model.solve() if hasattr(model, "solve") else model
    return _to_primitive(result)


def simulate_ode(
    model_cls: Type[Any],
    t_final: float,
    initial: Any,
    params: Optional[Dict[str, Any]] = None,
    events: Any = None,
    modes: Any = None,
) -> Dict[str, Any]:
    """Simulate an ``ODESystem`` until ``t_final``."""
    model = model_cls(**(params or {}))
    if hasattr(model, "simulate"):
        result = model.simulate(t_final, initial, events=events, modes=modes)
    else:  # pragma: no cover
        result = {}
    return _to_primitive(result)


def optimize(
    problem_cls: Type[Any],
    initial_guess: Any,
    bounds: Any = None,
    options: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Solve an optimisation problem if ``problem_cls`` implements ``solve``."""
    problem = problem_cls()
    if hasattr(problem, "solve"):
        result = problem.solve(initial_guess, bounds=bounds, options=options)
    else:  # pragma: no cover
        result = {}
    return _to_primitive(result)


__all__ = [
    "load_model_from_source",
    "optimize",
    "simulate_ode",
    "solve_algebraic",
    "validate_model_source",
]

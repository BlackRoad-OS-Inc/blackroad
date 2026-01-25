"""Quantum ML module for Lucidia.

This package is optional and guarded by the ``LUCIDIA_QML`` environment
variable. Only local simulators are used; remote providers are disabled
when ``LUCIDIA_QML_REMOTE`` is unset or false.
"""

from __future__ import annotations

import os
from typing import Dict, Type

from .backends import AerCPUBackend, QuantumBackend

_QML_ENABLED = os.getenv("LUCIDIA_QML", "off").lower() in {"1", "true", "on"}
_REMOTE_OK = os.getenv("LUCIDIA_QML_REMOTE", "false").lower() in {"1", "true", "on"}

# Registry of available backends
_BACKENDS: Dict[str, Type[QuantumBackend]] = {"aer_cpu": AerCPUBackend}


def is_enabled() -> bool:
    """Return True if the Quantum ML feature flag is on."""

    return _QML_ENABLED


def get_backend(name: str = "aer_cpu") -> QuantumBackend:
    """Instantiate and return a backend by name.

    Parameters
    ----------
    name:
        Registered backend key. Defaults to ``aer_cpu``.
    """

    if not _QML_ENABLED:
        raise RuntimeError("Quantum ML disabled")
    if not _REMOTE_OK and name not in _BACKENDS:
        raise RuntimeError("Remote backends are disabled")
    backend_cls = _BACKENDS.get(name)
    if backend_cls is None:
        raise ValueError(f"Unknown backend '{name}'")
    return backend_cls()

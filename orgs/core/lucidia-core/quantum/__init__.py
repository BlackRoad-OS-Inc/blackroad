"""Quantum ML module for Lucidia.

This package is optional and guarded by the ``LUCIDIA_QML`` environment
variable. Only local simulators are used; remote providers are disabled
when ``LUCIDIA_QML_REMOTE`` is unset or false.
"""

from __future__ import annotations

import os
from typing import Dict, Optional, Type

_QML_ENABLED = os.getenv("LUCIDIA_QML", "off").lower() in {"1", "true", "on"}
_REMOTE_OK = os.getenv("LUCIDIA_QML_REMOTE", "false").lower() in {"1", "true", "on"}

# Backends are imported lazily so that missing optional dependencies (qiskit,
# qiskit-aer) result in a graceful skip rather than a hard ImportError when
# the module is merely collected by pytest or imported on a machine without
# the quantum extras installed.
try:
    from .backends import AerCPUBackend, QuantumBackend as _QuantumBackend

    _BACKENDS: Dict[str, Type[_QuantumBackend]] = {"aer_cpu": AerCPUBackend}
    _BACKENDS_AVAILABLE = True
except ImportError:
    _BACKENDS = {}  # type: ignore[assignment]
    _BACKENDS_AVAILABLE = False


def is_enabled() -> bool:
    """Return True if the Quantum ML feature flag is on."""

    return _QML_ENABLED


def get_backend(name: str = "aer_cpu"):
    """Instantiate and return a backend by name.

    Parameters
    ----------
    name:
        Registered backend key. Defaults to ``aer_cpu``.
    """

    if not _QML_ENABLED:
        raise RuntimeError("Quantum ML disabled")
    if not _BACKENDS_AVAILABLE:
        raise ImportError(
            "Quantum backends are unavailable; install the quantum extras (qiskit, qiskit-aer)."
        )
    if not _REMOTE_OK and name not in _BACKENDS:
        raise RuntimeError("Remote backends are disabled")
    backend_cls = _BACKENDS.get(name)
    if backend_cls is None:
        raise ValueError(f"Unknown backend '{name}'")
    return backend_cls()

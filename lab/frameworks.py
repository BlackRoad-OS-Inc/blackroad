"""Runtime selection of math array backends."""

from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from typing import Any, List, Optional


@dataclass(frozen=True)
class MathBackend:
    """Description of an available array backend."""

    name: str
    array_module: Any
    description: str
    supports_autodiff: bool


@lru_cache()
def _discover_backends() -> List[MathBackend]:
    backends: List[MathBackend] = []
    try:
        import jax
        import jax.numpy as jnp

        backends.append(
            MathBackend(
                name="jax",
                array_module=jnp,
                description=f"JAX {jax.__version__} (autodiff)",
                supports_autodiff=True,
            )
        )
    except Exception:  # pragma: no cover - optional dependency
        pass

    import numpy as np

    backends.append(
        MathBackend(
            name="numpy",
            array_module=np,
            description=f"NumPy {np.__version__}",
            supports_autodiff=False,
        )
    )
    return backends


def available_backends() -> List[MathBackend]:
    """Return the detected math backends."""

    return list(_discover_backends())


def backend_names() -> List[str]:
    """Return backend names in preference order (JAX first when present)."""

    discovered = available_backends()
    preferred = ["jax", "numpy"]
    names = [backend.name for backend in discovered]
    ordered = [name for name in preferred if name in names]
    ordered.extend(name for name in names if name not in ordered)
    return ordered


def select_backend(name: Optional[str] = None) -> MathBackend:
    """Return the requested backend (defaults to the first available)."""

    discovered = available_backends()
    if not discovered:
        raise RuntimeError("No math backends detected")
    if name is None:
        return discovered[0]
    for backend in discovered:
        if backend.name == name:
            return backend
    raise ValueError(f"Unknown math backend {name!r}")


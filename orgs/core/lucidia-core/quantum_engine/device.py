"""Device wrapper around the active quantum backend."""
from __future__ import annotations

from .backends import get_backend
from .policy import guard_env, set_seed


class Device:
    """Lightweight wrapper providing deterministic setup and QASM export."""

    def __init__(
        self,
        n_wires: int,
        bsz: int = 1,
        device: str = "cpu",
        seed: int | None = None,
        backend: str | None = None,
    ) -> None:
        guard_env()
        set_seed(seed)
        self.backend = get_backend(backend)
        self.qdev = self.backend.create_device(n_wires=n_wires, bsz=bsz, device=device)

    def qasm(self) -> str:
        """Return a QASM-like string of the executed operations."""

        exporter = self.backend.qasm_exporter
        if exporter is not None:
            return exporter(self.qdev)
        if hasattr(self.qdev, "qasm"):
            return self.qdev.qasm()
        raise RuntimeError(f"Backend {self.backend.name!r} does not support QASM export")

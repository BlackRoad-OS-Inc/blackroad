"""Runtime selection of quantum simulation backends."""

from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
import importlib
import importlib.util
from typing import Callable, Dict, List, Optional


@dataclass(frozen=True)
class QuantumBackend:
    """Metadata describing an available quantum simulation backend."""

    name: str
    description: str
    create_device: Callable[[int, int, str], object]
    qasm_exporter: Optional[Callable[[object], str]] = None

    def summary(self) -> str:
        """Return a compact human readable description."""

        return f"{self.name}: {self.description}"


def _register_torchquantum(registry: Dict[str, QuantumBackend]) -> None:
    from third_party import torchquantum as tq

    version = getattr(tq, "__version__", "vendored")

    def _create_device(n_wires: int, bsz: int = 1, device: str = "cpu") -> object:
        return tq.QuantumDevice(n_wires=n_wires, bsz=bsz, device=device)

    def _export_qasm(device: object) -> str:
        if hasattr(device, "qasm"):
            return device.qasm()  # type: ignore[no-any-return]
        return ""

    registry["torchquantum"] = QuantumBackend(
        name="torchquantum",
        description=f"TorchQuantum ({version}) batch-friendly simulator",
        create_device=_create_device,
        qasm_exporter=_export_qasm,
    )


def _register_pennylane(registry: Dict[str, QuantumBackend]) -> None:
    if importlib.util.find_spec("pennylane") is None:
        return

    import pennylane as qml
    import numpy as _np
    import torch

    version = getattr(qml, "__version__", "unknown")
    gate_map = {"rx": qml.RX, "ry": qml.RY, "rz": qml.RZ}

    class _PennyLaneDevice:
        """Lightweight adapter exposing a TorchQuantum-like interface."""

        def __init__(self, n_wires: int, bsz: int = 1, device: str = "cpu") -> None:
            if bsz != 1:
                raise ValueError("Pennylane backend currently supports batch size 1")
            self.n_wires = n_wires
            self._qml = qml
            self._device = qml.device("default.qubit", wires=n_wires)
            self._ops: List[tuple[str, tuple[int, ...], Optional[float]]] = []

        def apply(self, name: str, mat, wire, params=None) -> None:  # pragma: no cover - thin adapter
            wires: tuple[int, ...]
            if isinstance(wire, (list, tuple)):
                wires = tuple(int(w) for w in wire)
            else:
                wires = (int(wire),)
            theta: Optional[float] = None
            if params:
                theta = float(params[0])
            self._ops.append((name.lower(), wires, theta))

        def measure_all(self):  # pragma: no cover - thin adapter
            qml = self._qml
            ops = list(self._ops)

            @qml.qnode(self._device)
            def circuit():
                for opname, wires, theta in ops:
                    gate = gate_map.get(opname)
                    if gate is None:
                        raise ValueError(f"Unsupported gate {opname!r} for pennylane backend")
                    kwargs = {"wires": wires if len(wires) > 1 else wires[0]}
                    if theta is None:
                        gate(**kwargs)
                    else:
                        gate(theta, **kwargs)
                return [qml.expval(qml.PauliZ(w)) for w in range(self.n_wires)]

            values = circuit()
            array = _np.asarray(values, dtype=_np.float32)
            return torch.from_numpy(array).reshape(1, -1)

        def qasm(self) -> str:  # pragma: no cover - string formatting helper
            lines: List[str] = []
            for opname, wires, theta in self._ops:
                targets = ",".join(f"q[{w}]" for w in wires)
                gate = opname.upper()
                if theta is None:
                    lines.append(f"{gate} {targets}")
                else:
                    lines.append(f"{gate}({theta}) {targets}")
            return "\n".join(lines)

    registry["pennylane"] = QuantumBackend(
        name="pennylane",
        description=f"Pennylane ({version}) analytic simulator",
        create_device=lambda n_wires, bsz=1, device="cpu": _PennyLaneDevice(n_wires, bsz, device),
        qasm_exporter=lambda dev: dev.qasm(),
    )


def _register_qiskit(registry: Dict[str, QuantumBackend]) -> None:
    if importlib.util.find_spec("qiskit") is None:
        return

    try:  # pragma: no cover - optional dependency subject to policy guard
        from qiskit import QuantumCircuit
        import torch

        version = importlib.import_module("qiskit").__version__
    except Exception:
        return

    class _QiskitDevice:
        def __init__(self, n_wires: int, bsz: int = 1, device: str = "cpu") -> None:
            if bsz != 1:
                raise ValueError("Qiskit backend currently supports batch size 1")
            self.n_wires = n_wires
            self._circuit = QuantumCircuit(n_wires)

        def apply(self, name: str, mat, wire, params=None) -> None:  # pragma: no cover - thin adapter
            gate = getattr(self._circuit, name.lower(), None)
            if gate is None:
                raise ValueError(f"Unsupported gate {name!r} for qiskit backend")
            if params:
                gate(float(params[0]), int(wire))
            else:
                gate(int(wire))

        def measure_all(self):  # pragma: no cover - thin adapter
            # qasm export is the primary goal; provide zeroed expectations as a placeholder.
            return torch.zeros(1, self.n_wires, dtype=torch.float32)

        def qasm(self) -> str:  # pragma: no cover - thin adapter
            return self._circuit.qasm()

    registry["qiskit"] = QuantumBackend(
        name="qiskit",
        description=f"Qiskit ({version}) circuit builder",
        create_device=lambda n_wires, bsz=1, device="cpu": _QiskitDevice(n_wires, bsz, device),
        qasm_exporter=lambda dev: dev.qasm(),
    )


@lru_cache()
def _registry() -> Dict[str, QuantumBackend]:
    registry: Dict[str, QuantumBackend] = {}
    _register_torchquantum(registry)
    _register_pennylane(registry)
    _register_qiskit(registry)
    return registry


def available_backends() -> List[QuantumBackend]:
    """Return the discovered quantum backends."""

    return list(_registry().values())


def backend_names() -> List[str]:
    """Return the names of registered backends in preference order."""

    preferred_order = ["torchquantum", "pennylane", "qiskit"]
    names = {backend.name for backend in available_backends()}
    ordered = [name for name in preferred_order if name in names]
    ordered.extend(sorted(names - set(ordered)))
    return ordered


def get_backend(name: Optional[str] = None) -> QuantumBackend:
    """Return the requested backend, defaulting to the first available one."""

    registry = _registry()
    if name is None:
        for candidate in backend_names():
            if candidate in registry:
                return registry[candidate]
        raise RuntimeError("No quantum backends registered")
    if name not in registry:
        raise ValueError(f"Unknown quantum backend {name!r}")
    return registry[name]


def backend_summaries() -> List[str]:
    """Return human readable summaries for CLI display."""

    return [backend.summary() for backend in available_backends()]


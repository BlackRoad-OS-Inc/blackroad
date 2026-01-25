"""Basic tests for the Quantum ML module."""

from __future__ import annotations

import importlib

import pytest

pytest.importorskip("torch")
pytest.importorskip("qiskit")

try:
    pytest.importorskip("qiskit_machine_learning")
except ValueError as exc:  # pragma: no cover - optional dependency mismatch
    pytest.skip(f"qiskit_machine_learning unavailable: {exc}")
np = pytest.importorskip("numpy", reason="Install numpy or ask codex for help")
pytest.importorskip("torch", reason="Install torch or ask codex for help")
pytest.importorskip("qiskit", reason="Install qiskit or ask codex for help")
pytest.importorskip("qiskit_machine_learning", reason="Install qiskit_machine_learning or ask codex for help")

import torch
from qiskit.circuit.library import RealAmplitudes, ZZFeatureMap

import lucidia.quantum as qml
from lucidia.quantum.kernels import fit_qsvc

try:
    from lucidia.quantum.qnn import build_sampler_qnn
    from lucidia.quantum.torch_bridge import QModule
except Exception as exc:  # pragma: no cover - optional dependency path
    pytest.skip(
        f"quantum neural network components unavailable: {exc}",
        allow_module_level=True,
    )


def test_feature_flag_off(monkeypatch):
    monkeypatch.setenv("LUCIDIA_QML", "off")
    importlib.reload(qml)
    assert not qml.is_enabled()
    with pytest.raises(RuntimeError):
        qml.get_backend()


def test_sampler_qnn_gradients(monkeypatch):
    monkeypatch.setenv("LUCIDIA_QML", "on")
    importlib.reload(qml)
    feature_map = ZZFeatureMap(2)
    ansatz = RealAmplitudes(2, reps=1)
    qnn = build_sampler_qnn(feature_map, ansatz, input_size=2, weight_size=ansatz.num_parameters, num_classes=2)
    module = QModule(qnn, seed=1)
    x = torch.zeros((1, 2), requires_grad=True)
    out = module(x)
    out.backward(torch.ones_like(out))
    assert torch.all(torch.isfinite(x.grad))


def test_qsvc_training(monkeypatch):
    monkeypatch.setenv("LUCIDIA_QML", "on")
    importlib.reload(qml)
    x = np.array([[0, 0], [1, 1]])
    y = np.array([0, 1])
    model = fit_qsvc(x, y)
    preds = model.predict(x)
    assert preds.shape == (2,)

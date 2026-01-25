"""PyTorch bridge for Quantum Neural Networks."""

from __future__ import annotations

import os
import random
from typing import Any

import numpy as np
import torch
from qiskit_machine_learning.connectors import TorchConnector
from qiskit_machine_learning.neural_networks import NeuralNetwork


class QModule(torch.nn.Module):
    """Wrap a Qiskit ``NeuralNetwork`` as a ``torch.nn.Module``."""

    def __init__(self, qnn: NeuralNetwork, seed: int | None = 42) -> None:
        super().__init__()
        if seed is not None:
            random.seed(seed)
            np.random.seed(seed)
            torch.manual_seed(seed)
        self.qnn = qnn
        self.connector = TorchConnector(neural_network=self.qnn)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        if not isinstance(x, torch.Tensor):  # pragma: no cover - defensive
            raise TypeError("expected torch.Tensor")
        return self.connector(x)

    def to(self, device: Any) -> "QModule":  # type: ignore[override]
        if device not in {"cpu", torch.device("cpu")}:  # pragma: no cover - gpu path
            if os.getenv("LUCIDIA_QML_GPU", "off").lower() not in {"1", "true", "on"}:
                raise RuntimeError("GPU disabled")
        self.connector.to(device)
        return super().to(device)

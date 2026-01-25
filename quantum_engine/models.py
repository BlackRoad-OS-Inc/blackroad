"""Example quantum models."""
from __future__ import annotations

import torch
import torch.nn.functional as F
from torch import nn
from third_party import torchquantum as tq


class PQCClassifier(nn.Module):
    def __init__(self, n_wires: int = 4):
        super().__init__()
        self.n_wires = n_wires
        self.measure = tq.MeasureAll(tq.PauliZ)
        self.rx0 = tq.RX(True, True)
        self.ry0 = tq.RY(True, True)
        self.rz0 = tq.RZ(True, True)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        bsz = x.shape[0]
        qdev = tq.QuantumDevice(n_wires=self.n_wires, bsz=bsz, device=x.device)
        self.rx0(qdev, wires=0)
        self.ry0(qdev, wires=1)
        self.rz0(qdev, wires=2)
        meas = self.measure(qdev)
        if meas.shape[-1] < 4:
            pad = torch.zeros(bsz, 4 - meas.shape[-1], device=meas.device, dtype=meas.dtype)
            meas = torch.cat([meas, pad], dim=-1)
        logits = meas[..., :4].reshape(bsz, 2, 2).sum(-1)
        measurements = self.measure(qdev)
        if measurements.shape[1] < 4:
            pad = 4 - measurements.shape[1]
            measurements = F.pad(measurements, (0, pad))
        logits = measurements[:, :4].reshape(bsz, 2, 2).sum(-1)
        return F.log_softmax(logits, dim=1)


class VQEModel(nn.Module):
    """Placeholder VQE model."""

    def forward(self, *args, **kwargs):
        return torch.tensor(0.0)


class QAOAModel(nn.Module):
    """Placeholder QAOA model."""

    def forward(self, *args, **kwargs):
        return torch.tensor(0.0)

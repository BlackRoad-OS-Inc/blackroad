"""Layer helpers wrapping TorchQuantum primitives."""
from __future__ import annotations

from torch import nn
from third_party import torchquantum as tq


class RandomLayer(tq.RandomLayer):
    """Expose torchquantum.RandomLayer."""


class QFTLayer(tq.QFTLayer):
    """Expose torchquantum.QFTLayer."""


class QutritEmulator(nn.Module):
    """Encode a trit with two qubits and penalise the forbidden state."""

    def forward(self, qdev, wires):
        # Probability of reaching the forbidden |11> state acts as a penalty
        return qdev.prob_11(wires)

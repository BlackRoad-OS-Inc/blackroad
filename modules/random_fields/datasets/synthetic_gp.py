"""Synthetic 1D field dataset for quick tests.

Each sample is generated from ``f(x) = a*sin(πx) + b*cos(πx)`` with random
coefficients ``a`` and ``b``.  Coordinates are fixed on ``[0, 1]``.
"""

from __future__ import annotations

from typing import Tuple

import torch
from torch.utils.data import Dataset


class SyntheticGPDataset(Dataset):
    """Simple analytic dataset mimicking a Gaussian process."""

    def __init__(self, n_samples: int = 100, n_points: int = 32, seed: int = 0):
        super().__init__()
        g = torch.Generator().manual_seed(seed)
        self.n_samples = n_samples
        self.coords = torch.linspace(0, 1, n_points).unsqueeze(-1)
        self.coeffs = torch.randn(n_samples, 2, generator=g)

    def __len__(self) -> int:  # noqa: D401 - short doc
        return self.n_samples

    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, torch.Tensor]:
        a, b = self.coeffs[idx]
        x = self.coords
        field = a * torch.sin(torch.pi * x) + b * torch.cos(torch.pi * x)
        return field.squeeze(-1), x


__all__ = ["SyntheticGPDataset"]

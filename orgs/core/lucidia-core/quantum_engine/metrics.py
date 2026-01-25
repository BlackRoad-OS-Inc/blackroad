"""Utility metrics for quantum circuits."""
from __future__ import annotations

import torch


def expval(qdev) -> torch.Tensor:
    return qdev.measure_all()


def kl_div(p: torch.Tensor, q: torch.Tensor) -> torch.Tensor:
    p = p + 1e-9
    q = q + 1e-9
    return torch.sum(p * (torch.log(p) - torch.log(q)), dim=-1)


def energy(values: torch.Tensor) -> torch.Tensor:
    return values.sum(dim=-1)


def depth(qdev) -> int:
    return len(qdev.ops)


def two_qubit_count(qdev) -> int:
    return 0

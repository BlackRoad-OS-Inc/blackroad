"""Constraint abstractions for random field modeling.

This module defines a base :class:`Constraint` along with example
implementations such as :class:`MeanConstraint` and :class:`PoissonResidual`.
The API is intentionally light‑weight so that new constraint types can be
plugged in by implementing the :meth:`Constraint.residual` method.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Optional

import torch


class Constraint(ABC):
    """Abstract base class for constraints.

    Subclasses implement :meth:`residual` which should return a tensor of
    residual values to be added to the training loss.  Each constraint has a
    ``weight`` used when aggregating the total constraint loss.
    """

    name: str = "base"

    def __init__(self, weight: float = 1.0) -> None:
        self.weight = float(weight)

    @abstractmethod
    def residual(
        self, f_hat: torch.Tensor, coords: torch.Tensor, aux: Optional[dict] = None
    ) -> torch.Tensor:
        """Compute the residual for the constraint."""


class MeanConstraint(Constraint):
    """Penalise deviation from a target mean ``mu_fn`` evaluated at ``coords``."""

    name = "mean"

    def __init__(self, mu_fn, weight: float = 1.0) -> None:
        super().__init__(weight)
        self.mu_fn = mu_fn

    def residual(
        self, f_hat: torch.Tensor, coords: torch.Tensor, aux: Optional[dict] = None
    ) -> torch.Tensor:
        target = self.mu_fn(coords)
        return (f_hat - target).pow(2).mean()


class PoissonResidual(Constraint):
    """Enforce ``Δf = s(coords)`` weakly via collocation points."""

    name = "poisson"

    def __init__(self, source_fn, weight: float = 1.0) -> None:
        super().__init__(weight)
        self.s = source_fn

    def residual(
        self, f_hat: torch.Tensor, coords: torch.Tensor, aux: Optional[dict] = None
    ) -> torch.Tensor:
        grads = torch.autograd.grad(f_hat.sum(), coords, create_graph=True)[0]
        lap = torch.autograd.grad(grads.sum(), coords, create_graph=True)[0]
        lap = lap.sum(dim=-1, keepdim=True)
        target = self.s(coords)
        return (lap - target).pow(2).mean()


__all__ = ["Constraint", "MeanConstraint", "PoissonResidual"]

"""Quantum-style finance sandbox."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List

import matplotlib.pyplot as plt
import numpy as np


from .frameworks import select_backend


@dataclass
class QuantumFinanceSimulator:
    price: float
    volatility: float
    history: List[float] = field(default_factory=list)
    backend: str = "numpy"
    device: str = "cpu"
    seed: int | None = None

    def __post_init__(self) -> None:
        self.history = list(self.history)
        self._rng = np.random.default_rng(self.seed)
        self._backend_name = self.backend
        if self.backend == "torch":
            try:
                import torch
            except ImportError as exc:  # pragma: no cover - optional dependency
                raise RuntimeError("Torch backend requested but torch is not installed") from exc
            self._torch = torch
        else:
            try:
                backend_cfg = select_backend(self.backend)
            except ValueError:
                backend_cfg = select_backend("numpy")
            self._backend_name = backend_cfg.name
            if backend_cfg.name == "jax":  # pragma: no cover - optional dependency
                import jax

                self._jax = jax
                self._key = jax.random.PRNGKey(self.seed or 0)

    def step(self, samples: int = 1000) -> np.ndarray:
        """Simulate a probabilistic price distribution."""

        if samples <= 0:
            raise ValueError("samples must be positive")

        if self._backend_name == "torch":  # pragma: no cover - optional dependency
            dist = self._torch.distributions.Normal(
                loc=self._torch.tensor(self.price, device=self.device),
                scale=self._torch.tensor(self.volatility, device=self.device),
            )
            tensor = dist.sample((samples,))
            distribution = tensor.detach().cpu().numpy()
        elif self._backend_name == "jax":  # pragma: no cover - optional dependency
            self._key, subkey = self._jax.random.split(self._key)
            noise = np.asarray(self._jax.random.normal(subkey, shape=(samples,)), dtype=float)
            distribution = self.price + self.volatility * noise
        else:
            distribution = self._rng.normal(self.price, self.volatility, samples)

        self.history.append(float(np.mean(distribution)))
        return np.asarray(distribution, dtype=float)

    def observe(self, distribution: np.ndarray) -> float:
        """Collapse the distribution to a single price."""

        values = np.asarray(distribution, dtype=float)
        self.price = float(self._rng.choice(values))
        return self.price

    def plot(self, distribution: np.ndarray) -> plt.Figure:
        values = np.asarray(distribution, dtype=float)
        fig, ax = plt.subplots(2, 1, figsize=(6, 6))
        ax[0].hist(values, bins=30)
        ax[0].set_title("Probability distribution")
        ax[1].plot(self.history + [float(self.price)])
        ax[1].set_title("Collapsed price over time")
        return fig

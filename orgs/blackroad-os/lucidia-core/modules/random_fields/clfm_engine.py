"""Minimal Constrained Latent Flow Matching engine.

This module provides a light‑weight implementation of the training stages
outlined in the C‑LFM paper:

1. Pre‑train a :class:`FunctionalVAE` with optional constraints.
2. Train a latent vector field using conditional flow matching.
3. Sample new fields by solving an ODE in the latent space and decoding
   through the VAE's function decoder.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Sequence

import torch
import torch.nn as nn
from torch.utils.data import DataLoader

from .functional_vae import FunctionalVAE


class LatentVectorField(nn.Module):
    """Simple MLP representing ``v(z, t)``."""

    def __init__(self, z_dim: int, hidden: int = 128) -> None:
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(z_dim + 1, hidden),
            nn.SiLU(),
            nn.Linear(hidden, hidden),
            nn.SiLU(),
            nn.Linear(hidden, z_dim),
        )

    def forward(self, z: torch.Tensor, t: torch.Tensor) -> torch.Tensor:
        if t.dim() == 1:
            t = t.unsqueeze(-1)
        inp = torch.cat([z, t.expand_as(z[:, :1])], dim=-1)
        return self.net(inp)


@dataclass
class TrainConfig:
    lr: float = 1e-3
    epochs: int = 1
    batch_size: int = 16


class CLFMEngine:
    """Encapsulates VAE and latent flow training."""

    def __init__(self, vae: FunctionalVAE, device: str | torch.device = "cpu") -> None:
        self.vae = vae.to(device)
        self.device = device
        self.z_dim = vae.encoder[-1].out_features // 2
        self.vfield = LatentVectorField(self.z_dim).to(device)

    # ------------------------------------------------------------------
    def pretrain_vae(
        self,
        dataset,
        constraints: Sequence = (),
        config: TrainConfig | None = None,
    ) -> None:
        config = config or TrainConfig()
        self.vae.train()
        loader = DataLoader(dataset, batch_size=config.batch_size, shuffle=True)
        opt = torch.optim.Adam(self.vae.parameters(), lr=config.lr)
        mse = nn.MSELoss()
        for _ in range(config.epochs):
            for x, xi in loader:
                x = x.to(self.device)
                xi = xi.to(self.device)
                f_hat, losses = self.vae(x, xi, constraints)
                recon = mse(f_hat.squeeze(), x)
                loss = recon + losses["kld"] + losses["cres"]
                opt.zero_grad()
                loss.backward()
                opt.step()

    # ------------------------------------------------------------------
    def train_flow(self, dataset, config: TrainConfig | None = None) -> None:
        config = config or TrainConfig()
        self.vae.eval()
        loader = DataLoader(dataset, batch_size=config.batch_size, shuffle=True)
        opt = torch.optim.Adam(self.vfield.parameters(), lr=config.lr)
        for _ in range(config.epochs):
            for x, _ in loader:
                x = x.to(self.device)
                with torch.no_grad():
                    mu, _ = self.vae.encode(x)
                z1 = mu
                z0 = torch.randn_like(z1)
                t = torch.rand(z1.size(0), device=self.device)
                zt = (1 - t[:, None]) * z0 + t[:, None] * z1
                v_target = z1 - z0
                v_pred = self.vfield(zt, t)
                loss = (v_pred - v_target).pow(2).mean()
                opt.zero_grad()
                loss.backward()
                opt.step()

    # ------------------------------------------------------------------
    def sample(
        self, coords: torch.Tensor, n_samples: int = 1, steps: int = 20
    ) -> torch.Tensor:
        """Generate ``n_samples`` fields evaluated at ``coords``."""

        self.vae.eval()
        self.vfield.eval()
        device = self.device
        coords = coords.to(device)
        dt = 1.0 / steps
        z = torch.randn(n_samples, self.z_dim, device=device)
        for i in range(steps):
            t = torch.full((n_samples,), i * dt, device=device)
            v = self.vfield(z, t)
            z = z + v * dt
        with torch.no_grad():
            f = self.vae.decoder(z, coords)
        return f.squeeze(-1)


__all__ = ["CLFMEngine", "LatentVectorField", "TrainConfig"]

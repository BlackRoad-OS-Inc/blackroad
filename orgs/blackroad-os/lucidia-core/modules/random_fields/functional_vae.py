"""Variational auto‑encoder with a function decoder.

The decoder follows the DeepONet paradigm where coordinates (``xi``) are
processed by a trunk network and latent variables (``z``) by a branch network.
Their interaction yields a predicted field value ``f_hat``.
"""

from __future__ import annotations

import torch
import torch.nn as nn


class Trunk(nn.Module):
    """Network processing spatial/temporal coordinates."""

    def __init__(self, in_dim: int = 2, width: int = 128, depth: int = 4) -> None:
        super().__init__()
        layers = []
        d = in_dim
        for _ in range(depth):
            layers.extend([nn.Linear(d, width), nn.SiLU()])
            d = width
        self.net = nn.Sequential(*layers)

    def forward(self, xi: torch.Tensor) -> torch.Tensor:  # noqa: D401 - short doc
        return self.net(xi)


class Branch(nn.Module):
    """Network processing the latent code ``z``."""

    def __init__(self, z_dim: int = 32, width: int = 128, depth: int = 2) -> None:
        super().__init__()
        layers = []
        d = z_dim
        for _ in range(depth):
            layers.extend([nn.Linear(d, width), nn.SiLU()])
            d = width
        self.net = nn.Sequential(*layers)

    def forward(self, z: torch.Tensor) -> torch.Tensor:  # noqa: D401 - short doc
        return self.net(z)


class FunctionDecoder(nn.Module):
    """DeepONet-style function decoder ``f_hat(xi; z)``."""

    def __init__(self, z_dim: int = 32, coord_dim: int = 2, width: int = 128) -> None:
        super().__init__()
        self.trunk = Trunk(coord_dim, width)
        self.branch = Branch(z_dim, width)
        self.out = nn.Sequential(nn.Linear(width, width), nn.SiLU(), nn.Linear(width, 1))

    def forward(self, z: torch.Tensor, xi: torch.Tensor) -> torch.Tensor:
        phi_t = self.trunk(xi)  # (N, W)
        phi_b = self.branch(z)  # (B, W)
        if phi_b.dim() == 2:
            phi_b = phi_b.unsqueeze(1)  # (B, 1, W)
        return self.out(phi_t * phi_b)


class FunctionalVAE(nn.Module):
    """Simple VAE with functional decoder and optional constraints."""

    def __init__(self, x_dim: int, z_dim: int = 32, coord_dim: int = 2) -> None:
        super().__init__()
        self.encoder = nn.Sequential(
            nn.Linear(x_dim, 256),
            nn.SiLU(),
            nn.Linear(256, 2 * z_dim),
        )
        self.decoder = FunctionDecoder(z_dim=z_dim, coord_dim=coord_dim)

    def encode(self, x: torch.Tensor) -> tuple[torch.Tensor, torch.Tensor]:
        h = self.encoder(x)
        mu, logvar = torch.chunk(h, 2, dim=-1)
        return mu, logvar

    def reparam(self, mu: torch.Tensor, logvar: torch.Tensor) -> torch.Tensor:
        eps = torch.randn_like(mu)
        return mu + eps * torch.exp(0.5 * logvar)

    def forward(
        self,
        x: torch.Tensor,
        xi: torch.Tensor,
        constraints: tuple = (),
    ) -> tuple[torch.Tensor, dict]:
        mu, logvar = self.encode(x)
        z = self.reparam(mu, logvar)
        f_hat = self.decoder(z, xi)
        kld = -0.5 * (1 + logvar - mu.pow(2) - logvar.exp()).mean()
        cres = sum(c.weight * c.residual(f_hat, xi) for c in constraints)
        return f_hat, {"kld": kld, "cres": cres}


__all__ = [
    "Trunk",
    "Branch",
    "FunctionDecoder",
    "FunctionalVAE",
]

"""Circuit search scaffolding."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import List

from third_party import torchquantum as tq


@dataclass
class SearchSpace:
    layers: List[tq.RandomLayer] = field(default_factory=list)

    def add_layer(self, layer: tq.RandomLayer) -> None:
        self.layers.append(layer)


def noise_aware_score(circuit: SearchSpace, noise: float | None = None) -> float:
    """Placeholder for future noise-aware scoring."""
    return float(len(circuit.layers))

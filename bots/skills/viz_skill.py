from __future__ import annotations

import os
from typing import Dict

import matplotlib.pyplot as plt

ART_DIR = "artifacts"


def save_hist(probs: Dict[str, float], fname: str = "hist.png") -> str:
    """Persist a bar chart for ``probs`` and return the artifact path."""

    os.makedirs(ART_DIR, exist_ok=True)
    keys = list(probs.keys())
    vals = list(probs.values())
    fig = plt.figure()
    plt.bar(range(len(keys)), vals)
    plt.xticks(range(len(keys)), keys)
    plt.ylabel("Probability")
    path = os.path.join(ART_DIR, fname)
    fig.savefig(path, dpi=160, bbox_inches="tight")
    plt.close(fig)
    return path

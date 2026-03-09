"""Visualization utilities.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from typing import Dict, Optional


def plot_histogram(counts: Dict[str, int], title: str = "Measurement Results") -> str:
    """Create ASCII histogram of counts."""
    if not counts:
        return "No data"
    
    total = sum(counts.values())
    max_count = max(counts.values())
    width = 40
    
    lines = [title, "=" * len(title)]
    for bitstring, count in sorted(counts.items()):
        bar_len = int(width * count / max_count)
        pct = 100 * count / total
        lines.append(f"{bitstring}: {'█' * bar_len} {pct:.1f}%")
    
    return "\n".join(lines)


def plot_bloch_sphere(statevector, title: str = "Bloch Sphere") -> str:
    """Create text representation of Bloch sphere state."""
    import numpy as np
    
    if len(statevector) != 2:
        return "Bloch sphere only for single qubit"
    
    alpha, beta = statevector
    theta = 2 * np.arccos(np.abs(alpha))
    phi = np.angle(beta) - np.angle(alpha)
    
    x = np.sin(theta) * np.cos(phi)
    y = np.sin(theta) * np.sin(phi)
    z = np.cos(theta)
    
    return f"{title}\n(x={x:.3f}, y={y:.3f}, z={z:.3f})"


__all__ = ["plot_histogram", "plot_bloch_sphere"]

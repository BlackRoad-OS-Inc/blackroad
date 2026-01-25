"""Utilities that capture the "Iterative Math-Build Loop" workflow.

This module turns a simple mathematical seed—the logistic map—into a tiny
experiment that can be iterated forever.  The workflow mirrors Block 43:

Step 1 (Seed)
    Use the logistic function :math:`x_{n+1} = r x_n (1 - x_n)` as the pattern.

Step 2 (Three translations)
    Physics
        Population dynamics where energy input (sunlight, nutrients) is limited.
    Code
        A feedback loop that maps the state into itself with a tunable gain.
    Hardware
        A single-transistor logistic oscillator driven by a biasing envelope.

Step 3 (Build a toy)
    Simulate the logistic loop over a configurable number of pulses.

Step 4 (Measure & rename)
    Rename raw variables once we observe their behaviour: ``population`` becomes
    ``pulse_level`` and ``r`` becomes ``gain`` to match the oscillation view.

Step 5 (Archive & fork)
    Export snapshots that carry timestamped tags ready for storage.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from statistics import fmean
from typing import Iterable, List

from .frameworks import select_backend


@dataclass(frozen=True)
class LoopSnapshot:
    """Stores a measured sequence from the logistic loop.

    Attributes
    ----------
    tag:
        Timestamped identifier that makes it easy to fork future experiments.
    gain:
        The effective amplification factor observed during the run.
    pulse_levels:
        Measured levels after each iteration of the loop.
    phase_drift:
        The final-step change, useful for spotting bifurcations.
    mean_level:
        Average pulse level over the capture window.
    """

    tag: str
    gain: float
    pulse_levels: List[float]
    phase_drift: float
    mean_level: float


def iterate_logistic_loop(
    *,
    gain: float,
    seed_level: float,
    pulses: int,
    backend: str | None = None,
) -> List[float]:
    """Run the logistic map for the requested number of pulses.

    Parameters
    ----------
    gain:
        Feedback intensity of the loop (commonly ``r`` in the logistic map).
    seed_level:
        Initial pulse level.  Must be in ``(0, 1)`` for the canonical map.
    pulses:
        Number of iterations to execute.
    backend:
        Optional math backend name.  When ``"jax"`` is available the update
        loop runs via ``jax.lax.scan``; otherwise the NumPy backend is used.

    Returns
    -------
    list of float
        Observed pulse levels after each iteration.
    """

    if pulses <= 0:
        raise ValueError("pulses must be positive")
    if not 0.0 < seed_level < 1.0:
        raise ValueError("seed_level must be strictly between 0 and 1")

    backend_cfg = select_backend(backend)
    if backend_cfg.name == "jax":  # pragma: no cover - requires optional dependency
        import jax

        jnp = backend_cfg.array_module
        gain_arr = jnp.asarray(gain, dtype=jnp.float64)
        seed_arr = jnp.asarray(seed_level, dtype=jnp.float64)

        def _step(x, _):
            nxt = gain_arr * x * (1.0 - x)
            return nxt, nxt

        _, values = jax.lax.scan(_step, seed_arr, None, length=pulses)
        return [float(val) for val in values.tolist()]

    level = seed_level
    pulse_levels: List[float] = []
    for _ in range(pulses):
        level = gain * level * (1.0 - level)
        pulse_levels.append(level)
    return pulse_levels


def capture_snapshot(
    *,
    gain: float = 3.72,
    seed_level: float = 0.21,
    pulses: int = 128,
    tag_prefix: str = "symmetry_break",
    backend: str | None = None,
) -> LoopSnapshot:
    """Simulate the loop and bundle the measurement in a :class:`LoopSnapshot`.

    The timestamp embedded into ``tag`` makes it trivial to archive runs and
    reference them the next time the "Next!" impulse hits.
    """

    if pulses < 2:
        raise ValueError("pulses must be at least 2 to compute phase drift")

    pulse_levels = iterate_logistic_loop(
        gain=gain,
        seed_level=seed_level,
        pulses=pulses,
        backend=backend,
    )
    phase_drift = pulse_levels[-1] - pulse_levels[-2]
    mean_level = fmean(pulse_levels)
    timestamp = datetime.now(timezone.utc).strftime("%Y_%m_%dT%H%M%SZ")
    tag = f"{tag_prefix}_{timestamp}"
    return LoopSnapshot(
        tag=tag,
        gain=gain,
        pulse_levels=pulse_levels,
        phase_drift=phase_drift,
        mean_level=mean_level,
    )


def export_snapshot(snapshot: LoopSnapshot) -> str:
    """Serialise a snapshot into a minimal archival string.

    The format favours human parsing (CSV-like) so it can be dropped into a
    notebook, pasted into a README, or stored alongside lab photos.
    """

    header = "tag,gain,mean_level,phase_drift,pulse_levels"
    levels = " ".join(f"{level:.6f}" for level in snapshot.pulse_levels)
    body = f"{snapshot.tag},{snapshot.gain:.6f},{snapshot.mean_level:.6f},{snapshot.phase_drift:.6f},{levels}"
    return f"{header}\n{body}\n"


def sweep_gains(
    *,
    gains: Iterable[float],
    seed_level: float,
    pulses: int,
    backend: str | None = None,
) -> List[LoopSnapshot]:
    """Generate snapshots for a sequence of gains.

    This helper makes it easy to scan for bifurcations and immediately archive
    the most interesting regimes.
    """

    return [
        capture_snapshot(
            gain=gain,
            seed_level=seed_level,
            pulses=pulses,
            tag_prefix=f"gain_{gain:.3f}",
            backend=backend,
        )
        for gain in gains
    ]


__all__ = [
    "LoopSnapshot",
    "capture_snapshot",
    "export_snapshot",
    "iterate_logistic_loop",
    "sweep_gains",
]

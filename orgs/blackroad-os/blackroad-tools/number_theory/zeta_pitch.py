"""Utilities for sampling the Amundson pitch of the Riemann zeta function.

The *pitch* associated to a complex trajectory describes the ratio between
radial growth and angular sweep of the image curve. For an analytic function
``f`` evaluated along the critical line ``s(t) = 1/2 + i t`` we can express the
pitch purely in terms of the logarithmic derivative of ``f``:

.. math::

    c_f(t) = \frac{\mathrm d \ln |f(s(t))| / \mathrm d t}{\mathrm d \arg f(s(t)) / \mathrm d t}.

This module provides helpers to evaluate ``c_f`` for the Riemann zeta function
``ζ`` using modest numerical precision. The implementation relies only on
``mpmath`` and Matplotlib (for optional plotting) and now includes a command
line harness that mirrors the standalone script used in exploratory notebooks.
"""

from __future__ import annotations

import argparse
import csv
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Sequence, Tuple

import mpmath as mp

try:  # Optional plotting dependency.
    import matplotlib.pyplot as plt
except Exception:  # pragma: no cover - matplotlib is optional.
    plt = None

PitchArrays = Tuple[List[float], List[float], List[float], List[float], List[float], List[float]]


@dataclass(frozen=True)
class ZetaPitchSample:
    """Container for a single ``ζ`` pitch measurement."""

    t: float
    zeta: complex
    log_derivative: complex
    pitch: float

    @property
    def magnitude(self) -> float:
        """Return ``|ζ(1/2 + i t)|``."""

        return abs(self.zeta)

    @property
    def phase(self) -> float:
        """Return ``arg ζ(1/2 + i t)`` using the principal branch."""

        return math.atan2(self.zeta.imag, self.zeta.real)

    @property
    def log_magnitude(self) -> float:
        """Return ``log |ζ(1/2 + i t)|`` with ``-inf`` at zeros."""

        magnitude = self.magnitude
        return math.log(magnitude) if magnitude > 0 else float("-inf")

    @property
    def dlog_dt(self) -> float:
        """Return the derivative of ``log |ζ|`` when available."""

        value = self.log_derivative.real
        return value if math.isfinite(value) else math.nan

    @property
    def dtheta_dt(self) -> float:
        """Return the derivative of ``arg ζ`` when available."""

        value = self.log_derivative.imag
        return value if math.isfinite(value) else math.nan


def _zeta_at(t: float) -> complex:
    """Evaluate ``ζ`` on the critical line with high precision."""

    return complex(mp.zeta(0.5 + t * 1j))


def _zeta_time_derivative(t: float, h: float) -> complex:
    """Finite-difference approximation of ``dζ/dt`` along the critical line."""

    s_plus = 0.5 + 1j * (t + h)
    s_minus = 0.5 + 1j * (t - h)
    z_plus = mp.zeta(s_plus)
    z_minus = mp.zeta(s_minus)
    return complex((z_plus - z_minus) / (2 * h))


def _pitch_from_log_derivative(log_derivative: complex) -> float:
    """Compute the Amundson pitch from the logarithmic derivative."""

    real = log_derivative.real
    imag = log_derivative.imag
    if not (math.isfinite(real) and math.isfinite(imag)):
        return math.nan
    if abs(imag) <= 1e-12:
        return math.nan
    return real / imag


def _pitch_from_values(zeta_val: complex, d_zeta_dt: complex) -> tuple[complex, float]:
    """Return ``(log_derivative, pitch)`` computed from ``ζ`` and its derivative."""

    if zeta_val == 0:
        nan = float("nan")
        return complex(nan, nan), math.nan

    log_derivative = d_zeta_dt / zeta_val
    return log_derivative, _pitch_from_log_derivative(log_derivative)


def sample_zeta_pitch(
    t_values: Sequence[float], *,
    h: float = 1e-4,
    mp_dps: int = 80,
) -> List[ZetaPitchSample]:
    """Evaluate ``c_ζ(t)`` for the provided ``t`` values.

    Args:
        t_values: Iterable of ordinates on the critical line.
        h: Step used for the symmetric finite difference in ``t``.
        mp_dps: Decimal precision forwarded to ``mpmath``.

    Returns:
        A list of :class:`ZetaPitchSample` entries ordered as ``t_values``.
    """

    old_dps = mp.mp.dps
    mp.mp.dps = max(old_dps, mp_dps)
    try:
        samples: List[ZetaPitchSample] = []
        for t in t_values:
            zeta_val = _zeta_at(t)
            d_zeta_dt = _zeta_time_derivative(t, h)
            log_derivative, pitch = _pitch_from_values(zeta_val, d_zeta_dt)
            samples.append(
                ZetaPitchSample(
                    t=float(t),
                    zeta=zeta_val,
                    log_derivative=log_derivative,
                    pitch=pitch,
                )
            )
        return samples
    finally:
        mp.mp.dps = old_dps


def sample_interval(
    t_start: float,
    t_end: float,
    *,
    num_points: int,
    h: float = 1e-4,
    mp_dps: int = 80,
) -> List[ZetaPitchSample]:
    """Convenience wrapper to sample a uniform grid on ``[t_start, t_end]``."""

    if num_points < 2:
        raise ValueError("num_points must be at least 2 to define a grid")
    spacing = (t_end - t_start) / (num_points - 1)
    grid = [t_start + i * spacing for i in range(num_points)]
    return sample_zeta_pitch(grid, h=h, mp_dps=mp_dps)


def _unwrap_phases(phases: Sequence[float]) -> List[float]:
    if not phases:
        return []
    unwrapped = [phases[0]]
    offset = 0.0
    for idx in range(1, len(phases)):
        delta = phases[idx] - phases[idx - 1]
        while delta <= -math.pi:
            delta += 2 * math.pi
            offset += 2 * math.pi
        while delta > math.pi:
            delta -= 2 * math.pi
            offset -= 2 * math.pi
        unwrapped.append(phases[idx] + offset)
    return unwrapped


def _format_finite(value: float) -> float | str:
    return value if math.isfinite(value) else ""


def write_csv(samples: Iterable[ZetaPitchSample], path: Path | str) -> None:
    """Persist ``ζ`` pitch samples to ``path`` as CSV."""

    sample_list = list(samples)
    phases = _unwrap_phases([sample.phase for sample in sample_list])
    fieldnames = [
        "t",
        "real",
        "imag",
        "logabs",
        "theta_unwrapped",
        "dlog_dt",
        "dtheta_dt",
        "c_pitch",
    ]
    with Path(path).open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for sample, theta in zip(sample_list, phases):
            writer.writerow(
                {
                    "t": float(sample.t),
                    "real": float(sample.zeta.real),
                    "imag": float(sample.zeta.imag),
                    "logabs": float(sample.log_magnitude),
                    "theta_unwrapped": float(theta),
                    "dlog_dt": _format_finite(sample.dlog_dt),
                    "dtheta_dt": _format_finite(sample.dtheta_dt),
                    "c_pitch": _format_finite(sample.pitch),
                }
            )


def plot_pitch(samples: Sequence[ZetaPitchSample], *, path: Path | str | None = None) -> None:
    """Plot ``c_ζ(t)`` for visual inspection."""

    if plt is None:  # pragma: no cover - plotting is optional.
        raise RuntimeError("Matplotlib is required for plotting but is not available")

    ts = [sample.t for sample in samples]
    pitches = [sample.pitch for sample in samples]
    magnitudes = [sample.magnitude for sample in samples]

    fig, ax1 = plt.subplots(figsize=(10, 5))
    ax1.set_title("Amundson pitch of ζ(1/2 + i t)")
    ax1.set_xlabel("t")
    ax1.set_ylabel("c_ζ(t)", color="tab:blue")
    ax1.plot(ts, pitches, color="tab:blue", label="pitch")
    ax1.tick_params(axis="y", labelcolor="tab:blue")

    ax2 = ax1.twinx()
    ax2.set_ylabel("|ζ|")
    ax2.plot(ts, magnitudes, color="tab:orange", alpha=0.6, label="|ζ|")

    fig.tight_layout()
    if path is None:
        plt.show()
    else:
        fig.savefig(path)
    plt.close(fig)


def compute(
    tmin: float,
    tmax: float,
    n: int,
    dps: int,
    *,
    h: float = 1e-4,
    return_samples: bool = False,
) -> PitchArrays | tuple[Sequence[ZetaPitchSample], PitchArrays]:
    """Compute pitch statistics on a uniform grid.

    When ``return_samples`` is ``True`` the list of :class:`ZetaPitchSample`
    instances used to assemble the arrays is returned as well. This mirrors the
    behaviour of the standalone script shared in internal notebooks while keeping
    the richer API available to library callers.
    """

    samples = sample_interval(tmin, tmax, num_points=n, h=h, mp_dps=dps)
    phases = _unwrap_phases([sample.phase for sample in samples])
    ts = [sample.t for sample in samples]
    logabs = [sample.log_magnitude for sample in samples]
    dlog = [sample.dlog_dt for sample in samples]
    dtheta = [sample.dtheta_dt for sample in samples]
    pitches = [sample.pitch for sample in samples]
    result: PitchArrays = (ts, logabs, phases, dlog, dtheta, pitches)
    if return_samples:
        return samples, result
    return result


def main(argv: Sequence[str] | None = None) -> None:
    """CLI entry-point used for quick experiments."""

    parser = argparse.ArgumentParser()
    parser.add_argument("--tmin", type=float, default=10.0)
    parser.add_argument("--tmax", type=float, default=100.0)
    parser.add_argument("--n", type=int, default=2000)
    parser.add_argument("--dps", type=int, default=80)
    parser.add_argument("--csv", default="data/zeta/pitch.csv")
    parser.add_argument("--png", default="")
    parser.add_argument("--h", type=float, default=1e-4, help="Finite-difference step for dζ/dt")
    args = parser.parse_args(argv)

    samples, arrays = compute(args.tmin, args.tmax, args.n, args.dps, h=args.h, return_samples=True)

    csv_path = Path(args.csv)
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    write_csv(samples, csv_path)

    if args.png:
        try:
            png_path = Path(args.png)
            png_path.parent.mkdir(parents=True, exist_ok=True)
            plot_pitch(samples, path=png_path)
        except Exception as exc:  # pragma: no cover - optional plotting.
            print(f"Plot skipped: {exc}")

    # Arrays are returned for callers that want to manipulate them immediately.
    _ = arrays


__all__ = [
    "ZetaPitchSample",
    "sample_zeta_pitch",
    "sample_interval",
    "write_csv",
    "plot_pitch",
    "compute",
]


if __name__ == "__main__":  # pragma: no cover - CLI entry point.
    main()

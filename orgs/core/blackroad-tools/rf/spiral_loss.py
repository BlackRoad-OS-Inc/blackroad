"""Estimate transmission-line attenuation/dispersion from reflection spirals.

This module exposes helpers and a CLI for estimating the logarithmic pitch of a
reflection-coefficient spiral traced on a Smith chart.  The pitch relates the
per-unit attenuation (``alpha``) and phase constant (``beta``) through

    c = d(ln|Gamma|) / d(theta) = -alpha / beta.

Given reflection data sampled along a transmission line (frequency sweeps or
spatial probes), the CLI determines the pitch, the derived ``alpha``/``beta``
constants, and a "spiralness" score that quantifies how well the trajectory
matches an ideal logarithmic spiral.  When requested it also renders an overlay
plot comparing the measured data with its least-squares spiral reconstruction.

Example usage::

    $ python -m tools.rf.spiral_loss trace.csv --distance frequency_hz \
          --real real --imag imag --vendor-alpha 2.4e-10 \
          --figure figures/rf_spiral_loss.png

The utility accepts CSV files with or without headers.  Columns can be
referenced either by name or zero-based index.
"""

from __future__ import annotations

import argparse
import csv
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Sequence, Tuple

import numpy as np


# ---------------------------------------------------------------------------
# Data containers
# ---------------------------------------------------------------------------


@dataclass
class ReflectionTrace:
    """Reflection coefficient samples along a one-dimensional sweep."""

    position: np.ndarray
    gamma: np.ndarray

    def __post_init__(self) -> None:
        if self.position.ndim != 1 or self.gamma.ndim != 1:
            raise ValueError("position and gamma must be 1-D arrays")
        if self.position.size != self.gamma.size:
            raise ValueError("position and gamma must have the same length")
        if not np.all(np.isfinite(self.position)):
            raise ValueError("position array contains non-finite values")
        if not np.all(np.isfinite(self.gamma)):
            raise ValueError("gamma array contains non-finite values")


@dataclass
class SpiralEstimate:
    """Summary of the logarithmic spiral regression."""

    pitch: float
    spiralness: float
    rho_slope: float
    rho_intercept: float


@dataclass
class LineEstimate:
    """Derived per-unit attenuation/phase constants."""

    alpha: float
    beta: float
    slope_theta_vs_position: float
    theta_intercept: float
    pitch: float

    @property
    def alpha_magnitude(self) -> float:
        """Absolute value of ``alpha`` for quick comparison against vendor data."""

        return float(abs(self.alpha))

    @property
    def c_hat(self) -> float:
        """Return the estimated logarithmic pitch ``-alpha / beta``."""

        if self.beta == 0:
            return float("nan")
        return float(-self.alpha / self.beta)


# ---------------------------------------------------------------------------
# Core computations
# ---------------------------------------------------------------------------


def unwrap_angle(z: np.ndarray) -> np.ndarray:
    """Return the unwrapped angle of a complex array."""

    return np.unwrap(np.angle(z))


def spiral_pitch(gamma: np.ndarray) -> SpiralEstimate:
    """Estimate the logarithmic pitch of a complex spiral."""

    if gamma.ndim != 1:
        raise ValueError("gamma must be a 1-D array")

    theta = unwrap_angle(gamma)
    rho = np.log(np.abs(gamma) + 1e-30)
    A = np.vstack([theta, np.ones_like(theta)]).T
    slope, intercept = np.linalg.lstsq(A, rho, rcond=None)[0]
    rho_hat = slope * theta + intercept
    resid = rho - rho_hat
    var_rho = np.var(rho)
    spiralness = 1.0 if var_rho == 0 else 1.0 - np.var(resid) / var_rho
    spiralness = float(np.clip(spiralness, 0.0, 1.0))
    return SpiralEstimate(float(slope), spiralness, float(slope), float(intercept))


def beta_from_trace(trace: ReflectionTrace) -> LineEstimate:
    """Compute the phase constant ``beta`` from ``theta(position)``."""

    theta = unwrap_angle(trace.gamma)
    B = np.vstack([trace.position, np.ones_like(trace.position)]).T
    slope, intercept = np.linalg.lstsq(B, theta, rcond=None)[0]
    beta = -0.5 * slope
    return LineEstimate(
        alpha=float("nan"),
        beta=float(beta),
        slope_theta_vs_position=float(slope),
        theta_intercept=float(intercept),
        pitch=float("nan"),
    )


def estimate_line(trace: ReflectionTrace) -> Tuple[SpiralEstimate, LineEstimate]:
    """Estimate spiral pitch and convert it into line parameters."""

    spiral = spiral_pitch(trace.gamma)
    base = beta_from_trace(trace)
    alpha = -spiral.pitch * base.beta
    line = LineEstimate(
        alpha=float(alpha),
        beta=base.beta,
        slope_theta_vs_position=base.slope_theta_vs_position,
        theta_intercept=base.theta_intercept,
        pitch=spiral.pitch,
    )
    return spiral, line


def reconstruct_spiral(trace: ReflectionTrace, spiral: SpiralEstimate, line: LineEstimate) -> np.ndarray:
    """Return the fitted spiral samples evaluated at the trace positions."""

    theta_hat = line.slope_theta_vs_position * trace.position + line.theta_intercept
    rho_hat = spiral.rho_slope * theta_hat + spiral.rho_intercept
    return np.exp(rho_hat + 1j * theta_hat)


def save_spiral_figure(
    path: Path,
    trace: ReflectionTrace,
    fitted: np.ndarray,
    *,
    vendor_alpha: float | None,
    line: LineEstimate,
    title: str | None = None,
) -> None:
    """Render a measured vs. fitted spiral overlay."""

    import matplotlib.pyplot as plt  # Imported lazily for CLI usage

    fig, ax = plt.subplots(figsize=(6, 6))
    ax.plot(np.real(trace.gamma), np.imag(trace.gamma), label="measured", linewidth=1.6)
    ax.plot(np.real(fitted), np.imag(fitted), label="fitted", linestyle="--", linewidth=1.6)
    ax.set_xlabel("Re(Γ)")
    ax.set_ylabel("Im(Γ)")
    ax.set_aspect("equal", adjustable="box")
    ax.set_title(title or "Reflection spiral fit")

    caption_lines = [f"|α| = {line.alpha_magnitude:.3e}"]
    if vendor_alpha is not None:
        caption_lines.append(f"vendor α = {vendor_alpha:.3e}")
    caption_lines.append(f"ĉ = {line.c_hat:.3e}")
    ax.text(0.02, 0.98, "\n".join(caption_lines), transform=ax.transAxes, va="top")

    ax.legend(loc="best")
    fig.tight_layout()

    path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(path, dpi=200)
    plt.close(fig)


# ---------------------------------------------------------------------------
# File parsing helpers
# ---------------------------------------------------------------------------


def _read_csv(path: Path) -> Tuple[List[str], List[List[float]]]:
    with path.open("r", newline="") as handle:
        reader = csv.reader(handle)
        rows: List[List[float]] = []
        headers: List[str] = []
        for idx, row in enumerate(reader):
            if not row:
                continue
            if idx == 0 and _row_is_header(row):
                headers = [cell.strip() for cell in row]
                continue
            try:
                rows.append([float(cell) for cell in row])
            except ValueError as exc:  # pragma: no cover - handled by CLI
                raise ValueError(f"Non-numeric value found on line {idx + 1}") from exc
    if not rows:
        raise ValueError("input file contains no data rows")
    return headers, rows


def _row_is_header(row: Sequence[str]) -> bool:
    for cell in row:
        try:
            float(cell)
            return False
        except ValueError:
            continue
    return True


def _coerce_column(value: str | None) -> str | int | None:
    if value is None:
        return None
    try:
        return int(value)
    except ValueError:
        return value


def load_trace(
    path: Path,
    distance_column: str | int | None,
    real_column: str | int | None,
    imag_column: str | int | None,
    magnitude_column: str | int | None,
    phase_column: str | int | None,
    phase_degrees: bool,
) -> ReflectionTrace:
    """Load a reflection trace from a CSV-like text file."""

    headers, rows = _read_csv(path)
    columns = list(zip(*rows))  # transpose

    def resolve(column: str | int | None, purpose: str) -> np.ndarray:
        if column is None:
            raise ValueError(f"{purpose} column must be specified")
        if isinstance(column, int):
            idx = column
        else:
            if not headers:
                raise ValueError("column names were provided but input file has no header")
            try:
                idx = headers.index(column)
            except ValueError as exc:
                raise ValueError(f"column '{column}' not found in header {headers}") from exc
        try:
            data = np.asarray(columns[idx], dtype=float)
        except IndexError as exc:
            raise ValueError(f"column index {idx} out of range for input with {len(columns)} columns") from exc
        return data

    position = resolve(distance_column, "distance")

    if real_column is not None and imag_column is not None:
        real = resolve(real_column, "real")
        imag = resolve(imag_column, "imaginary")
        gamma = real + 1j * imag
    elif magnitude_column is not None and phase_column is not None:
        mag = resolve(magnitude_column, "magnitude")
        phase = resolve(phase_column, "phase")
        if phase_degrees:
            phase = np.deg2rad(phase)
        gamma = mag * np.exp(1j * phase)
    else:
        raise ValueError("must supply either real+imag columns or magnitude+phase columns")

    sort_idx = np.argsort(position)
    position = position[sort_idx]
    gamma = gamma[sort_idx]

    return ReflectionTrace(position=position, gamma=gamma)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("trace", type=Path, help="CSV file containing the reflection trace")
    parser.add_argument("--distance", dest="distance", required=True, help="Distance/frequency column (name or zero-based index)")
    parser.add_argument("--real", dest="real", help="Real part column (name or index)")
    parser.add_argument("--imag", dest="imag", help="Imaginary part column (name or index)")
    parser.add_argument("--magnitude", dest="magnitude", help="Magnitude column (name or index)")
    parser.add_argument("--phase", dest="phase", help="Phase column (name or index)")
    parser.add_argument("--phase-degrees", dest="phase_degrees", action="store_true", help="Interpret phase column as degrees")
    parser.add_argument("--alpha-units", dest="alpha_units", default="nepers", help="Label for alpha units (default: nepers)")
    parser.add_argument("--beta-units", dest="beta_units", default="rad/m", help="Label for beta units (default: rad/m)")
    parser.add_argument("--figure", dest="figure", type=Path, help="Optional path to save a PNG figure of measured vs fitted spiral")
    parser.add_argument("--vendor-alpha", dest="vendor_alpha", type=float, help="Optional vendor-provided |alpha| for error reporting")
    parser.add_argument("--title", dest="title", help="Optional plot title when --figure is supplied")
    return parser


def format_report(
    path: Path,
    spiral: SpiralEstimate,
    line: LineEstimate,
    alpha_units: str,
    beta_units: str,
    vendor_alpha: float | None = None,
) -> str:
    lines = [
        f"Trace: {path}",
        f"Pitch (d ln|Gamma| / d theta): {spiral.pitch:+.6f}",
        f"Spiralness (0=circle, 1=ideal spiral): {spiral.spiralness:.3f}",
        f"Beta estimate: {line.beta:+.6e} {beta_units}",
        f"Alpha estimate (signed): {line.alpha:+.6e} {alpha_units}",
        f"Alpha magnitude: {line.alpha_magnitude:.6e} {alpha_units}",
        f"ĉ = -alpha/beta: {line.c_hat:+.6f}",
        f"Slope dtheta/dx: {line.slope_theta_vs_position:+.6e} rad/unit",
    ]
    if vendor_alpha is not None:
        error_pct = abs(line.alpha_magnitude - vendor_alpha) / vendor_alpha * 100.0
        lines.append(f"Vendor alpha: {vendor_alpha:.6e} {alpha_units} (error {error_pct:.2f}%)")
    return "\n".join(lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    distance = _coerce_column(args.distance)
    real = _coerce_column(args.real)
    imag = _coerce_column(args.imag)
    magnitude = _coerce_column(args.magnitude)
    phase = _coerce_column(args.phase)

    try:
        trace = load_trace(
            path=args.trace,
            distance_column=distance,
            real_column=real,
            imag_column=imag,
            magnitude_column=magnitude,
            phase_column=phase,
            phase_degrees=args.phase_degrees,
        )
        spiral, line = estimate_line(trace)
    except Exception as exc:  # pragma: no cover - CLI level error reporting
        parser.error(str(exc))
        return 2

    print(format_report(args.trace, spiral, line, args.alpha_units, args.beta_units, args.vendor_alpha))

    if args.figure is not None:
        fitted = reconstruct_spiral(trace, spiral, line)
        try:
            save_spiral_figure(
                args.figure,
                trace,
                fitted,
                vendor_alpha=args.vendor_alpha,
                line=line,
                title=args.title,
            )
        except Exception as exc:  # pragma: no cover - matplotlib import/runtime errors
            parser.error(str(exc))
            return 2

    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())

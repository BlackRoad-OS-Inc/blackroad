"""CLI wrapper around :func:`tools.rf.spiral_loss.spiral_pitch`."""

from __future__ import annotations

import argparse
import csv
import json
import sys
from dataclasses import asdict
from pathlib import Path
from typing import Sequence

import numpy as np

from tools.rf.spiral_loss import SpiralEstimate, spiral_pitch


def _read_csv(path: Path) -> tuple[list[str], list[list[float]]]:
    with path.open("r", newline="") as handle:
        reader = csv.reader(handle)
        headers: list[str] = []
        rows: list[list[float]] = []
        for idx, row in enumerate(reader):
            if idx == 0 and _row_is_header(row):
                headers = [cell.strip() for cell in row]
                continue
            if not row:
                continue
            try:
                rows.append([float(cell) for cell in row])
            except ValueError as exc:  # pragma: no cover - CLI path
                raise ValueError(f"Non-numeric value on line {idx + 1}") from exc
    if not rows:
        raise ValueError("input file contains no numeric rows")
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


def _resolve_column(
    headers: list[str],
    columns: list[list[float]],
    selector: str | int | None,
    label: str,
) -> np.ndarray:
    if selector is None:
        raise ValueError(f"{label} column must be provided")
    if isinstance(selector, int):
        index = selector
    else:
        if not headers:
            raise ValueError("column names supplied but the file has no header row")
        try:
            index = headers.index(selector)
        except ValueError as exc:
            raise ValueError(f"column '{selector}' not found in header {headers}") from exc
    try:
        data = np.asarray(columns[index], dtype=float)
    except IndexError as exc:
        raise ValueError(f"column index {index} out of range for input with {len(columns)} columns") from exc
    return data


def load_gamma(
    path: Path,
    real_column: str | int | None,
    imag_column: str | int | None,
    magnitude_column: str | int | None,
    phase_column: str | int | None,
    phase_degrees: bool,
) -> np.ndarray:
    """Load a complex array from ``path`` using the provided column selectors."""

    headers, rows = _read_csv(path)
    columns = list(zip(*rows))

    if real_column is not None and imag_column is not None:
        real = _resolve_column(headers, columns, real_column, "real")
        imag = _resolve_column(headers, columns, imag_column, "imaginary")
        gamma = real + 1j * imag
    elif magnitude_column is not None and phase_column is not None:
        mag = _resolve_column(headers, columns, magnitude_column, "magnitude")
        phase = _resolve_column(headers, columns, phase_column, "phase")
        if phase_degrees:
            phase = np.deg2rad(phase)
        gamma = mag * np.exp(1j * phase)
    else:
        raise ValueError("provide either real+imag or magnitude+phase columns")

    return gamma


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("samples", type=Path, help="CSV file containing complex samples")
    parser.add_argument("--real", dest="real", help="Real part column (name or zero-based index)")
    parser.add_argument("--imag", dest="imag", help="Imaginary part column (name or zero-based index)")
    parser.add_argument("--magnitude", dest="magnitude", help="Magnitude column (name or zero-based index)")
    parser.add_argument("--phase", dest="phase", help="Phase column (name or zero-based index)")
    parser.add_argument("--phase-degrees", action="store_true", help="Interpret phase column as degrees (default: radians)")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of text")
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Suppress slope/intercept fields when printing text output",
    )
    return parser


def format_text(path: Path, estimate: SpiralEstimate, summary_only: bool) -> str:
    lines: list[str] = [
        f"Samples: {path}",
        f"Pitch (d ln r / d theta): {estimate.pitch:+.6f}",
        f"Spiralness (0=circle, 1=ideal): {estimate.spiralness:.3f}",
    ]
    if not summary_only:
        lines.extend(
            [
                f"Slope (rho vs theta): {estimate.rho_slope:+.6f}",
                f"Intercept (rho vs theta): {estimate.rho_intercept:+.6f}",
            ]
        )
    return "\n".join(lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    real = _coerce_column(args.real)
    imag = _coerce_column(args.imag)
    magnitude = _coerce_column(args.magnitude)
    phase = _coerce_column(args.phase)

    try:
        gamma = load_gamma(
            path=args.samples,
            real_column=real,
            imag_column=imag,
            magnitude_column=magnitude,
            phase_column=phase,
            phase_degrees=args.phase_degrees,
        )
        estimate = spiral_pitch(gamma)
    except Exception as exc:  # pragma: no cover - CLI level error reporting
        parser.error(str(exc))
        return 2

    if args.json:
        payload = {"path": str(args.samples), **asdict(estimate)}
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(format_text(args.samples, estimate, summary_only=args.summary_only))

    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())

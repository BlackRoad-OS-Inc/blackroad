"""Perspective depth solver utilities."""

from __future__ import annotations

import argparse
from typing import Sequence


def depth_from_rail(
    z_a: float,
    z_b: float,
    s_a: float,
    s_b: float,
    s_c: float,
) -> float:
    """Return the physical depth of point ``C`` along a perspective rail.

    Parameters
    ----------
    z_a, z_b:
        Known scene depths (``Z_A`` and ``Z_B``) for two reference marks ``A`` and
        ``B`` positioned along the same receding rail.
    s_a, s_b, s_c:
        Measured coordinates on the drawing (``s(A)``, ``s(B)``, ``s(C)``) taken
        along the straight line that represents the rail.

    The computation follows the closed-form projective relation::

        alpha = (s_a - s_c) / (s_b - s_c)
        Z_C = (alpha * Z_B - Z_A) / (alpha - 1)

    Returns
    -------
    float
        The recovered depth ``Z_C`` for the target point ``C``.

    Raises
    ------
    ValueError
        If any intermediate denominator is zero, indicating a degenerate
        configuration of sample points.
    """

    denom_sb_sc = s_b - s_c
    if denom_sb_sc == 0:
        raise ValueError("s(B) and s(C) must be distinct to define the cross-ratio")

    alpha = (s_a - s_c) / denom_sb_sc
    denom_alpha = alpha - 1.0
    if denom_alpha == 0:
        raise ValueError("alpha must not equal 1; choose reference points spanning C")

    return (alpha * z_b - z_a) / denom_alpha


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Compute the depth of a perspective point along a rail using the "
            "cross-ratio relation with the far point at infinity."
        )
    )
    parser.add_argument(
        "depths",
        nargs=2,
        metavar=("Z_A", "Z_B"),
        type=float,
        help="Known physical depths for reference marks A and B.",
    )
    parser.add_argument(
        "coords",
        nargs=3,
        metavar=("sA", "sB", "sC"),
        type=float,
        help="Measured drawing coordinates along the rail for A, B, and target C.",
    )

    args = parser.parse_args(argv)
    z_a, z_b = args.depths
    s_a, s_b, s_c = args.coords

    z_c = depth_from_rail(z_a, z_b, s_a, s_b, s_c)
    print(f"Z_C={z_c}")
"""Perspective depth solver using cross-ratio interpolation.

This helper works with a single calibrated rail (or any straight
feature) and estimates the depth of a target point ``C`` once the
endpoint depths ``ZA`` and ``ZB`` are known.  The solver operates purely
on projective geometry: it converts the chosen points into a 1D
coordinate system along the rail, computes the cross-ratio between the
three samples (``A``, ``B``, ``C``) and the vanishing point, and maps the
result back to the requested depth unit.

Two measurement modes are supported:

``--A/--B/--C``
    Raw 2D image coordinates (``x,y``) for the samples.  The script
    projects them onto the rail defined by ``A`` and ``B`` and derives a
    consistent 1D scale.
``--s``
    Pre-measured scalars ``sA,sB,sC`` along the rail.  These might come
    from ruler measurements on the print, a CAD export, or any other
    scalar parameterisation you already prepared.

An optional ``--vanish`` argument can be used when the rail's vanishing
point is known in the image.  If omitted, the solver assumes that the
1D parameterisation already has the vanishing point at infinity (which is
true for ruler measurements or when the rail is parallel to the image
plane).

Example
-------

.. code-block:: bash

    python tools/projective/depth_solver.py --ZA 0 --ZB 1 \
      --A 100,400 --B 350,220 --C 270,260 --pretty

    python tools/projective/depth_solver.py --ZA 0 --ZB 1 \
      --s 0,5.0,8.25 --pretty
"""
from __future__ import annotations

import argparse
import json
import math
from dataclasses import dataclass
from typing import Iterable, Optional, Sequence, Tuple


@dataclass(frozen=True)
class RailPoints:
    """Container describing three aligned samples on the rail."""

    sA: float
    sB: float
    sC: float
    sV: Optional[float] = None

    @classmethod
    def from_coords(
        cls,
        a: Sequence[float],
        b: Sequence[float],
        c: Sequence[float],
        vanish: Optional[Sequence[float]] = None,
    ) -> "RailPoints":
        """Create a :class:`RailPoints` instance from 2D coordinates.

        The method flattens the 2D data into a 1D coordinate system that is
        aligned with the rail.  The axis origin is anchored at ``A``.
        """

        def to_vector(pt: Sequence[float]) -> Tuple[float, float]:
            if len(pt) != 2:
                raise ValueError("Coordinates must be 2D (x,y)")
            return float(pt[0]), float(pt[1])

        ax, ay = to_vector(a)
        bx, by = to_vector(b)
        cx, cy = to_vector(c)
        direction = (bx - ax, by - ay)
        norm = math.hypot(*direction)
        if norm == 0:
            raise ValueError("Points A and B must not coincide")
        ux, uy = direction[0] / norm, direction[1] / norm

        def project(px: float, py: float) -> float:
            return (px - ax) * ux + (py - ay) * uy

        sA = 0.0
        sB = project(bx, by)
        sC = project(cx, cy)
        sV = None
        if vanish is not None:
            vx, vy = to_vector(vanish)
            sV = project(vx, vy)
        return cls(sA=sA, sB=sB, sC=sC, sV=sV)

    @classmethod
    def from_scalars(cls, scalars: Iterable[float]) -> "RailPoints":
        scalars = list(float(v) for v in scalars)
        if len(scalars) != 3:
            raise ValueError("Expected three scalars for sA,sB,sC")
        return cls(sA=scalars[0], sB=scalars[1], sC=scalars[2])

    def cross_ratio_parameter(self) -> float:
        """Return the cross-ratio parameter ``alpha``.

        ``alpha`` captures the projective interpolation factor between the
        known depths.  When a vanishing point is available we use the full
        cross-ratio, otherwise we fall back to the simplified form where the
        vanishing point lies at infinity.
        """

        if self.sC == self.sB:
            raise ValueError("Point C coincides with B in the chosen scale")

        numerator = self.sC - self.sA
        denominator = self.sC - self.sB
        alpha = numerator / denominator
        if self.sV is not None:
            if self.sV == self.sA:
                raise ValueError("Vanishing point coincides with A")
            if self.sV == self.sB:
                raise ValueError("Vanishing point coincides with B")
            alpha *= (self.sV - self.sB) / (self.sV - self.sA)
        return alpha


def parse_point(value: str) -> Tuple[float, float]:
    try:
        x_str, y_str = value.split(",", 1)
        return float(x_str.strip()), float(y_str.strip())
    except ValueError as exc:  # pragma: no cover - defensive parsing
        raise argparse.ArgumentTypeError(
            f"Could not parse coordinate '{value}'. Expected 'x,y'."
        ) from exc


def parse_scalars(value: str) -> Tuple[float, float, float]:
    try:
        parts = [float(part.strip()) for part in value.split(",")]
    except ValueError as exc:  # pragma: no cover - defensive parsing
        raise argparse.ArgumentTypeError(
            f"Could not parse scalars '{value}'. Expected comma-separated floats."
        ) from exc
    if len(parts) != 3:
        raise argparse.ArgumentTypeError(
            f"Expected three scalars for sA,sB,sC, received {len(parts)}"
        )
    return parts[0], parts[1], parts[2]


def solve_depth(points: RailPoints, za: float, zb: float) -> Tuple[float, float]:
    """Compute the projective interpolation coefficient and depth."""

    alpha = points.cross_ratio_parameter()
    if math.isclose(alpha, 1.0):
        raise ValueError("Degenerate configuration: alpha approaches 1")
    zc = (za - alpha * zb) / (1.0 - alpha)
    return alpha, zc


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ZA", type=float, required=True, help="Depth at point A")
    parser.add_argument("--ZB", type=float, required=True, help="Depth at point B")

    parser.add_argument("--A", type=parse_point, help="Pixel coordinate for point A")
    parser.add_argument("--B", type=parse_point, help="Pixel coordinate for point B")
    parser.add_argument("--C", type=parse_point, help="Pixel coordinate for point C")
    parser.add_argument(
        "--vanish",
        type=parse_point,
        help="Optional vanishing point coordinate for the rail",
    )
    parser.add_argument(
        "--s",
        type=parse_scalars,
        help="Comma-separated scalar measurements sA,sB,sC",
    )
    parser.add_argument(
        "--pretty",
        action="store_true",
        help="Pretty-print the resulting JSON",
    )
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.s is None:
        if args.A is None or args.B is None or args.C is None:
            parser.error("Provide either --s or all of --A/--B/--C")
        points = RailPoints.from_coords(args.A, args.B, args.C, args.vanish)
    else:
        if args.A or args.B or args.C:
            parser.error("Use either scalar measurements or raw coordinates, not both")
        points = RailPoints.from_scalars(args.s)
        if args.vanish is not None:
            parser.error("Vanishing point can only be used with coordinate input")

    alpha, zc = solve_depth(points, args.ZA, args.ZB)
    payload = {"alpha": alpha, "ZC": zc}
    if args.pretty:
        print(json.dumps(payload, indent=2))
    else:
        print(json.dumps(payload))
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    raise SystemExit(main())

"""Projective cross-ratio utilities and command line helper."""

from __future__ import annotations

import argparse
from typing import Iterable, Sequence, Tuple

import numpy as np


Point2D = Tuple[float, float]


def _to_array(point: Sequence[float]) -> np.ndarray:
    arr = np.asarray(point, dtype=float)
    if arr.shape != (2,):
        raise ValueError(f"expected 2D point, received shape {arr.shape}")
    return arr


def line_coord(point: Sequence[float], a: Sequence[float], b: Sequence[float]) -> float:
    """Return the signed coordinate of *point* along the line through *a* → *b*.

    The origin of the coordinate system is placed at *a* and the axis is aligned
    with the direction from *a* to *b*. A positive result indicates the point
    lies in the forward direction from *a* towards *b*.
    """

    a_arr = _to_array(a)
    b_arr = _to_array(b)
    p_arr = _to_array(point)

    direction = b_arr - a_arr
    length = np.linalg.norm(direction)
    if length == 0:
        raise ValueError("reference points A and B must be distinct")
    unit_direction = direction / length
    return float(np.dot(p_arr - a_arr, unit_direction))


def cross_ratio(a: Sequence[float], b: Sequence[float], c: Sequence[float], d: Sequence[float]) -> float:
    """Compute the projective cross-ratio for four collinear points."""

    coords = [line_coord(p, a, b) for p in (a, b, c, d)]
    aa, bb, cc, dd = coords
    numerator = (aa - cc) * (bb - dd)
    denominator = (aa - dd) * (bb - cc)
    if denominator == 0:
        raise ValueError("degenerate configuration: denominator is zero")
    return float(numerator / denominator)


def homography_from_quad(
    quad: Iterable[Sequence[float]],
    target: Iterable[Sequence[float]] = ((0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)),
) -> np.ndarray:
    """Return the 3×3 homography that maps *quad* onto *target*.

    Parameters
    ----------
    quad:
        Iterable of four 2D points describing the source quadrilateral.
    target:
        Iterable of four 2D points that define the destination quadrilateral.
    """

    quad_pts = [_to_array(pt) for pt in quad]
    target_pts = [_to_array(pt) for pt in target]
    if len(quad_pts) != 4 or len(target_pts) != 4:
        raise ValueError("homography expects four source and four target points")

    matrix = []
    rhs = []
    for (x, y), (X, Y) in zip(quad_pts, target_pts):
        matrix.append([x, y, 1.0, 0.0, 0.0, 0.0, -X * x, -X * y])
        matrix.append([0.0, 0.0, 0.0, x, y, 1.0, -Y * x, -Y * y])
        rhs.append(X)
        rhs.append(Y)

    m_arr = np.asarray(matrix, dtype=float)
    rhs_arr = np.asarray(rhs, dtype=float)
    solution, *_ = np.linalg.lstsq(m_arr, rhs_arr, rcond=None)
    h = np.append(solution, [1.0])
    return h.reshape(3, 3)


def warp_point(point: Sequence[float], homography: np.ndarray) -> Point2D:
    """Apply a homography to a 2D point and return the affine projection."""

    if homography.shape != (3, 3):
        raise ValueError("homography must be a 3x3 matrix")
    x, y = _to_array(point)
    homogeneous = homography @ np.array([x, y, 1.0], dtype=float)
    if homogeneous[2] == 0:
        raise ValueError("homogeneous coordinate is zero; cannot project")
    return float(homogeneous[0] / homogeneous[2]), float(homogeneous[1] / homogeneous[2])


def _parse_point(text: str) -> Point2D:
    stripped = text.strip()
    if stripped.startswith("(") and stripped.endswith(")"):
        stripped = stripped[1:-1]
    pieces = stripped.replace(",", " ").split()
    if len(pieces) != 2:
        raise argparse.ArgumentTypeError(f"could not parse point from '{text}'")
    try:
        x, y = (float(piece) for piece in pieces)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc
    return (x, y)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Compute projective cross-ratios and helper homographies.")
    parser.add_argument(
        "points",
        nargs=4,
        metavar="x,y",
        help="Four collinear points (A B C D) supplied as 'x,y'.",
        type=_parse_point,
    )
    parser.add_argument(
        "--quad",
        nargs=4,
        metavar="x,y",
        type=_parse_point,
        help="Optional quadrilateral to rectify; prints the homography matrix.",
    )
    parser.add_argument(
        "--target",
        nargs=4,
        metavar="x,y",
        type=_parse_point,
        help="Destination quadrilateral when using --quad (defaults to the unit square).",
    )
    parser.add_argument(
        "--warp-point",
        metavar="x,y",
        type=_parse_point,
        help="If provided with --quad, applies the homography to this point and prints the warped coordinate.",
    )
    args = parser.parse_args(argv)

    cr_value = cross_ratio(*args.points)
    print(f"cross_ratio={cr_value}")

    if args.quad:
        target = args.target if args.target else ((0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0))
        homography = homography_from_quad(args.quad, target)
        print("homography=")
        for row in homography:
            print(" ".join(f"{value:.6f}" for value in row))
        if args.warp_point:
            warped = warp_point(args.warp_point, homography)
            print(f"warped_point=({warped[0]}, {warped[1]})")

    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    raise SystemExit(main())

"""Trigonometric helpers for power/root operations."""

from __future__ import annotations

import argparse
import math
from typing import Sequence


def sqrt01(x: float) -> float:
    """Return the principal square-root for ``x`` in the unit interval.

    Uses the exact trigonometric identity

    .. math:: \sqrt{x} = \cos\left(\tfrac{1}{2}\arccos(2x - 1)\right)

    which is valid for :math:`0 \le x \le 1`.
    """

    if not 0.0 <= x <= 1.0:
        raise ValueError("sqrt01 expects 0 <= x <= 1")
    return math.cos(0.5 * math.acos(2.0 * x - 1.0))


def cheb_root(x: float, n: int) -> float:
    """Return ``y`` such that ``T_n(y) = x`` using Chebyshev angle-splitting."""

    if n <= 0:
        raise ValueError("n must be a positive integer")
    if not -1.0 <= x <= 1.0:
        raise ValueError("|x| must not exceed 1 for the principal Chebyshev branch")
    return math.cos(math.acos(x) / n)


def log_spiral_pitch(c: float, power: float) -> float:
    """Return the pitch of ``r = exp(c * theta)`` after ``z -> z**power``."""

    if power == 0:
        raise ValueError("power must be non-zero")
    return c


def demo_spiral_pitch(c: float, power: float) -> str:
    """Produce a short report illustrating pitch invariance for a log-spiral."""

    pitch = log_spiral_pitch(c, power)
    lines = [
        f"Input pitch: {c}",
        f"Transform: z -> z^{power}",
        f"Resulting pitch: {pitch}",
    ]
    return "\n".join(lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Trigonometric power/root utilities.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    sqrt_parser = subparsers.add_parser("sqrt", help="Evaluate sqrt(x) on [0,1] via cosine.")
    sqrt_parser.add_argument("x", type=float, help="Value in [0,1] to evaluate.")

    cheb_parser = subparsers.add_parser("cheb", help="Solve T_n(y) = x for y via angle division.")
    cheb_parser.add_argument("x", type=float, help="Cosine value x in [-1,1].")
    cheb_parser.add_argument("n", type=int, help="Positive integer power n.")

    demo_parser = subparsers.add_parser(
        "pitch", help="Demonstrate log-spiral pitch invariance under powers/roots."
    )
    demo_parser.add_argument("c", type=float, help="Log-spiral pitch constant c.")
    demo_parser.add_argument("power", type=float, help="Power/root exponent to apply.")

    args = parser.parse_args(argv)
    if args.command == "sqrt":
        value = sqrt01(args.x)
        print(f"sqrt({args.x})={value}")
    elif args.command == "cheb":
        value = cheb_root(args.x, args.n)
        print(f"cheb_root(x={args.x}, n={args.n})={value}")
    else:
        report = demo_spiral_pitch(args.c, args.power)
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

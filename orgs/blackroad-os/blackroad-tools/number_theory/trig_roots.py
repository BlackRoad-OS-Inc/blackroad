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
"""Trigonometric root and power helpers for the Amundson toolchain."""
from __future__ import annotations

import argparse
import json
import math
from typing import Dict, Optional, Sequence


def sqrt_unit_interval(x: float) -> float:
    """Return ``sqrt(x)`` using a cosine half-angle identity."""

    if not 0.0 <= x <= 1.0:
        raise ValueError("sqrt01 expects x in [0, 1]")
    return math.cos(0.5 * math.acos(2.0 * x - 1.0))


def chebyshev_nth_root(x: float, n: int) -> float:
    """Chebyshev-style ``n``\ th root on [-1, 1]."""

    if not -1.0 <= x <= 1.0:
        raise ValueError("cheb expects x in [-1, 1]")
    if n == 0:
        raise ValueError("cheb expects a non-zero n")
    return math.cos(math.acos(x) / n)


def complex_to_polar(a: float, b: float) -> Dict[str, float]:
    r = math.hypot(a, b)
    theta = math.atan2(b, a)
    return {"r": r, "theta": theta}


def complex_root(a: float, b: float, n: int, k: int) -> Dict[str, float]:
    if n <= 0:
        raise ValueError("n must be positive")
    polar = complex_to_polar(a, b)
    magnitude = polar["r"] ** (1.0 / n)
    angle = (polar["theta"] + 2.0 * math.pi * k) / n
    return {"real": magnitude * math.cos(angle), "imag": magnitude * math.sin(angle)}


def complex_power(a: float, b: float, n: int) -> Dict[str, float]:
    polar = complex_to_polar(a, b)
    magnitude = polar["r"] ** n
    angle = polar["theta"] * n
    return {"real": magnitude * math.cos(angle), "imag": magnitude * math.sin(angle)}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="cmd", required=True)

    sqrt_parser = subparsers.add_parser("sqrt01", help="Exact sqrt on [0,1]")
    sqrt_parser.add_argument("--x", type=float, required=True)
    sqrt_parser.add_argument("--pretty", action="store_true")

    cheb_parser = subparsers.add_parser("cheb", help="Chebyshev nth-root on [-1,1]")
    cheb_parser.add_argument("--x", type=float, required=True)
    cheb_parser.add_argument("--n", type=int, required=True)
    cheb_parser.add_argument("--pretty", action="store_true")

    root_parser = subparsers.add_parser("root", help="Complex nth root")
    root_parser.add_argument("--a", type=float, required=True)
    root_parser.add_argument("--b", type=float, required=True)
    root_parser.add_argument("--n", type=int, required=True)
    root_parser.add_argument("--k", type=int, default=0)
    root_parser.add_argument("--pretty", action="store_true")

    power_parser = subparsers.add_parser("power", help="Complex power via polar form")
    power_parser.add_argument("--a", type=float, required=True)
    power_parser.add_argument("--b", type=float, required=True)
    power_parser.add_argument("--n", type=int, required=True)
    power_parser.add_argument("--pretty", action="store_true")
    return parser


def dispatch(cmd: str, args: argparse.Namespace) -> Dict[str, float]:
    if cmd == "sqrt01":
        return {"sqrt": sqrt_unit_interval(args.x)}
    if cmd == "cheb":
        return {"root": chebyshev_nth_root(args.x, args.n)}
    if cmd == "root":
        return complex_root(args.a, args.b, args.n, args.k)
    if cmd == "power":
        return complex_power(args.a, args.b, args.n)
    raise ValueError(f"Unknown command: {cmd}")


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    payload = dispatch(args.cmd, args)
    if getattr(args, "pretty", False):
        print(json.dumps(payload, indent=2))
    else:
        print(json.dumps(payload))
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    raise SystemExit(main())

"""Command line interface for modular exponentiation time signatures."""

from __future__ import annotations

import argparse
from typing import Iterable, List

from tools.timekeys import (
    modexp_signature_from_string,
    normalize_time_string,
    time_to_int,
)


DEFAULT_PRIMES: List[int] = [
    97,
    101,
    251,
    257,
    263,
    509,
    1009,
    1223,
    4099,
    6151,
    8191,
    65537,
    99991,
]


def _parse_primes(values: Iterable[str]) -> List[int]:
    primes: List[int] = []
    for value in values:
        if not value:
            continue
        try:
            primes.append(int(value, 10))
        except ValueError as exc:  # pragma: no cover - CLI validation
            raise argparse.ArgumentTypeError(
                f"Invalid prime value {value!r}"
            ) from exc
    return primes


def _format_table(rows: List[dict]) -> str:
    headers = ["prime", "ord_10", "N_mod_ord", "residue", "theta_rad"]
    str_rows = [
        [
            f"{row['prime']}",
            f"{row['ord_10']}",
            f"{row['N_mod_ord']}",
            f"{row['residue']}",
            f"{row['theta_rad']:.12f}",
        ]
        for row in rows
    ]

    widths = [len(header) for header in headers]
    for row in str_rows:
        for idx, column in enumerate(row):
            widths[idx] = max(widths[idx], len(column))

    def fmt(columns: Iterable[str]) -> str:
        return "  ".join(col.ljust(widths[idx]) for idx, col in enumerate(columns))

    output_lines = [fmt(headers), fmt(["-" * width for width in widths])]
    output_lines.extend(fmt(row) for row in str_rows)
    return "\n".join(output_lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Generate modular exponentiation signatures for timestamp strings. "
            "Outputs a residue table for the given primes."
        )
    )
    parser.add_argument("time", help="Timestamp string to normalise")
    parser.add_argument(
        "--unit",
        choices=["s", "ms", "us", "ns"],
        default="ms",
        help="Output unit for the epoch integer (default: ms)",
    )
    parser.add_argument(
        "--default-tz",
        default="UTC",
        help="Timezone to assume when parsing naive timestamps (default: UTC)",
    )
    parser.add_argument(
        "--dayfirst",
        default="auto",
        help="Interpret ambiguous dates as day-first (auto|true|false)",
    )
    parser.add_argument(
        "--primes",
        nargs="*",
        help="Optional list of primes (default set is used when omitted)",
    )

    args = parser.parse_args()

    primes = _parse_primes(args.primes) if args.primes else DEFAULT_PRIMES
    dt_utc = normalize_time_string(
        args.time, default_tz=args.default_tz, dayfirst=args.dayfirst
    )
    epoch_value = time_to_int(dt_utc, unit=args.unit)
    signatures = modexp_signature_from_string(
        args.time,
        primes=primes,
        unit=args.unit,
        default_tz=args.default_tz,
        dayfirst=args.dayfirst,
    )

    print(f"input: {args.time}")
    print(f"normalized_utc: {dt_utc.isoformat()}")
    print(f"epoch_{args.unit}: {epoch_value}")
    print()
    if signatures:
        print(_format_table(signatures))
    else:
        print("(no valid primes supplied)")


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    main()

"""Utilities for deriving modular-exponent signatures from timestamp strings."""

from __future__ import annotations

import math
import re
from datetime import datetime
from typing import Dict, Iterable, List
from zoneinfo import ZoneInfo


_FRACTIONAL_SECONDS_PATTERN = re.compile(
    r"(\d{2}:\d{2}:\d{2}):(\d{1,9})(Z?)$"
)


def _coerce_dayfirst_flag(dayfirst: bool | str) -> str:
    """Normalise the ``dayfirst`` flag into ``"auto"``, ``"mdy"`` or ``"dmy"``."""

    if isinstance(dayfirst, str):
        key = dayfirst.strip().lower()
        if key in {"auto", ""}:
            return "auto"
        if key in {"true", "yes", "dmy", "dayfirst"}:
            return "dmy"
        if key in {"false", "no", "mdy", "monthfirst"}:
            return "mdy"
        raise ValueError(
            "dayfirst must be one of 'auto', 'true', 'false', 'dmy', or 'mdy'"
        )
    return "dmy" if dayfirst else "mdy"


def normalize_time_string(
    s: str, *, default_tz: str = "UTC", dayfirst: bool | str = "auto"
) -> datetime:
    """Parse a wide variety of timestamp strings into a timezone-aware UTC datetime."""

    if not s:
        raise ValueError("Input time string must be non-empty")

    value = s.strip()
    value = _FRACTIONAL_SECONDS_PATTERN.sub(r"\1.\2\3", value)

    tzinfo = ZoneInfo(default_tz)
    dayfirst_mode = _coerce_dayfirst_flag(dayfirst)

    if value.endswith("Z"):
        base = value[:-1]
        try:
            dt = datetime.fromisoformat(base)
        except ValueError:
            dt = None
        if dt is not None:
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=ZoneInfo("UTC"))
            else:
                dt = dt.astimezone(ZoneInfo("UTC"))
            return dt
        value = base
        tzinfo = ZoneInfo("UTC")

    try:
        dt = datetime.fromisoformat(value)
    except ValueError:
        dt = None

    if dt is not None:
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=tzinfo)
        return dt.astimezone(ZoneInfo("UTC"))

    mdy_formats = ["%m:%d:%Y %H:%M:%S.%f", "%m:%d:%Y"]
    dmy_formats = ["%d:%m:%Y %H:%M:%S.%f", "%d:%m:%Y"]

    formats: List[str]
    if dayfirst_mode == "auto":
        formats = [
            "%Y-%m-%d %H:%M:%S.%f",
            "%Y-%m-%d %H:%M:%S",
            "%Y-%m-%d",
            *dmy_formats,
            *mdy_formats,
        ]
    elif dayfirst_mode == "dmy":
        formats = [*dmy_formats, *mdy_formats]
    else:
        formats = [*mdy_formats, *dmy_formats]

    for fmt in formats:
        try:
            dt = datetime.strptime(value, fmt).replace(tzinfo=tzinfo)
        except ValueError:
            continue
        return dt.astimezone(ZoneInfo("UTC"))

    raise ValueError(f"Unrecognized time format: {s!r}")


def time_to_int(dt: datetime, *, unit: str = "ms") -> int:
    """Convert a timezone-aware datetime to an integer epoch in the requested units."""

    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=ZoneInfo("UTC"))
    dt_utc = dt.astimezone(ZoneInfo("UTC"))

    factors = {"s": 1, "ms": 1_000, "us": 1_000_000, "ns": 1_000_000_000}
    if unit not in factors:
        raise ValueError(f"Unsupported unit: {unit!r}")

    epoch_seconds = dt_utc.timestamp()
    return int(round(epoch_seconds * factors[unit]))


def prime_factors(n: int) -> Dict[int, int]:
    """Return the prime factorisation of ``n`` using trial division."""

    if n < 1:
        raise ValueError("n must be a positive integer")

    result: Dict[int, int] = {}
    divisor = 2
    remainder = n

    while divisor * divisor <= remainder:
        while remainder % divisor == 0:
            result[divisor] = result.get(divisor, 0) + 1
            remainder //= divisor
        divisor = 3 if divisor == 2 else divisor + 2

    if remainder > 1:
        result[remainder] = result.get(remainder, 0) + 1

    return result


def multiplicative_order(a: int, p: int) -> int:
    """Compute the multiplicative order of ``a`` modulo a prime ``p``."""

    if p <= 1:
        raise ValueError("p must be greater than 1")
    if a % p == 0:
        raise ValueError("a and p must be coprime")

    order = p - 1
    for prime, multiplicity in prime_factors(order).items():
        for _ in range(multiplicity):
            candidate = order // prime
            if pow(a, candidate, p) == 1:
                order = candidate
            else:
                break
    return order


def modexp_signature_from_string(
    s: str,
    *,
    primes: Iterable[int],
    unit: str = "ms",
    default_tz: str = "UTC",
    dayfirst: bool | str = "auto",
) -> List[Dict[str, float]]:
    """Build modular exponentiation signatures for the provided time string."""

    dt_utc = normalize_time_string(s, default_tz=default_tz, dayfirst=dayfirst)
    exponent = time_to_int(dt_utc, unit=unit)

    signatures: List[Dict[str, float]] = []
    for prime in primes:
        if prime in (2, 5):
            continue
        base = 10 % prime
        order = multiplicative_order(base, prime)
        reduced_exponent = exponent % order
        residue = pow(base, reduced_exponent, prime)
        theta = math.tau * residue / prime
        signatures.append(
            {
                "prime": prime,
                "ord_10": order,
                "N_mod_ord": reduced_exponent,
                "residue": residue,
                "theta_rad": theta,
            }
        )

    return signatures


__all__ = [
    "modexp_signature_from_string",
    "multiplicative_order",
    "normalize_time_string",
    "prime_factors",
    "time_to_int",
]

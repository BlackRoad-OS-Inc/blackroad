"""Logging configuration helpers."""

from __future__ import annotations

import logging
from pathlib import Path


def setup_logging(log_level: str = "INFO") -> None:
    """Configure structured logging for the console."""

    logging.basicConfig(
        level=getattr(logging, log_level.upper(), logging.INFO),
        format="%(asctime)s [%(levelname)8s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    Path("artifacts").mkdir(exist_ok=True)

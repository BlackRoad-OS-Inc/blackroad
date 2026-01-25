"""Looping showcase demo for the Prism hologram scenes."""

from __future__ import annotations

import argparse
import os
import time
from typing import Iterable, List, Sequence, Tuple

from .holo_cli import MQTTSettings, add_mqtt_arguments, build_settings, parse_params, publish_scene

DEFAULT_INTERVAL = float(os.getenv("HOLO_SHOWCASE_INTERVAL", "5.0"))
DEFAULT_CYCLES = int(os.getenv("HOLO_SHOWCASE_CYCLES", "0"))

SHOWCASE_SEQUENCE: Sequence[Tuple[str, dict]] = (
    (
        "text",
        {
            "text": "Hello Prism",
            "text_color": [0, 200, 255],
        },
    ),
    (
        "shapes",
        {
            "speed": 1.2,
            "color": [255, 120, 80],
        },
    ),
    (
        "aurora",
        {
            "hue": 210,
            "intensity": 0.8,
        },
    ),
    (
        "grid",
        {
            "color": [80, 255, 180],
            "tempo": 0.6,
        },
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Cycle through a curated Prism hologram showcase.")
    parser.add_argument(
        "--interval",
        type=float,
        default=DEFAULT_INTERVAL,
        help="Seconds to wait between scene transitions",
    )
    parser.add_argument(
        "--cycles",
        type=int,
        default=DEFAULT_CYCLES,
        help="Number of times to loop the showcase (0 = infinite)",
    )
    parser.add_argument(
        "--extra",
        action="append",
        default=[],
        help="Optional extra scene payload in scene:key=value format (e.g. text:text='Hi').",
    )
    add_mqtt_arguments(parser)
    return parser


def _parse_extra(extra_args: Iterable[str]) -> List[Tuple[str, dict]]:
    entries: List[Tuple[str, dict]] = []
    for item in extra_args:
        if ":" not in item:
            raise ValueError(f"Invalid extra scene '{item}'. Expected scene:key=value format.")
        scene, payload = item.split(":", 1)
        params = parse_params([payload])
        entries.append((scene, params))
    return entries


def run_showcase(
    *,
    settings: MQTTSettings,
    interval: float,
    cycles: int,
    extra_scenes: Sequence[Tuple[str, dict]],
    verbose: bool,
    dry_run: bool,
) -> None:
    full_sequence: List[Tuple[str, dict]] = list(SHOWCASE_SEQUENCE) + list(extra_scenes)
    if not full_sequence:
        raise RuntimeError("No scenes available for the showcase")

    iteration = 0
    try:
        while cycles <= 0 or iteration < cycles:
            for scene, params in full_sequence:
                publish_scene(
                    scene,
                    params,
                    settings=settings,
                    verbose=verbose,
                    dry_run=dry_run,
                )
                if dry_run:
                    continue
                time.sleep(max(0.0, interval))
            iteration += 1
    except KeyboardInterrupt:
        if verbose or dry_run:
            print("[holo-showcase] interrupted by user")


def main(argv: Iterable[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        extra = _parse_extra(args.extra)
    except ValueError as exc:
        parser.error(str(exc))
        return

    settings = build_settings(args)

    try:
        run_showcase(
            settings=settings,
            interval=args.interval,
            cycles=args.cycles,
            extra_scenes=extra,
            verbose=args.verbose,
            dry_run=args.dry_run,
        )
    except Exception as exc:
        parser.exit(status=1, message=f"error: {exc}\n")


if __name__ == "__main__":
    main()

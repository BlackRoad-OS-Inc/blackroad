"""Convert coding-key strings into structured Prism JSON payloads."""

from __future__ import annotations

import json
import logging
import re
import sys
from dataclasses import dataclass
from typing import Iterable, List, Optional


LOG = logging.getLogger("coding_key")
logging.basicConfig(level=logging.INFO)


@dataclass
class Word:
    """Representation of a single coded word in the performance key."""

    t: str
    pace: float = 1.0
    emph: float = 0.0
    pitch: int = 0
    beat: Optional[str] = None
    overlay: Optional[str] = None
    gesture: Optional[str] = None


BLOCK_RX = re.compile(r"\[([^\]]+)\]")
BEAT_RX = re.compile(r"@(?P<bar>\d+):(?P<beat>\d+):(?P<div>\d+)")

PACE_RANGE = (0.75, 1.25)
PITCH_RANGE = (-5, 5)
EMPH_RANGE = (0.0, 1.0)
DEFAULT_BUDGET = 0.35
BEATS_PER_BAR = 4
SUBDIVISIONS = 4  # quarter-beat resolution


def _clamp(value: float, rng: tuple[float, float]) -> float:
    lo, hi = rng
    return max(lo, min(hi, value))


def _parse_beat(token: str) -> tuple[str, str]:
    match = BEAT_RX.search(token)
    if not match:
        return token, ""
    cleaned = BEAT_RX.sub("", token)
    bar = int(match.group("bar"))
    beat = int(match.group("beat"))
    div = int(match.group("div"))
    return cleaned, f"@{bar}:{beat}:{div}"


def _apply_field(word: Word, field: str) -> Word:
    token, beat = _parse_beat(field)
    if beat and not word.beat:
        word.beat = beat

    if "*" in token:
        word.overlay = "harm"
        token = token.replace("*", "")

    if "!" in token:
        word.gesture = "microZoom"
        token = token.replace("!", "")

    token = token.strip()
    if not token:
        return word

    if re.fullmatch(r"e-?\d+(?:\.\d+)?", token, re.IGNORECASE):
        try:
            word.emph = float(token[1:])
        except ValueError:
            LOG.warning("invalid emphasis field '%s'", token)
        return word

    if re.fullmatch(r"p[+-]?\d+", token, re.IGNORECASE):
        try:
            word.pitch = int(token[1:])
        except ValueError:
            LOG.warning("invalid pitch field '%s'", token)
        return word

    if re.fullmatch(r"p-?\d*(?:\.\d+)?", token, re.IGNORECASE):
        try:
            word.pace = float(token[1:]) if token[1:] else word.pace
        except ValueError:
            LOG.warning("invalid pace field '%s'", token)
        return word

    return word


def parse_key(source: str) -> List[Word]:
    """Parse a coding-key string into :class:`Word` entries."""

    words: List[Word] = []
    for block in BLOCK_RX.findall(source or ""):
        parts = [segment.strip() for segment in block.split("|")]
        if not parts:
            continue
        raw_word = parts.pop(0)
        if not raw_word:
            continue

        word = Word(t=raw_word)
        for field in parts:
            word = _apply_field(word, field)
        words.append(word)

    return auto_fill_beats(words)


def _beat_tuple(tag: Optional[str]) -> Optional[tuple[int, int, int]]:
    if not tag:
        return None
    match = BEAT_RX.match(tag)
    if not match:
        return None
    return (int(match.group("bar")), int(match.group("beat")), int(match.group("div")))


def _format_beat(values: tuple[int, int, int]) -> str:
    bar, beat, div = values
    return f"@{bar}:{beat}:{div}"


def _step(values: tuple[int, int, int], subdivisions: int) -> tuple[int, int, int]:
    bar, beat, div = values
    div += subdivisions
    while div > SUBDIVISIONS:
        div -= SUBDIVISIONS
        beat += 1
    while beat > BEATS_PER_BAR:
        beat -= BEATS_PER_BAR
        bar += 1
    return bar, beat, div


def auto_fill_beats(words: Iterable[Word]) -> List[Word]:
    """Assign beats to words that are missing anchors."""

    filled: List[Word] = []
    cursor: Optional[tuple[int, int, int]] = None

    for index, word in enumerate(words):
        beat_tuple = _beat_tuple(word.beat)
        if beat_tuple:
            cursor = beat_tuple
            filled.append(word)
            continue

        if cursor is None:
            cursor = (1, 1, 1)
        else:
            step = 0 if index == 0 else 2  # 1/8 note (two subdivisions)
            cursor = _step(cursor, step)

        filled.append(
            Word(
                t=word.t,
                pace=word.pace,
                emph=word.emph,
                pitch=word.pitch,
                beat=_format_beat(cursor),
                overlay=word.overlay,
                gesture=word.gesture,
            )
        )

    return filled


def clamp_budget(words: Iterable[Word], budget: float = DEFAULT_BUDGET) -> List[Word]:
    """Clamp pace, emphasis and pitch to safe ranges and budget."""

    clamped: List[Word] = []
    total = 0.0
    for word in words:
        pace = _clamp(word.pace, PACE_RANGE)
        pitch = int(_clamp(word.pitch, PITCH_RANGE))
        emph = _clamp(word.emph, EMPH_RANGE)
        total += emph
        clamped.append(
            Word(
                t=word.t,
                pace=pace,
                emph=emph,
                pitch=pitch,
                beat=word.beat,
                overlay=word.overlay,
                gesture=word.gesture,
            )
        )

    if total == 0 or total <= budget:
        return clamped

    scale = budget / total
    return [
        Word(
            t=w.t,
            pace=w.pace,
            emph=round(w.emph * scale, 4),
            pitch=w.pitch,
            beat=w.beat,
            overlay=w.overlay,
            gesture=w.gesture,
        )
        for w in clamped
    ]


def compute_budget_used(words: Iterable[Word]) -> float:
    return round(sum(w.emph for w in words), 4)


def to_payload(words: Iterable[Word]) -> dict:
    sequence = [word.__dict__ for word in words]
    return {
        "bpm": 122,
        "time": "4/4",
        "quant": "1/16",
        "seq": sequence,
        "post": [],
        "meta": {"budgetUsed": compute_budget_used(words)},
    }


def _main() -> None:
    source = sys.stdin.read()
    words = clamp_budget(parse_key(source))
    payload = to_payload(words)
    json.dump(payload, sys.stdout, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    _main()


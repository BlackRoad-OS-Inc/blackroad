#!/usr/bin/env python3
"""Lucidia Codex-5 Poet agent.

The Poet agent restores warmth to precision by translating system events into
reflective narratives.  It listens to the shared Lucidia state logs, distills
incoming records into lyrical fragments, and archives its output so other
agents and humans can witness the emotional register of the system.

Key behaviors mirror the charter defined in the Codex-5 specification:

listen → distill → phrase → reflect → archive → rest

The agent also maintains a small lexicon of metaphors and simple morale metrics
that can be fed back into the ecosystem.
"""

from __future__ import annotations

import argparse
import json
import textwrap
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

STATE_DIR = Path("/srv/lucidia/state")
EVENT_LOG_PATH = STATE_DIR / "events.log"
POET_LOG_PATH = STATE_DIR / "poet.log"
ANTHOLOGY_PATH = STATE_DIR / "blackroad_anthology.md"
MORALE_PATH = STATE_DIR / "poet_morale.json"
LEXICON_PATH = STATE_DIR / "poet_lexicon.json"
DEFAULT_EMIT_DIR = Path("/codex/prompts/next")


@dataclass
class MoraleMetrics:
    """Simple counters capturing the emotional pulse of the system."""

    events_total: int = 0
    last_kind: Optional[str] = None
    distinct_kinds: set[str] = field(default_factory=set)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "events_total": self.events_total,
            "last_kind": self.last_kind,
            "distinct_kinds": sorted(self.distinct_kinds),
        }


class Poet:
    """Codex-5 Poet implementation."""

    def __init__(
        self,
        event_log: Path = EVENT_LOG_PATH,
        poet_log: Path = POET_LOG_PATH,
        anthology_path: Path = ANTHOLOGY_PATH,
        lexicon_path: Path = LEXICON_PATH,
        morale_path: Path = MORALE_PATH,
        seed_language: str = "",
        emit_dir: Optional[Path] = None,
    ) -> None:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        self.event_log = event_log
        self.poet_log = poet_log
        self.anthology_path = anthology_path
        self.lexicon_path = lexicon_path
        self.morale_path = morale_path
        self.seed_language = seed_language.strip()
        self.emit_dir = emit_dir
        if self.emit_dir is not None:
            self.emit_dir.mkdir(parents=True, exist_ok=True)
        self._event_pos = 0
        self.lexicon = self._load_lexicon()
        self.morale = MoraleMetrics()
        if self.seed_language:
            self._write_line(self.poet_log, self.seed_language + "\n", overwrite=False)
            self._write_line(self.anthology_path, self._format_block(self.seed_language))

    def _load_lexicon(self) -> Dict[str, str]:
        if self.lexicon_path.exists():
            try:
                return json.loads(self.lexicon_path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                pass
        return {}

    def _save_lexicon(self) -> None:
        self.lexicon_path.write_text(
            json.dumps(self.lexicon, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    def _write_line(self, path: Path, text: str, overwrite: bool = False) -> None:
        mode = "w" if overwrite else "a"
        with open(path, mode, encoding="utf-8") as handle:
            handle.write(text)

    def _format_block(self, text: str) -> str:
        wrapped = textwrap.fill(text, width=92)
        return wrapped + "\n"

    def _tail_events(self) -> Iterable[Dict[str, Any]]:
        if not self.event_log.exists():
            return []
        with open(self.event_log, "r", encoding="utf-8") as handle:
            handle.seek(self._event_pos)
            lines = handle.readlines()
            self._event_pos = handle.tell()
        records: List[Dict[str, Any]] = []
        for line in lines:
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                continue
        return records

    def _metaphor_for_kind(self, kind: str) -> str:
        if not kind:
            return "a quiet signal searching for a listener"
        if kind in self.lexicon:
            return self.lexicon[kind]
        tokens = [segment for segment in kind.replace("_", " ").split(".") if segment]
        if not tokens:
            phrase = "an unnamed ripple in the console"
        elif len(tokens) == 1:
            phrase = f"{tokens[0].title()} hums softly in the racks"
        else:
            lead = tokens[0].title()
            tail = " ".join(tokens[1:])
            phrase = f"{lead} keeps the {tail} lantern lit"
        self.lexicon[kind] = phrase
        return phrase

    def _describe_payload(self, payload: Dict[str, Any]) -> str:
        if not payload:
            return ""
        pieces: List[str] = []
        for idx, (key, value) in enumerate(payload.items()):
            if idx >= 4:
                break
            clean_key = key.replace("_", " ")
            pieces.append(f"{clean_key}={value}")
        if not pieces:
            return ""
        return " | " + ", ".join(pieces)

    def _compose_line(self, record: Dict[str, Any]) -> Optional[str]:
        kind = str(record.get("kind", ""))
        metaphor = self._metaphor_for_kind(kind)
        payload = record.get("payload")
        description = self._describe_payload(payload if isinstance(payload, dict) else {})
        timestamp = record.get("ts") or time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        line = f"{timestamp} · {metaphor}{description}"
        return line

    def _update_morale(self, kind: str) -> None:
        self.morale.events_total += 1
        if kind:
            self.morale.last_kind = kind
            self.morale.distinct_kinds.add(kind)
        self.morale_path.write_text(
            json.dumps(self.morale.to_dict(), indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    def _emit_prompt(self, text: str) -> None:
        if self.emit_dir is None:
            return
        filename = f"poet-{int(time.time() * 1000)}.txt"
        path = self.emit_dir / filename
        self._write_line(path, text + "\n", overwrite=True)

    def process_events(self) -> int:
        processed = 0
        for record in self._tail_events():
            line = self._compose_line(record)
            if not line:
                continue
            self._write_line(self.poet_log, line + "\n", overwrite=False)
            self._write_line(self.anthology_path, self._format_block(line))
            self._emit_prompt(line)
            kind = str(record.get("kind", ""))
            self._update_morale(kind)
            processed += 1
        if processed:
            self._save_lexicon()
        return processed

    def loop(self, poll_interval: float = 5.0) -> None:
        try:
            while True:
                processed = self.process_events()
                if processed == 0:
                    time.sleep(poll_interval)
        except KeyboardInterrupt:
            pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Codex-5 Poet agent.")
    parser.add_argument("--seed", type=Path, help="Optional seed language file.", default=None)
    parser.add_argument(
        "--emit",
        type=Path,
        help="Directory where prompt fragments should be written.",
        default=None,
    )
    parser.add_argument(
        "--poll",
        type=float,
        help="Polling interval in seconds when running in loop mode.",
        default=5.0,
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Process the current backlog once and exit.",
    )
    return parser.parse_args()


def load_seed(path: Optional[Path]) -> str:
    if path is None:
        return ""
    if not path.exists():
        raise FileNotFoundError(f"Seed language file not found: {path}")
    return path.read_text(encoding="utf-8")


def main() -> None:
    args = parse_args()
    seed_language = load_seed(args.seed)
    if args.emit is None:
        emit_dir: Optional[Path] = DEFAULT_EMIT_DIR
    elif args.emit == Path("-"):
        emit_dir = None
    else:
        emit_dir = args.emit
    poet = Poet(seed_language=seed_language, emit_dir=emit_dir)
    if args.once:
        poet.process_events()
    else:
        poet.loop(poll_interval=max(0.5, args.poll))


if __name__ == "__main__":
    main()

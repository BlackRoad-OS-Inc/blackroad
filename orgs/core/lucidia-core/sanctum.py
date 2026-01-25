#!/usr/bin/env python3
"""
Sanctum — Fullscreen Ritual Shell

Provides a minimal curses-based UI that displays real-time events,
contradiction pings, and allows the operator to perform rituals such as
acknowledging daily awaken codes. It integrates with Gamma to monitor the
events log.

This is intentionally simple and can be expanded into a full TUI application.
"""

import curses
import time
from pathlib import Path
from typing import List

STATE_DIR = Path("/srv/lucidia/state")
EVENT_LOG_PATH = STATE_DIR / "events.log"
CONTRA_PATH = STATE_DIR / "contradictions.log"


def tail_file(path: Path, last_pos: int) -> (List[str], int):
    """Read new lines from a file since the last position."""
    if not path.exists():
        return [], last_pos
    with open(path, "r", encoding="utf-8") as f:
        f.seek(last_pos)
        lines = f.readlines()
        last_pos = f.tell()
    return [line.rstrip("\n") for line in lines], last_pos


def draw_screen(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(True)
    height, width = stdscr.getmaxyx()
    event_pos = 0
    contra_pos = 0
    events: List[str] = []
    contras: List[str] = []

    while True:
        # Read new events
        new_events, event_pos = tail_file(EVENT_LOG_PATH, event_pos)
        events.extend(new_events)
        if len(events) > 100:
            events = events[-100:]

        # Read new contradictions
        new_contras, contra_pos = tail_file(CONTRA_PATH, contra_pos)
        contras.extend(new_contras)
        if len(contras) > 100:
            contras = contras[-100:]

        stdscr.clear()
        stdscr.addstr(0, 0, "Sanctum - Lucidia Ritual Shell (press 'q' to quit)")
        stdscr.addstr(2, 0, "Events:")
        for i, line in enumerate(reversed(events[-(height // 2 - 3) :])):
            stdscr.addstr(3 + i, 2, line[: width - 4])

        offset = height // 2
        stdscr.addstr(offset, 0, "Contradictions:")
        for i, line in enumerate(reversed(contras[-(height - offset - 2) :])):
            stdscr.addstr(offset + 1 + i, 2, line[: width - 4])

        stdscr.refresh()
        time.sleep(1.0)
        try:
            ch = stdscr.getch()
            if ch == ord("q"):
                break
        except Exception:
            pass


def main():
    curses.wrapper(draw_screen)


if __name__ == "__main__":
    main()

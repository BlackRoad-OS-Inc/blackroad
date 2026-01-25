"""Job log reflex example."""

from __future__ import annotations

import re
import time
from typing import Any

from lucidia.reflex.core import BUS, start

ERROR_RE = re.compile(r"\bERROR\b")


@BUS.on("joblog:line")
def on_line(evt: Any) -> None:
    line = evt.get("line", "")
    if ERROR_RE.search(line):
        print("[reflex] tagged ERROR:", line.strip())


def tail(path: str = "/srv/blackroad/logs/agent.log", poll_interval: float = 0.1) -> None:
    if not BUS.enabled:
        return

    with open(path, "r", encoding="utf-8") as f:
        f.seek(0, 2)
        while True:
            line = f.readline()
            if not line:
                time.sleep(poll_interval)
                continue
            BUS.emit("joblog:line", {"line": line})


if __name__ == "__main__":  # pragma: no cover - manual wiring
    start()
    tail()


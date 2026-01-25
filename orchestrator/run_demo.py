from __future__ import annotations

from pathlib import Path
import sys

if __package__ is None or __package__ == "":  # pragma: no cover - script execution path
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    script_dir_str = str(script_dir)
    while script_dir_str in sys.path:
        sys.path.remove(script_dir_str)
    sys.path.insert(0, str(project_root))

from bots.archivist import Archivist
from bots.base import new_msg
from bots.bus import Bus
from bots.critic import Critic
from bots.executor import Executor
from bots.librarian import Librarian
from bots.planner import Planner


def wire(bus: Bus):
    """Register the demo bots on ``bus`` and return the instances."""

    bots = [Librarian(bus), Planner(bus), Executor(bus), Critic(bus), Archivist(bus)]

    def _subscribe(bot):
        def _handler(message):
            if bot.can_handle(message):
                for reply in bot.handle(message):
                    bus.publish(reply)

        bus.subscribe(_handler)

    for bot in bots:
        _subscribe(bot)
    return bots


if __name__ == "__main__":
    bus = Bus()
    wire(bus)
    bus.publish(new_msg("user", "planner", "task", op="plan", goal="make_bell_hist"))
    bus.publish(new_msg("user", "planner", "task", op="plan", goal="prime_demo"))
    print("Events:", len(bus.history()))
    print("Artifacts in ./artifacts (hist + lineage) expected.")

from __future__ import annotations

from typing import List

from .base import Bot, Message, new_msg


class Planner(Bot):
    name = "planner"

    def can_handle(self, msg: Message) -> bool:
        return msg.kind == "task" and msg.content.get("op") == "plan"

    def handle(self, msg: Message) -> List[Message]:
        goal = msg.content.get("goal")
        steps = []
        if goal == "make_bell_hist":
            steps = [
                {"op": "execute", "skill": "quantum.bell"},
                {"op": "execute", "skill": "viz.hist_bell"},
            ]
        elif goal == "prime_demo":
            steps = [{"op": "execute", "skill": "math.primes", "n": 200}]
        return [
            new_msg(
                self.name,
                "executor",
                "task",
                op="execute_many",
                steps=steps,
                parent=msg.id,
            )
        ]

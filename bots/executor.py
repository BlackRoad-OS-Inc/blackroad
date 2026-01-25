from __future__ import annotations

from typing import Any, Dict, List

import numpy as np

from .base import Bot, Message, new_msg
from .skills import math_skill as math_ops
from .skills import quantum_skill as quantum_ops
from .skills import viz_skill as viz_ops


class Executor(Bot):
    name = "executor"

    def can_handle(self, msg: Message) -> bool:
        return msg.kind == "task" and msg.content.get("op") in {"execute", "execute_many"}

    def handle(self, msg: Message) -> List[Message]:
        if msg.content.get("op") == "execute_many":
            step_messages: List[Message] = []
            for step in msg.content.get("steps", []):
                step_messages.extend(self._run_step(step))
            batch = new_msg(
                self.name,
                "critic",
                "result",
                op="batch",
                results=[m.content for m in step_messages],
                parent=msg.content.get("parent"),
            )
            return [*step_messages, batch]
        return self._run_step(msg.content)

    def _run_step(self, step: Dict[str, Any]) -> List[Message]:
        op = step.get("skill", "")
        if op == "quantum.bell":
            psi = quantum_ops.bell_pair()
            probs = {"00": float(abs(psi[0]) ** 2), "11": float(abs(psi[3]) ** 2)}
            return [new_msg(self.name, "critic", "result", op="bell", probs=probs)]
        if op == "viz.hist_bell":
            path = viz_ops.save_hist({"00": 0.5, "11": 0.5}, "bell_hist.png")
            return [new_msg(self.name, "critic", "result", op="plot", path=path)]
        if op == "math.primes":
            n = int(step.get("n", 200))
            primes = math_ops.primes_upto(n)
            return [
                new_msg(
                    self.name,
                    "critic",
                    "result",
                    op="primes",
                    n=n,
                    count=len(primes),
                )
            ]
        if op == "math.l2_norm":
            vec = np.asarray(step.get("vec", []), dtype=float)
            norm = math_ops.l2_norm(vec)
            return [new_msg(self.name, "critic", "result", op="l2_norm", value=norm)]
        return [new_msg(self.name, "critic", "result", op="noop")]

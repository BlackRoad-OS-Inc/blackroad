from __future__ import annotations

from typing import List

from .base import Bot, Message, new_msg


class Critic(Bot):
    name = "critic"

    def can_handle(self, msg: Message) -> bool:
        return msg.kind == "result"

    def handle(self, msg: Message) -> List[Message]:
        verdict = "pass"
        reason = "ok"
        if msg.content.get("op") == "bell":
            probs = msg.content.get("probs", {})
            if abs((probs.get("00", 0.0) + probs.get("11", 0.0)) - 1.0) > 1e-6:
                verdict, reason = "fail", "probabilities not normalized"
        return [
            new_msg(
                self.name,
                "archivist",
                "log",
                verdict=verdict,
                reason=reason,
                payload=msg.content,
            )
        ]

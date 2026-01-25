from __future__ import annotations

from typing import List

from .base import Bot, Message, new_msg

DOCS = {
    "riemann": "Short note on zeta zeros and phase plots (see pedagogy/riemann.md).",
    "bell": "Bell pair construction: (H ⊗ I)|00> → CNOT → (|00>+|11>)/√2.",
}


class Librarian(Bot):
    name = "librarian"

    def can_handle(self, msg: Message) -> bool:
        return msg.kind == "task" and msg.content.get("op") == "lookup"

    def handle(self, msg: Message) -> List[Message]:
        key = msg.content.get("key", "").lower()
        note = DOCS.get(key, "No doc found.")
        return [new_msg(self.name, msg.sender, "result", op="lookup", key=key, note=note)]

from __future__ import annotations

import json
import os
from typing import List

from .base import Bot, Message

LOG_PATH = "artifacts/lineage.jsonl"


class Archivist(Bot):
    name = "archivist"

    def can_handle(self, msg: Message) -> bool:
        return msg.kind in {"log", "result"}

    def handle(self, msg: Message) -> List[Message]:
        os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
        with open(LOG_PATH, "a", encoding="utf-8") as fh:
            fh.write(
                json.dumps(
                    {
                        "ts": msg.ts,
                        "sender": msg.sender,
                        "kind": msg.kind,
                        "content": msg.content,
                    }
                )
                + "\n"
            )
        return []

from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
from typing import Any, Dict, List


@dataclass
class Message:
    """Lightweight payload exchanged between bots on the in-memory bus."""

    id: str
    sender: str
    recipient: str
    kind: str
    content: Dict[str, Any]
    ts: float = field(default_factory=time.time)


def new_msg(sender: str, recipient: str, kind: str, **content: Any) -> Message:
    """Helper to create a :class:`Message` with a unique identifier."""

    return Message(
        id=str(uuid.uuid4()),
        sender=sender,
        recipient=recipient,
        kind=kind,
        content=content,
    )


class Bot:
    """Base interface used by simple orchestrated bots."""

    name: str = "bot"

    def __init__(self, bus: "Bus") -> None:  # type: ignore[name-defined]
        self.bus = bus

    def can_handle(self, msg: Message) -> bool:
        """Return ``True`` if this bot is interested in ``msg``."""

        return False

    def handle(self, msg: Message) -> List[Message]:
        """Process ``msg`` and return follow-up messages to emit on the bus."""

        return []

from __future__ import annotations

from typing import Callable, List

from .base import Message


class Bus:
    """Minimal in-memory message bus used by the demo orchestrator."""

    def __init__(self) -> None:
        self.subscribers: List[Callable[[Message], None]] = []
        self.log: List[Message] = []

    def publish(self, msg: Message) -> None:
        """Record ``msg`` and notify all subscribed handlers."""

        self.log.append(msg)
        for sub in list(self.subscribers):
            sub(msg)

    def subscribe(self, fn: Callable[[Message], None]) -> None:
        """Register ``fn`` to receive every bus message."""

        self.subscribers.append(fn)

    def history(self) -> List[Message]:
        """Return a shallow copy of the message log."""

        return list(self.log)

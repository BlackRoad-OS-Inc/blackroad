"""RoadQueue Pipeline - Middleware Pipeline.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Callable, List, Optional

from roadqueue_core.queue.message import Message


class Middleware(ABC):
    """Abstract middleware for message processing."""

    @abstractmethod
    def before_publish(self, message: Message) -> Optional[Message]:
        """Called before message is published. Return None to reject."""
        pass

    @abstractmethod
    def after_publish(self, message: Message) -> None:
        """Called after message is published."""
        pass

    @abstractmethod
    def before_consume(self, message: Message) -> Optional[Message]:
        """Called before message is consumed. Return None to skip."""
        pass

    @abstractmethod
    def after_consume(self, message: Message, success: bool) -> None:
        """Called after message is consumed."""
        pass


class BaseMiddleware(Middleware):
    """Base middleware with default implementations."""

    def before_publish(self, message: Message) -> Optional[Message]:
        return message

    def after_publish(self, message: Message) -> None:
        pass

    def before_consume(self, message: Message) -> Optional[Message]:
        return message

    def after_consume(self, message: Message, success: bool) -> None:
        pass


class Pipeline:
    """Middleware pipeline for message processing."""

    def __init__(self, middlewares: Optional[List[Middleware]] = None):
        self._middlewares: List[Middleware] = middlewares or []

    def add(self, middleware: Middleware) -> "Pipeline":
        """Add middleware to pipeline."""
        self._middlewares.append(middleware)
        return self

    def remove(self, middleware: Middleware) -> bool:
        """Remove middleware from pipeline."""
        if middleware in self._middlewares:
            self._middlewares.remove(middleware)
            return True
        return False

    def before_publish(self, message: Message) -> Optional[Message]:
        """Process message before publishing."""
        current = message
        for mw in self._middlewares:
            current = mw.before_publish(current)
            if current is None:
                return None
        return current

    def after_publish(self, message: Message) -> None:
        """Process message after publishing."""
        for mw in self._middlewares:
            mw.after_publish(message)

    def before_consume(self, message: Message) -> Optional[Message]:
        """Process message before consuming."""
        current = message
        for mw in self._middlewares:
            current = mw.before_consume(current)
            if current is None:
                return None
        return current

    def after_consume(self, message: Message, success: bool) -> None:
        """Process message after consuming."""
        for mw in reversed(self._middlewares):
            mw.after_consume(message, success)


__all__ = ["Middleware", "BaseMiddleware", "Pipeline"]

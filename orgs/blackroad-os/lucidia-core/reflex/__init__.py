"""Lightweight reflex runtime for Lucidia.

This package exposes the shared reflex bus instance and helpers for
registering background reactions to edge events.
"""

from .core import BUS, start, ReflexBus

__all__ = ["BUS", "start", "ReflexBus"]

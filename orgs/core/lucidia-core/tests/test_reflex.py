"""Tests for the reflex.core ReflexBus."""

from __future__ import annotations

import time
import threading

from reflex.core import ReflexBus


class TestReflexBus:

    def test_on_and_emit(self):
        bus = ReflexBus(disabled=False)
        received = []
        bus.on("test.topic", lambda payload: received.append(payload))
        bus.start()
        bus.emit("test.topic", {"key": "value"})
        # Give the dispatcher thread a moment.
        time.sleep(0.2)
        assert len(received) == 1
        assert received[0]["key"] == "value"

    def test_wildcard_routing(self):
        bus = ReflexBus(disabled=False)
        received = []
        bus.on("metrics.*", lambda p: received.append(p))
        bus.start()
        bus.emit("metrics.cpu", 42)
        bus.emit("metrics.mem", 80)
        bus.emit("other.thing", 0)
        time.sleep(0.2)
        assert len(received) == 2

    def test_disabled_bus_does_not_dispatch(self):
        bus = ReflexBus(disabled=True)
        received = []
        bus.on("topic", lambda p: received.append(p))
        bus.start()
        bus.emit("topic", "hello")
        time.sleep(0.2)
        assert received == []

    def test_enable_disable(self):
        bus = ReflexBus(disabled=True)
        assert not bus.enabled
        bus.enable()
        assert bus.enabled
        bus.disable()
        assert not bus.enabled

    def test_emit_without_subscribers(self):
        """Emitting to a topic with no subscribers should not raise."""
        bus = ReflexBus(disabled=False)
        bus.start()
        bus.emit("no.listener", {"data": 1})
        time.sleep(0.1)  # Just ensure no exception.

"""Example reflex wiring for Raspberry Pi GPIO events."""

from __future__ import annotations

import time
from typing import Any

try:  # pragma: no cover - optional hardware dependency
    import RPi.GPIO as GPIO
except ImportError:  # pragma: no cover - optional hardware dependency
    GPIO = None

from lucidia.reflex.core import BUS, start

LED = 18
INPUT = 17


def setup() -> None:
    """Prepare GPIO pins for input edge watching."""

    if GPIO is None:
        return
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(LED, GPIO.OUT)
    GPIO.setup(INPUT, GPIO.IN, pull_up_down=GPIO.PUD_UP)


@BUS.on("gpio:edge")
def blink(_: Any) -> None:
    if GPIO is None:
        return
    GPIO.output(LED, True)
    time.sleep(0.1)
    GPIO.output(LED, False)


def watch(poll_interval: float = 0.02) -> None:
    """Poll the GPIO pin and emit events on changes."""

    if GPIO is None or not BUS.enabled:
        return

    last = GPIO.input(INPUT)
    while True:
        cur = GPIO.input(INPUT)
        if cur != last:
            BUS.emit("gpio:edge", {"pin": INPUT, "state": cur})
            last = cur
        time.sleep(poll_interval)


if __name__ == "__main__":  # pragma: no cover - manual wiring
    setup()
    start()
    watch()


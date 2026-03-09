"""Core runtime for Lucidia reflexes.

The runtime offers a single in-process bus that small reflex handlers can
subscribe to.  Watchers emit topic/payload pairs into the bus and the
runtime dispatches them on a background thread so the emitters stay
non-blocking.

The runtime respects the ``LUCIDIA_REFLEX_OFF`` environment variable as an
emergency kill switch.  When the variable is set to ``"1"`` no handlers are
invoked, though events are still logged for observability.

Events are logged as JSON lines.  The output path defaults to the value of
``LUCIDIA_REFLEX_LOG`` if provided, otherwise the log is sent to stdout.
"""

from __future__ import annotations

from typing import Any, Callable, Dict, List
import json
import os
import queue
import threading
import time
import logging
from pathlib import Path


class ReflexBus:
    """A tiny publish/subscribe bus for reflex handlers."""

    def __init__(self, *, disabled: bool | None = None) -> None:
        env_disabled = os.environ.get("LUCIDIA_REFLEX_OFF", "0") == "1"
        self._enabled = not (disabled if disabled is not None else env_disabled)
        self._routes: Dict[str, List[Callable[[Any], None]]] = {}
        self._wildcard_routes: Dict[str, List[Callable[[Any], None]]] = {}
        self._q: "queue.Queue[tuple[str, Any]]" = queue.Queue()
        self._thread: threading.Thread | None = None
        self._lock = threading.Lock()
        self._logger = self._configure_logger()

    # ------------------------------------------------------------------
    def _configure_logger(self) -> logging.Logger:
        logger = logging.getLogger("lucidia.reflex")
        logger.setLevel(logging.INFO)

        if logger.handlers:
            return logger

        log_path = os.environ.get("LUCIDIA_REFLEX_LOG")
        handler: logging.Handler
        if log_path:
            try:
                path = Path(log_path)
                path.parent.mkdir(parents=True, exist_ok=True)
                handler = logging.FileHandler(path)
            except OSError:
                handler = logging.StreamHandler()
        else:
            handler = logging.StreamHandler()

        handler.setFormatter(logging.Formatter("%(message)s"))
        logger.addHandler(handler)
        return logger

    # ------------------------------------------------------------------
    @property
    def enabled(self) -> bool:
        """Return whether the bus will dispatch events to handlers."""

        return self._enabled

    # ------------------------------------------------------------------
    def enable(self) -> None:
        self._enabled = True

    # ------------------------------------------------------------------
    def disable(self) -> None:
        self._enabled = False

    # ------------------------------------------------------------------
    def on(self, topic: str, fn: Callable[[Any], None]) -> Callable[[Any], None]:
        """Register a reflex handler for a topic."""

        if topic.endswith("*"):
            prefix = topic[:-1]
            self._wildcard_routes.setdefault(prefix, []).append(fn)
        else:
            self._routes.setdefault(topic, []).append(fn)
        return fn

    # ------------------------------------------------------------------
    def emit(self, topic: str, payload: Any) -> None:
        """Publish an event to the bus."""

        entry = {
            "ts": time.time(),
            "topic": topic,
            "payload": payload,
        }
        try:
            self._logger.info(json.dumps(entry, default=str))
        except Exception:
            # Logging must never break reflex flow.
            pass

        if not self._enabled:
            return

        self._q.put((topic, payload))

    # ------------------------------------------------------------------
    def start(self) -> None:
        """Ensure the dispatcher thread is running."""

        if not self._enabled:
            return

        with self._lock:
            if self._thread and self._thread.is_alive():
                return
            self._thread = threading.Thread(target=self.run_forever, daemon=True)
            self._thread.start()

    # ------------------------------------------------------------------
    def run_forever(self) -> None:
        """Dispatch events to registered handlers."""

        while True:
            topic, payload = self._q.get()
            handlers: List[Callable[[Any], None]] = list(self._routes.get(topic, []))
            for prefix, fns in self._wildcard_routes.items():
                if topic.startswith(prefix):
                    handlers.extend(fns)
            for fn in handlers:
                try:
                    fn(payload)
                except Exception as exc:  # pragma: no cover - guardrail
                    err_entry = {
                        "ts": time.time(),
                        "topic": topic,
                        "error": str(exc),
                    }
                    try:
                        self._logger.info(json.dumps(err_entry, default=str))
                    except Exception:
                        pass


BUS = ReflexBus()


def start() -> None:
    """Public helper to spin up the reflex dispatcher."""

    BUS.start()


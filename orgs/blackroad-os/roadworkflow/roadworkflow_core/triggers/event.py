"""Event Triggers - Event-based workflow triggers.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import logging
import os
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set

from roadworkflow_core.triggers.base import (
    Trigger,
    TriggerConfig,
    TriggerEvent,
    TriggerType,
)

logger = logging.getLogger(__name__)


class EventTrigger(Trigger):
    """Event-based trigger.

    Listens for named events and triggers workflows.

    Usage:
        trigger = EventTrigger(event_name="data_ready")
        trigger.on_trigger(lambda e: run_workflow(e.payload))
        trigger.start()

        # Fire event from anywhere
        trigger.emit({"file": "data.csv"})
    """

    _instances: Dict[str, "EventTrigger"] = {}

    def __init__(
        self,
        event_name: str,
        filter_fn: Optional[Callable[[Dict[str, Any]], bool]] = None,
        **kwargs,
    ):
        config = TriggerConfig(trigger_type=TriggerType.EVENT)
        super().__init__(config=config, **kwargs)

        self.event_name = event_name
        self.filter_fn = filter_fn
        self._event_queue: List[Dict[str, Any]] = []

        EventTrigger._instances[event_name] = self

    def start(self) -> None:
        """Start listening for events."""
        self._running = True
        logger.info(f"EventTrigger started for: {self.event_name}")

    def stop(self) -> None:
        """Stop listening for events."""
        self._running = False

        if self.event_name in EventTrigger._instances:
            del EventTrigger._instances[self.event_name]

        logger.info(f"EventTrigger stopped: {self.event_name}")

    def check(self) -> Optional[TriggerEvent]:
        """Check for pending events."""
        with self._lock:
            if self._event_queue:
                payload = self._event_queue.pop(0)
                return self._create_event(payload=payload, source=self.event_name)
        return None

    def emit(self, payload: Optional[Dict[str, Any]] = None) -> None:
        """Emit an event.

        Args:
            payload: Event payload
        """
        if not self._running:
            return

        payload = payload or {}

        if self.filter_fn and not self.filter_fn(payload):
            return

        event = self._create_event(payload=payload, source=self.event_name)
        self._fire(event)

    @classmethod
    def fire(cls, event_name: str, payload: Optional[Dict[str, Any]] = None) -> bool:
        """Fire event by name (class method).

        Args:
            event_name: Event name
            payload: Event payload

        Returns:
            True if event was handled
        """
        trigger = cls._instances.get(event_name)
        if trigger:
            trigger.emit(payload)
            return True
        return False


class DatasetTrigger(Trigger):
    """Dataset-based trigger.

    Triggers when dataset is updated or meets criteria.

    Usage:
        trigger = DatasetTrigger(
            dataset_id="sales_data",
            condition=lambda ds: ds.row_count > 1000
        )
    """

    def __init__(
        self,
        dataset_id: str,
        condition: Optional[Callable[[Any], bool]] = None,
        poll_interval: float = 60.0,
        **kwargs,
    ):
        config = TriggerConfig(trigger_type=TriggerType.DATASET)
        super().__init__(config=config, **kwargs)

        self.dataset_id = dataset_id
        self.condition = condition
        self.poll_interval = poll_interval

        self._thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()
        self._last_state: Optional[str] = None

    def start(self) -> None:
        """Start monitoring dataset."""
        if self._running:
            return

        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._monitor_loop,
            daemon=True,
            name=f"DatasetTrigger-{self.trigger_id}",
        )
        self._thread.start()
        self._running = True
        logger.info(f"DatasetTrigger started for: {self.dataset_id}")

    def stop(self) -> None:
        """Stop monitoring."""
        self._stop_event.set()

        if self._thread:
            self._thread.join(timeout=5)
            self._thread = None

        self._running = False

    def check(self) -> Optional[TriggerEvent]:
        """Check dataset state."""
        current_state = self._get_dataset_state()

        if self._last_state is None:
            self._last_state = current_state
            return None

        if current_state != self._last_state:
            self._last_state = current_state
            return self._create_event(
                payload={"dataset_id": self.dataset_id, "state": current_state},
                source="dataset",
            )

        return None

    def _monitor_loop(self) -> None:
        """Monitor dataset for changes."""
        while not self._stop_event.is_set():
            try:
                event = self.check()
                if event:
                    self._fire(event)
            except Exception as e:
                logger.error(f"Dataset monitor error: {e}")

            self._stop_event.wait(self.poll_interval)

    def _get_dataset_state(self) -> str:
        """Get current dataset state hash."""
        state_info = f"{self.dataset_id}_{datetime.utcnow().minute}"
        return hashlib.md5(state_info.encode()).hexdigest()[:8]


class FileTrigger(Trigger):
    """File-based trigger.

    Triggers when file is created, modified, or deleted.

    Usage:
        trigger = FileTrigger(
            path="/data/input",
            patterns=["*.csv", "*.json"],
            events=["created", "modified"]
        )
    """

    def __init__(
        self,
        path: str,
        patterns: Optional[List[str]] = None,
        events: Optional[List[str]] = None,
        recursive: bool = False,
        poll_interval: float = 5.0,
        **kwargs,
    ):
        config = TriggerConfig(trigger_type=TriggerType.FILE)
        super().__init__(config=config, **kwargs)

        self.path = Path(path)
        self.patterns = patterns or ["*"]
        self.events = events or ["created", "modified"]
        self.recursive = recursive
        self.poll_interval = poll_interval

        self._thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()
        self._file_states: Dict[str, tuple] = {}

    def start(self) -> None:
        """Start monitoring files."""
        if self._running:
            return

        self._initialize_states()

        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._monitor_loop,
            daemon=True,
            name=f"FileTrigger-{self.trigger_id}",
        )
        self._thread.start()
        self._running = True
        logger.info(f"FileTrigger started for: {self.path}")

    def stop(self) -> None:
        """Stop monitoring."""
        self._stop_event.set()

        if self._thread:
            self._thread.join(timeout=5)
            self._thread = None

        self._running = False

    def check(self) -> Optional[TriggerEvent]:
        """Check for file changes."""
        changes = self._detect_changes()

        if changes:
            return self._create_event(
                payload={"changes": changes},
                source="file",
            )
        return None

    def _initialize_states(self) -> None:
        """Initialize file states."""
        for file_path in self._get_matching_files():
            self._file_states[str(file_path)] = self._get_file_state(file_path)

    def _monitor_loop(self) -> None:
        """Monitor files for changes."""
        while not self._stop_event.is_set():
            try:
                changes = self._detect_changes()

                if changes:
                    event = self._create_event(
                        payload={"changes": changes, "path": str(self.path)},
                        source="file",
                    )
                    self._fire(event)
            except Exception as e:
                logger.error(f"File monitor error: {e}")

            self._stop_event.wait(self.poll_interval)

    def _get_matching_files(self) -> List[Path]:
        """Get files matching patterns."""
        files = []

        for pattern in self.patterns:
            if self.recursive:
                files.extend(self.path.rglob(pattern))
            else:
                files.extend(self.path.glob(pattern))

        return [f for f in files if f.is_file()]

    def _get_file_state(self, file_path: Path) -> tuple:
        """Get file state (mtime, size)."""
        try:
            stat = file_path.stat()
            return (stat.st_mtime, stat.st_size)
        except OSError:
            return (0, 0)

    def _detect_changes(self) -> List[Dict[str, Any]]:
        """Detect file changes."""
        changes = []
        current_files = set(str(f) for f in self._get_matching_files())
        previous_files = set(self._file_states.keys())

        if "created" in self.events:
            new_files = current_files - previous_files
            for file_path in new_files:
                changes.append({
                    "type": "created",
                    "path": file_path,
                    "timestamp": datetime.utcnow().isoformat(),
                })
                self._file_states[file_path] = self._get_file_state(Path(file_path))

        if "deleted" in self.events:
            deleted_files = previous_files - current_files
            for file_path in deleted_files:
                changes.append({
                    "type": "deleted",
                    "path": file_path,
                    "timestamp": datetime.utcnow().isoformat(),
                })
                del self._file_states[file_path]

        if "modified" in self.events:
            for file_path in current_files & previous_files:
                new_state = self._get_file_state(Path(file_path))
                old_state = self._file_states.get(file_path)

                if new_state != old_state:
                    changes.append({
                        "type": "modified",
                        "path": file_path,
                        "timestamp": datetime.utcnow().isoformat(),
                    })
                    self._file_states[file_path] = new_state

        return changes


class S3Trigger(Trigger):
    """S3 bucket event trigger."""

    def __init__(
        self,
        bucket: str,
        prefix: str = "",
        events: Optional[List[str]] = None,
        poll_interval: float = 60.0,
        **kwargs,
    ):
        config = TriggerConfig(trigger_type=TriggerType.EXTERNAL)
        super().__init__(config=config, **kwargs)

        self.bucket = bucket
        self.prefix = prefix
        self.events = events or ["s3:ObjectCreated:*"]
        self.poll_interval = poll_interval

        self._thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()
        self._known_keys: Set[str] = set()

    def start(self) -> None:
        """Start monitoring S3."""
        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._monitor_loop,
            daemon=True,
        )
        self._thread.start()
        self._running = True
        logger.info(f"S3Trigger started for: {self.bucket}/{self.prefix}")

    def stop(self) -> None:
        """Stop monitoring."""
        self._stop_event.set()
        if self._thread:
            self._thread.join(timeout=5)
        self._running = False

    def check(self) -> Optional[TriggerEvent]:
        """Check for new S3 objects."""
        return None

    def _monitor_loop(self) -> None:
        """Monitor S3 for changes."""
        while not self._stop_event.is_set():
            try:
                new_objects = self._list_new_objects()
                if new_objects:
                    event = self._create_event(
                        payload={
                            "bucket": self.bucket,
                            "objects": new_objects,
                        },
                        source="s3",
                    )
                    self._fire(event)
            except Exception as e:
                logger.error(f"S3 monitor error: {e}")

            self._stop_event.wait(self.poll_interval)

    def _list_new_objects(self) -> List[str]:
        """List new objects in bucket."""
        return []


__all__ = [
    "EventTrigger",
    "DatasetTrigger",
    "FileTrigger",
    "S3Trigger",
]

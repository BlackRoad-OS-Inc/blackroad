"""
RoadWatch - File Watching for BlackRoad
Monitor files and directories for changes.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set, Union
import hashlib
import os
import threading
import time
import logging

logger = logging.getLogger(__name__)


class EventType(str, Enum):
    CREATED = "created"
    MODIFIED = "modified"
    DELETED = "deleted"
    MOVED = "moved"


@dataclass
class FileEvent:
    type: EventType
    path: Path
    timestamp: datetime = field(default_factory=datetime.now)
    old_path: Optional[Path] = None
    is_directory: bool = False

    def __str__(self) -> str:
        if self.type == EventType.MOVED:
            return f"{self.type.value}: {self.old_path} -> {self.path}"
        return f"{self.type.value}: {self.path}"


@dataclass
class FileSnapshot:
    path: Path
    size: int
    mtime: float
    hash: str = ""
    exists: bool = True

    @classmethod
    def from_path(cls, path: Path, compute_hash: bool = False) -> "FileSnapshot":
        if not path.exists():
            return cls(path=path, size=0, mtime=0, exists=False)
        stat = path.stat()
        hash_val = ""
        if compute_hash and path.is_file():
            with open(path, "rb") as f:
                hash_val = hashlib.md5(f.read()).hexdigest()
        return cls(path=path, size=stat.st_size, mtime=stat.st_mtime, hash=hash_val, exists=True)


class FileWatcher:
    def __init__(self, path: Union[str, Path], recursive: bool = True, patterns: List[str] = None,
                 ignore_patterns: List[str] = None, poll_interval: float = 1.0, use_hash: bool = False):
        self.path = Path(path)
        self.recursive = recursive
        self.patterns = patterns or ["*"]
        self.ignore_patterns = ignore_patterns or []
        self.poll_interval = poll_interval
        self.use_hash = use_hash
        self._snapshots: Dict[Path, FileSnapshot] = {}
        self._handlers: Dict[EventType, List[Callable]] = {t: [] for t in EventType}
        self._running = False
        self._thread: Optional[threading.Thread] = None

    def on(self, event_type: EventType, handler: Callable[[FileEvent], None]) -> "FileWatcher":
        self._handlers[event_type].append(handler)
        return self

    def on_created(self, handler: Callable[[FileEvent], None]) -> "FileWatcher":
        return self.on(EventType.CREATED, handler)

    def on_modified(self, handler: Callable[[FileEvent], None]) -> "FileWatcher":
        return self.on(EventType.MODIFIED, handler)

    def on_deleted(self, handler: Callable[[FileEvent], None]) -> "FileWatcher":
        return self.on(EventType.DELETED, handler)

    def on_any(self, handler: Callable[[FileEvent], None]) -> "FileWatcher":
        for t in EventType:
            self._handlers[t].append(handler)
        return self

    def _matches(self, path: Path) -> bool:
        name = path.name
        for pattern in self.ignore_patterns:
            if path.match(pattern):
                return False
        for pattern in self.patterns:
            if path.match(pattern):
                return True
        return False

    def _scan(self) -> Dict[Path, FileSnapshot]:
        snapshots = {}
        if self.path.is_file():
            if self._matches(self.path):
                snapshots[self.path] = FileSnapshot.from_path(self.path, self.use_hash)
        else:
            pattern = "**/*" if self.recursive else "*"
            for p in self.path.glob(pattern):
                if p.is_file() and self._matches(p):
                    snapshots[p] = FileSnapshot.from_path(p, self.use_hash)
        return snapshots

    def _emit(self, event: FileEvent) -> None:
        for handler in self._handlers[event.type]:
            try:
                handler(event)
            except Exception as e:
                logger.error(f"Handler error: {e}")

    def _check(self) -> List[FileEvent]:
        events = []
        current = self._scan()
        prev_paths = set(self._snapshots.keys())
        curr_paths = set(current.keys())

        for path in curr_paths - prev_paths:
            events.append(FileEvent(type=EventType.CREATED, path=path))

        for path in prev_paths - curr_paths:
            events.append(FileEvent(type=EventType.DELETED, path=path))

        for path in prev_paths & curr_paths:
            prev = self._snapshots[path]
            curr = current[path]
            if self.use_hash:
                if prev.hash != curr.hash:
                    events.append(FileEvent(type=EventType.MODIFIED, path=path))
            elif prev.mtime != curr.mtime or prev.size != curr.size:
                events.append(FileEvent(type=EventType.MODIFIED, path=path))

        self._snapshots = current
        return events

    def _poll(self) -> None:
        self._snapshots = self._scan()
        while self._running:
            events = self._check()
            for event in events:
                self._emit(event)
            time.sleep(self.poll_interval)

    def start(self) -> "FileWatcher":
        if self._running:
            return self
        self._running = True
        self._thread = threading.Thread(target=self._poll, daemon=True)
        self._thread.start()
        return self

    def stop(self) -> None:
        self._running = False
        if self._thread:
            self._thread.join(timeout=2)

    def poll_once(self) -> List[FileEvent]:
        if not self._snapshots:
            self._snapshots = self._scan()
            return []
        return self._check()

    def __enter__(self) -> "FileWatcher":
        return self.start()

    def __exit__(self, *args) -> None:
        self.stop()


class MultiWatcher:
    def __init__(self):
        self._watchers: List[FileWatcher] = []
        self._handlers: Dict[EventType, List[Callable]] = {t: [] for t in EventType}

    def watch(self, path: Union[str, Path], **kwargs) -> "MultiWatcher":
        watcher = FileWatcher(path, **kwargs)
        for event_type, handlers in self._handlers.items():
            for handler in handlers:
                watcher.on(event_type, handler)
        self._watchers.append(watcher)
        return self

    def on(self, event_type: EventType, handler: Callable) -> "MultiWatcher":
        self._handlers[event_type].append(handler)
        for watcher in self._watchers:
            watcher.on(event_type, handler)
        return self

    def on_any(self, handler: Callable) -> "MultiWatcher":
        for t in EventType:
            self.on(t, handler)
        return self

    def start(self) -> "MultiWatcher":
        for watcher in self._watchers:
            watcher.start()
        return self

    def stop(self) -> None:
        for watcher in self._watchers:
            watcher.stop()


def watch(path: Union[str, Path], callback: Callable[[FileEvent], None], **kwargs) -> FileWatcher:
    watcher = FileWatcher(path, **kwargs)
    watcher.on_any(callback)
    return watcher.start()


def example_usage():
    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        def on_change(event: FileEvent):
            print(f"Event: {event}")

        watcher = FileWatcher(tmp, patterns=["*.txt"], poll_interval=0.5)
        watcher.on_any(on_change)

        print(f"Watching: {tmp}")
        watcher.start()

        test_file = Path(tmp) / "test.txt"
        test_file.write_text("Hello")
        time.sleep(1)

        test_file.write_text("Hello World")
        time.sleep(1)

        test_file.unlink()
        time.sleep(1)

        watcher.stop()
        print("Done!")


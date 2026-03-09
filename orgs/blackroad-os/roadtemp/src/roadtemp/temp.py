"""
RoadTemp - Temporary Files for BlackRoad
Create and manage temporary files and directories.
"""

from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Callable, Dict, Generator, List, Optional, Union
import atexit
import os
import shutil
import tempfile
import threading
import uuid
import logging

logger = logging.getLogger(__name__)


class TempError(Exception):
    pass


@dataclass
class TempFileInfo:
    path: Path
    created: datetime
    expires: Optional[datetime] = None
    auto_delete: bool = True


class TempFile:
    def __init__(self, suffix: str = "", prefix: str = "road_", dir: str = None,
                 delete: bool = True, text: bool = True):
        self.suffix = suffix
        self.prefix = prefix
        self.dir = dir
        self.delete = delete
        self.text = text
        self._fd: Optional[int] = None
        self._path: Optional[Path] = None
        self._file = None

    def create(self) -> "TempFile":
        mode = "w+" if self.text else "wb+"
        self._fd, path = tempfile.mkstemp(suffix=self.suffix, prefix=self.prefix, dir=self.dir)
        self._path = Path(path)
        self._file = os.fdopen(self._fd, mode)
        if self.delete:
            atexit.register(self._cleanup)
        return self

    def _cleanup(self) -> None:
        try:
            if self._path and self._path.exists():
                self._path.unlink()
        except Exception:
            pass

    @property
    def path(self) -> Path:
        return self._path

    @property
    def name(self) -> str:
        return str(self._path) if self._path else ""

    def write(self, data: Union[str, bytes]) -> int:
        if self._file:
            return self._file.write(data)
        return 0

    def read(self) -> Union[str, bytes]:
        if self._file:
            self._file.seek(0)
            return self._file.read()
        return "" if self.text else b""

    def close(self) -> None:
        if self._file:
            self._file.close()
            self._file = None

    def __enter__(self) -> "TempFile":
        return self.create()

    def __exit__(self, *args) -> None:
        self.close()
        if self.delete:
            self._cleanup()


class TempDir:
    def __init__(self, suffix: str = "", prefix: str = "road_", dir: str = None, delete: bool = True):
        self.suffix = suffix
        self.prefix = prefix
        self.dir = dir
        self.delete = delete
        self._path: Optional[Path] = None

    def create(self) -> "TempDir":
        self._path = Path(tempfile.mkdtemp(suffix=self.suffix, prefix=self.prefix, dir=self.dir))
        if self.delete:
            atexit.register(self._cleanup)
        return self

    def _cleanup(self) -> None:
        try:
            if self._path and self._path.exists():
                shutil.rmtree(self._path)
        except Exception:
            pass

    @property
    def path(self) -> Path:
        return self._path

    @property
    def name(self) -> str:
        return str(self._path) if self._path else ""

    def file(self, name: str, content: str = None) -> Path:
        p = self._path / name
        if content is not None:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content)
        return p

    def subdir(self, name: str) -> Path:
        p = self._path / name
        p.mkdir(parents=True, exist_ok=True)
        return p

    def cleanup(self) -> None:
        self._cleanup()

    def __enter__(self) -> "TempDir":
        return self.create()

    def __exit__(self, *args) -> None:
        if self.delete:
            self._cleanup()


class TempManager:
    def __init__(self, base_dir: str = None, auto_cleanup: bool = True, max_age: int = 3600):
        self.base_dir = Path(base_dir) if base_dir else Path(tempfile.gettempdir()) / "roadtemp"
        self.auto_cleanup = auto_cleanup
        self.max_age = max_age
        self._files: Dict[str, TempFileInfo] = {}
        self._lock = threading.Lock()
        self.base_dir.mkdir(parents=True, exist_ok=True)

    def create_file(self, suffix: str = "", prefix: str = "", ttl: int = None) -> Path:
        name = f"{prefix}{uuid.uuid4().hex}{suffix}"
        path = self.base_dir / name
        path.touch()
        expires = datetime.now() + timedelta(seconds=ttl) if ttl else None
        with self._lock:
            self._files[str(path)] = TempFileInfo(path=path, created=datetime.now(), expires=expires)
        return path

    def create_dir(self, prefix: str = "", ttl: int = None) -> Path:
        name = f"{prefix}{uuid.uuid4().hex}"
        path = self.base_dir / name
        path.mkdir(parents=True)
        expires = datetime.now() + timedelta(seconds=ttl) if ttl else None
        with self._lock:
            self._files[str(path)] = TempFileInfo(path=path, created=datetime.now(), expires=expires)
        return path

    def cleanup(self, force: bool = False) -> int:
        count = 0
        now = datetime.now()
        with self._lock:
            to_remove = []
            for key, info in self._files.items():
                should_remove = force
                if not should_remove and info.expires and now > info.expires:
                    should_remove = True
                if not should_remove and self.auto_cleanup:
                    age = (now - info.created).total_seconds()
                    if age > self.max_age:
                        should_remove = True
                if should_remove:
                    to_remove.append(key)
            for key in to_remove:
                info = self._files.pop(key)
                try:
                    if info.path.is_file():
                        info.path.unlink()
                    elif info.path.is_dir():
                        shutil.rmtree(info.path)
                    count += 1
                except Exception as e:
                    logger.error(f"Cleanup failed for {info.path}: {e}")
        return count

    def list(self) -> List[TempFileInfo]:
        with self._lock:
            return list(self._files.values())

    def __enter__(self) -> "TempManager":
        return self

    def __exit__(self, *args) -> None:
        self.cleanup(force=True)


@contextmanager
def temp_file(suffix: str = "", prefix: str = "road_", **kwargs) -> Generator[Path, None, None]:
    f = TempFile(suffix=suffix, prefix=prefix, **kwargs)
    with f as tf:
        yield tf.path


@contextmanager
def temp_dir(suffix: str = "", prefix: str = "road_", **kwargs) -> Generator[Path, None, None]:
    d = TempDir(suffix=suffix, prefix=prefix, **kwargs)
    with d as td:
        yield td.path


def mktemp(suffix: str = "", prefix: str = "road_") -> Path:
    return Path(tempfile.mktemp(suffix=suffix, prefix=prefix))


def mkstemp(suffix: str = "", prefix: str = "road_", dir: str = None) -> tuple:
    fd, path = tempfile.mkstemp(suffix=suffix, prefix=prefix, dir=dir)
    return fd, Path(path)


def mkdtemp(suffix: str = "", prefix: str = "road_", dir: str = None) -> Path:
    return Path(tempfile.mkdtemp(suffix=suffix, prefix=prefix, dir=dir))


def gettempdir() -> Path:
    return Path(tempfile.gettempdir())


def example_usage():
    with temp_file(suffix=".txt") as path:
        path.write_text("Hello, World!")
        print(f"Temp file: {path}")
        print(f"Content: {path.read_text()}")

    with temp_dir() as path:
        (path / "test.txt").write_text("Test")
        (path / "subdir").mkdir()
        print(f"Temp dir: {path}")
        print(f"Contents: {list(path.iterdir())}")

    manager = TempManager(max_age=60)
    f1 = manager.create_file(suffix=".log", ttl=30)
    d1 = manager.create_dir(prefix="cache_")
    print(f"\nManaged file: {f1}")
    print(f"Managed dir: {d1}")
    print(f"Active temps: {len(manager.list())}")
    manager.cleanup(force=True)


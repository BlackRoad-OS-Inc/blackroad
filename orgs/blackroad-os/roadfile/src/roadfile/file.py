"""
RoadFile - File Operations for BlackRoad
High-level file operations with atomic writes and locking.
"""

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Callable, Dict, Generator, List, Optional, Union
import hashlib
import json
import os
import shutil
import tempfile
import logging

logger = logging.getLogger(__name__)


class FileError(Exception):
    pass


@dataclass
class FileInfo:
    path: Path
    size: int
    created: datetime
    modified: datetime
    is_file: bool
    is_dir: bool
    is_link: bool
    mode: int
    owner: int
    group: int

    @classmethod
    def from_path(cls, path: Union[str, Path]) -> "FileInfo":
        p = Path(path)
        stat = p.stat()
        return cls(
            path=p,
            size=stat.st_size,
            created=datetime.fromtimestamp(stat.st_ctime),
            modified=datetime.fromtimestamp(stat.st_mtime),
            is_file=p.is_file(),
            is_dir=p.is_dir(),
            is_link=p.is_symlink(),
            mode=stat.st_mode,
            owner=stat.st_uid,
            group=stat.st_gid
        )


class File:
    def __init__(self, path: Union[str, Path]):
        self.path = Path(path)

    def read(self, encoding: str = "utf-8") -> str:
        return self.path.read_text(encoding=encoding)

    def read_bytes(self) -> bytes:
        return self.path.read_bytes()

    def read_lines(self, encoding: str = "utf-8") -> List[str]:
        return self.path.read_text(encoding=encoding).splitlines()

    def read_json(self) -> Any:
        return json.loads(self.read())

    def write(self, content: str, encoding: str = "utf-8", atomic: bool = True) -> int:
        if atomic:
            return self._atomic_write(content.encode(encoding))
        self.path.write_text(content, encoding=encoding)
        return len(content)

    def write_bytes(self, content: bytes, atomic: bool = True) -> int:
        if atomic:
            return self._atomic_write(content)
        self.path.write_bytes(content)
        return len(content)

    def write_json(self, data: Any, indent: int = 2, atomic: bool = True) -> int:
        content = json.dumps(data, indent=indent)
        return self.write(content, atomic=atomic)

    def _atomic_write(self, content: bytes) -> int:
        parent = self.path.parent
        parent.mkdir(parents=True, exist_ok=True)
        fd, tmp_path = tempfile.mkstemp(dir=parent)
        try:
            os.write(fd, content)
            os.close(fd)
            os.replace(tmp_path, self.path)
            return len(content)
        except Exception:
            os.close(fd)
            os.unlink(tmp_path)
            raise

    def append(self, content: str, encoding: str = "utf-8") -> int:
        with open(self.path, "a", encoding=encoding) as f:
            return f.write(content)

    def copy(self, dest: Union[str, Path]) -> "File":
        shutil.copy2(self.path, dest)
        return File(dest)

    def move(self, dest: Union[str, Path]) -> "File":
        shutil.move(str(self.path), dest)
        self.path = Path(dest)
        return self

    def delete(self) -> bool:
        if self.path.exists():
            self.path.unlink()
            return True
        return False

    def exists(self) -> bool:
        return self.path.exists()

    def info(self) -> FileInfo:
        return FileInfo.from_path(self.path)

    def hash(self, algorithm: str = "sha256") -> str:
        h = hashlib.new(algorithm)
        with open(self.path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                h.update(chunk)
        return h.hexdigest()

    def touch(self) -> "File":
        self.path.touch()
        return self

    def chmod(self, mode: int) -> "File":
        self.path.chmod(mode)
        return self

    def rename(self, name: str) -> "File":
        new_path = self.path.parent / name
        self.path.rename(new_path)
        self.path = new_path
        return self


class Directory:
    def __init__(self, path: Union[str, Path]):
        self.path = Path(path)

    def create(self, parents: bool = True, exist_ok: bool = True) -> "Directory":
        self.path.mkdir(parents=parents, exist_ok=exist_ok)
        return self

    def delete(self, recursive: bool = False) -> bool:
        if not self.path.exists():
            return False
        if recursive:
            shutil.rmtree(self.path)
        else:
            self.path.rmdir()
        return True

    def list(self, pattern: str = "*") -> List[Path]:
        return list(self.path.glob(pattern))

    def list_files(self, pattern: str = "*") -> List[Path]:
        return [p for p in self.path.glob(pattern) if p.is_file()]

    def list_dirs(self, pattern: str = "*") -> List[Path]:
        return [p for p in self.path.glob(pattern) if p.is_dir()]

    def walk(self, pattern: str = "**/*") -> Generator[Path, None, None]:
        for p in self.path.glob(pattern):
            yield p

    def copy(self, dest: Union[str, Path]) -> "Directory":
        shutil.copytree(self.path, dest)
        return Directory(dest)

    def size(self) -> int:
        total = 0
        for p in self.walk():
            if p.is_file():
                total += p.stat().st_size
        return total

    def file(self, name: str) -> File:
        return File(self.path / name)

    def subdir(self, name: str) -> "Directory":
        return Directory(self.path / name)

    def exists(self) -> bool:
        return self.path.exists() and self.path.is_dir()


class FileManager:
    def __init__(self, base_path: Union[str, Path] = "."):
        self.base = Path(base_path)

    def file(self, path: str) -> File:
        return File(self.base / path)

    def dir(self, path: str) -> Directory:
        return Directory(self.base / path)

    def read(self, path: str) -> str:
        return self.file(path).read()

    def write(self, path: str, content: str) -> int:
        return self.file(path).write(content)

    def exists(self, path: str) -> bool:
        return (self.base / path).exists()

    def delete(self, path: str) -> bool:
        p = self.base / path
        if p.is_file():
            p.unlink()
        elif p.is_dir():
            shutil.rmtree(p)
        else:
            return False
        return True

    def copy(self, src: str, dest: str) -> None:
        s = self.base / src
        d = self.base / dest
        if s.is_file():
            shutil.copy2(s, d)
        else:
            shutil.copytree(s, d)

    def move(self, src: str, dest: str) -> None:
        shutil.move(str(self.base / src), self.base / dest)

    def find(self, pattern: str) -> List[Path]:
        return list(self.base.glob(f"**/{pattern}"))


def read(path: str) -> str:
    return File(path).read()


def write(path: str, content: str, atomic: bool = True) -> int:
    return File(path).write(content, atomic=atomic)


def example_usage():
    fm = FileManager("/tmp/roadfile_test")
    fm.dir(".").create()

    fm.write("test.txt", "Hello, World!")
    print(f"Content: {fm.read('test.txt')}")

    f = fm.file("data.json")
    f.write_json({"name": "BlackRoad", "version": 1})
    print(f"JSON: {f.read_json()}")
    print(f"Hash: {f.hash()}")

    d = fm.dir("subdir")
    d.create()
    fm.write("subdir/nested.txt", "Nested content")
    print(f"Size: {d.size()} bytes")

    fm.delete("subdir")
    fm.delete("test.txt")
    fm.delete("data.json")


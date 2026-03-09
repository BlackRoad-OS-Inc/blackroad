"""
RoadPath - Path Utilities for BlackRoad
Path manipulation, normalization, and resolution.
"""

from dataclasses import dataclass
from pathlib import Path, PurePath
from typing import Any, List, Optional, Tuple, Union
import os
import re
import logging

logger = logging.getLogger(__name__)


class PathError(Exception):
    pass


@dataclass
class PathParts:
    drive: str
    root: str
    parts: Tuple[str, ...]
    name: str
    stem: str
    suffix: str
    suffixes: List[str]
    parent: str


class RoadPath:
    def __init__(self, path: Union[str, Path, "RoadPath"]):
        if isinstance(path, RoadPath):
            self._path = path._path
        else:
            self._path = Path(path)

    @classmethod
    def cwd(cls) -> "RoadPath":
        return cls(Path.cwd())

    @classmethod
    def home(cls) -> "RoadPath":
        return cls(Path.home())

    @classmethod
    def temp(cls) -> "RoadPath":
        import tempfile
        return cls(tempfile.gettempdir())

    def __str__(self) -> str:
        return str(self._path)

    def __repr__(self) -> str:
        return f"RoadPath({self._path!r})"

    def __truediv__(self, other: Union[str, Path]) -> "RoadPath":
        return RoadPath(self._path / other)

    def __eq__(self, other: Any) -> bool:
        if isinstance(other, RoadPath):
            return self._path == other._path
        if isinstance(other, (str, Path)):
            return self._path == Path(other)
        return False

    @property
    def path(self) -> Path:
        return self._path

    @property
    def name(self) -> str:
        return self._path.name

    @property
    def stem(self) -> str:
        return self._path.stem

    @property
    def suffix(self) -> str:
        return self._path.suffix

    @property
    def suffixes(self) -> List[str]:
        return self._path.suffixes

    @property
    def parent(self) -> "RoadPath":
        return RoadPath(self._path.parent)

    @property
    def parents(self) -> List["RoadPath"]:
        return [RoadPath(p) for p in self._path.parents]

    @property
    def parts(self) -> Tuple[str, ...]:
        return self._path.parts

    def parse(self) -> PathParts:
        return PathParts(
            drive=self._path.drive,
            root=self._path.root,
            parts=self._path.parts,
            name=self._path.name,
            stem=self._path.stem,
            suffix=self._path.suffix,
            suffixes=self._path.suffixes,
            parent=str(self._path.parent)
        )

    def absolute(self) -> "RoadPath":
        return RoadPath(self._path.absolute())

    def resolve(self) -> "RoadPath":
        return RoadPath(self._path.resolve())

    def normalize(self) -> "RoadPath":
        return RoadPath(os.path.normpath(self._path))

    def relative_to(self, base: Union[str, Path, "RoadPath"]) -> "RoadPath":
        if isinstance(base, RoadPath):
            base = base._path
        return RoadPath(self._path.relative_to(base))

    def with_name(self, name: str) -> "RoadPath":
        return RoadPath(self._path.with_name(name))

    def with_stem(self, stem: str) -> "RoadPath":
        return RoadPath(self._path.with_stem(stem))

    def with_suffix(self, suffix: str) -> "RoadPath":
        return RoadPath(self._path.with_suffix(suffix))

    def join(self, *parts: str) -> "RoadPath":
        return RoadPath(self._path.joinpath(*parts))

    def exists(self) -> bool:
        return self._path.exists()

    def is_file(self) -> bool:
        return self._path.is_file()

    def is_dir(self) -> bool:
        return self._path.is_dir()

    def is_symlink(self) -> bool:
        return self._path.is_symlink()

    def is_absolute(self) -> bool:
        return self._path.is_absolute()

    def match(self, pattern: str) -> bool:
        return self._path.match(pattern)

    def glob(self, pattern: str) -> List["RoadPath"]:
        return [RoadPath(p) for p in self._path.glob(pattern)]

    def rglob(self, pattern: str) -> List["RoadPath"]:
        return [RoadPath(p) for p in self._path.rglob(pattern)]


def join(*parts: str) -> str:
    return str(Path(*parts))


def split(path: str) -> Tuple[str, str]:
    p = Path(path)
    return str(p.parent), p.name


def dirname(path: str) -> str:
    return str(Path(path).parent)


def basename(path: str) -> str:
    return Path(path).name


def splitext(path: str) -> Tuple[str, str]:
    p = Path(path)
    return str(p.with_suffix("")), p.suffix


def normalize(path: str) -> str:
    return os.path.normpath(path)


def absolute(path: str) -> str:
    return str(Path(path).absolute())


def resolve(path: str) -> str:
    return str(Path(path).resolve())


def relative(path: str, base: str = None) -> str:
    base = base or os.getcwd()
    return str(Path(path).relative_to(base))


def expanduser(path: str) -> str:
    return os.path.expanduser(path)


def expandvars(path: str) -> str:
    return os.path.expandvars(path)


def expand(path: str) -> str:
    return expandvars(expanduser(path))


def commonpath(paths: List[str]) -> str:
    return os.path.commonpath(paths)


def commonprefix(paths: List[str]) -> str:
    return os.path.commonprefix(paths)


def samefile(path1: str, path2: str) -> bool:
    return os.path.samefile(path1, path2)


class PathBuilder:
    def __init__(self, base: str = ""):
        self._parts: List[str] = [base] if base else []

    def add(self, *parts: str) -> "PathBuilder":
        self._parts.extend(parts)
        return self

    def parent(self) -> "PathBuilder":
        self._parts.append("..")
        return self

    def build(self) -> RoadPath:
        return RoadPath(Path(*self._parts))

    def __str__(self) -> str:
        return str(self.build())


def builder(base: str = "") -> PathBuilder:
    return PathBuilder(base)


def example_usage():
    p = RoadPath("/home/user/documents/file.txt")
    parts = p.parse()
    print(f"Path: {p}")
    print(f"Name: {parts.name}")
    print(f"Stem: {parts.stem}")
    print(f"Suffix: {parts.suffix}")
    print(f"Parent: {parts.parent}")

    home = RoadPath.home()
    print(f"\nHome: {home}")
    print(f"Documents: {home / 'Documents'}")

    cwd = RoadPath.cwd()
    print(f"\nCWD: {cwd}")
    print(f"Absolute: {cwd.absolute()}")

    path = builder("/tmp").add("myapp", "data").add("file.json").build()
    print(f"\nBuilt path: {path}")

    print(f"\nJoin: {join('a', 'b', 'c')}")
    print(f"Dirname: {dirname('/a/b/c.txt')}")
    print(f"Basename: {basename('/a/b/c.txt')}")
    print(f"Splitext: {splitext('/a/b/c.tar.gz')}")


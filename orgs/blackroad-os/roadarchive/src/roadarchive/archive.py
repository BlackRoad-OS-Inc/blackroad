"""
RoadArchive - Archive Operations for BlackRoad
Create and extract archives in various formats.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, Generator, List, Optional, Union
import gzip
import os
import shutil
import tarfile
import zipfile
import logging

logger = logging.getLogger(__name__)


class ArchiveError(Exception):
    pass


class ArchiveFormat(str, Enum):
    ZIP = "zip"
    TAR = "tar"
    TAR_GZ = "tar.gz"
    TAR_BZ2 = "tar.bz2"
    TAR_XZ = "tar.xz"
    GZIP = "gz"


@dataclass
class ArchiveEntry:
    name: str
    size: int
    compressed_size: int = 0
    modified: datetime = None
    is_dir: bool = False
    is_file: bool = True
    mode: int = 0


@dataclass
class ArchiveInfo:
    path: Path
    format: ArchiveFormat
    size: int
    entries: List[ArchiveEntry] = field(default_factory=list)


class Archive:
    def __init__(self, path: Union[str, Path]):
        self.path = Path(path)
        self.format = self._detect_format()

    def _detect_format(self) -> ArchiveFormat:
        name = self.path.name.lower()
        if name.endswith(".zip"):
            return ArchiveFormat.ZIP
        elif name.endswith(".tar.gz") or name.endswith(".tgz"):
            return ArchiveFormat.TAR_GZ
        elif name.endswith(".tar.bz2") or name.endswith(".tbz2"):
            return ArchiveFormat.TAR_BZ2
        elif name.endswith(".tar.xz") or name.endswith(".txz"):
            return ArchiveFormat.TAR_XZ
        elif name.endswith(".tar"):
            return ArchiveFormat.TAR
        elif name.endswith(".gz"):
            return ArchiveFormat.GZIP
        raise ArchiveError(f"Unknown archive format: {name}")

    def list(self) -> List[ArchiveEntry]:
        entries = []
        if self.format == ArchiveFormat.ZIP:
            with zipfile.ZipFile(self.path, "r") as zf:
                for info in zf.infolist():
                    entries.append(ArchiveEntry(
                        name=info.filename,
                        size=info.file_size,
                        compressed_size=info.compress_size,
                        modified=datetime(*info.date_time),
                        is_dir=info.is_dir(),
                        is_file=not info.is_dir()
                    ))
        elif self.format in (ArchiveFormat.TAR, ArchiveFormat.TAR_GZ, ArchiveFormat.TAR_BZ2, ArchiveFormat.TAR_XZ):
            mode = self._tar_mode("r")
            with tarfile.open(self.path, mode) as tf:
                for info in tf.getmembers():
                    entries.append(ArchiveEntry(
                        name=info.name,
                        size=info.size,
                        modified=datetime.fromtimestamp(info.mtime),
                        is_dir=info.isdir(),
                        is_file=info.isfile(),
                        mode=info.mode
                    ))
        return entries

    def extract(self, dest: Union[str, Path] = ".", members: List[str] = None) -> List[Path]:
        dest = Path(dest)
        dest.mkdir(parents=True, exist_ok=True)
        extracted = []

        if self.format == ArchiveFormat.ZIP:
            with zipfile.ZipFile(self.path, "r") as zf:
                if members:
                    for m in members:
                        zf.extract(m, dest)
                        extracted.append(dest / m)
                else:
                    zf.extractall(dest)
                    extracted = [dest / n for n in zf.namelist()]
        elif self.format in (ArchiveFormat.TAR, ArchiveFormat.TAR_GZ, ArchiveFormat.TAR_BZ2, ArchiveFormat.TAR_XZ):
            mode = self._tar_mode("r")
            with tarfile.open(self.path, mode) as tf:
                if members:
                    for m in members:
                        tf.extract(m, dest)
                        extracted.append(dest / m)
                else:
                    tf.extractall(dest)
                    extracted = [dest / m.name for m in tf.getmembers()]
        elif self.format == ArchiveFormat.GZIP:
            out_path = dest / self.path.stem
            with gzip.open(self.path, "rb") as f_in:
                with open(out_path, "wb") as f_out:
                    shutil.copyfileobj(f_in, f_out)
            extracted = [out_path]

        return extracted

    def extract_file(self, name: str, dest: Union[str, Path] = ".") -> Path:
        return self.extract(dest, [name])[0]

    def read(self, name: str) -> bytes:
        if self.format == ArchiveFormat.ZIP:
            with zipfile.ZipFile(self.path, "r") as zf:
                return zf.read(name)
        elif self.format in (ArchiveFormat.TAR, ArchiveFormat.TAR_GZ, ArchiveFormat.TAR_BZ2, ArchiveFormat.TAR_XZ):
            mode = self._tar_mode("r")
            with tarfile.open(self.path, mode) as tf:
                member = tf.getmember(name)
                f = tf.extractfile(member)
                if f:
                    return f.read()
        raise ArchiveError(f"Cannot read {name}")

    def info(self) -> ArchiveInfo:
        return ArchiveInfo(
            path=self.path,
            format=self.format,
            size=self.path.stat().st_size,
            entries=self.list()
        )

    def _tar_mode(self, base: str) -> str:
        if self.format == ArchiveFormat.TAR_GZ:
            return f"{base}:gz"
        elif self.format == ArchiveFormat.TAR_BZ2:
            return f"{base}:bz2"
        elif self.format == ArchiveFormat.TAR_XZ:
            return f"{base}:xz"
        return base


class ArchiveBuilder:
    def __init__(self, path: Union[str, Path], format: ArchiveFormat = None):
        self.path = Path(path)
        self.format = format or self._detect_format()
        self._files: List[tuple] = []

    def _detect_format(self) -> ArchiveFormat:
        name = self.path.name.lower()
        if name.endswith(".zip"):
            return ArchiveFormat.ZIP
        elif name.endswith(".tar.gz") or name.endswith(".tgz"):
            return ArchiveFormat.TAR_GZ
        elif name.endswith(".tar.bz2"):
            return ArchiveFormat.TAR_BZ2
        elif name.endswith(".tar.xz"):
            return ArchiveFormat.TAR_XZ
        elif name.endswith(".tar"):
            return ArchiveFormat.TAR
        return ArchiveFormat.ZIP

    def add_file(self, path: Union[str, Path], arcname: str = None) -> "ArchiveBuilder":
        path = Path(path)
        arcname = arcname or path.name
        self._files.append((path, arcname))
        return self

    def add_dir(self, path: Union[str, Path], arcname: str = None) -> "ArchiveBuilder":
        path = Path(path)
        base_arcname = arcname or path.name
        for f in path.rglob("*"):
            if f.is_file():
                rel = f.relative_to(path)
                self._files.append((f, str(Path(base_arcname) / rel)))
        return self

    def add_bytes(self, data: bytes, arcname: str) -> "ArchiveBuilder":
        self._files.append((data, arcname))
        return self

    def build(self) -> Archive:
        if self.format == ArchiveFormat.ZIP:
            with zipfile.ZipFile(self.path, "w", zipfile.ZIP_DEFLATED) as zf:
                for src, arcname in self._files:
                    if isinstance(src, bytes):
                        zf.writestr(arcname, src)
                    else:
                        zf.write(src, arcname)
        else:
            mode = "w"
            if self.format == ArchiveFormat.TAR_GZ:
                mode = "w:gz"
            elif self.format == ArchiveFormat.TAR_BZ2:
                mode = "w:bz2"
            elif self.format == ArchiveFormat.TAR_XZ:
                mode = "w:xz"
            with tarfile.open(self.path, mode) as tf:
                for src, arcname in self._files:
                    if isinstance(src, bytes):
                        import io
                        info = tarfile.TarInfo(name=arcname)
                        info.size = len(src)
                        tf.addfile(info, io.BytesIO(src))
                    else:
                        tf.add(src, arcname)
        return Archive(self.path)


def create_zip(path: str, *files: str, base_dir: str = None) -> Archive:
    builder = ArchiveBuilder(path, ArchiveFormat.ZIP)
    for f in files:
        p = Path(f)
        if p.is_dir():
            builder.add_dir(p)
        else:
            builder.add_file(p)
    return builder.build()


def create_tar_gz(path: str, *files: str) -> Archive:
    builder = ArchiveBuilder(path, ArchiveFormat.TAR_GZ)
    for f in files:
        p = Path(f)
        if p.is_dir():
            builder.add_dir(p)
        else:
            builder.add_file(p)
    return builder.build()


def extract(archive_path: str, dest: str = ".") -> List[Path]:
    return Archive(archive_path).extract(dest)


def example_usage():
    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        Path(tmp, "test1.txt").write_text("Hello")
        Path(tmp, "test2.txt").write_text("World")

        zip_path = Path(tmp, "archive.zip")
        archive = (ArchiveBuilder(zip_path)
            .add_file(Path(tmp, "test1.txt"))
            .add_file(Path(tmp, "test2.txt"))
            .add_bytes(b"In-memory data", "memory.txt")
            .build())

        print(f"Created: {archive.path}")
        print(f"Format: {archive.format}")
        
        for entry in archive.list():
            print(f"  {entry.name}: {entry.size} bytes")

        content = archive.read("memory.txt")
        print(f"\nRead memory.txt: {content.decode()}")


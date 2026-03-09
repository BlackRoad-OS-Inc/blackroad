"""Hashing utilities.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import json
import logging
from dataclasses import asdict, is_dataclass
from enum import Enum
from pathlib import Path
from typing import Any, BinaryIO, Dict, List, Optional, Union

logger = logging.getLogger(__name__)


class HashAlgorithm(Enum):
    """Supported hash algorithms."""

    MD5 = "md5"
    SHA1 = "sha1"
    SHA256 = "sha256"
    SHA512 = "sha512"
    BLAKE2B = "blake2b"
    BLAKE2S = "blake2s"


def get_hasher(algorithm: HashAlgorithm):
    """Get hasher for algorithm."""
    if algorithm == HashAlgorithm.MD5:
        return hashlib.md5()
    elif algorithm == HashAlgorithm.SHA1:
        return hashlib.sha1()
    elif algorithm == HashAlgorithm.SHA256:
        return hashlib.sha256()
    elif algorithm == HashAlgorithm.SHA512:
        return hashlib.sha512()
    elif algorithm == HashAlgorithm.BLAKE2B:
        return hashlib.blake2b()
    elif algorithm == HashAlgorithm.BLAKE2S:
        return hashlib.blake2s()
    else:
        raise ValueError(f"Unknown algorithm: {algorithm}")


def compute_hash(
    data: Union[str, bytes, Dict, List, Any],
    algorithm: HashAlgorithm = HashAlgorithm.SHA256,
) -> str:
    """Compute hash of data.

    Args:
        data: Data to hash (string, bytes, or JSON-serializable)
        algorithm: Hash algorithm to use

    Returns:
        Hex-encoded hash string
    """
    hasher = get_hasher(algorithm)

    if isinstance(data, bytes):
        hasher.update(data)
    elif isinstance(data, str):
        hasher.update(data.encode("utf-8"))
    elif is_dataclass(data):
        json_str = json.dumps(asdict(data), sort_keys=True)
        hasher.update(json_str.encode("utf-8"))
    elif isinstance(data, (dict, list)):
        json_str = json.dumps(data, sort_keys=True, default=str)
        hasher.update(json_str.encode("utf-8"))
    else:
        hasher.update(str(data).encode("utf-8"))

    return hasher.hexdigest()


def compute_file_hash(
    path: Union[str, Path],
    algorithm: HashAlgorithm = HashAlgorithm.SHA256,
    chunk_size: int = 8192,
) -> str:
    """Compute hash of file contents.

    Args:
        path: Path to file
        algorithm: Hash algorithm
        chunk_size: Size of chunks to read

    Returns:
        Hex-encoded hash string
    """
    path = Path(path)
    hasher = get_hasher(algorithm)

    with path.open("rb") as f:
        while chunk := f.read(chunk_size):
            hasher.update(chunk)

    return hasher.hexdigest()


def compute_stream_hash(
    stream: BinaryIO,
    algorithm: HashAlgorithm = HashAlgorithm.SHA256,
    chunk_size: int = 8192,
) -> str:
    """Compute hash of stream contents."""
    hasher = get_hasher(algorithm)

    while chunk := stream.read(chunk_size):
        hasher.update(chunk)

    return hasher.hexdigest()


def compute_directory_hash(
    path: Union[str, Path],
    algorithm: HashAlgorithm = HashAlgorithm.SHA256,
    include_patterns: Optional[List[str]] = None,
    exclude_patterns: Optional[List[str]] = None,
) -> str:
    """Compute hash of directory contents.

    Hashes all files in directory recursively.
    """
    import fnmatch

    path = Path(path)
    hasher = get_hasher(algorithm)

    files = sorted(path.rglob("*"))

    for file_path in files:
        if not file_path.is_file():
            continue

        rel_path = str(file_path.relative_to(path))

        if include_patterns:
            if not any(fnmatch.fnmatch(rel_path, p) for p in include_patterns):
                continue

        if exclude_patterns:
            if any(fnmatch.fnmatch(rel_path, p) for p in exclude_patterns):
                continue

        hasher.update(rel_path.encode("utf-8"))

        file_hash = compute_file_hash(file_path, algorithm)
        hasher.update(file_hash.encode("utf-8"))

    return hasher.hexdigest()


def verify_hash(
    data: Union[str, bytes],
    expected_hash: str,
    algorithm: HashAlgorithm = HashAlgorithm.SHA256,
) -> bool:
    """Verify data matches expected hash."""
    actual_hash = compute_hash(data, algorithm)
    return actual_hash == expected_hash


def verify_file_hash(
    path: Union[str, Path],
    expected_hash: str,
    algorithm: HashAlgorithm = HashAlgorithm.SHA256,
) -> bool:
    """Verify file matches expected hash."""
    actual_hash = compute_file_hash(path, algorithm)
    return actual_hash == expected_hash


class ContentAddressable:
    """Mixin for content-addressable storage."""

    def content_hash(
        self,
        algorithm: HashAlgorithm = HashAlgorithm.SHA256,
    ) -> str:
        """Compute content hash of this object."""
        if is_dataclass(self):
            data = asdict(self)
        elif hasattr(self, "__dict__"):
            data = self.__dict__
        else:
            data = str(self)

        return compute_hash(data, algorithm)


__all__ = [
    "HashAlgorithm",
    "compute_hash",
    "compute_file_hash",
    "compute_stream_hash",
    "compute_directory_hash",
    "verify_hash",
    "verify_file_hash",
    "ContentAddressable",
]

"""RoadQueue Compressor - Message Compression.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import gzip
import zlib
from abc import ABC, abstractmethod


class Compressor(ABC):
    """Abstract message compressor."""

    @abstractmethod
    def compress(self, data: bytes) -> bytes:
        """Compress data."""
        pass

    @abstractmethod
    def decompress(self, data: bytes) -> bytes:
        """Decompress data."""
        pass

    @property
    @abstractmethod
    def encoding(self) -> str:
        """Get content encoding."""
        pass


class GzipCompressor(Compressor):
    """Gzip compressor."""

    def __init__(self, level: int = 9):
        self.level = level

    def compress(self, data: bytes) -> bytes:
        return gzip.compress(data, compresslevel=self.level)

    def decompress(self, data: bytes) -> bytes:
        return gzip.decompress(data)

    @property
    def encoding(self) -> str:
        return "gzip"


class ZlibCompressor(Compressor):
    """Zlib compressor."""

    def __init__(self, level: int = 9):
        self.level = level

    def compress(self, data: bytes) -> bytes:
        return zlib.compress(data, level=self.level)

    def decompress(self, data: bytes) -> bytes:
        return zlib.decompress(data)

    @property
    def encoding(self) -> str:
        return "deflate"


class LZ4Compressor(Compressor):
    """LZ4 compressor (fast)."""

    def compress(self, data: bytes) -> bytes:
        try:
            import lz4.frame
            return lz4.frame.compress(data)
        except ImportError:
            return GzipCompressor().compress(data)

    def decompress(self, data: bytes) -> bytes:
        try:
            import lz4.frame
            return lz4.frame.decompress(data)
        except ImportError:
            return GzipCompressor().decompress(data)

    @property
    def encoding(self) -> str:
        return "lz4"


class NoCompressor(Compressor):
    """No compression (passthrough)."""

    def compress(self, data: bytes) -> bytes:
        return data

    def decompress(self, data: bytes) -> bytes:
        return data

    @property
    def encoding(self) -> str:
        return "identity"


__all__ = ["Compressor", "GzipCompressor", "ZlibCompressor", "LZ4Compressor", "NoCompressor"]

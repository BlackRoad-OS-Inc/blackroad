"""
RoadCompress - Compression Utilities for BlackRoad
Data compression, streaming, and format support.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, BinaryIO, Callable, Dict, Generator, List, Optional, Union
import gzip
import hashlib
import io
import json
import logging
import os
import struct
import threading
import zlib

logger = logging.getLogger(__name__)


class CompressionFormat(str, Enum):
    """Compression formats."""
    GZIP = "gzip"
    ZLIB = "zlib"
    DEFLATE = "deflate"
    RAW = "raw"


class CompressionLevel(Enum):
    """Compression levels."""
    NONE = 0
    FAST = 1
    DEFAULT = 6
    BEST = 9


@dataclass
class CompressionStats:
    """Compression statistics."""
    original_size: int
    compressed_size: int
    compression_ratio: float
    format: CompressionFormat
    level: int
    duration_ms: float

    @property
    def space_saved_percent(self) -> float:
        if self.original_size == 0:
            return 0
        return (1 - self.compressed_size / self.original_size) * 100


@dataclass
class CompressedData:
    """Compressed data container."""
    data: bytes
    format: CompressionFormat
    original_size: int
    checksum: str
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_bytes(self) -> bytes:
        """Serialize to bytes with header."""
        header = {
            "format": self.format.value,
            "original_size": self.original_size,
            "checksum": self.checksum,
            "metadata": self.metadata
        }
        header_json = json.dumps(header).encode()
        header_len = struct.pack(">I", len(header_json))
        return header_len + header_json + self.data

    @classmethod
    def from_bytes(cls, data: bytes) -> "CompressedData":
        """Deserialize from bytes."""
        header_len = struct.unpack(">I", data[:4])[0]
        header_json = data[4:4 + header_len]
        header = json.loads(header_json)
        compressed = data[4 + header_len:]

        return cls(
            data=compressed,
            format=CompressionFormat(header["format"]),
            original_size=header["original_size"],
            checksum=header["checksum"],
            metadata=header.get("metadata", {})
        )


class Compressor:
    """Base compressor."""

    def compress(self, data: bytes, level: int = 6) -> bytes:
        raise NotImplementedError

    def decompress(self, data: bytes) -> bytes:
        raise NotImplementedError


class GzipCompressor(Compressor):
    """GZIP compression."""

    def compress(self, data: bytes, level: int = 6) -> bytes:
        return gzip.compress(data, compresslevel=level)

    def decompress(self, data: bytes) -> bytes:
        return gzip.decompress(data)


class ZlibCompressor(Compressor):
    """ZLIB compression."""

    def compress(self, data: bytes, level: int = 6) -> bytes:
        return zlib.compress(data, level)

    def decompress(self, data: bytes) -> bytes:
        return zlib.decompress(data)


class DeflateCompressor(Compressor):
    """Raw DEFLATE compression."""

    def compress(self, data: bytes, level: int = 6) -> bytes:
        compress_obj = zlib.compressobj(level, zlib.DEFLATED, -zlib.MAX_WBITS)
        return compress_obj.compress(data) + compress_obj.flush()

    def decompress(self, data: bytes) -> bytes:
        decompress_obj = zlib.decompressobj(-zlib.MAX_WBITS)
        return decompress_obj.decompress(data)


class StreamingCompressor:
    """Streaming compression for large data."""

    def __init__(self, format: CompressionFormat = CompressionFormat.GZIP, level: int = 6):
        self.format = format
        self.level = level
        self._compressor = None
        self._init_compressor()

    def _init_compressor(self):
        if self.format == CompressionFormat.GZIP:
            self._compressor = zlib.compressobj(
                self.level, zlib.DEFLATED, zlib.MAX_WBITS | 16
            )
        elif self.format == CompressionFormat.ZLIB:
            self._compressor = zlib.compressobj(self.level)
        else:
            self._compressor = zlib.compressobj(self.level, zlib.DEFLATED, -zlib.MAX_WBITS)

    def compress_chunk(self, chunk: bytes) -> bytes:
        """Compress a chunk of data."""
        return self._compressor.compress(chunk)

    def finish(self) -> bytes:
        """Finish compression and return final bytes."""
        return self._compressor.flush()

    def reset(self):
        """Reset compressor for new stream."""
        self._init_compressor()


class StreamingDecompressor:
    """Streaming decompression for large data."""

    def __init__(self, format: CompressionFormat = CompressionFormat.GZIP):
        self.format = format
        self._decompressor = None
        self._init_decompressor()

    def _init_decompressor(self):
        if self.format == CompressionFormat.GZIP:
            self._decompressor = zlib.decompressobj(zlib.MAX_WBITS | 16)
        elif self.format == CompressionFormat.ZLIB:
            self._decompressor = zlib.decompressobj()
        else:
            self._decompressor = zlib.decompressobj(-zlib.MAX_WBITS)

    def decompress_chunk(self, chunk: bytes) -> bytes:
        """Decompress a chunk of data."""
        return self._decompressor.decompress(chunk)

    def reset(self):
        """Reset decompressor for new stream."""
        self._init_decompressor()


class CompressionPipeline:
    """Pipeline for processing data through compression."""

    def __init__(self):
        self.steps: List[Callable[[bytes], bytes]] = []

    def add_step(self, step: Callable[[bytes], bytes]) -> "CompressionPipeline":
        """Add a processing step."""
        self.steps.append(step)
        return self

    def process(self, data: bytes) -> bytes:
        """Process data through all steps."""
        result = data
        for step in self.steps:
            result = step(result)
        return result


class ChunkedCompressor:
    """Compress data in chunks for memory efficiency."""

    def __init__(
        self,
        format: CompressionFormat = CompressionFormat.GZIP,
        chunk_size: int = 64 * 1024,  # 64KB
        level: int = 6
    ):
        self.format = format
        self.chunk_size = chunk_size
        self.level = level

    def compress_stream(
        self,
        source: BinaryIO,
        target: BinaryIO
    ) -> CompressionStats:
        """Compress from source stream to target stream."""
        import time
        start = time.time()

        compressor = StreamingCompressor(self.format, self.level)
        original_size = 0
        compressed_size = 0

        while True:
            chunk = source.read(self.chunk_size)
            if not chunk:
                break

            original_size += len(chunk)
            compressed = compressor.compress_chunk(chunk)
            compressed_size += len(compressed)
            target.write(compressed)

        final = compressor.finish()
        compressed_size += len(final)
        target.write(final)

        duration = (time.time() - start) * 1000

        return CompressionStats(
            original_size=original_size,
            compressed_size=compressed_size,
            compression_ratio=compressed_size / original_size if original_size > 0 else 0,
            format=self.format,
            level=self.level,
            duration_ms=duration
        )

    def decompress_stream(
        self,
        source: BinaryIO,
        target: BinaryIO
    ) -> int:
        """Decompress from source stream to target stream."""
        decompressor = StreamingDecompressor(self.format)
        decompressed_size = 0

        while True:
            chunk = source.read(self.chunk_size)
            if not chunk:
                break

            decompressed = decompressor.decompress_chunk(chunk)
            decompressed_size += len(decompressed)
            target.write(decompressed)

        return decompressed_size


class DictionaryCompressor:
    """Dictionary-based compression for repeated patterns."""

    def __init__(self, dictionary: bytes = None):
        self.dictionary = dictionary or b""
        self._compressor = None
        self._decompressor = None
        self._init()

    def _init(self):
        if self.dictionary:
            self._compressor = zlib.compressobj(
                zlib.Z_DEFAULT_COMPRESSION,
                zlib.DEFLATED,
                -zlib.MAX_WBITS,
                zdict=self.dictionary
            )
            self._decompressor = zlib.decompressobj(-zlib.MAX_WBITS, zdict=self.dictionary)
        else:
            self._compressor = zlib.compressobj(zlib.Z_DEFAULT_COMPRESSION, zlib.DEFLATED, -zlib.MAX_WBITS)
            self._decompressor = zlib.decompressobj(-zlib.MAX_WBITS)

    def compress(self, data: bytes) -> bytes:
        """Compress with dictionary."""
        self._compressor = zlib.compressobj(
            zlib.Z_DEFAULT_COMPRESSION,
            zlib.DEFLATED,
            -zlib.MAX_WBITS,
            zdict=self.dictionary
        ) if self.dictionary else zlib.compressobj(zlib.Z_DEFAULT_COMPRESSION, zlib.DEFLATED, -zlib.MAX_WBITS)

        return self._compressor.compress(data) + self._compressor.flush()

    def decompress(self, data: bytes) -> bytes:
        """Decompress with dictionary."""
        self._decompressor = zlib.decompressobj(
            -zlib.MAX_WBITS,
            zdict=self.dictionary
        ) if self.dictionary else zlib.decompressobj(-zlib.MAX_WBITS)

        return self._decompressor.decompress(data)


class CompressionCache:
    """Cache for compressed data."""

    def __init__(self, max_size: int = 100):
        self.max_size = max_size
        self._cache: Dict[str, CompressedData] = {}
        self._access_order: List[str] = []
        self._lock = threading.Lock()

    def _get_key(self, data: bytes) -> str:
        return hashlib.sha256(data).hexdigest()

    def get(self, data: bytes) -> Optional[CompressedData]:
        """Get compressed data from cache."""
        key = self._get_key(data)
        with self._lock:
            if key in self._cache:
                self._access_order.remove(key)
                self._access_order.append(key)
                return self._cache[key]
        return None

    def put(self, original: bytes, compressed: CompressedData) -> None:
        """Put compressed data in cache."""
        key = self._get_key(original)
        with self._lock:
            if key in self._cache:
                self._access_order.remove(key)
            elif len(self._cache) >= self.max_size:
                oldest = self._access_order.pop(0)
                del self._cache[oldest]

            self._cache[key] = compressed
            self._access_order.append(key)


class CompressionManager:
    """High-level compression management."""

    def __init__(self, default_format: CompressionFormat = CompressionFormat.GZIP):
        self.default_format = default_format
        self.compressors: Dict[CompressionFormat, Compressor] = {
            CompressionFormat.GZIP: GzipCompressor(),
            CompressionFormat.ZLIB: ZlibCompressor(),
            CompressionFormat.DEFLATE: DeflateCompressor()
        }
        self.cache = CompressionCache()

    def compress(
        self,
        data: Union[str, bytes],
        format: CompressionFormat = None,
        level: int = 6,
        use_cache: bool = True
    ) -> CompressedData:
        """Compress data."""
        if isinstance(data, str):
            data = data.encode()

        format = format or self.default_format

        # Check cache
        if use_cache:
            cached = self.cache.get(data)
            if cached and cached.format == format:
                return cached

        compressor = self.compressors.get(format)
        if not compressor:
            raise ValueError(f"Unsupported format: {format}")

        compressed_bytes = compressor.compress(data, level)
        checksum = hashlib.md5(data).hexdigest()

        result = CompressedData(
            data=compressed_bytes,
            format=format,
            original_size=len(data),
            checksum=checksum
        )

        if use_cache:
            self.cache.put(data, result)

        return result

    def decompress(self, compressed: CompressedData, verify: bool = True) -> bytes:
        """Decompress data."""
        compressor = self.compressors.get(compressed.format)
        if not compressor:
            raise ValueError(f"Unsupported format: {compressed.format}")

        data = compressor.decompress(compressed.data)

        if verify:
            checksum = hashlib.md5(data).hexdigest()
            if checksum != compressed.checksum:
                raise ValueError("Checksum verification failed")

        return data

    def compress_file(
        self,
        input_path: str,
        output_path: str = None,
        format: CompressionFormat = None,
        level: int = 6
    ) -> CompressionStats:
        """Compress a file."""
        format = format or self.default_format
        output_path = output_path or f"{input_path}.{format.value}"

        chunked = ChunkedCompressor(format, level=level)

        with open(input_path, 'rb') as source:
            with open(output_path, 'wb') as target:
                return chunked.compress_stream(source, target)

    def decompress_file(
        self,
        input_path: str,
        output_path: str,
        format: CompressionFormat = None
    ) -> int:
        """Decompress a file."""
        format = format or self.default_format
        chunked = ChunkedCompressor(format)

        with open(input_path, 'rb') as source:
            with open(output_path, 'wb') as target:
                return chunked.decompress_stream(source, target)

    def compress_json(self, obj: Any, format: CompressionFormat = None) -> CompressedData:
        """Compress a JSON-serializable object."""
        json_bytes = json.dumps(obj, separators=(',', ':')).encode()
        return self.compress(json_bytes, format)

    def decompress_json(self, compressed: CompressedData) -> Any:
        """Decompress and parse JSON."""
        data = self.decompress(compressed)
        return json.loads(data.decode())

    def get_best_format(self, data: bytes, sample_size: int = 10000) -> CompressionFormat:
        """Find best compression format for data."""
        sample = data[:sample_size] if len(data) > sample_size else data

        best_format = self.default_format
        best_ratio = 1.0

        for format, compressor in self.compressors.items():
            try:
                compressed = compressor.compress(sample)
                ratio = len(compressed) / len(sample)
                if ratio < best_ratio:
                    best_ratio = ratio
                    best_format = format
            except Exception:
                continue

        return best_format

    def estimate_compression(
        self,
        data: bytes,
        format: CompressionFormat = None
    ) -> Dict[str, Any]:
        """Estimate compression results without full compression."""
        format = format or self.default_format
        sample_size = min(len(data), 10000)
        sample = data[:sample_size]

        compressor = self.compressors.get(format)
        compressed_sample = compressor.compress(sample)

        ratio = len(compressed_sample) / len(sample)
        estimated_size = int(len(data) * ratio)

        return {
            "original_size": len(data),
            "estimated_compressed_size": estimated_size,
            "estimated_ratio": ratio,
            "estimated_savings_percent": (1 - ratio) * 100,
            "format": format.value
        }


# Example usage
def example_usage():
    """Example compression usage."""
    manager = CompressionManager()

    # Compress string
    text = "Hello, World! " * 1000
    compressed = manager.compress(text)
    print(f"Original: {compressed.original_size} bytes")
    print(f"Compressed: {len(compressed.data)} bytes")
    print(f"Ratio: {len(compressed.data) / compressed.original_size:.2%}")

    # Decompress
    decompressed = manager.decompress(compressed)
    print(f"Decompressed: {len(decompressed)} bytes")

    # Compress JSON
    data = {"users": [{"name": f"User {i}", "id": i} for i in range(100)]}
    compressed_json = manager.compress_json(data)
    print(f"JSON compressed: {len(compressed_json.data)} bytes")

    # Decompress JSON
    restored = manager.decompress_json(compressed_json)
    print(f"Restored users: {len(restored['users'])}")

    # Estimate compression
    large_data = b"x" * 1000000
    estimate = manager.estimate_compression(large_data)
    print(f"Estimated savings: {estimate['estimated_savings_percent']:.1f}%")

    # Streaming compression
    source = io.BytesIO(b"data " * 10000)
    target = io.BytesIO()

    chunked = ChunkedCompressor()
    stats = chunked.compress_stream(source, target)
    print(f"Streamed: {stats.original_size} -> {stats.compressed_size}")


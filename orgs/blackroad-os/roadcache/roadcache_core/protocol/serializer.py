"""RoadCache Serializer - Value Serialization.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import gzip
import json
import logging
import pickle
import zlib
from abc import ABC, abstractmethod
from dataclasses import dataclass
from enum import Enum, auto
from typing import Any, Optional, Type

logger = logging.getLogger(__name__)


class CompressionType(Enum):
    """Compression types."""

    NONE = auto()
    GZIP = auto()
    ZLIB = auto()
    LZ4 = auto()


@dataclass
class SerializedData:
    """Serialized data container.

    Attributes:
        data: Serialized bytes
        format: Serialization format
        compressed: Whether compressed
        compression_type: Compression type
        original_size: Original size
    """

    data: bytes
    format: str
    compressed: bool = False
    compression_type: CompressionType = CompressionType.NONE
    original_size: int = 0


class Serializer(ABC):
    """Abstract serializer for cache values.

    Implementations handle different serialization formats.
    """

    @property
    @abstractmethod
    def format_name(self) -> str:
        """Get format name."""
        pass

    @abstractmethod
    def serialize(self, value: Any) -> bytes:
        """Serialize value to bytes.

        Args:
            value: Value to serialize

        Returns:
            Serialized bytes
        """
        pass

    @abstractmethod
    def deserialize(self, data: bytes) -> Any:
        """Deserialize bytes to value.

        Args:
            data: Serialized bytes

        Returns:
            Deserialized value
        """
        pass

    def serialize_with_compression(
        self,
        value: Any,
        compression: CompressionType = CompressionType.GZIP,
        threshold: int = 1024,
    ) -> SerializedData:
        """Serialize with optional compression.

        Args:
            value: Value to serialize
            compression: Compression type
            threshold: Size threshold for compression

        Returns:
            SerializedData container
        """
        data = self.serialize(value)
        original_size = len(data)

        if compression != CompressionType.NONE and len(data) >= threshold:
            if compression == CompressionType.GZIP:
                compressed = gzip.compress(data)
            elif compression == CompressionType.ZLIB:
                compressed = zlib.compress(data)
            else:
                compressed = data

            if len(compressed) < len(data):
                return SerializedData(
                    data=compressed,
                    format=self.format_name,
                    compressed=True,
                    compression_type=compression,
                    original_size=original_size,
                )

        return SerializedData(
            data=data,
            format=self.format_name,
            compressed=False,
            original_size=original_size,
        )

    def deserialize_with_decompression(
        self,
        serialized: SerializedData,
    ) -> Any:
        """Deserialize with decompression if needed.

        Args:
            serialized: Serialized data

        Returns:
            Deserialized value
        """
        data = serialized.data

        if serialized.compressed:
            if serialized.compression_type == CompressionType.GZIP:
                data = gzip.decompress(data)
            elif serialized.compression_type == CompressionType.ZLIB:
                data = zlib.decompress(data)

        return self.deserialize(data)


class JSONSerializer(Serializer):
    """JSON serializer.

    Good for human-readable data and interoperability.
    Limited to JSON-compatible types.
    """

    @property
    def format_name(self) -> str:
        return "json"

    def serialize(self, value: Any) -> bytes:
        """Serialize to JSON bytes.

        Args:
            value: Value to serialize

        Returns:
            JSON bytes
        """
        return json.dumps(value, default=str).encode("utf-8")

    def deserialize(self, data: bytes) -> Any:
        """Deserialize from JSON bytes.

        Args:
            data: JSON bytes

        Returns:
            Deserialized value
        """
        return json.loads(data.decode("utf-8"))


class PickleSerializer(Serializer):
    """Pickle serializer.

    Supports any Python object.
    Not safe for untrusted data.
    """

    def __init__(self, protocol: int = pickle.HIGHEST_PROTOCOL):
        """Initialize pickle serializer.

        Args:
            protocol: Pickle protocol version
        """
        self.protocol = protocol

    @property
    def format_name(self) -> str:
        return "pickle"

    def serialize(self, value: Any) -> bytes:
        """Serialize to pickle bytes.

        Args:
            value: Value to serialize

        Returns:
            Pickle bytes
        """
        return pickle.dumps(value, protocol=self.protocol)

    def deserialize(self, data: bytes) -> Any:
        """Deserialize from pickle bytes.

        Args:
            data: Pickle bytes

        Returns:
            Deserialized value
        """
        return pickle.loads(data)


class MsgPackSerializer(Serializer):
    """MessagePack serializer.

    Compact binary format, faster than JSON.
    Requires msgpack package.
    """

    @property
    def format_name(self) -> str:
        return "msgpack"

    def serialize(self, value: Any) -> bytes:
        """Serialize to MessagePack bytes.

        Args:
            value: Value to serialize

        Returns:
            MessagePack bytes
        """
        try:
            import msgpack
            return msgpack.packb(value, use_bin_type=True)
        except ImportError:
            raise ImportError("msgpack package not installed")

    def deserialize(self, data: bytes) -> Any:
        """Deserialize from MessagePack bytes.

        Args:
            data: MessagePack bytes

        Returns:
            Deserialized value
        """
        try:
            import msgpack
            return msgpack.unpackb(data, raw=False)
        except ImportError:
            raise ImportError("msgpack package not installed")


class SerializerRegistry:
    """Registry of serializers."""

    def __init__(self):
        self._serializers: dict[str, Serializer] = {}
        self._default: str = "pickle"

        # Register default serializers
        self.register(JSONSerializer())
        self.register(PickleSerializer())

    def register(self, serializer: Serializer) -> None:
        """Register a serializer.

        Args:
            serializer: Serializer to register
        """
        self._serializers[serializer.format_name] = serializer

    def get(self, format_name: str) -> Serializer:
        """Get serializer by format.

        Args:
            format_name: Format name

        Returns:
            Serializer instance

        Raises:
            KeyError: If format not found
        """
        if format_name not in self._serializers:
            raise KeyError(f"Unknown serializer format: {format_name}")
        return self._serializers[format_name]

    def get_default(self) -> Serializer:
        """Get default serializer.

        Returns:
            Default serializer
        """
        return self._serializers[self._default]

    def set_default(self, format_name: str) -> None:
        """Set default serializer.

        Args:
            format_name: Format name
        """
        if format_name not in self._serializers:
            raise KeyError(f"Unknown serializer format: {format_name}")
        self._default = format_name

    def list_formats(self) -> list[str]:
        """List available formats.

        Returns:
            List of format names
        """
        return list(self._serializers.keys())


# Global registry
_registry = SerializerRegistry()


def get_serializer(format_name: Optional[str] = None) -> Serializer:
    """Get serializer by format.

    Args:
        format_name: Format name or None for default

    Returns:
        Serializer instance
    """
    if format_name is None:
        return _registry.get_default()
    return _registry.get(format_name)


__all__ = [
    "Serializer",
    "SerializedData",
    "CompressionType",
    "JSONSerializer",
    "PickleSerializer",
    "MsgPackSerializer",
    "SerializerRegistry",
    "get_serializer",
]

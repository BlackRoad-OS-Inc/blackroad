"""RoadQueue Codec - Pluggable Codec System.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from typing import Any, Dict, Optional, Type

from roadqueue_core.protocol.serializer import Serializer, JSONSerializer
from roadqueue_core.protocol.compressor import Compressor, NoCompressor


class Codec:
    """Message codec combining serialization and compression."""

    def __init__(
        self,
        serializer: Optional[Serializer] = None,
        compressor: Optional[Compressor] = None,
    ):
        self.serializer = serializer or JSONSerializer()
        self.compressor = compressor or NoCompressor()

    def encode(self, data: Any) -> bytes:
        """Encode data to bytes."""
        serialized = self.serializer.serialize(data)
        return self.compressor.compress(serialized)

    def decode(self, data: bytes) -> Any:
        """Decode bytes to data."""
        decompressed = self.compressor.decompress(data)
        return self.serializer.deserialize(decompressed)

    @property
    def content_type(self) -> str:
        return self.serializer.content_type

    @property
    def content_encoding(self) -> str:
        return self.compressor.encoding


class CodecRegistry:
    """Registry for codec lookup."""

    _codecs: Dict[str, Codec] = {}
    _default: Optional[Codec] = None

    @classmethod
    def register(cls, name: str, codec: Codec) -> None:
        """Register a codec."""
        cls._codecs[name] = codec

    @classmethod
    def get(cls, name: str) -> Optional[Codec]:
        """Get a codec by name."""
        return cls._codecs.get(name)

    @classmethod
    def set_default(cls, codec: Codec) -> None:
        """Set default codec."""
        cls._default = codec

    @classmethod
    def default(cls) -> Codec:
        """Get default codec."""
        return cls._default or Codec()


# Register common codecs
CodecRegistry.register("json", Codec())
CodecRegistry.set_default(Codec())


__all__ = ["Codec", "CodecRegistry"]

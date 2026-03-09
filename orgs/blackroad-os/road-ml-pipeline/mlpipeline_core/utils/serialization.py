"""Serialization utilities.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import gzip
import io
import json
import logging
import pickle
from abc import ABC, abstractmethod
from dataclasses import asdict, is_dataclass
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Dict, Optional, Type, TypeVar, Union

logger = logging.getLogger(__name__)

T = TypeVar("T")


class SerializationFormat(Enum):
    """Supported serialization formats."""

    JSON = "json"
    PICKLE = "pickle"
    MSGPACK = "msgpack"


class Serializer(ABC):
    """Abstract serializer interface."""

    @abstractmethod
    def serialize(self, obj: Any) -> bytes:
        """Serialize object to bytes."""
        pass

    @abstractmethod
    def deserialize(self, data: bytes, target_type: Optional[Type[T]] = None) -> T:
        """Deserialize bytes to object."""
        pass

    def to_file(self, obj: Any, path: Union[str, Path], compress: bool = False) -> None:
        """Serialize to file."""
        data = self.serialize(obj)
        path = Path(path)

        if compress:
            data = gzip.compress(data)
            path = path.with_suffix(path.suffix + ".gz")

        path.write_bytes(data)
        logger.debug(f"Serialized to {path}")

    def from_file(
        self,
        path: Union[str, Path],
        target_type: Optional[Type[T]] = None,
        decompress: bool = False,
    ) -> T:
        """Deserialize from file."""
        path = Path(path)
        data = path.read_bytes()

        if decompress or path.suffix == ".gz":
            data = gzip.decompress(data)

        return self.deserialize(data, target_type)


class JSONSerializer(Serializer):
    """JSON serializer with extended type support."""

    def __init__(self, indent: Optional[int] = None, sort_keys: bool = False):
        self.indent = indent
        self.sort_keys = sort_keys

    def serialize(self, obj: Any) -> bytes:
        """Serialize to JSON bytes."""
        return json.dumps(
            obj,
            default=self._default_encoder,
            indent=self.indent,
            sort_keys=self.sort_keys,
        ).encode("utf-8")

    def deserialize(self, data: bytes, target_type: Optional[Type[T]] = None) -> T:
        """Deserialize from JSON bytes."""
        parsed = json.loads(data.decode("utf-8"))

        if target_type and is_dataclass(target_type):
            return target_type(**parsed)

        return parsed

    def _default_encoder(self, obj: Any) -> Any:
        """Handle non-JSON-serializable types."""
        if isinstance(obj, datetime):
            return {"__datetime__": obj.isoformat()}
        elif isinstance(obj, Enum):
            return {"__enum__": f"{type(obj).__name__}.{obj.name}"}
        elif is_dataclass(obj):
            return {"__dataclass__": type(obj).__name__, "data": asdict(obj)}
        elif isinstance(obj, bytes):
            return {"__bytes__": obj.hex()}
        elif isinstance(obj, set):
            return {"__set__": list(obj)}
        elif isinstance(obj, Path):
            return {"__path__": str(obj)}
        elif hasattr(obj, "__dict__"):
            return {"__object__": type(obj).__name__, "data": obj.__dict__}

        raise TypeError(f"Object of type {type(obj).__name__} is not JSON serializable")


class PickleSerializer(Serializer):
    """Pickle serializer for arbitrary Python objects."""

    def __init__(self, protocol: int = pickle.HIGHEST_PROTOCOL):
        self.protocol = protocol

    def serialize(self, obj: Any) -> bytes:
        """Serialize to pickle bytes."""
        return pickle.dumps(obj, protocol=self.protocol)

    def deserialize(self, data: bytes, target_type: Optional[Type[T]] = None) -> T:
        """Deserialize from pickle bytes."""
        return pickle.loads(data)


class CompressedSerializer(Serializer):
    """Wrapper that adds compression to any serializer."""

    def __init__(self, inner: Serializer, compression_level: int = 9):
        self.inner = inner
        self.compression_level = compression_level

    def serialize(self, obj: Any) -> bytes:
        """Serialize and compress."""
        data = self.inner.serialize(obj)
        return gzip.compress(data, compresslevel=self.compression_level)

    def deserialize(self, data: bytes, target_type: Optional[Type[T]] = None) -> T:
        """Decompress and deserialize."""
        decompressed = gzip.decompress(data)
        return self.inner.deserialize(decompressed, target_type)


# Convenience functions
_default_json = JSONSerializer()
_default_pickle = PickleSerializer()


def serialize(
    obj: Any,
    format: SerializationFormat = SerializationFormat.JSON,
) -> bytes:
    """Serialize object using specified format."""
    if format == SerializationFormat.JSON:
        return _default_json.serialize(obj)
    elif format == SerializationFormat.PICKLE:
        return _default_pickle.serialize(obj)
    else:
        raise ValueError(f"Unsupported format: {format}")


def deserialize(
    data: bytes,
    format: SerializationFormat = SerializationFormat.JSON,
    target_type: Optional[Type[T]] = None,
) -> T:
    """Deserialize bytes using specified format."""
    if format == SerializationFormat.JSON:
        return _default_json.deserialize(data, target_type)
    elif format == SerializationFormat.PICKLE:
        return _default_pickle.deserialize(data, target_type)
    else:
        raise ValueError(f"Unsupported format: {format}")


__all__ = [
    "Serializer",
    "JSONSerializer",
    "PickleSerializer",
    "CompressedSerializer",
    "SerializationFormat",
    "serialize",
    "deserialize",
]

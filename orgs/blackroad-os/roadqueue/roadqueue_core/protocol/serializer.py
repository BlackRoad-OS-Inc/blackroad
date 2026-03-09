"""RoadQueue Serializer - Message Serialization.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import json
import pickle
from abc import ABC, abstractmethod
from typing import Any


class Serializer(ABC):
    """Abstract message serializer."""

    @abstractmethod
    def serialize(self, data: Any) -> bytes:
        """Serialize data to bytes."""
        pass

    @abstractmethod
    def deserialize(self, data: bytes) -> Any:
        """Deserialize bytes to data."""
        pass

    @property
    @abstractmethod
    def content_type(self) -> str:
        """Get content type."""
        pass


class JSONSerializer(Serializer):
    """JSON serializer."""

    def serialize(self, data: Any) -> bytes:
        return json.dumps(data).encode("utf-8")

    def deserialize(self, data: bytes) -> Any:
        return json.loads(data.decode("utf-8"))

    @property
    def content_type(self) -> str:
        return "application/json"


class PickleSerializer(Serializer):
    """Pickle serializer for Python objects."""

    def serialize(self, data: Any) -> bytes:
        return pickle.dumps(data)

    def deserialize(self, data: bytes) -> Any:
        return pickle.loads(data)

    @property
    def content_type(self) -> str:
        return "application/x-python-pickle"


class MsgPackSerializer(Serializer):
    """MessagePack serializer."""

    def serialize(self, data: Any) -> bytes:
        try:
            import msgpack
            return msgpack.packb(data, use_bin_type=True)
        except ImportError:
            return JSONSerializer().serialize(data)

    def deserialize(self, data: bytes) -> Any:
        try:
            import msgpack
            return msgpack.unpackb(data, raw=False)
        except ImportError:
            return JSONSerializer().deserialize(data)

    @property
    def content_type(self) -> str:
        return "application/msgpack"


__all__ = ["Serializer", "JSONSerializer", "PickleSerializer", "MsgPackSerializer"]

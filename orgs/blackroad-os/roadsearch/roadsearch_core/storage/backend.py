"""RoadSearch Storage Backend - Abstract Storage Interface.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

@dataclass
class StorageConfig:
    """Storage configuration."""
    path: str = ""
    compression: bool = True
    sync_writes: bool = False
    max_size_mb: int = 1000

class StorageBackend(ABC):
    """Abstract storage backend."""

    def __init__(self, config: StorageConfig = None):
        self.config = config or StorageConfig()

    @abstractmethod
    def write(self, key: str, data: bytes) -> bool:
        pass

    @abstractmethod
    def read(self, key: str) -> Optional[bytes]:
        pass

    @abstractmethod
    def delete(self, key: str) -> bool:
        pass

    @abstractmethod
    def exists(self, key: str) -> bool:
        pass

    @abstractmethod
    def list_keys(self, prefix: str = "") -> List[str]:
        pass

    def close(self) -> None:
        pass

__all__ = ["StorageBackend", "StorageConfig"]

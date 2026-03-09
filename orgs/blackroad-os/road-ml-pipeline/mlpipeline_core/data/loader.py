"""RoadML DataLoader - Data Loading Utilities.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Iterator, List, Optional

logger = logging.getLogger(__name__)


@dataclass
class BatchConfig:
    """Batch loading configuration."""

    batch_size: int = 32
    shuffle: bool = False
    drop_last: bool = False
    num_workers: int = 0
    prefetch: int = 2


class DataLoader(ABC):
    """Abstract data loader."""

    @abstractmethod
    def __iter__(self) -> Iterator:
        pass

    @abstractmethod
    def __len__(self) -> int:
        pass


class BatchLoader(DataLoader):
    """Batch data loader with shuffling and prefetch."""

    def __init__(
        self,
        data: Any,
        config: Optional[BatchConfig] = None,
    ):
        self.data = data
        self.config = config or BatchConfig()
        self._indices: List[int] = list(range(len(data)))

    def __iter__(self) -> Iterator:
        if self.config.shuffle:
            import random
            random.shuffle(self._indices)

        batch_size = self.config.batch_size

        for i in range(0, len(self._indices), batch_size):
            batch_indices = self._indices[i:i + batch_size]

            if len(batch_indices) < batch_size and self.config.drop_last:
                break

            yield [self.data[j] for j in batch_indices]

    def __len__(self) -> int:
        n_batches = len(self._indices) // self.config.batch_size
        if not self.config.drop_last and len(self._indices) % self.config.batch_size:
            n_batches += 1
        return n_batches


__all__ = ["DataLoader", "BatchLoader", "BatchConfig"]

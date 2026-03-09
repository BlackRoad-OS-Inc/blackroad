"""RoadSearch Embeddings - Text to Vector Conversion.

Manages embedding models and text-to-vector conversion for
semantic search capabilities.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import logging
import threading
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)


class PoolingStrategy(Enum):
    """Pooling strategies for token embeddings."""

    MEAN = "mean"  # Average of all token embeddings
    CLS = "cls"  # First token (CLS) embedding
    MAX = "max"  # Max pooling
    LAST = "last"  # Last token embedding


@dataclass
class EmbeddingConfig:
    """Configuration for embedding model.

    Attributes:
        model_id: Model identifier
        dimensions: Output embedding dimensions
        max_tokens: Maximum input tokens
        pooling: Pooling strategy
        normalize: L2 normalize output
        truncation: Truncate long inputs
        batch_size: Batch processing size
    """

    model_id: str = "default"
    dimensions: int = 768
    max_tokens: int = 512
    pooling: PoolingStrategy = PoolingStrategy.MEAN
    normalize: bool = True
    truncation: bool = True
    batch_size: int = 32


class EmbeddingModel(ABC):
    """Abstract base class for embedding models.

    Provides interface for converting text to vector embeddings.
    """

    def __init__(self, config: EmbeddingConfig):
        """Initialize model.

        Args:
            config: Model configuration
        """
        self.config = config
        self._initialized = False
        self._lock = threading.Lock()

    @abstractmethod
    def load(self) -> None:
        """Load model weights."""
        pass

    @abstractmethod
    def embed(self, texts: List[str]) -> List[List[float]]:
        """Embed texts to vectors.

        Args:
            texts: Input texts

        Returns:
            List of embedding vectors
        """
        pass

    def embed_single(self, text: str) -> List[float]:
        """Embed single text.

        Args:
            text: Input text

        Returns:
            Embedding vector
        """
        results = self.embed([text])
        return results[0] if results else []

    def _normalize(self, vector: List[float]) -> List[float]:
        """L2 normalize vector."""
        import math
        norm = math.sqrt(sum(x * x for x in vector))
        if norm == 0:
            return vector
        return [x / norm for x in vector]


class SimpleEmbeddingModel(EmbeddingModel):
    """Simple bag-of-words based embedding model.

    Uses word hashing for fast, deterministic embeddings.
    """

    def __init__(
        self,
        config: Optional[EmbeddingConfig] = None,
    ):
        """Initialize simple model."""
        config = config or EmbeddingConfig(dimensions=128)
        super().__init__(config)

    def load(self) -> None:
        """No loading needed for simple model."""
        self._initialized = True

    def embed(self, texts: List[str]) -> List[List[float]]:
        """Embed using word hashing."""
        results = []

        for text in texts:
            # Tokenize
            words = text.lower().split()

            # Initialize vector
            vector = [0.0] * self.config.dimensions

            # Hash each word and accumulate
            for word in words:
                word_hash = hashlib.md5(word.encode()).digest()
                for i in range(self.config.dimensions):
                    byte_idx = i % len(word_hash)
                    vector[i] += (word_hash[byte_idx] - 128) / 128.0

            # Average and normalize
            if words:
                vector = [v / len(words) for v in vector]

            if self.config.normalize:
                vector = self._normalize(vector)

            results.append(vector)

        return results


class RandomEmbeddingModel(EmbeddingModel):
    """Random projection embedding model.

    Uses random projection for dimension reduction.
    Useful for testing and baseline comparison.
    """

    def __init__(
        self,
        config: Optional[EmbeddingConfig] = None,
        seed: int = 42,
    ):
        """Initialize random model."""
        config = config or EmbeddingConfig()
        super().__init__(config)
        self.seed = seed
        self._projection: Optional[List[List[float]]] = None

    def load(self) -> None:
        """Generate random projection matrix."""
        import random
        random.seed(self.seed)

        vocab_size = 10000  # Assumed vocabulary size
        self._projection = [
            [random.gauss(0, 1) / (self.config.dimensions ** 0.5)
             for _ in range(self.config.dimensions)]
            for _ in range(vocab_size)
        ]
        self._initialized = True

    def embed(self, texts: List[str]) -> List[List[float]]:
        """Embed using random projection."""
        if not self._initialized:
            self.load()

        results = []

        for text in texts:
            words = text.lower().split()
            vector = [0.0] * self.config.dimensions

            for word in words:
                word_idx = hash(word) % len(self._projection)
                word_vec = self._projection[word_idx]
                for i in range(self.config.dimensions):
                    vector[i] += word_vec[i]

            if words:
                vector = [v / len(words) for v in vector]

            if self.config.normalize:
                vector = self._normalize(vector)

            results.append(vector)

        return results


class TFIDFEmbeddingModel(EmbeddingModel):
    """TF-IDF weighted embedding model.

    Weights word contributions by TF-IDF importance.
    """

    def __init__(
        self,
        config: Optional[EmbeddingConfig] = None,
    ):
        """Initialize TF-IDF model."""
        config = config or EmbeddingConfig(dimensions=256)
        super().__init__(config)
        self._word_vectors: Dict[str, List[float]] = {}
        self._idf: Dict[str, float] = {}
        self._doc_count = 0

    def load(self) -> None:
        """Initialize empty model."""
        self._initialized = True

    def fit(self, texts: List[str]) -> None:
        """Fit IDF weights from corpus.

        Args:
            texts: Training corpus
        """
        word_doc_freq: Dict[str, int] = {}
        self._doc_count = len(texts)

        for text in texts:
            words = set(text.lower().split())
            for word in words:
                word_doc_freq[word] = word_doc_freq.get(word, 0) + 1

        # Calculate IDF
        import math
        for word, df in word_doc_freq.items():
            self._idf[word] = math.log(self._doc_count / (1 + df))

    def embed(self, texts: List[str]) -> List[List[float]]:
        """Embed using TF-IDF weighting."""
        results = []

        for text in texts:
            words = text.lower().split()
            word_counts: Dict[str, int] = {}
            for word in words:
                word_counts[word] = word_counts.get(word, 0) + 1

            vector = [0.0] * self.config.dimensions

            for word, count in word_counts.items():
                # TF
                tf = count / len(words) if words else 0

                # IDF
                idf = self._idf.get(word, 1.0)

                # Weight
                weight = tf * idf

                # Word vector (using hash)
                word_hash = hashlib.md5(word.encode()).digest()
                for i in range(self.config.dimensions):
                    byte_idx = i % len(word_hash)
                    vector[i] += weight * (word_hash[byte_idx] - 128) / 128.0

            if self.config.normalize:
                vector = self._normalize(vector)

            results.append(vector)

        return results


class Embedder:
    """High-level embedder interface.

    Manages embedding models and provides caching.
    """

    def __init__(
        self,
        model: Optional[EmbeddingModel] = None,
        cache_size: int = 10000,
    ):
        """Initialize embedder.

        Args:
            model: Embedding model
            cache_size: Cache size
        """
        self.model = model or SimpleEmbeddingModel()
        self._cache: Dict[str, List[float]] = {}
        self._cache_size = cache_size
        self._lock = threading.Lock()

        # Ensure model is loaded
        if not self.model._initialized:
            self.model.load()

    def embed(self, text: str) -> List[float]:
        """Embed single text with caching.

        Args:
            text: Input text

        Returns:
            Embedding vector
        """
        cache_key = hashlib.md5(text.encode()).hexdigest()

        with self._lock:
            if cache_key in self._cache:
                return self._cache[cache_key]

        vector = self.model.embed_single(text)

        with self._lock:
            if len(self._cache) >= self._cache_size:
                # Evict oldest (simple FIFO)
                oldest = next(iter(self._cache))
                del self._cache[oldest]
            self._cache[cache_key] = vector

        return vector

    def embed_batch(
        self,
        texts: List[str],
        show_progress: bool = False,
    ) -> List[List[float]]:
        """Embed batch of texts.

        Args:
            texts: Input texts
            show_progress: Show progress indicator

        Returns:
            List of embedding vectors
        """
        results = []
        batch_size = self.model.config.batch_size

        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            batch_results = self.model.embed(batch)
            results.extend(batch_results)

        return results

    def similarity(self, text1: str, text2: str) -> float:
        """Calculate cosine similarity between texts.

        Args:
            text1: First text
            text2: Second text

        Returns:
            Similarity score
        """
        vec1 = self.embed(text1)
        vec2 = self.embed(text2)

        dot = sum(a * b for a, b in zip(vec1, vec2))
        norm1 = sum(a * a for a in vec1) ** 0.5
        norm2 = sum(b * b for b in vec2) ** 0.5

        if norm1 == 0 or norm2 == 0:
            return 0.0

        return dot / (norm1 * norm2)

    @property
    def dimensions(self) -> int:
        """Get embedding dimensions."""
        return self.model.config.dimensions

    def clear_cache(self) -> None:
        """Clear embedding cache."""
        with self._lock:
            self._cache.clear()

    def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        with self._lock:
            return {
                "entries": len(self._cache),
                "max_size": self._cache_size,
            }


class EmbeddingRegistry:
    """Registry of available embedding models."""

    _models: Dict[str, type] = {}

    @classmethod
    def register(cls, name: str) -> Callable:
        """Register an embedding model.

        Args:
            name: Model name

        Returns:
            Decorator function
        """
        def decorator(model_cls: type) -> type:
            cls._models[name] = model_cls
            return model_cls
        return decorator

    @classmethod
    def get(cls, name: str) -> Optional[type]:
        """Get model class by name.

        Args:
            name: Model name

        Returns:
            Model class or None
        """
        return cls._models.get(name)

    @classmethod
    def list_models(cls) -> List[str]:
        """List available models."""
        return list(cls._models.keys())

    @classmethod
    def create(
        cls,
        name: str,
        config: Optional[EmbeddingConfig] = None,
    ) -> Optional[EmbeddingModel]:
        """Create model instance.

        Args:
            name: Model name
            config: Model configuration

        Returns:
            Model instance or None
        """
        model_cls = cls._models.get(name)
        if model_cls:
            return model_cls(config)
        return None


# Register built-in models
EmbeddingRegistry._models = {
    "simple": SimpleEmbeddingModel,
    "random": RandomEmbeddingModel,
    "tfidf": TFIDFEmbeddingModel,
}


__all__ = [
    "Embedder",
    "EmbeddingModel",
    "EmbeddingConfig",
    "EmbeddingRegistry",
    "SimpleEmbeddingModel",
    "RandomEmbeddingModel",
    "TFIDFEmbeddingModel",
    "PoolingStrategy",
]

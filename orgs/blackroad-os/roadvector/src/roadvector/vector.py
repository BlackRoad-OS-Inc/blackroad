"""
RoadVector - Vector Operations for BlackRoad
Vector math and embedding operations.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Tuple, Union
import math
import logging

logger = logging.getLogger(__name__)


@dataclass
class Vector:
    values: List[float]
    metadata: Dict[str, Any] = field(default_factory=dict)

    def __len__(self) -> int:
        return len(self.values)

    def __getitem__(self, index: int) -> float:
        return self.values[index]

    def __add__(self, other: "Vector") -> "Vector":
        if len(self) != len(other):
            raise ValueError("Vector dimensions must match")
        return Vector([a + b for a, b in zip(self.values, other.values)])

    def __sub__(self, other: "Vector") -> "Vector":
        if len(self) != len(other):
            raise ValueError("Vector dimensions must match")
        return Vector([a - b for a, b in zip(self.values, other.values)])

    def __mul__(self, scalar: float) -> "Vector":
        return Vector([v * scalar for v in self.values])

    def __truediv__(self, scalar: float) -> "Vector":
        return Vector([v / scalar for v in self.values])

    def dot(self, other: "Vector") -> float:
        if len(self) != len(other):
            raise ValueError("Vector dimensions must match")
        return sum(a * b for a, b in zip(self.values, other.values))

    def magnitude(self) -> float:
        return math.sqrt(sum(v * v for v in self.values))

    def normalize(self) -> "Vector":
        mag = self.magnitude()
        if mag == 0:
            return Vector([0.0] * len(self))
        return self / mag

    def cosine_similarity(self, other: "Vector") -> float:
        mag_self = self.magnitude()
        mag_other = other.magnitude()
        if mag_self == 0 or mag_other == 0:
            return 0.0
        return self.dot(other) / (mag_self * mag_other)

    def euclidean_distance(self, other: "Vector") -> float:
        if len(self) != len(other):
            raise ValueError("Vector dimensions must match")
        return math.sqrt(sum((a - b) ** 2 for a, b in zip(self.values, other.values)))

    def manhattan_distance(self, other: "Vector") -> float:
        if len(self) != len(other):
            raise ValueError("Vector dimensions must match")
        return sum(abs(a - b) for a, b in zip(self.values, other.values))

    def to_list(self) -> List[float]:
        return self.values.copy()

    @staticmethod
    def zeros(dim: int) -> "Vector":
        return Vector([0.0] * dim)

    @staticmethod
    def ones(dim: int) -> "Vector":
        return Vector([1.0] * dim)

    @staticmethod
    def random(dim: int, min_val: float = -1.0, max_val: float = 1.0) -> "Vector":
        import random
        return Vector([random.uniform(min_val, max_val) for _ in range(dim)])


class Matrix:
    def __init__(self, rows: List[List[float]]):
        self.rows = rows
        self.num_rows = len(rows)
        self.num_cols = len(rows[0]) if rows else 0

    def __getitem__(self, index: Tuple[int, int]) -> float:
        row, col = index
        return self.rows[row][col]

    def __mul__(self, other: Union["Matrix", Vector]) -> Union["Matrix", Vector]:
        if isinstance(other, Vector):
            if self.num_cols != len(other):
                raise ValueError("Matrix columns must match vector dimension")
            result = []
            for row in self.rows:
                result.append(sum(r * v for r, v in zip(row, other.values)))
            return Vector(result)
        else:
            if self.num_cols != other.num_rows:
                raise ValueError("Matrix dimensions incompatible")
            result = []
            for i in range(self.num_rows):
                row = []
                for j in range(other.num_cols):
                    val = sum(self.rows[i][k] * other.rows[k][j] for k in range(self.num_cols))
                    row.append(val)
                result.append(row)
            return Matrix(result)

    def transpose(self) -> "Matrix":
        return Matrix([[self.rows[i][j] for i in range(self.num_rows)] for j in range(self.num_cols)])

    @staticmethod
    def identity(n: int) -> "Matrix":
        return Matrix([[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)])


@dataclass
class VectorMatch:
    id: str
    vector: Vector
    score: float
    metadata: Dict[str, Any] = field(default_factory=dict)


class VectorStore:
    def __init__(self, dimension: int):
        self.dimension = dimension
        self.vectors: Dict[str, Vector] = {}

    def add(self, id: str, vector: Vector, metadata: Dict[str, Any] = None) -> None:
        if len(vector) != self.dimension:
            raise ValueError(f"Vector dimension must be {self.dimension}")
        vector.metadata = metadata or {}
        self.vectors[id] = vector

    def get(self, id: str) -> Optional[Vector]:
        return self.vectors.get(id)

    def delete(self, id: str) -> bool:
        if id in self.vectors:
            del self.vectors[id]
            return True
        return False

    def search(self, query: Vector, k: int = 10, metric: str = "cosine") -> List[VectorMatch]:
        if len(query) != self.dimension:
            raise ValueError(f"Query dimension must be {self.dimension}")
        
        results = []
        for id, vector in self.vectors.items():
            if metric == "cosine":
                score = query.cosine_similarity(vector)
            elif metric == "euclidean":
                score = -query.euclidean_distance(vector)
            else:
                score = -query.manhattan_distance(vector)
            
            results.append(VectorMatch(id=id, vector=vector, score=score, metadata=vector.metadata))
        
        results.sort(key=lambda x: x.score, reverse=True)
        return results[:k]

    def count(self) -> int:
        return len(self.vectors)


class Embedding:
    def __init__(self, dimension: int = 128):
        self.dimension = dimension

    def encode(self, text: str) -> Vector:
        import hashlib
        hash_bytes = hashlib.sha256(text.encode()).digest()
        values = []
        for i in range(self.dimension):
            byte_idx = i % len(hash_bytes)
            values.append((hash_bytes[byte_idx] / 255.0) * 2 - 1)
        return Vector(values)

    def encode_batch(self, texts: List[str]) -> List[Vector]:
        return [self.encode(text) for text in texts]


def example_usage():
    v1 = Vector([1.0, 2.0, 3.0])
    v2 = Vector([4.0, 5.0, 6.0])
    
    print(f"v1: {v1.values}")
    print(f"v2: {v2.values}")
    print(f"v1 + v2: {(v1 + v2).values}")
    print(f"v1 . v2: {v1.dot(v2)}")
    print(f"v1 magnitude: {v1.magnitude():.4f}")
    print(f"v1 normalized: {[round(x, 4) for x in v1.normalize().values]}")
    print(f"Cosine similarity: {v1.cosine_similarity(v2):.4f}")
    print(f"Euclidean distance: {v1.euclidean_distance(v2):.4f}")
    
    store = VectorStore(dimension=3)
    store.add("doc1", Vector([1.0, 0.0, 0.0]), {"title": "Document 1"})
    store.add("doc2", Vector([0.9, 0.1, 0.0]), {"title": "Document 2"})
    store.add("doc3", Vector([0.0, 1.0, 0.0]), {"title": "Document 3"})
    
    query = Vector([0.95, 0.05, 0.0])
    results = store.search(query, k=2)
    print(f"\nSearch results:")
    for match in results:
        print(f"  {match.id}: score={match.score:.4f}")
    
    embedding = Embedding(dimension=8)
    e1 = embedding.encode("Hello world")
    e2 = embedding.encode("Hello there")
    print(f"\nEmbedding similarity: {e1.cosine_similarity(e2):.4f}")


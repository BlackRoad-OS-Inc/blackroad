"""
RoadIndex - Index Structures for BlackRoad
B-tree, hash index, and inverted index implementations.
"""

from dataclasses import dataclass, field
from typing import Any, Dict, Generic, List, Optional, Set, Tuple, TypeVar
import hashlib
import logging

logger = logging.getLogger(__name__)

K = TypeVar('K')
V = TypeVar('V')


class HashIndex(Generic[K, V]):
    def __init__(self, bucket_count: int = 256):
        self.bucket_count = bucket_count
        self.buckets: List[List[Tuple[K, V]]] = [[] for _ in range(bucket_count)]
        self._size = 0

    def _hash(self, key: K) -> int:
        if isinstance(key, str):
            h = hashlib.md5(key.encode()).hexdigest()
            return int(h, 16) % self.bucket_count
        return hash(key) % self.bucket_count

    def put(self, key: K, value: V) -> None:
        bucket_idx = self._hash(key)
        bucket = self.buckets[bucket_idx]
        
        for i, (k, v) in enumerate(bucket):
            if k == key:
                bucket[i] = (key, value)
                return
        
        bucket.append((key, value))
        self._size += 1

    def get(self, key: K) -> Optional[V]:
        bucket_idx = self._hash(key)
        for k, v in self.buckets[bucket_idx]:
            if k == key:
                return v
        return None

    def delete(self, key: K) -> bool:
        bucket_idx = self._hash(key)
        bucket = self.buckets[bucket_idx]
        
        for i, (k, v) in enumerate(bucket):
            if k == key:
                bucket.pop(i)
                self._size -= 1
                return True
        return False

    def contains(self, key: K) -> bool:
        return self.get(key) is not None

    def size(self) -> int:
        return self._size

    def keys(self) -> List[K]:
        return [k for bucket in self.buckets for k, v in bucket]


@dataclass
class BTreeNode(Generic[K, V]):
    keys: List[K] = field(default_factory=list)
    values: List[V] = field(default_factory=list)
    children: List["BTreeNode[K, V]"] = field(default_factory=list)
    is_leaf: bool = True


class BTree(Generic[K, V]):
    def __init__(self, order: int = 4):
        self.order = order
        self.root = BTreeNode[K, V]()
        self._size = 0

    def search(self, key: K) -> Optional[V]:
        return self._search(self.root, key)

    def _search(self, node: BTreeNode[K, V], key: K) -> Optional[V]:
        i = 0
        while i < len(node.keys) and key > node.keys[i]:
            i += 1
        
        if i < len(node.keys) and key == node.keys[i]:
            return node.values[i]
        
        if node.is_leaf:
            return None
        
        return self._search(node.children[i], key)

    def insert(self, key: K, value: V) -> None:
        root = self.root
        if len(root.keys) == self.order - 1:
            new_root = BTreeNode[K, V](is_leaf=False)
            new_root.children.append(self.root)
            self._split_child(new_root, 0)
            self.root = new_root
        self._insert_non_full(self.root, key, value)
        self._size += 1

    def _insert_non_full(self, node: BTreeNode[K, V], key: K, value: V) -> None:
        i = len(node.keys) - 1
        
        if node.is_leaf:
            while i >= 0 and key < node.keys[i]:
                i -= 1
            node.keys.insert(i + 1, key)
            node.values.insert(i + 1, value)
        else:
            while i >= 0 and key < node.keys[i]:
                i -= 1
            i += 1
            
            if len(node.children[i].keys) == self.order - 1:
                self._split_child(node, i)
                if key > node.keys[i]:
                    i += 1
            
            self._insert_non_full(node.children[i], key, value)

    def _split_child(self, parent: BTreeNode[K, V], i: int) -> None:
        order = self.order
        child = parent.children[i]
        mid = order // 2 - 1
        
        new_node = BTreeNode[K, V](is_leaf=child.is_leaf)
        new_node.keys = child.keys[mid + 1:]
        new_node.values = child.values[mid + 1:]
        
        if not child.is_leaf:
            new_node.children = child.children[mid + 1:]
        
        parent.keys.insert(i, child.keys[mid])
        parent.values.insert(i, child.values[mid])
        parent.children.insert(i + 1, new_node)
        
        child.keys = child.keys[:mid]
        child.values = child.values[:mid]
        if not child.is_leaf:
            child.children = child.children[:mid + 1]

    def size(self) -> int:
        return self._size


@dataclass
class PostingList:
    term: str
    doc_ids: Set[str] = field(default_factory=set)
    positions: Dict[str, List[int]] = field(default_factory=dict)


class InvertedIndex:
    def __init__(self):
        self.index: Dict[str, PostingList] = {}
        self.doc_count = 0

    def index_document(self, doc_id: str, text: str) -> None:
        tokens = self._tokenize(text)
        
        for pos, token in enumerate(tokens):
            if token not in self.index:
                self.index[token] = PostingList(term=token)
            
            posting = self.index[token]
            posting.doc_ids.add(doc_id)
            
            if doc_id not in posting.positions:
                posting.positions[doc_id] = []
            posting.positions[doc_id].append(pos)
        
        self.doc_count += 1

    def _tokenize(self, text: str) -> List[str]:
        import re
        tokens = re.findall(r'\w+', text.lower())
        return [t for t in tokens if len(t) >= 2]

    def search(self, query: str) -> Set[str]:
        terms = self._tokenize(query)
        if not terms:
            return set()
        
        result = None
        for term in terms:
            posting = self.index.get(term)
            if posting is None:
                return set()
            if result is None:
                result = posting.doc_ids.copy()
            else:
                result &= posting.doc_ids
        
        return result or set()

    def search_or(self, query: str) -> Set[str]:
        terms = self._tokenize(query)
        result = set()
        for term in terms:
            posting = self.index.get(term)
            if posting:
                result |= posting.doc_ids
        return result

    def get_positions(self, term: str, doc_id: str) -> List[int]:
        posting = self.index.get(term)
        if posting and doc_id in posting.positions:
            return posting.positions[doc_id]
        return []

    def term_frequency(self, term: str) -> int:
        posting = self.index.get(term)
        return len(posting.doc_ids) if posting else 0

    def document_frequency(self, term: str, doc_id: str) -> int:
        return len(self.get_positions(term, doc_id))

    def terms(self) -> List[str]:
        return list(self.index.keys())


class SortedIndex(Generic[K, V]):
    def __init__(self):
        self.data: List[Tuple[K, V]] = []

    def insert(self, key: K, value: V) -> None:
        idx = self._binary_search_insert(key)
        self.data.insert(idx, (key, value))

    def _binary_search_insert(self, key: K) -> int:
        lo, hi = 0, len(self.data)
        while lo < hi:
            mid = (lo + hi) // 2
            if self.data[mid][0] < key:
                lo = mid + 1
            else:
                hi = mid
        return lo

    def search(self, key: K) -> Optional[V]:
        idx = self._binary_search(key)
        if idx is not None:
            return self.data[idx][1]
        return None

    def _binary_search(self, key: K) -> Optional[int]:
        lo, hi = 0, len(self.data) - 1
        while lo <= hi:
            mid = (lo + hi) // 2
            if self.data[mid][0] == key:
                return mid
            elif self.data[mid][0] < key:
                lo = mid + 1
            else:
                hi = mid - 1
        return None

    def range_query(self, start: K, end: K) -> List[Tuple[K, V]]:
        result = []
        for k, v in self.data:
            if start <= k <= end:
                result.append((k, v))
            elif k > end:
                break
        return result

    def size(self) -> int:
        return len(self.data)


def example_usage():
    hash_idx = HashIndex[str, int]()
    hash_idx.put("apple", 1)
    hash_idx.put("banana", 2)
    hash_idx.put("cherry", 3)
    print(f"Hash index: apple={hash_idx.get('apple')}, size={hash_idx.size()}")
    
    btree = BTree[int, str](order=4)
    for i in [10, 5, 15, 3, 7, 12, 20]:
        btree.insert(i, f"value-{i}")
    print(f"B-tree: search(7)={btree.search(7)}, size={btree.size()}")
    
    inv_idx = InvertedIndex()
    inv_idx.index_document("doc1", "The quick brown fox jumps over the lazy dog")
    inv_idx.index_document("doc2", "A quick brown dog runs in the park")
    inv_idx.index_document("doc3", "The lazy cat sleeps all day")
    
    print(f"\nInverted index:")
    print(f"  'quick brown': {inv_idx.search('quick brown')}")
    print(f"  'quick OR cat': {inv_idx.search_or('quick cat')}")
    print(f"  'lazy' positions in doc1: {inv_idx.get_positions('lazy', 'doc1')}")
    
    sorted_idx = SortedIndex[int, str]()
    for i in [5, 2, 8, 1, 9, 3]:
        sorted_idx.insert(i, f"val-{i}")
    print(f"\nSorted index range [2,5]: {sorted_idx.range_query(2, 5)}")


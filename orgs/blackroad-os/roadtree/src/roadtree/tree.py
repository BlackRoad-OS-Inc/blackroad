"""
RoadTree - Tree Data Structures for BlackRoad
Binary trees, tries, and tree operations.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, Generator, Generic, List, Optional, TypeVar
import logging

logger = logging.getLogger(__name__)

T = TypeVar('T')


@dataclass
class TreeNode(Generic[T]):
    value: T
    children: List["TreeNode[T]"] = field(default_factory=list)
    parent: Optional["TreeNode[T]"] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def add_child(self, value: T) -> "TreeNode[T]":
        child = TreeNode(value=value, parent=self)
        self.children.append(child)
        return child

    def remove_child(self, child: "TreeNode[T]") -> bool:
        if child in self.children:
            self.children.remove(child)
            child.parent = None
            return True
        return False

    def is_leaf(self) -> bool:
        return len(self.children) == 0

    def is_root(self) -> bool:
        return self.parent is None

    def depth(self) -> int:
        depth = 0
        node = self
        while node.parent is not None:
            depth += 1
            node = node.parent
        return depth

    def path_to_root(self) -> List["TreeNode[T]"]:
        path = []
        node = self
        while node is not None:
            path.append(node)
            node = node.parent
        return path


@dataclass
class BinaryNode(Generic[T]):
    value: T
    left: Optional["BinaryNode[T]"] = None
    right: Optional["BinaryNode[T]"] = None
    parent: Optional["BinaryNode[T]"] = None


class BinarySearchTree(Generic[T]):
    def __init__(self):
        self.root: Optional[BinaryNode[T]] = None
        self._size = 0

    def insert(self, value: T) -> BinaryNode[T]:
        node = BinaryNode(value=value)
        
        if self.root is None:
            self.root = node
        else:
            self._insert_recursive(self.root, node)
        
        self._size += 1
        return node

    def _insert_recursive(self, current: BinaryNode[T], node: BinaryNode[T]) -> None:
        if node.value < current.value:
            if current.left is None:
                current.left = node
                node.parent = current
            else:
                self._insert_recursive(current.left, node)
        else:
            if current.right is None:
                current.right = node
                node.parent = current
            else:
                self._insert_recursive(current.right, node)

    def search(self, value: T) -> Optional[BinaryNode[T]]:
        return self._search_recursive(self.root, value)

    def _search_recursive(self, node: Optional[BinaryNode[T]], value: T) -> Optional[BinaryNode[T]]:
        if node is None or node.value == value:
            return node
        if value < node.value:
            return self._search_recursive(node.left, value)
        return self._search_recursive(node.right, value)

    def delete(self, value: T) -> bool:
        node = self.search(value)
        if node is None:
            return False
        self._delete_node(node)
        self._size -= 1
        return True

    def _delete_node(self, node: BinaryNode[T]) -> None:
        if node.left is None and node.right is None:
            self._replace_node(node, None)
        elif node.left is None:
            self._replace_node(node, node.right)
        elif node.right is None:
            self._replace_node(node, node.left)
        else:
            successor = self._min_node(node.right)
            node.value = successor.value
            self._delete_node(successor)

    def _replace_node(self, node: BinaryNode[T], replacement: Optional[BinaryNode[T]]) -> None:
        if node.parent is None:
            self.root = replacement
        elif node == node.parent.left:
            node.parent.left = replacement
        else:
            node.parent.right = replacement
        if replacement:
            replacement.parent = node.parent

    def _min_node(self, node: BinaryNode[T]) -> BinaryNode[T]:
        while node.left:
            node = node.left
        return node

    def inorder(self) -> Generator[T, None, None]:
        yield from self._inorder_recursive(self.root)

    def _inorder_recursive(self, node: Optional[BinaryNode[T]]) -> Generator[T, None, None]:
        if node:
            yield from self._inorder_recursive(node.left)
            yield node.value
            yield from self._inorder_recursive(node.right)

    def preorder(self) -> Generator[T, None, None]:
        yield from self._preorder_recursive(self.root)

    def _preorder_recursive(self, node: Optional[BinaryNode[T]]) -> Generator[T, None, None]:
        if node:
            yield node.value
            yield from self._preorder_recursive(node.left)
            yield from self._preorder_recursive(node.right)

    def postorder(self) -> Generator[T, None, None]:
        yield from self._postorder_recursive(self.root)

    def _postorder_recursive(self, node: Optional[BinaryNode[T]]) -> Generator[T, None, None]:
        if node:
            yield from self._postorder_recursive(node.left)
            yield from self._postorder_recursive(node.right)
            yield node.value

    def height(self) -> int:
        return self._height_recursive(self.root)

    def _height_recursive(self, node: Optional[BinaryNode[T]]) -> int:
        if node is None:
            return 0
        return 1 + max(self._height_recursive(node.left), self._height_recursive(node.right))

    def size(self) -> int:
        return self._size

    def min(self) -> Optional[T]:
        if self.root is None:
            return None
        return self._min_node(self.root).value

    def max(self) -> Optional[T]:
        if self.root is None:
            return None
        node = self.root
        while node.right:
            node = node.right
        return node.value


class TrieNode:
    def __init__(self):
        self.children: Dict[str, "TrieNode"] = {}
        self.is_end: bool = False
        self.value: Any = None


class Trie:
    def __init__(self):
        self.root = TrieNode()
        self._size = 0

    def insert(self, key: str, value: Any = None) -> None:
        node = self.root
        for char in key:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        if not node.is_end:
            self._size += 1
        node.is_end = True
        node.value = value

    def search(self, key: str) -> Optional[Any]:
        node = self._find_node(key)
        if node and node.is_end:
            return node.value
        return None

    def starts_with(self, prefix: str) -> List[str]:
        node = self._find_node(prefix)
        if node is None:
            return []
        results = []
        self._collect_words(node, prefix, results)
        return results

    def _find_node(self, key: str) -> Optional[TrieNode]:
        node = self.root
        for char in key:
            if char not in node.children:
                return None
            node = node.children[char]
        return node

    def _collect_words(self, node: TrieNode, prefix: str, results: List[str]) -> None:
        if node.is_end:
            results.append(prefix)
        for char, child in node.children.items():
            self._collect_words(child, prefix + char, results)

    def delete(self, key: str) -> bool:
        return self._delete_recursive(self.root, key, 0)

    def _delete_recursive(self, node: TrieNode, key: str, depth: int) -> bool:
        if depth == len(key):
            if not node.is_end:
                return False
            node.is_end = False
            self._size -= 1
            return len(node.children) == 0
        
        char = key[depth]
        if char not in node.children:
            return False
        
        should_delete = self._delete_recursive(node.children[char], key, depth + 1)
        
        if should_delete:
            del node.children[char]
            return len(node.children) == 0 and not node.is_end
        return False

    def size(self) -> int:
        return self._size


def example_usage():
    bst = BinarySearchTree[int]()
    for val in [5, 3, 7, 1, 4, 6, 8]:
        bst.insert(val)
    
    print(f"BST Inorder: {list(bst.inorder())}")
    print(f"BST Preorder: {list(bst.preorder())}")
    print(f"BST Height: {bst.height()}")
    print(f"BST Min: {bst.min()}, Max: {bst.max()}")
    print(f"Search 4: {bst.search(4) is not None}")
    
    bst.delete(3)
    print(f"After delete 3: {list(bst.inorder())}")
    
    trie = Trie()
    words = ["apple", "app", "application", "banana", "band", "bandana"]
    for word in words:
        trie.insert(word, len(word))
    
    print(f"\nTrie size: {trie.size()}")
    print(f"Search 'app': {trie.search('app')}")
    print(f"Starts with 'app': {trie.starts_with('app')}")
    print(f"Starts with 'ban': {trie.starts_with('ban')}")
    
    root = TreeNode("root")
    child1 = root.add_child("child1")
    child2 = root.add_child("child2")
    child1.add_child("grandchild1")
    child1.add_child("grandchild2")
    
    print(f"\nTree root children: {len(root.children)}")
    print(f"child1 depth: {child1.depth()}")


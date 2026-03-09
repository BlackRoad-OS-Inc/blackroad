"""
RoadGraph - Graph Database for BlackRoad
Graph data structures, traversals, and relationship queries.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, Generator, List, Optional, Set, Tuple
import heapq
import json
import logging
import threading
import uuid

logger = logging.getLogger(__name__)


class NodeType(str, Enum):
    """Common node types."""
    USER = "user"
    ORGANIZATION = "organization"
    RESOURCE = "resource"
    EVENT = "event"
    CUSTOM = "custom"


class EdgeDirection(str, Enum):
    """Edge direction."""
    OUTGOING = "outgoing"
    INCOMING = "incoming"
    BOTH = "both"


@dataclass
class Node:
    """A graph node."""
    id: str
    node_type: str
    properties: Dict[str, Any] = field(default_factory=dict)
    labels: Set[str] = field(default_factory=set)
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "type": self.node_type,
            "properties": self.properties,
            "labels": list(self.labels),
            "created_at": self.created_at.isoformat()
        }


@dataclass
class Edge:
    """A graph edge."""
    id: str
    source_id: str
    target_id: str
    edge_type: str
    properties: Dict[str, Any] = field(default_factory=dict)
    weight: float = 1.0
    created_at: datetime = field(default_factory=datetime.now)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "source": self.source_id,
            "target": self.target_id,
            "type": self.edge_type,
            "properties": self.properties,
            "weight": self.weight
        }


@dataclass
class Path:
    """A path through the graph."""
    nodes: List[Node]
    edges: List[Edge]
    total_weight: float = 0

    def __len__(self) -> int:
        return len(self.nodes)


class GraphStore:
    """Graph storage engine."""

    def __init__(self):
        self.nodes: Dict[str, Node] = {}
        self.edges: Dict[str, Edge] = {}
        self.adjacency: Dict[str, Set[str]] = {}  # node_id -> edge_ids (outgoing)
        self.reverse_adjacency: Dict[str, Set[str]] = {}  # node_id -> edge_ids (incoming)
        self._lock = threading.Lock()

    def add_node(self, node: Node) -> None:
        with self._lock:
            self.nodes[node.id] = node
            if node.id not in self.adjacency:
                self.adjacency[node.id] = set()
            if node.id not in self.reverse_adjacency:
                self.reverse_adjacency[node.id] = set()

    def get_node(self, node_id: str) -> Optional[Node]:
        return self.nodes.get(node_id)

    def remove_node(self, node_id: str) -> bool:
        with self._lock:
            if node_id not in self.nodes:
                return False
            
            # Remove connected edges
            for edge_id in list(self.adjacency.get(node_id, set())):
                self._remove_edge(edge_id)
            for edge_id in list(self.reverse_adjacency.get(node_id, set())):
                self._remove_edge(edge_id)
            
            del self.nodes[node_id]
            self.adjacency.pop(node_id, None)
            self.reverse_adjacency.pop(node_id, None)
            return True

    def add_edge(self, edge: Edge) -> None:
        with self._lock:
            if edge.source_id not in self.nodes or edge.target_id not in self.nodes:
                raise ValueError("Source or target node not found")
            
            self.edges[edge.id] = edge
            self.adjacency[edge.source_id].add(edge.id)
            self.reverse_adjacency[edge.target_id].add(edge.id)

    def get_edge(self, edge_id: str) -> Optional[Edge]:
        return self.edges.get(edge_id)

    def _remove_edge(self, edge_id: str) -> bool:
        edge = self.edges.get(edge_id)
        if not edge:
            return False
        
        self.adjacency[edge.source_id].discard(edge_id)
        self.reverse_adjacency[edge.target_id].discard(edge_id)
        del self.edges[edge_id]
        return True

    def remove_edge(self, edge_id: str) -> bool:
        with self._lock:
            return self._remove_edge(edge_id)

    def get_neighbors(
        self,
        node_id: str,
        direction: EdgeDirection = EdgeDirection.OUTGOING,
        edge_type: Optional[str] = None
    ) -> List[Tuple[Node, Edge]]:
        """Get neighboring nodes."""
        results = []
        
        edge_ids = set()
        if direction in [EdgeDirection.OUTGOING, EdgeDirection.BOTH]:
            edge_ids.update(self.adjacency.get(node_id, set()))
        if direction in [EdgeDirection.INCOMING, EdgeDirection.BOTH]:
            edge_ids.update(self.reverse_adjacency.get(node_id, set()))

        for edge_id in edge_ids:
            edge = self.edges.get(edge_id)
            if edge and (edge_type is None or edge.edge_type == edge_type):
                neighbor_id = edge.target_id if edge.source_id == node_id else edge.source_id
                neighbor = self.nodes.get(neighbor_id)
                if neighbor:
                    results.append((neighbor, edge))

        return results

    def find_nodes(
        self,
        node_type: Optional[str] = None,
        labels: Optional[Set[str]] = None,
        properties: Optional[Dict[str, Any]] = None
    ) -> List[Node]:
        """Find nodes matching criteria."""
        results = []
        
        for node in self.nodes.values():
            if node_type and node.node_type != node_type:
                continue
            if labels and not labels.issubset(node.labels):
                continue
            if properties:
                match = all(node.properties.get(k) == v for k, v in properties.items())
                if not match:
                    continue
            results.append(node)
        
        return results


class GraphTraversal:
    """Graph traversal algorithms."""

    def __init__(self, store: GraphStore):
        self.store = store

    def bfs(
        self,
        start_id: str,
        max_depth: int = 10,
        direction: EdgeDirection = EdgeDirection.OUTGOING,
        edge_type: Optional[str] = None
    ) -> Generator[Tuple[Node, int], None, None]:
        """Breadth-first search."""
        visited = {start_id}
        queue = [(start_id, 0)]
        
        while queue:
            node_id, depth = queue.pop(0)
            node = self.store.get_node(node_id)
            
            if node:
                yield node, depth
                
                if depth < max_depth:
                    for neighbor, edge in self.store.get_neighbors(node_id, direction, edge_type):
                        if neighbor.id not in visited:
                            visited.add(neighbor.id)
                            queue.append((neighbor.id, depth + 1))

    def dfs(
        self,
        start_id: str,
        max_depth: int = 10,
        direction: EdgeDirection = EdgeDirection.OUTGOING,
        edge_type: Optional[str] = None
    ) -> Generator[Tuple[Node, int], None, None]:
        """Depth-first search."""
        visited = set()
        stack = [(start_id, 0)]
        
        while stack:
            node_id, depth = stack.pop()
            
            if node_id in visited:
                continue
            
            visited.add(node_id)
            node = self.store.get_node(node_id)
            
            if node:
                yield node, depth
                
                if depth < max_depth:
                    for neighbor, edge in self.store.get_neighbors(node_id, direction, edge_type):
                        if neighbor.id not in visited:
                            stack.append((neighbor.id, depth + 1))

    def shortest_path(
        self,
        start_id: str,
        end_id: str,
        direction: EdgeDirection = EdgeDirection.OUTGOING
    ) -> Optional[Path]:
        """Find shortest path using Dijkstra's algorithm."""
        distances = {start_id: 0}
        predecessors: Dict[str, Tuple[str, Edge]] = {}
        visited = set()
        heap = [(0, start_id)]
        
        while heap:
            dist, node_id = heapq.heappop(heap)
            
            if node_id in visited:
                continue
            
            visited.add(node_id)
            
            if node_id == end_id:
                return self._build_path(start_id, end_id, predecessors)
            
            for neighbor, edge in self.store.get_neighbors(node_id, direction):
                if neighbor.id in visited:
                    continue
                
                new_dist = dist + edge.weight
                
                if neighbor.id not in distances or new_dist < distances[neighbor.id]:
                    distances[neighbor.id] = new_dist
                    predecessors[neighbor.id] = (node_id, edge)
                    heapq.heappush(heap, (new_dist, neighbor.id))
        
        return None

    def _build_path(
        self,
        start_id: str,
        end_id: str,
        predecessors: Dict[str, Tuple[str, Edge]]
    ) -> Path:
        """Build path from predecessors."""
        nodes = []
        edges = []
        current = end_id
        total_weight = 0
        
        while current != start_id:
            nodes.append(self.store.get_node(current))
            if current in predecessors:
                prev_id, edge = predecessors[current]
                edges.append(edge)
                total_weight += edge.weight
                current = prev_id
            else:
                break
        
        nodes.append(self.store.get_node(start_id))
        nodes.reverse()
        edges.reverse()
        
        return Path(nodes=nodes, edges=edges, total_weight=total_weight)

    def find_all_paths(
        self,
        start_id: str,
        end_id: str,
        max_depth: int = 5
    ) -> List[Path]:
        """Find all paths between two nodes."""
        paths = []
        stack = [(start_id, [start_id], [], 0)]
        
        while stack:
            current, path_nodes, path_edges, weight = stack.pop()
            
            if current == end_id:
                nodes = [self.store.get_node(nid) for nid in path_nodes]
                paths.append(Path(nodes=nodes, edges=path_edges, total_weight=weight))
                continue
            
            if len(path_nodes) > max_depth:
                continue
            
            for neighbor, edge in self.store.get_neighbors(current):
                if neighbor.id not in path_nodes:
                    stack.append((
                        neighbor.id,
                        path_nodes + [neighbor.id],
                        path_edges + [edge],
                        weight + edge.weight
                    ))
        
        return paths


class GraphQuery:
    """Query builder for graphs."""

    def __init__(self, store: GraphStore):
        self.store = store
        self._results: List[Node] = []

    def match(self, node_type: Optional[str] = None, **properties) -> "GraphQuery":
        """Match nodes."""
        self._results = self.store.find_nodes(node_type=node_type, properties=properties)
        return self

    def where(self, predicate: Callable[[Node], bool]) -> "GraphQuery":
        """Filter results."""
        self._results = [n for n in self._results if predicate(n)]
        return self

    def traverse(
        self,
        edge_type: str,
        direction: EdgeDirection = EdgeDirection.OUTGOING
    ) -> "GraphQuery":
        """Traverse relationships."""
        new_results = []
        for node in self._results:
            for neighbor, edge in self.store.get_neighbors(node.id, direction, edge_type):
                if neighbor not in new_results:
                    new_results.append(neighbor)
        self._results = new_results
        return self

    def limit(self, count: int) -> "GraphQuery":
        """Limit results."""
        self._results = self._results[:count]
        return self

    def results(self) -> List[Node]:
        """Get results."""
        return self._results


class GraphManager:
    """High-level graph management."""

    def __init__(self):
        self.store = GraphStore()
        self.traversal = GraphTraversal(self.store)

    def create_node(
        self,
        node_type: str,
        properties: Dict[str, Any] = None,
        labels: Set[str] = None,
        node_id: str = None
    ) -> Node:
        """Create a node."""
        node = Node(
            id=node_id or str(uuid.uuid4()),
            node_type=node_type,
            properties=properties or {},
            labels=labels or set()
        )
        self.store.add_node(node)
        return node

    def create_edge(
        self,
        source_id: str,
        target_id: str,
        edge_type: str,
        properties: Dict[str, Any] = None,
        weight: float = 1.0
    ) -> Edge:
        """Create an edge."""
        edge = Edge(
            id=str(uuid.uuid4()),
            source_id=source_id,
            target_id=target_id,
            edge_type=edge_type,
            properties=properties or {},
            weight=weight
        )
        self.store.add_edge(edge)
        return edge

    def get_node(self, node_id: str) -> Optional[Dict[str, Any]]:
        """Get node by ID."""
        node = self.store.get_node(node_id)
        return node.to_dict() if node else None

    def delete_node(self, node_id: str) -> bool:
        """Delete a node."""
        return self.store.remove_node(node_id)

    def delete_edge(self, edge_id: str) -> bool:
        """Delete an edge."""
        return self.store.remove_edge(edge_id)

    def query(self) -> GraphQuery:
        """Start a query."""
        return GraphQuery(self.store)

    def neighbors(
        self,
        node_id: str,
        edge_type: Optional[str] = None,
        direction: str = "outgoing"
    ) -> List[Dict[str, Any]]:
        """Get neighbors of a node."""
        dir_enum = EdgeDirection(direction)
        neighbors = self.store.get_neighbors(node_id, dir_enum, edge_type)
        return [{"node": n.to_dict(), "edge": e.to_dict()} for n, e in neighbors]

    def shortest_path(self, start_id: str, end_id: str) -> Optional[Dict[str, Any]]:
        """Find shortest path."""
        path = self.traversal.shortest_path(start_id, end_id)
        if path:
            return {
                "nodes": [n.to_dict() for n in path.nodes],
                "edges": [e.to_dict() for e in path.edges],
                "total_weight": path.total_weight,
                "length": len(path)
            }
        return None

    def traverse_bfs(self, start_id: str, max_depth: int = 5) -> List[Dict[str, Any]]:
        """Traverse graph using BFS."""
        return [
            {"node": node.to_dict(), "depth": depth}
            for node, depth in self.traversal.bfs(start_id, max_depth)
        ]


# Example usage
def example_usage():
    """Example graph usage."""
    manager = GraphManager()

    # Create nodes
    alice = manager.create_node("user", {"name": "Alice"}, {"admin"})
    bob = manager.create_node("user", {"name": "Bob"})
    project = manager.create_node("resource", {"name": "Project X"})

    # Create edges
    manager.create_edge(alice.id, bob.id, "KNOWS", {"since": "2024"})
    manager.create_edge(alice.id, project.id, "OWNS")
    manager.create_edge(bob.id, project.id, "CONTRIBUTES")

    print(f"Created nodes: Alice={alice.id}, Bob={bob.id}")

    # Query
    users = manager.query().match("user").results()
    print(f"All users: {len(users)}")

    # Neighbors
    neighbors = manager.neighbors(alice.id)
    print(f"Alice's neighbors: {len(neighbors)}")

    # Shortest path
    path = manager.shortest_path(alice.id, project.id)
    print(f"Path to project: {path}")

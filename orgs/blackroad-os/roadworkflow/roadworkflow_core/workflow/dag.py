"""DAG - Directed Acyclic Graph for workflow dependencies.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from collections import deque
from dataclasses import dataclass, field
from typing import Any, Dict, Iterator, List, Optional, Set, Tuple

logger = logging.getLogger(__name__)


@dataclass
class Node:
    """DAG node representing a task."""

    id: str
    data: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Edge:
    """DAG edge representing a dependency."""

    source: str
    target: str
    data: Dict[str, Any] = field(default_factory=dict)


class DAG:
    """Directed Acyclic Graph for workflow task dependencies.

    Features:
    - Cycle detection
    - Topological sorting
    - Dependency resolution
    - Parallel execution groups

    Structure:
    ┌────────────────────────────────────────────────────────────┐
    │                         DAG                                 │
    │                                                             │
    │      ┌───┐                                                  │
    │      │ A │──────┐                                           │
    │      └───┘      │      ┌───┐                               │
    │                 ├─────▶│ C │──────┐                        │
    │      ┌───┐      │      └───┘      │      ┌───┐             │
    │      │ B │──────┘                 ├─────▶│ E │             │
    │      └───┘                        │      └───┘             │
    │                       ┌───┐       │                         │
    │                       │ D │───────┘                        │
    │                       └───┘                                 │
    │                                                             │
    │  Execution groups: [A,B,D] -> [C] -> [E]                   │
    └────────────────────────────────────────────────────────────┘
    """

    def __init__(self):
        self.nodes: Dict[str, Node] = {}
        self.edges: List[Edge] = []
        self._adjacency: Dict[str, Set[str]] = {}  # node -> outgoing edges
        self._reverse: Dict[str, Set[str]] = {}     # node -> incoming edges

    def add_node(self, node_id: str, **data) -> Node:
        """Add a node to the DAG."""
        if node_id not in self.nodes:
            self.nodes[node_id] = Node(id=node_id, data=data)
            self._adjacency[node_id] = set()
            self._reverse[node_id] = set()
        else:
            self.nodes[node_id].data.update(data)
        return self.nodes[node_id]

    def remove_node(self, node_id: str) -> bool:
        """Remove a node and its edges."""
        if node_id not in self.nodes:
            return False

        # Remove edges
        self.edges = [
            e for e in self.edges
            if e.source != node_id and e.target != node_id
        ]

        # Update adjacency
        for targets in self._adjacency.values():
            targets.discard(node_id)
        for sources in self._reverse.values():
            sources.discard(node_id)

        del self.nodes[node_id]
        del self._adjacency[node_id]
        del self._reverse[node_id]

        return True

    def add_edge(
        self,
        source: str,
        target: str,
        **data,
    ) -> Edge:
        """Add an edge (dependency) between nodes.

        Args:
            source: Source node (dependency)
            target: Target node (dependent)
        """
        # Ensure nodes exist
        if source not in self.nodes:
            self.add_node(source)
        if target not in self.nodes:
            self.add_node(target)

        edge = Edge(source=source, target=target, data=data)
        self.edges.append(edge)
        self._adjacency[source].add(target)
        self._reverse[target].add(source)

        return edge

    def remove_edge(self, source: str, target: str) -> bool:
        """Remove an edge."""
        for i, edge in enumerate(self.edges):
            if edge.source == source and edge.target == target:
                self.edges.pop(i)
                self._adjacency[source].discard(target)
                self._reverse[target].discard(source)
                return True
        return False

    def get_dependencies(self, node_id: str) -> Set[str]:
        """Get nodes that this node depends on (incoming edges)."""
        return self._reverse.get(node_id, set()).copy()

    def get_dependents(self, node_id: str) -> Set[str]:
        """Get nodes that depend on this node (outgoing edges)."""
        return self._adjacency.get(node_id, set()).copy()

    def get_roots(self) -> List[str]:
        """Get nodes with no dependencies (starting points)."""
        return [
            node_id for node_id, deps in self._reverse.items()
            if len(deps) == 0
        ]

    def get_leaves(self) -> List[str]:
        """Get nodes with no dependents (end points)."""
        return [
            node_id for node_id, deps in self._adjacency.items()
            if len(deps) == 0
        ]

    def has_cycle(self) -> bool:
        """Check if the graph contains a cycle."""
        visited = set()
        rec_stack = set()

        def dfs(node: str) -> bool:
            visited.add(node)
            rec_stack.add(node)

            for neighbor in self._adjacency.get(node, set()):
                if neighbor not in visited:
                    if dfs(neighbor):
                        return True
                elif neighbor in rec_stack:
                    return True

            rec_stack.remove(node)
            return False

        for node in self.nodes:
            if node not in visited:
                if dfs(node):
                    return True

        return False

    def topological_sort(self) -> List[str]:
        """Get nodes in topological order (respecting dependencies).

        Returns:
            List of node IDs in execution order
        """
        if self.has_cycle():
            raise ValueError("Cannot sort: graph contains a cycle")

        in_degree = {node: len(deps) for node, deps in self._reverse.items()}
        queue = deque([node for node, deg in in_degree.items() if deg == 0])
        result = []

        while queue:
            node = queue.popleft()
            result.append(node)

            for neighbor in self._adjacency.get(node, set()):
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    queue.append(neighbor)

        if len(result) != len(self.nodes):
            raise ValueError("Cannot sort: graph contains a cycle")

        return result

    def get_parallel_groups(self) -> List[List[str]]:
        """Get groups of tasks that can run in parallel.

        Returns:
            List of groups, where each group can run simultaneously
        """
        if self.has_cycle():
            raise ValueError("Cannot group: graph contains a cycle")

        groups = []
        remaining = set(self.nodes.keys())
        completed = set()

        while remaining:
            # Find all nodes whose dependencies are complete
            ready = [
                node for node in remaining
                if self._reverse[node] <= completed
            ]

            if not ready:
                raise ValueError("Cannot group: circular dependency detected")

            groups.append(ready)
            completed.update(ready)
            remaining -= set(ready)

        return groups

    def get_path(self, source: str, target: str) -> Optional[List[str]]:
        """Find a path between two nodes using BFS."""
        if source not in self.nodes or target not in self.nodes:
            return None

        queue = deque([(source, [source])])
        visited = {source}

        while queue:
            node, path = queue.popleft()

            if node == target:
                return path

            for neighbor in self._adjacency.get(node, set()):
                if neighbor not in visited:
                    visited.add(neighbor)
                    queue.append((neighbor, path + [neighbor]))

        return None

    def get_all_paths(
        self,
        source: str,
        target: str,
    ) -> List[List[str]]:
        """Find all paths between two nodes using DFS."""
        if source not in self.nodes or target not in self.nodes:
            return []

        paths = []

        def dfs(node: str, path: List[str]) -> None:
            if node == target:
                paths.append(path.copy())
                return

            for neighbor in self._adjacency.get(node, set()):
                if neighbor not in path:
                    path.append(neighbor)
                    dfs(neighbor, path)
                    path.pop()

        dfs(source, [source])
        return paths

    def subgraph(self, nodes: Set[str]) -> "DAG":
        """Create a subgraph containing only specified nodes."""
        sub = DAG()

        for node_id in nodes:
            if node_id in self.nodes:
                sub.add_node(node_id, **self.nodes[node_id].data)

        for edge in self.edges:
            if edge.source in nodes and edge.target in nodes:
                sub.add_edge(edge.source, edge.target, **edge.data)

        return sub

    def __iter__(self) -> Iterator[str]:
        """Iterate over nodes in topological order."""
        return iter(self.topological_sort())

    def __len__(self) -> int:
        """Get number of nodes."""
        return len(self.nodes)

    def __contains__(self, node_id: str) -> bool:
        """Check if node exists."""
        return node_id in self.nodes


__all__ = [
    "DAG",
    "Node",
    "Edge",
]

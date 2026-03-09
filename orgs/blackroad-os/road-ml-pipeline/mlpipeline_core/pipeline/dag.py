"""RoadML DAG - Directed Acyclic Graph for Pipeline.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

from collections import defaultdict, deque
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Set


@dataclass
class DAGNode:
    """A node in the DAG.

    Attributes:
        name: Node name
        dependencies: Upstream dependencies
        data: Node data
    """

    name: str
    dependencies: List[str] = field(default_factory=list)
    data: Any = None


class DAG:
    """Directed Acyclic Graph for pipeline orchestration.

    Supports:
    - Topological sorting
    - Cycle detection
    - Parallel level identification
    - Visualization
    """

    def __init__(self):
        """Initialize DAG."""
        self._nodes: Dict[str, DAGNode] = {}
        self._edges: Dict[str, Set[str]] = defaultdict(set)
        self._reverse_edges: Dict[str, Set[str]] = defaultdict(set)

    def add_node(
        self,
        name: str,
        dependencies: Optional[List[str]] = None,
        data: Any = None,
    ) -> DAGNode:
        """Add a node to the DAG.

        Args:
            name: Node name
            dependencies: Upstream node names
            data: Optional node data

        Returns:
            Created node
        """
        dependencies = dependencies or []

        node = DAGNode(name=name, dependencies=dependencies, data=data)
        self._nodes[name] = node

        # Add edges
        for dep in dependencies:
            self._edges[dep].add(name)
            self._reverse_edges[name].add(dep)

        return node

    def remove_node(self, name: str) -> None:
        """Remove a node from the DAG.

        Args:
            name: Node name to remove
        """
        if name not in self._nodes:
            return

        # Remove edges
        for downstream in self._edges.get(name, set()):
            self._reverse_edges[downstream].discard(name)

        for upstream in self._reverse_edges.get(name, set()):
            self._edges[upstream].discard(name)

        # Remove node
        del self._nodes[name]
        self._edges.pop(name, None)
        self._reverse_edges.pop(name, None)

    def has_node(self, name: str) -> bool:
        """Check if node exists.

        Args:
            name: Node name

        Returns:
            True if exists
        """
        return name in self._nodes

    def get_node(self, name: str) -> Optional[DAGNode]:
        """Get node by name.

        Args:
            name: Node name

        Returns:
            DAGNode or None
        """
        return self._nodes.get(name)

    def get_dependencies(self, name: str) -> List[str]:
        """Get upstream dependencies.

        Args:
            name: Node name

        Returns:
            List of dependency names
        """
        return list(self._reverse_edges.get(name, set()))

    def get_dependents(self, name: str) -> List[str]:
        """Get downstream dependents.

        Args:
            name: Node name

        Returns:
            List of dependent names
        """
        return list(self._edges.get(name, set()))

    def topological_sort(self) -> List[str]:
        """Get topologically sorted node order.

        Returns:
            Sorted node names

        Raises:
            ValueError: If cycle detected
        """
        if self.has_cycle():
            raise ValueError("DAG contains a cycle")

        # Kahn's algorithm
        in_degree = {name: len(self._reverse_edges.get(name, set()))
                     for name in self._nodes}

        queue = deque(name for name, degree in in_degree.items() if degree == 0)
        result = []

        while queue:
            node = queue.popleft()
            result.append(node)

            for downstream in self._edges.get(node, set()):
                in_degree[downstream] -= 1
                if in_degree[downstream] == 0:
                    queue.append(downstream)

        return result

    def has_cycle(self) -> bool:
        """Check if DAG has a cycle.

        Returns:
            True if cycle exists
        """
        WHITE, GRAY, BLACK = 0, 1, 2
        colors = {name: WHITE for name in self._nodes}

        def dfs(node: str) -> bool:
            colors[node] = GRAY

            for downstream in self._edges.get(node, set()):
                if colors[downstream] == GRAY:
                    return True
                if colors[downstream] == WHITE and dfs(downstream):
                    return True

            colors[node] = BLACK
            return False

        for node in self._nodes:
            if colors[node] == WHITE and dfs(node):
                return True

        return False

    def get_roots(self) -> List[str]:
        """Get root nodes (no dependencies).

        Returns:
            List of root node names
        """
        return [
            name for name in self._nodes
            if not self._reverse_edges.get(name)
        ]

    def get_leaves(self) -> List[str]:
        """Get leaf nodes (no dependents).

        Returns:
            List of leaf node names
        """
        return [
            name for name in self._nodes
            if not self._edges.get(name)
        ]

    def get_parallel_levels(self) -> List[List[str]]:
        """Get nodes grouped by parallel execution level.

        Returns:
            List of levels, each containing parallel nodes
        """
        if self.has_cycle():
            raise ValueError("DAG contains a cycle")

        levels: List[List[str]] = []
        remaining = set(self._nodes.keys())
        completed: Set[str] = set()

        while remaining:
            # Find nodes with all deps satisfied
            level = []
            for name in remaining:
                deps = self._reverse_edges.get(name, set())
                if deps.issubset(completed):
                    level.append(name)

            if not level:
                raise RuntimeError("Cannot make progress - possible cycle")

            levels.append(sorted(level))
            completed.update(level)
            remaining -= set(level)

        return levels

    def visualize(self) -> str:
        """Generate ASCII visualization.

        Returns:
            ASCII diagram
        """
        lines = ["DAG Visualization:", "=" * 40]

        try:
            levels = self.get_parallel_levels()

            for i, level in enumerate(levels):
                lines.append(f"Level {i}:")
                for name in level:
                    deps = self.get_dependencies(name)
                    if deps:
                        lines.append(f"  [{name}] <- {deps}")
                    else:
                        lines.append(f"  [{name}]")
                lines.append("")

        except ValueError as e:
            lines.append(f"Error: {e}")

        return "\n".join(lines)

    def __len__(self) -> int:
        """Get node count."""
        return len(self._nodes)

    def __contains__(self, name: str) -> bool:
        """Check if node exists."""
        return name in self._nodes

    def __repr__(self) -> str:
        return f"DAG(nodes={len(self._nodes)})"


__all__ = ["DAG", "DAGNode"]

"""Sacred geometry pattern generators - Flower of Life, Metatron's Cube, Spirals."""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import List, Tuple

import numpy as np

PHI = (1.0 + math.sqrt(5.0)) / 2.0  # Golden ratio


@dataclass
class Point2D:
    """2D point."""

    x: float
    y: float

    def distance_to(self, other: Point2D) -> float:
        """Calculate Euclidean distance to another point."""
        return math.sqrt((self.x - other.x) ** 2 + (self.y - other.y) ** 2)

    def to_tuple(self) -> Tuple[float, float]:
        """Convert to tuple."""
        return (self.x, self.y)


class FlowerOfLifeGenerator:
    """Generate Flower of Life sacred geometry pattern."""

    def __init__(self, radius: float = 1.0):
        """Initialize with circle radius."""
        self.radius = radius

    def generate_circles(self, layers: int = 3) -> List[Point2D]:
        """Generate circle centers for Flower of Life pattern.

        Args:
            layers: Number of hexagonal layers around center

        Returns:
            List of circle centers
        """
        centers = [Point2D(0.0, 0.0)]  # Central circle

        for layer in range(1, layers + 1):
            # Each layer forms a hexagon
            for i in range(6 * layer):
                angle = (i / (6 * layer)) * 2 * math.pi
                x = layer * self.radius * math.cos(angle)
                y = layer * self.radius * math.sin(angle)

                # Only add if not duplicate (accounting for floating point)
                new_point = Point2D(x, y)
                if not any(new_point.distance_to(p) < 0.1 * self.radius for p in centers):
                    centers.append(new_point)

        return centers

    def generate_vesica_piscis(self) -> Tuple[Point2D, Point2D]:
        """Generate two circles forming Vesica Piscis.

        Returns:
            Tuple of two circle centers
        """
        return (Point2D(-self.radius / 2, 0.0), Point2D(self.radius / 2, 0.0))


class MetatronsCubeGenerator:
    """Generate Metatron's Cube sacred geometry pattern."""

    def __init__(self, radius: float = 1.0):
        """Initialize with radius."""
        self.radius = radius

    def generate_vertices(self) -> List[Point2D]:
        """Generate 13 vertices of Metatron's Cube.

        Returns:
            List of 13 vertices (1 center + 2 hexagonal rings)
        """
        vertices = [Point2D(0.0, 0.0)]  # Center

        # First hexagonal ring
        for i in range(6):
            angle = i * (math.pi / 3)
            x = self.radius * math.cos(angle)
            y = self.radius * math.sin(angle)
            vertices.append(Point2D(x, y))

        # Second hexagonal ring (offset by 30 degrees)
        for i in range(6):
            angle = i * (math.pi / 3) + (math.pi / 6)
            x = self.radius * PHI * math.cos(angle)
            y = self.radius * PHI * math.sin(angle)
            vertices.append(Point2D(x, y))

        return vertices

    def generate_edges(self) -> List[Tuple[int, int]]:
        """Generate all edges connecting vertices.

        Returns:
            List of vertex index pairs
        """
        edges = []

        # Connect center to all vertices
        for i in range(1, 13):
            edges.append((0, i))

        # Connect inner hexagon
        for i in range(1, 7):
            edges.append((i, (i % 6) + 1))

        # Connect outer hexagon
        for i in range(7, 13):
            edges.append((i, ((i - 7 + 1) % 6) + 7))

        # Connect inner to outer
        for i in range(6):
            edges.append((i + 1, i + 7))
            edges.append((i + 1, ((i + 1) % 6) + 7))

        return edges


class GoldenSpiralGenerator:
    """Generate golden ratio spiral (Fibonacci spiral)."""

    def __init__(self, initial_size: float = 1.0):
        """Initialize with initial square size."""
        self.initial_size = initial_size

    def generate_arc_points(self, iterations: int = 8, points_per_arc: int = 20) -> List[Point2D]:
        """Generate points along golden spiral.

        Args:
            iterations: Number of Fibonacci iterations
            points_per_arc: Number of points per quarter-circle arc

        Returns:
            List of points along the spiral
        """
        points = []
        size = self.initial_size
        x, y = 0.0, 0.0
        direction = 0  # 0=right, 1=down, 2=left, 3=up

        for iteration in range(iterations):
            # Generate quarter-circle arc
            for i in range(points_per_arc):
                t = i / points_per_arc
                angle = (math.pi / 2) * t

                # Calculate point on arc based on direction
                if direction == 0:  # Right
                    px = x + size * (1 - math.cos(angle))
                    py = y + size * math.sin(angle)
                elif direction == 1:  # Down
                    px = x - size * math.sin(angle)
                    py = y + size * (1 - math.cos(angle))
                elif direction == 2:  # Left
                    px = x - size * (1 - math.cos(angle))
                    py = y - size * math.sin(angle)
                else:  # Up
                    px = x + size * math.sin(angle)
                    py = y - size * (1 - math.cos(angle))

                points.append(Point2D(px, py))

            # Update position and size for next iteration
            if direction == 0:
                x += size
            elif direction == 1:
                y += size
            elif direction == 2:
                x -= size
                y -= size
            else:
                y -= size

            direction = (direction + 1) % 4
            size *= PHI

        return points


class PlatonicSolidProjector:
    """Project 3D Platonic solids onto 2D plane."""

    @staticmethod
    def tetrahedron_vertices() -> np.ndarray:
        """Get tetrahedron vertices."""
        return np.array([[1, 1, 1], [-1, -1, 1], [-1, 1, -1], [1, -1, -1]], dtype=float)

    @staticmethod
    def cube_vertices() -> np.ndarray:
        """Get cube vertices."""
        vertices = []
        for i in range(8):
            x = 1 if i & 1 else -1
            y = 1 if i & 2 else -1
            z = 1 if i & 4 else -1
            vertices.append([x, y, z])
        return np.array(vertices, dtype=float)

    @staticmethod
    def octahedron_vertices() -> np.ndarray:
        """Get octahedron vertices."""
        return np.array([[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]], dtype=float)

    @staticmethod
    def icosahedron_vertices() -> np.ndarray:
        """Get icosahedron vertices."""
        vertices = []
        for i in [-1, 1]:
            for j in [-1, 1]:
                vertices.append([0, i, j * PHI])
                vertices.append([i, j * PHI, 0])
                vertices.append([i * PHI, 0, j])
        return np.array(vertices, dtype=float)

    @staticmethod
    def dodecahedron_vertices() -> np.ndarray:
        """Get dodecahedron vertices."""
        vertices = []

        # Cube vertices
        for i in [-1, 1]:
            for j in [-1, 1]:
                for k in [-1, 1]:
                    vertices.append([i, j, k])

        # Rectangular faces
        phi_inv = 1 / PHI
        for i in [-1, 1]:
            for j in [-1, 1]:
                vertices.append([0, i * phi_inv, j * PHI])
                vertices.append([i * phi_inv, j * PHI, 0])
                vertices.append([i * PHI, 0, j * phi_inv])

        return np.array(vertices, dtype=float)

    @staticmethod
    def project_2d(vertices_3d: np.ndarray, rotation: Tuple[float, float, float] = (0, 0, 0)) -> List[Point2D]:
        """Project 3D vertices to 2D using perspective projection.

        Args:
            vertices_3d: Nx3 array of 3D vertices
            rotation: (rx, ry, rz) rotation angles in radians

        Returns:
            List of 2D projected points
        """
        # Apply rotations
        rx, ry, rz = rotation

        # Rotation matrices
        Rx = np.array([[1, 0, 0], [0, math.cos(rx), -math.sin(rx)], [0, math.sin(rx), math.cos(rx)]])

        Ry = np.array([[math.cos(ry), 0, math.sin(ry)], [0, 1, 0], [-math.sin(ry), 0, math.cos(ry)]])

        Rz = np.array([[math.cos(rz), -math.sin(rz), 0], [math.sin(rz), math.cos(rz), 0], [0, 0, 1]])

        # Apply rotations
        rotated = vertices_3d @ Rx.T @ Ry.T @ Rz.T

        # Perspective projection (simple orthographic for now)
        points_2d = []
        for vertex in rotated:
            # Simple orthographic projection (ignore z)
            points_2d.append(Point2D(vertex[0], vertex[1]))

        return points_2d


__all__ = [
    "Point2D",
    "FlowerOfLifeGenerator",
    "MetatronsCubeGenerator",
    "GoldenSpiralGenerator",
    "PlatonicSolidProjector",
    "PHI",
]

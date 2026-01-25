"""Core utilities for the Lucidia project.

This package provides foundational building blocks that other Lucidia
components can rely on.  Currently it offers a small geometry module with a
`Vector3` class for basic vector mathematics.  The goal is to keep these
utilities lightweight and dependency free so they can be reused broadly.
"""

from .vectors import Vector3

__all__ = ["Vector3"]

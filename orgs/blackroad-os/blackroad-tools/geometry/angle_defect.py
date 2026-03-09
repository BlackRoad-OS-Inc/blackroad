"""Discrete Gaussian curvature via angle defects with a simple CLI."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from typing import List, Sequence, Tuple

import numpy as np


Point3D = Tuple[float, float, float]
Face = Tuple[int, int, int]


def angle(a: Sequence[float], b: Sequence[float], c: Sequence[float]) -> float:
    """Return the angle ∠ABC for triangle (a, b, c)."""

    a_arr = np.asarray(a, dtype=float)
    b_arr = np.asarray(b, dtype=float)
    c_arr = np.asarray(c, dtype=float)

    u = a_arr - b_arr
    v = c_arr - b_arr
    denom = np.linalg.norm(u) * np.linalg.norm(v)
    if denom == 0:
        raise ValueError("triangle edges must have positive length")
    cos_value = np.dot(u, v) / denom
    return float(np.arccos(np.clip(cos_value, -1.0, 1.0)))


def angle_defects(vertices: Sequence[Sequence[float]], faces: Sequence[Sequence[int]]) -> np.ndarray:
    """Return the angle defect K(v) for each vertex in a triangulated mesh."""

    vertex_count = len(vertices)
    if vertex_count == 0:
        raise ValueError("mesh must contain vertices")

    curvature = np.full(vertex_count, 2 * np.pi, dtype=float)
    vertices_arr = np.asarray(vertices, dtype=float)

    for face in faces:
        if len(face) != 3:
            raise ValueError("angle defects require triangular faces")
        i, j, k = face
        ai = angle(vertices_arr[j], vertices_arr[i], vertices_arr[k])
        aj = angle(vertices_arr[i], vertices_arr[j], vertices_arr[k])
        ak = angle(vertices_arr[i], vertices_arr[k], vertices_arr[j])
        curvature[i] -= ai
        curvature[j] -= aj
        curvature[k] -= ak

    return curvature


def _parse_obj(path: Path) -> Tuple[List[Point3D], List[Face]]:
    vertices: List[Point3D] = []
    faces: List[Face] = []

    with path.open("r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("v "):
                _, x, y, z, *rest = line.split()
                vertices.append((float(x), float(y), float(z)))
            elif line.startswith("f "):
                parts = line.split()[1:]
                if len(parts) != 3:
                    raise ValueError("only triangular faces are supported")
                face_indices: List[int] = []
                for part in parts:
                    index_str = part.split("/")[0]
                    index = int(index_str) - 1
                    face_indices.append(index)
                faces.append((face_indices[0], face_indices[1], face_indices[2]))

    if not vertices or not faces:
        raise ValueError("OBJ file must contain vertices and triangular faces")

    return vertices, faces


def _write_curvature_csv(path: Path, curvature: np.ndarray) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["vertex", "angle_defect"])
        for index, value in enumerate(curvature):
            writer.writerow([index, float(value)])


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Compute per-vertex angle defects for a triangulated OBJ mesh.")
    parser.add_argument("obj", help="Path to a triangle mesh in Wavefront OBJ format.")
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=Path("angle_defects.csv"),
        help="Destination CSV file for per-vertex curvature values.",
    )
    args = parser.parse_args(argv)

    obj_path = Path(args.obj)
    vertices, faces = _parse_obj(obj_path)
    curvature = angle_defects(vertices, faces)

    output_path = args.output
    if not output_path.parent.exists():
        output_path.parent.mkdir(parents=True, exist_ok=True)
    _write_curvature_csv(output_path, curvature)

    total_curvature = float(curvature.sum())
    euler_estimate = total_curvature / (2 * np.pi)

    print(f"vertices={len(vertices)}")
    print(f"faces={len(faces)}")
    print(f"sum_curvature={total_curvature}")
    print(f"sum_curvature_over_2pi={euler_estimate}")
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    raise SystemExit(main())

"""CLI utility for projecting 3D points onto a 2D picture plane.

The script consumes an input CSV with columns ``x``, ``y``, ``z`` and
optionally ``d`` (viewer-to-window distance). A constant ``d`` can also be
specified via the ``--distance`` flag. The projection equations follow the
setup described in the prompt:

    x' = d * x / (z + d)
    y' = d * y / (z + d)

Vanishing points for direction vectors may be computed by supplying an
additional CSV via ``--directions`` containing columns ``vx``, ``vy``, ``vz``
and an optional ``label``.
"""
from __future__ import annotations

import argparse
import csv
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Sequence


@dataclass
class Point3D:
    x: float
    y: float
    z: float
    d: float


@dataclass
class ProjectedPoint:
    index: int
    x: float
    y: float
    z: float
    d: float
    x_proj: float
    y_proj: float


@dataclass
class Direction:
    vx: float
    vy: float
    vz: float
    label: str | None = None


@dataclass
class VanishingPoint:
    direction: Direction
    x: float | None
    y: float | None

    @property
    def is_finite(self) -> bool:
        return self.x is not None and self.y is not None


class ProjectionError(Exception):
    """Raised when a point cannot be projected."""


def _parse_float(value: str, field: str, row_number: int) -> float:
    try:
        return float(value)
    except ValueError as exc:
        raise ProjectionError(
            f"Row {row_number}: unable to parse '{field}' value '{value}' as a float"
        ) from exc


def read_points(path: Path, distance: float | None = None) -> List[Point3D]:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        required_fields = {"x", "y", "z"}
        missing = required_fields - set(reader.fieldnames or [])
        if missing:
            raise ProjectionError(
                f"Input CSV is missing required columns: {', '.join(sorted(missing))}"
            )
        points: List[Point3D] = []
        for idx, row in enumerate(reader, start=2):  # header is row 1
            x = _parse_float(row["x"], "x", idx)
            y = _parse_float(row["y"], "y", idx)
            z = _parse_float(row["z"], "z", idx)
            d_value: float
            if "d" in row and row["d"] != "":
                d_value = _parse_float(row["d"], "d", idx)
            elif distance is not None:
                d_value = distance
            else:
                raise ProjectionError(
                    "Viewer distance 'd' must be supplied either as a column or via --distance"
                )
            points.append(Point3D(x=x, y=y, z=z, d=d_value))
    if not points:
        raise ProjectionError("Input CSV did not contain any data rows")
    return points


def read_directions(path: Path | None) -> List[Direction]:
    if path is None:
        return []
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        required_fields = {"vx", "vy", "vz"}
        missing = required_fields - set(reader.fieldnames or [])
        if missing:
            raise ProjectionError(
                f"Direction CSV is missing required columns: {', '.join(sorted(missing))}"
            )
        directions: List[Direction] = []
        for idx, row in enumerate(reader, start=2):
            vx = _parse_float(row["vx"], "vx", idx)
            vy = _parse_float(row["vy"], "vy", idx)
            vz = _parse_float(row["vz"], "vz", idx)
            label = row.get("label") or None
            directions.append(Direction(vx=vx, vy=vy, vz=vz, label=label))
    return directions


def project_points(points: Sequence[Point3D]) -> List[ProjectedPoint]:
    projected: List[ProjectedPoint] = []
    for index, point in enumerate(points):
        denominator = point.z + point.d
        if denominator == 0:
            raise ProjectionError(
                f"Point at index {index} has z + d == 0, projection is undefined"
            )
        factor = point.d / denominator
        projected.append(
            ProjectedPoint(
                index=index,
                x=point.x,
                y=point.y,
                z=point.z,
                d=point.d,
                x_proj=factor * point.x,
                y_proj=factor * point.y,
            )
        )
    return projected


def compute_vanishing_points(directions: Iterable[Direction], distance: float) -> List[VanishingPoint]:
    vanishing_points: List[VanishingPoint] = []
    for direction in directions:
        if direction.vz == 0:
            vanishing_points.append(VanishingPoint(direction=direction, x=None, y=None))
            continue
        factor = distance / direction.vz
        vanishing_points.append(
            VanishingPoint(
                direction=direction,
                x=factor * direction.vx,
                y=factor * direction.vy,
            )
        )
    return vanishing_points


def write_projected(points: Sequence[ProjectedPoint], output_path: Path | None) -> None:
    """Persist projected points to CSV or stdout."""

    if output_path is None:
        # Stream JSON to stdout for easy clipboard usage.
        print(json.dumps([point.__dict__ for point in points], indent=2))
        return

    fieldnames = ["index", "x", "y", "z", "d", "x_proj", "y_proj"]
    with output_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for point in points:
            writer.writerow(point.__dict__)


def write_vanishing_points(
    vanishing_points: Sequence[VanishingPoint],
    output_path: Path | None,
) -> None:
    serializable = []
    for vp in vanishing_points:
        data = {
            "vx": vp.direction.vx,
            "vy": vp.direction.vy,
            "vz": vp.direction.vz,
            "label": vp.direction.label,
        }
        if vp.is_finite:
            data.update({"x": vp.x, "y": vp.y})
        serializable.append(data)
    text = json.dumps(serializable, indent=2)
    if output_path is None:
        print(text)
        return
    output_path.write_text(text + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Project 3D points into 2D space")
    parser.add_argument("input", type=Path, help="Path to input CSV with x,y,z[,d] columns")
    parser.add_argument(
        "--output",
        type=Path,
        help="Optional path for the projected CSV output (defaults to stdout as JSON)",
    )
    parser.add_argument(
        "--distance",
        type=float,
        help="Viewer distance d. Overrides any per-row d column if supplied",
    )
    parser.add_argument(
        "--directions",
        type=Path,
        help="Optional CSV of direction vectors (vx,vy,vz[,label]) for vanishing point calculation",
    )
    parser.add_argument(
        "--vanishing-output",
        type=Path,
        help="Optional output path for vanishing points (JSON). Defaults to stdout",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    try:
        points = read_points(args.input, distance=args.distance)
        projected = project_points(points)
        write_projected(projected, args.output)
        if args.directions:
            if args.distance is not None:
                distance = args.distance
            else:
                unique_distances = {point.d for point in points}
                if len(unique_distances) != 1:
                    raise ProjectionError(
                        "Cannot compute vanishing points: specify --distance when rows have different d"
                    )
                distance = unique_distances.pop()
            directions = read_directions(args.directions)
            vanishing_points = compute_vanishing_points(directions, distance)
            write_vanishing_points(vanishing_points, args.vanishing_output)
    except ProjectionError as exc:
        raise SystemExit(str(exc)) from exc


if __name__ == "__main__":
    main()

"""Magic square generator toolkit.

This module can generate magic squares for odd and doubly-even orders,
validate the generated square, and export the result to CSV. A simple
command-line interface is also provided.
"""
from __future__ import annotations

import argparse
import csv
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Sequence


@dataclass
class MagicSquareSummary:
    """Statistics gathered for a magic square."""

    order: int
    magic_constant: int
    row_sums: List[int]
    column_sums: List[int]
    diagonal_sums: List[int]

    @property
    def is_magic(self) -> bool:
        """Return ``True`` when the square satisfies the magic constraints."""

        target = self.magic_constant
        return (
            all(total == target for total in self.row_sums)
            and all(total == target for total in self.column_sums)
            and all(total == target for total in self.diagonal_sums)
        )

    def to_json(self) -> str:
        """Serialise the summary to JSON."""

        payload = {
            "n": self.order,
            "magic_constant": self.magic_constant,
            "row_sums": self.row_sums,
            "column_sums": self.column_sums,
            "diagonal_sums": self.diagonal_sums,
            "is_magic": self.is_magic,
        }
        return json.dumps(payload, indent=2)


def generate_magic_square(order: int) -> List[List[int]]:
    """Generate a magic square of the requested order."""

    if order < 1:
        raise ValueError("Order must be positive")

    if order % 2 == 1:
        return _generate_magic_square_odd(order)
    if order % 4 == 0:
        return _generate_magic_square_doubly_even(order)

    raise NotImplementedError(
        "Singly-even orders (n = 2 mod 4) are not implemented yet."
    )


def _generate_magic_square_odd(order: int) -> List[List[int]]:
    """Generate an odd-order magic square using the Gamma + 2 method."""

    square = [[0 for _ in range(order)] for _ in range(order)]
    max_value = order * order
    row = 0
    col = order // 2

    for value in range(1, max_value + 1):
        square[row][col] = value
        next_row = (row - 1) % order
        next_col = (col + 1) % order

        if square[next_row][next_col] != 0:
            row = (row + 1) % order
        else:
            row = next_row
            col = next_col

    return square


def _generate_magic_square_doubly_even(order: int) -> List[List[int]]:
    """Generate a doubly-even order magic square using the Dürer mask."""

    square = [[0 for _ in range(order)] for _ in range(order)]
    max_value = order * order

    for row in range(order):
        for col in range(order):
            value = row * order + col + 1
            if _is_masked_cell(row, col):
                square[row][col] = max_value + 1 - value
            else:
                square[row][col] = value

    return square


def _is_masked_cell(row: int, col: int) -> bool:
    return (
        (row % 4 in {0, 3} and col % 4 in {0, 3})
        or (row % 4 in {1, 2} and col % 4 in {1, 2})
    )


def summarise(square: Iterable[Iterable[int]]) -> MagicSquareSummary:
    matrix = [list(row) for row in square]
    order = len(matrix)
    if order == 0 or any(len(row) != order for row in matrix):
        raise ValueError("Square must be a non-empty n x n matrix")

    magic_constant = order * (order * order + 1) // 2
    row_sums = [sum(row) for row in matrix]
    column_sums = [sum(matrix[r][c] for r in range(order)) for c in range(order)]
    diagonal_primary = sum(matrix[i][i] for i in range(order))
    diagonal_secondary = sum(matrix[i][order - 1 - i] for i in range(order))

    return MagicSquareSummary(
        order=order,
        magic_constant=magic_constant,
        row_sums=row_sums,
        column_sums=column_sums,
        diagonal_sums=[diagonal_primary, diagonal_secondary],
    )


def write_csv(square: Sequence[Sequence[int]], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle)
        for row in square:
            writer.writerow(list(row))


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Magic square generator")
    parser.add_argument("--n", type=int, required=True, help="Order of the magic square")
    parser.add_argument(
        "--outcsv",
        type=Path,
        required=True,
        help="Location to write the generated square as CSV",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_arguments()
    square = generate_magic_square(args.n)
    summary = summarise(square)
    if not summary.is_magic:
        raise RuntimeError("Generated square failed validation")

    write_csv(square, args.outcsv)
    print(summary.to_json())


if __name__ == "__main__":
    main()

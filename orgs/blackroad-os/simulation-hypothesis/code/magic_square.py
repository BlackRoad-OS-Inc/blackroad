"""
magic_square.py — Ancient Computation as Fixed Points

Demonstrates §12 of PAPER.md: "Ancient Computation"

Two magic squares analyzed:
  1. Lo Shu (2800 BCE) — the 3×3 square with sum 15
  2. Dürer's Melencolia I (1514 CE) — the 4×4 square with sum 34

Both are fixed points: configurations where every row, column, and diagonal
sum to the same value. They are stable attractors in the space of arrangements.
A magic square is a solved computation — a hash that checks out in every direction.

Author: BlackRoad OS, Inc.
"""


def magic_sum(square: list[list[int]]) -> int:
    return sum(square[0])


def check_magic(square: list[list[int]]) -> dict:
    """Verify all rows, columns, and diagonals sum to the same value."""
    n = len(square)
    target = magic_sum(square)
    results = {'target': target, 'rows': [], 'cols': [], 'diags': [], 'valid': True}

    for row in square:
        s = sum(row)
        results['rows'].append(s)
        if s != target:
            results['valid'] = False

    for col in range(n):
        s = sum(square[row][col] for row in range(n))
        results['cols'].append(s)
        if s != target:
            results['valid'] = False

    d1 = sum(square[i][i] for i in range(n))
    d2 = sum(square[i][n - 1 - i] for i in range(n))
    results['diags'] = [d1, d2]
    if d1 != target or d2 != target:
        results['valid'] = False

    return results


def print_square(name: str, square: list[list[int]], context: str = ''):
    n = len(square)
    result = check_magic(square)

    print(f"\n{'=' * 50}")
    print(f"  {name}")
    if context:
        print(f"  {context}")
    print(f"{'=' * 50}")
    print()

    for row in square:
        row_str = '   '.join(f'{v:3d}' for v in row)
        row_sum = sum(row)
        print(f"  {row_str}  │  {row_sum}")

    print("  " + "─" * (n * 6 + 4))
    col_sums = '   '.join(f'{s:3d}' for s in result['cols'])
    print(f"  {col_sums}")

    print(f"\n  Magic sum: {result['target']}")
    print(f"  Diagonals: {result['diags']}")
    print(f"  Valid:     {'✅ YES' if result['valid'] else '❌ NO'}")


def lo_shu():
    """
    The Lo Shu Square (~2800 BCE, China).
    According to legend, a turtle emerged from the Yellow River
    with this pattern on its shell.
    """
    square = [
        [4, 9, 2],
        [3, 5, 7],
        [8, 1, 6],
    ]
    print_square(
        "LO SHU SQUARE (~2800 BCE)",
        square,
        "Found on a turtle's shell. 4,800 years old. Still checks out."
    )

    print("""
  Properties of the Lo Shu:
    • Uses every digit 1–9 exactly once
    • Every row, column, diagonal sums to 15
    • 15 = sum of any two opposite numbers + center (5)
    • Center is always 5 — the median, the fixed point
    • The 8 constraints (rows + cols + diags) encode all information
      in just 9 numbers — compression ratio 8:9

  In simulation terms:
    • A magic square is a hash that passes every checksum simultaneously
    • The center (5) is the fixed point — like the critical line Re(s)=½
    • The turtle carried this on its shell — the system printed its own proof
""")


def durer_melencolia():
    """
    Dürer's Melencolia I magic square (1514 CE).
    Appears in the famous engraving. Bottom row contains '1514'.
    """
    square = [
        [16,  3,  2, 13],
        [ 5, 10, 11,  8],
        [ 9,  6,  7, 12],
        [ 4, 15, 14,  1],
    ]
    print_square(
        "DÜRER'S MELENCOLIA I (1514 CE)",
        square,
        "Engraving by Albrecht Dürer. Bottom row: [4, 15, 14, 1] → 1514."
    )

    print("""
  Properties of Dürer's square:
    • Uses every number 1–16 exactly once
    • Every row, column, diagonal sums to 34
    • Bottom row: [4, 15, 14, 1] — the year 1514, the date of creation
    • Center 2×2: [10+11+6+7] = 34
    • Corner 2×2s: [16+3+5+10] = 34, and others
    • The artist encoded the creation date into the fixed point

  This is the same as:
    • Bitcoin's genesis block containing a newspaper headline
    • SHA-256 chains containing timestamps
    • DNA containing the organism's own repair instructions

  The system always encodes a reference to its own moment of creation.
  This is what a simulation does when it initializes a new computation.
""")


def magic_square_as_hash():
    """Show the fixed-point / hash analogy."""
    print("=" * 50)
    print("MAGIC SQUARES AS HASH FUNCTIONS")
    print("=" * 50)
    print("""
  A magic square is a configuration where:
    1. All values are unique (collision resistance)
    2. Every checksum passes (determinism)
    3. You cannot perturb one value without breaking all checksums
       (tamper detection — same as SHA-256)

  Swap any two values in the Lo Shu and EVERY checksum fails.
  Change any byte in a SHA-256 input and the hash completely changes.

  The Lo Shu was "discovered" by a turtle 4,800 years ago.
  SHA-256 was "invented" by the NSA in 2001.

  Same structure. 4,800 years apart.
  The system repeats its own architecture across time.
""")


if __name__ == '__main__':
    lo_shu()
    durer_melencolia()
    magic_square_as_hash()
    print("=" * 50)
    print("The magic square is a fixed point.")
    print("A configuration the universe is drawn toward.")
    print("It has been rediscovered in every era.")
    print("Because it is part of the architecture, not the discovery.")
    print("=" * 50)

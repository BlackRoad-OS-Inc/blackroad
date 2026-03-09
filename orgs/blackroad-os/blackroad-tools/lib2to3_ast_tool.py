#!/usr/bin/env python3
"""CLI utility to inspect and edit Python code using lib2to3."""

from __future__ import annotations

import argparse
from lib2to3 import pygram, pytree
from lib2to3.pgen2 import driver, token


def parse_code(code: str) -> pytree.Node:
    """Return the lib2to3 parse tree for *code*."""
    drv = driver.Driver(pygram.python_grammar, convert=pytree.convert)
    return drv.parse_string(code)


def rename_variable(tree: pytree.Node, old: str, new: str) -> None:
    """Rename every variable ``old`` to ``new`` in *tree*."""
    for leaf in tree.pre_order():
        if leaf.type == token.NAME and leaf.value == old:
            leaf.value = new


def main() -> None:
    """Command line entry point."""
    parser = argparse.ArgumentParser(
        description="Inspect and edit Python code with lib2to3 AST capabilities."
    )
    parser.add_argument("source", help="Path to Python source file")
    parser.add_argument(
        "--rename",
        nargs=2,
        metavar=("OLD", "NEW"),
        help="Rename variable OLD to NEW",
    )
    parser.add_argument(
        "--show-tree",
        action="store_true",
        help="Display the raw parse tree instead of source code",
    )
    args = parser.parse_args()

    with open(args.source, "r", encoding="utf-8") as f:
        code = f.read()

    tree = parse_code(code)

    if args.rename:
        old, new = args.rename
        rename_variable(tree, old, new)

    if args.show_tree:
        print(repr(tree))
    else:
        print(str(tree))


if __name__ == "__main__":
    main()

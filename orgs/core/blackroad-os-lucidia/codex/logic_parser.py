from __future__ import annotations

from dataclasses import dataclass
from typing import List, Union

# A tiny placeholder AST for expressions like: "a AND NOT b"
@dataclass
class Atom:
    name: str

@dataclass
class Not:
    expr: "Expr"

@dataclass
class BinOp:
    op: str
    left: "Expr"
    right: "Expr"

Expr = Union[Atom, Not, BinOp]


def tokenize(s: str) -> List[str]:
    return s.replace("(", " ( ").replace(")", " ) ").split()


def parse(tokens: List[str]) -> Expr:
    """
    Very small, permissive parser:
    grammar ~> expr := term (("AND"|"OR") term)*
             term := "NOT" term | atom | "(" expr ")"
             atom := /[A-Za-z_][A-Za-z0-9_]*/
    """
    pos = 0

    def peek() -> str | None:
        return tokens[pos] if pos < len(tokens) else None

    def eat() -> str:
        nonlocal pos
        tok = tokens[pos]
        pos += 1
        return tok

    def parse_term() -> Expr:
        t = peek()
        if t is None:
            raise ValueError("unexpected end")
        if t == "NOT":
            eat()
            return Not(parse_term())
        if t == "(":
            eat()
            node = parse_expr()
            if eat() != ")":
                raise ValueError("expected ')'")
            return node
        # atom
        return Atom(eat())

    def parse_expr() -> Expr:
        left = parse_term()
        while peek() in ("AND", "OR"):
            op = eat()
            right = parse_term()
            left = BinOp(op, left, right)
        return left

    return parse_expr()

"""Custom symbolic operators for the Lucidia Math Forge.

Three playful operators are provided:

``paradox_merge`` (⊕)
    Combines two values in a way that remembers both sum and difference.
``infinite_fold`` (⊗)
    Repeatedly applies a binary function, emulating an infinite folding.
``collapse`` (↯)
    Reduces a nested structure to a single value.

These operators are intentionally whimsical and serve as examples of how
one might craft new algebraic toys in Python.
"""
from __future__ import annotations

from functools import reduce
from typing import Any, Callable, Iterable, Tuple


def paradox_merge(a: Any, b: Any) -> Tuple[Any, Any]:
    """Paradox merge operator ⊕.

    Returns a tuple of ``(a + b, a - b)``.  The operator is non-
    commutative and non-associative, encouraging exploration of unusual
    algebraic structures.
    """

    try:
        return a + b, a - b
    except TypeError as exc:  # pragma: no cover - demonstration only
        raise TypeError("operands must support + and -") from exc


def infinite_fold(func: Callable[[Any, Any], Any], values: Iterable[Any]) -> Any:
    """Infinite fold operator ⊗.

    Conceptually applies ``func`` across ``values`` endlessly.  In
    practice we simply use :func:`functools.reduce` but expose the idea of
    a never-ending fold.
    """

    return reduce(func, values)


def collapse(value: Any) -> Any:
    """Collapse operator ↯.

    If ``value`` is iterable the items are combined using ``paradox_merge``
    until a single value remains; otherwise it is returned unchanged.
    """

    if isinstance(value, Iterable) and not isinstance(value, (str, bytes)):
        items = list(value)
        if not items:
            return None
        result = items[0]
        for item in items[1:]:
            result = paradox_merge(result, item)[0]
        return result
    return value


if __name__ == "__main__":
    # Example usage of the custom operators.
    print("Paradox merge of 3 and 1:", paradox_merge(3, 1))
    print("Infinite fold sum:", infinite_fold(lambda x, y: x + y, [1, 2, 3, 4]))
    print("Collapse list:", collapse([1, 2, 3]))

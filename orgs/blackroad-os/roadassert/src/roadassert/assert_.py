"""
RoadAssert - Assertion Library for BlackRoad
Fluent assertions with detailed error messages.
"""

from dataclasses import dataclass
from typing import Any, Callable, Dict, List, Optional, Pattern, Type, Union
import re
import logging

logger = logging.getLogger(__name__)


class AssertionError(Exception):
    def __init__(self, message: str, expected: Any = None, actual: Any = None):
        self.expected = expected
        self.actual = actual
        super().__init__(message)


class Assertion:
    def __init__(self, value: Any, name: str = "value"):
        self._value = value
        self._name = name
        self._negated = False

    @property
    def not_(self) -> "Assertion":
        self._negated = True
        return self

    def _check(self, condition: bool, message: str, expected: Any = None) -> "Assertion":
        if self._negated:
            condition = not condition
            message = f"NOT: {message}"

        if not condition:
            raise AssertionError(message, expected=expected, actual=self._value)

        self._negated = False
        return self

    def equals(self, expected: Any) -> "Assertion":
        return self._check(
            self._value == expected,
            f"Expected {self._name} to equal {expected!r}, got {self._value!r}",
            expected
        )

    def is_same(self, expected: Any) -> "Assertion":
        return self._check(
            self._value is expected,
            f"Expected {self._name} to be same object as {expected!r}",
            expected
        )

    def is_true(self) -> "Assertion":
        return self._check(self._value is True, f"Expected {self._name} to be True")

    def is_false(self) -> "Assertion":
        return self._check(self._value is False, f"Expected {self._name} to be False")

    def is_none(self) -> "Assertion":
        return self._check(self._value is None, f"Expected {self._name} to be None")

    def is_not_none(self) -> "Assertion":
        return self._check(self._value is not None, f"Expected {self._name} to not be None")

    def is_instance(self, cls: Type) -> "Assertion":
        return self._check(
            isinstance(self._value, cls),
            f"Expected {self._name} to be instance of {cls.__name__}, got {type(self._value).__name__}"
        )

    def is_type(self, cls: Type) -> "Assertion":
        return self._check(
            type(self._value) is cls,
            f"Expected {self._name} to be type {cls.__name__}, got {type(self._value).__name__}"
        )

    def contains(self, item: Any) -> "Assertion":
        return self._check(
            item in self._value,
            f"Expected {self._name} to contain {item!r}"
        )

    def has_length(self, length: int) -> "Assertion":
        actual_len = len(self._value)
        return self._check(
            actual_len == length,
            f"Expected {self._name} to have length {length}, got {actual_len}"
        )

    def is_empty(self) -> "Assertion":
        return self._check(len(self._value) == 0, f"Expected {self._name} to be empty")

    def is_not_empty(self) -> "Assertion":
        return self._check(len(self._value) > 0, f"Expected {self._name} to not be empty")

    def is_greater_than(self, other: Any) -> "Assertion":
        return self._check(self._value > other, f"Expected {self._name} > {other}")

    def is_less_than(self, other: Any) -> "Assertion":
        return self._check(self._value < other, f"Expected {self._name} < {other}")

    def is_between(self, low: Any, high: Any) -> "Assertion":
        return self._check(
            low <= self._value <= high,
            f"Expected {low} <= {self._name} <= {high}, got {self._value}"
        )

    def matches(self, pattern: Union[str, Pattern]) -> "Assertion":
        if isinstance(pattern, str):
            pattern = re.compile(pattern)
        return self._check(
            pattern.match(str(self._value)) is not None,
            f"Expected {self._name} to match {pattern.pattern!r}"
        )

    def starts_with(self, prefix: str) -> "Assertion":
        return self._check(
            str(self._value).startswith(prefix),
            f"Expected {self._name} to start with {prefix!r}"
        )

    def ends_with(self, suffix: str) -> "Assertion":
        return self._check(
            str(self._value).endswith(suffix),
            f"Expected {self._name} to end with {suffix!r}"
        )

    def has_key(self, key: Any) -> "Assertion":
        return self._check(key in self._value, f"Expected {self._name} to have key {key!r}")

    def has_value(self, value: Any) -> "Assertion":
        return self._check(
            value in self._value.values(),
            f"Expected {self._name} to have value {value!r}"
        )

    def all_match(self, predicate: Callable[[Any], bool]) -> "Assertion":
        return self._check(
            all(predicate(x) for x in self._value),
            f"Expected all items in {self._name} to match predicate"
        )

    def any_match(self, predicate: Callable[[Any], bool]) -> "Assertion":
        return self._check(
            any(predicate(x) for x in self._value),
            f"Expected any item in {self._name} to match predicate"
        )

    def raises(self, exception: Type[Exception] = Exception) -> "Assertion":
        if not callable(self._value):
            raise TypeError("Value must be callable for raises assertion")

        try:
            self._value()
            raise AssertionError(f"Expected {self._name} to raise {exception.__name__}")
        except exception:
            return self
        except Exception as e:
            raise AssertionError(f"Expected {exception.__name__}, got {type(e).__name__}: {e}")

    def returns(self, expected: Any) -> "Assertion":
        if not callable(self._value):
            raise TypeError("Value must be callable for returns assertion")

        result = self._value()
        return self._check(
            result == expected,
            f"Expected {self._name} to return {expected!r}, got {result!r}"
        )


def expect(value: Any, name: str = "value") -> Assertion:
    return Assertion(value, name)


def assert_equals(actual: Any, expected: Any, message: str = "") -> None:
    if actual != expected:
        msg = message or f"Expected {expected!r}, got {actual!r}"
        raise AssertionError(msg, expected, actual)


def assert_true(value: Any, message: str = "") -> None:
    if not value:
        raise AssertionError(message or "Expected True")


def assert_false(value: Any, message: str = "") -> None:
    if value:
        raise AssertionError(message or "Expected False")


def assert_none(value: Any, message: str = "") -> None:
    if value is not None:
        raise AssertionError(message or f"Expected None, got {value!r}")


def assert_raises(exception: Type[Exception], func: Callable, *args, **kwargs) -> Exception:
    try:
        func(*args, **kwargs)
        raise AssertionError(f"Expected {exception.__name__} to be raised")
    except exception as e:
        return e


def example_usage():
    expect(5).equals(5)
    expect(10).is_greater_than(5)
    expect("hello").starts_with("he")
    expect([1, 2, 3]).contains(2).has_length(3)
    expect({"a": 1}).has_key("a")
    expect(None).is_none()
    expect(5).not_.equals(10)
    expect([1, 2, 3]).all_match(lambda x: x > 0)

    def divide_by_zero():
        return 1 / 0
    expect(divide_by_zero).raises(ZeroDivisionError)

    print("All assertions passed!")

    try:
        expect(5).equals(10)
    except AssertionError as e:
        print(f"\nCaught expected error: {e}")

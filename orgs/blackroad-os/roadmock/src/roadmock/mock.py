"""
RoadMock - Mocking Framework for BlackRoad
Create mock objects and patch functions.
"""

from dataclasses import dataclass
from typing import Any, Callable, Dict, List, Optional
import functools
import logging

logger = logging.getLogger(__name__)


@dataclass
class Call:
    args: tuple
    kwargs: dict
    return_value: Any = None


class Mock:
    def __init__(self, name: str = "mock", return_value: Any = None, side_effect: Any = None):
        self._name = name
        self._return_value = return_value
        self._side_effect = side_effect
        self._calls: List[Call] = []
        self._children: Dict[str, "Mock"] = {}

    def __call__(self, *args, **kwargs) -> Any:
        call = Call(args=args, kwargs=kwargs)
        self._calls.append(call)
        if self._side_effect is not None:
            if isinstance(self._side_effect, Exception):
                raise self._side_effect
            if callable(self._side_effect):
                return self._side_effect(*args, **kwargs)
            if isinstance(self._side_effect, list) and len(self._calls) <= len(self._side_effect):
                return self._side_effect[len(self._calls) - 1]
        call.return_value = self._return_value
        return self._return_value

    def __getattr__(self, name: str) -> "Mock":
        if name.startswith("_"):
            raise AttributeError(name)
        if name not in self._children:
            self._children[name] = Mock(name=f"{self._name}.{name}")
        return self._children[name]

    @property
    def called(self) -> bool:
        return len(self._calls) > 0

    @property
    def call_count(self) -> int:
        return len(self._calls)

    @property
    def call_args(self) -> Optional[Call]:
        return self._calls[-1] if self._calls else None

    def assert_called(self) -> None:
        if not self.called:
            raise AssertionError(f"{self._name} was not called")

    def assert_called_once(self) -> None:
        if self.call_count != 1:
            raise AssertionError(f"{self._name} was called {self.call_count} times")

    def assert_called_with(self, *args, **kwargs) -> None:
        if not self.called:
            raise AssertionError(f"{self._name} was not called")
        last = self._calls[-1]
        if last.args != args or last.kwargs != kwargs:
            raise AssertionError(f"Expected ({args}, {kwargs}), got ({last.args}, {last.kwargs})")

    def reset_mock(self) -> None:
        self._calls.clear()
        for child in self._children.values():
            child.reset_mock()


class MagicMock(Mock):
    def __repr__(self) -> str:
        return f"<MagicMock name="{self._name}">"

    def __iter__(self):
        return iter([])

    def __len__(self) -> int:
        return 0

    def __bool__(self) -> bool:
        return True


class Patch:
    def __init__(self, target: str, new: Any = None, **kwargs):
        self.target = target
        self.new = new if new is not None else Mock(**kwargs)
        self._original = None
        self._obj = None
        self._attr = None

    def _get_target(self) -> tuple:
        parts = self.target.rsplit(".", 1)
        if len(parts) == 2:
            module_path, attr = parts
            module = __import__(module_path, fromlist=[attr])
            return module, attr
        raise ValueError(f"Invalid target: {self.target}")

    def start(self) -> Mock:
        self._obj, self._attr = self._get_target()
        self._original = getattr(self._obj, self._attr)
        setattr(self._obj, self._attr, self.new)
        return self.new

    def stop(self) -> None:
        if self._obj and self._attr:
            setattr(self._obj, self._attr, self._original)

    def __enter__(self) -> Mock:
        return self.start()

    def __exit__(self, *args) -> None:
        self.stop()


def patch(target: str, new: Any = None, **kwargs) -> Patch:
    return Patch(target, new, **kwargs)


def example_usage():
    mock = Mock(return_value=42)
    result = mock(1, 2, key="value")
    print(f"Result: {result}")
    print(f"Called: {mock.called}")
    mock.assert_called_with(1, 2, key="value")

    api = MagicMock()
    api.users.get.return_value = {"id": 1, "name": "Alice"}
    user = api.users.get(1)
    print(f"User: {user}")

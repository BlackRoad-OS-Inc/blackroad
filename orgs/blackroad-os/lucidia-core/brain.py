"""Core cognitive primitives for Lucidia.

This module defines a tiny `LucidiaBrain` class that can register named
processing steps and execute them sequentially. Steps may later be
introspected, unregistered, or the entire pipeline reset. It acts as a
very small placeholder for more sophisticated reasoning engines.
This module defines a tiny :class:`LucidiaBrain` class that can register
processing steps and execute them sequentially. Steps may be given unique
names so they can later be inspected, removed, or replaced. Attempting to
reuse a step name raises :class:`ValueError`, clarifying how named steps are
managed. The class acts as a very small placeholder for more sophisticated
reasoning engines.
"""
from __future__ import annotations

from collections.abc import Callable
from typing import Any, List, Tuple


class LucidiaBrain:
    """Simple pipeline-based brain for Lucidia.

    Functions registered via :meth:`register` are called in the order they
    were added when :meth:`think` is invoked. Each function receives the
    current value and returns the next value. Steps can be named to allow
    subsequent removal or inspection.
    were added when :meth:`think` is invoked. Each step has a unique name,
    allowing introspection via :attr:`steps` as well as selective removal
    with :meth:`unregister` or clearing with :meth:`reset`.
    """

    def __init__(self) -> None:
        self._steps: List[Tuple[str, Callable[[Any], Any]]] = []

    def register(self, func: Callable[[Any], Any], *, name: str | None = None) -> None:
        """Register a processing step.

        Parameters
        ----------
        func:
            A callable that accepts a single argument and returns the
            transformed value.
        name:
            Optional unique identifier for the step. If omitted the
            function's ``__name__`` attribute is used.

        Raises
        ------
        ValueError
            If a step with the same ``name`` is already registered.
        """

        if name is None:
            name = getattr(func, "__name__", repr(func))
        if any(step_name == name for step_name, _ in self._steps):
            raise ValueError(f"Step '{name}' already exists")
        self._steps.append((name, func))

    def unregister(self, name: str) -> None:
        """Remove the step identified by ``name``.

        Raises
        ------
        KeyError
            If no step with the given name is registered.
        """

        for i, (step_name, _) in enumerate(self._steps):
            if step_name == name:
                del self._steps[i]
                return
        raise KeyError(f"No step named '{name}'")

    @property
    def steps(self) -> List[str]:
        """Return the names of registered steps in execution order."""

        return [name for name, _ in self._steps]

    def reset(self) -> None:
        """Remove all registered steps."""

        self._steps.clear()

    def think(self, value: Any) -> Any:
        """Run the registered steps on ``value``.

        Parameters
        ----------
        value:
            Initial input to the pipeline.

        Returns
        -------
        Any
            The result after all steps have been applied.
        """

        for _, step in self._steps:
            value = step(value)
        return value

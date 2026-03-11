"""Tests for the LucidiaBrain pipeline."""

from __future__ import annotations

import pytest

from brain import LucidiaBrain


class TestLucidiaBrain:
    """Exercise LucidiaBrain registration, execution, and removal."""

    def test_register_and_think(self):
        brain = LucidiaBrain()
        brain.register(lambda x: x + 1, name="inc")
        assert brain.think(0) == 1

    def test_pipeline_order(self):
        brain = LucidiaBrain()
        brain.register(lambda x: x * 2, name="double")
        brain.register(lambda x: x + 10, name="add10")
        # (5 * 2) + 10 = 20
        assert brain.think(5) == 20

    def test_steps_property(self):
        brain = LucidiaBrain()
        brain.register(lambda x: x, name="a")
        brain.register(lambda x: x, name="b")
        assert brain.steps == ["a", "b"]

    def test_duplicate_name_raises(self):
        brain = LucidiaBrain()
        brain.register(lambda x: x, name="dup")
        with pytest.raises(ValueError, match="already exists"):
            brain.register(lambda x: x, name="dup")

    def test_unregister(self):
        brain = LucidiaBrain()
        brain.register(lambda x: x + 1, name="inc")
        brain.unregister("inc")
        assert brain.steps == []
        # Without any steps the value passes through unchanged.
        assert brain.think(42) == 42

    def test_unregister_missing_raises(self):
        brain = LucidiaBrain()
        with pytest.raises(KeyError, match="no_such"):
            brain.unregister("no_such")

    def test_reset(self):
        brain = LucidiaBrain()
        brain.register(lambda x: x, name="a")
        brain.register(lambda x: x, name="b")
        brain.reset()
        assert brain.steps == []

    def test_think_empty_pipeline(self):
        brain = LucidiaBrain()
        assert brain.think("hello") == "hello"

    def test_auto_name_from_function(self):
        """When no name is given, the function's __name__ is used."""
        brain = LucidiaBrain()

        def my_step(x):
            return x

        brain.register(my_step)
        assert brain.steps == ["my_step"]

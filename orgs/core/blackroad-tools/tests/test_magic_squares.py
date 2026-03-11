"""Tests for magic.magic_squares — generation and validation."""

import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from magic.magic_squares import (
    generate_magic_square,
    summarise,
    MagicSquareSummary,
)


class TestGenerateMagicSquare:
    def test_order_1(self):
        sq = generate_magic_square(1)
        assert sq == [[1]]

    def test_order_3(self):
        sq = generate_magic_square(3)
        summary = summarise(sq)
        assert summary.is_magic
        assert summary.magic_constant == 15

    def test_order_5(self):
        sq = generate_magic_square(5)
        summary = summarise(sq)
        assert summary.is_magic
        assert summary.magic_constant == 65

    def test_order_7(self):
        sq = generate_magic_square(7)
        summary = summarise(sq)
        assert summary.is_magic

    def test_order_4_doubly_even(self):
        sq = generate_magic_square(4)
        summary = summarise(sq)
        assert summary.is_magic
        assert summary.magic_constant == 34

    def test_order_8_doubly_even(self):
        sq = generate_magic_square(8)
        summary = summarise(sq)
        assert summary.is_magic

    def test_singly_even_raises(self):
        with pytest.raises(NotImplementedError):
            generate_magic_square(6)

    def test_zero_order_raises(self):
        with pytest.raises(ValueError):
            generate_magic_square(0)

    def test_negative_order_raises(self):
        with pytest.raises(ValueError):
            generate_magic_square(-1)


class TestSummarise:
    def test_summary_fields(self):
        sq = generate_magic_square(3)
        s = summarise(sq)
        assert s.order == 3
        assert len(s.row_sums) == 3
        assert len(s.column_sums) == 3
        assert len(s.diagonal_sums) == 2

    def test_to_json(self):
        sq = generate_magic_square(3)
        s = summarise(sq)
        import json
        data = json.loads(s.to_json())
        assert data["is_magic"] is True
        assert data["n"] == 3

    def test_non_square_raises(self):
        with pytest.raises(ValueError):
            summarise([[1, 2], [3]])

    def test_empty_raises(self):
        with pytest.raises(ValueError):
            summarise([])

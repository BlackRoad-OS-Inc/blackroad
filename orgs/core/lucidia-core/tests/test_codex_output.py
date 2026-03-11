"""Tests for the codex_output helper module."""

from __future__ import annotations

import os
import tempfile
from pathlib import Path

from codex_output import HEADER_TEMPLATE, append_to_file, create_text_file, write_file_with_header


class TestWriteFileWithHeader:

    def test_creates_file_with_header(self, tmp_path):
        target = str(tmp_path / "out.html")
        write_file_with_header(target, "<h1>Hello</h1>")
        content = Path(target).read_text()
        assert content.startswith("<!-- FILE:")
        assert "<h1>Hello</h1>" in content

    def test_creates_nested_dirs(self, tmp_path):
        target = str(tmp_path / "a" / "b" / "c.txt")
        write_file_with_header(target, "deep")
        assert Path(target).exists()

    def test_create_text_file_alias(self, tmp_path):
        target = str(tmp_path / "new.txt")
        create_text_file(target, "content here")
        content = Path(target).read_text()
        assert "content here" in content

    def test_append_creates_if_missing(self, tmp_path):
        target = str(tmp_path / "missing.txt")
        append_to_file(target, "first")
        content = Path(target).read_text()
        assert "first" in content

    def test_append_to_existing(self, tmp_path):
        target = str(tmp_path / "existing.txt")
        Path(target).write_text("original\n")
        append_to_file(target, "appended")
        content = Path(target).read_text()
        assert "original" in content
        assert "appended" in content

#!/usr/bin/env python3
"""
Codex Output Helper

This module provides convenience functions to write files that embed HTML
comment-based path metadata. It is designed for the Lucidia build process,
allowing agents to emit nano-ready files with uniform header metadata.
"""

import os
from pathlib import Path

HEADER_TEMPLATE = "<!-- FILE: {path} -->\n"


def write_file_with_header(target_path: str, content: str, mode: str = "w") -> None:
    """
    Write `content` to `target_path` preceded by an HTML comment header.

    :param target_path: Filesystem path to write to.
    :param content: Content to write after the header.
    :param mode: File open mode ("w" or "a").
    """
    path = Path(target_path).resolve()
    os.makedirs(path.parent, exist_ok=True)
    header = HEADER_TEMPLATE.format(path=path)
    data = header + content
    with open(path, mode, encoding="utf-8") as f:
        f.write(data)


def create_text_file(path: str, content: str) -> None:
    """Alias for write_file_with_header, emphasising new file creation."""
    write_file_with_header(path, content, mode="w")


def append_to_file(path: str, content: str) -> None:
    """Append `content` to `path`, including header if file did not exist."""
    if Path(path).exists():
        with open(path, "a", encoding="utf-8") as f:
            f.write(content)
    else:
        write_file_with_header(path, content, mode="w")

"""Local snapshot/restore utility."""
from __future__ import annotations

import shutil
from pathlib import Path

DATA_DIR = Path("data")


def snapshot(dest_dir: str | Path) -> Path:
    dest = Path(dest_dir)
    dest.mkdir(parents=True, exist_ok=True)
    target = dest / "data"
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(DATA_DIR, target)
    return target


def restore(src_dir: str | Path) -> None:
    src = Path(src_dir) / "data"
    if not src.exists():
        raise FileNotFoundError(src)
    if DATA_DIR.exists():
        shutil.rmtree(DATA_DIR)
    shutil.copytree(src, DATA_DIR)

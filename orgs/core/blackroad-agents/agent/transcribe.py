"""Temporary storage helpers for uploaded audio."""

from __future__ import annotations

import os
import secrets
from pathlib import Path
from typing import BinaryIO


TMP_DIR = Path(os.environ.get("BLACKROAD_TRANSCRIBE_TMP", "/tmp/blackroad-transcribe"))
TMP_DIR.mkdir(parents=True, exist_ok=True)


def _token(suffix: str | None = None) -> str:
    body = secrets.token_hex(16)
    if suffix:
        suffix = suffix if suffix.startswith(".") else f".{suffix}"
        return f"{body}{suffix}"
    return body


def allocate_path(filename: str | None = None) -> Path:
    """Return an absolute path under :data:`TMP_DIR` for the upload."""

    suffix = None
    if filename:
        suffix = Path(filename).suffix
    return (TMP_DIR / _token(suffix)).resolve()


def write_temp(stream: BinaryIO, filename: str | None = None) -> Path:
    """Persist *stream* to disk and return the resolved path."""

    dest = allocate_path(filename)
    with open(dest, "wb") as fh:
        while True:
            chunk = stream.read(1024 * 1024)
            if not chunk:
                break
            fh.write(chunk)
    return dest


__all__ = ["TMP_DIR", "allocate_path", "write_temp"]

"""Local file management for transcription uploads."""
from __future__ import annotations

import os
from pathlib import Path

_DEFAULT_TMP = Path(os.getenv("BLACKROAD_TRANSCRIBE_TMP", "/tmp/blackroad_transcribe"))
TMP_DIR = _DEFAULT_TMP
TMP_DIR.mkdir(parents=True, exist_ok=True)

__all__ = ["TMP_DIR"]
"""Helpers for handling Whisper streaming transcription."""
"""Local wrapper for whisper.cpp transcription."""

from __future__ import annotations

import pathlib
import shutil
import subprocess
import tempfile
from typing import Iterable

TMP_DIR = pathlib.Path("/tmp/blackroad_whisper")
TMP_DIR.mkdir(parents=True, exist_ok=True)


def save_upload(data: bytes, suffix: str = ".wav") -> str:
    """Persist uploaded ``data`` to a temporary file and return its path."""

    with tempfile.NamedTemporaryFile(delete=False, dir=TMP_DIR, suffix=suffix) as handle:
        handle.write(data)
        return handle.name


def run_whisper_stream(
    audio_path: str,
    *,
    model_path: str | None = None,
    lang: str = "en",
) -> Iterable[str]:
    """Invoke ``whisper.cpp`` and yield decoded lines as they stream."""

    exe = shutil.which("whisper") or shutil.which("main")
    if not exe:
        yield "[error] whisper.cpp binary not found"
        return

    resolved_model = model_path or "/var/lib/blackroad/models/ggml-base.en.bin"
    cmd = [exe, "-m", resolved_model, "-l", lang, audio_path]

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    try:
        if proc.stdout is None:
            yield "[error] failed to capture whisper output"
            return

        for line in proc.stdout:
            yield line.rstrip("\n")
    finally:
        if proc.stdout is not None:
            proc.stdout.close()
        proc.wait()


def run_whisper(audio_path: str, model_path: str | None = None, lang: str = "en") -> str:
    """Run whisper.cpp binary against the provided audio file."""
    exe = shutil.which("whisper") or shutil.which("main")  # adjust to your whisper.cpp binary
    if not exe:
        return "[error] whisper.cpp binary not found"

    audio_file = pathlib.Path(audio_path).expanduser()
    if not audio_file.exists():
        return "[error] audio file not found"

    model_path = model_path or "/var/lib/blackroad/models/ggml-base.en.bin"
    cmd = [exe, "-m", model_path, "-l", lang, str(audio_file)]

    try:
        out = subprocess.check_output(
            cmd,
            text=True,
            stderr=subprocess.STDOUT,
            cwd=tempfile.gettempdir(),
        )
        return out
    except subprocess.CalledProcessError as exc:  # pragma: no cover - passthrough error text
        return f"[error] {exc.output}"

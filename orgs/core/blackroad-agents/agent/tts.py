"""Simple text-to-speech helpers for the BlackRoad console."""

from __future__ import annotations

import pathlib
import shutil
import subprocess
import uuid

OUT_DIR = pathlib.Path("/tmp/blackroad_tts")
OUT_DIR.mkdir(parents=True, exist_ok=True)


def say_to_wav(text: str, voice: str | None = None) -> str:
    """Render ``text`` to a WAV file using Piper if available, else espeak-ng."""

    if not text:
        raise ValueError("text must be non-empty")

    wav = OUT_DIR / f"tts_{uuid.uuid4().hex[:8]}.wav"

    piper = shutil.which("piper")
    if piper:
        voice = voice or "/usr/share/piper/en_US-amy-low.onnx"
        cmd = [piper, "-m", voice, "-f", str(wav)]
        proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, text=True)
        try:
            proc.communicate(text, timeout=60)
        finally:
            if proc.poll() is None:
                proc.kill()
        if proc.returncode != 0:
            raise RuntimeError("piper failed")
        return str(wav)

    espeak = shutil.which("espeak-ng") or shutil.which("espeak")
    if espeak:
        cmd = [espeak, "-w", str(wav), text]
        subprocess.check_call(cmd)
        return str(wav)

    raise RuntimeError("No TTS engine found (install piper or espeak-ng)")


__all__ = ["say_to_wav"]

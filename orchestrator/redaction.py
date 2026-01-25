"""PII redaction utilities."""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass
from typing import Any, Dict, Mapping, Sequence

from orchestrator.exceptions import RedactionError

EMAIL_PATTERN = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
PHONE_PATTERN = re.compile(r"\+?[0-9][0-9\-]{8,}[0-9]")


@dataclass(slots=True)
class RedactionStats:
    """Summary of redaction operations."""

    emails: int = 0
    phones: int = 0


def _tokenise(value: str, token_type: str) -> str:
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:8]
    return f"{{{{REDACTED:{token_type}:{digest}}}}}"


def redact_text(text: str) -> tuple[str, RedactionStats]:
    """Redact known PII tokens within text."""

    stats = RedactionStats()
    if EMAIL_PATTERN.search(text):
        matches = EMAIL_PATTERN.findall(text)
        for match in matches:
            text = text.replace(match, _tokenise(match, "email"))
            stats.emails += 1
    if PHONE_PATTERN.search(text):
        matches = PHONE_PATTERN.findall(text)
        for match in matches:
            text = text.replace(match, _tokenise(match, "phone"))
            stats.phones += 1
    return text, stats


def redact_payload(payload: Any) -> Any:
    """Recursively redact PII from a JSON-serialisable payload."""

    if isinstance(payload, str):
        redacted, _ = redact_text(payload)
        return redacted
    if isinstance(payload, Mapping):
        return {key: redact_payload(value) for key, value in payload.items()}
    if isinstance(payload, Sequence) and not isinstance(payload, (bytes, bytearray)):
        return [redact_payload(item) for item in payload]
    return payload


def ensure_redacted(payload: Mapping[str, Any]) -> Dict[str, Any]:
    """Return a redacted copy of *payload* or raise if redaction fails."""

    try:
        return {key: redact_payload(value) for key, value in payload.items()}
    except Exception as exc:  # noqa: BLE001
        raise RedactionError("Unable to redact payload") from exc

"""Audit trail management for task execution."""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
from datetime import datetime
from pathlib import Path
from typing import Iterator, Optional

from orchestrator.consent import ConsentRegistry
from orchestrator.exceptions import MemoryWriteError
from orchestrator.protocols import BotResponse, MemoryRecord, Task
from orchestrator.redaction import ensure_redacted

DEFAULT_MEMORY_PATH = Path("memory.jsonl")
DEFAULT_SIGNING_KEY = "development-signing-key"


def _load_signing_key() -> bytes:
    key = os.environ.get("PRISM_SIGNING_KEY", DEFAULT_SIGNING_KEY)
    return key.encode("utf-8")


def _hash_payload(payload: str, previous_hash: Optional[str]) -> str:
    digest = hashlib.sha256()
    if previous_hash:
        digest.update(previous_hash.encode("utf-8"))
    digest.update(payload.encode("utf-8"))
    return digest.hexdigest()


def _sign_payload(payload: str, key: bytes) -> str:
    signature = hmac.new(key, payload.encode("utf-8"), hashlib.sha256).digest()
    return base64.b64encode(signature).decode("utf-8")


def _iter_memory(path: Path) -> Iterator[dict[str, object]]:
    if not path.exists():
        yield from ()
        return
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            yield json.loads(line)


class MemoryLog:
    """Append-only log that stores orchestrator activity."""

    def __init__(self, path: Path = DEFAULT_MEMORY_PATH) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)

    def append(self, task: Task, bot_name: str, response: BotResponse) -> MemoryRecord:
        """Append a new record to the log and return it."""

        try:
            owner = task.owner or "system"
            ConsentRegistry.get_default().check_consent(
                from_agent=owner,
                to_agent=bot_name,
                consent_type="data_access",
                scope=(f"task:{task.id}", "memory"),
            )
            previous_entry = None
            for previous_entry in _iter_memory(self.path):
                pass
            previous_hash = previous_entry.get("hash") if previous_entry else None

            payload = {
                "task": ensure_redacted(task.to_dict()),
                "bot": bot_name,
                "response": ensure_redacted(response.to_dict()),
            }
            payload_json = json.dumps(payload, sort_keys=True)
            content_hash = _hash_payload(payload_json, previous_hash)
            signature = _sign_payload(payload_json, _load_signing_key())

            record = MemoryRecord(
                timestamp=datetime.utcnow(),
                task=task,
                bot=bot_name,
                response=response,
                signature=signature,
                previous_hash=previous_hash,
                hash=content_hash,
            )

            with self.path.open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(record.to_dict()) + "\n")

            return record
        except Exception as exc:  # noqa: BLE001
            raise MemoryWriteError("Unable to append memory record") from exc

    def tail(self, limit: int = 10) -> list[dict[str, object]]:
        """Return the most recent *limit* entries."""

        entries = list(_iter_memory(self.path))
        return entries[-limit:]

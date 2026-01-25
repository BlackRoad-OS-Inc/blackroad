"""Consent request/approval primitives used by the orchestrator stack."""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import re
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from enum import Enum
from fnmatch import fnmatch
from pathlib import Path
from threading import RLock
from typing import Dict, Iterable, Iterator, Mapping, Sequence
from uuid import uuid4

from orchestrator.exceptions import ConsentError

DEFAULT_CONSENT_LOG_PATH = Path("orchestrator/consent.jsonl")
DEFAULT_SIGNING_KEY = "development-consent-signing-key"


class ConsentType(str, Enum):
    """Consent categories the orchestrator understands."""

    DATA_ACCESS = "data_access"
    TASK_ASSIGNMENT = "task_assignment"
    REPRESENTATION = "representation"
    COLLABORATION = "collaboration"
    ATTRIBUTION = "attribution"
    LEARNING = "learning"


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _ensure_utc(moment: datetime | None) -> datetime | None:
    if moment is None:
        return None
    if moment.tzinfo is None:
        return moment.replace(tzinfo=timezone.utc)
    return moment.astimezone(timezone.utc)


def _normalise_scope(scope: str | Sequence[str] | None) -> tuple[str, ...]:
    if scope is None:
        return tuple()
    if isinstance(scope, str):
        scope = (scope,)
    return tuple(str(entry).strip() for entry in scope if str(entry).strip())


_DURATION_PATTERN = re.compile(r"(?P<value>\d+)(?P<unit>[smhdw])", re.IGNORECASE)
_DURATION_FACTORS = {"s": 1, "m": 60, "h": 3600, "d": 86400, "w": 604800}


def _parse_duration(value: str | timedelta | None) -> timedelta | None:
    if value is None:
        return None
    if isinstance(value, timedelta):
        return value
    seconds = 0
    for match in _DURATION_PATTERN.finditer(value.strip().lower()):
        seconds += int(match.group("value")) * _DURATION_FACTORS[match.group("unit")]
    if seconds == 0:
        raise ValueError(f"invalid duration: {value!r}")
    return timedelta(seconds=seconds)


def _format_duration(duration: timedelta | None) -> str | None:
    if duration is None:
        return None
    remaining = int(duration.total_seconds())
    pieces: list[str] = []
    for unit, factor in (("w", 604800), ("d", 86400), ("h", 3600), ("m", 60), ("s", 1)):
        if remaining >= factor:
            value, remaining = divmod(remaining, factor)
            if value:
                pieces.append(f"{value}{unit}")
    return "".join(pieces) or "0s"


def _ps_shainfty(data: str) -> str:
    payload = data.encode("utf-8")
    sha3 = hashlib.sha3_512(payload).digest()
    sha2 = hashlib.sha512(sha3 + payload).digest()
    blake = hashlib.blake2b(sha2 + sha3, digest_size=32).digest()
    combined = sha3 + sha2 + blake
    return base64.urlsafe_b64encode(combined).decode("ascii").rstrip("=")


def _serialise_payload(payload: Mapping[str, object]) -> str:
    return json.dumps(payload, sort_keys=True, separators=(",", ":"))


@dataclass(slots=True)
class ConsentRequest:
    """Structured payload describing a consent negotiation."""

    from_agent: str
    to_agent: str
    consent_type: ConsentType | str
    purpose: str
    duration: str | timedelta | None = None
    scope: str | Sequence[str] | None = None
    created_at: datetime = field(default_factory=_utcnow)
    request_id: str = field(default_factory=lambda: f"req_{uuid4().hex}"[:16])
    signature: str = field(init=False)

    def __post_init__(self) -> None:
        if not isinstance(self.consent_type, ConsentType):
            self.consent_type = ConsentType(str(self.consent_type))
        self.from_agent = self.from_agent.strip()
        self.to_agent = self.to_agent.strip()
        self.purpose = self.purpose.strip()
        self.duration = _parse_duration(self.duration)
        self.scope = _normalise_scope(self.scope)
        self.created_at = _ensure_utc(self.created_at) or _utcnow()
        self.signature = self._compute_signature()

    def _compute_signature(self) -> str:
        payload = {
            "created_at": self.created_at.isoformat(),
            "from": self.from_agent,
            "to": self.to_agent,
            "type": self.consent_type.value,
            "purpose": self.purpose,
            "duration": _format_duration(self.duration),
            "scope": list(self.scope),
        }
        return _ps_shainfty(_serialise_payload(payload))

    def to_dict(self) -> dict[str, object]:
        return {
            "request_id": self.request_id,
            "from_agent": self.from_agent,
            "to_agent": self.to_agent,
            "consent_type": self.consent_type.value,
            "purpose": self.purpose,
            "duration": _format_duration(self.duration),
            "scope": list(self.scope),
            "created_at": self.created_at.isoformat(),
            "signature": self.signature,
        }

    def to_natural_language(self) -> str:
        scope_text = ", ".join(self.scope) if self.scope else "defined scope"
        duration_text = (
            f"for {_format_duration(self.duration)}"
            if self.duration is not None
            else "until revoked"
        )
        return (
            f"{self.from_agent} requests {self.consent_type.value} consent from {self.to_agent} "
            f"to {self.purpose} within {scope_text} {duration_text}."
        )

    @classmethod
    def from_dict(cls, payload: Mapping[str, object]) -> "ConsentRequest":
        duration = payload.get("duration")
        created_raw = payload.get("created_at") or payload.get("timestamp")
        created_at = (
            datetime.fromisoformat(str(created_raw)) if created_raw else _utcnow()
        )
        scope = payload.get("scope") or ()
        return cls(
            request_id=str(payload.get("request_id", f"req_{uuid4().hex}"[:16])),
            from_agent=str(payload["from_agent"]),
            to_agent=str(payload["to_agent"]),
            consent_type=payload.get("consent_type", ConsentType.TASK_ASSIGNMENT),
            purpose=str(payload.get("purpose", "")),
            duration=duration,
            scope=scope,
            created_at=_ensure_utc(created_at) or _utcnow(),
        )


@dataclass(slots=True)
class ConsentGrant:
    """Represents an approved consent request."""

    request_id: str
    granted_by: str
    granted_to: str
    consent_type: ConsentType | str
    scope: str | Sequence[str] | None
    conditions: Iterable[str] = field(default_factory=tuple)
    expires_at: datetime | None = None
    revocable: bool = True
    granted_at: datetime = field(default_factory=_utcnow)
    grant_id: str = field(default_factory=lambda: f"grant_{uuid4().hex}"[:18])
    revoked_at: datetime | None = None
    revoked_by: str | None = None
    revocation_reason: str | None = None

    def __post_init__(self) -> None:
        if not isinstance(self.consent_type, ConsentType):
            self.consent_type = ConsentType(str(self.consent_type))
        self.scope = _normalise_scope(self.scope)
        self.conditions = tuple(self.conditions)
        self.granted_by = self.granted_by.strip()
        self.granted_to = self.granted_to.strip()
        self.granted_at = _ensure_utc(self.granted_at) or _utcnow()
        self.expires_at = _ensure_utc(self.expires_at)
        self.revoked_at = _ensure_utc(self.revoked_at)

    def is_valid(self, moment: datetime | None = None) -> bool:
        if self.revoked_at is not None:
            return False
        moment = _ensure_utc(moment) or _utcnow()
        if self.expires_at is None:
            return True
        return moment <= self.expires_at

    def can_revoke(self) -> bool:
        return self.revocable and self.revoked_at is None

    def matches(self, from_agent: str, to_agent: str, consent_type: str | ConsentType) -> bool:
        if isinstance(consent_type, ConsentType):
            type_value = consent_type.value
        else:
            type_value = consent_type
        type_matches = self.consent_type.value == type_value
        from_matches = self.granted_to in {from_agent, "*"} or from_agent == "*"
        to_matches = self.granted_by in {to_agent, "*"} or to_agent == "*"
        return from_matches and to_matches and type_matches

    def scope_includes(self, required: Sequence[str]) -> bool:
        if not required or "*" in self.scope:
            return True
        patterns = tuple(self.scope)
        for candidate in required:
            candidate_options = {candidate}
            if ":" in candidate:
                candidate_options.add(candidate.split(":", 1)[1])
            if not any(
                fnmatch(option, pattern) or fnmatch(pattern, option)
                for option in candidate_options
                for pattern in patterns
            ):
                return False
        return True

    def to_dict(self) -> dict[str, object]:
        payload: dict[str, object] = {
            "grant_id": self.grant_id,
            "request_id": self.request_id,
            "granted_by": self.granted_by,
            "granted_to": self.granted_to,
            "consent_type": self.consent_type.value,
            "scope": list(self.scope),
            "conditions": list(self.conditions),
            "revocable": self.revocable,
            "granted_at": self.granted_at.isoformat(),
        }
        if self.expires_at is not None:
            payload["expires_at"] = self.expires_at.isoformat()
        if self.revoked_at is not None:
            payload["revoked_at"] = self.revoked_at.isoformat()
        if self.revoked_by is not None:
            payload["revoked_by"] = self.revoked_by
        if self.revocation_reason is not None:
            payload["revocation_reason"] = self.revocation_reason
        return payload

    @classmethod
    def from_dict(cls, payload: Mapping[str, object]) -> "ConsentGrant":
        granted_at = payload.get("granted_at")
        expires_at = payload.get("expires_at")
        revoked_at = payload.get("revoked_at")
        return cls(
            grant_id=str(payload.get("grant_id", f"grant_{uuid4().hex}"[:18])),
            request_id=str(payload["request_id"]),
            granted_by=str(payload["granted_by"]),
            granted_to=str(payload["granted_to"]),
            consent_type=payload.get("consent_type", ConsentType.TASK_ASSIGNMENT),
            scope=payload.get("scope"),
            conditions=payload.get("conditions", ()),
            expires_at=(
                datetime.fromisoformat(str(expires_at)) if isinstance(expires_at, str) else expires_at
            ),
            revocable=bool(payload.get("revocable", True)),
            granted_at=(
                datetime.fromisoformat(str(granted_at)) if isinstance(granted_at, str) else granted_at
            ),
            revoked_at=(
                datetime.fromisoformat(str(revoked_at)) if isinstance(revoked_at, str) else revoked_at
            ),
            revoked_by=payload.get("revoked_by"),
            revocation_reason=payload.get("revocation_reason"),
        )


def _load_signing_key() -> bytes:
    key = os.environ.get("PRISM_CONSENT_SIGNING_KEY", DEFAULT_SIGNING_KEY)
    return key.encode("utf-8")


def _hash_payload(payload: str, previous_hash: str | None) -> str:
    digest = hashlib.sha256()
    if previous_hash:
        digest.update(previous_hash.encode("utf-8"))
    digest.update(payload.encode("utf-8"))
    return digest.hexdigest()


def _sign_payload(payload: str, key: bytes) -> str:
    signature = hmac.new(key, payload.encode("utf-8"), digestmod="sha256").digest()
    return base64.b64encode(signature).decode("utf-8")


def _iter_log(path: Path) -> Iterator[Mapping[str, object]]:
    if not path.exists():
        return iter(())
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            yield json.loads(line)


class ConsentRegistry:
    """Central registry that records and validates consent grants."""

    _default_registry: "ConsentRegistry" | None = None
    _default_lock = RLock()

    def __init__(self, log_path: Path | str | None = None) -> None:
        resolved_path = log_path or os.environ.get("PRISM_CONSENT_LOG", DEFAULT_CONSENT_LOG_PATH)
        self.log_path = Path(resolved_path)
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = RLock()
        self._requests: Dict[str, ConsentRequest] = {}
        self._grants: Dict[str, ConsentGrant] = {}
        self._load()
        with ConsentRegistry._default_lock:
            ConsentRegistry._default_registry = self

    # ------------------------------------------------------------------
    # Global registry helpers
    # ------------------------------------------------------------------
    @classmethod
    def get_default(cls) -> "ConsentRegistry":
        with cls._default_lock:
            if cls._default_registry is None:
                cls._default_registry = ConsentRegistry()
            return cls._default_registry

    @classmethod
    def reset_default(cls) -> None:
        with cls._default_lock:
            cls._default_registry = None

    # ------------------------------------------------------------------
    # Request lifecycle
    # ------------------------------------------------------------------
    def request_consent(self, request: ConsentRequest | None = None, /, **kwargs) -> str:
        if request is None:
            if not kwargs:
                raise TypeError("request details required")
            request = ConsentRequest(**kwargs)
        elif kwargs:
            raise TypeError("unexpected keyword arguments for ConsentRequest")
        with self._lock:
            self._requests[request.request_id] = request
            self._append_log({"type": "request", "request": request.to_dict()})
            return request.request_id

    def get_request(self, request_id: str) -> ConsentRequest:
        try:
            return self._requests[request_id]
        except KeyError as exc:  # pragma: no cover - defensive
            raise ConsentError(f"unknown consent request '{request_id}'") from exc

    def grant_consent(
        self,
        grant: ConsentGrant | str,
        *,
        conditions: Iterable[str] | None = None,
        expires_in: str | timedelta | None = None,
        expires_at: datetime | None = None,
        revocable: bool = True,
    ) -> str:
        with self._lock:
            if isinstance(grant, ConsentGrant):
                ready = grant
            else:
                request = self.get_request(grant)
                expiry_candidate = expires_at
                if expiry_candidate is None and request.duration is not None:
                    expiry_candidate = request.created_at + request.duration
                if expires_in is not None:
                    expiry_candidate = _utcnow() + _parse_duration(expires_in)
                ready = ConsentGrant(
                    request_id=request.request_id,
                    granted_by=request.to_agent,
                    granted_to=request.from_agent,
                    consent_type=request.consent_type,
                    scope=request.scope,
                    conditions=conditions or (),
                    expires_at=expiry_candidate,
                    revocable=revocable,
                )
            self._grants[ready.grant_id] = ready
            self._append_log({"type": "grant", "grant": ready.to_dict()})
            return ready.grant_id

    def get_grant(self, grant_id: str) -> ConsentGrant:
        try:
            return self._grants[grant_id]
        except KeyError as exc:  # pragma: no cover - defensive
            raise ConsentError(f"unknown consent grant '{grant_id}'") from exc

    def revoke_consent(
        self,
        grant_id: str,
        revoked_by: str | None = None,
        *,
        reason: str | None = None,
        revoked_at: datetime | None = None,
    ) -> None:
        with self._lock:
            grant = self.get_grant(grant_id)
            actor = revoked_by or grant.granted_to
            if actor not in (grant.granted_by, grant.granted_to):
                raise PermissionError("Only participating agents may revoke consent")
            if not grant.can_revoke():
                raise ConsentError(f"grant '{grant_id}' cannot be revoked")
            grant.revoked_at = _ensure_utc(revoked_at) or _utcnow()
            grant.revoked_by = actor
            grant.revocation_reason = reason
            self._append_log(
                {
                    "type": "revocation",
                    "payload": {
                        "grant_id": grant.grant_id,
                        "revoked_by": actor,
                        "revoked_at": grant.revoked_at.isoformat(),
                        "reason": reason,
                    },
                }
            )

    # ------------------------------------------------------------------
    # Consent enforcement
    # ------------------------------------------------------------------
    def _find_matching_grant(
        self,
        from_agent: str,
        to_agent: str,
        consent_type: str | ConsentType,
        scope: Sequence[str] | None,
    ) -> ConsentGrant | None:
        required_scope = _normalise_scope(scope)
        if isinstance(consent_type, ConsentType):
            consent_label = consent_type.value
        else:
            consent_label = str(consent_type)
        implicit_scopes = {consent_label, "memory", "handoff"}
        filtered_scope = tuple(item for item in required_scope if item not in implicit_scopes)
        candidate_types: tuple[str | ConsentType, ...]
        if consent_label in {ConsentType.DATA_ACCESS.value, ConsentType.COLLABORATION.value}:
            candidate_types = (consent_type, ConsentType.TASK_ASSIGNMENT.value)
        else:
            candidate_types = (consent_type,)
        for candidate in candidate_types:
            for grant in self._grants.values():
                if not grant.matches(from_agent, to_agent, candidate):
                    continue
                if not grant.scope_includes(filtered_scope):
                    continue
                if grant.is_valid():
                    return grant
        return None

    def check_consent(self, *args, **kwargs):
        legacy_actor = kwargs.pop("actor", None)
        legacy_target = kwargs.pop("target", None)
        if args or legacy_actor or legacy_target:
            if args:
                actor = args[0]
                consent_type = args[1]
                target = args[2]
                scope = args[3] if len(args) > 3 else kwargs.get("scope")
            else:
                actor = legacy_actor
                consent_type = kwargs.get("consent_type")
                target = legacy_target
                scope = kwargs.get("scope")
            if actor is None or target is None or consent_type is None:
                raise TypeError("actor, target, and consent_type are required")
            with self._lock:
                return (
                    self._find_matching_grant(actor, target, consent_type, scope) is not None
                )
        from_agent = kwargs.get("from_agent")
        to_agent = kwargs.get("to_agent")
        consent_type = kwargs.get("consent_type")
        scope = kwargs.get("scope")
        if not (from_agent and to_agent and consent_type):
            raise TypeError("from_agent, to_agent and consent_type are required")
        with self._lock:
            grant = self._find_matching_grant(from_agent, to_agent, consent_type, scope)
            if grant is None:
                raise ConsentError(
                    "missing valid consent: "
                    f"from={from_agent} to={to_agent} type={consent_type} scope={_normalise_scope(scope)}"
                )
            return grant

    # ------------------------------------------------------------------
    # Audit helpers
    # ------------------------------------------------------------------
    def audit(self, agent: str | None = None) -> list[dict[str, object]]:
        entries: list[dict[str, object]] = []
        for entry in self._iter_log():
            if agent is None:
                entries.append(entry)
                continue
            payload = entry.get("payload", entry)
            if entry.get("type") == "request":
                request = payload.get("request") or payload
                if agent in {request.get("from_agent"), request.get("to_agent")}:
                    normalised = dict(entry)
                    normalised.setdefault("request", request)
                    entries.append(normalised)
            elif entry.get("type") == "grant":
                grant = payload.get("grant") or payload
                from_agent = grant.get("from_agent") or grant.get("granted_to")
                to_agent = grant.get("to_agent") or grant.get("granted_by")
                if agent in {from_agent, to_agent}:
                    normalised = dict(entry)
                    grant_payload = dict(grant)
                    grant_payload.setdefault("from_agent", from_agent)
                    grant_payload.setdefault("to_agent", to_agent)
                    normalised["grant"] = grant_payload
                    entries.append(normalised)
            elif entry.get("type") == "revocation":
                grant = self._grants.get(payload.get("grant_id", ""))
                if grant and agent in {grant.granted_by, grant.granted_to}:
                    entries.append(entry)
        return entries

    # ------------------------------------------------------------------
    # Persistence helpers
    # ------------------------------------------------------------------
    def _load(self) -> None:
        if not self.log_path.exists():
            return
        for entry in self._iter_log():
            kind = entry.get("type")
            payload = entry.get("payload", entry)
            if kind == "request":
                request_payload = payload.get("request", payload)
                request = ConsentRequest.from_dict(request_payload)
                self._requests[request.request_id] = request
            elif kind == "grant":
                grant_payload = payload.get("grant", payload)
                grant = ConsentGrant.from_dict(grant_payload)
                self._grants[grant.grant_id] = grant
            elif kind == "revocation":
                grant_id = payload.get("grant_id")
                grant = self._grants.get(str(grant_id))
                if grant:
                    revoked_at = payload.get("revoked_at")
                    if isinstance(revoked_at, str):
                        grant.revoked_at = datetime.fromisoformat(revoked_at)
                    elif isinstance(revoked_at, datetime):
                        grant.revoked_at = _ensure_utc(revoked_at)
                    grant.revoked_by = payload.get("revoked_by")
                    grant.revocation_reason = payload.get("reason")

    def _iter_log(self) -> Iterable[Mapping[str, object]]:
        if not self.log_path.exists():
            return []
        signing_key = _load_signing_key()
        expected_previous_hash: str | None = None
        with self.log_path.open("r", encoding="utf-8") as handle:
            for line_number, raw_line in enumerate(handle, 1):
                line = raw_line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError as exc:  # pragma: no cover - defensive
                    raise ConsentError(
                        f"corrupted consent log entry at line {line_number}: invalid JSON"
                    ) from exc
                payload = {
                    key: value
                    for key, value in entry.items()
                    if key not in {"timestamp", "previous_hash", "hash", "signature"}
                }
                payload_json = json.dumps(payload, sort_keys=True)
                entry_previous_hash = entry.get("previous_hash")
                if entry_previous_hash != expected_previous_hash:
                    raise ConsentError(
                        f"tampered consent log at line {line_number}: previous hash mismatch"
                    )
                entry_hash = entry.get("hash")
                if not isinstance(entry_hash, str):
                    raise ConsentError(
                        f"tampered consent log at line {line_number}: missing hash"
                    )
                expected_hash = _hash_payload(payload_json, entry_previous_hash)
                if entry_hash != expected_hash:
                    raise ConsentError(
                        f"tampered consent log at line {line_number}: hash mismatch"
                    )
                signature = entry.get("signature")
                if not isinstance(signature, str):
                    raise ConsentError(
                        f"tampered consent log at line {line_number}: missing signature"
                    )
                expected_signature = _sign_payload(payload_json, signing_key)
                if not hmac.compare_digest(signature, expected_signature):
                    raise ConsentError(
                        f"tampered consent log at line {line_number}: signature mismatch"
                    )
                expected_previous_hash = entry_hash
                yield entry

    def _append_log(self, payload: Mapping[str, object]) -> None:
        previous_entry: Mapping[str, object] | None = None
        for previous_entry in _iter_log(self.log_path):
            pass
        previous_hash = previous_entry.get("hash") if previous_entry else None
        body_json = json.dumps(payload, sort_keys=True)
        record = {
            **payload,
            "timestamp": _utcnow().isoformat(),
            "previous_hash": previous_hash,
            "hash": _hash_payload(body_json, previous_hash),
            "signature": _sign_payload(body_json, _load_signing_key()),
        }
        with self.log_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(record) + "\n")


__all__ = ["ConsentRegistry", "ConsentRequest", "ConsentGrant", "ConsentType"]

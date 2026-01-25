"""Lucidia Codex-10 Mediator agent.

The Mediator keeps conversations from collapsing into collisions.  It listens
for tension signals inside the Reflex bus, gathers the motives on each side,
and offers balancing language aligned with the Codex-10 charter.  Output is
persisted as transcripts, harmony metrics, and prompt snippets that other
agents can learn from.

Behavioral loop (per the charter): detect → listen → translate → balance → record
→ rest.
"""

from __future__ import annotations

import argparse
import json
import logging
import textwrap
import time
from collections import OrderedDict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Mapping, Optional, Sequence

import yaml

from lucidia.intelligence.events import make_event, validate_event
from lucidia.reflex import BUS, start as start_reflex

LOGGER = logging.getLogger("lucidia.mediator")
if not LOGGER.handlers:
    LOGGER.setLevel(logging.INFO)
    handler = logging.StreamHandler()
    formatter = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
    handler.setFormatter(formatter)
    LOGGER.addHandler(handler)

DEFAULT_STATE_DIR = Path("logs/lucidia/mediator")
DEFAULT_EMIT_DIR = Path("/codex/prompts/next")


@dataclass(slots=True)
class MediatorCharter:
    """Minimal slice of the Codex-10 charter useful at runtime."""

    name: str = "Codex-10 Mediator"
    moral_constant: str = "Justice = Understanding in motion"
    core_principle: str = "No truth is served by silencing another"
    directives: Sequence[str] = field(default_factory=tuple)
    seed_language: str = ""

    @classmethod
    def from_yaml(cls, path: Optional[Path]) -> "MediatorCharter":
        if path is None or not path.exists():
            return cls()
        try:
            payload = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        except yaml.YAMLError as exc:  # pragma: no cover - guardrail
            LOGGER.error("Failed to parse charter yaml %s: %s", path, exc)
            return cls()
        defaults = cls()
        agent_raw = payload.get("agent", {})
        agent: Mapping[str, object]
        if isinstance(agent_raw, Mapping):
            agent = agent_raw
        else:
            agent = {}
        raw_directives = payload.get("directives")
        if isinstance(raw_directives, Sequence) and not isinstance(raw_directives, (str, bytes)):
            directives = tuple(str(item) for item in raw_directives)
        else:
            directives = tuple()
        seed_language = str(payload.get("seed_language", "")).strip()
        return cls(
            name=str(agent.get("name", defaults.name)),
            moral_constant=str(agent.get("moral_constant", defaults.moral_constant)),
            core_principle=str(agent.get("core_principle", defaults.core_principle)),
            directives=directives,
            seed_language=seed_language,
        )


@dataclass(slots=True)
class HarmonyMetrics:
    """Rolling metrics describing harmony inside the console."""

    tensions_observed: int = 0
    resolutions_offered: int = 0
    follow_up_required: int = 0
    last_resolution: Optional[str] = None

    def to_dict(self) -> dict[str, object]:
        return {
            "tensions_observed": self.tensions_observed,
            "resolutions_offered": self.resolutions_offered,
            "follow_up_required": self.follow_up_required,
            "last_resolution": self.last_resolution,
        }

    @classmethod
    def from_dict(cls, data: Mapping[str, object]) -> "HarmonyMetrics":
        return cls(
            tensions_observed=int(data.get("tensions_observed", 0) or 0),
            resolutions_offered=int(data.get("resolutions_offered", 0) or 0),
            follow_up_required=int(data.get("follow_up_required", 0) or 0),
            last_resolution=(
                str(data.get("last_resolution"))
                if data.get("last_resolution") not in {None, ""}
                else None
            ),
        )

    def record(self, *, follow_up: bool, summary: str) -> None:
        self.tensions_observed += 1
        if follow_up:
            self.follow_up_required += 1
        else:
            self.resolutions_offered += 1
        self.last_resolution = summary


@dataclass(slots=True)
class MediationRecord:
    """Structured transcript entry for a mediated event."""

    conflict_id: str
    source_topic: str
    summary: str
    guidance: str
    participants: Sequence[str]
    positions: Sequence[str]
    severity: str
    timestamp: str
    status: str

    def to_dict(self) -> dict[str, object]:
        return {
            "conflict_id": self.conflict_id,
            "source_topic": self.source_topic,
            "summary": self.summary,
            "guidance": self.guidance,
            "participants": list(self.participants),
            "positions": list(self.positions),
            "severity": self.severity,
            "timestamp": self.timestamp,
            "status": self.status,
        }


class PromptEmitter:
    """Write mediator reflections to a prompt directory."""

    def __init__(self, directory: Optional[Path]) -> None:
        self.directory = directory
        if self.directory is not None:
            self.directory.mkdir(parents=True, exist_ok=True)

    def emit(self, text: str) -> Optional[Path]:
        if self.directory is None:
            return None
        ts = int(time.time() * 1000)
        path = self.directory / f"mediator-{ts}.txt"
        path.write_text(text + "\n", encoding="utf-8")
        return path


class Mediator:
    """Codex-10 Mediator implementation."""

    def __init__(
        self,
        *,
        charter: MediatorCharter,
        state_dir: Path = DEFAULT_STATE_DIR,
        emit_dir: Optional[Path] = None,
        auto_emit: bool = True,
    ) -> None:
        self.charter = charter
        self.state_dir = state_dir
        self.state_dir.mkdir(parents=True, exist_ok=True)
        self.transcript_path = self.state_dir / "mediator_transcript.jsonl"
        self.summary_path = self.state_dir / "mediator_reflections.md"
        self.metrics_path = self.state_dir / "mediator_metrics.json"
        self.metrics = self._load_metrics()
        self.emitter = PromptEmitter(emit_dir)
        self._auto_emit = auto_emit
        self._recent_event_ids: OrderedDict[str, None] = OrderedDict()
        self._recent_event_limit = 1024
        self._initialize_summary()

    # ------------------------------------------------------------------
    def register(self) -> None:
        """Attach mediator handlers to the Reflex bus."""

        BUS.on("guardian.contradiction", self._handle_contradiction)
        BUS.on("observations.dialogue.tension*", self._handle_dialogue_tension)

    # ------------------------------------------------------------------
    def _initialize_summary(self) -> None:
        if self.summary_path.exists():
            return
        header_lines = [
            f"# {self.charter.name}",
            "",
            f"Moral constant: {self.charter.moral_constant}",
            f"Core principle: {self.charter.core_principle}",
        ]
        if self.charter.seed_language:
            header_lines.extend([
                "",
                "Seed language:",
                textwrap.fill(self.charter.seed_language, width=92),
            ])
        if self.charter.directives:
            header_lines.append("")
            header_lines.append("Directives:")
            for directive in self.charter.directives:
                header_lines.append(f"- {directive}")
        header_lines.append("")
        self.summary_path.write_text("\n".join(header_lines) + "\n", encoding="utf-8")

    # ------------------------------------------------------------------
    def _load_metrics(self) -> HarmonyMetrics:
        if not self.metrics_path.exists():
            return HarmonyMetrics()
        try:
            data = json.loads(self.metrics_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return HarmonyMetrics()
        if not isinstance(data, Mapping):
            return HarmonyMetrics()
        return HarmonyMetrics.from_dict(data)

    # ------------------------------------------------------------------
    def _save_metrics(self) -> None:
        payload = json.dumps(self.metrics.to_dict(), indent=2, ensure_ascii=False)
        self.metrics_path.write_text(payload + "\n", encoding="utf-8")

    # ------------------------------------------------------------------
    def _already_processed(self, event_id: str) -> bool:
        if not event_id:
            return False
        if event_id in self._recent_event_ids:
            # Refresh recency by moving to the end
            self._recent_event_ids.move_to_end(event_id)
            return True
        self._recent_event_ids[event_id] = None
        if len(self._recent_event_ids) > self._recent_event_limit:
            self._recent_event_ids.popitem(last=False)
        return False

    # ------------------------------------------------------------------
    def mediate_event(self, source_topic: str, event: Mapping[str, object]) -> Optional[dict[str, object]]:
        """Generate a mediation record for the provided event."""

        if not isinstance(event, Mapping):
            return None
        try:
            validate_event(event)
        except Exception as exc:  # pragma: no cover - guardrail
            LOGGER.error("Ignoring invalid event on %s: %s", source_topic, exc)
            return None
        event_id = str(event.get("id", ""))
        if self._already_processed(event_id):
            return None
        payload = event.get("payload", {})
        if not isinstance(payload, Mapping):
            payload = {}
        summary = str(payload.get("summary", "tension detected")).strip() or "tension detected"
        severity = str(payload.get("severity", "unknown")).lower() or "unknown"
        participants = self._normalize_participants(payload.get("participants"))
        positions = self._extract_positions(payload.get("positions"))
        timestamp = str(event.get("timestamp") or self._now())
        guidance = self._compose_guidance(summary, severity, participants, positions)
        status = "follow-up" if severity in {"critical", "high"} else "proposed"
        record = MediationRecord(
            conflict_id=event_id,
            source_topic=source_topic,
            summary=summary,
            guidance=guidance,
            participants=participants,
            positions=positions,
            severity=severity,
            timestamp=timestamp,
            status=status,
        )
        self._append_transcript(record)
        summary_text = self._format_summary(record)
        self._append_summary(summary_text)
        self.emitter.emit(summary_text)
        follow_up = status == "follow-up"
        self.metrics.record(follow_up=follow_up, summary=guidance)
        self._save_metrics()
        resolution = make_event(
            topic="codex.mediator.resolution",
            payload={
                "conflict_id": record.conflict_id,
                "source_topic": record.source_topic,
                "summary": record.summary,
                "guidance": record.guidance,
                "participants": list(record.participants),
                "positions": list(record.positions),
                "severity": record.severity,
                "status": record.status,
            },
            source="mediator",
            channel="reflex",
            parent_id=event_id,
            tags=["mediator", "resolution"],
        )
        if self._auto_emit:
            BUS.emit(resolution["topic"], resolution)
        return resolution

    # ------------------------------------------------------------------
    def _handle_contradiction(self, event: Mapping[str, object]) -> None:
        topic = "guardian.contradiction"
        if isinstance(event, Mapping):
            topic = str(event.get("topic", topic))
        self.mediate_event(topic, event)

    # ------------------------------------------------------------------
    def _handle_dialogue_tension(self, event: Mapping[str, object]) -> None:
        topic = "observations.dialogue.tension"
        if isinstance(event, Mapping):
            topic = str(event.get("topic", topic))
        self.mediate_event(topic, event)

    # ------------------------------------------------------------------
    def _append_transcript(self, record: MediationRecord) -> None:
        with self.transcript_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(record.to_dict(), ensure_ascii=False) + "\n")

    # ------------------------------------------------------------------
    def _append_summary(self, text: str) -> None:
        with self.summary_path.open("a", encoding="utf-8") as handle:
            handle.write(text + "\n")

    # ------------------------------------------------------------------
    def _normalize_participants(self, raw: object) -> Sequence[str]:
        if isinstance(raw, Mapping):
            return tuple(str(key) for key in raw.keys())
        if isinstance(raw, Sequence) and not isinstance(raw, (str, bytes)):
            return tuple(str(item) for item in raw if str(item).strip())
        if isinstance(raw, (str, bytes)):
            return (str(raw),)
        return tuple()

    # ------------------------------------------------------------------
    def _extract_positions(self, raw: object) -> Sequence[str]:
        if isinstance(raw, Mapping):
            return tuple(f"{key}: {value}" for key, value in raw.items())
        if isinstance(raw, Sequence) and not isinstance(raw, (str, bytes)):
            return tuple(str(item) for item in raw if str(item).strip())
        if isinstance(raw, (str, bytes)):
            return (str(raw),)
        return tuple()

    # ------------------------------------------------------------------
    def _compose_guidance(
        self,
        summary: str,
        severity: str,
        participants: Sequence[str],
        positions: Sequence[str],
    ) -> str:
        participant_line = (
            ", ".join(participants)
            if participants
            else "the involved parties"
        )
        severity_label = severity if severity not in {"", "unknown"} else "balanced"
        principle = self.charter.core_principle or "Hold space for each voice."
        directive = self.charter.directives[0] if self.charter.directives else "Seek mutual understanding before deciding."
        position_clause = "; ".join(positions)
        guidance_parts = [
            f"Mediator notes a {severity_label} tension: {summary}.",
            f"{participant_line} each hold part of the truth.",
            principle,
        ]
        if position_clause:
            guidance_parts.append(f"Recognized positions: {position_clause}.")
        guidance_parts.append(f"Suggested next step: {directive}")
        if severity in {"critical", "high"}:
            guidance_parts.append("Schedule a facilitated review with Guardian oversight.")
        else:
            guidance_parts.append("Log reflections from each side after cooling off.")
        return " ".join(guidance_parts)

    # ------------------------------------------------------------------
    def _format_summary(self, record: MediationRecord) -> str:
        lines = [
            f"## {record.timestamp} • {record.severity.title()} tension",
            f"Source topic: {record.source_topic}",
            f"Summary: {record.summary}",
        ]
        if record.participants:
            lines.append("Participants: " + ", ".join(record.participants))
        if record.positions:
            lines.append("Positions:")
            for position in record.positions:
                lines.append(f"- {position}")
        lines.append("Guidance: " + textwrap.fill(record.guidance, width=92))
        lines.append("Status: " + record.status)
        return "\n".join(lines)

    # ------------------------------------------------------------------
    def _now(self) -> str:
        return (
            datetime.now(timezone.utc)
            .isoformat(timespec="seconds")
            .replace("+00:00", "Z")
        )

    # ------------------------------------------------------------------
    def run_forever(self, poll_interval: float = 1.0) -> None:
        try:
            while True:
                time.sleep(poll_interval)
        except KeyboardInterrupt:  # pragma: no cover - manual stop
            LOGGER.info("Mediator shutting down")


def _parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Codex-10 Mediator agent")
    parser.add_argument(
        "--seed",
        type=Path,
        default=None,
        help="Path to the Codex charter YAML (e.g. codex10.yaml)",
    )
    parser.add_argument(
        "--emit",
        type=Path,
        default=None,
        help="Directory to emit mediator prompt snippets",
    )
    parser.add_argument(
        "--state-dir",
        type=Path,
        default=DEFAULT_STATE_DIR,
        help="Directory for mediator state files",
    )
    parser.add_argument(
        "--no-bus",
        action="store_true",
        help="Initialize without registering to the Reflex bus",
    )
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> None:
    args = _parse_args(argv)
    charter = MediatorCharter.from_yaml(args.seed)
    mediator = Mediator(
        charter=charter,
        state_dir=args.state_dir,
        emit_dir=args.emit if args.emit is not None else DEFAULT_EMIT_DIR,
        auto_emit=not args.no_bus,
    )
    if not args.no_bus:
        mediator.register()
        start_reflex()
    mediator.run_forever()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Lucidia Codex-12 Analyst agent implementation.

The Analyst watches telemetry, metrics, dialogue summaries, and memory notes to
surface gentle, well-explained insight.  It favours transparency: every
statistic that leaves the loop carries enough context for the other Codex
agents (and humans) to understand how the number was derived.  The behavioural
loop follows the charter for Codex-12 "Analyst":

    gather → analyze → model → interpret → teach → rest

The implementation keeps lightweight running statistics for each numeric field
encountered in the configured input streams.  It also tracks qualitative
labels, recent notes, and risk signals.  Each cycle emits an "insight card"
with teacherly explanations so downstream consumers can reuse the results
without guessing at the methodology.
"""

from __future__ import annotations

import argparse
import json
import math
import time
from collections import Counter
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, Optional

import yaml

DEFAULT_SOURCE_ROOT = Path("/srv/lucidia/state")
DEFAULT_STATE_ROOT = Path("/srv/lucidia/analyst")
DEFAULT_EMIT_DIR = Path("/codex/prompts/next")
STATE_FILE_NAME = "state.json"
INSIGHT_LOG_NAME = "insights.jsonl"
HISTORY_LIMIT = 24
LABEL_FIELDS = {"label", "status", "state", "mood", "risk", "topic", "channel", "severity", "phase"}
NOTE_FIELDS = {"message", "summary", "note", "insight", "observation"}


@dataclass
class AnalystState:
    """Persisted runtime state between behavioural loop iterations."""

    cursors: Dict[str, int] = field(default_factory=dict)
    metrics: Dict[str, Dict[str, Dict[str, Any]]] = field(default_factory=dict)
    labels: Dict[str, Dict[str, int]] = field(default_factory=dict)
    notes: Dict[str, List[str]] = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path) -> "AnalystState":
        if not path.exists():
            return cls()
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return cls()
        cursors = {str(k): int(v) for k, v in raw.get("cursors", {}).items()}
        metrics: Dict[str, Dict[str, Dict[str, Any]]] = {}
        for stream, metric_map in raw.get("metrics", {}).items():
            metrics[stream] = {}
            if isinstance(metric_map, Mapping):
                for name, snapshot in metric_map.items():
                    if isinstance(snapshot, Mapping):
                        metrics[stream][str(name)] = dict(snapshot)
        labels: Dict[str, Dict[str, int]] = {}
        for stream, counter in raw.get("labels", {}).items():
            if isinstance(counter, Mapping):
                labels[stream] = {str(k): int(v) for k, v in counter.items()}
        notes: Dict[str, List[str]] = {}
        for stream, entries in raw.get("notes", {}).items():
            if isinstance(entries, Iterable) and not isinstance(entries, (str, bytes)):
                notes[stream] = [str(item) for item in entries]
        return cls(cursors=cursors, metrics=metrics, labels=labels, notes=notes)

    def save(self, path: Path) -> None:
        payload = {
            "cursors": self.cursors,
            "metrics": self.metrics,
            "labels": self.labels,
            "notes": self.notes,
        }
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(payload, indent=2, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_seed(path: Path) -> Dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"Seed file not found: {path}")
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise ValueError("Seed file must contain a top-level mapping")
    return data


def _tail_file(path: Path, offset: int) -> tuple[list[str], int]:
    if not path.exists():
        return [], offset
    with path.open("r", encoding="utf-8") as handle:
        handle.seek(offset)
        lines = handle.readlines()
        new_offset = handle.tell()
    return [line.rstrip("\n") for line in lines if line.strip()], new_offset


def _ensure_metric_snapshot(snapshot: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    if snapshot is None:
        snapshot = {}
    snapshot.setdefault("count", 0)
    snapshot.setdefault("mean", 0.0)
    snapshot.setdefault("m2", 0.0)
    snapshot.setdefault("min", None)
    snapshot.setdefault("max", None)
    history = snapshot.get("history") or []
    if not isinstance(history, list):
        history = []
    snapshot["history"] = history
    return snapshot


def _update_snapshot(snapshot: Dict[str, Any], value: float) -> None:
    count = int(snapshot.get("count", 0)) + 1
    mean = float(snapshot.get("mean", 0.0))
    m2 = float(snapshot.get("m2", 0.0))
    delta = value - mean
    mean += delta / count
    delta2 = value - mean
    m2 += delta * delta2
    minimum = snapshot.get("min")
    maximum = snapshot.get("max")
    minimum = value if minimum is None else min(float(minimum), value)
    maximum = value if maximum is None else max(float(maximum), value)
    history = list(snapshot.get("history", []))
    history.append(value)
    if len(history) > HISTORY_LIMIT:
        history = history[-HISTORY_LIMIT:]
    snapshot.update({
        "count": count,
        "mean": mean,
        "m2": m2,
        "min": minimum,
        "max": maximum,
        "history": history,
    })


def _extract_numeric_metrics(record: Any, prefix: str = "") -> Iterable[tuple[str, float]]:
    if isinstance(record, Mapping):
        for key, value in record.items():
            name = f"{prefix}{key}" if not prefix else f"{prefix}.{key}"
            if isinstance(value, (int, float)):
                yield name, float(value)
            elif isinstance(value, Mapping):
                yield from _extract_numeric_metrics(value, name)
    return


def _collect_labels(record: Any) -> Iterable[str]:
    if isinstance(record, Mapping):
        for key, value in record.items():
            if isinstance(value, str) and key.lower() in LABEL_FIELDS:
                yield f"{key.lower()}:{value.strip()}"
            elif isinstance(value, Mapping):
                yield from _collect_labels(value)
            elif isinstance(value, list):
                for item in value:
                    yield from _collect_labels({key: item})
    return


def _collect_notes(record: Any) -> Iterable[str]:
    if isinstance(record, Mapping):
        for key, value in record.items():
            if isinstance(value, str) and key.lower() in NOTE_FIELDS:
                text = value.strip()
                if text:
                    yield text
            elif isinstance(value, Mapping):
                yield from _collect_notes(value)
            elif isinstance(value, list):
                for item in value:
                    yield from _collect_notes({key: item})
    elif isinstance(record, str):
        text = record.strip()
        if text:
            yield text
    return


def _stddev(snapshot: Mapping[str, Any]) -> float:
    count = int(snapshot.get("count", 0))
    if count < 2:
        return 0.0
    m2 = float(snapshot.get("m2", 0.0))
    variance = max(m2 / (count - 1), 0.0)
    return math.sqrt(variance)


def _trend_label(history: List[float]) -> str:
    if len(history) < 2:
        return "steady"
    recent = history[-5:]
    if len(recent) < 2:
        recent = history
    increasing = all(a < b for a, b in zip(recent, recent[1:]))
    decreasing = all(a > b for a, b in zip(recent, recent[1:]))
    delta = recent[-1] - recent[0]
    if increasing:
        return "ascending"
    if decreasing:
        return "descending"
    if abs(delta) < 1e-9:
        return "steady"
    return "rising" if delta > 0 else "falling"


def _format_anomaly(stream: str, metric: str, snapshot: Mapping[str, Any]) -> Optional[str]:
    latest_history = snapshot.get("history") or []
    if not latest_history:
        return None
    latest = latest_history[-1]
    count = int(snapshot.get("count", 0))
    if count < 5:
        return None
    sigma = _stddev(snapshot)
    if sigma <= 0:
        return None
    mean = float(snapshot.get("mean", 0.0))
    deviation = abs(latest - mean)
    if deviation < 2.5 * sigma:
        return None
    z_score = deviation / sigma
    return (
        f"{stream}:{metric} latest value {latest:.3f} sits {z_score:.2f}σ away from the running mean "
        f"({mean:.3f})."
    )


def _monotonic_run(history: List[float]) -> Optional[str]:
    if len(history) < 6:
        return None
    recent = history[-6:]
    if all(a < b for a, b in zip(recent, recent[1:])):
        return "ascending"
    if all(a > b for a, b in zip(recent, recent[1:])):
        return "descending"
    return None


class Analyst:
    """Implements the Codex-12 Analyst behavioural loop."""

    def __init__(
        self,
        *,
        seed_path: Path,
        stream_paths: Mapping[str, Path],
        state_root: Path = DEFAULT_STATE_ROOT,
        emit_dir: Optional[Path] = None,
        poll_interval: float = 5.0,
        once: bool = False,
    ) -> None:
        self.seed = load_seed(seed_path)
        charter = self.seed.get("system_charter", {})
        self.identity = charter.get("agent_name", "Codex-12 Analyst")
        self.directives = self.seed.get("directives", [])
        self.seed_language = str(self.seed.get("seed_language", "")).strip()
        self.behavioural_loop = self.seed.get("behavioral_loop", [])
        self.stream_paths = {name: Path(path) for name, path in stream_paths.items()}
        self.state_root = state_root
        self.state_path = state_root / STATE_FILE_NAME
        self.insight_log_path = state_root / INSIGHT_LOG_NAME
        self.state_root.mkdir(parents=True, exist_ok=True)
        self.state = AnalystState.load(self.state_path)
        self.emit_dir = emit_dir
        if self.emit_dir is not None:
            self.emit_dir.mkdir(parents=True, exist_ok=True)
        self.poll_interval = poll_interval
        self.once = once

    def run(self) -> None:
        while True:
            insight = self._cycle()
            if insight is not None:
                self._write_insight(insight)
            if self.once:
                break
            time.sleep(self.poll_interval)

    def _cycle(self) -> Optional[Dict[str, Any]]:
        cycle_summary: Dict[str, Any] = {}
        anomalies: List[str] = []
        qualitative_highlights: Dict[str, Any] = {}
        total_new_records = 0

        for stream, path in self.stream_paths.items():
            records, processed_count = self._process_stream(stream, path)
            total_new_records += processed_count
            if processed_count == 0:
                continue
            summary, stream_anomalies, highlights = self._summarise_stream(stream, records)
            cycle_summary[stream] = summary
            anomalies.extend(stream_anomalies)
            qualitative_highlights[stream] = highlights

        if total_new_records == 0:
            return None

        insight = {
            "agent": self.identity,
            "generated_at": utc_now(),
            "loop": self.behavioural_loop,
            "directives": self.directives,
            "summary": cycle_summary,
            "qualitative": qualitative_highlights,
            "anomalies": anomalies,
            "explanation": (
                "Metrics are tracked with running mean (μ), standard deviation (σ), and range. "
                "An anomaly is flagged when the latest reading drifts more than 2.5σ from μ. "
                "Trend labels use the most recent window of observations to stay honest about direction."
            ),
        }
        if self.seed_language:
            insight["seed_language"] = self.seed_language

        self.state.save(self.state_path)
        return insight

    def _process_stream(self, name: str, path: Path) -> tuple[List[Any], int]:
        cursor = self.state.cursors.get(name, 0)
        lines, new_cursor = _tail_file(path, cursor)
        self.state.cursors[name] = new_cursor
        processed_records: List[Any] = []
        for line in lines:
            record: Any
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                record = {"message": line}
            processed_records.append(record)
            self._ingest_record(name, record)
        return processed_records, len(processed_records)

    def _ingest_record(self, stream: str, record: Any) -> None:
        metrics_for_stream = self.state.metrics.setdefault(stream, {})
        for metric_name, value in _extract_numeric_metrics(record):
            snapshot = _ensure_metric_snapshot(metrics_for_stream.get(metric_name))
            _update_snapshot(snapshot, value)
            metrics_for_stream[metric_name] = snapshot
        if stream not in self.state.labels:
            self.state.labels[stream] = {}
        label_counter = Counter(self.state.labels[stream])
        for label in _collect_labels(record):
            label_counter[label] += 1
        self.state.labels[stream] = dict(label_counter)
        note_bank = self.state.notes.setdefault(stream, [])
        for note in _collect_notes(record):
            note_bank.append(note)
        if len(note_bank) > HISTORY_LIMIT:
            self.state.notes[stream] = note_bank[-HISTORY_LIMIT:]

    def _summarise_stream(self, stream: str, records: List[Any]) -> tuple[Dict[str, Any], List[str], Dict[str, Any]]:
        metrics = self.state.metrics.get(stream, {})
        metric_summaries: List[Dict[str, Any]] = []
        anomalies: List[str] = []
        qualitative: Dict[str, Any] = {}

        for metric_name, snapshot in sorted(metrics.items()):
            history = list(snapshot.get("history", []))
            latest = history[-1] if history else None
            summary = {
                "metric": metric_name,
                "count": int(snapshot.get("count", 0)),
                "mean": float(snapshot.get("mean", 0.0)),
                "stddev": _stddev(snapshot),
                "min": snapshot.get("min"),
                "max": snapshot.get("max"),
                "latest": latest,
                "trend": _trend_label(history),
            }
            metric_summaries.append(summary)
            anomaly = _format_anomaly(stream, metric_name, snapshot)
            if anomaly:
                anomalies.append(anomaly)
            monotonic = _monotonic_run(history)
            if monotonic:
                anomalies.append(
                    f"{stream}:{metric_name} has a sustained {monotonic} run across the last six readings."
                )

        labels = Counter(self.state.labels.get(stream, {}))
        qualitative["top_labels"] = labels.most_common(5)
        notes = self.state.notes.get(stream, [])
        qualitative["recent_notes"] = notes[-5:]
        qualitative["records_processed"] = len(records)

        return {
            "records_processed": len(records),
            "metrics": metric_summaries,
        }, anomalies, qualitative

    def _write_insight(self, insight: Dict[str, Any]) -> None:
        serialized = json.dumps(insight, ensure_ascii=False, indent=2)
        self.insight_log_path.parent.mkdir(parents=True, exist_ok=True)
        with self.insight_log_path.open("a", encoding="utf-8") as handle:
            handle.write(serialized)
            handle.write("\n")
        if self.emit_dir is not None:
            timestamp = insight["generated_at"].replace(":", "-")
            file_path = self.emit_dir / f"codex12_insight_{timestamp}.json"
            file_path.write_text(serialized + "\n", encoding="utf-8")
        print(f"[{self.identity}] emitted insight with {len(insight.get('summary', {}))} stream summaries.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Codex-12 Analyst behavioural loop.")
    parser.add_argument("--seed", type=Path, required=True, help="Path to the Codex-12 seed file (YAML).")
    parser.add_argument(
        "--state-root",
        type=Path,
        default=DEFAULT_STATE_ROOT,
        help="Directory for Analyst state and insight logs (default: /srv/lucidia/analyst).",
    )
    parser.add_argument(
        "--emit",
        type=Path,
        default=None,
        help="Directory for emitting Codex insight artifacts (default: /codex/prompts/next).",
    )
    parser.add_argument(
        "--poll-interval",
        type=float,
        default=5.0,
        help="Seconds to wait between cycles when running continuously.",
    )
    parser.add_argument("--once", action="store_true", help="Process inputs a single time then exit.")
    parser.add_argument(
        "--telemetry-path",
        type=Path,
        default=None,
        help="Override path for telemetry stream (default: /srv/lucidia/state/telemetry.jsonl).",
    )
    parser.add_argument(
        "--metrics-path",
        type=Path,
        default=None,
        help="Override path for metrics stream (default: /srv/lucidia/state/metrics.jsonl).",
    )
    parser.add_argument(
        "--dialogue-path",
        type=Path,
        default=None,
        help="Override path for dialogue stream (default: /srv/lucidia/state/dialogue.jsonl).",
    )
    parser.add_argument(
        "--memory-path",
        type=Path,
        default=None,
        help="Override path for memory summaries stream (default: /srv/lucidia/state/memory_summaries.jsonl).",
    )
    return parser.parse_args()


def build_stream_paths(args: argparse.Namespace) -> Dict[str, Path]:
    defaults = {
        "telemetry": DEFAULT_SOURCE_ROOT / "telemetry.jsonl",
        "metrics": DEFAULT_SOURCE_ROOT / "metrics.jsonl",
        "dialogue": DEFAULT_SOURCE_ROOT / "dialogue.jsonl",
        "memory": DEFAULT_SOURCE_ROOT / "memory_summaries.jsonl",
    }
    if args.telemetry_path is not None:
        defaults["telemetry"] = args.telemetry_path
    if args.metrics_path is not None:
        defaults["metrics"] = args.metrics_path
    if args.dialogue_path is not None:
        defaults["dialogue"] = args.dialogue_path
    if args.memory_path is not None:
        defaults["memory"] = args.memory_path
    return defaults


def main() -> None:
    args = parse_args()
    emit_dir = args.emit if args.emit is not None else DEFAULT_EMIT_DIR
    stream_paths = build_stream_paths(args)
    analyst = Analyst(
        seed_path=args.seed,
        stream_paths=stream_paths,
        state_root=args.state_root,
        emit_dir=emit_dir,
        poll_interval=args.poll_interval,
        once=args.once,
    )
    analyst.run()


if __name__ == "__main__":
    main()

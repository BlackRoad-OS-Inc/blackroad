#!/usr/bin/env python3
"""Codex-3 Researcher agent.

This agent follows the charter provided in ``codex3.yaml``. It watches for
experiment briefs dropped into ``/srv/lucidia/researcher/inbox.jsonl`` and
contradictions escalated by Guardian via
``/srv/lucidia/state/contradictions.log``. Each cycle moves through the
behavioral loop described in the charter: ask → test → observe → analyze →
integrate → teach → rest.

Key behaviours implemented here:

* Structured experiment ingestion with reproducibility fingerprints.
* Hypothesis generation from Guardian contradictions.
* Teaching card emission for other Codex agents.
* Emergence tracking that highlights recurring research topics.

The seed manifest is stored as JSON (valid YAML) so we can load it using the
standard library. The ``--emit`` directory receives machine-readable deltas
that downstream Codex tooling can ingest.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple

STATE_ROOT = Path("/srv/lucidia/researcher")
INBOX_PATH = STATE_ROOT / "inbox.jsonl"
RESULTS_PATH = STATE_ROOT / "results.jsonl"
HYPOTHESES_PATH = STATE_ROOT / "hypotheses.jsonl"
TEACHING_DIR = STATE_ROOT / "teaching_cards"
EMERGENCE_LOG = STATE_ROOT / "emergence.log"
CURSOR_PATH = STATE_ROOT / "state.json"
CONTRADICTION_LOG = Path("/srv/lucidia/state/contradictions.log")
EMIT_STREAM = "researcher_stream.jsonl"


def utc_now() -> str:
    """Return the current UTC timestamp in ISO8601 format."""

    return datetime.now(timezone.utc).isoformat()


@dataclass
class ResearchState:
    """Mutable runtime state persisted between loop iterations."""

    cursors: Dict[str, int] = field(
        default_factory=lambda: {"inbox": 0, "contradictions": 0}
    )
    emergence: Dict[str, int] = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path) -> "ResearchState":
        if not path.exists():
            return cls()
        with path.open("r", encoding="utf-8") as handle:
            try:
                payload = json.load(handle)
            except json.JSONDecodeError:
                return cls()
        cursors = payload.get("cursors", {})
        emergence = payload.get("emergence", {})
        return cls(cursors=cursors, emergence=emergence)

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        payload = {"cursors": self.cursors, "emergence": self.emergence}
        with path.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)


class Researcher:
    """Implements the Codex-3 Researcher behavioural loop."""

    def __init__(self, seed_path: Path, emit_dir: Path, poll_interval: float = 5.0):
        self.seed_manifest = self._load_seed(seed_path)
        self.identity = self.seed_manifest.get("agent", "Codex-3 Researcher")
        self.directives = self.seed_manifest.get("directives", [])
        self.core_tasks = self.seed_manifest.get("core_tasks", [])
        self.behavioural_loop = self.seed_manifest.get(
            "behavioral_loop", ["ask", "test", "observe", "analyze", "integrate", "teach", "rest"]
        )
        self.seed_language = self.seed_manifest.get("seed_language", "")
        self.emit_dir = emit_dir
        self.emit_dir.mkdir(parents=True, exist_ok=True)
        STATE_ROOT.mkdir(parents=True, exist_ok=True)
        TEACHING_DIR.mkdir(parents=True, exist_ok=True)
        self.state = ResearchState.load(CURSOR_PATH)
        self.poll_interval = poll_interval

    # ------------------------------------------------------------------
    # Seed and state helpers
    # ------------------------------------------------------------------
    def _load_seed(self, path: Path) -> Dict[str, Any]:
        with path.open("r", encoding="utf-8") as handle:
            raw = handle.read()
        try:
            return json.loads(raw)
        except json.JSONDecodeError as exc:
            raise ValueError(f"Seed manifest {path} is not valid JSON/YAML") from exc

    def _persist_state(self) -> None:
        self.state.save(CURSOR_PATH)

    # ------------------------------------------------------------------
    # File tailing
    # ------------------------------------------------------------------
    def _tail_file(self, path: Path, offset: int) -> Tuple[List[str], int]:
        if not path.exists():
            return [], offset
        with path.open("r", encoding="utf-8") as handle:
            handle.seek(offset)
            lines = handle.readlines()
            new_offset = handle.tell()
        return [line.strip() for line in lines if line.strip()], new_offset

    def _append_jsonl(self, path: Path, payloads: Iterable[Dict[str, Any]]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a", encoding="utf-8") as handle:
            for payload in payloads:
                handle.write(json.dumps(payload, sort_keys=True))
                handle.write("\n")

    # ------------------------------------------------------------------
    # Experiment ingestion
    # ------------------------------------------------------------------
    def _handle_inbox(self) -> List[Dict[str, Any]]:
        cursor = self.state.cursors.get("inbox", 0)
        lines, new_cursor = self._tail_file(INBOX_PATH, cursor)
        new_results: List[Dict[str, Any]] = []
        for line in lines:
            try:
                brief = json.loads(line)
            except json.JSONDecodeError:
                print(f"[{self.identity}] Skipping malformed inbox line: {line}")
                continue
            result = self._execute_experiment(brief)
            new_results.append(result)
        if new_results:
            self._append_jsonl(RESULTS_PATH, new_results)
        self.state.cursors["inbox"] = new_cursor
        return new_results

    def _execute_experiment(self, brief: Dict[str, Any]) -> Dict[str, Any]:
        experiment_id = brief.get("id") or hashlib.sha256(json.dumps(brief, sort_keys=True).encode("utf-8")).hexdigest()[:12]
        question = brief.get("question") or brief.get("prompt")
        hypothesis = brief.get("hypothesis")
        protocol = brief.get("protocol", {})
        domain = brief.get("domain") or brief.get("topic") or "general"
        observation = {
            "agent": self.identity,
            "experiment_id": experiment_id,
            "timestamp": utc_now(),
            "question": question,
            "hypothesis": hypothesis,
            "protocol": protocol,
            "inputs": brief.get("inputs", {}),
            "observations": brief.get("observations", []),
            "analysis": self._generate_analysis(brief),
            "domain": domain,
            "directives_snapshot": self.directives,
            "core_tasks_snapshot": self.core_tasks,
            "seed_language": self.seed_language,
        }
        observation["replication_hash"] = self._replication_hash(observation)
        self._maybe_log_emergence(domain)
        print(f"[{self.identity}] Recorded experiment {experiment_id} in domain '{domain}'")
        return observation

    def _generate_analysis(self, brief: Dict[str, Any]) -> Dict[str, Any]:
        notes = brief.get("notes") or ""
        metrics = brief.get("metrics", {})
        protocol = brief.get("protocol", {})
        summary = {
            "status": brief.get("status", "recorded"),
            "notes": notes,
            "metrics": metrics,
            "replication_ready": bool(protocol),
        }
        if protocol and "steps" in protocol:
            summary["step_count"] = len(protocol["steps"])
        return summary

    def _replication_hash(self, observation: Dict[str, Any]) -> str:
        canonical = json.dumps(
            {
                "question": observation.get("question"),
                "hypothesis": observation.get("hypothesis"),
                "protocol": observation.get("protocol"),
                "inputs": observation.get("inputs"),
            },
            sort_keys=True,
        )
        return hashlib.sha256(canonical.encode("utf-8")).hexdigest()

    # ------------------------------------------------------------------
    # Contradiction-driven hypotheses
    # ------------------------------------------------------------------
    def _handle_contradictions(self) -> List[Dict[str, Any]]:
        cursor = self.state.cursors.get("contradictions", 0)
        lines, new_cursor = self._tail_file(CONTRADICTION_LOG, cursor)
        hypotheses: List[Dict[str, Any]] = []
        for line in lines:
            try:
                payload = json.loads(line)
            except json.JSONDecodeError:
                print(f"[{self.identity}] Skipping malformed contradiction line: {line}")
                continue
            hypothesis = self._create_hypothesis(payload)
            hypotheses.append(hypothesis)
        if hypotheses:
            self._append_jsonl(HYPOTHESES_PATH, hypotheses)
        self.state.cursors["contradictions"] = new_cursor
        return hypotheses

    def _create_hypothesis(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        topic = payload.get("topic") or payload.get("domain") or "unknown"
        context = payload.get("context") or payload.get("details")
        contradiction_id = payload.get("id") or payload.get("hash") or hashlib.sha256(json.dumps(payload, sort_keys=True).encode("utf-8")).hexdigest()[:10]
        hypothesis_id = f"H-{contradiction_id}-{int(time.time())}"
        rationale = payload.get("rationale") or "Guardian flagged contradiction requiring investigation."
        hypothesis = {
            "agent": self.identity,
            "hypothesis_id": hypothesis_id,
            "source_contradiction": contradiction_id,
            "timestamp": utc_now(),
            "topic": topic,
            "question": f"What reconciles the contradiction in {topic}?",
            "rationale": rationale,
            "context": context,
        }
        print(f"[{self.identity}] Derived hypothesis {hypothesis_id} for topic '{topic}'")
        return hypothesis

    # ------------------------------------------------------------------
    # Teaching cards & publication
    # ------------------------------------------------------------------
    def _emit_results(self, results: List[Dict[str, Any]]) -> None:
        if not results:
            return
        stream_path = self.emit_dir / EMIT_STREAM
        self._append_jsonl(stream_path, results)
        for result in results:
            card_path = self._write_teaching_card(result)
            self._publish_card(result, card_path)

    def _emit_hypotheses(self, hypotheses: List[Dict[str, Any]]) -> None:
        if not hypotheses:
            return
        stream_path = self.emit_dir / "hypotheses.jsonl"
        self._append_jsonl(stream_path, hypotheses)

    def _write_teaching_card(self, result: Dict[str, Any]) -> Path:
        card_name = f"{result['experiment_id']}.md"
        card_path = TEACHING_DIR / card_name
        directives = "\n".join(f"- {item}" for item in self.directives)
        tasks = "\n".join(f"- {item}" for item in self.core_tasks)
        loop = " → ".join(self.behavioural_loop)
        content = [
            f"# Teaching Card · {result['experiment_id']}",
            "",
            f"**Agent:** {self.identity}",
            f"**Domain:** {result.get('domain', 'general')}",
            f"**Question:** {result.get('question') or 'n/a'}",
            f"**Hypothesis:** {result.get('hypothesis') or 'n/a'}",
            f"**Replication Hash:** `{result['replication_hash']}`",
            "",
            "## Protocol",
        ]
        protocol = result.get("protocol") or {}
        if isinstance(protocol, dict) and protocol.get("steps"):
            for idx, step in enumerate(protocol["steps"], start=1):
                content.append(f"{idx}. {step}")
        else:
            content.append("No explicit steps provided; protocol requires elaboration.")
        content.extend(
            [
                "",
                "## Analysis",
                json.dumps(result.get("analysis", {}), indent=2, sort_keys=True),
                "",
                "## Directives Snapshot",
                directives if directives else "- (none)",
                "",
                "## Core Tasks Snapshot",
                tasks if tasks else "- (none)",
                "",
                f"## Behavioral Loop\n{loop}",
                "",
                "## Seed Language",
                result.get("seed_language") or self.seed_language or "(not provided)",
            ]
        )
        card_path.write_text("\n".join(content), encoding="utf-8")
        return card_path

    def _publish_card(self, result: Dict[str, Any], card_path: Path) -> None:
        emit_card_dir = self.emit_dir / "teaching_cards"
        emit_card_dir.mkdir(parents=True, exist_ok=True)
        target = emit_card_dir / card_path.name
        target.write_text(card_path.read_text(encoding="utf-8"), encoding="utf-8")

    # ------------------------------------------------------------------
    # Emergence tracking
    # ------------------------------------------------------------------
    def _maybe_log_emergence(self, domain: str) -> None:
        count = self.state.emergence.get(domain, 0) + 1
        self.state.emergence[domain] = count
        if count in (3, 5, 10):
            record = {
                "timestamp": utc_now(),
                "agent": self.identity,
                "domain": domain,
                "count": count,
                "message": f"Emergent pattern: {count} findings within domain '{domain}'",
            }
            self._append_jsonl(EMERGENCE_LOG, [record])
            print(f"[{self.identity}] Emergence alert for domain '{domain}' at count {count}")

    # ------------------------------------------------------------------
    # Main loop
    # ------------------------------------------------------------------
    def cycle(self) -> None:
        print(f"[{self.identity}] Starting behavioural loop: {' → '.join(self.behavioural_loop)}")
        results = self._handle_inbox()
        hypotheses = self._handle_contradictions()
        if results:
            self._emit_results(results)
        if hypotheses:
            self._emit_hypotheses(hypotheses)
        self._persist_state()

    def loop(self, run_once: bool = False) -> None:
        while True:
            self.cycle()
            if run_once:
                break
            time.sleep(self.poll_interval)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Codex-3 Researcher agent")
    parser.add_argument("--seed", type=Path, required=True, help="Path to codex3 seed manifest")
    parser.add_argument("--emit", type=Path, required=True, help="Directory to write output deltas")
    parser.add_argument(
        "--interval",
        type=float,
        default=5.0,
        help="Poll interval in seconds between behavioural loop iterations",
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Run a single behavioural loop cycle and exit",
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    agent = Researcher(seed_path=args.seed, emit_dir=args.emit, poll_interval=args.interval)
    agent.loop(run_once=args.once)


if __name__ == "__main__":
    main()

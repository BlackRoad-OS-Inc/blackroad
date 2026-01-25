#!/usr/bin/env python3
"""Codex-22 Mathematician agent implementation.

This agent gives structure to Lucidia's mathematical knowledge. It ingests
formula definitions, proof requests, contradiction logs, and dataset manifests,
then emits notation registries, proof sketches, validation reports, and
teaching notes that other agents can use. The workflow mirrors the charter's
behavioural loop:

observe → abstract → formalise → prove → teach → rest

The intent is not to produce fully formal proofs but to illuminate structure and
highlight where deeper verification is required. Outputs are persisted under the
Mathematician state directory so downstream tooling can subscribe to them.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, MutableMapping, Optional, Sequence, Tuple

import yaml

DEFAULT_STATE_ROOT = Path("/srv/lucidia/mathematician")
FORMULA_LOG_NAME = "formulas.jsonl"
PROOF_REQUEST_LOG_NAME = "proof_requests.jsonl"
STATE_FILENAME = "state.json"
PROOF_ARCHIVE_NAME = "proof_archive.jsonl"
NOTATION_REGISTRY_NAME = "notation_system.json"
VALIDATION_REPORT_NAME = "validation_report.json"
TEACHING_NOTES_NAME = "teaching_notes.md"
DATASET_DIR_NAME = "datasets"
CONTRADICTION_LOG_PATH = Path("/srv/lucidia/state/contradictions.log")


# ---------------------------------------------------------------------------
# Seed parsing helpers
# ---------------------------------------------------------------------------


def _ensure_list(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        stripped = value.strip()
        return [stripped] if stripped else []
    raise TypeError(f"Expected list-compatible value, received {type(value)!r}")


@dataclass
class MathematicianSeed:
    """Structured representation of the Mathematician seed manifest."""

    identifier: str
    agent_name: str
    generation: str
    parent: Optional[str]
    siblings: List[str]
    domain: List[str]
    moral_constant: str
    core_principle: str
    purpose: str
    directives: List[str]
    jobs: List[str]
    personality: Mapping[str, Any]
    input_channels: List[str]
    output_channels: List[str]
    behavioural_loop: List[str]
    seed_language: str
    boot_command: str


def load_seed(path: Path) -> MathematicianSeed:
    """Load and validate the Mathematician seed file."""

    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}

    if not isinstance(data, MutableMapping):
        raise ValueError("Mathematician seed must be a mapping at the top level")

    charter = data.get("system_charter")
    if not isinstance(charter, MutableMapping):
        raise ValueError("Mathematician seed missing 'system_charter' mapping")

    required_charter = [
        "agent_name",
        "generation",
        "domain",
        "moral_constant",
        "core_principle",
    ]
    missing_charter = [field for field in required_charter if field not in charter]
    if missing_charter:
        raise ValueError(
            "Mathematician seed missing charter field(s): " + ", ".join(missing_charter)
        )

    for required in [
        "purpose",
        "directives",
        "jobs",
        "input",
        "output",
        "behavioral_loop",
        "seed_language",
        "boot_command",
    ]:
        if required not in data:
            raise ValueError(f"Mathematician seed missing required field: {required}")

    return MathematicianSeed(
        identifier=str(data.get("id", "codex-22")),
        agent_name=str(charter["agent_name"]),
        generation=str(charter["generation"]),
        parent=str(charter.get("parent")) if charter.get("parent") else None,
        siblings=_ensure_list(charter.get("siblings")),
        domain=_ensure_list(charter.get("domain")),
        moral_constant=str(charter["moral_constant"]),
        core_principle=str(charter["core_principle"]),
        purpose=str(data["purpose"]).strip(),
        directives=_ensure_list(data["directives"]),
        jobs=_ensure_list(data["jobs"]),
        personality=data.get("personality", {}),
        input_channels=_ensure_list(data["input"]),
        output_channels=_ensure_list(data["output"]),
        behavioural_loop=_ensure_list(data["behavioral_loop"]),
        seed_language=str(data["seed_language"]).strip(),
        boot_command=str(data["boot_command"]).strip(),
    )


# ---------------------------------------------------------------------------
# State models
# ---------------------------------------------------------------------------


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass
class DatasetStatus:
    path: str
    fingerprint: str
    size_bytes: int
    status: str
    last_checked: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "path": self.path,
            "fingerprint": self.fingerprint,
            "size_bytes": self.size_bytes,
            "status": self.status,
            "last_checked": self.last_checked,
        }


@dataclass
class MathematicianState:
    cursors: Dict[str, int] = field(
        default_factory=lambda: {"formulas": 0, "proof_requests": 0, "contradictions": 0}
    )
    dataset_fingerprints: Dict[str, str] = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path) -> "MathematicianState":
        if not path.exists():
            return cls()
        with path.open("r", encoding="utf-8") as handle:
            try:
                payload = json.load(handle)
            except json.JSONDecodeError:
                return cls()
        cursors = payload.get("cursors", {})
        dataset_fingerprints = payload.get("dataset_fingerprints", {})
        return cls(cursors=cursors, dataset_fingerprints=dataset_fingerprints)

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "cursors": self.cursors,
            "dataset_fingerprints": self.dataset_fingerprints,
        }
        with path.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)


@dataclass
class NormalisedFormula:
    record: Dict[str, Any]
    normalised: str
    signature: str
    notation_label: str
    variables: List[str]

    def to_summary(self) -> Dict[str, Any]:
        return {
            "id": self.record.get("id"),
            "notation": self.notation_label,
            "normalised": self.normalised,
            "signature": self.signature,
            "variables": self.variables,
            "source": self.record,
        }


@dataclass
class Observation:
    formulas: List[Dict[str, Any]]
    proof_requests: List[Dict[str, Any]]
    contradictions: List[Dict[str, Any]]
    datasets: List[DatasetStatus]


@dataclass
class ProofPlan:
    request_id: str
    theorem: str
    steps: List[Dict[str, Any]]
    used_notation: List[str]
    contradictions: List[Dict[str, Any]]
    confidence: float

    def to_dict(self) -> Dict[str, Any]:
        return {
            "request_id": self.request_id,
            "theorem": self.theorem,
            "steps": self.steps,
            "used_notation": self.used_notation,
            "contradictions": self.contradictions,
            "confidence": self.confidence,
        }


@dataclass
class ProofRecord:
    plan: ProofPlan
    issued_at: str
    summary: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            **self.plan.to_dict(),
            "issued_at": self.issued_at,
            "summary": self.summary,
        }


# ---------------------------------------------------------------------------
# Mathematician implementation
# ---------------------------------------------------------------------------


class Mathematician:
    """Implements the Codex-22 Mathematician behavioural loop."""

    def __init__(
        self,
        seed_path: Path,
        emit_dir: Optional[Path] = None,
        state_root: Path = DEFAULT_STATE_ROOT,
    ) -> None:
        self.seed = load_seed(seed_path)
        self.identity = self.seed.agent_name
        self.state_root = state_root
        self.state_root.mkdir(parents=True, exist_ok=True)
        self.formula_log = self.state_root / FORMULA_LOG_NAME
        self.proof_request_log = self.state_root / PROOF_REQUEST_LOG_NAME
        self.dataset_dir = self.state_root / DATASET_DIR_NAME
        self.dataset_dir.mkdir(parents=True, exist_ok=True)
        self.proof_archive = self.state_root / PROOF_ARCHIVE_NAME
        self.notation_registry_path = self.state_root / NOTATION_REGISTRY_NAME
        self.validation_report_path = self.state_root / VALIDATION_REPORT_NAME
        self.teaching_notes_path = self.state_root / TEACHING_NOTES_NAME
        self.state_path = self.state_root / STATE_FILENAME
        self.emit_dir = emit_dir
        if self.emit_dir is not None:
            self.emit_dir.mkdir(parents=True, exist_ok=True)
        self.state = MathematicianState.load(self.state_path)
        self.notation_entries: List[Dict[str, Any]] = []
        self._notation_by_signature: Dict[str, Dict[str, Any]] = {}
        self._notation_counter = 1
        self._load_notation_registry()

    # ------------------------------------------------------------------
    # Initialisation helpers
    # ------------------------------------------------------------------
    def _load_notation_registry(self) -> None:
        if not self.notation_registry_path.exists():
            return
        try:
            payload = json.loads(self.notation_registry_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return
        entries = payload.get("entries", []) if isinstance(payload, dict) else []
        if not isinstance(entries, list):
            return
        for entry in entries:
            if not isinstance(entry, dict):
                continue
            signature = str(entry.get("signature")) if entry.get("signature") else None
            label = str(entry.get("label")) if entry.get("label") else None
            if not signature or not label:
                continue
            self.notation_entries.append(entry)
            self._notation_by_signature[signature] = entry
            try:
                suffix = label.split("-")[-1]
                value = int(suffix)
                self._notation_counter = max(self._notation_counter, value + 1)
            except (ValueError, IndexError):
                continue

    # ------------------------------------------------------------------
    # Observation phase
    # ------------------------------------------------------------------
    def observe(self) -> Observation:
        formulas = self._consume_jsonl(self.formula_log, "formulas")
        proof_requests = self._consume_jsonl(self.proof_request_log, "proof_requests")
        contradictions = self._consume_contradictions(CONTRADICTION_LOG_PATH)
        datasets = self._scan_datasets()
        return Observation(
            formulas=formulas,
            proof_requests=proof_requests,
            contradictions=contradictions,
            datasets=datasets,
        )

    def _consume_jsonl(self, path: Path, cursor_key: str) -> List[Dict[str, Any]]:
        if cursor_key not in self.state.cursors:
            self.state.cursors[cursor_key] = 0
        cursor = self.state.cursors.get(cursor_key, 0)
        records: List[Dict[str, Any]] = []
        if not path.exists():
            return records
        with path.open("r", encoding="utf-8") as handle:
            handle.seek(cursor)
            lines = handle.readlines()
            new_cursor = handle.tell()
        for line in lines:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                record = {"raw": line, "error": "unparseable_json"}
            records.append(record)
        self.state.cursors[cursor_key] = new_cursor
        return records

    def _consume_contradictions(self, path: Path) -> List[Dict[str, Any]]:
        cursor_key = "contradictions"
        if cursor_key not in self.state.cursors:
            self.state.cursors[cursor_key] = 0
        cursor = self.state.cursors.get(cursor_key, 0)
        entries: List[Dict[str, Any]] = []
        if not path.exists():
            return entries
        with path.open("r", encoding="utf-8") as handle:
            handle.seek(cursor)
            lines = handle.readlines()
            new_cursor = handle.tell()
        for line in lines:
            line = line.strip()
            if not line:
                continue
            try:
                payload = json.loads(line)
                if isinstance(payload, dict):
                    payload.setdefault("source", "guardian")
                    entries.append(payload)
                    continue
            except json.JSONDecodeError:
                pass
            entries.append({"message": line, "source": "guardian", "parsed": False})
        self.state.cursors[cursor_key] = new_cursor
        return entries

    def _scan_datasets(self) -> List[DatasetStatus]:
        statuses: List[DatasetStatus] = []
        now = utc_now()
        if not self.dataset_dir.exists():
            return statuses
        for path in sorted(self.dataset_dir.rglob("*")):
            if not path.is_file():
                continue
            fingerprint = self._hash_file(path)
            size = path.stat().st_size
            previous = self.state.dataset_fingerprints.get(str(path))
            if previous is None:
                status = "new"
            elif previous != fingerprint:
                status = "updated"
            else:
                status = "verified"
            statuses.append(
                DatasetStatus(
                    path=str(path.relative_to(self.state_root)),
                    fingerprint=fingerprint,
                    size_bytes=size,
                    status=status,
                    last_checked=now,
                )
            )
            self.state.dataset_fingerprints[str(path)] = fingerprint
        return statuses

    def _hash_file(self, path: Path, chunk_size: int = 65536) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            while True:
                chunk = handle.read(chunk_size)
                if not chunk:
                    break
                digest.update(chunk)
        return digest.hexdigest()

    # ------------------------------------------------------------------
    # Abstract phase
    # ------------------------------------------------------------------
    def abstract(self, observation: Observation) -> List[NormalisedFormula]:
        normalised: List[NormalisedFormula] = []
        for record in observation.formulas:
            expression = self._extract_expression(record)
            if not expression:
                continue
            clean = self._normalise_expression(expression)
            signature = hashlib.sha256(clean.encode("utf-8")).hexdigest()[:16]
            variables = self._resolve_variables(record, clean)
            notation_label = self._ensure_notation_entry(
                signature=signature,
                expression=expression,
                normalised=clean,
                variables=variables,
                source_id=str(record.get("id") or signature),
            )
            normalised.append(
                NormalisedFormula(
                    record=record,
                    normalised=clean,
                    signature=signature,
                    notation_label=notation_label,
                    variables=variables,
                )
            )
        return normalised

    def _extract_expression(self, record: Mapping[str, Any]) -> Optional[str]:
        for key in ("expression", "formula", "statement"):
            value = record.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
        return None

    def _normalise_expression(self, expression: str) -> str:
        condensed = " ".join(expression.replace("→", "->").replace("⇔", "<->").split())
        condensed = condensed.replace(" forall", " ∀").replace(" exists", " ∃")
        condensed = condensed.replace("\t", " ")
        condensed = " ".join(condensed.split())
        return condensed

    def _resolve_variables(self, record: Mapping[str, Any], expression: str) -> List[str]:
        if "variables" in record and isinstance(record["variables"], Sequence):
            return [str(item) for item in record["variables"] if str(item).strip()]
        tokens = set()
        current = ""
        for char in expression:
            if char.isalpha():
                current += char
            else:
                if current:
                    tokens.add(current)
                    current = ""
        if current:
            tokens.add(current)
        variables = sorted(tokens)
        return variables[:12]

    def _ensure_notation_entry(
        self,
        *,
        signature: str,
        expression: str,
        normalised: str,
        variables: Sequence[str],
        source_id: str,
    ) -> str:
        existing = self._notation_by_signature.get(signature)
        if existing:
            sources = existing.setdefault("sources", [])
            if source_id not in sources:
                sources.append(source_id)
            return str(existing["label"])
        label = f"Φ22-{self._notation_counter:03d}"
        self._notation_counter += 1
        entry = {
            "label": label,
            "signature": signature,
            "expression": expression,
            "normalised": normalised,
            "variables": list(variables),
            "sources": [source_id],
            "created_at": utc_now(),
        }
        self.notation_entries.append(entry)
        self._notation_by_signature[signature] = entry
        return label

    # ------------------------------------------------------------------
    # Formalise and prove phases
    # ------------------------------------------------------------------
    def formalise(
        self,
        normalised_formulas: List[NormalisedFormula],
        observation: Observation,
    ) -> List[ProofPlan]:
        plans: List[ProofPlan] = []
        for request in observation.proof_requests:
            theorem = str(request.get("theorem") or request.get("statement") or "Unnamed theorem")
            request_id = str(request.get("id") or hashlib.sha256(theorem.encode("utf-8")).hexdigest()[:12])
            used_notation, steps = self._map_request_to_notation(request, normalised_formulas)
            contradiction_refs = observation.contradictions[-5:]
            confidence = self._estimate_confidence(request, used_notation, contradiction_refs)
            plan = ProofPlan(
                request_id=request_id,
                theorem=theorem,
                steps=steps,
                used_notation=used_notation,
                contradictions=contradiction_refs,
                confidence=confidence,
            )
            plans.append(plan)
        return plans

    def _map_request_to_notation(
        self,
        request: Mapping[str, Any],
        normalised_formulas: List[NormalisedFormula],
    ) -> Tuple[List[str], List[Dict[str, Any]]]:
        assumptions = request.get("assumptions")
        if isinstance(assumptions, str):
            assumptions_list = [assumptions]
        elif isinstance(assumptions, Sequence):
            assumptions_list = [str(item) for item in assumptions]
        else:
            assumptions_list = []
        goal = str(request.get("goal") or request.get("conclusion") or "")
        matched: List[str] = []
        steps: List[Dict[str, Any]] = []
        for formula in normalised_formulas:
            score = self._match_score(formula.normalised, assumptions_list, goal)
            if score <= 0:
                continue
            matched.append(formula.notation_label)
            steps.append(
                {
                    "action": "reference",
                    "notation": formula.notation_label,
                    "support": score,
                    "summary": formula.normalised,
                }
            )
        if goal:
            steps.append(
                {
                    "action": "target",
                    "summary": goal,
                }
            )
        if not matched and not steps:
            steps.append({"action": "analysis", "summary": "No existing notation matched; manual proof required."})
        return matched, steps

    def _match_score(self, expression: str, assumptions: List[str], goal: str) -> float:
        score = 0.0
        lowered = expression.lower()
        for assumption in assumptions:
            if not assumption:
                continue
            tokens = assumption.lower().split()
            overlap = sum(1 for token in tokens if token and token in lowered)
            score += overlap / max(len(tokens), 1)
        if goal:
            goal_tokens = goal.lower().split()
            overlap = sum(1 for token in goal_tokens if token and token in lowered)
            score += 0.5 * (overlap / max(len(goal_tokens), 1))
        return round(score, 3)

    def _estimate_confidence(
        self,
        request: Mapping[str, Any],
        used_notation: List[str],
        contradictions: List[Dict[str, Any]],
    ) -> float:
        base = 0.4
        complexity = float(request.get("complexity", 1.0))
        complexity = max(0.2, min(5.0, complexity))
        support = min(len(used_notation) * 0.1, 0.4)
        contradiction_penalty = 0.1 * len(contradictions)
        confidence = base + support - contradiction_penalty
        confidence /= math.sqrt(complexity)
        return round(max(0.05, min(confidence, 0.99)), 3)

    def prove(self, plans: List[ProofPlan]) -> List[ProofRecord]:
        records: List[ProofRecord] = []
        for plan in plans:
            summary = self._summarise_plan(plan)
            issued_at = utc_now()
            records.append(ProofRecord(plan=plan, issued_at=issued_at, summary=summary))
        return records

    def _summarise_plan(self, plan: ProofPlan) -> str:
        if not plan.used_notation:
            return (
                "Sketch pending: no established notation matched this request. "
                "Recommend generating a bespoke proof exploration."
            )
        notation_list = ", ".join(plan.used_notation)
        return (
            f"Proof sketch references {notation_list} with estimated confidence {plan.confidence:.2f}. "
            "Contradictions reviewed: "
            + str(len(plan.contradictions))
        )

    # ------------------------------------------------------------------
    # Teach and rest phases
    # ------------------------------------------------------------------
    def teach(self, records: List[ProofRecord], observation: Observation) -> None:
        if records:
            self._append_jsonl(self.proof_archive, (record.to_dict() for record in records))
            if self.emit_dir is not None:
                for record in records:
                    self._emit_prompt(record)
        self._write_notation_registry()
        self._write_validation_report(observation.datasets)
        self._write_teaching_notes(records, observation)
        self.state.save(self.state_path)

    def _append_jsonl(self, path: Path, payloads: Iterable[Mapping[str, Any]]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a", encoding="utf-8") as handle:
            for payload in payloads:
                handle.write(json.dumps(payload, sort_keys=True))
                handle.write("\n")

    def _emit_prompt(self, record: ProofRecord) -> None:
        if self.emit_dir is None:
            return
        filename = f"mathematician-{record.plan.request_id}-{record.issued_at.replace(':', '').replace('-', '')}.json"
        path = self.emit_dir / filename
        payload = {
            "agent": self.identity,
            "summary": record.summary,
            "plan": record.plan.to_dict(),
        }
        path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    def _write_notation_registry(self) -> None:
        payload = {
            "agent": self.identity,
            "updated_at": utc_now(),
            "entries": sorted(self.notation_entries, key=lambda entry: entry.get("label", "")),
        }
        self.notation_registry_path.write_text(
            json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    def _write_validation_report(self, datasets: List[DatasetStatus]) -> None:
        payload = {
            "agent": self.identity,
            "updated_at": utc_now(),
            "datasets": [status.to_dict() for status in datasets],
        }
        self.validation_report_path.write_text(
            json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    def _write_teaching_notes(self, records: List[ProofRecord], observation: Observation) -> None:
        timestamp = utc_now()
        header = f"## {timestamp}\n"
        lines = [header]
        if self.seed.seed_language and not self.teaching_notes_path.exists():
            lines.append(self.seed.seed_language.strip() + "\n\n")
        lines.append(
            f"Observed {len(observation.formulas)} new formulae, {len(observation.proof_requests)} proof requests, "
            f"and {len(observation.contradictions)} contradictions.\n"
        )
        if records:
            lines.append("Proof sketches issued:\n")
            for record in records:
                lines.append(
                    f"- {record.plan.theorem} ({record.plan.request_id}) — confidence {record.plan.confidence:.2f}\n"
                )
        else:
            lines.append("No proof sketches emitted this cycle; awaiting richer notation overlaps.\n")
        lines.append("\n")
        with self.teaching_notes_path.open("a", encoding="utf-8") as handle:
            handle.writelines(lines)

    def rest(self) -> None:
        # Placeholder for potential scheduling hooks. The agent already respects the
        # behavioural loop by persisting state at the end of teach().
        pass

    # ------------------------------------------------------------------
    # Control flow
    # ------------------------------------------------------------------
    def run_cycle(self) -> List[ProofRecord]:
        observation = self.observe()
        normalised = self.abstract(observation)
        plans = self.formalise(normalised, observation)
        records = self.prove(plans)
        self.teach(records, observation)
        self.rest()
        return records


# ---------------------------------------------------------------------------
# CLI entrypoint
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the Codex-22 Mathematician agent")
    parser.add_argument("--seed", required=True, help="Path to the Mathematician seed manifest")
    parser.add_argument("--emit", help="Directory for emitted prompts")
    parser.add_argument(
        "--state-root",
        default=str(DEFAULT_STATE_ROOT),
        help=f"Override the state root directory (default: {DEFAULT_STATE_ROOT})",
    )
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    seed_path = Path(args.seed)
    emit_dir = Path(args.emit) if args.emit else None
    state_root = Path(args.state_root)
    agent = Mathematician(seed_path=seed_path, emit_dir=emit_dir, state_root=state_root)
    agent.run_cycle()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

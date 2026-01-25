"""Check Prism console load test summary and persist alerts."""

from __future__ import annotations

import argparse
import json
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

DEFAULT_SUMMARY = Path("logs/perf/k6_summary.json")
ALERTS_PATH = Path("data/aiops/alerts.jsonl")


@dataclass(frozen=True)
class Threshold:
    metric_key: str
    limit_ms: float
    severity: str
    description: str


THRESHOLDS: dict[str, Threshold] = {
    "frontend": Threshold(
        metric_key="http_req_duration{component:frontend}",
        limit_ms=850.0,
        severity="warning",
        description="Console UI p95 latency exceeded 850ms",
    ),
    "quantum-lab": Threshold(
        metric_key="http_req_duration{component:quantum-lab}",
        limit_ms=1200.0,
        severity="critical",
        description="Quantum Lab API p95 latency exceeded 1.2s",
    ),
    "materials-service": Threshold(
        metric_key="http_req_duration{component:materials-service}",
        limit_ms=1400.0,
        severity="warning",
        description="Materials job API p95 latency exceeded 1.4s",
    ),
}


def load_summary(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise SystemExit(f"Summary file not found: {path}")
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def append_alert(row: dict[str, Any]) -> None:
    ALERTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    with ALERTS_PATH.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, separators=(",", ":")) + "\n")


def evaluate(summary: dict[str, Any], dry_run: bool = False) -> list[dict[str, Any]]:
    metrics = summary.get("metrics", {})
    alerts: list[dict[str, Any]] = []
    timestamp = int(time.time() * 1000)

    for component, cfg in THRESHOLDS.items():
        metric = metrics.get(cfg.metric_key)
        if not metric:
            continue
        p95 = float(metric.get("p(95)", 0.0))
        if p95 <= cfg.limit_ms:
            continue
        alert = {
            "ts": timestamp,
            "component": component,
            "metric": cfg.metric_key,
            "p95_ms": round(p95, 2),
            "threshold_ms": cfg.limit_ms,
            "severity": cfg.severity,
            "description": cfg.description,
            "source": str(DEFAULT_SUMMARY),
        }
        alerts.append(alert)
        if not dry_run:
            append_alert(alert)
    return alerts


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--summary", type=Path, default=DEFAULT_SUMMARY, help="Path to k6 summary JSON")
    parser.add_argument("--dry-run", action="store_true", help="Only print alerts without writing")
    args = parser.parse_args()

    summary = load_summary(args.summary)
    alerts = evaluate(summary, dry_run=args.dry_run)
    if not alerts:
        print("All components are within thresholds.")
    else:
        print(f"Generated {len(alerts)} alert(s).")
        for row in alerts:
            print(json.dumps(row))


if __name__ == "__main__":
    main()

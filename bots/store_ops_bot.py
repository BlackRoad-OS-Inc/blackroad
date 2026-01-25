"""Retail store operations bot."""

from __future__ import annotations

import csv
from pathlib import Path
from typing import Any, Dict, List

from orchestrator.protocols import Task

FIXTURES = Path("fixtures/retail/store_sizes.csv")


class Bot:
    NAME = "Store-Ops-BOT"
    SUPPORTED_TASKS = ["plan_promotion"]

    def run(self, task: Task) -> Dict[str, Any]:
        plan: List[Dict[str, Any]] = []
        if FIXTURES.exists():
            with FIXTURES.open() as f:
                reader = csv.DictReader(f)
                for row in reader:
                    labor = int(row["size"]) // 10
                    plan.append({"store": row["store"], "labor_hours": labor})
        return {"labor_plan": plan, "checklist": ["prep", "staff"]}


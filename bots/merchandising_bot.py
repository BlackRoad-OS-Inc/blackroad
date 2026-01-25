"""Retail merchandising bot."""

from __future__ import annotations

import csv
from pathlib import Path
from typing import Dict

from orchestrator.protocols import Task

FIXTURES = Path("fixtures/retail/sales_history.csv")


class Bot:
    NAME = "Merchandising-BOT"
    SUPPORTED_TASKS = ["plan_assortment"]

    def run(self, task: Task) -> Dict[str, int]:
        counts: Dict[str, int] = {}
        if FIXTURES.exists():
            with FIXTURES.open() as f:
                reader = csv.DictReader(f)
                for row in reader:
                    counts[row["sku"]] = counts.get(row["sku"], 0) + int(row["qty"])
        return counts


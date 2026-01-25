from sdk import plugin_api

CAPABILITIES = [
    {"intent": "forecast_check", "inputs_schema": {"type": "object"}, "outputs_schema": {"type": "object"}}
]


class RevOpsBot(plugin_api.BaseBot):
    NAME = "RevOps-BOT"

    def handle(self, task: plugin_api.Task) -> plugin_api.BotResponse:
        return plugin_api.BotResponse(ok=True, content="forecast ok")


plugin_api.register_plugin_bot(RevOpsBot)
from __future__ import annotations

import json
from pathlib import Path
from statistics import mean

from orchestrator.base import BaseBot, BotResponse, Task
from orchestrator.registry import register

NAME = "RevOps-BOT"
MISSION = "Improve revenue operations"
SUPPORTED_TASKS = ["forecast_accuracy", "pipeline_hygiene"]

_DATA = json.loads((Path(__file__).resolve().parents[1] / "fixtures" / "revops.json").read_text())


class RevOpsBot(BaseBot):
    NAME = NAME
    MISSION = MISSION
    SUPPORTED_TASKS = SUPPORTED_TASKS

    def run(self, task: Task) -> BotResponse:
        goal = task.goal.lower()
        if "pipeline" in goal or "hygiene" in goal:
            return self._pipeline_hygiene()
        return self._forecast_accuracy()

    def _forecast_accuracy(self) -> BotResponse:
        forecast = _DATA["forecast"]
        actuals = _DATA["actuals"]
        errors = [abs(f - a) / f for f, a in zip(forecast, actuals)]
        avg_error = round(mean(errors) * 100, 2)
        summary = f"RevOps-BOT forecast accuracy check shows {avg_error}% error (percent)."
        risks = ["Forecast variance could misalign quotas"]
        artifacts = {"errors": errors, "avg_error": avg_error}
        return BotResponse(summary=summary, artifacts=artifacts, risks=risks)

    def _pipeline_hygiene(self) -> BotResponse:
        opps = _DATA["opps"]
        stale = [o["name"] for o in opps if o["last_activity"] > 30]
        stage_age = [o["name"] for o in opps if o["stage_age"] > 60]
        missing_close = [o["name"] for o in opps if not o["has_close_date"]]
        summary = (
            f"RevOps-BOT pipeline hygiene: {len(stale)} stale, {len(stage_age)} stage-age breaches, "
            f"{len(missing_close)} missing close dates."
        )
        risks = []
        if stale:
            risks.append("Stale opportunities may slip")
        if stage_age:
            risks.append("Stage-age breaches risk forecast slippage")
        if missing_close:
            risks.append("Missing close dates reduce visibility")
        artifacts = {"stale": stale, "stage_age": stage_age, "missing_close": missing_close}
        return BotResponse(summary=summary, artifacts=artifacts, risks=risks)


register(RevOpsBot())

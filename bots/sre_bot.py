from sdk import plugin_api

CAPABILITIES = [
    {"intent": "error_budget", "inputs_schema": {"type": "object"}, "outputs_schema": {"type": "object"}}
]


class SREBot(plugin_api.BaseBot):
    NAME = "SRE-BOT"

    def handle(self, task: plugin_api.Task) -> plugin_api.BotResponse:
        return plugin_api.BotResponse(ok=True, content="error budget ok")


plugin_api.register_plugin_bot(SREBot)
from __future__ import annotations

from orchestrator.base import BaseBot
from orchestrator.flags import get_flag
from orchestrator.protocols import BotResponse, Task


class SREBot(BaseBot):
    name = "SRE-BOT"
    mission = "Create postmortem outlines"

    def run(self, task: Task) -> BotResponse:
        if get_flag("bot.SRE-BOT.postmortem_v2", False):
            summary = "Postmortem v2 skeleton"
            steps = ["collect metrics", "draft timeline"]
        else:
            summary = "Postmortem v1 skeleton"
            steps = ["gather logs"]
        return BotResponse(
            task_id=task.id,
            summary=summary,
            steps=steps,
            data={},
            risks=["none"],
            artifacts=["pm.md"],
            next_actions=["review"],
            ok=True,
        )
from __future__ import annotations

import json
from pathlib import Path
from typing import List

from orchestrator.base import BaseBot, BotResponse, Task
from orchestrator.registry import register

NAME = "SRE-BOT"
MISSION = "Ensure service reliability"
SUPPORTED_TASKS = ["slo_error_budget", "postmortem"]

_DATA = json.loads((Path(__file__).resolve().parents[1] / "fixtures" / "sre_incidents.json").read_text())


class SREBot(BaseBot):
    NAME = NAME
    MISSION = MISSION
    SUPPORTED_TASKS = SUPPORTED_TASKS

    def run(self, task: Task) -> BotResponse:
        goal = task.goal.lower()
        if "postmortem" in goal:
            incident_id = str(task.context.get("incident_id", "unknown")) if task.context else "unknown"
            timeline: List[str] = list(task.context.get("timeline", [])) if task.context else []
            return self._postmortem(incident_id, timeline)
        return self._error_budget()

    def _error_budget(self) -> BotResponse:
        burn_minutes = sum(i["duration_minutes"] for i in _DATA["incidents"])
        total_budget = _DATA["period_hours"] * 60 * (1 - _DATA["slo_target"] / 100)
        remaining = round(total_budget - burn_minutes, 2)
        summary = (
            f"SRE-BOT error-budget burn is {burn_minutes} minutes with {remaining} minutes remaining."
        )
        risks = ["Budget exhaustion may breach SLO"]
        artifacts = {"burn_minutes": burn_minutes, "remaining_minutes": remaining}
        return BotResponse(summary=summary, artifacts=artifacts, risks=risks)

    def _postmortem(self, incident_id: str, timeline: List[str]) -> BotResponse:
        summary = f"SRE-BOT postmortem skeleton for {incident_id} generated."
        risks = ["Follow-up actions required"]
        artifacts = {
            "incident_id": incident_id,
            "timeline": timeline,
            "mitigations": ["Improve monitoring", "Add rollback checklist"],
        }
        return BotResponse(summary=summary, artifacts=artifacts, risks=risks)


register(SREBot())

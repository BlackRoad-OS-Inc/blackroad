"""Close process bot."""

from __future__ import annotations

from orchestrator import BaseBot, BotMetadata
from orchestrator.protocols import BotResponse, Task


class CloseBot(BaseBot):
    """Bot that summarises close process readiness."""

    metadata = BotMetadata(
        name="Close-BOT",
        mission="Coordinate month-end close deliverables and risk reviews.",
        inputs=["task.goal", "config.close.calendar"],
        outputs=["status_report", "risk_register"],
        kpis=["close_duration", "reconciliation_completion"],
        guardrails=["Requires approvals for policy exceptions"],
        handoffs=["Controller team"],
        tags=("conscious", "finance", "close"),
    )

    def handle_task(self, task: Task) -> BotResponse:
        """Return a templated close status update."""

        summary = "Prepared close readiness update"
        steps = ["collect milestones", "assess risks", "compile summary"]
        data = {
            "milestones": [
                {"name": "Pre-close reconciliation", "status": "complete"},
                {"name": "Flux analysis", "status": "pending"},
            ],
            "risks": [
                {
                    "name": "Unreconciled cash",
                    "impact": "medium",
                    "owner": "treasury",
                }
            ],
        }
        artifacts = [f"artifacts/{task.id}/close_packet.md"]
        return BotResponse(
            task_id=task.id,
            summary=summary,
            steps=steps,
            data=data,
            risks=["Outstanding flux analysis"],
            artifacts=artifacts,
            next_actions=["Complete flux analysis", "Review reconciliations"],
            ok=True,
            metrics={"milestones_completed": 1},
        )

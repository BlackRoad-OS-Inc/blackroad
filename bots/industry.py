from __future__ import annotations

from orchestrator.protocols import Response, Task


class IndustryBot:
    """IndustryBot

    MISSION: Provide industry-specific expertise.
    INPUTS: Sector-focused tasks.
    OUTPUTS: Industry insights.
    KPIS: Sector alignment, strategic value.
    GUARDRAILS: Avoid disclosing proprietary information.
    HANDOFFS: Works with RegionalBot for local tailoring.
    """

    def run(self, task: Task) -> Response:
        return Response(task_id=task.id, status="not_implemented", data="Industry bot stub")

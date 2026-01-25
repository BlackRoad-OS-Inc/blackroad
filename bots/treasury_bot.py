"""Treasury bot implementation."""

from __future__ import annotations

import re
from datetime import datetime, timedelta

from orchestrator import BaseBot, BotMetadata
from orchestrator.protocols import BotResponse, Task


class TreasuryBot(BaseBot):
    """Finance bot specialising in treasury planning."""

    metadata = BotMetadata(
        name="Treasury-BOT",
        mission="Deliver short- and mid-term cash forecasts and hedging suggestions.",
        inputs=["task.goal", "config.finance.treasury"],
        outputs=["cash_forecast", "hedging_plan"],
        kpis=["cash_floor", "hedge_coverage"],
        guardrails=["Offline deterministic calculations", "No external integrations"],
        handoffs=["Treasury operations"],
        tags=("conscious", "finance", "treasury"),
    )

    def handle_task(self, task: Task) -> BotResponse:
        """Generate a deterministic cash plan based on the task goal."""

        # Extract horizon from task goal using regex, or use config default
        horizon_match = re.search(r'(\d+)[- ]week', task.goal, re.IGNORECASE)
        if horizon_match:
            horizon_weeks = int(horizon_match.group(1))
        else:
            # Default to 8 weeks if not specified in goal
            horizon_weeks = 8

        # Read treasury config
        treasury_config = task.config.get("finance", {}).get("treasury", {})
        base_amount = treasury_config.get("cash_floor", 2_500_000)

        forecast = [base_amount + index * 75_000 for index in range(horizon_weeks)]

        # Generate hedges based on config policies
        hedge_policies = treasury_config.get("hedge_policies", [])
        hedges = []
        for policy in hedge_policies[:1]:  # Use first policy for demo
            hedges.append({
                "instrument": "forward",
                "currency": policy.get("currency", "EUR"),
                "notional": policy.get("max_notional", 500_000),
                "maturity": (datetime.utcnow() + timedelta(days=90)).date().isoformat(),
            })

        summary = f"Generated {horizon_weeks}-week cash outlook"
        return BotResponse(
            task_id=task.id,
            summary=summary,
            steps=["ingest goal", "simulate cash flow", "prepare hedging"],
            data={"weekly_cash": forecast, "hedging": hedges},
            risks=["Forecast uses static fixtures"],
            artifacts=[f"artifacts/{task.id}/cash_forecast.csv"],
            next_actions=["Review forecast", "Capture approvals if required"],
            ok=True,
            metrics={"cash_floor": min(forecast)},
from datetime import datetime

from orchestrator.base import BaseBot
from orchestrator.protocols import Task, BotResponse


class TreasuryBot(BaseBot):
    """
    MISSION: Provide treasury analysis for cash forecasting and hedging.
    INPUTS: Task context containing financial parameters.
    OUTPUTS: Cash forecast or hedging plan summaries.
    KPIS: Cash position accuracy, hedge coverage.
    GUARDRAILS: Uses deterministic mock data only; no external systems.
    HANDOFFS: Finance team for execution.
    """

    name = "Treasury-BOT"
    mission = "Assist with cash forecasting and hedging outlines."

    def run(self, task: Task) -> BotResponse:
        goal = task.goal.lower()
        if "13-week" in goal:
            summary = "Generated mock 13-week cash forecast including KPIs."
            data = {
                "weekly_cash": [10000 + i * 100 for i in range(13)],
                "currency": "USD",
            }
            artifacts = [f"/artifacts/{task.id}/cash_forecast.csv"]
            next_actions = ["Review forecast", "Adjust assumptions"]
        elif "hedging" in goal:
            summary = "Outlined mock hedging plan with KPI coverage ratios."
            data = {
                "hedges": [
                    {"instrument": "forward", "amount": 50000, "rate": 1.1}
                ]
            }
            artifacts = [f"/artifacts/{task.id}/hedging_plan.md"]
            next_actions = ["Confirm exposures", "Execute hedges"]
        else:
            summary = "Unable to process request."
            data = {}
            artifacts = []
            next_actions = []

        steps = ["gather data", "analyze", "summarize"]
        risks = ["Mock data may not reflect reality"]
        return BotResponse(
            task_id=task.id,
            summary=summary,
            steps=steps,
            data=data,
            risks=risks,
            artifacts=artifacts,
            next_actions=next_actions,
            ok=bool(data),
        )
from __future__ import annotations

from random import seed

from config.settings import settings
from orchestrator.base import BaseBot, BotResponse, Task
from orchestrator.registry import register

NAME = "Treasury-BOT"
MISSION = "Build cash forecasts and manage liquidity"
SUPPORTED_TASKS = ["cash_view"]


class TreasuryBot(BaseBot):
    NAME = NAME
    MISSION = MISSION
    SUPPORTED_TASKS = SUPPORTED_TASKS

    def run(self, task: Task) -> BotResponse:  # pragma: no cover - simple
        seed(settings.RANDOM_SEED)
        summary = (
            "Treasury-BOT produced a deterministic 13-week cash view with projected cash "
            "balance of $100000."
        )
        risks = ["Liquidity risk if collections slip"]
        return BotResponse(summary=summary, risks=risks)


register(TreasuryBot())

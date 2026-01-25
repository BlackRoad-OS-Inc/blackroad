"""Supply chain S&OP bot."""

from __future__ import annotations

from orchestrator import BaseBot, BotMetadata
from orchestrator.protocols import BotResponse, Task


class SopBot(BaseBot):
    """Bot that generates S&OP planning recommendations."""

    metadata = BotMetadata(
        name="S&OP-BOT",
        mission="Balance demand, supply, and inventory in rolling plans.",
        inputs=["task.goal", "config.supply.sop"],
        outputs=["allocation_plan", "logistics_recommendations"],
        kpis=["service_level", "inventory_turns"],
        guardrails=["No live system integrations"],
        handoffs=["Supply chain planning"],
        tags=("conscious", "supply-chain", "planning"),
    )

    def handle_task(self, task: Task) -> BotResponse:
        """Create a deterministic plan with mock metrics."""

        # Read S&OP configuration from task config
        sop_config = task.config.get("supply", {}).get("sop", {})
        inventory_targets = sop_config.get("inventory_targets", [])
        logistics_partners = sop_config.get("logistics_partners", [])

        # Generate allocations based on inventory targets
        allocations = []
        for target in inventory_targets:
            sku = target.get("sku", "UNKNOWN")
            # Use midpoint between min and max as target quantity
            min_qty = target.get("min", 0)
            max_qty = target.get("max", 0)
            target_qty = (min_qty + max_qty) // 2
            # Assign to a default plant for simplicity
            allocations.append({"sku": sku, "plant": "SFO", "qty": target_qty})

        # Generate logistics recommendations based on configured partners
        logistics = []
        for partner in logistics_partners:
            carrier = partner.get("carrier", "UNKNOWN")
            lanes = partner.get("lanes", [])
            for lane in lanes:
                # Use ocean mode for demo; real logic may vary
                logistics.append({"lane": lane, "carrier": carrier, "mode": "ocean"})

        return BotResponse(
            task_id=task.id,
            summary="Generated S&OP allocation scenario",
            steps=["analyse demand", "balance supply", "prepare logistics"],
            data={"allocations": allocations, "logistics": logistics},
            risks=["Inventory buffer is static"],
            artifacts=[f"artifacts/{task.id}/sop_plan.json"],
            next_actions=["Review allocation", "Confirm logistics capacity"],
            ok=True,
            metrics={"service_level": 0.96},
        )

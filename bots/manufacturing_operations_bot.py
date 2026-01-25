"""
Manufacturing Operations Bot - Advanced MRP and production planning intelligence.

MISSION: Transform PLM data into actionable manufacturing plans with material requirements 
planning, capacity analysis, and production scheduling optimization.

INPUTS:
- BOM structures from PLM-Analysis-BOT
- Demand forecasts and order requirements
- Inventory levels and work-in-progress status
- Production capacity and routing constraints

OUTPUTS:
- Material Requirements Planning (MRP) schedules
- Production capacity analysis and bottleneck identification
- Work order generation with optimal sequencing
- Supplier purchase recommendations with lead time optimization

KPIS:
- Planning accuracy > 95% for material requirements
- Capacity utilization optimization to 85-90% target
- Lead time reduction through intelligent scheduling
- Inventory turnover improvement of 15-20%

GUARDRAILS:
- Never schedule beyond confirmed capacity limits
- Must validate supplier lead times before commitment
- Material safety stock levels cannot fall below minimums
- Production sequences must respect work center dependencies

HANDOFFS:
- PLM-Analysis-BOT: Receives BOM explosion and cost data
- Treasury-BOT: Provides cash flow impact of material purchases
- Quality-BOT: Validates supplier certifications for critical components
- Supply-Chain-BOT: Coordinates with supplier relationship management

TEACHING NOTES:
This bot demonstrates advanced manufacturing concepts and shows how BlackRoad
bots can handle complex business logic while maintaining deterministic behavior.
Key learning: Manufacturing is about optimization under constraints!
"""

import json
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List

from orchestrator.base import BaseBot
from orchestrator.protocols import Task, BotResponse
from plm import bom
from tools import storage


@dataclass
class WorkOrder:
    """Represents a manufacturing work order."""
    id: str
    item_id: str
    revision: str
    quantity: int
    priority: int
    due_date: str
    work_center: str
    estimated_hours: float
    status: str = "planned"


@dataclass
class MaterialRequirement:
    """Represents a material requirement for production."""
    component_id: str
    required_quantity: float
    available_quantity: float
    shortage_quantity: float
    supplier: str
    lead_time_days: int
    order_date: str
    delivery_date: str


class ManufacturingOperationsBot(BaseBot):
    name = "Manufacturing-Operations-BOT"
    mission = "Transform PLM data into optimized manufacturing plans"

    def run(self, task: Task) -> BotResponse:
        """Execute manufacturing operations planning and optimization."""
        
        # Parse task context for manufacturing requirements
        context = task.context or {}
        target_item = context.get("item_id", "PROD-100")
        target_revision = context.get("revision", "A")
        production_quantity = context.get("quantity", 100)
        due_date_str = context.get("due_date", "2025-11-15")
        
        # Ensure PLM data is loaded (teaching: always validate dependencies!)
        bom.load_items('fixtures/plm/items')
        bom.load_boms('fixtures/plm/boms')
        
        # Step 1: Generate Material Requirements Plan (MRP)
        self._log_teaching_moment("Creating MRP from BOM explosion", 
                                 "MRP transforms static BOMs into time-phased requirements")
        
        material_requirements = self._generate_mrp(target_item, target_revision, 
                                                 production_quantity, due_date_str)
        
        # Step 2: Analyze production capacity and bottlenecks
        self._log_teaching_moment("Analyzing production capacity", 
                                 "Capacity planning prevents overcommitment and identifies constraints")
        
        capacity_analysis = self._analyze_production_capacity(production_quantity)
        
        # Step 3: Generate optimized work orders
        work_orders = self._generate_work_orders(target_item, target_revision, 
                                               production_quantity, due_date_str)
        
        # Step 4: Create supplier purchase recommendations
        purchase_recommendations = self._generate_purchase_recommendations(material_requirements)
        
        # Calculate key performance metrics
        total_material_cost = sum(req.shortage_quantity * self._get_component_cost(req.component_id) 
                                for req in material_requirements)
        
        critical_path_days = max((req.lead_time_days for req in material_requirements), default=0)
        
        # Create comprehensive manufacturing plan
        manufacturing_plan = {
            "production_order": {
                "item": f"{target_item}@{target_revision}",
                "quantity": production_quantity,
                "due_date": due_date_str,
                "estimated_completion": self._calculate_completion_date(due_date_str, critical_path_days)
            },
            "material_requirements": [
                {
                    "component": req.component_id,
                    "required": req.required_quantity,
                    "available": req.available_quantity,
                    "shortage": req.shortage_quantity,
                    "supplier": req.supplier,
                    "lead_time_days": req.lead_time_days,
                    "order_by": req.order_date,
                    "deliver_by": req.delivery_date
                }
                for req in material_requirements
            ],
            "capacity_analysis": capacity_analysis,
            "work_orders": [
                {
                    "id": wo.id,
                    "item": f"{wo.item_id}@{wo.revision}",
                    "quantity": wo.quantity,
                    "work_center": wo.work_center,
                    "estimated_hours": wo.estimated_hours,
                    "priority": wo.priority,
                    "due_date": wo.due_date
                }
                for wo in work_orders
            ],
            "purchase_recommendations": purchase_recommendations,
            "kpis": {
                "total_material_cost": round(total_material_cost, 2),
                "critical_path_days": critical_path_days,
                "work_orders_count": len(work_orders),
                "suppliers_involved": len(set(req.supplier for req in material_requirements)),
                "capacity_utilization": capacity_analysis.get("utilization_percent", 0)
            }
        }
        
        # Store artifacts with teaching metadata
        artifacts_dir = Path("artifacts") / task.id
        artifacts_dir.mkdir(parents=True, exist_ok=True)
        
        plan_file = artifacts_dir / "manufacturing_plan.json"
        storage.write(str(plan_file), json.dumps(manufacturing_plan, indent=2))
        
        # Create teaching summary for other bots
        teaching_file = artifacts_dir / "manufacturing_lessons.md"
        teaching_content = self._create_teaching_summary(manufacturing_plan)
        storage.write(str(teaching_file), teaching_content)
        
        return BotResponse(
            task_id=task.id,
            summary=f"Generated manufacturing plan for {production_quantity} units of {target_item}@{target_revision}. "
                   f"Total material cost: ${total_material_cost:.2f}, Critical path: {critical_path_days} days, "
                   f"Capacity utilization: {capacity_analysis.get('utilization_percent', 0):.1f}%",
            steps=[
                f"Loaded PLM data and exploded BOM for {target_item}@{target_revision}",
                f"Generated MRP for {production_quantity} units with lead time analysis",
                f"Analyzed production capacity and identified bottlenecks",
                f"Created {len(work_orders)} optimized work orders",
                f"Generated purchase recommendations for {len(material_requirements)} components",
                f"Calculated KPIs and stored manufacturing plan",
                f"Created teaching materials for knowledge sharing"
            ],
            data=manufacturing_plan,
            risks=[
                "Production schedule assumes normal capacity - overtime may be required",
                "Supplier lead times based on historical data - confirm with current quotes",
                "Material costs may fluctuate between planning and execution",
                "Work center capacity assumes no unplanned downtime"
            ],
            artifacts=[str(plan_file), str(teaching_file)],
            next_actions=[
                "Share material cost projections with Treasury-BOT for cash flow planning",
                "Request supplier qualification validation from Quality-BOT",
                "Coordinate supplier relationship management with Supply-Chain-BOT",
                "Monitor actual vs. planned performance for continuous improvement"
            ],
            ok=True
        )
    
    def _generate_mrp(self, item_id: str, revision: str, quantity: int, due_date: str) -> List[MaterialRequirement]:
        """Generate Material Requirements Planning from BOM explosion."""
        requirements = []
        
        # Get BOM explosion
        bom_structure = bom.explode(item_id, revision, level=5)
        
        # Convert to material requirements with lead time offset
        due_date_obj = datetime.strptime(due_date, "%Y-%m-%d")

        for _level, component_id, bom_qty in bom_structure:
            required_qty = bom_qty * quantity
            
            # Simulate current inventory (teaching: real systems would query inventory)
            available_qty = max(0, required_qty * 0.3)  # Assume 30% available
            shortage_qty = max(0, required_qty - available_qty)
            
            # Get component details
            comp_key = (component_id, "A")
            if comp_key in bom.ITEMS:
                item = bom.ITEMS[comp_key]
                supplier = item.suppliers[0] if item.suppliers else "UNKNOWN"
                lead_time = item.lead_time_days
                
                # Calculate order timing (working backwards from due date)
                order_date = due_date_obj - timedelta(days=lead_time + 2)  # +2 for safety
                delivery_date = order_date + timedelta(days=lead_time)
                
                requirements.append(MaterialRequirement(
                    component_id=component_id,
                    required_quantity=required_qty,
                    available_quantity=available_qty,
                    shortage_quantity=shortage_qty,
                    supplier=supplier,
                    lead_time_days=lead_time,
                    order_date=order_date.strftime("%Y-%m-%d"),
                    delivery_date=delivery_date.strftime("%Y-%m-%d")
                ))
        
        return requirements
    
    def _analyze_production_capacity(self, quantity: int) -> Dict:
        """Analyze production capacity and identify bottlenecks."""
        # Teaching: Real manufacturing systems have complex capacity models
        
        # Simulate work center capacities (hours per day)
        work_centers = {
            "Assembly": {"capacity_hours": 16, "efficiency": 0.85},
            "Fabrication": {"capacity_hours": 24, "efficiency": 0.80},
            "Testing": {"capacity_hours": 8, "efficiency": 0.90},
            "Packaging": {"capacity_hours": 12, "efficiency": 0.95}
        }
        
        # Calculate capacity requirements (simplified model)
        hours_per_unit = 0.5  # Assume 30 minutes per unit
        total_hours_needed = quantity * hours_per_unit
        
        capacity_analysis = {
            "total_hours_required": total_hours_needed,
            "work_centers": {},
            "bottleneck": None,
            "utilization_percent": 0.0
        }
        
        max_utilization = 0.0
        bottleneck_center = None
        
        for center, specs in work_centers.items():
            available_hours = specs["capacity_hours"] * specs["efficiency"]
            utilization = (total_hours_needed / 4) / available_hours * 100  # Spread across centers
            
            capacity_analysis["work_centers"][center] = {
                "available_hours": available_hours,
                "required_hours": total_hours_needed / 4,
                "utilization_percent": round(utilization, 1),
                "efficiency": specs["efficiency"]
            }
            
            if utilization > max_utilization:
                max_utilization = utilization
                bottleneck_center = center
        
        capacity_analysis["bottleneck"] = bottleneck_center
        capacity_analysis["utilization_percent"] = round(max_utilization, 1)
        
        return capacity_analysis
    
    def _generate_work_orders(self, item_id: str, revision: str, quantity: int, due_date: str) -> List[WorkOrder]:
        """Generate optimized work orders for production."""
        work_orders = []
        
        # Create primary assembly work order
        work_orders.append(WorkOrder(
            id=f"WO-{item_id}-001",
            item_id=item_id,
            revision=revision,
            quantity=quantity,
            priority=1,
            due_date=due_date,
            work_center="Assembly",
            estimated_hours=quantity * 0.5
        ))
        
        # Create component fabrication work orders based on BOM
        bom_structure = bom.explode(item_id, revision, level=2)
        for level, component_id, bom_qty in bom_structure:
            if level == 1:  # Direct components
                comp_quantity = int(bom_qty * quantity)
                work_orders.append(WorkOrder(
                    id=f"WO-{component_id}-001",
                    item_id=component_id,
                    revision="A",
                    quantity=comp_quantity,
                    priority=2,
                    due_date=due_date,
                    work_center="Fabrication",
                    estimated_hours=comp_quantity * 0.2
                ))
        
        return work_orders
    
    def _generate_purchase_recommendations(self, requirements: List[MaterialRequirement]) -> List[Dict]:
        """Generate optimized purchase recommendations."""
        recommendations = []
        
        for req in requirements:
            if req.shortage_quantity > 0:
                unit_cost = self._get_component_cost(req.component_id)
                total_cost = req.shortage_quantity * unit_cost
                
                recommendations.append({
                    "component_id": req.component_id,
                    "supplier": req.supplier,
                    "quantity": req.shortage_quantity,
                    "unit_cost": unit_cost,
                    "total_cost": round(total_cost, 2),
                    "order_date": req.order_date,
                    "delivery_date": req.delivery_date,
                    "priority": "High" if req.lead_time_days > 7 else "Normal"
                })
        
        # Sort by priority and delivery date
        recommendations.sort(key=lambda x: (x["priority"] == "Normal", x["delivery_date"]))
        
        return recommendations
    
    def _get_component_cost(self, component_id: str) -> float:
        """Get component unit cost from PLM data."""
        comp_key = (component_id, "A")
        if comp_key in bom.ITEMS:
            return bom.ITEMS[comp_key].cost
        return 0.0
    
    def _calculate_completion_date(self, due_date: str, critical_path_days: int) -> str:
        """Calculate realistic completion date based on critical path."""
        due_date_obj = datetime.strptime(due_date, "%Y-%m-%d")
        completion_date = due_date_obj - timedelta(days=max(0, critical_path_days - 5))
        return completion_date.strftime("%Y-%m-%d")
    
    def _log_teaching_moment(self, action: str, lesson: str):
        """Log teaching moments for knowledge sharing (teaching: observability!)."""
        print(f"🎓 TEACHING: {action} - {lesson}")
    
    def _create_teaching_summary(self, manufacturing_plan: Dict) -> str:
        """Create educational summary for other bots and developers."""
        return f"""# Manufacturing Operations Teaching Summary

## Key Concepts Demonstrated

### 1. Material Requirements Planning (MRP)
- **What**: Time-phased planning of material needs based on production schedules
- **Why**: Ensures materials are available when needed without excess inventory
- **How**: BOM explosion + lead time offset + safety stock considerations

### 2. Capacity Planning
- **Bottleneck Analysis**: Work center with highest utilization is the constraint
- **Current Bottleneck**: {manufacturing_plan['capacity_analysis'].get('bottleneck', 'None')}
- **Max Utilization**: {manufacturing_plan['capacity_analysis'].get('utilization_percent', 0)}%

### 3. Work Order Optimization
- **Sequencing**: Higher priority items scheduled first
- **Resource Allocation**: Work centers assigned based on capability and capacity
- **Lead Time Management**: Orders timed to prevent bottlenecks

### 4. Purchase Optimization
- **Supplier Selection**: Primary supplier from PLM data
- **Order Timing**: Lead time offset from production requirements
- **Cost Management**: Total material cost: ${manufacturing_plan['kpis']['total_material_cost']}

## Manufacturing Wisdom 🏭
> "Manufacturing is the art of optimization under constraints. Every decision involves trade-offs between cost, time, quality, and capacity."

## Integration Patterns
This bot demonstrates how BlackRoad bots collaborate:
- **Data Flow**: PLM-Analysis-BOT → Manufacturing-Operations-BOT → Treasury-BOT
- **Artifact Sharing**: JSON artifacts enable deterministic handoffs
- **Teaching Mode**: Each bot teaches others through documentation

## Next Level Learning
To understand advanced manufacturing, study:
- Theory of Constraints (TOC)
- Lean Manufacturing principles
- Just-In-Time (JIT) inventory
- Statistical Process Control (SPC)

*Generated by Manufacturing-Operations-BOT on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*
"""
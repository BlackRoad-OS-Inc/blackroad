"""
Supply Chain Management Bot - Orchestrates supplier relationships and logistics optimization.

MISSION: Optimize supply chain performance through strategic supplier management,
logistics coordination, and supply risk mitigation for manufacturing operations.

INPUTS:
- Purchase requirements from Manufacturing-Operations-BOT
- Supplier quality data from Quality-Control-BOT  
- Inventory levels and demand forecasts
- Supplier performance metrics and contracts

OUTPUTS:
- Optimized supplier selection and allocation strategies
- Logistics coordination and delivery scheduling
- Supply risk assessments and mitigation plans
- Supplier performance scorecards and improvement plans

KPIS:
- On-time delivery performance > 98%
- Supply cost reduction of 3-5% annually
- Supplier quality rating > 95%
- Supply chain risk score < 20% (low risk)

GUARDRAILS:
- Minimum 2 qualified suppliers for critical components
- No single supplier > 60% of category spend
- All suppliers must meet quality and compliance standards
- Supply chain disruption plans required for critical paths

HANDOFFS:
- Manufacturing-Operations-BOT: Receives purchase recommendations and schedules
- Quality-Control-BOT: Integrates supplier quality assessments
- Treasury-BOT: Coordinates payment terms and cash flow impact
- PLM-Analysis-BOT: Validates supplier technical capabilities

TEACHING NOTES:
Supply chain is about relationships, not just transactions! This bot teaches
the importance of strategic partnerships and risk management in global supply chains.
Key learning: The cheapest supplier is not always the best supplier!
"""

import json
import random
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List

from orchestrator.base import BaseBot
from orchestrator.protocols import Task, BotResponse
from plm import bom
from tools import storage


@dataclass
class SupplierProfile:
    """Comprehensive supplier profile with performance metrics."""
    supplier_id: str
    name: str
    category: str
    location: str
    lead_time_days: int
    quality_rating: float
    delivery_performance: float
    cost_competitiveness: float
    financial_stability: str
    risk_score: float
    contract_terms: Dict
    certifications: List[str]


@dataclass
class PurchaseRecommendation:
    """Optimized purchase recommendation with supplier allocation."""
    component_id: str
    total_quantity: float
    supplier_allocations: List[Dict]
    total_cost: float
    risk_assessment: str
    delivery_schedule: List[Dict]
    contract_requirements: List[str]


class SupplyChainManagementBot(BaseBot):
    name = "Supply-Chain-Management-BOT"
    mission = "Optimize supply chain performance through strategic supplier management"

    def run(self, task: Task) -> BotResponse:
        """Execute comprehensive supply chain optimization and management."""

        # Parse task context for supply chain requirements
        context = task.context or {}
        target_item = context.get("item_id", "PROD-100")
        target_revision = context.get("revision", "A")
        production_quantity = context.get("quantity", 100)
        urgency_level = context.get("urgency", "normal")  # normal, urgent, critical

        # Ensure PLM data is loaded (teaching: supply chain starts with accurate data!)
        bom.load_items('fixtures/plm/items')
        bom.load_boms('fixtures/plm/boms')

        # Step 1: Build comprehensive supplier profiles
        self._log_teaching_moment("Building Supplier Intelligence",
                                "Know your suppliers better than they know themselves")

        supplier_profiles = self._build_supplier_profiles(target_item, target_revision)

        # Step 2: Generate optimized purchase recommendations
        self._log_teaching_moment("Optimizing Supplier Selection",
                                "Balance cost, quality, delivery, and risk in supplier selection")

        purchase_recommendations = self._generate_purchase_strategy(
            target_item, target_revision, production_quantity, supplier_profiles, urgency_level)

        # Step 3: Assess supply chain risks
        self._log_teaching_moment("Evaluating Supply Chain Risks",
                                "Identify and mitigate supply chain vulnerabilities")

        risk_assessment = self._assess_supply_chain_risks(supplier_profiles, purchase_recommendations)

        # Step 4: Create logistics coordination plan
        logistics_plan = self._create_logistics_plan(purchase_recommendations, urgency_level)

        # Calculate supply chain performance metrics
        total_supply_cost = sum(rec.total_cost for rec in purchase_recommendations)
        average_lead_time = sum(sp.lead_time_days for sp in supplier_profiles) / len(supplier_profiles) if supplier_profiles else 0
        weighted_quality_score = self._calculate_weighted_quality_score(supplier_profiles, purchase_recommendations)

        # Create comprehensive supply chain strategy
        supply_chain_strategy = {
            "program_overview": {
                "item": f"{target_item}@{target_revision}",
                "production_quantity": production_quantity,
                "urgency_level": urgency_level,
                "strategy_date": datetime.now().strftime("%Y-%m-%d")
            },
            "supplier_intelligence": {
                "profiles": [
                    {
                        "supplier_id": sp.supplier_id,
                        "name": sp.name,
                        "category": sp.category,
                        "location": sp.location,
                        "lead_time": sp.lead_time_days,
                        "quality_rating": sp.quality_rating,
                        "delivery_performance": sp.delivery_performance,
                        "cost_competitiveness": sp.cost_competitiveness,
                        "financial_stability": sp.financial_stability,
                        "risk_score": sp.risk_score,
                        "certifications": sp.certifications
                    }
                    for sp in supplier_profiles
                ],
                "supplier_count": len(supplier_profiles),
                "average_quality_rating": weighted_quality_score
            },
            "purchase_strategy": {
                "recommendations": [
                    {
                        "component": rec.component_id,
                        "quantity": rec.total_quantity,
                        "supplier_split": rec.supplier_allocations,
                        "total_cost": rec.total_cost,
                        "risk_level": rec.risk_assessment,
                        "delivery_plan": rec.delivery_schedule,
                        "contract_needs": rec.contract_requirements
                    }
                    for rec in purchase_recommendations
                ],
                "total_cost": total_supply_cost,
                "cost_optimization": "Multi-supplier strategy for risk mitigation"
            },
            "risk_management": risk_assessment,
            "logistics_coordination": logistics_plan,
            "performance_targets": {
                "on_time_delivery": "> 98%",
                "quality_performance": f"{weighted_quality_score:.1f}%",
                "cost_competitiveness": "Top quartile",
                "supply_continuity": "99.9% availability"
            }
        }

        # Store artifacts with supply chain documentation
        artifacts_dir = Path("artifacts") / task.id
        artifacts_dir.mkdir(parents=True, exist_ok=True)

        strategy_file = artifacts_dir / "supply_chain_strategy.json"
        storage.write(str(strategy_file), json.dumps(supply_chain_strategy, indent=2))

        # Create supply chain teaching materials
        teaching_file = artifacts_dir / "supply_chain_lessons.md"
        teaching_content = self._create_supply_chain_teaching_guide(supply_chain_strategy)
        storage.write(str(teaching_file), teaching_content)

        return BotResponse(
            task_id=task.id,
            summary=f"Developed supply chain strategy for {target_item}@{target_revision}. "
                   f"Optimized sourcing across {len(supplier_profiles)} suppliers, "
                   f"total cost: ${total_supply_cost:.2f}, average lead time: {average_lead_time:.1f} days, "
                   f"weighted quality score: {weighted_quality_score:.1f}%",
            steps=[
                f"Built intelligence profiles for {len(supplier_profiles)} suppliers",
                f"Generated optimized purchase recommendations for {len(purchase_recommendations)} components",
                f"Assessed supply chain risks and developed mitigation strategies",
                f"Created logistics coordination plan for {urgency_level} delivery requirements",
                f"Calculated performance targets and KPIs",
                f"Stored comprehensive supply chain strategy and teaching materials"
            ],
            data=supply_chain_strategy,
            risks=[
                "Supplier performance based on historical data - monitor current conditions",
                "Supply chain disruptions possible due to external factors",
                "Cost optimization may require contract renegotiation",
                "Lead time assumptions subject to supplier capacity constraints"
            ],
            artifacts=[str(strategy_file), str(teaching_file)],
            next_actions=[
                "Share cost and payment terms with Treasury-BOT for cash flow planning",
                "Coordinate delivery schedules with Manufacturing-Operations-BOT",
                "Validate supplier quality requirements with Quality-Control-BOT",
                "Monitor supplier performance and adjust strategy as needed"
            ],
            ok=True
        )

    def _build_supplier_profiles(self, item_id: str, revision: str) -> List[SupplierProfile]:
        """Build comprehensive intelligence profiles for all suppliers."""
        profiles = []

        # Get all suppliers from BOM
        bom_structure = bom.explode(item_id, revision, level=3)
        suppliers = set()

        for _level, component_id, _qty in bom_structure:
            comp_key = (component_id, "A")
            if comp_key in bom.ITEMS:
                item = bom.ITEMS[comp_key]
                suppliers.update(item.suppliers)

        # Create detailed profiles for each supplier
        for supplier in suppliers:
            profiles.append(self._create_supplier_profile(supplier))

        return profiles

    def _create_supplier_profile(self, supplier_id: str) -> SupplierProfile:
        """Create detailed supplier profile with performance metrics."""
        # Simulate realistic supplier data (teaching: real systems would have actual data)
        base_performance = random.uniform(85, 98)
        
        # Generate realistic supplier characteristics
        locations = ["Shanghai, China", "Munich, Germany", "San Jose, USA", "Tokyo, Japan", "Bangalore, India"]
        categories = ["Electronics", "Mechanical", "Raw Materials", "Assemblies"]
        
        return SupplierProfile(
            supplier_id=supplier_id,
            name=f"{supplier_id} Manufacturing Corp",
            category=random.choice(categories),
            location=random.choice(locations),
            lead_time_days=random.randint(3, 21),
            quality_rating=round(base_performance + random.uniform(-3, 3), 1),
            delivery_performance=round(base_performance + random.uniform(-5, 2), 1),
            cost_competitiveness=round(random.uniform(75, 95), 1),
            financial_stability=self._assess_financial_stability(base_performance),
            risk_score=round(100 - base_performance + random.uniform(-5, 10), 1),
            contract_terms={
                "payment_terms": random.choice(["Net 30", "Net 45", "2/10 Net 30"]),
                "minimum_order": random.randint(100, 1000),
                "volume_discounts": random.choice([True, False]),
                "long_term_contract": random.choice([True, False])
            },
            certifications=self._generate_certifications(base_performance)
        )

    def _generate_purchase_strategy(self, item_id: str, revision: str, quantity: int,
                                  supplier_profiles: List[SupplierProfile], urgency: str) -> List[PurchaseRecommendation]:
        """Generate optimized purchase recommendations with supplier allocation."""
        recommendations = []

        # Get BOM requirements
        bom_structure = bom.explode(item_id, revision, level=2)

        for _level, component_id, bom_qty in bom_structure:
            total_required = bom_qty * quantity

            # Find suppliers for this component
            comp_key = (component_id, "A")
            if comp_key not in bom.ITEMS:
                continue

            item = bom.ITEMS[comp_key]
            component_suppliers = [sp for sp in supplier_profiles if sp.supplier_id in item.suppliers]

            if not component_suppliers:
                continue

            # Optimize supplier allocation
            allocations = self._optimize_supplier_allocation(
                component_suppliers, total_required, urgency)

            # Calculate total cost
            unit_cost = item.cost
            total_cost = total_required * unit_cost

            # Assess risk level
            risk_level = self._assess_component_risk(component_suppliers, allocations)

            # Create delivery schedule
            delivery_schedule = self._create_delivery_schedule(allocations, urgency)

            recommendations.append(PurchaseRecommendation(
                component_id=component_id,
                total_quantity=total_required,
                supplier_allocations=allocations,
                total_cost=total_cost,
                risk_assessment=risk_level,
                delivery_schedule=delivery_schedule,
                contract_requirements=self._determine_contract_requirements(component_suppliers, total_cost)
            ))

        return recommendations

    def _optimize_supplier_allocation(self, suppliers: List[SupplierProfile], 
                                    quantity: float, urgency: str) -> List[Dict]:
        """Optimize allocation across suppliers based on performance and risk."""
        if not suppliers:
            return []

        # Sort suppliers by composite score (quality + delivery + cost - risk)
        def supplier_score(supplier):
            quality_weight = 0.3
            delivery_weight = 0.3
            cost_weight = 0.2
            risk_weight = 0.2
            
            score = (supplier.quality_rating * quality_weight +
                    supplier.delivery_performance * delivery_weight +
                    supplier.cost_competitiveness * cost_weight -
                    supplier.risk_score * risk_weight)
            
            # Boost score for urgent orders if supplier has short lead time
            if urgency in ["urgent", "critical"] and supplier.lead_time_days <= 7:
                score += 10
                
            return score

        suppliers.sort(key=supplier_score, reverse=True)

        allocations = []
        
        if len(suppliers) == 1:
            # Single supplier - allocate 100%
            allocations.append({
                "supplier_id": suppliers[0].supplier_id,
                "percentage": 100.0,
                "quantity": quantity,
                "rationale": "Single qualified supplier available"
            })
        else:
            # Multi-supplier strategy for risk mitigation
            primary_supplier = suppliers[0]
            secondary_supplier = suppliers[1]
            
            # Allocation based on urgency and risk
            if urgency == "critical":
                # Favor best performer heavily but maintain backup
                primary_pct = 80.0
                secondary_pct = 20.0
            elif urgency == "urgent":
                # Balanced approach
                primary_pct = 70.0
                secondary_pct = 30.0
            else:
                # Standard risk mitigation
                primary_pct = 60.0
                secondary_pct = 40.0

            allocations.extend([
                {
                    "supplier_id": primary_supplier.supplier_id,
                    "percentage": primary_pct,
                    "quantity": quantity * primary_pct / 100,
                    "rationale": f"Primary supplier - highest composite score ({supplier_score(primary_supplier):.1f})"
                },
                {
                    "supplier_id": secondary_supplier.supplier_id,
                    "percentage": secondary_pct,
                    "quantity": quantity * secondary_pct / 100,
                    "rationale": f"Secondary supplier - risk mitigation and capacity backup"
                }
            ])

        return allocations

    def _assess_supply_chain_risks(self, suppliers: List[SupplierProfile], 
                                 recommendations: List[PurchaseRecommendation]) -> Dict:
        """Assess comprehensive supply chain risks and mitigation strategies."""
        # Geographic risk assessment
        locations = [sp.location for sp in suppliers]
        geographic_concentration = len(set(locations)) / len(locations) if locations else 1

        # Supplier concentration risk
        supplier_allocations = {}
        for rec in recommendations:
            for alloc in rec.supplier_allocations:
                supplier_id = alloc["supplier_id"]
                supplier_allocations[supplier_id] = supplier_allocations.get(supplier_id, 0) + alloc["quantity"]

        max_supplier_concentration = max(supplier_allocations.values()) / sum(supplier_allocations.values()) if supplier_allocations else 0

        # Financial stability risk
        high_risk_suppliers = [sp for sp in suppliers if sp.financial_stability in ["Poor", "At Risk"]]

        return {
            "overall_risk_score": round((100 - geographic_concentration * 100) * 0.3 +
                                      max_supplier_concentration * 100 * 0.4 +
                                      len(high_risk_suppliers) / len(suppliers) * 100 * 0.3 if suppliers else 0, 1),
            "geographic_risk": {
                "concentration_level": "Low" if geographic_concentration > 0.6 else "Medium" if geographic_concentration > 0.3 else "High",
                "unique_locations": len(set(locations)),
                "mitigation": "Diversify supplier base across regions"
            },
            "supplier_concentration": {
                "max_concentration": f"{max_supplier_concentration * 100:.1f}%",
                "risk_level": "Low" if max_supplier_concentration < 0.4 else "Medium" if max_supplier_concentration < 0.6 else "High",
                "mitigation": "Maintain multiple qualified suppliers per component"
            },
            "financial_stability": {
                "high_risk_count": len(high_risk_suppliers),
                "high_risk_suppliers": [sp.supplier_id for sp in high_risk_suppliers],
                "mitigation": "Monitor financial health and develop backup suppliers"
            },
            "mitigation_strategies": [
                "Implement dual sourcing for critical components",
                "Maintain strategic inventory buffers",
                "Develop supplier relationship management program",
                "Create supply chain disruption response procedures"
            ]
        }

    def _create_logistics_plan(self, recommendations: List[PurchaseRecommendation], urgency: str) -> Dict:
        """Create comprehensive logistics coordination plan."""
        # Calculate logistics requirements
        total_shipments = sum(len(rec.delivery_schedule) for rec in recommendations)
        
        # Determine transportation strategy based on urgency
        transport_strategy = {
            "normal": {"primary": "Ocean/Ground", "expedite": "Air for urgent items"},
            "urgent": {"primary": "Air/Express", "expedite": "Same day for critical"},
            "critical": {"primary": "Express/Same day", "expedite": "Charter if needed"}
        }.get(urgency, {"primary": "Standard", "expedite": "Express"})

        return {
            "coordination_overview": {
                "total_shipments": total_shipments,
                "urgency_level": urgency,
                "coordination_complexity": "High" if total_shipments > 10 else "Medium" if total_shipments > 5 else "Low"
            },
            "transportation_strategy": transport_strategy,
            "delivery_coordination": {
                "sequencing": "Coordinate arrivals with production schedule",
                "consolidation": "Combine shipments where possible to reduce cost",
                "tracking": "Real-time visibility for all shipments",
                "receiving": "Coordinate with manufacturing schedule"
            },
            "risk_mitigation": {
                "backup_plans": "Alternative transportation modes available",
                "insurance": "Cargo insurance for high-value shipments",
                "customs": "Pre-cleared documentation for international shipments"
            }
        }

    def _assess_financial_stability(self, performance: float) -> str:
        """Assess supplier financial stability."""
        if performance > 95:
            return "Excellent"
        elif performance > 90:
            return "Good"
        elif performance > 85:
            return "Fair"
        else:
            return "At Risk"

    def _generate_certifications(self, performance: float) -> List[str]:
        """Generate realistic supplier certifications."""
        base_certs = ["ISO 9001"]
        if performance > 90:
            base_certs.extend(["ISO 14001", "OHSAS 18001"])
        if performance > 95:
            base_certs.extend(["AS9100", "TS 16949"])
        return base_certs

    def _assess_component_risk(self, suppliers: List[SupplierProfile], allocations: List[Dict]) -> str:
        """Assess risk level for component sourcing."""
        if len(suppliers) == 1:
            return "High - Single source"
        elif any(alloc["percentage"] > 70 for alloc in allocations):
            return "Medium - Concentrated"
        else:
            return "Low - Diversified"

    def _create_delivery_schedule(self, allocations: List[Dict], urgency: str) -> List[Dict]:
        """Create optimized delivery schedule."""
        schedule = []
        base_date = datetime.now() + timedelta(days=7 if urgency == "critical" else 14 if urgency == "urgent" else 21)
        
        for i, alloc in enumerate(allocations):
            delivery_date = base_date + timedelta(days=i * 2)  # Stagger deliveries
            schedule.append({
                "supplier_id": alloc["supplier_id"],
                "quantity": alloc["quantity"],
                "requested_delivery": delivery_date.strftime("%Y-%m-%d"),
                "urgency": urgency
            })
        
        return schedule

    def _determine_contract_requirements(self, suppliers: List[SupplierProfile], total_cost: float) -> List[str]:
        """Determine contract requirements based on suppliers and order value."""
        requirements = ["Standard purchase order terms"]
        
        if total_cost > 10000:
            requirements.append("Volume pricing agreement")
        if total_cost > 50000:
            requirements.append("Long-term supply agreement")
        if any(sp.risk_score > 30 for sp in suppliers):
            requirements.append("Enhanced supplier monitoring")
        if len(suppliers) > 1:
            requirements.append("Allocation flexibility clause")
            
        return requirements

    def _calculate_weighted_quality_score(self, suppliers: List[SupplierProfile], 
                                        recommendations: List[PurchaseRecommendation]) -> float:
        """Calculate weighted quality score based on purchase allocations."""
        if not suppliers or not recommendations:
            return 0.0

        total_weight = 0
        weighted_sum = 0

        for rec in recommendations:
            for alloc in rec.supplier_allocations:
                supplier = next((sp for sp in suppliers if sp.supplier_id == alloc["supplier_id"]), None)
                if supplier:
                    weight = alloc["quantity"]
                    weighted_sum += supplier.quality_rating * weight
                    total_weight += weight

        return weighted_sum / total_weight if total_weight > 0 else 0.0

    def _log_teaching_moment(self, action: str, lesson: str):
        """Log teaching moments for knowledge sharing."""
        print(f"🎓 SUPPLY CHAIN TEACHING: {action} - {lesson}")

    def _create_supply_chain_teaching_guide(self, strategy: Dict) -> str:
        """Create educational guide about supply chain management principles."""
        return f"""# Supply Chain Management Teaching Guide

## Core Supply Chain Principles

### 1. Strategic Sourcing Philosophy
> "The cheapest supplier is not always the best supplier"

- **Total Cost of Ownership**: Price + Quality Cost + Risk Cost + Service Cost
- **Supplier Performance**: Our weighted quality score: {strategy['supplier_intelligence']['average_quality_rating']:.1f}%
- **Strategic Partnerships**: Long-term relationships create mutual value

### 2. Risk Management in Supply Chains
- **Overall Risk Score**: {strategy['risk_management']['overall_risk_score']:.1f}%
- **Geographic Diversification**: {strategy['risk_management']['geographic_risk']['unique_locations']} locations
- **Supplier Diversification**: Maximum concentration {strategy['risk_management']['supplier_concentration']['max_concentration']}

### 3. The Supply Chain Triad
```
    COST
     /\\
    /  \\
   /    \\
QUALITY--SERVICE
```
You can optimize any two, but the third will suffer. Great supply chains balance all three.

## Advanced Supply Chain Concepts

### 4. Bullwhip Effect
- **Problem**: Small demand changes amplify upstream
- **Solution**: Information sharing and collaboration
- **BlackRoad Approach**: Integrated planning across all bots

### 5. Supplier Relationship Management (SRM)
- **Transactional**: Buy based on price alone
- **Preferred**: Develop relationships with key suppliers  
- **Strategic**: Partner for innovation and competitive advantage
- **Our Approach**: {len(strategy['supplier_intelligence']['profiles'])} suppliers across multiple tiers

### 6. Supply Chain Resilience
- **Redundancy**: Multiple suppliers for critical items
- **Flexibility**: Ability to shift between suppliers quickly
- **Visibility**: Real-time monitoring of supplier performance
- **Collaboration**: Joint problem-solving with key suppliers

## Logistics Coordination Excellence

### 7. Transportation Optimization
- **Total Shipments**: {strategy['logistics_coordination']['coordination_overview']['total_shipments']}
- **Mode Selection**: Balance cost, speed, and reliability  
- **Consolidation**: Combine shipments to reduce cost and complexity

### 8. Inventory Strategy
- **Just-in-Time**: Minimize inventory while ensuring availability
- **Safety Stock**: Buffer against demand and supply variability
- **Strategic Inventory**: Position inventory for competitive advantage

## Supply Chain Integration with BlackRoad

### Cross-Functional Collaboration
- **Manufacturing**: Coordinate delivery with production schedules
- **Quality**: Ensure supplier quality meets requirements
- **Finance**: Optimize payment terms and cash flow impact
- **PLM**: Validate technical capabilities and specifications

### Data-Driven Decision Making
All supply chain decisions should be based on:
- **Performance Data**: Quality, delivery, cost metrics
- **Risk Assessment**: Financial, operational, geographic risks
- **Market Intelligence**: Industry trends and supplier capabilities
- **Total Cost Analysis**: Not just purchase price

## Global Supply Chain Considerations

### 9. Cultural Intelligence
- **Communication Styles**: Direct vs. indirect communication
- **Relationship Building**: Time investment in relationships
- **Business Practices**: Understanding local customs and practices

### 10. Regulatory Compliance
- **Import/Export**: Customs, duties, trade regulations
- **Quality Standards**: ISO, industry-specific certifications
- **Environmental**: Sustainability and environmental regulations

## Supply Chain Excellence Metrics

### Performance Scorecard
- **On-Time Delivery**: Target > 98%
- **Quality Performance**: Current {strategy['supplier_intelligence']['average_quality_rating']:.1f}%
- **Cost Competitiveness**: Top quartile benchmark
- **Supplier Reliability**: 99.9% availability target

### Continuous Improvement
- **Regular Supplier Reviews**: Quarterly business reviews
- **Performance Improvement Plans**: For underperforming suppliers
- **Innovation Partnerships**: Joint development projects
- **Market Benchmarking**: Continuous competitive analysis

## The Future of Supply Chain

### Digital Transformation
- **AI/ML**: Predictive analytics for demand and risk
- **IoT**: Real-time tracking and monitoring
- **Blockchain**: Transparency and traceability
- **Automation**: Robotic process automation for routine tasks

*Generated by Supply-Chain-Management-BOT on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*
"""
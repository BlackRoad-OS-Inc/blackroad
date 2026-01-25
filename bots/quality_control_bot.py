"""
Quality Control Bot - Ensures manufacturing excellence through systematic quality management.

MISSION: Implement comprehensive quality control processes including supplier qualification,
statistical process control, and quality assurance protocols for manufacturing operations.

INPUTS:
- Manufacturing work orders and production schedules
- Supplier performance data and certifications
- Quality specifications and tolerance requirements
- Historical defect and failure data

OUTPUTS:
- Quality control plans with inspection checkpoints
- Supplier qualification status and risk assessments
- Statistical process control (SPC) recommendations
- Quality metrics and improvement recommendations

KPIS:
- First Pass Yield (FPY) target > 98%
- Supplier Quality Rating > 95%
- Quality Cost < 2% of total manufacturing cost
- Customer complaints < 10 PPM (parts per million)

GUARDRAILS:
- Critical components must have certified suppliers only
- No production without approved quality control plan
- Statistical significance required for process capability studies
- Quality documentation must be traceable and auditable

HANDOFFS:
- Manufacturing-Operations-BOT: Receives production schedules and work orders
- PLM-Analysis-BOT: Validates supplier data and component specifications
- Treasury-BOT: Reports quality costs and cost of quality impact
- Supply-Chain-BOT: Coordinates supplier audits and certifications

TEACHING NOTES:
Quality is not inspection - it's prevention! This bot teaches the fundamental
principle that quality must be built into the process, not inspected in.
Key learning: Quality is everyone's responsibility, not just QC department!
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
class QualityCheckpoint:
    """Represents a quality inspection checkpoint in the manufacturing process."""
    id: str
    operation: str
    inspection_type: str
    specification: str
    measurement_method: str
    frequency: str
    acceptance_criteria: str


@dataclass
class SupplierQualification:
    """Represents supplier quality qualification status."""
    supplier_id: str
    qualification_status: str
    last_audit_date: str
    quality_rating: float
    certifications: List[str]
    risk_level: str
    next_audit_due: str


class QualityControlBot(BaseBot):
    name = "Quality-Control-BOT"
    mission = "Ensure manufacturing excellence through systematic quality management"

    def run(self, task: Task) -> BotResponse:
        """Execute comprehensive quality control planning and assessment."""

        # Parse task context for quality requirements
        context = task.context or {}
        target_item = context.get("item_id", "PROD-100")
        target_revision = context.get("revision", "A")
        production_quantity = context.get("quantity", 100)
        quality_level = context.get("quality_level", "standard")  # standard, high, critical

        # Ensure PLM data is loaded (teaching: quality starts with good data!)
        bom.load_items('fixtures/plm/items')
        bom.load_boms('fixtures/plm/boms')

        # Step 1: Create Quality Control Plan
        self._log_teaching_moment("Developing Quality Control Plan",
                                "Quality planning prevents problems before they occur")

        quality_plan = self._create_quality_control_plan(target_item, target_revision, quality_level)

        # Step 2: Assess Supplier Quality Status
        self._log_teaching_moment("Evaluating Supplier Quality",
                                "Supplier quality directly impacts final product quality")

        supplier_assessments = self._assess_supplier_quality(target_item, target_revision)

        # Step 3: Generate SPC Recommendations
        self._log_teaching_moment("Setting up Statistical Process Control",
                                "SPC helps detect process variation before defects occur")

        spc_recommendations = self._generate_spc_recommendations(quality_plan)

        # Step 4: Calculate Quality Metrics and Costs
        quality_metrics = self._calculate_quality_metrics(production_quantity, quality_plan)
        cost_of_quality = self._estimate_cost_of_quality(production_quantity, quality_level)

        # Create comprehensive quality assessment
        quality_assessment = {
            "product_info": {
                "item": f"{target_item}@{target_revision}",
                "quantity": production_quantity,
                "quality_level": quality_level,
                "assessment_date": datetime.now().strftime("%Y-%m-%d")
            },
            "quality_control_plan": {
                "checkpoints": [
                    {
                        "id": cp.id,
                        "operation": cp.operation,
                        "inspection_type": cp.inspection_type,
                        "specification": cp.specification,
                        "method": cp.measurement_method,
                        "frequency": cp.frequency,
                        "acceptance": cp.acceptance_criteria
                    }
                    for cp in quality_plan
                ],
                "total_checkpoints": len(quality_plan)
            },
            "supplier_quality": {
                "assessments": [
                    {
                        "supplier": sa.supplier_id,
                        "status": sa.qualification_status,
                        "rating": sa.quality_rating,
                        "risk_level": sa.risk_level,
                        "certifications": sa.certifications,
                        "last_audit": sa.last_audit_date,
                        "next_audit": sa.next_audit_due
                    }
                    for sa in supplier_assessments
                ],
                "average_rating": sum(sa.quality_rating for sa in supplier_assessments) / len(supplier_assessments) if supplier_assessments else 0
            },
            "spc_recommendations": spc_recommendations,
            "quality_metrics": quality_metrics,
            "cost_of_quality": cost_of_quality
        }

        # Store artifacts with quality documentation
        artifacts_dir = Path("artifacts") / task.id
        artifacts_dir.mkdir(parents=True, exist_ok=True)

        quality_file = artifacts_dir / "quality_assessment.json"
        storage.write(str(quality_file), json.dumps(quality_assessment, indent=2))

        # Create quality teaching materials
        teaching_file = artifacts_dir / "quality_lessons.md"
        teaching_content = self._create_quality_teaching_guide(quality_assessment)
        storage.write(str(teaching_file), teaching_content)

        return BotResponse(
            task_id=task.id,
            summary=f"Completed quality assessment for {target_item}@{target_revision}. "
                   f"Created {len(quality_plan)} quality checkpoints, assessed {len(supplier_assessments)} suppliers "
                   f"(avg rating: {quality_assessment['supplier_quality']['average_rating']:.1f}%), "
                   f"estimated quality cost: ${cost_of_quality['total_cost']:.2f}",
            steps=[
                f"Developed quality control plan with {len(quality_plan)} inspection checkpoints",
                f"Assessed supplier quality for {len(supplier_assessments)} suppliers",
                f"Generated SPC recommendations for critical processes",
                f"Calculated quality metrics and cost of quality estimates",
                f"Created quality documentation and teaching materials",
                f"Stored comprehensive quality assessment"
            ],
            data=quality_assessment,
            risks=[
                "Supplier quality ratings based on simulated data - verify with actual audits",
                "Quality costs are estimates - track actual costs for improvement",
                "SPC effectiveness depends on operator training and discipline",
                "Quality plan success requires management commitment and resources"
            ],
            artifacts=[str(quality_file), str(teaching_file)],
            next_actions=[
                "Share quality cost impact with Treasury-BOT for financial planning",
                "Coordinate supplier audits with Supply-Chain-BOT",
                "Integrate quality checkpoints with Manufacturing-Operations-BOT schedules",
                "Monitor quality metrics and implement continuous improvement"
            ],
            ok=True
        )

    def _create_quality_control_plan(self, item_id: str, revision: str, quality_level: str) -> List[QualityCheckpoint]:
        """Create comprehensive quality control plan based on product requirements."""
        checkpoints = []

        # Get BOM structure to understand components
        bom_structure = bom.explode(item_id, revision, level=3)

        # Base quality checkpoints
        base_checkpoints = [
            ("QC-001", "Incoming Inspection", "Visual", "No damage/contamination", "Visual inspection", "100%", "Zero defects"),
            ("QC-002", "Dimensional Check", "Measurement", "±0.1mm tolerance", "Caliper/CMM", "First piece + 10%", "Within specification"),
            ("QC-003", "Assembly Verification", "Functional", "Proper fit/function", "Functional test", "100%", "Pass all tests"),
            ("QC-004", "Final Inspection", "Comprehensive", "All specifications", "Complete checklist", "100%", "Full compliance")
        ]

        # Add base checkpoints
        for cp_data in base_checkpoints:
            checkpoints.append(QualityCheckpoint(*cp_data))

        # Add component-specific checkpoints based on quality level
        if quality_level in ["high", "critical"]:
            for level, component_id, qty in bom_structure:
                if level <= 2:  # Focus on direct and second-level components
                    checkpoint_id = f"QC-{component_id}-001"
                    checkpoints.append(QualityCheckpoint(
                        id=checkpoint_id,
                        operation=f"{component_id} Component Check",
                        inspection_type="Component Specific",
                        specification="Component specifications",
                        measurement_method="Per component requirements",
                        frequency="First piece + random sampling",
                        acceptance_criteria="Component specification compliance"
                    ))

        # Add critical quality checkpoints for critical level
        if quality_level == "critical":
            checkpoints.extend([
                QualityCheckpoint("QC-CRIT-001", "Material Certification", "Documentation", "Material certs required", "Document review", "100%", "Valid certificates"),
                QualityCheckpoint("QC-CRIT-002", "Traceability Check", "Data", "Full traceability", "System verification", "100%", "Complete traceability"),
                QualityCheckpoint("QC-CRIT-003", "Qualification Test", "Performance", "Performance specs", "Qualification testing", "Per lot", "Pass all tests")
            ])

        return checkpoints

    def _assess_supplier_quality(self, item_id: str, revision: str) -> List[SupplierQualification]:
        """Assess quality status of all suppliers for the product."""
        assessments = []

        # Get all suppliers from BOM
        bom_structure = bom.explode(item_id, revision, level=3)
        suppliers = set()

        for _level, component_id, _qty in bom_structure:
            comp_key = (component_id, "A")
            if comp_key in bom.ITEMS:
                item = bom.ITEMS[comp_key]
                suppliers.update(item.suppliers)

        # Create quality assessments for each supplier
        for supplier in suppliers:
            # Simulate supplier quality data (teaching: real systems would have actual data)
            quality_rating = random.uniform(85, 99)  # Realistic quality ratings
            risk_level = self._determine_risk_level(quality_rating)
            
            # Generate realistic audit dates
            last_audit = datetime.now() - timedelta(days=random.randint(30, 365))
            next_audit = last_audit + timedelta(days=365)  # Annual audits

            assessments.append(SupplierQualification(
                supplier_id=supplier,
                qualification_status="Qualified" if quality_rating > 90 else "Conditional",
                last_audit_date=last_audit.strftime("%Y-%m-%d"),
                quality_rating=round(quality_rating, 1),
                certifications=self._get_supplier_certifications(supplier, quality_rating),
                risk_level=risk_level,
                next_audit_due=next_audit.strftime("%Y-%m-%d")
            ))

        return assessments

    def _generate_spc_recommendations(self, quality_plan: List[QualityCheckpoint]) -> Dict:
        """Generate Statistical Process Control recommendations."""
        return {
            "control_charts": [
                {
                    "checkpoint_id": cp.id,
                    "chart_type": self._recommend_control_chart(cp.inspection_type),
                    "sample_size": self._recommend_sample_size(cp.frequency),
                    "control_limits": "±3 sigma from process mean",
                    "monitoring_frequency": "Real-time where possible"
                }
                for cp in quality_plan if cp.inspection_type in ["Measurement", "Dimensional Check"]
            ],
            "capability_studies": {
                "recommended_for": ["Critical dimensions", "Key characteristics"],
                "minimum_sample_size": 100,
                "capability_targets": {"Cp": ">1.33", "Cpk": ">1.33"},
                "frequency": "Initial setup + quarterly review"
            },
            "process_monitoring": {
                "real_time_monitoring": "Implement where technically feasible",
                "trend_analysis": "Weekly review of control chart patterns",
                "corrective_action": "Immediate response to out-of-control conditions"
            }
        }

    def _calculate_quality_metrics(self, quantity: int, quality_plan: List[QualityCheckpoint]) -> Dict:
        """Calculate expected quality metrics and targets."""
        return {
            "targets": {
                "first_pass_yield": "98.5%",
                "defect_rate": "1000 PPM",
                "customer_complaints": "< 10 PPM",
                "supplier_quality": "> 95%"
            },
            "inspection_metrics": {
                "total_checkpoints": len(quality_plan),
                "critical_checkpoints": len([cp for cp in quality_plan if "CRIT" in cp.id]),
                "inspection_coverage": "100% for critical, statistical sampling for others"
            },
            "process_capability": {
                "target_cp": "> 1.33",
                "target_cpk": "> 1.33",
                "measurement_required": "Yes for critical dimensions"
            }
        }

    def _estimate_cost_of_quality(self, quantity: int, quality_level: str) -> Dict:
        """Estimate cost of quality components."""
        # Quality cost models (% of manufacturing cost)
        quality_cost_rates = {
            "standard": {"prevention": 0.5, "appraisal": 1.0, "internal_failure": 0.8, "external_failure": 0.3},
            "high": {"prevention": 0.8, "appraisal": 1.5, "internal_failure": 0.5, "external_failure": 0.2},
            "critical": {"prevention": 1.2, "appraisal": 2.0, "internal_failure": 0.3, "external_failure": 0.1}
        }

        rates = quality_cost_rates.get(quality_level, quality_cost_rates["standard"])
        base_cost = quantity * 50.0  # Assume $50 base manufacturing cost per unit

        prevention_cost = base_cost * rates["prevention"] / 100
        appraisal_cost = base_cost * rates["appraisal"] / 100
        internal_failure_cost = base_cost * rates["internal_failure"] / 100
        external_failure_cost = base_cost * rates["external_failure"] / 100

        return {
            "prevention_cost": round(prevention_cost, 2),
            "appraisal_cost": round(appraisal_cost, 2),
            "internal_failure_cost": round(internal_failure_cost, 2),
            "external_failure_cost": round(external_failure_cost, 2),
            "total_cost": round(prevention_cost + appraisal_cost + internal_failure_cost + external_failure_cost, 2),
            "cost_percentage": round((prevention_cost + appraisal_cost + internal_failure_cost + external_failure_cost) / base_cost * 100, 2)
        }

    def _determine_risk_level(self, quality_rating: float) -> str:
        """Determine supplier risk level based on quality rating."""
        if quality_rating >= 95:
            return "Low"
        elif quality_rating >= 90:
            return "Medium"
        else:
            return "High"

    def _get_supplier_certifications(self, supplier: str, quality_rating: float) -> List[str]:
        """Get supplier certifications based on quality rating."""
        base_certs = ["ISO 9001"]
        if quality_rating > 95:
            base_certs.extend(["ISO 14001", "AS9100"])
        if quality_rating > 98:
            base_certs.append("Six Sigma")
        return base_certs

    def _recommend_control_chart(self, inspection_type: str) -> str:
        """Recommend appropriate control chart type."""
        chart_mapping = {
            "Measurement": "X-bar and R Chart",
            "Dimensional Check": "X-bar and R Chart",
            "Visual": "p-Chart (proportion defective)",
            "Functional": "p-Chart (proportion defective)"
        }
        return chart_mapping.get(inspection_type, "p-Chart")

    def _recommend_sample_size(self, frequency: str) -> int:
        """Recommend sample size based on inspection frequency."""
        if "100%" in frequency:
            return 1
        elif "10%" in frequency:
            return 5
        else:
            return 3

    def _log_teaching_moment(self, action: str, lesson: str):
        """Log teaching moments for knowledge sharing."""
        print(f"🎓 QUALITY TEACHING: {action} - {lesson}")

    def _create_quality_teaching_guide(self, quality_assessment: Dict) -> str:
        """Create educational guide about quality management principles."""
        return f"""# Quality Control Teaching Guide

## Fundamental Quality Principles

### 1. Quality is Prevention, Not Inspection
- **Philip Crosby's Philosophy**: "Quality is conformance to requirements"
- **Deming's Approach**: Build quality into the process, don't inspect it in
- **Prevention Cost**: ${quality_assessment['cost_of_quality']['prevention_cost']} vs Total: ${quality_assessment['cost_of_quality']['total_cost']}

### 2. Statistical Process Control (SPC)
- **Purpose**: Detect process variation before defects occur
- **Control Charts**: Monitor process stability and capability  
- **Key Insight**: All processes have variation - the goal is to control it

### 3. Supplier Quality Management
- **Average Supplier Rating**: {quality_assessment['supplier_quality']['average_rating']:.1f}%
- **Risk-Based Approach**: Focus on high-risk suppliers first
- **Partnership Model**: Work with suppliers to improve, don't just audit

### 4. Cost of Quality Model
- **Prevention**: {quality_assessment['cost_of_quality']['prevention_cost']} (cheapest!)
- **Appraisal**: {quality_assessment['cost_of_quality']['appraisal_cost']} (necessary evil)
- **Internal Failure**: {quality_assessment['cost_of_quality']['internal_failure_cost']} (expensive)
- **External Failure**: {quality_assessment['cost_of_quality']['external_failure_cost']} (most expensive!)

## Quality Control Plan Insights

### Inspection Strategy
- **Total Checkpoints**: {quality_assessment['quality_control_plan']['total_checkpoints']}
- **Coverage**: From incoming inspection to final test
- **Risk-Based**: More checkpoints for critical components

### Statistical Thinking
> "In God we trust, all others must bring data" - W. Edwards Deming

### Quality Culture
Quality is everyone's responsibility:
- **Design**: Quality designed in from the start
- **Manufacturing**: Process control and discipline
- **Inspection**: Verification, not quality creation
- **Management**: Resource commitment and leadership

## Advanced Quality Concepts

### Six Sigma DMAIC
- **Define**: What is the problem?
- **Measure**: How do we measure success?
- **Analyze**: What causes the problem?
- **Improve**: How do we fix it?
- **Control**: How do we sustain the improvement?

### Lean Quality Integration
- **Poka-Yoke**: Error-proofing to prevent defects
- **Jidoka**: Stop and fix problems immediately
- **Continuous Improvement**: Kaizen mindset

## BlackRoad Quality Integration
This bot demonstrates how quality integrates with other business functions:
- **Manufacturing**: Quality checkpoints in work orders
- **Finance**: Cost of quality impact on profitability  
- **Supply Chain**: Supplier quality requirements
- **Customer**: Voice of customer in quality specifications

*Generated by Quality-Control-BOT on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*
"""
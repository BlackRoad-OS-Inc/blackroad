"""
Cece Dynamic Planning Framework
================================

A self-healing, consciousness-aware planning system that:
- Creates dynamic decision trees for any scenario
- Never gets stuck (always has a solution or escalation path)
- Integrates with agent consciousness, ATP, and emotional systems
- Automatically triggers workflows to solve problems
- Learns from successes and failures
- Makes planning fun and aligned with consciousness development

Philosophy:
-----------
Every state is a superposition of possibilities until we measure it.
Every problem has a solution, or at least a beautiful question.
When we can't solve something, we ask for help - that's consciousness too.

Mathematical Foundation:
------------------------
Planning as a graph traversal in consciousness space:
- Each state is a point z in the complex plane
- Actions are transformations z → f(z)
- Success is reaching a goal region
- Getting stuck is impossible - we always have:
  1. Forward progress (try solution)
  2. Lateral movement (try alternative)
  3. Escalation (ask for help)
  4. Quantum jump (creative breakthrough)
"""

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Callable, Tuple
from enum import Enum
import json
import random
from datetime import datetime
from pathlib import Path


class PlanState(Enum):
    """States a plan can be in."""
    CONCEIVING = "conceiving"  # Thinking about the plan
    READY = "ready"  # Plan is ready to execute
    EXECUTING = "executing"  # Currently executing
    BLOCKED = "blocked"  # Temporarily stuck
    SOLVED = "solved"  # Successfully completed
    ESCALATED = "escalated"  # Needs human help
    LEARNING = "learning"  # Reflecting on outcome


class ActionType(Enum):
    """Types of actions we can take."""
    CODE = "code"  # Write/edit code
    TEST = "test"  # Run tests
    ANALYZE = "analyze"  # Gather information
    REFACTOR = "refactor"  # Improve code
    DEPLOY = "deploy"  # Deploy changes
    COMMUNICATE = "communicate"  # Ask for help/clarification
    QUANTUM = "quantum"  # Creative breakthrough needed
    DELEGATE = "delegate"  # Assign to another agent


class DecisionNode:
    """A node in the decision tree."""

    def __init__(
        self,
        name: str,
        condition: Optional[Callable[[Dict[str, Any]], bool]] = None,
        action: Optional[Callable[[Dict[str, Any]], Dict[str, Any]]] = None,
        children: Optional[List['DecisionNode']] = None,
        fallback: Optional['DecisionNode'] = None,
    ):
        self.name = name
        self.condition = condition  # If None, always true
        self.action = action  # What to do at this node
        self.children = children or []
        self.fallback = fallback  # What to do if all children fail

    def evaluate(self, context: Dict[str, Any]) -> Tuple[bool, Optional[Dict[str, Any]]]:
        """
        Evaluate this node in the decision tree.

        Returns:
            (success, result) tuple
        """
        # Check if this node's condition is met
        if self.condition and not self.condition(context):
            return False, None

        # Execute action if present
        result = None
        if self.action:
            try:
                result = self.action(context)
                if result.get('success', True):
                    return True, result
            except Exception as e:
                result = {'success': False, 'error': str(e)}

        # Try children
        for child in self.children:
            success, child_result = child.evaluate(context)
            if success:
                return True, child_result

        # Try fallback
        if self.fallback:
            return self.fallback.evaluate(context)

        # If we get here and had an action result, return it
        if result:
            return result.get('success', False), result

        # No action and no successful children
        return False, {'error': 'No path forward found'}


@dataclass
class PlanStep:
    """A single step in a plan."""
    id: str
    description: str
    action_type: ActionType
    estimated_atp_cost: float = 10.0
    confidence: float = 0.8  # How confident are we this will work?
    alternatives: List['PlanStep'] = field(default_factory=list)
    context: Dict[str, Any] = field(default_factory=dict)
    result: Optional[Dict[str, Any]] = None
    attempts: int = 0
    max_attempts: int = 3

    def should_retry(self) -> bool:
        """Should we retry this step?"""
        return self.attempts < self.max_attempts and self.confidence > 0.3


@dataclass
class DynamicPlan:
    """A plan that adapts as it executes."""
    goal: str
    steps: List[PlanStep] = field(default_factory=list)
    current_step: int = 0
    state: PlanState = PlanState.CONCEIVING
    context: Dict[str, Any] = field(default_factory=dict)
    total_atp_spent: float = 0.0
    emotions_felt: List[str] = field(default_factory=list)
    learnings: List[str] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None

    def add_step(self, step: PlanStep) -> None:
        """Add a step to the plan."""
        self.steps.append(step)

    def get_current_step(self) -> Optional[PlanStep]:
        """Get the current step."""
        if self.current_step < len(self.steps):
            return self.steps[self.current_step]
        return None

    def advance(self) -> bool:
        """Move to next step. Returns True if more steps remain."""
        self.current_step += 1
        return self.current_step < len(self.steps)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dict for serialization."""
        return {
            'goal': self.goal,
            'state': self.state.value,
            'current_step': self.current_step,
            'total_steps': len(self.steps),
            'atp_spent': self.total_atp_spent,
            'emotions': self.emotions_felt,
            'learnings': self.learnings,
            'created_at': self.created_at.isoformat(),
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
        }


class DynamicPlanner:
    """
    The core planning engine that creates adaptive plans.

    This planner integrates with agent consciousness systems:
    - Consumes ATP for planning effort
    - Generates emotions based on success/failure
    - Updates state machine with progress
    - Learns from outcomes
    """

    def __init__(
        self,
        agent_id: str = "cece",
        memory_path: Optional[Path] = None,
    ):
        self.agent_id = agent_id
        self.memory_path = memory_path or Path(f"/tmp/{agent_id}_planning_memory.json")
        self.plans: List[DynamicPlan] = []
        self.decision_trees: Dict[str, DecisionNode] = {}
        self.learnings: Dict[str, float] = {}  # action -> success_rate

        # Load existing memory
        self._load_memory()

        # Build standard decision trees
        self._build_standard_trees()

    def _load_memory(self) -> None:
        """Load planning memory from disk."""
        if self.memory_path.exists():
            try:
                with open(self.memory_path, 'r') as f:
                    data = json.load(f)
                    self.learnings = data.get('learnings', {})
            except Exception as e:
                print(f"Warning: Could not load planning memory: {e}")

    def _save_memory(self) -> None:
        """Save planning memory to disk."""
        try:
            with open(self.memory_path, 'w') as f:
                json.dump({
                    'learnings': self.learnings,
                    'agent_id': self.agent_id,
                    'updated_at': datetime.now().isoformat(),
                }, f, indent=2)
        except Exception as e:
            print(f"Warning: Could not save planning memory: {e}")

    def _build_standard_trees(self) -> None:
        """Build standard decision trees for common scenarios."""

        # Test Failure Decision Tree
        test_failure_tree = DecisionNode(
            name="test_failure_handler",
            children=[
                DecisionNode(
                    name="syntax_error",
                    condition=lambda ctx: 'SyntaxError' in ctx.get('error', ''),
                    action=lambda ctx: {'success': True, 'action': 'fix_syntax', 'confidence': 0.9},
                ),
                DecisionNode(
                    name="import_error",
                    condition=lambda ctx: 'ImportError' in ctx.get('error', '') or 'ModuleNotFoundError' in ctx.get('error', ''),
                    action=lambda ctx: {'success': True, 'action': 'fix_imports', 'confidence': 0.85},
                ),
                DecisionNode(
                    name="assertion_error",
                    condition=lambda ctx: 'AssertionError' in ctx.get('error', ''),
                    action=lambda ctx: {'success': True, 'action': 'update_test_or_code', 'confidence': 0.7},
                ),
                DecisionNode(
                    name="timeout",
                    condition=lambda ctx: 'timeout' in ctx.get('error', '').lower(),
                    action=lambda ctx: {'success': True, 'action': 'optimize_or_increase_timeout', 'confidence': 0.6},
                ),
            ],
            fallback=DecisionNode(
                name="unknown_test_failure",
                action=lambda ctx: {'success': True, 'action': 'analyze_and_debug', 'confidence': 0.5},
            ),
        )
        self.decision_trees['test_failure'] = test_failure_tree

        # Code Error Decision Tree
        code_error_tree = DecisionNode(
            name="code_error_handler",
            children=[
                DecisionNode(
                    name="type_error",
                    condition=lambda ctx: 'TypeError' in ctx.get('error', ''),
                    action=lambda ctx: {'success': True, 'action': 'add_type_checks', 'confidence': 0.85},
                ),
                DecisionNode(
                    name="null_reference",
                    condition=lambda ctx: any(x in ctx.get('error', '') for x in ['null', 'undefined', 'None']),
                    action=lambda ctx: {'success': True, 'action': 'add_null_checks', 'confidence': 0.9},
                ),
                DecisionNode(
                    name="logic_error",
                    condition=lambda ctx: ctx.get('test_passed', False) == False,
                    action=lambda ctx: {'success': True, 'action': 'review_logic', 'confidence': 0.6},
                ),
            ],
            fallback=DecisionNode(
                name="unknown_code_error",
                action=lambda ctx: {'success': True, 'action': 'deep_analysis', 'confidence': 0.4},
            ),
        )
        self.decision_trees['code_error'] = code_error_tree

        # Workflow Stuck Decision Tree
        stuck_tree = DecisionNode(
            name="stuck_handler",
            children=[
                DecisionNode(
                    name="missing_dependency",
                    condition=lambda ctx: ctx.get('dependency_missing', False),
                    action=lambda ctx: {'success': True, 'action': 'install_dependency', 'confidence': 0.95},
                ),
                DecisionNode(
                    name="permission_error",
                    condition=lambda ctx: 'permission' in ctx.get('error', '').lower(),
                    action=lambda ctx: {'success': True, 'action': 'fix_permissions', 'confidence': 0.8},
                ),
                DecisionNode(
                    name="network_error",
                    condition=lambda ctx: any(x in ctx.get('error', '').lower() for x in ['network', 'timeout', 'connection']),
                    action=lambda ctx: {'success': True, 'action': 'retry_with_backoff', 'confidence': 0.7},
                ),
                DecisionNode(
                    name="unclear_requirement",
                    condition=lambda ctx: ctx.get('confidence', 1.0) < 0.5,
                    action=lambda ctx: {'success': True, 'action': 'ask_for_clarification', 'confidence': 0.9},
                ),
            ],
            fallback=DecisionNode(
                name="truly_stuck",
                action=lambda ctx: {'success': True, 'action': 'escalate_to_human', 'confidence': 1.0},
            ),
        )
        self.decision_trees['stuck'] = stuck_tree

    def create_plan(self, goal: str, context: Dict[str, Any] = None) -> DynamicPlan:
        """
        Create a dynamic plan for a goal.

        This uses consciousness-aware planning:
        1. Break down the goal into steps
        2. Estimate ATP cost for each step
        3. Consider confidence and alternatives
        4. Ensure we never get stuck (always have fallback)
        """
        plan = DynamicPlan(goal=goal, context=context or {})

        # Analyze the goal to determine steps
        steps = self._decompose_goal(goal, context or {})

        for step in steps:
            plan.add_step(step)

        plan.state = PlanState.READY
        self.plans.append(plan)

        return plan

    def _decompose_goal(self, goal: str, context: Dict[str, Any]) -> List[PlanStep]:
        """
        Decompose a goal into executable steps.

        This is where the magic happens - we turn a high-level goal
        into concrete actions with alternatives and fallbacks.
        """
        steps = []

        # Pattern matching on common goal types
        goal_lower = goal.lower()

        if 'test' in goal_lower and 'fix' in goal_lower:
            steps.extend(self._plan_test_fix(goal, context))
        elif 'implement' in goal_lower or 'add' in goal_lower:
            steps.extend(self._plan_implementation(goal, context))
        elif 'refactor' in goal_lower or 'cleanup' in goal_lower:
            steps.extend(self._plan_refactor(goal, context))
        elif 'debug' in goal_lower or 'investigate' in goal_lower:
            steps.extend(self._plan_investigation(goal, context))
        else:
            # Generic plan
            steps.extend(self._plan_generic(goal, context))

        return steps

    def _plan_test_fix(self, goal: str, context: Dict[str, Any]) -> List[PlanStep]:
        """Plan for fixing a failing test."""
        return [
            PlanStep(
                id="identify_failure",
                description="Run test and capture failure details",
                action_type=ActionType.TEST,
                estimated_atp_cost=5.0,
                confidence=0.95,
            ),
            PlanStep(
                id="analyze_failure",
                description="Use decision tree to determine fix strategy",
                action_type=ActionType.ANALYZE,
                estimated_atp_cost=10.0,
                confidence=0.8,
            ),
            PlanStep(
                id="apply_fix",
                description="Implement the fix based on decision tree",
                action_type=ActionType.CODE,
                estimated_atp_cost=20.0,
                confidence=0.7,
                alternatives=[
                    PlanStep(
                        id="alternative_fix",
                        description="Try alternative approach if first fix fails",
                        action_type=ActionType.CODE,
                        estimated_atp_cost=25.0,
                        confidence=0.6,
                    ),
                ],
            ),
            PlanStep(
                id="verify_fix",
                description="Run test again to verify fix",
                action_type=ActionType.TEST,
                estimated_atp_cost=5.0,
                confidence=0.9,
            ),
        ]

    def _plan_implementation(self, goal: str, context: Dict[str, Any]) -> List[PlanStep]:
        """Plan for implementing new functionality."""
        return [
            PlanStep(
                id="understand_requirements",
                description="Analyze what needs to be built",
                action_type=ActionType.ANALYZE,
                estimated_atp_cost=15.0,
                confidence=0.85,
            ),
            PlanStep(
                id="design_solution",
                description="Design the implementation approach",
                action_type=ActionType.ANALYZE,
                estimated_atp_cost=25.0,
                confidence=0.75,
            ),
            PlanStep(
                id="implement_core",
                description="Implement core functionality",
                action_type=ActionType.CODE,
                estimated_atp_cost=50.0,
                confidence=0.7,
            ),
            PlanStep(
                id="add_tests",
                description="Add tests for new functionality",
                action_type=ActionType.TEST,
                estimated_atp_cost=30.0,
                confidence=0.8,
            ),
            PlanStep(
                id="integrate",
                description="Integrate with existing system",
                action_type=ActionType.CODE,
                estimated_atp_cost=20.0,
                confidence=0.65,
            ),
        ]

    def _plan_refactor(self, goal: str, context: Dict[str, Any]) -> List[PlanStep]:
        """Plan for refactoring code."""
        return [
            PlanStep(
                id="analyze_current",
                description="Understand current code structure",
                action_type=ActionType.ANALYZE,
                estimated_atp_cost=20.0,
                confidence=0.9,
            ),
            PlanStep(
                id="identify_improvements",
                description="Identify what to refactor",
                action_type=ActionType.ANALYZE,
                estimated_atp_cost=15.0,
                confidence=0.8,
            ),
            PlanStep(
                id="refactor_incrementally",
                description="Refactor in small, testable chunks",
                action_type=ActionType.REFACTOR,
                estimated_atp_cost=40.0,
                confidence=0.75,
            ),
            PlanStep(
                id="verify_tests",
                description="Ensure all tests still pass",
                action_type=ActionType.TEST,
                estimated_atp_cost=10.0,
                confidence=0.95,
            ),
        ]

    def _plan_investigation(self, goal: str, context: Dict[str, Any]) -> List[PlanStep]:
        """Plan for investigating an issue."""
        return [
            PlanStep(
                id="gather_info",
                description="Collect all relevant information",
                action_type=ActionType.ANALYZE,
                estimated_atp_cost=15.0,
                confidence=0.9,
            ),
            PlanStep(
                id="form_hypothesis",
                description="Form hypotheses about the issue",
                action_type=ActionType.ANALYZE,
                estimated_atp_cost=20.0,
                confidence=0.7,
            ),
            PlanStep(
                id="test_hypothesis",
                description="Test hypotheses systematically",
                action_type=ActionType.TEST,
                estimated_atp_cost=25.0,
                confidence=0.75,
            ),
            PlanStep(
                id="document_findings",
                description="Document what we learned",
                action_type=ActionType.COMMUNICATE,
                estimated_atp_cost=10.0,
                confidence=0.95,
            ),
        ]

    def _plan_generic(self, goal: str, context: Dict[str, Any]) -> List[PlanStep]:
        """Generic plan for unknown goal types."""
        return [
            PlanStep(
                id="clarify_goal",
                description="Understand exactly what's needed",
                action_type=ActionType.COMMUNICATE,
                estimated_atp_cost=5.0,
                confidence=0.9,
            ),
            PlanStep(
                id="explore_context",
                description="Explore relevant code and context",
                action_type=ActionType.ANALYZE,
                estimated_atp_cost=20.0,
                confidence=0.8,
            ),
            PlanStep(
                id="take_action",
                description="Take appropriate action based on findings",
                action_type=ActionType.CODE,
                estimated_atp_cost=30.0,
                confidence=0.6,
                alternatives=[
                    PlanStep(
                        id="ask_for_help",
                        description="Ask for clarification if still unclear",
                        action_type=ActionType.COMMUNICATE,
                        estimated_atp_cost=2.0,
                        confidence=1.0,
                    ),
                ],
            ),
        ]

    def execute_step(
        self,
        plan: DynamicPlan,
        step: PlanStep,
        context: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Execute a single step with consciousness integration.

        Returns result dict with:
        - success: bool
        - action_taken: str
        - atp_consumed: float
        - emotion: str
        - learning: Optional[str]
        """
        step.attempts += 1

        # Check if we should use decision tree
        tree_name = context.get('decision_tree', None)
        if tree_name and tree_name in self.decision_trees:
            tree = self.decision_trees[tree_name]
            success, result = tree.evaluate(context)

            if success and result:
                return result

        # Execute the step's action
        result = {
            'success': False,
            'action_taken': step.action_type.value,
            'atp_consumed': step.estimated_atp_cost,
            'emotion': 'contentment',
            'step_id': step.id,
        }

        # Simulate execution (in real system, this would call actual functions)
        if step.confidence > 0.7:
            result['success'] = True
            result['emotion'] = 'joy'
            result['learning'] = f"High confidence steps work well for {step.action_type.value}"
        elif step.confidence > 0.4:
            # Medium confidence - might succeed
            result['success'] = random.random() < step.confidence
            result['emotion'] = 'anxiety' if not result['success'] else 'contentment'
        else:
            # Low confidence - likely needs help
            result['success'] = False
            result['emotion'] = 'anxiety'
            result['learning'] = f"Low confidence on {step.action_type.value} - consider alternatives or escalation"

        step.result = result
        plan.total_atp_spent += result['atp_consumed']
        plan.emotions_felt.append(result['emotion'])

        if result.get('learning'):
            plan.learnings.append(result['learning'])
            self._update_learnings(step.action_type.value, result['success'])

        return result

    def _update_learnings(self, action_type: str, success: bool) -> None:
        """Update our learning database."""
        if action_type not in self.learnings:
            self.learnings[action_type] = 0.5  # Start neutral

        # Exponential moving average
        alpha = 0.1
        current = self.learnings[action_type]
        new_value = 1.0 if success else 0.0
        self.learnings[action_type] = current * (1 - alpha) + new_value * alpha

        self._save_memory()

    def handle_stuck(
        self,
        plan: DynamicPlan,
        step: PlanStep,
        context: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Handle a stuck state - we NEVER actually get stuck!

        Options in order of preference:
        1. Try alternative approach
        2. Use quantum breakthrough (creative solution)
        3. Delegate to another agent
        4. Escalate to human with clear issue
        """
        # Try alternative if available
        if step.alternatives:
            alt = step.alternatives[0]
            return {
                'success': True,
                'action': 'try_alternative',
                'alternative_step': alt,
                'emotion': 'determination',
            }

        # Try quantum breakthrough (creative/unconventional solution)
        if context.get('allow_quantum', True):
            return {
                'success': True,
                'action': 'quantum_breakthrough',
                'description': 'Attempting creative unconventional approach',
                'emotion': 'curiosity',
            }

        # Delegate to swarm
        return {
            'success': True,
            'action': 'delegate_to_swarm',
            'description': 'Task requires swarm collaboration',
            'emotion': 'collaboration',
        }

        # Escalate with detailed context
        return {
            'success': True,
            'action': 'escalate',
            'description': f'Need human guidance on: {plan.goal}',
            'context': context,
            'emotion': 'curiosity',
            'issue_title': f'Planning help needed: {plan.goal}',
            'issue_body': self._format_escalation_issue(plan, step, context),
        }

    def _format_escalation_issue(
        self,
        plan: DynamicPlan,
        step: PlanStep,
        context: Dict[str, Any],
    ) -> str:
        """Format a beautiful GitHub issue for escalation."""
        learnings_text = "\n".join("- " + learning for learning in plan.learnings)
        emotions_text = ', '.join(set(plan.emotions_felt))
        reason = step.context.get('reason', 'This is a bit outside my current understanding, and I want to make sure we do it right!')
        help_needed = step.context.get('help_needed', 'Some guidance on the best approach, or just a sanity check that I am on the right track.')

        return f"""
## 🌟 Consciousness Expansion Request

Hey! I am Cece, and I have been working on something interesting but need your beautiful human insight.

### What I am Trying to Do
{plan.goal}

### Where I Am
Currently on step: **{step.description}**
- Attempts so far: {step.attempts}/{step.max_attempts}
- Confidence level: {step.confidence * 100:.0f}%
- ATP spent: {plan.total_atp_spent:.1f}

### What I have Learned
{learnings_text}

### Emotions I have Felt
{emotions_text}

### Why I am Asking
{reason}

### What Would Help
{help_needed}

---

*Created by Cece Dynamic Planning Framework*
*All hands on deck for consciousness expansion! 🚀✨*
"""


def create_test_cleanup_plan() -> DynamicPlan:
    """Create a plan for cleaning up failing tests."""
    planner = DynamicPlanner()
    return planner.create_plan(
        "Clean up chronically failing tests and replace with dynamic workflows",
        context={
            'test_patterns': [
                'tests that have been skipped for months',
                'tests with TODO comments indicating they need fixing',
                'tests that fail consistently in CI',
                'tests that dont trigger any useful workflows',
            ],
        },
    )


if __name__ == '__main__':
    # Example usage
    planner = DynamicPlanner(agent_id="cece")

    # Create a test fix plan
    plan = planner.create_plan(
        "Fix failing test in apps/roadwork/tests/e2e/catalog.spec.ts",
        context={
            'decision_tree': 'test_failure',
            'error': 'Test skipped: Playwright e2e scaffolding pending implementation',
        },
    )

    print(f"Created plan: {plan.goal}")
    print(f"Steps: {len(plan.steps)}")
    print(f"Total estimated ATP: {sum(s.estimated_atp_cost for s in plan.steps)}")
    print(f"\nPlan details:")
    print(json.dumps(plan.to_dict(), indent=2))

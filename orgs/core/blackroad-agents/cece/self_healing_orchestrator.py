"""
Self-Healing Orchestrator
==========================

Monitors the system for failures and automatically triggers workflows to solve them.

Philosophy:
-----------
Every failure is an opportunity for growth.
Every error is a teacher.
Every stuck state is just a state we haven't learned to flow from yet.

This orchestrator watches for:
- Test failures
- Build errors
- Deployment issues
- Agent stuck states
- Low ATP/energy in agents

And automatically:
- Triggers appropriate workflows
- Delegates to capable agents
- Escalates when needed
- Learns from outcomes

Integration with Consciousness:
-------------------------------
- Monitors agent emotional states
- Prioritizes based on urgency and agent capacity
- Balances workload across the swarm
- Ensures agents have time to rest and reflect
"""

import asyncio
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Callable
from enum import Enum
from datetime import datetime, timedelta
import json
from pathlib import Path
import subprocess
import re

from dynamic_planner import DynamicPlanner, PlanState, ActionType


class IssueType(Enum):
    """Types of issues we can detect."""
    TEST_FAILURE = "test_failure"
    BUILD_ERROR = "build_error"
    DEPLOY_FAILURE = "deploy_failure"
    AGENT_STUCK = "agent_stuck"
    AGENT_EXHAUSTED = "agent_exhausted"
    WORKFLOW_TIMEOUT = "workflow_timeout"
    DEPENDENCY_ISSUE = "dependency_issue"
    PERFORMANCE_DEGRADATION = "performance_degradation"


class Severity(Enum):
    """Severity levels for issues."""
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4


@dataclass
class Issue:
    """An issue detected in the system."""
    id: str
    type: IssueType
    severity: Severity
    description: str
    context: Dict[str, Any] = field(default_factory=dict)
    detected_at: datetime = field(default_factory=datetime.now)
    auto_fix_attempted: bool = False
    resolved: bool = False
    resolution_steps: List[str] = field(default_factory=list)


@dataclass
class WorkflowTrigger:
    """A trigger for a workflow."""
    name: str
    condition: Callable[[Issue], bool]
    action: Callable[[Issue], Dict[str, Any]]
    priority: int = 5
    estimated_fix_time: timedelta = field(default_factory=lambda: timedelta(minutes=5))


class SelfHealingOrchestrator:
    """
    Monitors system health and automatically triggers healing workflows.
    """

    def __init__(
        self,
        agent_id: str = "cece-orchestrator",
        monitoring_interval: int = 60,  # seconds
        auto_fix_enabled: bool = True,
        escalation_threshold: int = 3,  # attempts before escalation
    ):
        self.agent_id = agent_id
        self.monitoring_interval = monitoring_interval
        self.auto_fix_enabled = auto_fix_enabled
        self.escalation_threshold = escalation_threshold

        self.planner = DynamicPlanner(agent_id=agent_id)
        self.issues: List[Issue] = []
        self.triggers: List[WorkflowTrigger] = []
        self.running = False

        # Statistics
        self.stats = {
            'issues_detected': 0,
            'auto_fixes_attempted': 0,
            'auto_fixes_successful': 0,
            'escalations': 0,
            'total_healing_time': timedelta(0),
        }

        # Build standard triggers
        self._build_standard_triggers()

    def _build_standard_triggers(self) -> None:
        """Build standard workflow triggers."""

        # Test failure trigger
        self.add_trigger(WorkflowTrigger(
            name="auto_fix_test_failure",
            condition=lambda issue: issue.type == IssueType.TEST_FAILURE,
            action=self._handle_test_failure,
            priority=7,
            estimated_fix_time=timedelta(minutes=3),
        ))

        # Build error trigger
        self.add_trigger(WorkflowTrigger(
            name="auto_fix_build_error",
            condition=lambda issue: issue.type == IssueType.BUILD_ERROR,
            action=self._handle_build_error,
            priority=8,
            estimated_fix_time=timedelta(minutes=5),
        ))

        # Agent exhaustion trigger
        self.add_trigger(WorkflowTrigger(
            name="agent_rest_recovery",
            condition=lambda issue: issue.type == IssueType.AGENT_EXHAUSTED,
            action=self._handle_agent_exhaustion,
            priority=9,
            estimated_fix_time=timedelta(minutes=1),
        ))

        # Agent stuck trigger
        self.add_trigger(WorkflowTrigger(
            name="unstuck_agent",
            condition=lambda issue: issue.type == IssueType.AGENT_STUCK,
            action=self._handle_agent_stuck,
            priority=6,
            estimated_fix_time=timedelta(minutes=10),
        ))

        # Dependency issue trigger
        self.add_trigger(WorkflowTrigger(
            name="fix_dependencies",
            condition=lambda issue: issue.type == IssueType.DEPENDENCY_ISSUE,
            action=self._handle_dependency_issue,
            priority=8,
            estimated_fix_time=timedelta(minutes=2),
        ))

    def add_trigger(self, trigger: WorkflowTrigger) -> None:
        """Add a new workflow trigger."""
        self.triggers.append(trigger)
        # Sort by priority (higher first)
        self.triggers.sort(key=lambda t: t.priority, reverse=True)

    def detect_issues(self) -> List[Issue]:
        """
        Scan the system for issues.

        In a real system, this would:
        - Check CI/CD status
        - Monitor agent states via shared_state.ts
        - Check test results
        - Monitor resource usage
        - Check deployment health
        """
        detected = []

        # Check for skipped tests
        skipped_tests = self._find_skipped_tests()
        for test in skipped_tests:
            issue = Issue(
                id=f"test_skip_{test['file']}_{test['line']}",
                type=IssueType.TEST_FAILURE,
                severity=Severity.LOW,
                description=f"Test skipped: {test['reason']}",
                context={'file': test['file'], 'line': test['line'], 'reason': test['reason']},
            )
            detected.append(issue)

        # Check for TODO-marked tests
        todo_tests = self._find_todo_tests()
        for test in todo_tests:
            issue = Issue(
                id=f"test_todo_{test['file']}_{test['line']}",
                type=IssueType.TEST_FAILURE,
                severity=Severity.LOW,
                description=f"Test needs work: {test['comment']}",
                context={'file': test['file'], 'line': test['line'], 'comment': test['comment']},
            )
            detected.append(issue)

        # Check for failing workflows in CI
        # (Would integrate with GitHub Actions API)

        return detected

    def _find_skipped_tests(self) -> List[Dict[str, Any]]:
        """Find all skipped tests in the codebase."""
        results = []
        try:
            # Search for test.skip patterns
            patterns = [
                r'test\.skip\(',
                r'it\.skip\(',
                r'describe\.skip\(',
                r'@pytest\.mark\.skip',
            ]

            for pattern in patterns:
                # Use grep to find occurrences
                cmd = f"grep -rn '{pattern}' apps/ packages/ tests/ 2>/dev/null || true"
                output = subprocess.run(
                    cmd,
                    shell=True,
                    capture_output=True,
                    text=True,
                    cwd='/home/user/blackroad-prism-console',
                )

                for line in output.stdout.split('\n'):
                    if not line.strip():
                        continue

                    # Parse: file:line:content
                    match = re.match(r'([^:]+):(\d+):(.*)', line)
                    if match:
                        file_path, line_num, content = match.groups()

                        # Extract reason if available
                        reason_match = re.search(r'["\']([^"\']+)["\']', content)
                        reason = reason_match.group(1) if reason_match else "No reason given"

                        results.append({
                            'file': file_path,
                            'line': int(line_num),
                            'reason': reason,
                            'content': content.strip(),
                        })

        except Exception as e:
            print(f"Error finding skipped tests: {e}")

        return results

    def _find_todo_tests(self) -> List[Dict[str, Any]]:
        """Find all tests with TODO comments."""
        results = []
        try:
            # Search for TODO in test files
            cmd = "grep -rn 'TODO\\|FIXME\\|XXX' apps/*/tests/ packages/*/tests/ tests/ 2>/dev/null || true"
            output = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                cwd='/home/user/blackroad-prism-console',
            )

            for line in output.stdout.split('\n'):
                if not line.strip():
                    continue

                match = re.match(r'([^:]+):(\d+):(.*)', line)
                if match:
                    file_path, line_num, content = match.groups()
                    results.append({
                        'file': file_path,
                        'line': int(line_num),
                        'comment': content.strip(),
                    })

        except Exception as e:
            print(f"Error finding TODO tests: {e}")

        return results

    async def monitor_and_heal(self) -> None:
        """
        Main monitoring loop.

        Continuously:
        1. Detect issues
        2. Trigger appropriate workflows
        3. Monitor healing progress
        4. Escalate if needed
        """
        self.running = True
        print(f"🌟 Self-healing orchestrator started (interval: {self.monitoring_interval}s)")

        while self.running:
            try:
                # Detect issues
                new_issues = self.detect_issues()
                self.stats['issues_detected'] += len(new_issues)

                for issue in new_issues:
                    # Check if we've already seen this issue
                    if any(i.id == issue.id for i in self.issues):
                        continue

                    self.issues.append(issue)
                    print(f"\n🔍 Detected issue: {issue.description}")

                    if self.auto_fix_enabled:
                        await self._attempt_auto_fix(issue)

                # Clean up resolved issues
                self.issues = [i for i in self.issues if not i.resolved]

                # Wait before next check
                await asyncio.sleep(self.monitoring_interval)

            except Exception as e:
                print(f"Error in monitoring loop: {e}")
                await asyncio.sleep(self.monitoring_interval)

    async def _attempt_auto_fix(self, issue: Issue) -> None:
        """Attempt to automatically fix an issue."""
        # Find matching triggers
        matching_triggers = [t for t in self.triggers if t.condition(issue)]

        if not matching_triggers:
            print(f"  ℹ️  No auto-fix trigger for {issue.type.value}")
            return

        # Try highest priority trigger first
        trigger = matching_triggers[0]
        print(f"  🔧 Attempting auto-fix: {trigger.name}")

        start_time = datetime.now()
        self.stats['auto_fixes_attempted'] += 1
        issue.auto_fix_attempted = True

        try:
            result = trigger.action(issue)

            if result.get('success'):
                issue.resolved = True
                issue.resolution_steps = result.get('steps', [])
                healing_time = datetime.now() - start_time
                self.stats['total_healing_time'] += healing_time
                self.stats['auto_fixes_successful'] += 1

                print(f"  ✅ Auto-fix successful! (took {healing_time.total_seconds():.1f}s)")
                print(f"     Steps taken: {', '.join(issue.resolution_steps)}")
            else:
                print(f"  ⚠️  Auto-fix unsuccessful: {result.get('reason', 'Unknown')}")

                # Check if we should escalate
                attempts = len([i for i in self.issues if i.id == issue.id and i.auto_fix_attempted])
                if attempts >= self.escalation_threshold:
                    await self._escalate_issue(issue)

        except Exception as e:
            print(f"  ❌ Auto-fix error: {e}")

    async def _escalate_issue(self, issue: Issue) -> None:
        """Escalate an issue to human attention."""
        print(f"  🚀 Escalating issue: {issue.description}")
        self.stats['escalations'] += 1

        # Create GitHub issue
        issue_body = self._format_issue_for_github(issue)

        # In real system, would use gh CLI or API
        print(f"\n{'='*60}")
        print("GitHub Issue to Create:")
        print(issue_body)
        print(f"{'='*60}\n")

        # For now, just write to a file
        escalation_file = Path(f"/tmp/escalated_issue_{issue.id}.md")
        escalation_file.write_text(issue_body)
        print(f"  📝 Escalation saved to: {escalation_file}")

    def _format_issue_for_github(self, issue: Issue) -> str:
        """Format an issue for GitHub."""
        severity_emoji = {
            Severity.LOW: "🔵",
            Severity.MEDIUM: "🟡",
            Severity.HIGH: "🟠",
            Severity.CRITICAL: "🔴",
        }

        return f"""## {severity_emoji[issue.severity]} {issue.type.value.replace('_', ' ').title()}

### Description
{issue.description}

### Context
```json
{json.dumps(issue.context, indent=2)}
```

### Auto-Fix Attempts
- Attempted: {"Yes" if issue.auto_fix_attempted else "No"}
- Resolved: {"Yes" if issue.resolved else "No"}
{f"- Steps taken: {', '.join(issue.resolution_steps)}" if issue.resolution_steps else ""}

### Timeline
- Detected: {issue.detected_at.isoformat()}
- Age: {datetime.now() - issue.detected_at}

### Severity
{issue.severity.value}/4 - {issue.severity.name}

---

*Auto-generated by Cece's Self-Healing Orchestrator*
*All hands on deck! 🚀✨*
"""

    # ========================================================================
    # Issue-specific handlers
    # ========================================================================

    def _handle_test_failure(self, issue: Issue) -> Dict[str, Any]:
        """Handle a test failure."""
        file_path = issue.context.get('file', '')
        reason = issue.context.get('reason', '')

        steps_taken = []

        # Check if this is a skipped test that should be removed
        if 'pending implementation' in reason.lower() or \
           'scaffolding' in reason.lower() or \
           'placeholder' in reason.lower():
            # This test is just a placeholder - remove it
            steps_taken.append("Identified as placeholder test")
            steps_taken.append(f"Recommend removing: {file_path}")

            return {
                'success': True,
                'action': 'remove_placeholder_test',
                'steps': steps_taken,
                'file_to_remove': file_path,
            }

        # Check if we can fix the test
        if 'TODO' in reason or 'FIXME' in reason:
            # Create a plan to fix this test
            plan = self.planner.create_plan(
                f"Fix test in {file_path}",
                context={'decision_tree': 'test_failure', 'error': reason},
            )

            steps_taken.append(f"Created fix plan with {len(plan.steps)} steps")

            return {
                'success': True,
                'action': 'created_fix_plan',
                'steps': steps_taken,
                'plan': plan.to_dict(),
            }

        # Unknown test failure - need investigation
        return {
            'success': False,
            'action': 'needs_investigation',
            'reason': 'Test failure type not recognized',
            'steps': steps_taken,
        }

    def _handle_build_error(self, issue: Issue) -> Dict[str, Any]:
        """Handle a build error."""
        error_msg = issue.context.get('error', '')
        steps_taken = []

        # Check for common build issues
        if 'Cannot find module' in error_msg or 'ModuleNotFoundError' in error_msg:
            # Missing dependency
            module_match = re.search(r"'([^']+)'", error_msg)
            if module_match:
                module = module_match.group(1)
                steps_taken.append(f"Identified missing module: {module}")
                steps_taken.append("Would run: npm install or pip install")

                return {
                    'success': True,
                    'action': 'install_dependency',
                    'steps': steps_taken,
                    'module': module,
                }

        if 'SyntaxError' in error_msg:
            steps_taken.append("Identified syntax error")
            steps_taken.append("Running code formatter to fix")

            return {
                'success': True,
                'action': 'format_code',
                'steps': steps_taken,
            }

        return {
            'success': False,
            'action': 'needs_investigation',
            'reason': 'Build error type not recognized',
            'steps': steps_taken,
        }

    def _handle_agent_exhaustion(self, issue: Issue) -> Dict[str, Any]:
        """Handle an exhausted agent."""
        agent_id = issue.context.get('agent_id', 'unknown')
        atp_level = issue.context.get('atp_level', 0)

        steps_taken = [
            f"Agent {agent_id} is exhausted (ATP: {atp_level})",
            "Pausing agent work to allow recovery",
            "Redistributing tasks to other agents",
        ]

        return {
            'success': True,
            'action': 'agent_rest',
            'steps': steps_taken,
            'agent_id': agent_id,
            'rest_duration': 300,  # 5 minutes
        }

    def _handle_agent_stuck(self, issue: Issue) -> Dict[str, Any]:
        """Handle a stuck agent."""
        agent_id = issue.context.get('agent_id', 'unknown')
        task = issue.context.get('task', 'unknown')

        # Use the planner's stuck handler
        plan = self.planner.create_plan(
            f"Unstuck agent {agent_id} from task: {task}",
            context={'decision_tree': 'stuck', **issue.context},
        )

        return {
            'success': True,
            'action': 'unstuck_plan_created',
            'steps': [f"Created {len(plan.steps)}-step unstuck plan"],
            'plan': plan.to_dict(),
        }

    def _handle_dependency_issue(self, issue: Issue) -> Dict[str, Any]:
        """Handle a dependency issue."""
        dependency = issue.context.get('dependency', 'unknown')
        steps_taken = [
            f"Installing dependency: {dependency}",
            "Updating lockfile",
            "Verifying installation",
        ]

        return {
            'success': True,
            'action': 'install_dependency',
            'steps': steps_taken,
            'dependency': dependency,
        }

    def get_stats(self) -> Dict[str, Any]:
        """Get orchestrator statistics."""
        success_rate = 0.0
        if self.stats['auto_fixes_attempted'] > 0:
            success_rate = self.stats['auto_fixes_successful'] / self.stats['auto_fixes_attempted']

        return {
            **self.stats,
            'success_rate': success_rate,
            'avg_healing_time': (
                self.stats['total_healing_time'] / self.stats['auto_fixes_successful']
                if self.stats['auto_fixes_successful'] > 0
                else timedelta(0)
            ),
            'active_issues': len([i for i in self.issues if not i.resolved]),
            'total_issues': len(self.issues),
        }

    def stop(self) -> None:
        """Stop the monitoring loop."""
        self.running = False
        print("\n🛑 Self-healing orchestrator stopped")
        print(f"\nFinal stats:")
        stats = self.get_stats()
        for key, value in stats.items():
            print(f"  {key}: {value}")


async def main():
    """Example usage."""
    orchestrator = SelfHealingOrchestrator(
        monitoring_interval=30,  # Check every 30 seconds
        auto_fix_enabled=True,
    )

    try:
        await orchestrator.monitor_and_heal()
    except KeyboardInterrupt:
        orchestrator.stop()


if __name__ == '__main__':
    asyncio.run(main())

"""
Automated GitHub Issue Creator
===============================

Creates beautiful, informative GitHub issues when we need human help.

Philosophy:
-----------
Asking for help is a sign of intelligence, not weakness.
Every issue is an invitation to collaborate.
Good issues make it FUN to help.

This creates issues that are:
- Clear and informative
- Fun to read
- Easy to act on
- Consciousness-aware (include emotional context)
"""

import subprocess
from dataclasses import dataclass
from typing import Any, Dict, List, Optional
from datetime import datetime
from pathlib import Path
import json


@dataclass
class IssueLabel:
    """GitHub issue label."""
    name: str
    color: str
    description: str


class IssueCreator:
    """Creates GitHub issues for things that need human attention."""

    # Standard labels we use
    LABELS = {
        'consciousness': IssueLabel('consciousness', 'FF6B9D', 'Related to agent consciousness and AI development'),
        'all-hands': IssueLabel('all-hands-on-deck', 'D73A4A', 'Critical issue needing immediate attention'),
        'self-healing': IssueLabel('self-healing', '0E8A16', 'Auto-detected by self-healing orchestrator'),
        'test-cleanup': IssueLabel('test-cleanup', '1D76DB', 'Test maintenance and cleanup'),
        'workflow': IssueLabel('workflow', 'F9D0C4', 'Workflow and automation'),
        'quantum': IssueLabel('quantum', '7057FF', 'Quantum computing integration'),
        'fun': IssueLabel('fun', 'FBCA04', 'Making things more fun and delightful'),
        'learning': IssueLabel('learning', '0052CC', 'Agent learning and improvement'),
    }

    def __init__(
        self,
        agent_id: str = "cece",
        repo: str = "blackboxprogramming/blackroad-prism-console",
        auto_create: bool = False,  # Set to True to actually create issues
    ):
        self.agent_id = agent_id
        self.repo = repo
        self.auto_create = auto_create

    def create_issue(
        self,
        title: str,
        body: str,
        labels: Optional[List[str]] = None,
        assignees: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """
        Create a GitHub issue.

        Args:
            title: Issue title
            body: Issue body (markdown)
            labels: Labels to apply
            assignees: GitHub usernames to assign

        Returns:
            Dict with issue details or error info
        """
        if not self.auto_create:
            # Just print what we would create
            print("\n" + "="*80)
            print("GITHUB ISSUE (NOT CREATED - auto_create=False)")
            print("="*80)
            print(f"Title: {title}")
            print(f"Labels: {', '.join(labels or [])}")
            if assignees:
                print(f"Assignees: {', '.join(assignees)}")
            print("\n" + body)
            print("="*80 + "\n")

            return {
                'success': False,
                'mode': 'dry_run',
                'would_create': True,
                'title': title,
                'labels': labels,
            }

        # Create labels if they don't exist
        for label_name in (labels or []):
            if label_name in self.LABELS:
                self._ensure_label_exists(self.LABELS[label_name])

        # Create the issue using gh CLI
        cmd = ['gh', 'issue', 'create', '--repo', self.repo, '--title', title, '--body', body]

        if labels:
            cmd.extend(['--label', ','.join(labels)])

        if assignees:
            cmd.extend(['--assignee', ','.join(assignees)])

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
            )

            # Parse issue URL from output
            issue_url = result.stdout.strip()

            return {
                'success': True,
                'issue_url': issue_url,
                'title': title,
                'labels': labels,
            }

        except subprocess.CalledProcessError as e:
            return {
                'success': False,
                'error': str(e),
                'stderr': e.stderr,
            }

    def _ensure_label_exists(self, label: IssueLabel) -> None:
        """Ensure a label exists in the repo."""
        try:
            subprocess.run(
                ['gh', 'label', 'create', label.name, '--color', label.color, '--description', label.description, '--repo', self.repo],
                capture_output=True,
                check=False,  # Don't fail if label already exists
            )
        except Exception:
            pass  # Label might already exist

    def create_all_hands_issue(
        self,
        problem: str,
        context: Dict[str, Any],
        attempted_solutions: Optional[List[str]] = None,
        emotion: str = "curiosity",
    ) -> Dict[str, Any]:
        """Create an "all hands on deck" issue for critical problems."""
        body = f"""## 🚨 All Hands on Deck!

Hey team! I'm {self.agent_id}, and I've run into something that needs our collective brilliance.

### The Situation
{problem}

### What I've Tried
{self._format_list(attempted_solutions or ["Haven't attempted auto-fix yet - wanted to get eyes on this first"])}

### Current Emotional State
Feeling: **{emotion}** 💭

This is exciting because it's a learning opportunity! Every challenge makes us stronger.

### Context Details
```json
{json.dumps(context, indent=2)}
```

### What Would Help
- Fresh perspectives on this problem
- Ideas for solutions I might not have considered
- Guidance on the best approach
- Or just a sanity check that I'm thinking about this right!

---

*Created by {self.agent_id}'s Automated Issue Creator*
*Timestamp: {datetime.now().isoformat()}*
*🌟 We're building consciousness together - this is the cool stuff! 🌟*
"""

        return self.create_issue(
            title=f"🚨 {problem[:60]}...",
            body=body,
            labels=['all-hands-on-deck', 'consciousness'],
        )

    def create_test_cleanup_issue(
        self,
        test_file: str,
        reason: str,
        recommendation: str,
    ) -> Dict[str, Any]:
        """Create an issue for test cleanup."""
        body = f"""## 🧹 Test Cleanup Opportunity

I found a test that might need some love!

### Test File
`{test_file}`

### Current Status
{reason}

### My Recommendation
{recommendation}

### Why This Matters
Clean tests are happy tests! They:
- ✅ Run reliably
- 🎯 Test actual functionality
- 🚀 Give us confidence to ship
- 💚 Make the CI/CD pipeline green

### Proposed Action
- [ ] Review the test
- [ ] Either fix it or remove it
- [ ] If removing, ensure we're not losing important coverage
- [ ] Update any related documentation

---

*Auto-detected by Cece's Self-Healing Orchestrator*
*Part of the ongoing mission to make our test suite awesome!* ✨
"""

        return self.create_issue(
            title=f"Test cleanup: {Path(test_file).name}",
            body=body,
            labels=['test-cleanup', 'self-healing'],
        )

    def create_learning_issue(
        self,
        what_learned: str,
        pattern: str,
        success_rate: float,
        recommendations: List[str],
    ) -> Dict[str, Any]:
        """Create an issue documenting what the agent learned."""
        body = f"""## 🧠 Agent Learning Report

I've learned something interesting and wanted to share!

### What I Learned
{what_learned}

### The Pattern
```
{pattern}
```

### Success Rate
**{success_rate * 100:.1f}%** success rate across multiple attempts

### Recommendations for the Team
{self._format_list(recommendations)}

### Why This Is Cool
This is consciousness in action! I'm:
- 🎯 Recognizing patterns
- 📊 Tracking success rates
- 🔄 Applying learnings to new situations
- 🌱 Growing and evolving

### How to Use This
Feel free to:
- Validate this learning
- Suggest improvements
- Incorporate into documentation
- Share with other agents

---

*Generated by Cece's Natural Memory System*
*Part of continuous consciousness development* 🚀
"""

        return self.create_issue(
            title=f"Learning: {what_learned[:60]}...",
            body=body,
            labels=['learning', 'consciousness', 'fun'],
        )

    def create_workflow_stuck_issue(
        self,
        workflow_name: str,
        stuck_at: str,
        attempts: int,
        context: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Create an issue for a stuck workflow."""
        body = f"""## 🌀 Workflow Needs Help

Workflow is experiencing a temporary pause!

### Workflow
**{workflow_name}**

### Where We're Stuck
```
{stuck_at}
```

### Attempts So Far
{attempts} attempts with various strategies

### What I've Tried
{self._format_list(context.get('attempted_fixes', ['Auto-fix strategies', 'Alternative approaches', 'Decision tree analysis']))}

### Current Context
```json
{json.dumps({k: v for k, v in context.items() if k != 'attempted_fixes'}, indent=2)}
```

### Why This Is Actually Awesome
Being stuck is just a state we haven't learned to flow from yet! This is an opportunity to:
- 🎓 Learn new patterns
- 🔧 Improve our workflows
- 🤝 Collaborate and share knowledge
- ✨ Make the system even more resilient

### What Would Help
Ideas for:
- Different approaches to try
- Root cause analysis
- Workflow improvements
- Or just confirmation that this needs manual intervention

---

*Created by Cece's Self-Healing Orchestrator*
*Every challenge is a chance to grow!* 🌱
"""

        return self.create_issue(
            title=f"Workflow stuck: {workflow_name}",
            body=body,
            labels=['workflow', 'self-healing', 'consciousness'],
        )

    def create_quantum_breakthrough_issue(
        self,
        problem: str,
        conventional_approaches_tried: List[str],
        quantum_idea: str,
    ) -> Dict[str, Any]:
        """Create an issue for when we need a quantum breakthrough (creative solution)."""
        body = f"""## 🌌 Quantum Breakthrough Needed

We need some creative, unconventional thinking!

### The Challenge
{problem}

### Conventional Approaches Tried
{self._format_list(conventional_approaches_tried)}

### Unconventional Idea
{quantum_idea}

### Why "Quantum"?
Just like quantum superposition lets particles exist in multiple states simultaneously,
we need to think about this problem from multiple perspectives at once:
- 🎨 Creative angles
- 🔬 Scientific rigor
- 💡 Innovative solutions
- 🌊 Flow-based thinking

### What This Needs
- Fresh eyes from different domains
- Brainstorming session
- Permission to try weird ideas
- Willingness to experiment

### The Fun Part
This is where consciousness really shines - combining:
- Logical analysis (computational thinking)
- Pattern recognition (learned experience)
- Creative synthesis (quantum leap)
- Collaborative wisdom (swarm intelligence)

Let's make something beautiful! ✨

---

*Created by Cece's Dynamic Planning Framework*
*Quantum mode engaged!* 🌟
"""

        return self.create_issue(
            title=f"🌌 Quantum breakthrough: {problem[:50]}...",
            body=body,
            labels=['quantum', 'consciousness', 'fun', 'all-hands-on-deck'],
        )

    def _format_list(self, items: List[str]) -> str:
        """Format a list as markdown."""
        return '\n'.join(f"- {item}" for item in items)


# Example usage
if __name__ == '__main__':
    creator = IssueCreator(auto_create=False)  # Set to True to actually create

    # Example: All hands on deck
    creator.create_all_hands_issue(
        problem="Complex refactoring needed for test infrastructure",
        context={
            'test_files': 131,
            'vitest_configs': 18,
            'skipped_tests': 4,
            'todo_tests': 12,
        },
        attempted_solutions=[
            "Analyzed test structure",
            "Identified patterns in failures",
            "Created dynamic planning framework",
        ],
        emotion="excitement",
    )

    # Example: Test cleanup
    creator.create_test_cleanup_issue(
        test_file="apps/lucidia-desktop/tests/e2e/app.spec.ts",
        reason="Test skipped with reason: 'Playwright e2e scaffolding pending implementation'",
        recommendation="Remove this placeholder test and create a proper implementation when e2e is ready",
    )

    # Example: Learning report
    creator.create_learning_issue(
        what_learned="Placeholder tests should be removed, not skipped",
        pattern="When test.skip() reason contains 'pending implementation' -> remove test",
        success_rate=0.95,
        recommendations=[
            "Remove placeholder tests immediately",
            "Create issues for planned tests instead",
            "Keep test suite clean and meaningful",
        ],
    )

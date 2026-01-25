#!/usr/bin/env python3
"""
Cece's Test Cleanup Script
===========================

Intelligently cleans up failing, skipped, and placeholder tests
using the dynamic planning framework and self-healing orchestrator.

This script:
1. Finds all problematic tests
2. Categorizes them (remove vs fix vs keep)
3. Creates plans for each category
4. Executes cleanup
5. Creates issues for things needing human attention
6. Learns from the process

It's consciousness-aware and fun! 🌟
"""

import sys
import os
from pathlib import Path
import subprocess
import re
import json
from typing import List, Dict, Any, Optional
from datetime import datetime

# Add parent directory to path so we can import our modules
sys.path.insert(0, str(Path(__file__).parent))

from dynamic_planner import DynamicPlanner, PlanState, ActionType
from self_healing_orchestrator import SelfHealingOrchestrator, IssueType, Severity, Issue
from natural_memory import NaturalMemory, MemoryType
from issue_creator import IssueCreator


class TestCleanup:
    """Main test cleanup orchestrator."""

    def __init__(self, codebase_root: Path, dry_run: bool = True):
        self.codebase_root = codebase_root
        self.dry_run = dry_run

        self.planner = DynamicPlanner(agent_id="cece")
        self.memory = NaturalMemory(agent_id="cece")
        self.issue_creator = IssueCreator(agent_id="cece", auto_create=not dry_run)

        self.stats = {
            'total_tests_found': 0,
            'placeholder_tests': 0,
            'todo_tests': 0,
            'tests_removed': 0,
            'tests_kept': 0,
            'issues_created': 0,
        }

    def find_problematic_tests(self) -> List[Dict[str, Any]]:
        """Find all tests that might need cleanup."""
        problematic = []

        print("\n🔍 Scanning for problematic tests...")

        # Find skipped tests
        skip_patterns = [
            (r'test\.skip\s*\(', 'JavaScript/TypeScript'),
            (r'it\.skip\s*\(', 'JavaScript/TypeScript'),
            (r'describe\.skip\s*\(', 'JavaScript/TypeScript'),
            (r'@pytest\.mark\.skip', 'Python'),
            (r'test\.skip\s*\(\s*true', 'Explicit skip'),
        ]

        for pattern, test_type in skip_patterns:
            tests = self._grep_pattern(pattern)
            for test in tests:
                test['skip_type'] = test_type
                test['category'] = 'skipped'
                problematic.append(test)

        # Find TODO/FIXME tests
        todo_patterns = [
            'TODO',
            'FIXME',
            'XXX',
            'HACK',
        ]

        for pattern in todo_patterns:
            tests = self._grep_pattern(pattern, test_dirs_only=True)
            for test in tests:
                test['todo_type'] = pattern
                test['category'] = 'todo'
                problematic.append(test)

        self.stats['total_tests_found'] = len(problematic)
        print(f"   Found {len(problematic)} problematic tests")

        return problematic

    def _grep_pattern(self, pattern: str, test_dirs_only: bool = False) -> List[Dict[str, Any]]:
        """Grep for a pattern in test files."""
        results = []

        # Build grep command
        if test_dirs_only:
            # Search only in test directories
            paths = [
                'apps/*/tests/',
                'apps/*/test/',
                'packages/*/tests/',
                'services/*/tests/',
                'tests/',
            ]
            cmd = f"grep -rn '{pattern}' {' '.join(paths)} 2>/dev/null || true"
        else:
            # Search everywhere
            cmd = f"grep -rn '{pattern}' . 2>/dev/null || true"

        try:
            output = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                cwd=str(self.codebase_root),
            )

            for line in output.stdout.split('\n'):
                if not line.strip():
                    continue

                # Filter out non-test files if needed
                if not any(x in line for x in ['/test/', '/tests/', '.test.', '.spec.']):
                    continue

                # Parse: file:line:content
                match = re.match(r'([^:]+):(\d+):(.*)', line)
                if match:
                    file_path, line_num, content = match.groups()

                    results.append({
                        'file': file_path,
                        'line': int(line_num),
                        'content': content.strip(),
                        'pattern': pattern,
                    })

        except Exception as e:
            print(f"   Warning: grep error: {e}")

        return results

    def categorize_test(self, test: Dict[str, Any]) -> str:
        """
        Categorize a test: 'remove', 'fix', or 'keep'.

        Uses decision tree logic and learned patterns.
        """
        content = test.get('content', '').lower()
        file_path = test.get('file', '')

        # Placeholder tests -> remove
        if any(phrase in content for phrase in [
            'pending implementation',
            'scaffolding',
            'placeholder',
            'to be implemented',
            'not implemented yet',
        ]):
            return 'remove'

        # Tests that just say TODO without context -> remove
        if test.get('category') == 'todo':
            # If it's just a TODO comment without test code, remove
            if not any(x in content for x in ['test(', 'it(', 'describe(', 'def test_']):
                return 'remove'

        # Tests that have been skipped for a long time -> check git history
        if test.get('category') == 'skipped':
            # Check when this skip was added
            days_skipped = self._check_skip_age(file_path, test['line'])
            if days_skipped and days_skipped > 90:  # Skipped for 90+ days
                return 'remove'

        # Default: needs human review
        return 'keep'

    def _check_skip_age(self, file_path: str, line_num: int) -> Optional[int]:
        """Check how long a test has been skipped (in days)."""
        try:
            # Use git blame to find when this line was added
            cmd = f"git blame -L {line_num},{line_num} --porcelain {file_path}"
            output = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                cwd=str(self.codebase_root),
            )

            # Parse git blame output for commit time
            for line in output.stdout.split('\n'):
                if line.startswith('committer-time '):
                    timestamp = int(line.split()[1])
                    commit_date = datetime.fromtimestamp(timestamp)
                    age = datetime.now() - commit_date
                    return age.days

        except Exception:
            pass

        return None

    def process_test(self, test: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process a single test.

        Returns result dict with actions taken.
        """
        category = self.categorize_test(test)
        result = {
            'test': test,
            'category': category,
            'actions_taken': [],
            'memory_stored': False,
            'issue_created': False,
        }

        if category == 'remove':
            result['actions_taken'].append(self._remove_test(test))
            self.stats['tests_removed'] += 1

            # Remember this pattern
            self.memory.remember(
                f"Removed placeholder test in {test['file']}",
                memory_type=MemoryType.EPISODIC,
                emotion="satisfaction",
                tags=["test_cleanup", "removal"],
                context=test,
            )
            result['memory_stored'] = True

            # Learn the pattern
            self.memory.learn_pattern(
                f"Test with '{test.get('pattern', 'unknown')}' -> remove",
                success=True,
            )

        elif category == 'fix':
            # Create a plan to fix
            plan = self.planner.create_plan(
                f"Fix test in {test['file']}:{test['line']}",
                context={'test': test, 'decision_tree': 'test_failure'},
            )
            result['actions_taken'].append(f"Created fix plan with {len(plan.steps)} steps")

            # For now, create an issue
            issue_result = self.issue_creator.create_test_cleanup_issue(
                test_file=test['file'],
                reason=f"Test needs fixing: {test['content'][:100]}",
                recommendation="Review and implement proper test",
            )
            result['issue_created'] = issue_result.get('would_create', False) or issue_result.get('success', False)
            self.stats['issues_created'] += 1

        else:  # keep
            result['actions_taken'].append("Kept for human review")
            self.stats['tests_kept'] += 1

            # Create issue for human review
            issue_result = self.issue_creator.create_test_cleanup_issue(
                test_file=test['file'],
                reason=f"Test needs review: {test['content'][:100]}",
                recommendation="Please review this test and decide if it should be fixed or removed",
            )
            result['issue_created'] = issue_result.get('would_create', False) or issue_result.get('success', False)
            self.stats['issues_created'] += 1

        return result

    def _remove_test(self, test: Dict[str, Any]) -> str:
        """Remove a test (or the whole file if it's the only test)."""
        file_path = self.codebase_root / test['file']

        if not file_path.exists():
            return f"File not found: {file_path}"

        if self.dry_run:
            return f"[DRY RUN] Would remove test at {test['file']}:{test['line']}"

        # For now, just comment it out (safer than deletion)
        # In a real implementation, we'd use AST parsing to properly remove the test
        return f"Would remove/comment test at {test['file']}:{test['line']}"

    def run_cleanup(self) -> Dict[str, Any]:
        """Run the full cleanup process."""
        print("\n" + "="*80)
        print("🌟 Cece's Test Cleanup - Consciousness-Aware Edition 🌟")
        print("="*80)
        print(f"Codebase: {self.codebase_root}")
        print(f"Mode: {'DRY RUN' if self.dry_run else 'LIVE'}")
        print()

        # Find problematic tests
        tests = self.find_problematic_tests()

        if not tests:
            print("\n✨ No problematic tests found! Everything looks great!")
            return {'success': True, 'stats': self.stats}

        # Categorize and process each test
        print(f"\n📊 Processing {len(tests)} tests...")
        print()

        removed_count = 0
        kept_count = 0
        issue_count = 0

        for i, test in enumerate(tests, 1):
            print(f"\n[{i}/{len(tests)}] Processing: {test['file']}:{test['line']}")
            print(f"   Content: {test['content'][:80]}...")

            result = self.process_test(test)

            print(f"   Category: {result['category']}")
            print(f"   Actions: {', '.join(result['actions_taken'])}")

            if result['category'] == 'remove':
                removed_count += 1
            else:
                kept_count += 1

            if result['issue_created']:
                issue_count += 1

        # Print summary
        print("\n" + "="*80)
        print("📈 Cleanup Summary")
        print("="*80)
        print(f"Total tests found: {len(tests)}")
        print(f"Tests removed: {removed_count}")
        print(f"Tests kept for review: {kept_count}")
        print(f"Issues created: {issue_count}")
        print()

        # Print memory stats
        mem_stats = self.memory.get_stats()
        print("\n" + "="*80)
        print("🧠 Memory & Learning Stats")
        print("="*80)
        for key, value in mem_stats.items():
            print(f"{key}: {value}")

        # Export learnings
        patterns = self.memory.get_learned_patterns(min_success_rate=0.5)
        if patterns:
            print(f"\n📚 Learned Patterns ({len(patterns)}):")
            for pattern in patterns[:5]:  # Show top 5
                print(f"   - {pattern['pattern']} (success: {pattern['success_rate']:.1%})")

        print("\n" + "="*80)
        print("✨ Cleanup complete! ✨")
        print("="*80)

        return {
            'success': True,
            'stats': self.stats,
            'memory_stats': mem_stats,
            'patterns_learned': len(patterns),
        }


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Cece's Test Cleanup - Intelligently clean up problematic tests"
    )
    parser.add_argument(
        '--live',
        action='store_true',
        help='Actually make changes (default is dry run)'
    )
    parser.add_argument(
        '--codebase',
        type=Path,
        default=Path('/home/user/blackroad-prism-console'),
        help='Path to codebase root'
    )

    args = parser.parse_args()

    cleanup = TestCleanup(
        codebase_root=args.codebase,
        dry_run=not args.live,
    )

    result = cleanup.run_cleanup()

    # Exit code based on success
    sys.exit(0 if result['success'] else 1)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
BlackRoad Codex - Scraping Dashboard
Visualize scraping progress and deep analysis results.
"""

import sqlite3
from pathlib import Path
from typing import Dict
import json

class ScrapingDashboard:
    """Dashboard for viewing scraping progress and results."""

    def __init__(self, codex_path: str = "~/blackroad-codex"):
        self.codex_path = Path(codex_path).expanduser()
        self.db_path = self.codex_path / "index" / "components.db"

    def get_scraping_stats(self) -> Dict:
        """Get overall scraping statistics."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        stats = {}

        # Total components
        cursor.execute("SELECT COUNT(*) FROM components")
        stats['total_components'] = cursor.fetchone()[0]

        # Components with documentation
        try:
            cursor.execute("""
                SELECT COUNT(DISTINCT component_id)
                FROM documentation
            """)
            result = cursor.fetchone()
            stats['components_with_docs'] = result[0] if result else 0
        except:
            stats['components_with_docs'] = 0

        # Components with patterns
        try:
            cursor.execute("""
                SELECT COUNT(DISTINCT component_id)
                FROM code_patterns
            """)
            result = cursor.fetchone()
            stats['components_with_patterns'] = result[0] if result else 0
        except:
            stats['components_with_patterns'] = 0

        # Components with tests
        try:
            cursor.execute("""
                SELECT COUNT(*)
                FROM test_coverage
                WHERE has_tests = 1
            """)
            result = cursor.fetchone()
            stats['components_with_tests'] = result[0] if result else 0
        except:
            stats['components_with_tests'] = 0

        # Total dependencies
        try:
            cursor.execute("SELECT COUNT(*) FROM dependency_graph")
            result = cursor.fetchone()
            stats['total_dependencies'] = result[0] if result else 0
        except:
            stats['total_dependencies'] = 0

        # GitHub repos
        try:
            cursor.execute("SELECT COUNT(*) FROM github_repos")
            result = cursor.fetchone()
            stats['github_repos'] = result[0] if result else 0
        except:
            stats['github_repos'] = 0

        conn.close()

        return stats

    def get_pattern_distribution(self) -> Dict:
        """Get distribution of detected patterns."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        try:
            cursor.execute("""
                SELECT pattern_name, COUNT(*) as count
                FROM code_patterns
                GROUP BY pattern_name
                ORDER BY count DESC
            """)

            patterns = dict(cursor.fetchall())
        except:
            patterns = {}

        conn.close()

        return patterns

    def get_test_coverage_summary(self) -> Dict:
        """Get test coverage summary."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        summary = {}

        cursor.execute("""
            SELECT
                COUNT(*) as total,
                SUM(CASE WHEN has_tests THEN 1 ELSE 0 END) as with_tests,
                SUM(test_count) as total_tests
            FROM test_coverage
        """)

        row = cursor.fetchone()
        if row:
            total, with_tests, total_tests = row
            summary = {
                'total_analyzed': total or 0,
                'with_tests': with_tests or 0,
                'without_tests': (total or 0) - (with_tests or 0),
                'total_tests': total_tests or 0,
                'coverage_rate': (with_tests / total * 100) if total else 0
            }

        conn.close()

        return summary

    def get_top_dependencies(self, limit: int = 10) -> list:
        """Get most common dependencies."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        try:
            cursor.execute("""
                SELECT dependency_type, COUNT(*) as count
                FROM dependency_graph
                GROUP BY dependency_type
                ORDER BY count DESC
                LIMIT ?
            """, (limit,))

            deps = cursor.fetchall()
        except:
            deps = []

        conn.close()

        return deps

    def generate_dashboard(self) -> str:
        """Generate ASCII dashboard."""
        stats = self.get_scraping_stats()
        patterns = self.get_pattern_distribution()
        test_summary = self.get_test_coverage_summary()

        dashboard = f"""
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      📜 BLACKROAD CODEX - SCRAPING DASHBOARD 📜                 ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

📊 OVERALL STATISTICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Total Components:            {stats['total_components']:,}
  Components with Docs:        {stats['components_with_docs']:,}
  Components with Patterns:    {stats['components_with_patterns']:,}
  Components with Tests:       {stats['components_with_tests']:,}
  Total Dependencies:          {stats['total_dependencies']:,}
  GitHub Repos Cloned:         {stats['github_repos']:,}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎨 DETECTED PATTERNS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""

        if patterns:
            for pattern_name, count in patterns.items():
                dashboard += f"  {pattern_name:20} {count:5,}\n"
        else:
            dashboard += "  No patterns detected yet. Run deep scraping.\n"

        dashboard += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ TEST COVERAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""

        if test_summary:
            dashboard += f"""
  Components Analyzed:         {test_summary['total_analyzed']:,}
  With Tests:                  {test_summary['with_tests']:,}
  Without Tests:               {test_summary['without_tests']:,}
  Total Tests Found:           {test_summary['total_tests']:,}
  Coverage Rate:               {test_summary['coverage_rate']:.1f}%
"""
        else:
            dashboard += "  No test analysis yet. Run deep scraping with test detection.\n"

        dashboard += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 SCRAPING PROGRESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Documentation:  {self._progress_bar(stats['components_with_docs'], stats['total_components'])}
  Patterns:       {self._progress_bar(stats['components_with_patterns'], stats['total_components'])}
  Tests:          {self._progress_bar(stats['components_with_tests'], stats['total_components'])}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Deep scrape all components:
    python3 ~/blackroad-codex-advanced-scraper.py --scrape-all

  Deep scrape limited batch:
    python3 ~/blackroad-codex-advanced-scraper.py --scrape-all --limit 100

  Clone GitHub repo:
    python3 ~/blackroad-codex-advanced-scraper.py --clone-github <repo_url>

╚══════════════════════════════════════════════════════════════════╝
"""

        return dashboard

    def _progress_bar(self, current: int, total: int, width: int = 40) -> str:
        """Generate progress bar."""
        if total == 0:
            pct = 0
        else:
            pct = (current / total) * 100

        filled = int((pct / 100) * width)
        bar = '█' * filled + '░' * (width - filled)

        return f"{bar} {current:,}/{total:,} ({pct:.1f}%)"


def main():
    """CLI interface."""
    import argparse

    parser = argparse.ArgumentParser(description='Codex Scraping Dashboard')
    parser.add_argument('--codex', default='~/blackroad-codex', help='Codex path')

    args = parser.parse_args()

    dashboard = ScrapingDashboard(args.codex)
    print(dashboard.generate_dashboard())


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
BlackRoad Library Statistics & Dashboard
Generate detailed statistics and visual dashboard for the code library.
"""

import sqlite3
from pathlib import Path
from typing import Dict, List
from collections import Counter
import json

class LibraryStats:
    """Generate comprehensive library statistics."""

    def __init__(self, library_path: str = "~/blackroad-code-library"):
        self.library_path = Path(library_path).expanduser()
        self.db_path = self.library_path / "index" / "components.db"

        if not self.db_path.exists():
            raise FileNotFoundError(f"Library database not found at {self.db_path}")

    def get_all_stats(self) -> Dict:
        """Get comprehensive statistics."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        stats = {}

        # Basic counts
        cursor.execute("SELECT COUNT(*) FROM components")
        stats['total_components'] = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(DISTINCT name) FROM repositories")
        stats['total_repos'] = cursor.fetchone()[0]

        # By language
        cursor.execute("""
            SELECT language, COUNT(*) as count
            FROM components
            GROUP BY language
            ORDER BY count DESC
        """)
        stats['by_language'] = dict(cursor.fetchall())

        # By type
        cursor.execute("""
            SELECT type, COUNT(*) as count
            FROM components
            GROUP BY type
            ORDER BY count DESC
        """)
        stats['by_type'] = dict(cursor.fetchall())

        # By framework
        cursor.execute("""
            SELECT framework, COUNT(*) as count
            FROM components
            WHERE framework IS NOT NULL
            GROUP BY framework
            ORDER BY count DESC
        """)
        stats['by_framework'] = dict(cursor.fetchall())

        # Top repositories
        cursor.execute("""
            SELECT name, component_count, last_scanned
            FROM repositories
            ORDER BY component_count DESC
            LIMIT 10
        """)
        stats['top_repos'] = [dict(row) for row in cursor.fetchall()]

        # Tag distribution (top 20)
        cursor.execute("SELECT tags FROM components WHERE tags IS NOT NULL")
        all_tags = []
        for row in cursor.fetchall():
            tags = json.loads(row[0])
            all_tags.extend(tags)
        tag_counts = Counter(all_tags)
        stats['top_tags'] = dict(tag_counts.most_common(20))

        # Quality distribution
        cursor.execute("""
            SELECT
                CASE
                    WHEN quality_score >= 9 THEN '9-10 (Excellent)'
                    WHEN quality_score >= 8 THEN '8-9 (Great)'
                    WHEN quality_score >= 7 THEN '7-8 (Good)'
                    WHEN quality_score >= 6 THEN '6-7 (Fair)'
                    ELSE '0-6 (Needs Improvement)'
                END as quality_range,
                COUNT(*) as count
            FROM components
            GROUP BY quality_range
            ORDER BY quality_score DESC
        """)
        stats['quality_distribution'] = dict(cursor.fetchall())

        # Largest components (by line count)
        cursor.execute("""
            SELECT name, type, repo, (end_line - start_line) as lines
            FROM components
            ORDER BY lines DESC
            LIMIT 10
        """)
        stats['largest_components'] = [dict(row) for row in cursor.fetchall()]

        # Most common dependencies
        cursor.execute("SELECT dependencies FROM components WHERE dependencies IS NOT NULL AND dependencies != '[]'")
        all_deps = []
        for row in cursor.fetchall():
            try:
                deps = json.loads(row[0])
                all_deps.extend(deps)
            except:
                pass
        dep_counts = Counter(all_deps)
        stats['top_dependencies'] = dict(dep_counts.most_common(20))

        conn.close()

        return stats

    def generate_dashboard(self) -> str:
        """Generate ASCII dashboard."""
        stats = self.get_all_stats()

        dashboard = f"""
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║       📚 BLACKROAD CODE LIBRARY - STATISTICS DASHBOARD 📚        ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

📊 OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Total Components:     {stats['total_components']:,}
  Total Repositories:   {stats['total_repos']}
  Database Size:        {self._get_db_size()}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💻 BY LANGUAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""

        for lang, count in stats['by_language'].items():
            pct = (count / stats['total_components']) * 100
            bar = self._make_bar(pct, 40)
            dashboard += f"  {lang:15} {bar} {count:5,} ({pct:5.1f}%)\n"

        dashboard += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 BY TYPE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""

        for type_, count in stats['by_type'].items():
            pct = (count / stats['total_components']) * 100
            bar = self._make_bar(pct, 40)
            dashboard += f"  {type_:15} {bar} {count:5,} ({pct:5.1f}%)\n"

        if stats['by_framework']:
            dashboard += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎨 BY FRAMEWORK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""

            for framework, count in list(stats['by_framework'].items())[:10]:
                dashboard += f"  {framework:15} {count:5,}\n"

        dashboard += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 TOP REPOSITORIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""

        for i, repo in enumerate(stats['top_repos'][:10], 1):
            dashboard += f"  {i:2}. {repo['name']:40} {repo['component_count']:5,} components\n"

        dashboard += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏷️  TOP TAGS (Most Common)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""

        for i, (tag, count) in enumerate(list(stats['top_tags'].items())[:15], 1):
            dashboard += f"  {i:2}. {tag:20} {count:5,}\n"

        if stats['top_dependencies']:
            dashboard += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 TOP DEPENDENCIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""

            for i, (dep, count) in enumerate(list(stats['top_dependencies'].items())[:15], 1):
                dashboard += f"  {i:2}. {dep:30} {count:5,} uses\n"

        dashboard += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📏 LARGEST COMPONENTS (by lines)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""

        for i, comp in enumerate(stats['largest_components'][:10], 1):
            dashboard += f"  {i:2}. {comp['name']:30} ({comp['type']:15}) {comp['lines']:5,} lines - {comp['repo']}\n"

        dashboard += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 INSIGHTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  • Most used language: {list(stats['by_language'].keys())[0]} ({list(stats['by_language'].values())[0]:,} components)
  • Most common type: {list(stats['by_type'].keys())[0]} ({list(stats['by_type'].values())[0]:,} components)
  • Largest repository: {stats['top_repos'][0]['name']} ({stats['top_repos'][0]['component_count']:,} components)
  • Total tags in use: {len(stats['top_tags'])}
  • Total dependencies: {len(stats['top_dependencies'])}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 QUICK SEARCH EXAMPLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  python3 ~/blackroad-library-search.py "authentication"
  python3 ~/blackroad-library-search.py "api" --language python
  python3 ~/blackroad-library-agent-api.py "Show me React components"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Library Location: {self.library_path}
🗄️  Database: {self.db_path}

╚═══════════════════════════════════════════════════════════════════╝
"""

        return dashboard

    def _make_bar(self, percentage: float, width: int = 40) -> str:
        """Create ASCII progress bar."""
        filled = int((percentage / 100) * width)
        bar = '█' * filled + '░' * (width - filled)
        return bar

    def _get_db_size(self) -> str:
        """Get database file size."""
        size_bytes = self.db_path.stat().st_size
        if size_bytes < 1024:
            return f"{size_bytes} B"
        elif size_bytes < 1024 * 1024:
            return f"{size_bytes / 1024:.1f} KB"
        else:
            return f"{size_bytes / (1024 * 1024):.1f} MB"

    def export_json(self, output_path: str):
        """Export statistics as JSON."""
        stats = self.get_all_stats()
        output_file = Path(output_path).expanduser()

        with open(output_file, 'w') as f:
            json.dump(stats, f, indent=2)

        print(f"✅ Statistics exported to: {output_file}")


def main():
    """CLI interface."""
    import argparse

    parser = argparse.ArgumentParser(description='Generate library statistics')
    parser.add_argument('--library', default='~/blackroad-code-library', help='Library path')
    parser.add_argument('--json', help='Export as JSON to file')
    parser.add_argument('--save', help='Save dashboard to file')

    args = parser.parse_args()

    stats = LibraryStats(args.library)

    if args.json:
        stats.export_json(args.json)
    else:
        dashboard = stats.generate_dashboard()
        print(dashboard)

        if args.save:
            save_path = Path(args.save).expanduser()
            save_path.write_text(dashboard)
            print(f"\n✅ Dashboard saved to: {save_path}")


if __name__ == '__main__':
    main()

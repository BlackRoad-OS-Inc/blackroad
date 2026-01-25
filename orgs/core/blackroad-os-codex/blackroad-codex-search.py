#!/usr/bin/env python3
"""
BlackRoad Code Library Search
Search and retrieve components from the code library.
"""

import sqlite3
import json
from pathlib import Path
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import re

class LibrarySearch:
    """Search interface for the code library."""

    def __init__(self, library_path: str = "~/blackroad-code-library"):
        self.library_path = Path(library_path).expanduser()
        self.db_path = self.library_path / "index" / "components.db"

        if not self.db_path.exists():
            raise FileNotFoundError(f"Library database not found at {self.db_path}. Run scanner first.")

    def search(self, query: str, filters: Optional[Dict] = None, limit: int = 10) -> List[Dict]:
        """
        Search for components.

        Args:
            query: Search query (matches name, tags, description)
            filters: Optional filters (language, type, framework, min_quality, max_age_days)
            limit: Max results to return

        Returns:
            List of matching components
        """
        filters = filters or {}

        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        # Build query
        sql = """
            SELECT * FROM components
            WHERE (
                name LIKE ? OR
                tags LIKE ? OR
                description LIKE ? OR
                type LIKE ?
            )
        """
        params = [f"%{query}%"] * 4

        # Add filters
        if 'language' in filters:
            sql += " AND language = ?"
            params.append(filters['language'])

        if 'type' in filters:
            sql += " AND type = ?"
            params.append(filters['type'])

        if 'framework' in filters:
            sql += " AND framework = ?"
            params.append(filters['framework'])

        if 'min_quality' in filters:
            sql += " AND quality_score >= ?"
            params.append(filters['min_quality'])

        if 'max_age_days' in filters:
            cutoff_date = (datetime.now() - timedelta(days=filters['max_age_days'])).isoformat()
            sql += " AND (last_used_at >= ? OR created_at >= ?)"
            params.extend([cutoff_date, cutoff_date])

        if 'repo' in filters:
            sql += " AND repo = ?"
            params.append(filters['repo'])

        # Order by quality and recency
        sql += " ORDER BY quality_score DESC, created_at DESC LIMIT ?"
        params.append(limit)

        cursor.execute(sql, params)
        rows = cursor.fetchall()

        conn.close()

        return [dict(row) for row in rows]

    def search_by_tag(self, tag: str, limit: int = 10) -> List[Dict]:
        """Search components by tag."""
        return self.search(tag, limit=limit)

    def get_component(self, component_id: str) -> Optional[Dict]:
        """Get a specific component by ID."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM components WHERE id = ?", (component_id,))
        row = cursor.fetchone()

        conn.close()

        return dict(row) if row else None

    def get_similar_components(self, component_id: str, limit: int = 5) -> List[Dict]:
        """
        Find similar components based on:
        - Same type
        - Overlapping tags
        - Same language/framework
        """
        component = self.get_component(component_id)
        if not component:
            return []

        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        # Find components with similar characteristics
        cursor.execute("""
            SELECT * FROM components
            WHERE id != ?
            AND (
                type = ? OR
                language = ? OR
                framework = ? OR
                tags LIKE ?
            )
            ORDER BY quality_score DESC
            LIMIT ?
        """, (
            component_id,
            component['type'],
            component['language'],
            f"%{json.loads(component['tags'])[0]}%",
            limit
        ))

        rows = cursor.fetchall()
        conn.close()

        return [dict(row) for row in rows]

    def get_stats(self) -> Dict:
        """Get library statistics."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        stats = {}

        # Total components
        cursor.execute("SELECT COUNT(*) FROM components")
        stats['total_components'] = cursor.fetchone()[0]

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

        # Quality distribution
        cursor.execute("""
            SELECT
                ROUND(quality_score) as score,
                COUNT(*) as count
            FROM components
            GROUP BY ROUND(quality_score)
            ORDER BY score DESC
        """)
        stats['quality_distribution'] = dict(cursor.fetchall())

        # Repository stats
        cursor.execute("SELECT * FROM repositories ORDER BY component_count DESC")
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM repositories ORDER BY component_count DESC")
        stats['repositories'] = [dict(row) for row in cursor.fetchall()]

        conn.close()

        return stats

    def format_result(self, component: Dict) -> str:
        """Format a component result for display."""
        tags = json.loads(component['tags'])
        deps = json.loads(component['dependencies'])

        output = f"""
{'='*70}
⭐ {component['name']} (Quality: {component['quality_score']}/10)
{'='*70}

Type:        {component['type']}
Language:    {component['language']}
Framework:   {component.get('framework') or 'N/A'}
Repository:  {component['repo']}
Location:    {component['file_path']}:{component['start_line']}-{component['end_line']}

Tags:        {', '.join(tags[:8])}
Dependencies: {', '.join(deps[:5]) if deps else 'None'}

Description:
{component['description']}

Code Preview:
{component['code_snippet']}
...

Full path: {component['file_path']}
"""
        return output

    def format_results(self, components: List[Dict]) -> str:
        """Format multiple results for display."""
        if not components:
            return "No components found."

        output = f"\nFound {len(components)} component(s):\n"

        for i, comp in enumerate(components, 1):
            tags = json.loads(comp['tags'])
            output += f"\n{i}. ⭐ {comp['name']} ({comp['language']}/{comp['type']}) - {comp['quality_score']:.1f}/10\n"
            output += f"   📍 {comp['repo']}/{Path(comp['file_path']).name}:{comp['start_line']}\n"
            output += f"   🏷️  {', '.join(tags[:5])}\n"

        return output


def main():
    """CLI interface for library search."""
    import argparse

    parser = argparse.ArgumentParser(description='Search the BlackRoad code library')
    parser.add_argument('query', nargs='?', help='Search query')
    parser.add_argument('--library', default='~/blackroad-code-library', help='Library path')
    parser.add_argument('--language', help='Filter by language')
    parser.add_argument('--type', help='Filter by type')
    parser.add_argument('--framework', help='Filter by framework')
    parser.add_argument('--min-quality', type=float, help='Minimum quality score')
    parser.add_argument('--max-age', type=int, help='Max age in days')
    parser.add_argument('--limit', type=int, default=10, help='Max results')
    parser.add_argument('--stats', action='store_true', help='Show library statistics')
    parser.add_argument('--id', help='Get specific component by ID')
    parser.add_argument('--similar', help='Find similar components to ID')

    args = parser.parse_args()

    search = LibrarySearch(args.library)

    # Show stats
    if args.stats:
        stats = search.get_stats()
        print("\n📊 Library Statistics")
        print("=" * 70)
        print(f"\nTotal Components: {stats['total_components']}")

        print("\nBy Language:")
        for lang, count in stats['by_language'].items():
            print(f"  {lang}: {count}")

        print("\nBy Type:")
        for type_, count in stats['by_type'].items():
            print(f"  {type_}: {count}")

        if stats['by_framework']:
            print("\nBy Framework:")
            for framework, count in stats['by_framework'].items():
                print(f"  {framework}: {count}")

        print("\nRepositories:")
        for repo in stats['repositories'][:10]:
            print(f"  {repo['name']}: {repo['component_count']} components")

        return

    # Get specific component
    if args.id:
        comp = search.get_component(args.id)
        if comp:
            print(search.format_result(comp))
        else:
            print(f"Component {args.id} not found.")
        return

    # Find similar components
    if args.similar:
        comps = search.get_similar_components(args.similar, args.limit)
        print(search.format_results(comps))
        return

    # Search
    if not args.query:
        parser.print_help()
        return

    filters = {}
    if args.language:
        filters['language'] = args.language
    if args.type:
        filters['type'] = args.type
    if args.framework:
        filters['framework'] = args.framework
    if args.min_quality:
        filters['min_quality'] = args.min_quality
    if args.max_age:
        filters['max_age_days'] = args.max_age

    results = search.search(args.query, filters, args.limit)
    print(search.format_results(results))

    # If only one result, show details
    if len(results) == 1:
        print("\n" + "=" * 70)
        print("Showing details for single result:")
        print(search.format_result(results[0]))


if __name__ == '__main__':
    main()

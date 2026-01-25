#!/usr/bin/env python3
"""
BlackRoad Library Agent API
Simple API interface for agents to query and use the code library.
"""

import sys
import sqlite3
from pathlib import Path
from typing import List, Dict, Optional
import json
from datetime import datetime, timedelta
import re

# Inline the LibrarySearch class
class LibrarySearch:
    """Search interface for the code library."""

    def __init__(self, library_path: str = "~/blackroad-code-library"):
        self.library_path = Path(library_path).expanduser()
        self.db_path = self.library_path / "index" / "components.db"

        if not self.db_path.exists():
            raise FileNotFoundError(f"Library database not found at {self.db_path}. Run scanner first.")

    def search(self, query: str, filters: Optional[Dict] = None, limit: int = 10) -> List[Dict]:
        """Search for components."""
        filters = filters or {}

        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

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

        sql += " ORDER BY quality_score DESC, created_at DESC LIMIT ?"
        params.append(limit)

        cursor.execute(sql, params)
        rows = cursor.fetchall()

        conn.close()

        return [dict(row) for row in rows]

    def search_by_tag(self, tag: str, limit: int = 10) -> List[Dict]:
        """Search components by tag."""
        return self.search(tag, limit=limit)

    def get_stats(self) -> Dict:
        """Get library statistics."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        stats = {}

        cursor.execute("SELECT COUNT(*) FROM components")
        stats['total_components'] = cursor.fetchone()[0]

        cursor.execute("""
            SELECT language, COUNT(*) as count
            FROM components
            GROUP BY language
            ORDER BY count DESC
        """)
        stats['by_language'] = dict(cursor.fetchall())

        cursor.execute("""
            SELECT type, COUNT(*) as count
            FROM components
            GROUP BY type
            ORDER BY count DESC
        """)
        stats['by_type'] = dict(cursor.fetchall())

        cursor.execute("""
            SELECT framework, COUNT(*) as count
            FROM components
            WHERE framework IS NOT NULL
            GROUP BY framework
            ORDER BY count DESC
        """)
        stats['by_framework'] = dict(cursor.fetchall())

        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM repositories ORDER BY component_count DESC")
        stats['repositories'] = [dict(row) for row in cursor.fetchall()]

        conn.close()

        return stats


class LibraryAgent:
    """Agent interface for the code library."""

    def __init__(self, library_path: str = "~/blackroad-code-library"):
        self.search = LibrarySearch(library_path)

    def ask(self, question: str) -> str:
        """
        Natural language interface for agents.

        Examples:
        - "Show me authentication implementations"
        - "I need a React sidebar"
        - "Find JWT components"
        - "What database code do we have?"
        """

        # Parse intent from question
        question_lower = question.lower()

        # Detect filters
        filters = {}

        if 'react' in question_lower:
            filters['framework'] = 'react'
        if 'typescript' in question_lower or 'ts' in question_lower:
            filters['language'] = 'typescript'
        if 'python' in question_lower:
            filters['language'] = 'python'
        if 'nextjs' in question_lower or 'next.js' in question_lower:
            filters['framework'] = 'nextjs'

        # Extract search terms
        keywords = []

        # Common patterns
        patterns = {
            'authentication': ['auth', 'authentication', 'login', 'jwt', 'oauth'],
            'sidebar': ['sidebar', 'navigation', 'nav'],
            'chat': ['chat', 'message', 'conversation'],
            'database': ['database', 'db', 'postgres', 'redis', 'supabase'],
            'api': ['api', 'endpoint', 'route'],
            'form': ['form', 'input', 'validation'],
            'state': ['state', 'store', 'zustand', 'redux'],
            'deployment': ['deploy', 'docker', 'cloudflare', 'railway'],
        }

        # Find matching patterns
        for category, terms in patterns.items():
            if any(term in question_lower for term in terms):
                keywords.append(category)

        # Fallback: extract meaningful words
        if not keywords:
            words = question_lower.split()
            keywords = [w for w in words if len(w) > 3 and w not in ['show', 'find', 'need', 'have', 'what']]

        # Search
        query = ' '.join(keywords) if keywords else question
        results = self.search.search(query, filters, limit=5)

        # Format response
        if not results:
            return f"❌ No components found for: {question}\n\nTry:\n- Being more specific\n- Using different keywords\n- Checking the library stats: --stats"

        response = f"✅ Found {len(results)} component(s) for: {question}\n"
        response += "=" * 70 + "\n"

        for i, comp in enumerate(results, 1):
            tags = json.loads(comp['tags'])
            deps = json.loads(comp['dependencies'])

            response += f"\n{i}. ⭐ {comp['name']} ({comp['language']}/{comp['type']}) - Quality: {comp['quality_score']:.1f}/10\n"
            response += f"   📍 Location: {comp['repo']}/{Path(comp['file_path']).name}:{comp['start_line']}\n"
            response += f"   🏷️  Tags: {', '.join(tags[:5])}\n"

            if comp.get('framework'):
                response += f"   🔧 Framework: {comp['framework']}\n"

            if deps:
                response += f"   📦 Deps: {', '.join(deps[:3])}\n"

            response += f"\n   Preview:\n"
            preview_lines = comp['code_snippet'].split('\n')[:5]
            for line in preview_lines:
                response += f"   {line}\n"
            response += "   ...\n"

        response += "\n" + "=" * 70
        response += f"\n\nTo see full details: blackroad-library-search.py --id <component_id>"
        response += f"\nTo extract code: cat {results[0]['file_path']}"

        return response

    def find_by_category(self, category: str) -> List[Dict]:
        """
        Find components by category.

        Categories:
        - authentication
        - database
        - ui-components
        - api
        - state-management
        - deployment
        """
        return self.search.search_by_tag(category, limit=10)

    def get_best_match(self, query: str, filters: Optional[Dict] = None) -> Optional[Dict]:
        """Get the single best matching component."""
        results = self.search.search(query, filters, limit=1)
        return results[0] if results else None

    def quick_stats(self) -> str:
        """Quick library statistics."""
        stats = self.search.get_stats()

        output = f"""
📚 BlackRoad Code Library Quick Stats
{'=' * 50}

Total Components: {stats['total_components']}

Top Languages:
"""
        for lang, count in list(stats['by_language'].items())[:5]:
            output += f"  • {lang}: {count}\n"

        output += f"\nTop Types:\n"
        for type_, count in list(stats['by_type'].items())[:5]:
            output += f"  • {type_}: {count}\n"

        output += f"\nTop Repositories:\n"
        for repo in stats['repositories'][:5]:
            output += f"  • {repo['name']}: {repo['component_count']} components\n"

        return output


def main():
    """CLI for agent API."""
    import argparse

    parser = argparse.ArgumentParser(description='Agent interface for code library')
    parser.add_argument('question', nargs='*', help='Natural language question')
    parser.add_argument('--library', default='~/blackroad-code-library', help='Library path')
    parser.add_argument('--stats', action='store_true', help='Show quick stats')

    args = parser.parse_args()

    agent = LibraryAgent(args.library)

    if args.stats:
        print(agent.quick_stats())
        return

    if not args.question:
        # Interactive mode
        print("🤖 BlackRoad Library Agent")
        print("Ask me anything about the code library!")
        print("Examples:")
        print("  - Show me authentication implementations")
        print("  - I need a React sidebar")
        print("  - Find JWT components")
        print("\nType 'exit' to quit.\n")

        while True:
            try:
                question = input("❓ ")
                if question.lower() in ['exit', 'quit', 'q']:
                    break

                response = agent.ask(question)
                print(f"\n{response}\n")

            except (KeyboardInterrupt, EOFError):
                print("\nGoodbye!")
                break
    else:
        # Single question mode
        question = ' '.join(args.question)
        response = agent.ask(question)
        print(response)


if __name__ == '__main__':
    main()

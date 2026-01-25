#!/usr/bin/env python3
"""
BlackRoad Code Library Scanner
Scans 66 repos and extracts reusable components into searchable library.
"""

import os
import sqlite3
import json
import hashlib
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional
import subprocess
import re

class ComponentScanner:
    """Scans repositories and extracts reusable components."""

    def __init__(self, library_path: str = "~/blackroad-code-library"):
        self.library_path = Path(library_path).expanduser()
        self.library_path.mkdir(parents=True, exist_ok=True)

        self.db_path = self.library_path / "index" / "components.db"
        self.db_path.parent.mkdir(parents=True, exist_ok=True)

        self.init_database()

    def init_database(self):
        """Initialize SQLite database for components."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS components (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                type TEXT NOT NULL,
                language TEXT,
                framework TEXT,
                repo TEXT NOT NULL,
                file_path TEXT NOT NULL,
                start_line INT,
                end_line INT,
                created_at TIMESTAMP,
                last_used_at TIMESTAMP,
                quality_score REAL,
                usage_count INT DEFAULT 0,
                dependencies TEXT,  -- JSON
                tags TEXT,          -- JSON
                description TEXT,
                code_hash TEXT,
                code_snippet TEXT   -- First 500 chars
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS usage_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                component_id TEXT,
                used_in_project TEXT,
                used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS repositories (
                name TEXT PRIMARY KEY,
                path TEXT NOT NULL,
                last_scanned TIMESTAMP,
                component_count INT DEFAULT 0,
                total_files INT DEFAULT 0
            )
        """)

        conn.commit()
        conn.close()

    def scan_repository(self, repo_path: str) -> List[Dict]:
        """Scan a single repository for components."""
        repo_path = Path(repo_path).expanduser()
        repo_name = repo_path.name

        print(f"📂 Scanning {repo_name}...")

        components = []

        # File patterns to scan
        patterns = {
            'typescript': ['**/*.ts', '**/*.tsx'],
            'javascript': ['**/*.js', '**/*.jsx'],
            'python': ['**/*.py'],
            'go': ['**/*.go'],
            'rust': ['**/*.rs'],
        }

        for lang, pattern_list in patterns.items():
            for pattern in pattern_list:
                for file_path in repo_path.glob(pattern):
                    # Skip node_modules, dist, build, etc.
                    if any(x in file_path.parts for x in ['node_modules', 'dist', 'build', '.next', 'venv', '__pycache__']):
                        continue

                    components.extend(self.extract_components_from_file(
                        file_path, repo_name, lang
                    ))

        # Update repository metadata
        self.update_repo_metadata(repo_name, str(repo_path), len(components))

        return components

    def extract_components_from_file(self, file_path: Path, repo: str, language: str) -> List[Dict]:
        """Extract components from a single file."""
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
        except Exception as e:
            print(f"  ⚠️  Could not read {file_path}: {e}")
            return []

        components = []

        # Extract different types based on language
        if language in ['typescript', 'javascript']:
            components.extend(self.extract_typescript_components(content, file_path, repo))
        elif language == 'python':
            components.extend(self.extract_python_components(content, file_path, repo))

        return components

    def extract_typescript_components(self, content: str, file_path: Path, repo: str) -> List[Dict]:
        """Extract React components, functions, classes from TypeScript/JavaScript."""
        components = []
        lines = content.split('\n')

        # Pattern 1: React components (function or const)
        react_component_pattern = r'^(?:export\s+)?(?:const|function)\s+([A-Z][a-zA-Z0-9]*)\s*[=:]'

        # Pattern 2: Named exports (utilities, helpers)
        export_function_pattern = r'^export\s+(?:async\s+)?function\s+([a-zA-Z_][a-zA-Z0-9_]*)'

        # Pattern 3: Classes
        class_pattern = r'^export\s+class\s+([A-Z][a-zA-Z0-9]*)'

        for i, line in enumerate(lines):
            component_name = None
            component_type = None

            # Check for React components
            match = re.search(react_component_pattern, line)
            if match:
                component_name = match.group(1)
                component_type = 'react-component' if 'tsx' in file_path.suffix else 'function'

            # Check for exported functions
            if not match:
                match = re.search(export_function_pattern, line)
                if match:
                    component_name = match.group(1)
                    component_type = 'function'

            # Check for classes
            if not match:
                match = re.search(class_pattern, line)
                if match:
                    component_name = match.group(1)
                    component_type = 'class'

            if component_name:
                # Find end of component (heuristic: next export or end of file)
                end_line = i + 1
                brace_count = 0
                for j in range(i, len(lines)):
                    if '{' in lines[j]:
                        brace_count += lines[j].count('{')
                    if '}' in lines[j]:
                        brace_count -= lines[j].count('}')
                    if brace_count == 0 and j > i:
                        end_line = j + 1
                        break

                component = self.create_component_entry(
                    name=component_name,
                    type=component_type,
                    language='typescript',
                    repo=repo,
                    file_path=str(file_path),
                    start_line=i + 1,
                    end_line=end_line,
                    code_snippet='\n'.join(lines[i:min(i+20, end_line)])
                )

                components.append(component)

        return components

    def extract_python_components(self, content: str, file_path: Path, repo: str) -> List[Dict]:
        """Extract functions and classes from Python files."""
        components = []
        lines = content.split('\n')

        # Pattern 1: Functions
        function_pattern = r'^(?:async\s+)?def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\('

        # Pattern 2: Classes
        class_pattern = r'^class\s+([A-Z][a-zA-Z0-9_]*)\s*[:(]'

        for i, line in enumerate(lines):
            component_name = None
            component_type = None

            # Check for functions
            match = re.search(function_pattern, line)
            if match:
                component_name = match.group(1)
                component_type = 'function'

            # Check for classes
            if not match:
                match = re.search(class_pattern, line)
                if match:
                    component_name = match.group(1)
                    component_type = 'class'

            if component_name and not component_name.startswith('_'):  # Skip private
                # Find end (heuristic: next def/class at same indentation or end of file)
                indent = len(line) - len(line.lstrip())
                end_line = len(lines)

                for j in range(i + 1, len(lines)):
                    current_indent = len(lines[j]) - len(lines[j].lstrip())
                    if lines[j].strip() and current_indent <= indent:
                        if lines[j].strip().startswith(('def ', 'class ', 'async def ')):
                            end_line = j
                            break

                component = self.create_component_entry(
                    name=component_name,
                    type=component_type,
                    language='python',
                    repo=repo,
                    file_path=str(file_path),
                    start_line=i + 1,
                    end_line=end_line,
                    code_snippet='\n'.join(lines[i:min(i+20, end_line)])
                )

                components.append(component)

        return components

    def create_component_entry(self, name: str, type: str, language: str,
                              repo: str, file_path: str, start_line: int,
                              end_line: int, code_snippet: str) -> Dict:
        """Create a component entry with metadata."""

        # Generate unique ID
        component_id = hashlib.sha256(
            f"{repo}:{file_path}:{name}:{start_line}".encode()
        ).hexdigest()[:16]

        # Calculate code hash (for detecting duplicates)
        code_hash = hashlib.md5(code_snippet.encode()).hexdigest()

        # Extract dependencies (basic heuristic)
        dependencies = self.extract_dependencies(code_snippet, language)

        # Auto-tag based on patterns
        tags = self.auto_tag_component(name, type, code_snippet, file_path)

        return {
            'id': component_id,
            'name': name,
            'type': type,
            'language': language,
            'framework': self.detect_framework(file_path, code_snippet),
            'repo': repo,
            'file_path': file_path,
            'start_line': start_line,
            'end_line': end_line,
            'created_at': datetime.now().isoformat(),
            'dependencies': json.dumps(dependencies),
            'tags': json.dumps(tags),
            'code_hash': code_hash,
            'code_snippet': code_snippet[:500],  # First 500 chars
            'description': self.generate_description(name, type, tags),
            'quality_score': 5.0  # Default, will be calculated later
        }

    def extract_dependencies(self, code: str, language: str) -> List[str]:
        """Extract dependencies from code snippet."""
        deps = []

        if language in ['typescript', 'javascript']:
            # Find imports
            import_pattern = r"import\s+.*?\s+from\s+['\"]([^'\"]+)['\"]"
            deps = re.findall(import_pattern, code)
        elif language == 'python':
            # Find imports
            import_pattern = r"(?:from\s+([^\s]+)\s+import|import\s+([^\s]+))"
            matches = re.findall(import_pattern, code)
            deps = [m[0] or m[1] for m in matches if not (m[0] or m[1]).startswith('.')]

        return list(set(deps))[:10]  # Max 10 deps

    def auto_tag_component(self, name: str, type: str, code: str, file_path: str) -> List[str]:
        """Auto-generate tags based on component characteristics."""
        tags = [type]

        # Path-based tags
        path_lower = file_path.lower()
        if 'auth' in path_lower:
            tags.append('authentication')
        if 'api' in path_lower:
            tags.append('api')
        if 'component' in path_lower or 'ui' in path_lower:
            tags.append('ui')
        if 'util' in path_lower or 'helper' in path_lower:
            tags.append('utility')
        if 'store' in path_lower or 'state' in path_lower:
            tags.append('state-management')

        # Name-based tags
        name_lower = name.lower()
        if 'sidebar' in name_lower or 'nav' in name_lower:
            tags.append('navigation')
        if 'modal' in name_lower or 'dialog' in name_lower:
            tags.append('modal')
        if 'button' in name_lower:
            tags.append('button')
        if 'form' in name_lower or 'input' in name_lower:
            tags.append('form')
        if 'chat' in name_lower or 'message' in name_lower:
            tags.append('chat')

        # Code-based tags
        code_lower = code.lower()
        if 'jwt' in code_lower or 'token' in code_lower:
            tags.append('jwt')
        if 'postgres' in code_lower or 'pg' in code_lower:
            tags.append('postgresql')
        if 'redis' in code_lower:
            tags.append('redis')
        if 'websocket' in code_lower or 'socket.io' in code_lower:
            tags.append('websocket')
        if 'tailwind' in code_lower:
            tags.append('tailwind')

        return list(set(tags))

    def detect_framework(self, file_path: str, code: str) -> Optional[str]:
        """Detect framework being used."""
        code_lower = code.lower()

        if 'react' in code_lower or 'useState' in code or 'useEffect' in code:
            return 'react'
        if 'next' in file_path.lower() or 'next/' in code_lower:
            return 'nextjs'
        if 'express' in code_lower:
            return 'express'
        if 'fastapi' in code_lower:
            return 'fastapi'
        if 'django' in code_lower:
            return 'django'

        return None

    def generate_description(self, name: str, type: str, tags: List[str]) -> str:
        """Generate a basic description for the component."""
        return f"{type.title()}: {name} ({', '.join(tags[:3])})"

    def save_components(self, components: List[Dict]):
        """Save components to database."""
        if not components:
            return

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        for comp in components:
            cursor.execute("""
                INSERT OR REPLACE INTO components (
                    id, name, type, language, framework, repo, file_path,
                    start_line, end_line, created_at, dependencies, tags,
                    code_hash, code_snippet, description, quality_score
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                comp['id'], comp['name'], comp['type'], comp['language'],
                comp['framework'], comp['repo'], comp['file_path'],
                comp['start_line'], comp['end_line'], comp['created_at'],
                comp['dependencies'], comp['tags'], comp['code_hash'],
                comp['code_snippet'], comp['description'], comp['quality_score']
            ))

        conn.commit()
        conn.close()

        print(f"  ✅ Saved {len(components)} components")

    def update_repo_metadata(self, repo_name: str, repo_path: str, component_count: int):
        """Update repository metadata."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            INSERT OR REPLACE INTO repositories (name, path, last_scanned, component_count)
            VALUES (?, ?, ?, ?)
        """, (repo_name, repo_path, datetime.now().isoformat(), component_count))

        conn.commit()
        conn.close()

    def scan_all_repos(self, repos_base_path: str = "~/projects"):
        """Scan all repositories in a base directory."""
        repos_path = Path(repos_base_path).expanduser()

        print(f"🔍 Scanning all repos in {repos_path}...\n")

        total_components = 0
        repo_count = 0

        for repo_dir in repos_path.iterdir():
            if repo_dir.is_dir() and not repo_dir.name.startswith('.'):
                components = self.scan_repository(repo_dir)
                self.save_components(components)
                total_components += len(components)
                repo_count += 1

        print(f"\n✅ Scanned {repo_count} repositories")
        print(f"📦 Found {total_components} components")
        print(f"💾 Library saved to: {self.library_path}")

        return total_components

def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description='Scan repositories for reusable components')
    parser.add_argument('--repos', default='~/projects', help='Path to repositories')
    parser.add_argument('--library', default='~/blackroad-code-library', help='Library output path')
    parser.add_argument('--repo', help='Scan single repository')

    args = parser.parse_args()

    scanner = ComponentScanner(args.library)

    if args.repo:
        components = scanner.scan_repository(args.repo)
        scanner.save_components(components)
    else:
        scanner.scan_all_repos(args.repos)

if __name__ == '__main__':
    main()

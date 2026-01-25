#!/usr/bin/env python3
"""
BlackRoad Codex - Advanced Scraper
Enhanced scraping capabilities for deeper code analysis and knowledge extraction.
"""

import os
import sqlite3
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Set
from datetime import datetime
import subprocess
import ast
import hashlib

class AdvancedCodexScraper:
    """Advanced scraping capabilities for the Codex."""

    def __init__(self, codex_path: str = "~/blackroad-codex"):
        self.codex_path = Path(codex_path).expanduser()
        self.db_path = self.codex_path / "index" / "components.db"

        if not self.db_path.exists():
            raise FileNotFoundError(f"Codex not found at {self.db_path}")

        self.init_advanced_tables()

    def init_advanced_tables(self):
        """Initialize additional tables for advanced scraping."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        # Documentation table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS documentation (
                id TEXT PRIMARY KEY,
                component_id TEXT,
                doc_type TEXT,  -- docstring, comment, readme, inline
                content TEXT,
                line_number INT,
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        # Dependencies graph table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS dependency_graph (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                source_component_id TEXT,
                target_component_id TEXT,
                dependency_type TEXT,  -- import, inherit, call, compose
                strength INT,  -- 1-10 how strong the dependency
                FOREIGN KEY (source_component_id) REFERENCES components(id),
                FOREIGN KEY (target_component_id) REFERENCES components(id)
            )
        """)

        # Code patterns table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS code_patterns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                component_id TEXT,
                pattern_type TEXT,  -- singleton, factory, observer, etc.
                pattern_name TEXT,
                confidence REAL,  -- 0.0-1.0
                evidence TEXT,  -- JSON with supporting evidence
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        # Import/Export relationships
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS import_export (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                component_id TEXT,
                relationship_type TEXT,  -- imports, exports, requires
                module_name TEXT,
                is_external BOOLEAN,  -- True if from external package
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        # Test coverage
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS test_coverage (
                component_id TEXT PRIMARY KEY,
                has_tests BOOLEAN,
                test_file_path TEXT,
                coverage_percentage REAL,
                test_count INT,
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        # GitHub metadata
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS github_repos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                repo_url TEXT UNIQUE,
                repo_name TEXT,
                clone_path TEXT,
                stars INT,
                forks INT,
                last_updated TIMESTAMP,
                scraped BOOLEAN DEFAULT 0
            )
        """)

        conn.commit()
        conn.close()

    def scrape_documentation(self, component_id: str, file_path: str,
                           start_line: int, end_line: int) -> List[Dict]:
        """Extract all documentation from a component."""
        docs = []

        try:
            with open(file_path, 'r') as f:
                lines = f.readlines()

            component_lines = lines[start_line-1:end_line]
            full_code = ''.join(component_lines)

            # Python docstrings
            if file_path.endswith('.py'):
                docs.extend(self._extract_python_docstrings(
                    component_id, full_code, start_line
                ))

            # TypeScript/JavaScript JSDoc comments
            elif file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
                docs.extend(self._extract_jsdoc(
                    component_id, full_code, start_line
                ))

            # Inline comments
            docs.extend(self._extract_inline_comments(
                component_id, component_lines, start_line
            ))

        except Exception as e:
            print(f"  ⚠️  Error extracting docs from {file_path}: {e}")

        return docs

    def _extract_python_docstrings(self, component_id: str,
                                   code: str, start_line: int) -> List[Dict]:
        """Extract Python docstrings."""
        docs = []

        try:
            tree = ast.parse(code)
            for node in ast.walk(tree):
                if isinstance(node, (ast.FunctionDef, ast.ClassDef, ast.Module)):
                    docstring = ast.get_docstring(node)
                    if docstring:
                        doc_id = hashlib.md5(
                            f"{component_id}:{docstring[:50]}".encode()
                        ).hexdigest()[:16]

                        docs.append({
                            'id': doc_id,
                            'component_id': component_id,
                            'doc_type': 'docstring',
                            'content': docstring,
                            'line_number': start_line + node.lineno
                        })
        except:
            pass

        return docs

    def _extract_jsdoc(self, component_id: str,
                       code: str, start_line: int) -> List[Dict]:
        """Extract JSDoc comments."""
        docs = []

        # Pattern: /** ... */
        jsdoc_pattern = r'/\*\*\s*(.*?)\s*\*/'
        matches = re.finditer(jsdoc_pattern, code, re.DOTALL)

        for match in matches:
            content = match.group(1)
            # Clean up asterisks
            content = re.sub(r'^\s*\*\s*', '', content, flags=re.MULTILINE)

            doc_id = hashlib.md5(
                f"{component_id}:{content[:50]}".encode()
            ).hexdigest()[:16]

            # Rough line number estimate
            line_num = code[:match.start()].count('\n') + start_line

            docs.append({
                'id': doc_id,
                'component_id': component_id,
                'doc_type': 'jsdoc',
                'content': content,
                'line_number': line_num
            })

        return docs

    def _extract_inline_comments(self, component_id: str,
                                 lines: List[str], start_line: int) -> List[Dict]:
        """Extract inline comments."""
        docs = []

        for i, line in enumerate(lines):
            # Python/JS/TS single-line comments
            if '#' in line or '//' in line:
                comment = None
                if '#' in line:
                    comment = line.split('#', 1)[1].strip()
                elif '//' in line:
                    comment = line.split('//', 1)[1].strip()

                if comment and len(comment) > 5:  # Meaningful comments
                    doc_id = hashlib.md5(
                        f"{component_id}:{i}:{comment[:30]}".encode()
                    ).hexdigest()[:16]

                    docs.append({
                        'id': doc_id,
                        'component_id': component_id,
                        'doc_type': 'inline',
                        'content': comment,
                        'line_number': start_line + i
                    })

        return docs

    def build_dependency_graph(self, component_id: str,
                              file_path: str, code: str) -> List[Dict]:
        """Build dependency graph for a component."""
        deps = []

        if file_path.endswith('.py'):
            deps.extend(self._analyze_python_dependencies(component_id, code))
        elif file_path.endswith(('.ts', '.tsx', '.js', '.jsx')):
            deps.extend(self._analyze_typescript_dependencies(component_id, code))

        return deps

    def _analyze_python_dependencies(self, component_id: str, code: str) -> List[Dict]:
        """Analyze Python import dependencies."""
        deps = []

        try:
            tree = ast.parse(code)

            for node in ast.walk(tree):
                # Import statements
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        deps.append({
                            'source_component_id': component_id,
                            'target_component_id': None,  # Will resolve later
                            'dependency_type': 'import',
                            'module_name': alias.name,
                            'strength': 5
                        })

                # From X import Y
                elif isinstance(node, ast.ImportFrom):
                    if node.module:
                        deps.append({
                            'source_component_id': component_id,
                            'target_component_id': None,
                            'dependency_type': 'import',
                            'module_name': node.module,
                            'strength': 5
                        })

                # Class inheritance
                elif isinstance(node, ast.ClassDef):
                    for base in node.bases:
                        if isinstance(base, ast.Name):
                            deps.append({
                                'source_component_id': component_id,
                                'target_component_id': None,
                                'dependency_type': 'inherit',
                                'module_name': base.id,
                                'strength': 8
                            })

        except:
            pass

        return deps

    def _analyze_typescript_dependencies(self, component_id: str, code: str) -> List[Dict]:
        """Analyze TypeScript/JavaScript import dependencies."""
        deps = []

        # import X from 'Y'
        import_pattern = r'import\s+.*?\s+from\s+[\'"]([^\'"]+)[\'"]'
        matches = re.finditer(import_pattern, code)

        for match in matches:
            module_name = match.group(1)
            deps.append({
                'source_component_id': component_id,
                'target_component_id': None,
                'dependency_type': 'import',
                'module_name': module_name,
                'strength': 5
            })

        # require('X')
        require_pattern = r'require\([\'"]([^\'"]+)[\'"]\)'
        matches = re.finditer(require_pattern, code)

        for match in matches:
            module_name = match.group(1)
            deps.append({
                'source_component_id': component_id,
                'target_component_id': None,
                'dependency_type': 'require',
                'module_name': module_name,
                'strength': 5
            })

        return deps

    def detect_patterns(self, component_id: str, code: str,
                       component_type: str) -> List[Dict]:
        """Detect design patterns in code."""
        patterns = []

        # Singleton pattern
        if self._is_singleton(code, component_type):
            patterns.append({
                'component_id': component_id,
                'pattern_type': 'creational',
                'pattern_name': 'singleton',
                'confidence': 0.8,
                'evidence': json.dumps({'reason': 'Single instance pattern detected'})
            })

        # Factory pattern
        if self._is_factory(code, component_type):
            patterns.append({
                'component_id': component_id,
                'pattern_type': 'creational',
                'pattern_name': 'factory',
                'confidence': 0.7,
                'evidence': json.dumps({'reason': 'Factory method pattern detected'})
            })

        # Observer pattern
        if self._is_observer(code):
            patterns.append({
                'component_id': component_id,
                'pattern_type': 'behavioral',
                'pattern_name': 'observer',
                'confidence': 0.75,
                'evidence': json.dumps({'reason': 'Event/listener pattern detected'})
            })

        return patterns

    def _is_singleton(self, code: str, component_type: str) -> bool:
        """Check if code follows singleton pattern."""
        if component_type != 'class':
            return False

        # Simple heuristics
        singleton_indicators = [
            'instance' in code.lower(),
            '__new__' in code,
            'getInstance' in code,
            '_instance' in code
        ]

        return sum(singleton_indicators) >= 2

    def _is_factory(self, code: str, component_type: str) -> bool:
        """Check if code follows factory pattern."""
        factory_indicators = [
            'create' in code.lower(),
            'factory' in code.lower(),
            'build' in code.lower(),
            'make' in code.lower()
        ]

        return sum(factory_indicators) >= 2

    def _is_observer(self, code: str) -> bool:
        """Check if code follows observer pattern."""
        observer_indicators = [
            'subscribe' in code.lower(),
            'notify' in code.lower(),
            'listener' in code.lower(),
            'observer' in code.lower(),
            'addEventListener' in code,
            'on(' in code or 'emit(' in code
        ]

        return sum(observer_indicators) >= 2

    def find_tests(self, component_id: str, component_name: str,
                   repo_path: str) -> Optional[Dict]:
        """Find tests for a component."""
        repo = Path(repo_path)

        # Common test file patterns
        test_patterns = [
            f"test_{component_name}.py",
            f"{component_name}.test.ts",
            f"{component_name}.test.js",
            f"{component_name}.spec.ts",
            f"{component_name}.spec.js",
            f"test_{component_name}.ts",
        ]

        # Common test directories
        test_dirs = ['tests', 'test', '__tests__', 'spec']

        for test_dir in test_dirs:
            test_path = repo / test_dir
            if test_path.exists():
                for pattern in test_patterns:
                    test_file = test_path / pattern
                    if test_file.exists():
                        # Count tests
                        test_count = self._count_tests(test_file)

                        return {
                            'component_id': component_id,
                            'has_tests': True,
                            'test_file_path': str(test_file),
                            'coverage_percentage': None,  # Would need coverage tool
                            'test_count': test_count
                        }

        return {
            'component_id': component_id,
            'has_tests': False,
            'test_file_path': None,
            'coverage_percentage': None,
            'test_count': 0
        }

    def _count_tests(self, test_file: Path) -> int:
        """Count number of tests in a file."""
        try:
            content = test_file.read_text()

            # Python: def test_* or class Test*
            if test_file.suffix == '.py':
                count = len(re.findall(r'def test_\w+', content))
                count += len(re.findall(r'class Test\w+', content))
                return count

            # TypeScript/JavaScript: test(, it(, describe(
            elif test_file.suffix in ['.ts', '.js']:
                count = len(re.findall(r'\b(test|it)\s*\(', content))
                return count

        except:
            pass

        return 0

    def scrape_github_repo(self, repo_url: str, clone_to: str = "~/codex-github-repos") -> bool:
        """Clone and scrape a GitHub repository."""
        clone_dir = Path(clone_to).expanduser()
        clone_dir.mkdir(parents=True, exist_ok=True)

        # Extract repo name from URL
        repo_name = repo_url.rstrip('/').split('/')[-1].replace('.git', '')
        repo_path = clone_dir / repo_name

        print(f"📦 Cloning {repo_name} from GitHub...")

        try:
            # Clone if not exists
            if not repo_path.exists():
                result = subprocess.run(
                    ['git', 'clone', repo_url, str(repo_path)],
                    capture_output=True,
                    text=True,
                    timeout=300
                )

                if result.returncode != 0:
                    print(f"  ❌ Failed to clone: {result.stderr}")
                    return False

            # Get GitHub stats
            stats = self._get_github_stats(repo_url)

            # Save repo metadata
            self._save_github_repo(repo_url, repo_name, str(repo_path), stats)

            print(f"  ✅ Cloned successfully")
            return True

        except Exception as e:
            print(f"  ❌ Error cloning repo: {e}")
            return False

    def _get_github_stats(self, repo_url: str) -> Dict:
        """Get GitHub repository statistics."""
        # Would use GitHub API here
        # For now, return placeholders
        return {
            'stars': 0,
            'forks': 0,
            'last_updated': datetime.now().isoformat()
        }

    def _save_github_repo(self, url: str, name: str, path: str, stats: Dict):
        """Save GitHub repo metadata."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            INSERT OR REPLACE INTO github_repos (repo_url, repo_name, clone_path, stars, forks, last_updated)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (url, name, path, stats['stars'], stats['forks'], stats['last_updated']))

        conn.commit()
        conn.close()

    def deep_scrape_component(self, component_id: str):
        """Perform deep scrape on a single component."""
        # Get component info
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM components WHERE id = ?", (component_id,))
        comp = dict(cursor.fetchone())
        conn.close()

        print(f"🔍 Deep scraping: {comp['name']}")

        # Extract code
        file_path = Path(comp['file_path'])
        if not file_path.exists():
            print(f"  ⚠️  File not found: {file_path}")
            return

        with open(file_path) as f:
            lines = f.readlines()

        code = ''.join(lines[comp['start_line']-1:comp['end_line']])

        # 1. Documentation
        docs = self.scrape_documentation(
            component_id, str(file_path),
            comp['start_line'], comp['end_line']
        )
        self._save_documentation(docs)
        print(f"  📖 Extracted {len(docs)} documentation entries")

        # 2. Dependencies
        deps = self.build_dependency_graph(component_id, str(file_path), code)
        self._save_dependencies(deps)
        print(f"  🔗 Found {len(deps)} dependencies")

        # 3. Patterns
        patterns = self.detect_patterns(component_id, code, comp['type'])
        self._save_patterns(patterns)
        print(f"  🎨 Detected {len(patterns)} patterns")

        # 4. Tests
        repo_path = str(file_path.parent)
        test_info = self.find_tests(component_id, comp['name'], repo_path)
        if test_info:
            self._save_test_coverage(test_info)
            if test_info['has_tests']:
                print(f"  ✅ Tests found: {test_info['test_count']} tests")
            else:
                print(f"  ⚠️  No tests found")

    def _save_documentation(self, docs: List[Dict]):
        """Save documentation to database."""
        if not docs:
            return

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        for doc in docs:
            cursor.execute("""
                INSERT OR REPLACE INTO documentation (id, component_id, doc_type, content, line_number)
                VALUES (?, ?, ?, ?, ?)
            """, (doc['id'], doc['component_id'], doc['doc_type'],
                  doc['content'], doc['line_number']))

        conn.commit()
        conn.close()

    def _save_dependencies(self, deps: List[Dict]):
        """Save dependencies to database."""
        if not deps:
            return

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        for dep in deps:
            cursor.execute("""
                INSERT INTO dependency_graph (source_component_id, target_component_id, dependency_type, strength)
                VALUES (?, ?, ?, ?)
            """, (dep['source_component_id'], dep['target_component_id'],
                  dep.get('dependency_type', 'import'), dep.get('strength', 5)))

        conn.commit()
        conn.close()

    def _save_patterns(self, patterns: List[Dict]):
        """Save detected patterns to database."""
        if not patterns:
            return

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        for pattern in patterns:
            cursor.execute("""
                INSERT INTO code_patterns (component_id, pattern_type, pattern_name, confidence, evidence)
                VALUES (?, ?, ?, ?, ?)
            """, (pattern['component_id'], pattern['pattern_type'],
                  pattern['pattern_name'], pattern['confidence'], pattern['evidence']))

        conn.commit()
        conn.close()

    def _save_test_coverage(self, test_info: Dict):
        """Save test coverage info to database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            INSERT OR REPLACE INTO test_coverage (component_id, has_tests, test_file_path, coverage_percentage, test_count)
            VALUES (?, ?, ?, ?, ?)
        """, (test_info['component_id'], test_info['has_tests'],
              test_info['test_file_path'], test_info['coverage_percentage'],
              test_info['test_count']))

        conn.commit()
        conn.close()


def main():
    """CLI interface for advanced scraping."""
    import argparse

    parser = argparse.ArgumentParser(description='Advanced Codex Scraper')
    parser.add_argument('--codex', default='~/blackroad-codex', help='Codex path')
    parser.add_argument('--deep-scrape', help='Deep scrape component by ID')
    parser.add_argument('--clone-github', help='Clone and scrape GitHub repo URL')
    parser.add_argument('--scrape-all', action='store_true', help='Deep scrape all components')
    parser.add_argument('--limit', type=int, help='Limit number of components to scrape')

    args = parser.parse_args()

    scraper = AdvancedCodexScraper(args.codex)

    if args.clone_github:
        scraper.scrape_github_repo(args.clone_github)

    elif args.deep_scrape:
        scraper.deep_scrape_component(args.deep_scrape)

    elif args.scrape_all:
        # Get all components
        conn = sqlite3.connect(scraper.db_path)
        cursor = conn.cursor()

        limit_clause = f"LIMIT {args.limit}" if args.limit else ""
        cursor.execute(f"SELECT id FROM components {limit_clause}")
        component_ids = [row[0] for row in cursor.fetchall()]
        conn.close()

        print(f"🔍 Deep scraping {len(component_ids)} components...\n")

        for i, comp_id in enumerate(component_ids, 1):
            print(f"[{i}/{len(component_ids)}]", end=" ")
            scraper.deep_scrape_component(comp_id)
            print()

        print(f"\n✅ Deep scraping complete!")

    else:
        parser.print_help()


if __name__ == '__main__':
    main()

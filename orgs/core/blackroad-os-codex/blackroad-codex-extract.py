#!/usr/bin/env python3
"""
BlackRoad Library Component Extractor
Extract and copy components from the library for easy integration.
"""

import sqlite3
from pathlib import Path
from typing import Dict, Optional
import json
import shutil

class ComponentExtractor:
    """Extract components from library."""

    def __init__(self, library_path: str = "~/blackroad-code-library"):
        self.library_path = Path(library_path).expanduser()
        self.db_path = self.library_path / "index" / "components.db"

        if not self.db_path.exists():
            raise FileNotFoundError(f"Library database not found at {self.db_path}")

    def get_component(self, component_id: str) -> Optional[Dict]:
        """Get component by ID."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM components WHERE id = ?", (component_id,))
        row = cursor.fetchone()

        conn.close()

        return dict(row) if row else None

    def extract_code(self, component_id: str) -> str:
        """Extract full source code for a component."""
        comp = self.get_component(component_id)
        if not comp:
            return f"Component {component_id} not found"

        file_path = Path(comp['file_path'])

        if not file_path.exists():
            return f"Source file not found: {file_path}"

        try:
            with open(file_path, 'r') as f:
                lines = f.readlines()

            start = comp['start_line'] - 1  # 0-indexed
            end = comp['end_line']

            code = ''.join(lines[start:end])
            return code

        except Exception as e:
            return f"Error reading file: {e}"

    def extract_component_with_context(self, component_id: str) -> Dict:
        """Extract component with metadata and usage instructions."""
        comp = self.get_component(component_id)
        if not comp:
            return {"error": f"Component {component_id} not found"}

        code = self.extract_code(component_id)
        tags = json.loads(comp['tags'])
        deps = json.loads(comp['dependencies'])

        return {
            'metadata': {
                'id': comp['id'],
                'name': comp['name'],
                'type': comp['type'],
                'language': comp['language'],
                'framework': comp.get('framework'),
                'repo': comp['repo'],
                'file_path': comp['file_path'],
                'location': f"{comp['file_path']}:{comp['start_line']}-{comp['end_line']}",
                'quality_score': comp['quality_score'],
                'tags': tags,
                'dependencies': deps,
            },
            'code': code,
            'usage_instructions': self._generate_usage_instructions(comp, deps),
        }

    def _generate_usage_instructions(self, comp: Dict, deps: list) -> str:
        """Generate usage instructions."""
        instructions = f"""
# How to Use: {comp['name']}

## 1. Copy the code
The full component code is provided below.

## 2. Install dependencies
"""

        if deps:
            if comp['language'] in ['typescript', 'javascript']:
                instructions += "```bash\n"
                instructions += "npm install " + " ".join(deps[:10]) + "\n"
                instructions += "```\n"
            elif comp['language'] == 'python':
                instructions += "```bash\n"
                instructions += "pip install " + " ".join(deps[:10]) + "\n"
                instructions += "```\n"
        else:
            instructions += "No external dependencies required.\n"

        instructions += f"""
## 3. Integration
- File location: `{comp['file_path']}`
- Type: {comp['type']}
- Framework: {comp.get('framework') or 'N/A'}

## 4. Adjust imports
Update import paths to match your project structure.
"""

        return instructions

    def copy_to_file(self, component_id: str, output_path: str):
        """Copy component to a file."""
        output_file = Path(output_path).expanduser()

        extraction = self.extract_component_with_context(component_id)

        if 'error' in extraction:
            print(f"❌ {extraction['error']}")
            return

        # Create output content
        content = f"""# Component: {extraction['metadata']['name']}
# Source: {extraction['metadata']['location']}
# Quality: {extraction['metadata']['quality_score']}/10
# Tags: {', '.join(extraction['metadata']['tags'])}

{extraction['usage_instructions']}

# ============================================================================
# CODE
# ============================================================================

{extraction['code']}
"""

        output_file.write_text(content)
        print(f"✅ Component extracted to: {output_file}")
        print(f"   Name: {extraction['metadata']['name']}")
        print(f"   Type: {extraction['metadata']['type']}")
        print(f"   Quality: {extraction['metadata']['quality_score']}/10")

    def create_component_package(self, component_id: str, output_dir: str):
        """Create a complete package with component + dependencies."""
        output_path = Path(output_dir).expanduser()
        output_path.mkdir(parents=True, exist_ok=True)

        extraction = self.extract_component_with_context(component_id)

        if 'error' in extraction:
            print(f"❌ {extraction['error']}")
            return

        meta = extraction['metadata']

        # Save component code
        lang_ext = {
            'python': '.py',
            'typescript': '.ts',
            'javascript': '.js',
        }.get(meta['language'], '.txt')

        code_file = output_path / f"{meta['name']}{lang_ext}"
        code_file.write_text(extraction['code'])

        # Save metadata
        metadata_file = output_path / "component-info.json"
        metadata_file.write_text(json.dumps(meta, indent=2))

        # Save README
        readme_file = output_path / "README.md"
        readme_file.write_text(f"""# {meta['name']}

**Type:** {meta['type']}
**Language:** {meta['language']}
**Framework:** {meta.get('framework') or 'N/A'}
**Quality Score:** {meta['quality_score']}/10

## Source
- **Repository:** {meta['repo']}
- **File:** {meta['file_path']}
- **Lines:** {meta['location']}

## Tags
{', '.join(meta['tags'])}

## Dependencies
{'- ' + '\n- '.join(meta['dependencies']) if meta['dependencies'] else 'None'}

{extraction['usage_instructions']}

## Files in Package
- `{code_file.name}` - Component code
- `component-info.json` - Metadata
- `README.md` - This file
""")

        print(f"✅ Component package created: {output_path}")
        print(f"   Files:")
        print(f"     - {code_file.name}")
        print(f"     - component-info.json")
        print(f"     - README.md")


def main():
    """CLI interface."""
    import argparse

    parser = argparse.ArgumentParser(description='Extract components from library')
    parser.add_argument('component_id', help='Component ID to extract')
    parser.add_argument('--library', default='~/blackroad-code-library', help='Library path')
    parser.add_argument('--output', '-o', help='Output file path')
    parser.add_argument('--package', '-p', help='Create full package in directory')
    parser.add_argument('--print', action='store_true', help='Print code to stdout')

    args = parser.parse_args()

    extractor = ComponentExtractor(args.library)

    if args.print:
        # Just print the code
        code = extractor.extract_code(args.component_id)
        print(code)

    elif args.package:
        # Create full package
        extractor.create_component_package(args.component_id, args.package)

    elif args.output:
        # Save to file
        extractor.copy_to_file(args.component_id, args.output)

    else:
        # Show extraction with metadata
        extraction = extractor.extract_component_with_context(args.component_id)

        if 'error' in extraction:
            print(f"❌ {extraction['error']}")
            return

        print(f"""
{'='*70}
Component: {extraction['metadata']['name']}
{'='*70}

Type:        {extraction['metadata']['type']}
Language:    {extraction['metadata']['language']}
Framework:   {extraction['metadata'].get('framework') or 'N/A'}
Quality:     {extraction['metadata']['quality_score']}/10
Location:    {extraction['metadata']['location']}

Tags:        {', '.join(extraction['metadata']['tags'])}
Dependencies: {', '.join(extraction['metadata']['dependencies']) if extraction['metadata']['dependencies'] else 'None'}

{extraction['usage_instructions']}

{'='*70}
CODE
{'='*70}

{extraction['code']}

{'='*70}

💡 To save: --output <file>
💡 To create package: --package <directory>
💡 To print only code: --print
""")


if __name__ == '__main__':
    main()

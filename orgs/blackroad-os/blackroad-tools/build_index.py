import json
import re
from pathlib import Path

README = Path('README.md').read_text().splitlines()
index = {}
section = None

link_re = re.compile(r"^- \[([^\]]+)\]\(([^)]+)\)(?: - (.*))?")
for line in README:
    header = re.match(r'^##\s+(.*)', line)
    if header:
        section = header.group(1).strip()
        index.setdefault(section, [])
        continue
    match = link_re.match(line)
    if match and section:
        title, url, notes = match.groups()
        entry = {'title': title, 'url': url}
        if notes:
            entry['notes'] = notes
        index[section].append(entry)

output_path = Path('docs/index.json')
output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text(json.dumps(index, indent=2))
